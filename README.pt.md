# ☀️ SonnerStudio Cluster-Case-Companion (SS-CCC)

> **🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

**SonnerStudio Cluster-Case-Companion (SS-CCC)** é uma aplicação nativa para macOS para criação, gestão e inferência distribuída em clusters (inspirada no **EXO** e no **Apple/Claris Harbor / Fabric**). Permite acoplar a memória unificada de vários Macs Apple Silicon — por exemplo, **Mac Studio M5 Max (36 GB, Thunderbolt 5)** + **Mac mini M4 (16 GB, Thunderbolt 4)** num **cluster de IA com 52 GB físicos (~42 GB utilizáveis)** via **Thunderbolt (Bridge / RDMA)**, **LAN/WLAN** ou modo **híbrido**.

---

## ✨ Principais funcionalidades

- **Agrupamento heterogéneo de 52 GB:** Paralelismo em pipeline ponderado por memória (`~71 %` das camadas no M5 Max `460 GB/s`, `~29 %` no M4 `120 GB/s`) com proteção segura via `iogpu.wired_limit_mb`.
- **Arquitetura híbrida Control / Data Plane:**
  - **Control Plane (LAN/WLAN):** Descoberta Bonjour/mDNS (`_ssccc._tcp.local.`), heartbeats, gateway API e transferência de modelos.
  - **Data Plane (Thunderbolt 4/5 ou RDMA):** IPs ponto a ponto isolados (`10.99.1.x`) para `mlx.distributed` (`ring` TCP/IP a 30–37 Gbps reais ou `jaccl` RDMA `<50 µs`).
- **Consola nativa SwiftUI (*Solaris Telemetry Lab*):**
  - **Visão do Cluster:** Topologia em tempo real e barra de memória de 52 GB.
  - **Dispositivos e Comparação:** Leitura direta de hardware (`sysctl`, `sw_vers`, `ibv_devices`, `ipconfig`) com comparação lado a lado.
  - **Model Studio:** Divisão proporcional de camadas, quantização da cache KV (`FP16 / 8-bit / 4-bit`) e integração com **oMLX**, **Ollama** e **llama.cpp**.
  - **Agentes e IDEs (1 clique):** Configuração imediata para **OpenCode**, **Hermes Agent** e **Google Antigravity (AGY)**.
  - **Ciência e Roofline:** Fundamentado em *Splitwise/DistServe*, *SpecPipe* e `MLX_METAL_FAST_SYNCH=1`.

---

## 🚀 Arranque rápido (macOS Apple Silicon)

```bash
# 1. Iniciar a app nativa SwiftUI
"./scripts/run_ssccc.sh"

# 2. (Opcional) Iniciar o gateway Python/FastAPI (requer uv)
cd core && uv sync --extra dev
PYTHONPATH=".." uv run uvicorn core.api.gateway:app --host 0.0.0.0 --port 8000
```

---

## 📄 Licença

Licenciado sob a [Licença MIT](LICENSE.md).
