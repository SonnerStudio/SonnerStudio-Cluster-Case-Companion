#!/usr/bin/env python3
"""SS-CCC Ersteinrichtung: prüfen, automatisch einrichten, Programme verbinden.

Läuft mit dem System-Python von macOS (3.9+, keine Zusatzpakete), damit es auch auf
einem frischen Mac startet. Alle Erfahrungen aus der manuellen Einrichtung von Mac
Studio M5 Max + Mac mini M4 stecken in den Prüfungen (siehe README.de.md).

  python3 ssccc_setup.py check [--json]          Bereitschaft prüfen
  python3 ssccc_setup.py apply [--json] [--only ID,ID] [--skip-models]
                                                 automatisch behebbare Punkte einrichten
  python3 ssccc_setup.py detect [--json]         Macs im Netz (Bonjour/SSH) auflisten
  python3 ssccc_setup.py secure                  API-Schlüssel erzeugen und alle Programme umstellen
  python3 ssccc_setup.py configure --worker-host H --worker-user U [--worker-name N]
                                                 Worker-Mac eintragen (cluster.json + ~/.ssh/config)

Jeder Prüfpunkt hat: id, mac, title, status (pass|warn|fail), detail, fix (auto|user|none)
und remediation (was zu tun ist). Mit --json gibt jede Zeile ein JSON-Objekt aus
(Fortschritt für die SS-CCC-App).
"""

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO_CLUSTER = Path(__file__).resolve().parent
HOME = Path(os.environ.get("SSCCC_HOME", "/Users/Shared/ssccc"))
SSH_ALIAS = "ssccc-worker"
DEPLOY_FILES = ["ssccc_config.py", "ssccc_gateway.py", "ssccc_server.py", "forward.py",
                "make_rank_shard.py", "vlm_server.py", "node_info.sh", "start_ssccc.sh", "start_verbund.sh"]
GATEWAY_LABEL = "de.sonnerstudio.ssccc-verbund"
JSON_OUT = False


# ── Hilfsfunktionen ──────────────────────────────────────────────────────────
def emit(obj):
    if JSON_OUT:
        print(json.dumps(obj, ensure_ascii=False), flush=True)
    else:
        kind = obj.get("type")
        if kind == "check":
            sym = {"pass": "✅", "warn": "⚠️ ", "fail": "❌"}[obj["status"]]
            print(f"{sym} [{obj['mac']}] {obj['title']}: {obj['detail']}", flush=True)
            if obj["status"] != "pass" and obj.get("remediation"):
                who = "automatisch (apply)" if obj["fix"] == "auto" else ("von dir" if obj["fix"] == "user" else "")
                print(f"      → {obj['remediation']}" + (f"  [{who}]" if who else ""), flush=True)
        elif kind == "step":
            print(f"▶ {obj['title']}: {obj.get('detail', '')}", flush=True)
        elif kind == "detect":
            print(f"Dieser Mac: {obj['self']}", flush=True)
            for c in obj["candidates"]:
                print(f"  gefunden: {c}  (Entfernte Anmeldung aktiv)", flush=True)
            if not obj["candidates"]:
                print("  keine weiteren Macs mit „Entfernte Anmeldung“ gefunden", flush=True)
        elif kind == "summary":
            print(f"\nErgebnis: {obj['state']}  ({obj['pass']} ok, {obj['warn']} Hinweise, {obj['fail']} Fehler)", flush=True)
        else:
            print(obj, flush=True)


def run(cmd, timeout=60, check=False, shell=False):
    r = subprocess.run(cmd, capture_output=True, text=True, errors="replace", timeout=timeout, shell=shell)
    if check and r.returncode != 0:
        raise RuntimeError((r.stderr or r.stdout).strip()[-500:])
    return r


def load_cfg():
    sys.path.insert(0, str(REPO_CLUSTER))
    import ssccc_config  # noqa: E402
    ssccc_config.HOME = HOME
    return ssccc_config, ssccc_config.load()


def worker_ssh(cfg):
    return cfg["worker"].get("ssh", "")


def ssh(cfg, command, timeout=60):
    return run(["/usr/bin/ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=6", worker_ssh(cfg), command],
               timeout=timeout)


def on(mac, cfg, command, timeout=60):
    """Befehl auf Leitrechner ('coordinator') oder Worker ('worker') ausführen."""
    if mac == "coordinator":
        return run(["/bin/sh", "-c", command], timeout=timeout)
    return ssh(cfg, command, timeout=timeout)


def mac_name(mac, cfg):
    return cfg["coordinator"]["name"] if mac == "coordinator" else cfg["worker"]["name"]


def check(id_, mac, cfg, title, status, detail, fix="none", remediation=""):
    item = {"type": "check", "id": id_, "mac": mac_name(mac, cfg), "role": mac, "title": title,
            "status": status, "detail": detail, "fix": fix, "remediation": remediation}
    emit(item)
    return item


def mac_hw(mac, cfg):
    out = on(mac, cfg, "sysctl -n hw.memsize machdep.cpu.brand_string; df -k /System/Volumes/Data | awk 'NR==2{print $4}'").stdout.split("\n")
    try:
        return {"ram_gb": int(out[0]) / 2**30, "chip": out[1], "free_gb": int(out[2]) / 2**20}
    except (ValueError, IndexError):
        return {"ram_gb": 0, "chip": "?", "free_gb": 0}


def recommended_wired_mb(ram_gb):
    """Schutzreserve für macOS: 4 GB bis 24 GB RAM, 6 GB bis 64 GB, sonst 8 GB."""
    reserve = 4 if ram_gb <= 24 else (6 if ram_gb <= 64 else 8)
    return int((ram_gb - reserve) * 1024)


# ── Prüfungen ────────────────────────────────────────────────────────────────
def checks(cfg):
    results = []
    has_worker = bool(worker_ssh(cfg))
    macs = ["coordinator"] + (["worker"] if has_worker else [])

    # SSH zum Worker (Voraussetzung für alle Worker-Prüfungen)
    worker_ok = False
    if has_worker:
        r = ssh(cfg, "echo ok", timeout=20)
        worker_ok = r.returncode == 0 and "ok" in r.stdout
        host = cfg["worker"].get("host", "")
        results.append(check(
            "ssh_worker", "coordinator", cfg, "SSH ohne Passwort zum Worker",
            "pass" if worker_ok else "fail",
            f"{worker_ssh(cfg)} erreichbar" if worker_ok else f"{worker_ssh(cfg)} ({host}) nicht erreichbar: {(r.stderr or '').strip()[-120:]}",
            "user", f"Auf dem Worker „Entfernte Anmeldung“ einschalten, dann im Terminal: ssh-copy-id -i ~/.ssh/id_ed25519.pub <benutzer>@{host} (Passwort eingeben)"))
    else:
        results.append(check("worker", "coordinator", cfg, "Worker-Mac", "warn", "kein Worker in cluster.json – Einzelrechner-Betrieb",
                             "user", "Zweiten Mac eintragen: ssccc_setup.py detect, dann configure --worker-host … --worker-user …"))

    for mac in macs:
        if mac == "worker" and not worker_ok:
            continue
        hw = mac_hw(mac, cfg)
        # Xcode-Lizenz (ohne sie starten python3/swiftc nicht)
        r = on(mac, cfg, "xcodebuild -license check >/dev/null 2>&1 && echo ok || (xcrun --find swiftc >/dev/null 2>&1 && echo ok || echo nein)")
        results.append(check("xcode_license", mac, cfg, "Xcode-Lizenz / Befehlszeilenwerkzeuge",
                             "pass" if "ok" in r.stdout else "warn",
                             "bestätigt" if "ok" in r.stdout else "nicht bestätigt (python3/swiftc blockiert)",
                             "user", "Im Terminal: sudo xcodebuild -license accept (Admin-Passwort)"))
        # Speicherplatz
        need = 60 if mac == "coordinator" else 12
        st = "pass" if hw["free_gb"] >= need else ("warn" if hw["free_gb"] >= need / 3 else "fail")
        results.append(check("disk", mac, cfg, "Freier Speicherplatz", st,
                             f"{hw['free_gb']:.0f} GB frei (empfohlen ≥ {need} GB)", "user",
                             "Platz schaffen (Caches, alte Modelle) – Modelle und Umgebung brauchen diesen Platz"))
        # Gemeinsamer Ordner + Umgebungen
        r = on(mac, cfg, f"test -w {HOME} && test -x {HOME}/venv/bin/python && {HOME}/venv/bin/python -c 'import mlx.core, mlx_lm' && echo ok")
        results.append(check("mlx_env", mac, cfg, f"MLX-Umgebung in {HOME}", "pass" if "ok" in r.stdout else "fail",
                             "vorhanden" if "ok" in r.stdout else "fehlt", "auto",
                             "uv + Python 3.12 + mlx/mlx-lm installieren (bzw. vom Leitrechner kopieren)"))
        # Skripte aktuell
        r = on(mac, cfg, f"cd {HOME} 2>/dev/null && shasum {' '.join(DEPLOY_FILES)} 2>/dev/null")
        remote = {l.split()[1]: l.split()[0] for l in r.stdout.splitlines() if len(l.split()) == 2}
        local = {f: run(["shasum", str(REPO_CLUSTER / f)]).stdout.split()[0] for f in DEPLOY_FILES}
        missing = [f for f in DEPLOY_FILES if remote.get(f) != local[f]]
        results.append(check("scripts", mac, cfg, "SS-CCC-Server-Dateien", "pass" if not missing else "fail",
                             "aktuell" if not missing else f"veraltet/fehlend: {', '.join(missing)}", "auto",
                             f"Dateien aus core/cluster nach {HOME} kopieren"))
        # GPU-Speicherfreigabe
        r = on(mac, cfg, "sysctl -n iogpu.wired_limit_mb; test -f /Library/LaunchDaemons/de.sonnerstudio.wiredlimit.plist && echo dauerhaft")
        lines = r.stdout.split()
        wired = int(lines[0]) if lines and lines[0].isdigit() else 0
        persistent = "dauerhaft" in r.stdout
        rec = recommended_wired_mb(hw["ram_gb"])
        results.append(check("wired_limit", mac, cfg, "GPU-Speicherfreigabe (iogpu.wired_limit_mb)",
                             "pass" if wired and persistent else "warn",
                             f"{wired} MB" + (" (dauerhaft)" if persistent else (" (geht beim Neustart verloren)" if wired else " (macOS-Standard)")),
                             "user", f"sudo sysctl -w iogpu.wired_limit_mb={rec} und LaunchDaemon de.sonnerstudio.wiredlimit installieren (Admin-Passwort)"))

    # Netzwerk zum Worker
    if has_worker and worker_ok:
        ip = ssh(cfg, "ipconfig getifaddr en0 || ipconfig getifaddr en1").stdout.strip()
        route = run(["/sbin/route", "-n", "get", ip]).stdout if ip else ""
        iface = next((l.split(":")[1].strip() for l in route.splitlines() if "interface:" in l), "")
        hw = run(["/usr/sbin/networksetup", "-listallhardwareports"]).stdout
        port = next((b.splitlines()[0].replace("Hardware Port: ", "") for b in hw.split("\n\n") if f"Device: {iface}" in b), "")
        if iface.startswith("bridge"):
            results.append(check("link", "coordinator", cfg, "Verbindung zum Worker", "pass", "Thunderbolt"))
        elif "Wi-Fi" in port:
            results.append(check("link", "coordinator", cfg, "Verbindung zum Worker", "warn",
                                 f"WLAN ({iface}) – gemessen ~10× langsamer und schwankend", "user",
                                 "Beide Macs per LAN-Kabel (oder Thunderbolt) verbinden"))
        else:
            results.append(check("link", "coordinator", cfg, "Verbindung zum Worker", "pass", f"LAN-Kabel ({iface}, {ip})"))
        # Thunderbolt-Kabel: CIO-Transport aktiv?
        io = run(["/usr/sbin/ioreg", "-l", "-w0"], timeout=60).stdout
        cio = '"TransportsActive" = ("CC","CIO"' in io or '"CIO"' in "".join(l for l in io.splitlines() if "TransportsActive" in l)
        usb_ncm = "AppleUSBDeviceNCM" in io or "AppleUSBNCM" in io
        if cio:
            results.append(check("thunderbolt", "coordinator", cfg, "Thunderbolt-Kabel", "pass", "Thunderbolt-Verbindung aktiv"))
        elif usb_ncm:
            results.append(check("thunderbolt", "coordinator", cfg, "Thunderbolt-Kabel", "warn",
                                 "USB-C-Kabel ohne Thunderbolt erkannt (nur USB-Netz, 100 Mbit)", "user",
                                 "Thunderbolt-4/5-Kabel (Blitzsymbol) an den hinteren Anschlüssen beider Macs verwenden"))
        else:
            results.append(check("thunderbolt", "coordinator", cfg, "Thunderbolt-Kabel", "warn", "kein Thunderbolt-Kabel – Betrieb über LAN",
                                 "user", "Optional: Thunderbolt-4/5-Kabel für eine zweite, schnellere Leitung"))

    # Modelle
    mods = [("llm", cfg["llm"]["repo"])]
    if cfg["llm"].get("draft_repo"):
        mods.append(("draft", cfg["llm"]["draft_repo"]))
    for key, repo in mods:
        snap = (HOME / "hf/hub" / f"models--{repo.replace('/', '--')}" / "snapshots")
        ok = snap.exists() and any(p.suffix == ".safetensors" for s in snap.iterdir() for p in s.iterdir())
        results.append(check(f"model_{key}", "coordinator", cfg, f"Modell {repo}", "pass" if ok else "fail",
                             "vorhanden" if ok else "fehlt", "auto", "herunterladen (mit Wiederholung, ohne Xet)"))
    if cfg["image"]["enabled"]:
        img = HOME / cfg["image"]["model_dir"]
        ok = (img / "model.safetensors").exists() and (HOME / "venv-img/bin/python").exists()
        results.append(check("model_image", "coordinator", cfg, f"Bildmodell {cfg['image']['name']}", "pass" if ok else "fail",
                             "vorhanden" if ok else "fehlt (Modell oder Umgebung)", "auto", "herunterladen und Python-3.11-Umgebung einrichten"))
    if has_worker and worker_ok and cfg["reserve"]["enabled"]:
        md = cfg["reserve"].get("model_dir", "")
        ok = bool(md) and ssh(cfg, f"test -f {shlex.quote(md)}/config.json && echo ok").stdout.strip() == "ok"
        results.append(check("model_reserve", "worker", cfg, "Reserve-Modell", "pass" if ok else "warn",
                             md if ok else "nicht eingetragen oder nicht gefunden", "user",
                             "reserve.model_dir in cluster.json auf ein kleines MLX-Modell (≤ 8 GB) setzen"))

    # Dienste
    r = run(["/bin/launchctl", "print", f"gui/{os.getuid()}/{GATEWAY_LABEL}"])
    results.append(check("service_gateway", "coordinator", cfg, "Autostart-Dienst", "pass" if r.returncode == 0 else "fail",
                         "geladen" if r.returncode == 0 else "nicht eingerichtet", "auto", "LaunchAgent installieren und laden"))
    if has_worker and worker_ok:
        for label, title in (("de.sonnerstudio.ssccc-forward", "Weiterleitung zum Leitrechner"),
                             ("de.sonnerstudio.ssccc-reserve", "Antwort-Reserve")):
            if label.endswith("reserve") and not cfg["reserve"]["enabled"]:
                continue
            r = ssh(cfg, f"launchctl print gui/$(id -u)/{label} >/dev/null 2>&1 && echo ok")
            results.append(check(f"service_{label.split('-')[-1]}", "worker", cfg, title,
                                 "pass" if "ok" in r.stdout else "fail", "geladen" if "ok" in r.stdout else "nicht eingerichtet",
                                 "auto", "LaunchAgent auf dem Worker installieren"))

    # Gateway erreichbar + Antwort + Werkzeugaufruf
    port = cfg["gateway_port"]
    r = run(["/usr/bin/curl", "-s", "-m", "5", f"http://127.0.0.1:{port}/health"])
    healthy = '"status":"ok"' in r.stdout.replace(" ", "")
    results.append(check("gateway", "coordinator", cfg, f"Gateway :{port}", "pass" if healthy else "fail",
                         r.stdout.strip() or "keine Antwort", "auto", "Dienst starten (launchctl kickstart)"))
    if healthy:
        body = json.dumps({"model": "ssccc", "max_tokens": 120, "chat_template_kwargs": {"enable_thinking": False},
                           "messages": [{"role": "user", "content": "Wie spät ist es in Berlin? Nutze das Werkzeug."}],
                           "tools": [{"type": "function", "function": {"name": "get_time", "description": "Uhrzeit einer Stadt",
                                      "parameters": {"type": "object", "properties": {"city": {"type": "string"}}, "required": ["city"]}}}]})
        r = run(["/usr/bin/curl", "-s", "-m", "300", f"http://127.0.0.1:{port}/v1/chat/completions",
                 "-H", "Content-Type: application/json", "-H", f"Authorization: Bearer {cfg.get('api_key', '')}",
                 "-d", body], timeout=320)
        try:
            tc = json.loads(r.stdout)["choices"][0]["message"].get("tool_calls")
        except Exception:
            tc = None
        results.append(check("tools", "coordinator", cfg, "Werkzeugaufruf (für Agenten)", "pass" if tc else "fail",
                             f"{tc[0]['function']['name']}({tc[0]['function']['arguments']})" if tc else "kein Werkzeugaufruf",
                             "none", "Modell/Chat-Vorlage prüfen"))
    results.append(check("api_key", "coordinator", cfg, "Zugriffsschutz (API-Schlüssel)",
                         "pass" if cfg.get("api_key") else "warn",
                         "aktiv" if cfg.get("api_key") else "Gateway ist im ganzen Heimnetz ohne Schlüssel erreichbar",
                         "auto", "ssccc_setup.py secure – erzeugt einen Schlüssel und stellt alle Programme um"))
    if has_worker and worker_ok:
        r = ssh(cfg, f"curl -s -m 8 http://127.0.0.1:{cfg['forward_port']}/health")
        results.append(check("worker_reach", "worker", cfg, "Gateway vom Worker erreichbar", "pass" if '"ok"' in r.stdout else "fail",
                             r.stdout.strip() or "keine Antwort", "user",
                             "Freigabe „Lokales Netzwerk“ für python3.12 auf beiden Macs erteilen (Datenschutz & Sicherheit)"))

    # Programme
    for mac in macs:
        if mac == "worker" and not worker_ok:
            continue
        r = on(mac, cfg, "~/.local/bin/hermes config get model.provider 2>/dev/null; grep -c '\"ssccc\"' ~/.config/opencode/opencode.json 2>/dev/null")
        out = r.stdout
        for key, title, present in (("hermes", "Hermes", "ssccc" in out.split("\n")[0] if out else False),
                                    ("opencode", "OpenCode", any(l.strip().isdigit() and int(l) > 0 for l in out.split("\n")[1:2]))):
            results.append(check(f"client_{key}", mac, cfg, f"{title} an SS-CCC", "pass" if present else "warn",
                                 "verbunden" if present else "nicht verbunden", "auto", f"{title} auf das SS-CCC-Gateway einstellen"))
    return results


def summarize(results):
    n = {s: sum(1 for r in results if r["status"] == s) for s in ("pass", "warn", "fail")}
    state = "notReady" if n["fail"] else ("incomplete" if n["warn"] else "ready")
    emit({"type": "summary", "state": state, **n})
    return state


# ── Automatische Schritte ────────────────────────────────────────────────────
def step(title, detail=""):
    emit({"type": "step", "title": title, "detail": detail})


def fix_mlx_env(cfg, mac):
    if mac == "coordinator":
        HOME.mkdir(parents=True, exist_ok=True)
        uv = HOME / "bin/uv"
        if not uv.exists():
            step("uv installieren", str(uv))
            inst = HOME / "uv-install.sh"
            run(["/usr/bin/curl", "-LsSf", "https://astral.sh/uv/install.sh", "-o", str(inst)], check=True, timeout=120)
            subprocess.run(["/bin/sh", str(inst)], capture_output=True, timeout=300, check=True,
                           env={**os.environ, "UV_INSTALL_DIR": str(HOME / "bin"), "UV_NO_MODIFY_PATH": "1"})
        env = {**os.environ, "UV_PYTHON_INSTALL_DIR": str(HOME / "python")}
        for venv, py, pkgs in (("venv", "3.12", ["mlx", "mlx-lm", "huggingface_hub", "fastapi", "uvicorn[standard]", "httpx",
                                                  "python-multipart", "pillow", "psutil", "zeroconf"]),
                               ("venv-vlm", "3.12", ["mlx-vlm"])):
            if not (HOME / venv / "bin/python").exists():
                step(f"Python-Umgebung {venv}", " ".join(pkgs))
                subprocess.run([str(uv), "venv", "-q", "--python", py, str(HOME / venv)], env=env, check=True, capture_output=True)
            subprocess.run([str(uv), "pip", "install", "-q", *pkgs], env={**env, "VIRTUAL_ENV": str(HOME / venv)},
                           check=True, capture_output=True, timeout=1800)
    else:
        step("Umgebung auf den Worker kopieren", f"{HOME} (gleicher Pfad, gleiche Architektur)")
        ssh(cfg, f"mkdir -p {HOME}")
        run(["/usr/bin/rsync", "-a", "--exclude", "hf", "--exclude", "models", "--exclude", "bilder", "--exclude", "*.log",
             f"{HOME}/bin", f"{HOME}/python", f"{HOME}/venv", f"{worker_ssh(cfg)}:{HOME}/"], timeout=1800, check=True)


def fix_scripts(cfg, mac):
    step("Server-Dateien verteilen", mac_name(mac, cfg))
    srcs = [str(REPO_CLUSTER / f) for f in DEPLOY_FILES]
    if mac == "coordinator":
        for s in srcs:
            shutil.copy2(s, HOME)
        run(["/bin/chmod", "+x", *[str(HOME / f) for f in DEPLOY_FILES if f.endswith(".sh")]])
        cj = HOME / "cluster.json"
        if not cj.exists():
            name = run(["/usr/sbin/scutil", "--get", "ComputerName"]).stdout.strip()
            host = run(["/usr/sbin/scutil", "--get", "LocalHostName"]).stdout.strip() + ".local"
            cj.write_text(json.dumps({"coordinator": {"name": name, "host": host}}, indent=2, ensure_ascii=False))
    else:
        run(["/usr/bin/rsync", "-a", *srcs, str(HOME / "cluster.json"), f"{worker_ssh(cfg)}:{HOME}/"], check=True, timeout=120)
        ssh(cfg, f"chmod +x {HOME}/*.sh")


def hf_download(repo, local_dir=None):
    step("Modell herunterladen", repo)
    env = {**os.environ, "HF_HOME": str(HOME / "hf"), "HF_HUB_DISABLE_XET": "1"}   # Xet-Downloads blieben hängen
    cmd = [str(HOME / "venv/bin/hf"), "download", repo, "--max-workers", "8"]
    if local_dir:
        cmd += ["--local-dir", str(local_dir)]
    for attempt in range(1, 6):
        r = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=7200)
        if r.returncode == 0:
            return
        step("Download wird wiederholt", f"Versuch {attempt + 1}")
        time.sleep(5)
    raise RuntimeError(f"Download {repo} fehlgeschlagen")


def fix_image(cfg):
    img = HOME / cfg["image"]["model_dir"]
    if not (img / "model.safetensors").exists():
        hf_download(cfg["image"]["repo"], img)
    if not (HOME / "venv-img/bin/python").exists():
        step("Bild-Umgebung (Python 3.11)", "requirements.txt des Modells")
        env = {**os.environ, "UV_PYTHON_INSTALL_DIR": str(HOME / "python")}
        subprocess.run([str(HOME / "bin/uv"), "venv", "-q", "--python", "3.11", str(HOME / "venv-img")], env=env, check=True)
        subprocess.run([str(HOME / "bin/uv"), "pip", "install", "-q", "-r", str(img / "requirements.txt")],
                       env={**env, "VIRTUAL_ENV": str(HOME / "venv-img")}, check=True, timeout=1800)


def render(template, repl):
    text = (REPO_CLUSTER / "launchd" / template).read_text()
    for k, v in repl.items():
        text = text.replace(k, str(v))
    return text


def fix_service_gateway(cfg):
    step("Autostart-Dienst einrichten", GATEWAY_LABEL)
    dst = Path.home() / "Library/LaunchAgents" / f"{GATEWAY_LABEL}.plist"
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(render("de.sonnerstudio.ssccc.plist", {"__SSCCC_HOME__": HOME}))
    uid = os.getuid()
    run(["/bin/launchctl", "bootout", f"gui/{uid}/{GATEWAY_LABEL}"])
    run(["/bin/launchctl", "bootstrap", f"gui/{uid}", str(dst)])
    for _ in range(120):
        if '"llm_ready":true' in run(["/usr/bin/curl", "-s", "-m", "2", f"http://127.0.0.1:{cfg['gateway_port']}/health"]).stdout.replace(" ", ""):
            return
        time.sleep(3)


def fix_worker_service(cfg, name):
    label = f"de.sonnerstudio.ssccc-{name}"
    step("Dienst auf dem Worker", label)
    text = render(f"{label}.plist", {"__SSCCC_HOME__": HOME, "__RESERVE_MODEL__": cfg["reserve"].get("model_dir", ""),
                                     "__RESERVE_PORT__": cfg["reserve"]["port"]})
    tmp = HOME / f".{label}.plist"
    tmp.write_text(text)
    run(["/usr/bin/scp", "-q", str(tmp), f"{worker_ssh(cfg)}:Library/LaunchAgents/{label}.plist"], check=True)
    tmp.unlink()
    ssh(cfg, f"launchctl bootout gui/$(id -u)/{label} 2>/dev/null; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/{label}.plist")


def fix_clients(cfg, mac):
    base = f"http://127.0.0.1:{cfg['gateway_port']}" if mac == "coordinator" else f"http://127.0.0.1:{cfg['forward_port']}"
    key = cfg.get("api_key") or "ssccc-lokal"
    step("Programme verbinden", f"{mac_name(mac, cfg)} → {base}/v1")
    ctx = cfg["llm"]["context"]
    hermes = ("H=~/.local/bin/hermes; if [ -x $H ]; then cp ~/.hermes/config.yaml ~/.hermes/config.yaml.bak-ssccc 2>/dev/null; "
              f"$H config set providers.ssccc.base_url {base}/v1; $H config set providers.ssccc.api_key {key}; "
              f"$H config set model.provider ssccc; $H config set model.default {cfg['llm']['repo']}; "
              f"$H config set model.base_url {base}/v1; $H config set model.context_length {ctx}; "
              "$H config set image_gen.provider openai; $H config set image_gen.openai.provider ssccc; "
              f"$H config set image_gen.openai.model {cfg['image']['name']}; fi")
    opencode = (f"P=~/.config/opencode/opencode.json; [ -f $P ] && {HOME}/venv/bin/python - $P <<'PY'\n"
                "import json,sys,shutil\np=sys.argv[1]; shutil.copy2(p,p+'.bak-ssccc'); d=json.load(open(p))\n"
                "d.setdefault('provider',{})['ssccc']={'npm':'@ai-sdk/openai-compatible','name':'SS-CCC',"
                f"'options':{{'baseURL':'{base}/v1','apiKey':'{key}'}},"
                f"'models':{{'qwen3.8-27b':{{'name':'{cfg['llm']['display_name']}','tool_call':True,'limit':{{'context':{ctx},'output':{cfg['llm']['max_output']}}}}}}}}}\n"
                "d['model']='ssccc/qwen3.8-27b'; json.dump(d,open(p,'w'),indent=2,ensure_ascii=False)\nPY")
    app = (f"mkdir -p {HOME} && printf '%s' '{json.dumps({'gateway': base, 'api_key': cfg.get('api_key', '')})}' > {HOME}/ssccc_app.json")
    for script in (hermes, opencode, app):
        # Umleitung um den ganzen Block – an einer Heredoc-Endmarke angehängt, würde
        # sie die Marke unkenntlich machen (der OpenCode-Teil lief dann nie).
        on(mac, cfg, "{\n" + script + "\n} >/dev/null 2>&1", timeout=120)


def apply(cfg, only=None, skip_models=False):
    results = [r for r in checks(cfg) if r["status"] != "pass" and r["fix"] == "auto"]
    if only:
        results = [r for r in results if r["id"] in only]
    done = set()
    for r in results:
        key = (r["id"], r["role"])
        if key in done:
            continue
        done.add(key)
        try:
            if r["id"] == "mlx_env":
                fix_mlx_env(cfg, r["role"])
            elif r["id"] == "scripts":
                fix_scripts(cfg, r["role"])
            elif r["id"] in ("model_llm", "model_draft") and not skip_models:
                hf_download(cfg["llm"]["repo"] if r["id"] == "model_llm" else cfg["llm"]["draft_repo"])
            elif r["id"] == "model_image" and not skip_models:
                fix_image(cfg)
            elif r["id"] in ("service_gateway", "gateway"):
                fix_service_gateway(cfg)
            elif r["id"] in ("service_forward", "service_reserve"):
                fix_worker_service(cfg, r["id"].split("_")[1])
            elif r["id"] == "api_key":
                secure(cfg)
            elif r["id"].startswith("client_"):
                if ("clients", r["role"]) not in done:
                    done.add(("clients", r["role"]))
                    fix_clients(cfg, r["role"])
        except Exception as e:  # weitermachen, Fehler melden
            emit({"type": "error", "id": r["id"], "mac": r["mac"], "detail": str(e)[-400:]})
    emit({"type": "step", "title": "Abschlussprüfung", "detail": ""})
    return summarize(checks(cfg))


# ── Erkennung / Konfiguration ────────────────────────────────────────────────
def secure(cfg):
    """API-Schlüssel erzeugen, Programme auf beiden Macs umstellen, Gateway neu starten."""
    import secrets
    key = cfg.get("api_key") or "ssccc-" + secrets.token_urlsafe(24)
    cj = HOME / "cluster.json"
    data = json.loads(cj.read_text()) if cj.exists() else {}
    data["api_key"] = key
    cj.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    os.chmod(cj, 0o600 if not worker_ssh(cfg) else 0o644)
    cfg["api_key"] = key
    step("API-Schlüssel gesetzt", "in cluster.json (nicht im Repository)")
    if worker_ssh(cfg):
        run(["/usr/bin/rsync", "-a", str(cj), f"{worker_ssh(cfg)}:{HOME}/"], timeout=60)
    for mac in ["coordinator"] + (["worker"] if worker_ssh(cfg) else []):
        fix_clients(cfg, mac)
    step("Gateway neu starten", GATEWAY_LABEL)
    run(["/bin/launchctl", "kickstart", "-k", f"gui/{os.getuid()}/{GATEWAY_LABEL}"])
    for _ in range(90):
        if '"llm_ready":true' in run(["/usr/bin/curl", "-s", "-m", "2", f"http://127.0.0.1:{cfg['gateway_port']}/health"]).stdout.replace(" ", ""):
            break
        time.sleep(2)
    emit({"type": "step", "title": "Zugriffsschutz aktiv", "detail": "Hermes, OpenCode und die App nutzen den Schlüssel"})


def detect():
    """Macs mit SSH (Entfernte Anmeldung) im lokalen Netz über Bonjour finden."""
    p = subprocess.Popen(["/usr/bin/dns-sd", "-B", "_ssh._tcp", "local."], stdout=subprocess.PIPE, text=True)
    time.sleep(4)
    p.terminate()
    out = p.communicate()[0]
    me = run(["/usr/sbin/scutil", "--get", "ComputerName"]).stdout.strip().replace("\u00a0", " ")
    names = sorted({l.split("_ssh._tcp.")[-1].strip().replace("\u00a0", " ") for l in out.splitlines() if "_ssh._tcp." in l and " Add " in l})
    found = [n for n in names if n and n != me]
    emit({"type": "detect", "self": me, "candidates": found})
    return found


def configure(host, user, name):
    sshdir = Path.home() / ".ssh"
    sshdir.mkdir(mode=0o700, exist_ok=True)
    key = sshdir / "id_ed25519"
    if not key.exists():
        run(["/usr/bin/ssh-keygen", "-t", "ed25519", "-N", "", "-q", "-f", str(key)], check=True)
    conf = sshdir / "config"
    text = conf.read_text() if conf.exists() else ""
    if f"Host {SSH_ALIAS}\n" not in text:
        text += f"\n# SS-CCC Worker\nHost {SSH_ALIAS}\n    HostName {host}\n    User {user}\n    IdentityFile ~/.ssh/id_ed25519\n"
        conf.write_text(text)
        conf.chmod(0o600)
    cj = HOME / "cluster.json"
    HOME.mkdir(parents=True, exist_ok=True)
    data = json.loads(cj.read_text()) if cj.exists() else {}
    data["worker"] = {"name": name or host.replace(".local", ""), "ssh": SSH_ALIAS, "host": host}
    if "coordinator" not in data:
        data["coordinator"] = {"name": run(["/usr/sbin/scutil", "--get", "ComputerName"]).stdout.strip(),
                               "host": run(["/usr/sbin/scutil", "--get", "LocalHostName"]).stdout.strip() + ".local"}
    cj.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    emit({"type": "step", "title": "Worker eingetragen", "detail": f"{user}@{host} als {SSH_ALIAS}",
          "next": f"ssh-copy-id -i ~/.ssh/id_ed25519.pub {user}@{host}"})


def main():
    global JSON_OUT
    ap = argparse.ArgumentParser(description="SS-CCC Ersteinrichtung")
    ap.add_argument("command", choices=["check", "apply", "detect", "configure", "secure"])
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--only", default="")
    ap.add_argument("--skip-models", action="store_true")
    ap.add_argument("--worker-host", default="")
    ap.add_argument("--worker-user", default="")
    ap.add_argument("--worker-name", default="")
    a = ap.parse_args()
    JSON_OUT = a.json
    if a.command == "detect":
        detect()
        return
    if a.command == "configure":
        if not a.worker_host or not a.worker_user:
            ap.error("--worker-host und --worker-user sind nötig")
        configure(a.worker_host, a.worker_user, a.worker_name)
        return
    _, cfg = load_cfg()
    if a.command == "secure":
        secure(cfg)
        return
    if a.command == "check":
        state = summarize(checks(cfg))
    else:
        state = apply(cfg, only=set(filter(None, a.only.split(","))), skip_models=a.skip_models)
    sys.exit(0 if state == "ready" else 1)


if __name__ == "__main__":
    main()
