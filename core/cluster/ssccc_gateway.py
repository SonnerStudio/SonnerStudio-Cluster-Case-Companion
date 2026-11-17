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
- Gemini-Protokoll (gemini_adapter.py) für Google Antigravity.
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
import ssccc_config  # noqa: E402

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


def log(msg: str) -> None:
    print(f"[SS-CCC Gateway] {time.strftime('%H:%M:%S')} {msg}", file=sys.stderr, flush=True)


# ── Sprachmodell-Unterprozess ────────────────────────────────────────────────
async def start_llm() -> None:
    global _llm_proc
    _llm_ready.clear()
    cmd = [str(B / "venv-vlm/bin/python"), "-m", "mlx_vlm.server", "--host", "127.0.0.1",
           "--port", str(LLM_PORT), "--model", LLM_MODEL, "--prefill-step-size", "512",
           # Speicherschutz: wenige gleichzeitige Sequenzen und 8-Bit-KV-Cache. Ohne das
           # lief der GPU-Speicher bei einer 89k-Token-Anfrage plus parallelen Anfragen
           # über ("Insufficient Memory") und der Server hing danach.
           "--max-num-seqs", str(CFG["llm"].get("max_num_seqs", 2)),
           "--kv-bits", str(CFG["llm"].get("kv_bits", 8))]
    if LLM_DRAFT:
        cmd += ["--draft-model", LLM_DRAFT, "--draft-kind", "mtp"]
    logf = open(B / "llm.log", "a")
    _llm_proc = subprocess.Popen(cmd, stdout=logf, stderr=subprocess.STDOUT,
                                 env={**os.environ, "HF_HOME": str(B / "hf")})
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

    async with _gpu_lock:
        t0 = time.time()
        await stop_llm()
        data = []
        try:
            for i in range(n):
                log(f"Bild {i + 1}/{n} {w}x{h}: {prompt[:60]!r}")
                path = await asyncio.to_thread(_run_hidream, prompt, w, h, seed0 + i, steps, [])
                item = {"revised_prompt": prompt, "ssccc_file": str(path)}
                if fmt == "url":
                    item["url"] = f"/ssccc/bilder/{path.name}"
                else:
                    item["b64_json"] = base64.b64encode(path.read_bytes()).decode()
                data.append(item)
        except Exception as e:
            log(f"Bildfehler: {e}")
            raise HTTPException(500, f"Bilderzeugung fehlgeschlagen: {str(e)[-500:]}")
        finally:
            _stats["images"] += len(data)
            _stats["last_image_s"] = round(time.time() - t0, 1)
            asyncio.create_task(start_llm())
    return {"created": int(time.time()), "model": IMG_NAME, "data": data}


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
        async with _gpu_lock:
            t0 = time.time()
            await stop_llm()
            data = []
            try:
                for i in range(n):
                    log(f"Bearbeitung {i + 1}/{n} mit {len(refs)} Referenz(en): {prompt[:60]!r}")
                    path = await asyncio.to_thread(_run_hidream, prompt, w, h, seed0 + i, steps, refs)
                    item = {"revised_prompt": prompt, "ssccc_file": str(path)}
                    if fmt == "url":
                        item["url"] = f"/ssccc/bilder/{path.name}"
                    else:
                        item["b64_json"] = base64.b64encode(path.read_bytes()).decode()
                    data.append(item)
            except Exception as e:
                log(f"Bearbeitungsfehler: {e}")
                raise HTTPException(500, f"Bildbearbeitung fehlgeschlagen: {str(e)[-500:]}")
            finally:
                _stats["images"] += len(data)
                _stats["last_image_s"] = round(time.time() - t0, 1)
                asyncio.create_task(start_llm())
    return {"created": int(time.time()), "model": IMG_NAME, "data": data}


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
    # Kontextangaben in mehreren üblichen Feldnamen – Antigravity (Gateway-Modus)
    # braucht sie, sonst bricht es mit "maxMessageTokens must be positive" ab.
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


# Gemini-Protokoll für Google Antigravity (/v1beta/models/...:streamGenerateContent)
import gemini_adapter  # noqa: E402

gemini_adapter.configure(pick_target=lambda: pick_target("Antigravity-Anfrage"), client=_client,
                         log=log, model_name=LLM_NAME)
app.include_router(gemini_adapter.router)


@app.api_route("/v1/{path:path}", methods=["GET", "POST"])
async def proxy(path: str, req: Request):
    # Hauptmodell nicht verfügbar (Bildauftrag / Neustart): an die Reserve auf dem
    # Mac mini weiterreichen; ist auch die nicht erreichbar, warten statt fehlschlagen.
    target, target_model = await pick_target(f"Anfrage /v1/{path}")
    raw = await req.body()
    stream = False
    if raw and req.method == "POST":
        try:
            body = json.loads(raw)
            if isinstance(body, dict) and "model" in body:
                body["model"] = target_model       # jeder Name -> geladenes Modell
            stream = bool(body.get("stream"))
            raw = json.dumps(body).encode()
        except json.JSONDecodeError:
            pass
    headers = {"Content-Type": req.headers.get("content-type", "application/json")}
    upstream = _client.build_request(req.method, f"{target}/v1/{path}", content=raw,
                                     headers=headers, params=req.query_params)
    r = await _client.send(upstream, stream=True)
    if stream:
        async def gen():
            async for chunk in r.aiter_raw():
                yield chunk
            await r.aclose()
        return StreamingResponse(gen(), status_code=r.status_code,
                                 media_type=r.headers.get("content-type", "text/event-stream"))
    content = await r.aread()
    await r.aclose()
    return Response(content, status_code=r.status_code,
                    media_type=r.headers.get("content-type", "application/json"))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(CFG["gateway_port"]), log_level="warning")
