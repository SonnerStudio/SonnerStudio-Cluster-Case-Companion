"""Zentrale Konfiguration des SS-CCC-Verbunds.

Alle rechnerspezifischen Werte (Worker-Mac, Modelle, Ports) stehen in
`$SSCCC_HOME/cluster.json` (Standard: /Users/Shared/ssccc/cluster.json). Fehlende
Werte werden mit den Standardwerten unten ergänzt. Die Ersteinrichtung
(`ssccc_setup.py`) erzeugt die Datei.

Gemeinsamer Pfad /Users/Shared/ssccc: mlx.launch startet auf jedem Mac dieselbe
Befehlszeile – Benutzernamen und Home-Ordner unterscheiden sich aber. Ein für alle
Benutzer gleicher Pfad vermeidet das Problem.

Aufruf als Skript:
  python ssccc_config.py env    -> Shell-Exports für die Startskripte
  python ssccc_config.py show   -> zusammengeführte Konfiguration als JSON
"""

import copy
import json
import os
import sys
from pathlib import Path

HOME = Path(os.environ.get("SSCCC_HOME", "/Users/Shared/ssccc"))

DEFAULTS: dict = {
    "mode": "multimodel",               # multimodel | verbund
    "gateway_port": 8000,
    "coordinator": {"name": "Leitrechner", "host": ""},   # Bonjour-Name (*.local) für Worker
    "worker": {                         # leer lassen, wenn es keinen zweiten Mac gibt
        "name": "Worker",
        "ssh": "",                      # SSH-Alias aus ~/.ssh/config, z. B. "ssccc-worker"
        "host": "",                     # Bonjour-Name des Workers
    },
    "llm": {                            # Multi-Model-Mode: Sprachmodell auf dem Leitrechner
        "repo": "mlx-community/Qwen3.8-27B-4bit",
        "draft_repo": "mlx-community/Qwen3.8-27B-MTP-4bit",   # MTP (Speculative Decoding), "" = aus
        "display_name": "SS-CCC Qwen3.8 27B (lokal, MTP)",
        "context": 131072,
        "max_output": 32768,
        "max_num_seqs": 2,              # gleichzeitige Sequenzen (Speicherschutz)
        "kv_bits": 8,                   # KV-Cache-Quantisierung (Speicherschutz; 0 = aus, ~5 % schneller)
        "large_prompt": 32768,          # ab hier laufen Anfragen nacheinander
        "port": 8001,
    },
    "verbund": {                        # Verbund-Modus: ein Modell über alle Macs geteilt
        "repo": "mlx-community/Qwen3.8-27B-8bit",
        "model_dir": "models/Qwen3.8-27B-8bit",
        "split": "60,4",                # Schichten je Rang (Rang 0 zuerst)
    },
    "image": {
        "enabled": True,
        "name": "HiDream-O1-Image-Dev",
        "repo": "mlx-community/HiDream-O1-Image-Dev-mlx-bf16",
        "model_dir": "models/HiDream-O1-Image-Dev-bf16",
        "idle_wait_s": 30,              # Bild erst nach so viel Chat-Leerlauf …
        "max_wait_s": 300,              # … aber spätestens nach dieser Wartezeit
    },
    "reserve": {                        # Antwort-Reserve auf dem Worker während Bildaufträgen
        "enabled": True,
        "port": 8002,
        "model_dir": "",
        "name": "Reserve-Modell (Worker)",
    },
    "forward_port": 8090,               # lokale Weiterleitung auf dem Worker -> Gateway
    "api_key": "",                      # leer = offen im Heimnetz; sonst Schlüssel für alle Clients
    "tls": {"cert": "", "key": ""},     # optional HTTPS (Zertifikat + Schlüssel als Dateipfade)
}


def _merge(base: dict, over: dict) -> dict:
    out = copy.deepcopy(base)
    for k, v in (over or {}).items():
        out[k] = _merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out


def load() -> dict:
    p = HOME / "cluster.json"
    data = json.loads(p.read_text()) if p.exists() else {}
    cfg = _merge(DEFAULTS, data)
    cfg["home"] = str(HOME)
    return cfg


def path(rel: str) -> Path:
    p = Path(rel)
    return p if p.is_absolute() else HOME / p


def hf_snapshot(repo: str) -> str:
    """Pfad des heruntergeladenen Hugging-Face-Modells im gemeinsamen Cache."""
    d = HOME / "hf/hub" / f"models--{repo.replace('/', '--')}" / "snapshots"
    snaps = sorted(d.iterdir()) if d.exists() else []
    return str(snaps[-1]) if snaps else ""


def shell_env(cfg: dict) -> str:
    w, v, r = cfg["worker"], cfg["verbund"], cfg["reserve"]
    vals = {
        "SSCCC_HOME": cfg["home"],
        "SSCCC_MODE": cfg["mode"],
        "SSCCC_PORT": cfg["gateway_port"],
        "SSCCC_WORKER_SSH": w.get("ssh", ""),
        "SSCCC_WORKER_HOST": w.get("host", ""),
        "SSCCC_COORDINATOR_HOST": cfg["coordinator"].get("host", ""),
        "SSCCC_VERBUND_MODEL": str(path(v["model_dir"])),
        "SSCCC_VERBUND_REPO": v["repo"],
        "SSCCC_DEFAULT_SPLIT": v["split"],
        "SSCCC_RESERVE_PORT": r["port"],
        "SSCCC_FORWARD_PORT": cfg["forward_port"],
    }
    return "\n".join(f"export {k}='{val}'" for k, val in vals.items())


if __name__ == "__main__":
    c = load()
    if len(sys.argv) > 1 and sys.argv[1] == "env":
        print(shell_env(c))
    else:
        print(json.dumps(c, indent=2, ensure_ascii=False))
