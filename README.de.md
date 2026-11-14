# ☀️ SonnerStudio Cluster-Case-Companion (SS-CCC)

> **🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

**SonnerStudio Cluster-Case-Companion (SS-CCC)** ist eine native macOS-Cluster-App und Inferenz-Plattform (inspiriert von **EXO** und **Apple/Claris Harbor / Fabric**). Sie koppelt den Unified Memory mehrerer Apple-Silicon-Macs — z. B. **Mac Studio M5 Max (36 GB, Thunderbolt 5)** + **Mac mini M4 (16 GB, Thunderbolt 4)** zu einem **52 GB physischen (~42 GB nutzbaren) KI-Cluster** über **Thunderbolt (Bridge / RDMA)**, **LAN/WLAN** oder **Hybrid-Betrieb**.

---

## ✨ Hauptfunktionen

- **52-GB-Verbund für heterogene Hardware:** Speichergewichtetes Pipeline-Sharding (`~71 %` Layer + Embeddings/LM-Head auf M5 Max `460 GB/s`, `~29 %` Layer auf M4 `120 GB/s`) mit sicherem `iogpu.wired_limit_mb`-Schutz.
- **Hybride Control- & Data-Plane-Architektur:**
  - **Control Plane (LAN/WLAN):** Bonjour/mDNS-Discovery (`_ssccc._tcp.local.`), Heartbeats, API-Gateway und Modell-Downloads.
  - **Data Plane (Thunderbolt 4/5 oder RDMA):** Isolierte Punkt-zu-Punkt-IPs (`10.99.1.x`) für `mlx.distributed` (`ring` TCP/IP mit real 30–37 Gbps oder `jaccl` RDMA `<50 µs` auf TB5 / Opt-In TB4).
- **Native SwiftUI-Oberfläche (*Solaris Telemetry Lab*):**
  - **Cluster-Übersicht:** Live-Topologie, animierter Datenfluss und 52-GB-Speicherpool-Balken.
  - **Geräte & Vergleich:** Live-Hardware-Auslesung (`sysctl`, `sw_vers`, `ibv_devices`, `ipconfig`) mit Direktvergleich.
  - **Modell-Studio:** Proportionales Layer-Sharding, KV-Cache-Quantisierung (`FP16 / 8-Bit / 4-Bit`) sowie Laufzeit-Dienste für **oMLX** (Paged SSD KV-Cache), **Ollama** und **llama.cpp**.
  - **Agenten & IDEs (1-Klick-Setup):** Sofortige Konfiguration für **OpenCode**, **Hermes Agent** und **Google Antigravity (AGY)**.
  - **Forschung & Roofline:** Wissenschaftliche Grundlagen (*Splitwise/DistServe*, *SpecPipe*, `MLX_METAL_FAST_SYNCH=1`).

---

## 🚀 Schnellstart (macOS Apple Silicon)

```bash
# 1. Native SwiftUI Studio-App starten
"./scripts/run_ssccc.sh"

# 2. (Optional) Python/FastAPI-Gateway starten (benötigt uv)
cd core && uv sync --extra dev
PYTHONPATH=".." uv run uvicorn core.api.gateway:app --host 0.0.0.0 --port 8000

# 3. Punkt-zu-Punkt-Thunderbolt-IPs einrichten (Studio & Mini)
./scripts/setup_tb_network.sh studio   # 10.99.1.1
./scripts/setup_tb_network.sh mini     # 10.99.1.2
```

---

## 📁 Projektstruktur

- `app/` — Native macOS SwiftUI-App (`SSCCCApp`, MVVM)
- `core/` — Hexagonale Python/MLX-Cluster-Engine (`domain/`, `ports/`, `adapters/`, `application/`, `api/`, `tests/`)
- `docs/` — [Roadmap](docs/ROADMAP.md), [Implementation Plan](docs/IMPLEMENTATION_PLAN.md), [Architektur](docs/ARCHITECTURE.md)
- `scripts/` — Hardware-Check, Thunderbolt-Netzwerk-Setup, MLX-Benchmarks, App-Starter
- `configs/` — MLX-Distributed-Hostfile-Vorlagen

---

## 📄 Lizenz

Veröffentlicht unter der [MIT-Lizenz](LICENSE.md).
