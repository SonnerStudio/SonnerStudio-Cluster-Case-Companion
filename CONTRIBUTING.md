# Contributing to SonnerStudio Cluster-Case-Companion (SS-CCC)

Welcome! Thank you for helping shape **SS-CCC** — the open-source native macOS cluster orchestrator and distributed MLX inference studio for **Apple Silicon (M1–M12+)**.

> **Quick Links (GitHub Right-Sidebar & Wiki)**
> - [📖 Project Wiki Home](wiki/Home.md) · [🌐 GitHub Wiki](https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion/wiki)
> - [🏛️ Architecture & RDMA](wiki/Architecture-and-RDMA.md)
> - [🧠 Multi-Model Mode & Agents](wiki/Multi-Model-Mode-and-Agents.md)
> - [🛰️ Menu Bar Service & Dock Icon](wiki/Menu-Bar-and-Dock-Service-Mode.md)
> - [🔬 Science Lab & Record Challenge](wiki/Science-Lab-and-Record-Challenge.md)
> - [🌍 17 Languages & Localization](wiki/Languages-and-Localization.md)
> - [🛡️ Security Policy](SECURITY.md) · [⚖️ Code of Conduct](CODE_OF_CONDUCT.md) · [📄 MIT License](LICENSE.md)

---

## 🛠️ How You Can Contribute

1. **Test on Your Apple Silicon Hardware (M1–M12+)**
   - Run SS-CCC on your Mac mini, MacBook Air/Pro, iMac, Mac Studio, or Mac Pro.
   - Verify CPU/GPU/Neural Engine telemetry, `iogpu.wired_limit_mb`, Thunderbolt 3/4/5 bridges, and RDMA (`JACCL`) stability, and share benchmark findings from **Science & Roofline**.

2. **Join the Hybrid Supercluster Record Challenge**
   - Connect local TB/RDMA islands with remote WAN peers (`Tailscale`, `WireGuard`, `QUIC/Iroh`) and export reproducible `JSON`, `CSV`, and `LaTeX` trial logs (`N = 20`, `T = 0.0`).

3. **Submit Pull Requests (Code, Runtimes, Scripts & Translations)**
   - Keep **Swift** views free of third-party packages in `Localization.swift` / `ClusterModels.swift` (Foundation-only so `test_01_swift_runtime_checks` stays fast and clean).
   - Keep all **17 languages** (`en, de, fr, es, pt, ru, ja, zh, nl, af, pl, cs, sk, hu, ko, hi, ta`) synchronized across `Localization.swift`, `HelpDocsView.swift`, and `README*.md`.
   - Always run the full verification suite before opening a PR:
     ```bash
     python3 scripts/bump_version.py --check
     python3 tests/test_global_suite.py
     ./scripts/run_ssccc.sh --build-only
     ```

---

## 🧩 Development Setup

```bash
git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
cd SonnerStudio-Cluster-Case-Companion
chmod +x scripts/run_ssccc.sh
./scripts/run_ssccc.sh
```

For full module walkthroughs, consult the [Project Wiki](wiki/Home.md).
