# ☀️ SonnerStudio Cluster-Case-Companion (SS-CCC)

> **🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

**SonnerStudio Cluster-Case-Companion (SS-CCC)** es una aplicación nativa para macOS de gestión de clústeres e inferencia distribuida (inspirada en **EXO** y **Apple/Claris Harbor / Fabric**). Permite unificar la memoria de varios Mac con Apple Silicon — por ejemplo, **Mac Studio M5 Max (36 GB, Thunderbolt 5)** + **Mac mini M4 (16 GB, Thunderbolt 4)** para obtener un **clúster de IA de 52 GB físicos (~42 GB utilizables)** mediante **Thunderbolt (Bridge / RDMA)**, **LAN/WLAN** o modo **híbrido**.

---

## ✨ Características principales

- **Agrupación heterogénea de 52 GB:** Paralelismo en pipeline ponderado por memoria (`~71 %` de capas en M5 Max `460 GB/s`, `~29 %` en M4 `120 GB/s`) con protección segura de `iogpu.wired_limit_mb`.
- **Arquitectura híbrida Control / Data Plane:**
  - **Control Plane (LAN/WLAN):** Descubrimiento Bonjour/mDNS (`_ssccc._tcp.local.`), latidos, pasarela API y descargas de modelos.
  - **Data Plane (Thunderbolt 4/5 o RDMA):** IPs punto a punto aisladas (`10.99.1.x`) para `mlx.distributed` (`ring` TCP/IP a 30–37 Gbps reales o `jaccl` RDMA `<50 µs`).
- **Consola nativa SwiftUI (*Solaris Telemetry Lab*):**
  - **Vista del clúster:** Topología en vivo y barra de memoria de 52 GB.
  - **Dispositivos y comparación:** Lectura de hardware en directo (`sysctl`, `sw_vers`, `ibv_devices`, `ipconfig`) y comparativa visual.
  - **Model Studio:** División proporcional de capas, cuantización de caché KV (`FP16 / 8-bit / 4-bit`) e integración con **oMLX**, **Ollama** y **llama.cpp**.
  - **Agentes e IDEs (1 clic):** Configuración directa para **OpenCode**, **Hermes Agent** y **Google Antigravity (AGY)**.
  - **Ciencia y Roofline:** Basado en *Splitwise/DistServe*, *SpecPipe* y `MLX_METAL_FAST_SYNCH=1`.

---

## 🚀 Inicio rápido (macOS Apple Silicon)

```bash
# 1. Iniciar la app nativa SwiftUI
"./scripts/run_ssccc.sh"

# 2. (Opcional) Iniciar la pasarela Python/FastAPI (requiere uv)
cd core && uv sync --extra dev
PYTHONPATH=".." uv run uvicorn core.api.gateway:app --host 0.0.0.0 --port 8000
```

---

## 📄 Licencia

Publicado bajo la [Licencia MIT](LICENSE.md).
