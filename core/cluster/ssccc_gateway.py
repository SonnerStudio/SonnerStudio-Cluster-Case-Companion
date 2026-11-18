"""SS-CCC Gateway (Multi-Model-Mode) auf dem Leitrechner – Port 8000.

- Sprache: Sprachmodell (mlx-vlm, mit MTP-Speculative-Decoding) als Unterprozess
  auf 127.0.0.1:<llm.port>. Alle /v1/*-Anfragen werden durchgereicht (auch
  Streaming), jeder Modellname wird auf das geladene Modell abgebildet
  (mlx-Server würden sonst ein neues Modell aus dem Internet nachladen).
- Bild: HiDream-O1-Image-Dev (BF16, MIT-Lizenz) „auf Abruf“ über
  POST /v1/images/generations und /v1/images/edits (OpenAI-kompatibel). Für die
  Bilderzeugung wird das Sprachmodell kurz entladen (beide passen nicht
  gleichzeitig in den GPU-Speicher) und danach automatisch wieder gestartet.
- Antwort-Reserve: während eines Bildauftrags beantwortet ein kleineres Modell auf
  dem Worker-Mac Chat-Anfragen; ohne Reserve warten die Anfragen.
- Status für die SS-CCC-App: GET /ssccc/cluster, GET /health.

Alle rechnerspezifischen Werte kommen aus ssccc_config.py / cluster.json.
"""

import asyncio
import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, Response, StreamingResponse

sys.path.insert(0, str(Path(__file__).resolve().parent))
import image_queue  # noqa: E402
import request_guard  # noqa: E402
import ssccc_config  # noqa: E402
import telemetry  # noqa: E402

CFG = ssccc_config.load()
B = Path(CFG["home"])

LLM_MODEL = os.environ.get("SSCCC_LLM_MODEL") or ssccc_config.hf_snapshot(CFG["llm"]["repo"])
LLM_DRAFT = os.environ.get("SSCCC_LLM_DRAFT")
if LLM_DRAFT is None:
    LLM_DRAFT = ssccc_config.hf_snapshot(CFG["llm"]["draft_repo"]) if CFG["llm"]["draft_repo"] else ""
LLM_NAME = os.environ.get("SSCCC_LLM_NAME", CFG["llm"]["repo"])
LLM_PORT = int(CFG["llm"]["port"])
LLM_URL = f"http://127.0.0.1:{LLM_PORT}"
IMG_ENABLED = bool(CFG["image"]["enabled"])
IMG_MODEL = str(ssccc_config.path(CFG["image"]["model_dir"]))
IMG_NAME = CFG["image"]["name"]
IMG_SCRIPT = f"{IMG_MODEL}/scripts/hidream_o1/generate_hidream_o1_mlx.py"
IMG_PY = str(B / "venv-img/bin/python")
OUT_DIR = B / "bilder"
OUT_DIR.mkdir(exist_ok=True)
WORKER_SSH = CFG["worker"].get("ssh", "")
WORKER_HOST = CFG["worker"].get("host", "")


def _worker_ipv4() -> str:
    """IPv4 des Worker-Macs.

    Die Namensauflösung über *.local liefert auch IPv6-Adressen (inkl. link-local);
    Python/Node probieren diese zuerst und hängen dann minutenlang. Deshalb die
    IPv4-Adresse direkt vom Worker erfragen.
    """
    if not WORKER_SSH:
        return WORKER_HOST
    try:
        ip = subprocess.run(["/usr/bin/ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", WORKER_SSH,
                             "ipconfig getifaddr en0 || ipconfig getifaddr en1"],
                            capture_output=True, text=True, timeout=15).stdout.strip()
        return ip or WORKER_HOST
    except Exception:
        return WORKER_HOST


# Antwort-Reserve auf dem Worker beantwortet Chat-Anfragen, solange das Hauptmodell
# für einen Bildauftrag entladen ist oder neu startet.
_reserve_host = _worker_ipv4() if CFG["reserve"]["enabled"] else ""
RESERVE_URL = os.environ.get("SSCCC_RESERVE_URL") or (
    f"http://{_reserve_host}:{CFG['reserve']['port']}" if _reserve_host else "")
RESERVE_NAME = CFG["reserve"]["name"]

app = FastAPI(title="SS-CCC Gateway")
_llm_proc: subprocess.Popen | None = None
_llm_ready = asyncio.Event()
_gpu_lock = asyncio.Lock()          # exklusiver GPU-Zugriff für Bildaufträge
_stats = {"images": 0, "last_image_s": None, "llm_starts": 0, "started": time.time()}
_client = httpx.AsyncClient(timeout=httpx.Timeout(None, connect=10))
TELEMETRY = telemetry.Telemetry()
SCHED = image_queue.ImageScheduler(idle_s=float(CFG["image"].get("idle_wait_s", 30)),
                                   max_wait_s=float(CFG["image"].get("max_wait_s", 300)))
_batch_images = False               # weitere Bilder warten -> Sprachmodell bleibt entladen
_large_sem = asyncio.Semaphore(1)   # große Anfragen nacheinander (Speicherschutz)
API_KEY = str(CFG.get("api_key") or os.environ.get("SSCCC_API_KEY") or "")
_tokenizer = None


def _limits() -> request_guard.Limits:
    kv = 0.0
    try:
        conf = json.loads((Path(LLM_MODEL) / "config.json").read_text())
        kv = request_guard.kv_bytes_per_token(conf, int(CFG["llm"].get("kv_bits", 8)))
    except Exception:
        pass
    return request_guard.Limits(context=int(CFG["llm"]["context"]),
                                large_prompt=int(CFG["llm"].get("large_prompt", 32768)),
                                kv_bytes_per_token=kv)


LIMITS = _limits()


def _gpu_free_bytes() -> int | None:
    try:
        import psutil
        return int(psutil.virtual_memory().available)
    except Exception:
        return None


def _load_tokenizer():
    global _tokenizer
    try:
        from transformers import AutoTokenizer
        _tokenizer = AutoTokenizer.from_pretrained(LLM_MODEL)
        log("Tokenizer für die Speicherwarnung geladen")
    except Exception as e:
        log(f"Tokenizer nicht verfügbar ({e}) – Token werden geschätzt")


def log(msg: str) -> None:
    print(f"[SS-CCC Gateway] {time.strftime('%H:%M:%S')} {msg}", file=sys.stderr, flush=True)


# ── Sprachmodell-Unterprozess ────────────────────────────────────────────────
def _prefix_cache_env() -> dict:
    """Präfix-Cache (APC) von mlx-vlm: Agenten schicken bei jedem Schritt dieselben
    20–45k Token Anweisungen und Verlauf – mit Cache wird nur der neue Teil berechnet."""
    pc = CFG["llm"].get("prefix_cache") or {}
    if not pc.get("enabled"):
        return {"APC_ENABLED": "0"}
    return {"APC_ENABLED": "1", "APC_DEFAULT_TENANT": "ssccc",
            "APC_MEMORY_MAX_GB": str(pc.get("memory_gb", 4)),
            "APC_MEMORY_RESERVE_GB": str(pc.get("reserve_gb", 1)),
            "APC_NUM_BLOCKS": str(max(2048, int(pc.get("max_tokens", 131072)) // 16)),
            "APC_DISK_ENABLED": "1" if pc.get("disk_gb", 0) else "0",
            "APC_DISK_MAX_GB": str(pc.get("disk_gb", 20)),
            "APC_DISK_PATH": str(B / "apc-cache"),
            "APC_DISK_NAMESPACE": Path(LLM_MODEL).parent.parent.name or "default"}


def _kill_stale_llm() -> None:
    """Beendet verwaiste Modellserver vom letzten Gateway-Lauf (launchd beendet beim
    Neustart nur das Gateway, nicht dessen Kindprozess – der hielt sonst Speicher)."""
    try:
        pids = subprocess.run(["lsof", "-ti", f"tcp:{LLM_PORT}", "-sTCP:LISTEN"],
                              capture_output=True, text=True, timeout=5).stdout.split()
        pids += subprocess.run(["pgrep", "-f", f"(mlx_vlm[.]server|vlm_server[.]py) .*--port {LLM_PORT}"],
                               capture_output=True, text=True, timeout=5).stdout.split()
    except (OSError, subprocess.SubprocessError):
        return
    own = {str(_llm_proc.pid)} if _llm_proc else set()
    for pid in set(pids) - own:
        try:
            os.kill(int(pid), 9)
            log(f"Verwaisten Modellserver beendet (PID {pid})")
        except (ProcessLookupError, ValueError, PermissionError):
            pass


async def start_llm() -> None:
    global _llm_proc
    _llm_ready.clear()
    _kill_stale_llm()
    # vlm_server.py startet mlx_vlm.server mit SS-CCC-Korrekturen (Kaltstart-Rückfall des Prefix-Caches)
    launcher = [str(B / "vlm_server.py")] if (B / "vlm_server.py").exists() else ["-m", "mlx_vlm.server"]
    cmd = [str(B / "venv-vlm/bin/python"), *launcher, "--host", "127.0.0.1",
           "--port", str(LLM_PORT), "--model", LLM_MODEL,
           "--prefill-step-size", str(CFG["llm"].get("prefill_step", 1024)),
           # Speicherschutz: wenige gleichzeitige Sequenzen und 8-Bit-KV-Cache. Ohne das
           # lief der GPU-Speicher bei einer 89k-Token-Anfrage plus parallelen Anfragen
           # über ("Insufficient Memory") und der Server hing danach.
           "--max-num-seqs", str(CFG["llm"].get("max_num_seqs", 2)),
           ] + (["--kv-bits", str(CFG["llm"]["kv_bits"])] if CFG["llm"].get("kv_bits", 8) else [])
    if LLM_DRAFT:
        cmd += ["--draft-model", LLM_DRAFT, "--draft-kind", "mtp"]
    logf = open(B / "llm.log", "a")
    _llm_proc = subprocess.Popen(cmd, stdout=logf, stderr=subprocess.STDOUT,
                                 env={**os.environ, "HF_HOME": str(B / "hf"), **_prefix_cache_env()})
    _stats["llm_starts"] += 1
    log(f"Sprachmodell startet (PID {_llm_proc.pid}, MTP={'an' if LLM_DRAFT else 'aus'})")
    # Bereit, sobald das Modell geladen ist (Server antwortet vorher schon mit 503)
    for _ in range(600):
        if _llm_proc.poll() is not None:
            log("Sprachmodell-Prozess beendet sich unerwartet – Gateway beendet sich (launchd startet neu)")
            os._exit(1)
        try:
            r = await _client.post(f"{LLM_URL}/v1/chat/completions", json={
                "model": LLM_MODEL, "max_tokens": 1,
                "messages": [{"role": "user", "content": "ok"}]}, timeout=30)
            if r.status_code == 200:
                _llm_ready.set()
                log("Sprachmodell bereit")
                return
        except httpx.HTTPError:
            pass
        await asyncio.sleep(1)
    log("Sprachmodell wurde nicht rechtzeitig bereit – Gateway beendet sich")
    os._exit(1)


async def stop_llm() -> None:
    global _llm_proc
    _llm_ready.clear()
    if _llm_proc and _llm_proc.poll() is None:
        _llm_proc.terminate()
        try:
            await asyncio.wait_for(asyncio.to_thread(_llm_proc.wait), 30)
        except asyncio.TimeoutError:
            _llm_proc.kill()
    _llm_proc = None
    log("Sprachmodell entladen")


@app.on_event("startup")
async def _startup():
    asyncio.create_task(start_llm())
    asyncio.create_task(_status_loop())
    asyncio.create_task(asyncio.to_thread(_load_tokenizer))
    try:
        globals()["_llm_log_pos"] = (B / "llm.log").stat().st_size
    except OSError:
        pass
    asyncio.create_task(_watchdog())


@app.on_event("shutdown")
async def _shutdown():
    if _llm_proc and _llm_proc.poll() is None:
        _llm_proc.terminate()


# ── Bild auf Abruf ───────────────────────────────────────────────────────────
# HiDream-O1 ist nativ auf ~4 MP trainiert (2048², 2560×1440, 3104×1312 …). Andere
# Größen werden auf das nächste trainierte Seitenverhältnis gesetzt; nur 1024×1024
# wird als schnelle Vorschau ohne Umrechnung erzeugt (gemessen M5 Max: ~12 s statt ~50 s).
DEFAULT_SIZE = "2048x2048"
FAST_SIZE = "1024x1024"


def _run_hidream(prompt: str, w: int, h: int, seed: int, steps: int, refs: list[str]) -> Path:
    out = OUT_DIR / f"{time.strftime('%Y%m%d-%H%M%S')}-{uuid.uuid4().hex[:6]}.png"
    cmd = [IMG_PY, IMG_SCRIPT, "--model-path", IMG_MODEL, "--prompt", prompt,
           "--output", str(out), "--width", str(w), "--height", str(h),
           "--num-inference-steps", str(steps), "--seed", str(seed)]
    if f"{w}x{h}" == FAST_SIZE:
        cmd.append("--no-snap-resolution")
    if refs:
        cmd += ["--ref-images", *refs]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=IMG_MODEL)
    if r.returncode != 0 or not out.exists():
        raise RuntimeError((r.stderr or r.stdout)[-2000:])
    return out


async def _image_job(prompt, w, h, n, steps, seed0, fmt, refs, urgent=False, label="Bild"):
    """Bildauftrag über die Warteschlange: erst Leerlauf abwarten, dann am Stück erzeugen."""
    global _batch_images
    waited = await SCHED.wait_turn(urgent=urgent or _batch_images)
    if waited > 1:
        log(f"{label}: {waited:.0f} s auf Leerlauf gewartet")
    async with _gpu_lock:
        SCHED.running += 1
        t0 = time.time()
        if _llm_proc is not None:
            await stop_llm()
        data = []
        try:
            for i in range(n):
                log(f"{label} {i + 1}/{n} {w}x{h}" + (f" mit {len(refs)} Referenz(en)" if refs else "") + f": {prompt[:60]!r}")
                path = await asyncio.to_thread(_run_hidream, prompt, w, h, seed0 + i, steps, refs)
                item = {"revised_prompt": prompt, "ssccc_file": str(path), "url_path": f"/ssccc/bilder/{path.name}"}
                if fmt == "url":
                    item["url"] = f"/ssccc/bilder/{path.name}"
                else:
                    item["b64_json"] = base64.b64encode(path.read_bytes()).decode()
                data.append(item)
        except Exception as e:
            log(f"{label}fehler: {e}")
            raise HTTPException(500, f"{label} fehlgeschlagen: {str(e)[-500:]}")
        finally:
            SCHED.running -= 1
            _stats["images"] += len(data)
            _stats["last_image_s"] = round(time.time() - t0, 1)
            TELEMETRY.count("images", len(data))
            # Warten weitere Bilder, bleibt das Sprachmodell entladen (spart je ~10 s Neuladen)
            _batch_images = SCHED.waiting > 0
            if not _batch_images:
                asyncio.create_task(start_llm())
    return {"created": int(time.time()), "model": IMG_NAME, "data": data, "queue_wait_s": round(waited, 1)}


@app.post("/v1/images/generations")
async def images_generations(req: Request):
    if not IMG_ENABLED:
        raise HTTPException(404, "Bilderzeugung ist in cluster.json abgeschaltet")
    body = await req.json()
    prompt = (body.get("prompt") or "").strip()
    if not prompt:
        raise HTTPException(400, "prompt fehlt")
    # Höchste Qualität als Standard: Größen werden nur als Seitenverhältnis gelesen
    # und auf die native ~4-MP-Auflösung gesetzt. Schnelle 1024²-Vorschau nur mit
    # "quality": "low"/"draft".
    size = str(body.get("size") or "auto").lower()
    try:
        w, h = (int(x) for x in size.split("x"))
    except ValueError:
        w, h = (int(x) for x in DEFAULT_SIZE.split("x"))
    if body.get("quality") in ("low", "draft"):
        w, h = (int(x) for x in FAST_SIZE.split("x"))
    elif f"{w}x{h}" == FAST_SIZE:
        w, h = (int(x) for x in DEFAULT_SIZE.split("x"))
    n = max(1, min(int(body.get("n") or 1), 4))
    steps = int(body.get("steps") or 28)
    seed0 = int(body.get("seed") or int(time.time()) % 100000)
    fmt = body.get("response_format") or "b64_json"
    return await _image_job(prompt, w, h, n, steps, seed0, fmt, [], urgent=body.get("priority") == "now")


def _save_ref(data: bytes, tmpdir: str, i: int) -> str:
    """Referenzbild normalisieren (RGB-PNG) und ablegen; gibt Pfad zurück."""
    from io import BytesIO

    from PIL import Image

    img = Image.open(BytesIO(data)).convert("RGB")
    p = os.path.join(tmpdir, f"ref{i}.png")
    img.save(p)
    return p


@app.post("/v1/images/edits")
async def images_edits(req: Request):
    """Bildbearbeitung (1 Referenz) bzw. Mehrfach-Referenz-Komposition (2–3 Referenzen).

    Akzeptiert OpenAI-Multipart (`image` bzw. `image[]`, `prompt`, `size`, `n`) oder
    JSON (`prompt`, `images`: Liste aus Base64-Strings oder Pfaden aus /ssccc/bilder).
    Ohne `size` wird das Seitenverhältnis des ersten Referenzbilds übernommen.
    """
    from PIL import Image

    ctype = req.headers.get("content-type", "")
    blobs: list[bytes] = []
    if ctype.startswith("multipart/"):
        form = await req.form()
        body = {k: v for k, v in form.items() if isinstance(v, str)}
        for key in ("image", "image[]", "images", "images[]"):
            for f in form.getlist(key):
                if hasattr(f, "read"):
                    blobs.append(await f.read())
    else:
        body = await req.json()
        for item in body.get("images") or ([body["image"]] if body.get("image") else []):
            if isinstance(item, dict):
                item = item.get("b64_json") or item.get("url") or ""
            if item.startswith("/ssccc/bilder/") or item.startswith(str(OUT_DIR)):
                blobs.append((OUT_DIR / Path(item).name).read_bytes())
            else:
                blobs.append(base64.b64decode(item.split(",", 1)[-1]))
    prompt = (body.get("prompt") or "").strip()
    if not prompt or not blobs:
        raise HTTPException(400, "prompt und mindestens ein Bild (image) sind nötig")
    if len(blobs) > 3:
        raise HTTPException(400, "höchstens 3 Referenzbilder")
    n = max(1, min(int(body.get("n") or 1), 4))
    seed0 = int(body.get("seed") or int(time.time()) % 100000)
    steps = int(body.get("steps") or 28)
    fmt = body.get("response_format") or "b64_json"

    with tempfile.TemporaryDirectory() as tmp:
        refs = [_save_ref(b, tmp, i) for i, b in enumerate(blobs)]
        size = str(body.get("size") or "auto").lower()
        try:
            w, h = (int(x) for x in size.split("x"))
        except ValueError:
            w, h = Image.open(refs[0]).size        # Seitenverhältnis der Vorlage
        return await _image_job(prompt, w, h, n, steps, seed0, fmt, refs,
                                urgent=body.get("priority") == "now", label="Bearbeitung")


@app.get("/ssccc/bilder/{name}")
async def bild(name: str):
    p = OUT_DIR / Path(name).name
    if not p.exists():
        raise HTTPException(404)
    return Response(p.read_bytes(), media_type="image/png")


# ── Status ───────────────────────────────────────────────────────────────────
_status: dict = {"nodes": []}


def _link_label() -> str:
    """Verbindung zum Worker: Thunderbolt-Bridge, LAN-Kabel oder WLAN."""
    if not WORKER_SSH:
        return "Einzelrechner"
    try:
        ip = _worker_ipv4()
        out = subprocess.run(["/sbin/route", "-n", "get", ip], capture_output=True, text=True, timeout=5).stdout
        iface = next((l.split(":")[1].strip() for l in out.splitlines() if "interface:" in l), "")
        if iface.startswith("bridge"):
            return "Thunderbolt"
        hw = subprocess.run(["/usr/sbin/networksetup", "-listallhardwareports"], capture_output=True, text=True, timeout=5).stdout
        port = ""
        for block in hw.split("\n\n"):
            if f"Device: {iface}" in block:
                port = block.splitlines()[0].replace("Hardware Port: ", "")
        return "WLAN" if "Wi-Fi" in port else ("LAN-Kabel" if iface else "unbekannt")
    except Exception:
        return "unbekannt"


def _collect_status() -> dict:
    nodes = []
    hosts = [("127.0.0.1", "Sprache + Bild (Rank 0)" if IMG_ENABLED else "Sprache (Rank 0)")]
    if WORKER_SSH:
        hosts.append((WORKER_SSH, "Reserve (Rank 1)"))
    for rank, (host, role) in enumerate(hosts):
        cmd = [str(B / "node_info.sh")] if host == "127.0.0.1" else [
            "/usr/bin/ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=5", host, str(B / "node_info.sh")]
        try:
            info = json.loads(subprocess.run(cmd, capture_output=True, text=True, timeout=30).stdout)
            info["online"] = True
        except Exception:
            info = {"name": host, "online": False}
        info.update(rank=rank, role=role, layers=64 if rank == 0 else 0,
                    ssh_ok=bool(info.get("online")),
                    ring_ok=True if rank == 0 else bool(info.get("online")),
                    wired_ok=int(info.get("wired_limit_mb") or 0) > 0)
        if rank == 1:
            info["model_ok"] = True   # im Multi-Model-Mode braucht die Reserve kein Modell
        nodes.append(info)
    return {"cluster": "SS-CCC Multi-Model-Mode", "mode": "multimodel",
            "backend": "mlx-vlm" + (" (MTP)" if LLM_DRAFT else "") + (f" + {IMG_NAME} auf Abruf" if IMG_ENABLED else ""),
            "link": _link_label(),
            "model": LLM_NAME, "image_model": IMG_NAME, "total_layers": 64,
            "endpoint_port": 8000, "nodes": nodes}


_llm_log_pos = 0
_FATAL = ("Insufficient Memory", "OutOfMemory", "generation thread died", "Command buffer execution failed")


async def _watchdog():
    """Neustart, wenn das Sprachmodell abgestürzt ist, aber der Prozess noch läuft.

    mlx-vlm beendet sich bei einem GPU-Speicherfehler nicht, antwortet aber nicht mehr.
    Das Gateway liest deshalb das Protokoll mit und startet das Modell bei einem
    schweren Fehler neu (laufende Anfragen gehen verloren, neue funktionieren wieder).
    """
    global _llm_log_pos
    logf = B / "llm.log"
    while True:
        await asyncio.sleep(10)
        try:
            size = logf.stat().st_size
            if size < _llm_log_pos:
                _llm_log_pos = 0
            if size > _llm_log_pos:
                with open(logf, "rb") as f:
                    f.seek(_llm_log_pos)
                    new = f.read().decode(errors="ignore")
                _llm_log_pos = size
                if _llm_ready.is_set() and not _gpu_lock.locked() and any(k in new for k in _FATAL):
                    log("Sprachmodell meldet schweren Fehler (GPU-Speicher) – automatischer Neustart")
                    _stats["llm_crash_restarts"] = _stats.get("llm_crash_restarts", 0) + 1
                    async with _gpu_lock:
                        await stop_llm()
                        await start_llm()
        except Exception as e:  # Wächter darf nie selbst ausfallen
            log(f"Wächter-Fehler: {e}")


async def _status_loop():
    while True:
        try:
            _status.update(await asyncio.to_thread(_collect_status))
        except Exception as e:
            log(f"Status-Fehler: {e}")
        await asyncio.sleep(20)


@app.get("/ssccc/cluster")
async def cluster():
    return dict(_status, llm_ready=_llm_ready.is_set(), image_busy=_gpu_lock.locked(),
                uptime_s=int(time.time() - _stats["started"]), stats=_stats, updated=int(time.time()))


@app.get("/health")
async def health():
    return {"status": "ok", "llm_ready": _llm_ready.is_set(), "image_busy": _gpu_lock.locked()}


@app.get("/v1/models")
async def models():
    # Kontextangaben in mehreren üblichen Feldnamen – manche Clients brechen ohne sie ab.
    ctx, out = int(CFG["llm"]["context"]), int(CFG["llm"]["max_output"])
    return {"object": "list", "data": [
        {"id": LLM_NAME, "object": "model", "owned_by": "ss-ccc", "created": int(_stats["started"]),
         "display_name": CFG["llm"]["display_name"],
         "context_window": ctx, "context_length": ctx, "max_context_tokens": ctx, "max_input_tokens": ctx,
         "max_output_tokens": out, "max_tokens": out,
         "capabilities": {"tools": True, "vision": True, "reasoning": True}}]}


# ── Durchreichen aller übrigen /v1-Anfragen an das Sprachmodell ─────────────
async def _reserve_ok() -> bool:
    if not RESERVE_URL:
        return False
    try:
        r = await _client.get(f"{RESERVE_URL}/health", timeout=2)
        return r.status_code == 200
    except httpx.HTTPError:
        return False


async def pick_target(what: str = "Chat") -> tuple[str, str]:
    """Hauptmodell, sonst Reserve auf dem Mac mini, sonst warten."""
    if _llm_ready.is_set():
        return LLM_URL, LLM_MODEL
    if await _reserve_ok():
        _stats["reserve_requests"] = _stats.get("reserve_requests", 0) + 1
        log(f"Hauptmodell belegt – {what} geht an {RESERVE_NAME}")
        return RESERVE_URL, "default_model"
    try:
        await asyncio.wait_for(_llm_ready.wait(), 900)
    except asyncio.TimeoutError:
        raise HTTPException(503, "Sprachmodell nicht bereit")
    return LLM_URL, LLM_MODEL



GUARDED_PATHS = ("chat/completions", "responses", "completions", "messages")


def apply_default_output(body: dict, path: str) -> bool:
    """Setzt eine Antwortlänge, wenn der Client keine angibt.

    mlx-vlm begrenzt Antworten ohne Angabe auf 2048 Tokens. Denkende Modelle
    verbrauchen das oft schon vor der eigentlichen Antwort, sodass Antworten
    und Zusammenfassungen abgeschnitten werden (finish_reason=length). Die
    Speicherprüfung kürzt den Wert danach bei Bedarf auf das, was passt."""
    keys = ("max_tokens", "max_completion_tokens", "max_output_tokens")
    if any(body.get(k) for k in keys):
        return False
    key = "max_output_tokens" if path.startswith("responses") else "max_tokens"
    body[key] = int(CFG["llm"].get("default_max_tokens", 16384))
    return True


def guard_request(body: dict, path: str):
    """Speicherwarnung: (fehler_response | None, info). Passt ggf. max_tokens an."""
    if not isinstance(body, dict) or not path.startswith(GUARDED_PATHS):
        return None, {}
    apply_default_output(body, path)
    tokens = request_guard.estimate_tokens(body, _tokenizer)
    ok, err, info = request_guard.check(body, tokens, LIMITS, _gpu_free_bytes())
    if not ok:
        TELEMETRY.count("rejected")
        log(f"Anfrage abgelehnt (~{tokens} Token): {err['body']['error']['code']}")
        return JSONResponse(err["body"], status_code=err["status"]), info
    if info.get("clamped_output"):
        for key in ("max_tokens", "max_completion_tokens", "max_output_tokens"):
            if body.get(key):
                body[key] = info["clamped_output"]
        TELEMETRY.count("clamped")
    return None, info



def soften_response_format(body: dict) -> bool:
    """Wandelt ``response_format`` (JSON/Schema) in eine Anweisung um.

    mlx-vlm lehnt strukturierte Ausgabe bei aktivem MTP (spekulativem Dekodieren)
    ab („Structured response_format is not supported with speculative decoding“).
    Clients nutzen sie für Hilfsaufgaben (Titel, Klassifizierung) und bekämen
    sonst einen Fehler. Das Modell erhält stattdessen die Vorgabe als
    Systemanweisung."""
    fmt = body.get("response_format")
    if not isinstance(fmt, dict) or fmt.get("type") not in ("json_object", "json_schema"):
        return False
    body.pop("response_format", None)
    text = "Antworte ausschließlich mit gültigem JSON, ohne Erklärung und ohne Markdown."
    schema = (fmt.get("json_schema") or {}).get("schema") if fmt.get("type") == "json_schema" else None
    if schema:
        text += " Das JSON muss diesem Schema entsprechen: " + json.dumps(schema, ensure_ascii=False)
    msgs = body.get("messages")
    if isinstance(msgs, list):
        if msgs and isinstance(msgs[0], dict) and msgs[0].get("role") == "system" \
                and isinstance(msgs[0].get("content"), str):
            msgs[0] = {**msgs[0], "content": msgs[0]["content"] + "\n\n" + text}
        else:
            msgs.insert(0, {"role": "system", "content": text})
    return True


@app.api_route("/v1/{path:path}", methods=["GET", "POST"])
async def proxy(path: str, req: Request):
    raw = await req.body()
    body = None
    stream = False
    if raw and req.method == "POST":
        try:
            body = json.loads(raw)
        except json.JSONDecodeError:
            body = None
    # 1) Speicherwarnung vor dem Weiterreichen
    info = {}
    if isinstance(body, dict):
        rejected, info = guard_request(body, path)
        if rejected is not None:
            return rejected
    # 2) Ziel wählen (Hauptmodell, Reserve oder warten)
    target, target_model = await pick_target(f"Anfrage /v1/{path}")
    if isinstance(body, dict):
        if "model" in body:
            body["model"] = target_model           # jeder Name -> geladenes Modell
        stream = bool(body.get("stream"))
        if LLM_DRAFT and target == LLM_URL and path.startswith("chat/completions"):
            soften_response_format(body)
        if stream and path.startswith("chat/completions"):
            body.setdefault("stream_options", {"include_usage": True})
        raw = json.dumps(body).encode()
    headers = {"Content-Type": req.headers.get("content-type", "application/json")}
    is_chat = req.method == "POST" and path.startswith(GUARDED_PATHS)
    large = bool(info.get("large"))
    if is_chat:
        SCHED.chat_started()
    if large:
        await _large_sem.acquire()                   # große Anfragen nacheinander
    t0 = time.time()

    def finish(ttft, tokens, ok=True):
        if large:
            _large_sem.release()
        if is_chat:
            SCHED.chat_finished()
            TELEMETRY.record(path=path, ttft=ttft, duration=time.time() - t0, tokens=tokens,
                             prompt_tokens=info.get("prompt_tokens"), target="reserve" if target != LLM_URL else "main", ok=ok)

    try:
        upstream = _client.build_request(req.method, f"{target}/v1/{path}", content=raw,
                                         headers=headers, params=req.query_params)
        r = await _client.send(upstream, stream=True)
    except Exception:
        finish(None, 0, ok=False)
        raise
    if stream:
        async def gen():
            ttft, tokens, buf = None, 0, b""
            try:
                async for chunk in r.aiter_raw():
                    if is_chat:
                        buf += chunk
                        while b"\n" in buf:
                            line, buf = buf.split(b"\n", 1)
                            if not line.startswith(b"data:") or line.strip().endswith(b"[DONE]"):
                                continue
                            try:
                                d = json.loads(line[5:])
                            except ValueError:
                                continue
                            if d.get("usage") and d["usage"].get("completion_tokens"):
                                tokens = d["usage"]["completion_tokens"]
                            for ch in d.get("choices") or []:
                                if (ch.get("delta") or {}).get("content") and ttft is None:
                                    ttft = time.time() - t0
                                if (ch.get("delta") or {}).get("content") and not d.get("usage"):
                                    tokens += 1
                    yield chunk
            finally:
                await r.aclose()
                finish(ttft, tokens, ok=r.status_code == 200)
        return StreamingResponse(gen(), status_code=r.status_code,
                                 media_type=r.headers.get("content-type", "text/event-stream"))
    content = await r.aread()
    await r.aclose()
    tokens = 0
    if is_chat:
        try:
            tokens = json.loads(content).get("usage", {}).get("completion_tokens", 0)
        except Exception:
            pass
    finish(None, tokens, ok=r.status_code == 200)
    return Response(content, status_code=r.status_code,
                    media_type=r.headers.get("content-type", "application/json"))


# ── Verwaltung: Telemetrie, Betriebsart, Modellwechsel ───────────────────────
@app.get("/ssccc/metrics")
async def metrics():
    return dict(TELEMETRY.summary(), queue=SCHED.snapshot(), llm_ready=_llm_ready.is_set(),
                image_busy=_gpu_lock.locked(), stats=_stats, model=LLM_NAME,
                limits={"context": LIMITS.context, "large_prompt": LIMITS.large_prompt,
                        "kv_bytes_per_token": LIMITS.kv_bytes_per_token})


@app.post("/ssccc/mode")
async def set_mode(req: Request):
    """Betriebsart umschalten (multimodel | verbund). Der Dienst startet danach neu."""
    mode = (await req.json()).get("mode", "")
    if mode not in ("multimodel", "verbund"):
        raise HTTPException(400, "mode muss 'multimodel' oder 'verbund' sein")
    if mode == "verbund" and not WORKER_SSH:
        raise HTTPException(400, "Verbund braucht einen Worker-Mac in cluster.json")
    (B / "modus").write_text(mode + "\n")
    log(f"Betriebsart wird auf '{mode}' umgestellt – Neustart")

    async def restart():
        await asyncio.sleep(1)
        if _llm_proc and _llm_proc.poll() is None:
            _llm_proc.terminate()
        os._exit(1)                                  # launchd (KeepAlive) startet neu
    asyncio.create_task(restart())
    return {"ok": True, "mode": mode, "restart_s": 30}


MODEL_CATALOG = [
    {"repo": "mlx-community/Qwen3.8-27B-4bit", "draft_repo": "mlx-community/Qwen3.8-27B-MTP-4bit",
     "label": "Qwen3.8 27B · 4 Bit + MTP", "note": "Standard: schnell (≈170 Zeichen/s auf M5 Max)"},
    {"repo": "mlx-community/Qwen3.8-27B-oQ6", "draft_repo": "",
     "label": "Qwen3.8 27B · 6 Bit", "note": "bessere Qualität, deutlich langsamer"},
    {"repo": "mlx-community/Qwen3.6-35B-A3B-4bit", "draft_repo": "",
     "label": "Qwen3.6 35B-A3B · 4 Bit (MoE)", "note": "nur 3B aktive Parameter – sehr schnell"},
    {"repo": "mlx-community/gemma-4-26B-A4B-it-qat-4bit",
     "draft_repo": "mlx-community/gemma-4-26B-A4B-it-qat-assistant-4bit",
     "label": "Gemma 4 26B-A4B · 4 Bit QAT + Assistent",
     "note": "MoE mit 4B aktiven Parametern – sehr schnelle Eingabe, ab 24 GB RAM"},
    {"repo": "mlx-community/Qwen3.5-9B-4bit", "draft_repo": "",
     "label": "Qwen3.5 9B · 4 Bit", "note": "klein, für Macs mit 16 GB"},
]
_download = {"repo": None, "state": "idle", "done_bytes": 0, "total_bytes": 0, "error": None}
_size_cache: dict = {}


def _repo_size(repo: str) -> int:
    if repo in _size_cache:
        return _size_cache[repo]
    snap = ssccc_config.hf_snapshot(repo)
    if snap:
        size = sum(f.stat().st_size for f in Path(snap).iterdir() if f.is_file() or f.is_symlink())
    else:
        try:
            r = httpx.get(f"https://huggingface.co/api/models/{repo}?blobs=true", timeout=15)
            size = sum(s.get("size", 0) for s in r.json().get("siblings", []))
        except Exception:
            size = 0
    _size_cache[repo] = size
    return size


def _gpu_limit_bytes() -> int:
    try:
        mb = int(subprocess.run(["/usr/sbin/sysctl", "-n", "iogpu.wired_limit_mb"], capture_output=True,
                                text=True, timeout=5).stdout.strip() or 0)
    except Exception:
        mb = 0
    if mb:
        return mb << 20
    import psutil
    return int(psutil.virtual_memory().total * 0.70)


def _fits(size: int) -> dict:
    limit = _gpu_limit_bytes()
    need = size + int(32768 * max(LIMITS.kv_bytes_per_token, 32768)) + (2 << 30)
    return {"fits": need <= limit, "need_gb": round(need / 2**30, 1), "limit_gb": round(limit / 2**30, 1)}


@app.get("/ssccc/models")
async def list_models():
    out = []
    for m in MODEL_CATALOG:
        size = await asyncio.to_thread(_repo_size, m["repo"])
        draft = await asyncio.to_thread(_repo_size, m["draft_repo"]) if m["draft_repo"] else 0
        out.append(dict(m, size_gb=round((size + draft) / 2**30, 1),
                        installed=bool(ssccc_config.hf_snapshot(m["repo"])),
                        active=m["repo"] == CFG["llm"]["repo"], **_fits(size + draft)))
    return {"current": CFG["llm"]["repo"], "models": out, "download": _download}


async def _download_and_switch(repo: str, draft: str):
    global LLM_MODEL, LLM_DRAFT, LLM_NAME, LIMITS, _tokenizer
    total = _repo_size(repo) + (_repo_size(draft) if draft else 0)
    _download.update(repo=repo, state="download", done_bytes=0, total_bytes=total, error=None)
    env = {**os.environ, "HF_HOME": str(B / "hf"), "HF_HUB_DISABLE_XET": "1"}
    try:
        for r_ in [repo] + ([draft] if draft else []):
            if ssccc_config.hf_snapshot(r_):
                continue
            for attempt in range(5):
                proc = await asyncio.create_subprocess_exec(str(B / "venv/bin/hf"), "download", r_, "--max-workers", "8",
                                                            env=env, stdout=asyncio.subprocess.DEVNULL,
                                                            stderr=asyncio.subprocess.DEVNULL)
                while proc.returncode is None:
                    await asyncio.sleep(3)
                    try:
                        await asyncio.wait_for(proc.wait(), 0.1)
                    except asyncio.TimeoutError:
                        pass
                    blobs = B / "hf/hub/blobs"
                    now = sum(f.stat().st_size for f in blobs.glob("*") if f.is_file()) if blobs.exists() else 0
                    _download["done_bytes"] = max(0, min(total, now - _download.get("_base", 0)))
                if proc.returncode == 0:
                    break
        _download["state"] = "switch"
        data = json.loads((B / "cluster.json").read_text()) if (B / "cluster.json").exists() else {}
        data.setdefault("llm", {}).update(repo=repo, draft_repo=draft)
        (B / "cluster.json").write_text(json.dumps(data, indent=2, ensure_ascii=False))
        CFG["llm"].update(repo=repo, draft_repo=draft)
        LLM_MODEL = ssccc_config.hf_snapshot(repo)
        LLM_DRAFT = ssccc_config.hf_snapshot(draft) if draft else ""
        LLM_NAME = repo
        LIMITS = _limits()
        _tokenizer = None
        async with _gpu_lock:
            await stop_llm()
            await start_llm()
        await asyncio.to_thread(_load_tokenizer)
        _download.update(state="done")
        log(f"Sprachmodell gewechselt auf {repo}")
    except Exception as e:
        _download.update(state="error", error=str(e)[-300:])
        log(f"Modellwechsel fehlgeschlagen: {e}")


@app.post("/ssccc/models/select")
async def select_model(req: Request):
    body = await req.json()
    repo = body.get("repo", "")
    entry = next((m for m in MODEL_CATALOG if m["repo"] == repo), None)
    if not entry:
        raise HTTPException(400, "Unbekanntes Modell (nur Modelle aus GET /ssccc/models)")
    if _download["state"] in ("download", "switch"):
        raise HTTPException(409, "Es läuft bereits ein Modellwechsel")
    draft = entry["draft_repo"]
    fit = _fits(await asyncio.to_thread(_repo_size, repo) + (await asyncio.to_thread(_repo_size, draft) if draft else 0))
    if not fit["fits"] and not body.get("force"):
        raise HTTPException(409, f"Passt nicht in den GPU-Speicher: ~{fit['need_gb']} GB nötig, {fit['limit_gb']} GB frei")
    try:
        blobs = B / "hf/hub/blobs"
        _download["_base"] = sum(f.stat().st_size for f in blobs.glob("*") if f.is_file()) if blobs.exists() else 0
    except Exception:
        _download["_base"] = 0
    asyncio.create_task(_download_and_switch(repo, draft))
    return {"ok": True, "repo": repo, **fit}


@app.get("/ssccc/models/progress")
async def model_progress():
    d = {k: v for k, v in _download.items() if not k.startswith("_")}
    d["percent"] = round(100 * d["done_bytes"] / d["total_bytes"], 1) if d.get("total_bytes") else None
    return d


# ── Zugriffsschutz (API-Schlüssel) ───────────────────────────────────────────
@app.middleware("http")
async def api_key_guard(request: Request, call_next):
    """Mit gesetztem api_key (cluster.json) braucht jede Anfrage außer /health den Schlüssel:
    Authorization: Bearer <key>, x-api-key oder ?key=<key>."""
    if API_KEY and request.url.path != "/health":
        auth = request.headers.get("authorization", "")
        given = (auth[7:] if auth.lower().startswith("bearer ") else "") or request.headers.get("x-api-key", "") \
            or request.query_params.get("key", "")
        if given != API_KEY:
            TELEMETRY.count("unauthorized")
            return JSONResponse({"error": {"message": "API-Schlüssel fehlt oder ist falsch", "type": "invalid_request_error",
                                           "code": "invalid_api_key"}}, status_code=401)
    return await call_next(request)


if __name__ == "__main__":
    import uvicorn

    tls = CFG.get("tls") or {}
    ssl = {"ssl_certfile": tls["cert"], "ssl_keyfile": tls["key"]} if tls.get("cert") and tls.get("key") else {}
    uvicorn.run(app, host="0.0.0.0", port=int(CFG["gateway_port"]), log_level="warning", **ssl)
