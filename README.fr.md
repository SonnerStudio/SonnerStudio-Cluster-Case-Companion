# ☀️ SonnerStudio Cluster-Case-Companion (SS-CCC)

> **🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

**SonnerStudio Cluster-Case-Companion (SS-CCC)** est un gestionnaire de cluster macOS natif et compagnon d'inférence (inspiré d'**EXO** et d'**Apple/Claris Harbor / Fabric**). Il mutualise la mémoire unifiée de plusieurs Mac Apple Silicon — par ex. **Mac Studio M5 Max (36 Go, Thunderbolt 5)** + **Mac mini M4 (16 Go, Thunderbolt 4)** pour former un **cluster IA de 52 Go physiques (~42 Go exploitables)** via **Thunderbolt (Bridge / RDMA)**, **LAN/WLAN** ou en mode **hybride**.

---

## ✨ Fonctionnalités principales

- **Mutualisation mémoire hétérogène de 52 Go :** Parallélisme pipeline pondéré par la mémoire (`~71 %` des couches + embeddings/LM-head sur M5 Max `460 Go/s`, `~29 %` sur M4 `120 Go/s`) avec garde-fou `iogpu.wired_limit_mb`.
- **Architecture hybride Control / Data Plane :**
  - **Control Plane (LAN/WLAN) :** Découverte Bonjour/mDNS (`_ssccc._tcp.local.`), heartbeats, passerelle API et téléchargement de modèles.
  - **Data Plane (Thunderbolt 4/5 ou RDMA) :** Adresses IP point-à-point isolées (`10.99.1.x`) pour `mlx.distributed` (`ring` TCP/IP à 30–37 Gbps réels ou `jaccl` RDMA `<50 µs`).
- **Console Studio SwiftUI native (*Solaris Telemetry Lab*) :**
  - **Vue d'ensemble du cluster :** Topologie en direct, flux animé et jauge du pool de 52 Go.
  - **Appareils & Comparaison :** Lecture matérielle en direct (`sysctl`, `sw_vers`, `ibv_devices`, `ipconfig`) avec comparaison côte à côte.
  - **Model Studio :** Partitionnement proportionnel, quantification du cache KV (`FP16 / 8-bit / 4-bit`) et intégration **oMLX**, **Ollama** et **llama.cpp**.
  - **Agents & IDEs (1 clic) :** Configuration instantanée pour **OpenCode**, **Hermes Agent** et **Google Antigravity (AGY)**.
  - **Recherche & Roofline :** Fondements scientifiques (*Splitwise/DistServe*, *SpecPipe*, `MLX_METAL_FAST_SYNCH=1`).

---

## 🚀 Démarrage rapide (macOS Apple Silicon)

```bash
# 1. Lancer l'application native SwiftUI
"./scripts/run_ssccc.sh"

# 2. (Optionnel) Démarrer la passerelle Python/FastAPI (requiert uv)
cd core && uv sync --extra dev
PYTHONPATH=".." uv run uvicorn core.api.gateway:app --host 0.0.0.0 --port 8000
```

---

## 📄 Licence

Distribué sous [Licence MIT](LICENSE.md).
