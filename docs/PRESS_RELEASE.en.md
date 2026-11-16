# Press Release: SonnerStudio Cluster-Case-Companion (SS-CCC) v1.6.44 — 17 Languages, Multi-Model Mode, 6-Tab Research Lab & Menu Bar Background Service

**November 16, 2026 — SonnerStudio** announces **v1.6.44** of **SonnerStudio Cluster-Case-Companion (SS-CCC)**. Built natively in SwiftUI for macOS, the open-source platform unites any **Apple Silicon Macs (M1–M12+)** over **Thunderbolt 3/4/5**, **RDMA (`JACCL`)**, and **global Internet WAN bridges** into a unified memory and inference pool for **MLX**, **oMLX**, **Ollama**, and **llama.cpp**.

![SonnerStudio Cluster-Case-Companion Ecosystem](images/ssccc_ecosystem_banner.jpg)

---

### Key Development Highlights & Current Status

1. **Universal Apple Silicon Support (M1–M12+) & Full Sensor Telemetry**
   SS-CCC supports every **Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, and Mac Pro** from **M1–M6** through open-ended **M7–M12+**, reading live **CPU P/E cores, GPU cores, Neural Engine (ANE) cores**, NVMe SSD capacity, thermal state, and power draw under `iogpu.wired_limit_mb` memory protection.

2. **Global Internet WAN Mesh, Audio-Party & Multi-Model Mode (MMM)**
   Local TB/RDMA islands can be bridged with worldwide WAN peers via **Tailscale / WireGuard**, **QUIC / Iroh P2P (0-RTT)**, and **libp2p / DERP** alongside WebSocket chat (`/ws/wan/{room_id}`) and **`AVAudioEngine` Cluster Audio-Party**. **Multi-Model Mode (MMM)** orchestrates multiple concurrent models (*Parallel Pool*, *MoA*, *EAGLE-3 / Speculative Decoding*, *Tree-MoA*, *Ares*) on `:8000/v1` for **Cursor**, **VS Code**, **Xcode**, **OpenCode**, **Hermes Agent**, and **Google Antigravity**.

   ![Global Internet WAN Cluster and Participant Chat](images/ssccc_internet_wan_mesh.jpg)

3. **6-Tab Scientific Research Lab & Per-Position History Recording**
   **Science & Roofline** features 6 specialized analysis tabs (**Local TB/RDMA**, **Internet WAN**, and **Comparison**): **Roofline & Bottleneck**, **WAN Topology & Scaling (`N = 1..128`, *Petals/SWARM*, *DiLoCo*)**, **Memory & KV Analysis (`ANE-Split`, `3-Tier CacheGen`)**, **Energy, CO₂ & Cost (`J/token`, `EDP`)**, **Trials & Export (`CI₉₅`, `CV%`, `Goodput%`, `CSV / JSON / LaTeX / BibTeX`)**, and **History Recording**.

   ![Scientific Roofline and Energy Analytics](images/ssccc_science_roofline_hero.jpg)

4. **Minimize-to-Menu-Bar Service (`⌘⇧M`), Modern Solaris Dock Icon, Auto-Setup & 17 Languages**
   - **Menu Bar Service & Dock Icon:** Minimizing moves SS-CCC into the top macOS menu bar next to **Ollama** (`.accessory` service mode) with live readiness, RAM pool, active nodes, loaded model/layers, MMM slot indicators, and 1-click `:8000/v1` & `:11434` endpoint copying, paired with a custom **Solaris macOS Dock icon**.
   - **Auto-Setup & 4-State Readiness:** **Setup & Provision** discovers Macs automatically and validates **Ready / Not Ready / Partially Configured / Unconfigured**.
   - **17 Languages & 25/25 Global Tests:** Complete localization across all 11 views, 12 Help chapters, hover shorttips, and 17 README files in **English, German, French, Spanish, Portuguese, Russian, Japanese, Chinese, Dutch, Afrikaans, Polish, Czech, Slovak, Hungarian, Korean, Hindi, and Tamil**.

---

### Availability, Wiki & Source Code

- **GitHub Repository:** https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion
- **Project Wiki:** https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion/wiki
- **Quick Start on Apple Silicon (macOS 14.0+):**
  ```bash
  git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
  cd SonnerStudio-Cluster-Case-Companion
  chmod +x scripts/run_ssccc.sh && ./scripts/run_ssccc.sh
  ```
