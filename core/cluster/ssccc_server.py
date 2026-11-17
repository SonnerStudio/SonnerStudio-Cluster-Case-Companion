"""SS-CCC Verbund-Server: mlx_lm.server mit speichergewichteter Pipeline-Aufteilung.

Wird von mlx.launch auf allen Rechnern des Verbunds gestartet (gleicher Pfad
/Users/Shared/ssccc auf jedem Mac). Rang 0 (Leitrechner) stellt die
OpenAI-kompatible Schnittstelle bereit.

Aufteilung: SSCCC_USABLE_GB="30,12" (nutzbarer Speicher je Rang, Rang 0 zuerst).
Formel wie MemoryWeightedPlanner: Schichten_i = Gesamt * Nutzbar_i / Summe(Nutzbar).
"""

import os
import sys

from mlx_lm.models import pipeline as _pipeline

_orig_pipeline = _pipeline.PipelineMixin.pipeline


def _weighted_split(n_layers: int, usable: list[float]) -> list[int]:
    total = sum(usable)
    split = [max(1, int(n_layers * u / total)) for u in usable]
    # Rest an die Ränge mit dem größten Speicher verteilen
    order = sorted(range(len(usable)), key=lambda i: -usable[i])
    i = 0
    while sum(split) < n_layers:
        split[order[i % len(order)]] += 1
        i += 1
    while sum(split) > n_layers:
        j = order[-1 - (i % len(order))]
        if split[j] > 1:
            split[j] -= 1
        i += 1
    return split


class _ZeroEmbed:
    """Ersatz für die Embedding-Tabelle auf Rängen, die sie nie nutzen.

    Nur der letzte Pipeline-Rang (erste Schichten) bettet Token ein; alle
    anderen empfangen den Hidden-State per recv_like und brauchen nur Form
    und Datentyp. Spart ~1,35 GB auf dem Leitrechner.
    """

    def __init__(self, hidden, dtype):
        self.hidden, self.dtype = hidden, dtype

    def __call__(self, inputs):
        import mlx.core as mx

        return mx.zeros((*inputs.shape, self.hidden), dtype=self.dtype)


def _pipeline_weighted(self, group, split=None):
    if split is None:
        raw_split = os.environ.get("SSCCC_SPLIT", "")
        raw = os.environ.get("SSCCC_USABLE_GB", "")
        if raw_split:
            split = [int(x) for x in raw_split.split(",")]
            source = "fest"
        elif raw:
            usable = [float(x) for x in raw.split(",")]
            if len(usable) == group.size():
                split = _weighted_split(len(self.layers), usable)
            source = f"nutzbar GB {usable}"
        if split is not None:
            print(
                f"[SS-CCC] Rang {group.rank()}/{group.size()}: "
                f"Schichten-Aufteilung {split} ({source})",
                file=sys.stderr,
                flush=True,
            )
    result = _orig_pipeline(self, group, split)
    if (
        os.environ.get("SSCCC_DROP_EMBED") == "1"
        and self.pipeline_size > 1
        and self.pipeline_rank != self.pipeline_size - 1
        and hasattr(self, "embed_tokens")
    ):
        hidden = self.norm.weight.shape[0]
        self.embed_tokens = _ZeroEmbed(hidden, self.norm.weight.dtype)
        print(f"[SS-CCC] Rang {self.pipeline_rank}: Embedding-Tabelle eingespart", file=sys.stderr, flush=True)
    return result


_pipeline.PipelineMixin.pipeline = _pipeline_weighted

if __name__ == "__main__":
    import shlex

    from mlx_lm import server as _server
    from mlx_lm.server import main

    # Im Verbund ist genau ein Modell geladen. Jeder angefragte Modellname
    # (z. B. "mlx-community/Qwen3.8-27B-8bit" oder "qwen3.8") wird darauf
    # abgebildet, statt ein neues Modell aus dem Internet nachzuladen.
    _orig_load = _server.ModelProvider.load

    def _load_pinned(self, model_path, adapter_path=None, draft_model_path=None):
        return _orig_load(self, "default_model", None, "default_model")

    _server.ModelProvider.load = _load_pinned

    # Ausgabeschicht (lm_head) nach Vokabular auf alle Ränge verteilen, statt
    # sie auf jedem Rang vollständig zu rechnen. Danach sammelt
    # gather_last_axis die Logit-Teile ein.
    if os.environ.get("SSCCC_SHARD_LMHEAD") == "1":
        import mlx.core as mx
        from mlx.nn.layers.distributed import shard_linear

        _orig_sharded_load = _server.sharded_load

        def _sharded_load_split_head(*args, **kwargs):
            out = _orig_sharded_load(*args, **kwargs)
            model = out[0]
            group = mx.distributed.init()
            lm = getattr(model, "language_model", model)
            if group.size() > 1 and hasattr(lm, "lm_head") and hasattr(lm, "sharding_group"):
                lm.lm_head = shard_linear(lm.lm_head, "all-to-sharded", group=group)
                lm.sharding_group = group
                mx.eval(lm.lm_head.parameters())
                mx.clear_cache()
                print(f"[SS-CCC] Rang {group.rank()}: lm_head geteilt", file=sys.stderr, flush=True)
            return out

        _server.sharded_load = _sharded_load_split_head

    # Selbstheilung: Stirbt der Generierungs-Thread (z. B. Speichermangel oder
    # verlorene Ring-Verbindung), beendet sich der Prozess. mlx.launch stoppt
    # dann alle Ränge, und launchd startet den Verbund nach 30 s neu.
    _gen_cls = next(
        c for c in vars(_server).values()
        if isinstance(c, type) and hasattr(c, "_run_generate")
    )
    _orig_run_generate = _gen_cls._run_generate

    def _run_generate_or_exit(self):
        _orig_run_generate(self)
        if getattr(self, "_generation_failed", False):
            print("[SS-CCC] Generierung abgebrochen – Verbund wird neu gestartet", file=sys.stderr, flush=True)
            os._exit(1)

    _gen_cls._run_generate = _run_generate_or_exit

    # ── Verbundstatus für die SS-CCC-App: GET /ssccc/cluster ─────────────────
    # Rang 0 sammelt alle 20 s die echten Hardware-Daten beider Macs
    # (node_info.sh lokal und per SSH) und liefert sie zusammen mit
    # Schichten-Aufteilung, Verbindung und Modell als JSON aus.
    import json as _json
    import subprocess as _sp
    import threading as _th
    import time as _time

    _B = "/Users/Shared/ssccc"
    _status = {"nodes": [], "updated": 0}
    _started = _time.time()

    def _collect_status():
        hosts = _json.load(open(f"{_B}/hostfile_aktiv.json"))
        split = [int(x) for x in os.environ.get("SSCCC_SPLIT", "0,0").split(",")]
        link = ""
        try:
            for line in open(f"{_B}/verbund.log", encoding="utf-8", errors="ignore"):
                if "Verbindung:" in line:
                    link = line.split("Verbindung:", 1)[1].split("|")[0].strip()
        except OSError:
            pass
        nodes = []
        for rank, h in enumerate(hosts):
            cmd = [f"{_B}/node_info.sh"] if h["ssh"] == "127.0.0.1" else [
                "/usr/bin/ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", h["ssh"], f"{_B}/node_info.sh"]
            try:
                info = _json.loads(_sp.run(cmd, capture_output=True, text=True, timeout=30).stdout)
                info["online"] = True
            except Exception:
                info = {"name": h["ssh"], "online": False}
            # Echte Bereitschaftsprüfung je Knoten
            info["ssh_ok"] = bool(info.get("online"))
            if rank == 0:
                info["ring_ok"] = True
            else:
                info["ring_ok"] = all(
                    _sp.run(["/sbin/ping", "-c", "1", "-t", "2", ip], capture_output=True).returncode == 0
                    for ip in h["ips"]
                )
            info["wired_ok"] = int(info.get("wired_limit_mb") or 0) > 0
            info["rank"] = rank
            info["role"] = "Coordinator (Rank 0)" if rank == 0 else f"Worker (Rank {rank})"
            info["layers"] = split[rank] if rank < len(split) else 0
            info["ring_ips"] = h["ips"]
            nodes.append(info)
        return {
            "cluster": "SS-CCC Verbund",
            "backend": "mlx.distributed ring (Pipeline)",
            "link": link,
            "model": os.environ.get("SSCCC_VERBUND_REPO", "verbund-modell"),
            "total_layers": sum(split),
            "endpoint_port": 8000,
            "uptime_s": int(_time.time() - _started),
            "updated": int(_time.time()),
            "nodes": nodes,
        }

    def _status_loop():
        while True:
            try:
                _status.update(_collect_status())
            except Exception as e:  # Status darf den Server nie stören
                print(f"[SS-CCC] Status-Fehler: {e}", file=sys.stderr, flush=True)
            _time.sleep(20)

    import mlx.core as _mx

    if _mx.distributed.init().rank() == 0:
        _th.Thread(target=_status_loop, daemon=True).start()

    _orig_do_get = _server.APIHandler.do_GET

    def _do_get_with_status(self):
        if self.path.split("?")[0] == "/ssccc/cluster":
            body = _json.dumps(dict(_status, uptime_s=int(_time.time() - _started)), ensure_ascii=False).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(body)
            return
        return _orig_do_get(self)

    _server.APIHandler.do_GET = _do_get_with_status

    # mlx.launch würde Optionen wie --host selbst auswerten, daher kommen die
    # Server-Argumente über SSCCC_SERVER_ARGS.
    sys.argv += shlex.split(os.environ.get("SSCCC_SERVER_ARGS", ""))
    main()
