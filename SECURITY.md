# Security Policy — SonnerStudio Cluster-Case-Companion (SS-CCC)

## 🔒 Core Security & Safety Guarantees

SS-CCC is built for **local-first, privacy-preserving distributed AI** on Apple Silicon:

1. **Zero Cloud Telemetry / Zero Data Exfiltration**
   - Inference requests routed via `:8000/v1` (OpenAI/Anthropic) or `:11434` (Ollama) remain strictly within your local macOS machine, your Thunderbolt/LAN cluster (`10.99.x.x` / `192.168.x.x`), or encrypted WAN tunnels (**Tailscale**, **WireGuard**, **QUIC/Iroh P2P**).
   - No prompt data or hardware identifiers are transmitted to external analytics servers.

2. **macOS Memory Protection (`iogpu.wired_limit_mb`)**
   - SS-CCC enforces system RAM reserves (**4–8 GB per Mac**) and validates pool allocations before sharding or launching Multi-Model-Mode (MMM) workloads to prevent macOS WindowServer freezes or kernel OOM crashes.

3. **Thunderbolt `bridge0` & RDMA Safety**
   - Dedicated point-to-point TB scripts (`scripts/setup_tb_network.sh`) and preflight checks (`rdma_ctl`, `ifconfig bridge0 down`) guard against routing loops and kernel panics when coupling multi-cable Thunderbolt clusters.

4. **Safe GitHub Update Pipeline**
   - Update checks only read public GitHub release metadata (`version.json`, Releases API, `commits/main`) over HTTPS without executing unverified remote binaries. Source installs explicitly invoke `git pull --ff-only origin main` + local `swiftc` recompilation.

---

## 📣 Reporting a Vulnerability

If you discover a security issue in the SwiftUI app, FastAPI/WebSocket gateway (`core/`), or shell setup scripts (`scripts/`):

- Please **do not** disclose exploitable credentials, private room tokens, or remote execution details in public Issues before a patch is ready.
- Open a private **GitHub Security Advisory** under the repository's **Security** tab or contact the maintainers via GitHub.
- Include reproduction steps, affected version (`version.json`), macOS version, and Apple Silicon chip family.

Thank you for helping keep SS-CCC clusters safe and resilient.
