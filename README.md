# ☀️ SonnerStudio Cluster-Case-Companion (SS-CCC)

> **🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

**SonnerStudio Cluster-Case-Companion (SS-CCC)** is a native macOS cluster manager and inference companion (inspired by **EXO** and **Apple/Claris Harbor / Fabric**) built to pool Unified Memory across multiple Apple Silicon Macs — e.g., combining a **Mac Studio M5 Max (36 GB, Thunderbolt 5)** and a **Mac mini M4 (16 GB, Thunderbolt 4)** into a **52 GB physical (~42 GB usable) AI cluster** over **Thunderbolt (Bridge / RDMA)**, **LAN/WLAN**, or **Hybrid** networking.

---

## ✨ Key Features

- **52 GB Heterogeneous Memory Pooling:** Memory-weighted pipeline parallelism (`~71%` layers + embeddings/LM-head on M5 Max `460 GB/s`, `~29%` layers on M4 `120 GB/s`) with safe `iogpu.wired_limit_mb` guards.
- **Hybrid Control / Data-Plane Architecture:**
  - **Control Plane (LAN/WLAN):** Bonjour/mDNS discovery (`_ssccc._tcp.local.`), heartbeats, API gateway, and model downloads.
  - **Data Plane (Thunderbolt 4/5 or RDMA):** Isolated point-to-point numeric IPs (`10.99.1.x`) for `mlx.distributed` (`ring` TCP/IP at 30–37 Gbps real throughput, or `jaccl` RDMA `<50 µs` on TB5/opt-in TB4).
- **Native SwiftUI Studio Console (*Solaris Telemetry Lab*):**
  - **Cluster Overview:** Live topology, animated link flow, and 52 GB pool breakdown.
  - **Devices & Compare:** Live `sysctl` / `sw_vers` / `ibv_devices` / `ipconfig` telemetry with side-by-side hardware comparison.
  - **Model Studio:** Proportional layer sharding, KV-cache quantization (`FP16 / 8-bit / 4-bit`), and runtime integration for **oMLX** (Paged SSD KV-Cache), **Ollama**, and **llama.cpp**.
  - **Agents & IDEs (1-Click Setup):** Instant configuration export for **OpenCode**, **Hermes Agent**, and **Google Antigravity (AGY)**.
  - **Science & Roofline:** Grounded in *Splitwise/DistServe* (OSDI '24), *SpecPipe* (arXiv), and `MLX_METAL_FAST_SYNCH=1` (`~4 µs` vs. `~180 µs`).

---

## 🚀 Quick Start (macOS Apple Silicon)

```bash
# 1. Launch the native SwiftUI Studio App
"./scripts/run_ssccc.sh"

# 2. (Optional) Start the Python/FastAPI Gateway (requires uv)
cd core && uv sync --extra dev
PYTHONPATH=".." uv run uvicorn core.api.gateway:app --host 0.0.0.0 --port 8000

# 3. Configure Thunderbolt Point-to-Point IPs (on Studio & Mini)
./scripts/setup_tb_network.sh studio   # 10.99.1.1
./scripts/setup_tb_network.sh mini     # 10.99.1.2
```

---

## 📁 Project Structure

- `app/` — Native macOS SwiftUI application (`SSCCCApp`, MVVM)
- `core/` — Hexagonal Python/MLX cluster engine (`domain/`, `ports/`, `adapters/`, `application/`, `api/`, `tests/`)
- `docs/` — [Roadmap](docs/ROADMAP.md), [Implementation Plan](docs/IMPLEMENTATION_PLAN.md), [Architecture](docs/ARCHITECTURE.md)
- `scripts/` — Hardware checks, Thunderbolt network setup, MLX benchmarks, app launcher
- `configs/` — MLX distributed hostfile templates

---

## 📄 License

Licensed under the [MIT License](LICENSE.md).
