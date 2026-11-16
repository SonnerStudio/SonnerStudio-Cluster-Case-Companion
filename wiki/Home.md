# ☀️ SonnerStudio Cluster-Case-Companion (SS-CCC) Wiki

Welcome to the official **SS-CCC Wiki** — the knowledge base for **native macOS Apple Silicon (M1–M12+) clustering**, **distributed MLX / oMLX / Ollama / llama.cpp inference**, **Multi-Model Mode (MMM)**, **Global Internet WAN coupling**, the **Menu Bar Background Service (`⌘⇧M`)**, and the **6-Tab Scientific Research Lab**.

---

## 📚 Wiki Navigation

| Guide | Topics Covered |
| :--- | :--- |
| **[Architecture & RDMA](Architecture-and-RDMA.md)** | M1–M12+ Unified Memory bandwidths, Thunderbolt 3/4/5, RDMA (`JACCL`), `bridge0` protection & `iogpu.wired_limit_mb` guards |
| **[Multi-Model Mode & Agents](Multi-Model-Mode-and-Agents.md)** | 4 Orchestration strategies, EAGLE-3, Tree-MoA, 1-click Auto-Setup, Multi-IDE gateway (`:8000/v1`), MCP & A2A cards |
| **[Menu Bar & Dock Service Mode](Menu-Bar-and-Dock-Service-Mode.md)** | Minimize-to-Menu-Bar (`⌘⇧M`), live status popover, `.accessory` background mode next to Ollama, Solaris Dock icon |
| **[Science Lab & Record Challenge](Science-Lab-and-Record-Challenge.md)** | 6-Tab Roofline/WAN/KV/Carbon/Trials/History lab, $B^*$ pipeline model, reproducible `N=20` protocol |
| **[Languages & Localization](Languages-and-Localization.md)** | All **17 supported languages** (`EN` through `TA`), 4-row README switcher, 12-chapter Help Center & shorttips |

---

## 🖥️ All 11 Program Modules

1. **Cluster Overview:** Unified memory bar, M1–M12+ topology, TB/RDMA bandwidth, 4-state Readiness card (**Local**, **Internet**, **Local + Internet**).
2. **Devices & Compare:** Real-time CPU P/E, GPU & Neural Engine (`ANE`) cores, NVMe SSD, thermal state & power draw across any M1–M12+ Mac.
3. **Model Studio:** Live model discovery (**oMLX**, **Ollama**, **llama.cpp**, local `.gguf`, `~/.cache/huggingface/hub`), layer splits, ANE-Split & 3-tier KV-cache.
4. **Network & RDMA:** Auto-Hybrid / TB-Only / LAN / RDMA modes, `MLX_METAL_FAST_SYNCH=1`, Pipeline Ring vs. JACCL Full-Mesh TP.
5. **Internet Cluster & Chat:** Tailscale, WireGuard, QUIC/Iroh 0-RTT & libp2p/DERP WAN coupling, live WAN throughput monitor, WebSocket chat & `AVAudioEngine` Audio-Party.
6. **Multi-Model Mode (MMM):** Cross-cluster parallel/MoA/speculative/pipeline orchestration sharing `:8000/v1` across IDEs.
7. **Agents & IDEs:** 1-click configurations for **OpenCode**, **Hermes Agent**, **Google Antigravity**, **Cursor**, **VS Code**, and **Xcode** (+ MCP & A2A).
8. **Science & Roofline:** 6-tab empirical research lab with live SSE + ICMP RTT telemetry, Log-Log Roofline, `CI₉₅`, LaTeX & BibTeX export.
9. **API & Console:** Live test runner for OpenAI (`/v1/chat/completions`, `/v1/responses`), Ollama (`/api/tags`), and A2A Agent Cards.
10. **Setup & Provision:** Bonjour/mDNS & WAN peer auto-discovery, SSH trust provisioning & `iogpu.wired_limit_mb` verification.
11. **Help & Documentation:** Searchable **12-chapter interactive manual** (`⌘?`) with click-to-detail diagrams across all **17 languages**.

---

## ⚡ Quick Start

```bash
git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
cd SonnerStudio-Cluster-Case-Companion
chmod +x scripts/run_ssccc.sh
./scripts/run_ssccc.sh
```

> **Quick Links:** [Contributing Guide](../CONTRIBUTING.md) · [Security Policy](../SECURITY.md) · [Code of Conduct](../CODE_OF_CONDUCT.md) · [Main README](../README.md)
