<div align="center">

# ☀️ Compagnon de grappe SonnerStudio (SS-CCC)

**🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

*Gestionnaire natif macOS de grappe Apple Silicon et atelier d'inférence MLX répartie*

![Interface SS-CCC](docs/images/ssccc_hero_screenshot_v2.png)

</div>

---

## 🧭 Présentation

Le **Compagnon de grappe SonnerStudio (SS-CCC)** associe la mémoire unifiée de plusieurs Mac Apple Silicon — par exemple un **Mac Studio M5 Max (36 Go, Thunderbolt 5)** et un **Mac mini M4 (16 Go, Thunderbolt 4)** — pour former une **grappe de 52 Go physiques (~42 Go exploitables)** par **Thunderbolt (pont ou accès direct mémoire)**, **réseau filaire/sans fil** ou en mode **hybride**.

<div align="center">
  <img src="docs/images/cluster_topology_graphic.png" alt="Mac Studio M5 Max et Mac mini M4 reliés par Thunderbolt" width="88%"/>
</div>

---

## 🏗️ Architecture hybride (plan de contrôle et plan de données)

```mermaid
flowchart LR
  Clients["OpenCode · Hermes Agent · Antigravity · oMLX · Ollama · llama.cpp"] -->|"Interface (:8000 / :11434)"| Studio
  subgraph Control["Plan de contrôle (réseau filaire / sans fil)"]
    Discovery["Découverte Bonjour & battements de cœur"]
  end
  subgraph Data["Plan de données (Thunderbolt 4/5 · 30–37 Gbps)"]
    Studio["Mac Studio M5 Max (36 Go · ~71 % couches)"] <-->|"MLX ring / jaccl + FAST_SYNCH=1 (~4 µs)"| Mini["Mac mini M4 (16 Go · ~29 % couches)"]
  end
```

---

## ✨ Fonctionnalités principales

- **Couplage mémoire hétérogène de 52 Go :** Répartition pondérée des couches (`~71 %` des couches sur le M5 Max à `460 Go/s`, `~29 %` sur le M4 à `120 Go/s`) avec protection `iogpu.wired_limit_mb`.
- **Interface native macOS :**
  - **Vue de la grappe et comparaison :** Lecture directe du matériel (`sysctl`, `sw_vers`, `ibv_devices`, `ipconfig`) avec barres comparatives.
  - **Atelier de modèles :** Découpage proportionnel, compression du cache KV (`FP16 / 8-bit / 4-bit`) et liaison directe avec **oMLX**, **Ollama** et **llama.cpp**.
  - **Agents et environnements (en un clic) :** Configuration immédiate pour **OpenCode**, **Hermes Agent** et **Google Antigravity**.
  - **Interface multilingue :** Sélecteur de langue intégré dans le menu latéral gauche.

---

## 🚀 Démarrage rapide

```bash
"./scripts/run_ssccc.sh"
```

---

## 📚 Extraits de la documentation (intégrés dans l'aide de l'application)

### 1. Tous les Mac à puce Apple M en grappe (M1–M6)
SS-CCC prend en charge **chaque Mac équipé d'une puce Apple Silicon** (**M1, M2, M3, M4, M5, M6** — Base, Pro, Max et Ultra) : **Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio et Mac Pro**. Sous **Appareils et comparaison**, ajoutez autant de Mac que souhaité ; celui offrant le plus haut débit mémoire prend automatiquement le **rang 0 (maître)**.

| Famille de puces | Débit mémoire | Thunderbolt | Réserve macOS conseillée |
| :--- | :--- | :--- | :--- |
| **M1 / M2 / M3** (Base) | 68 – 100 Go/s | TB 4 | **4 Go** (≤ 24 Go RAM) |
| **M4 / M5 / M6** (Base) | 120 – 180 Go/s | TB 4 / TB 5 | **4 Go** (≤ 24 Go RAM) |
| **M1–M6 Pro** | 150 – 273 Go/s | TB 4 / TB 5 | **4 – 6 Go** |
| **M1–M6 Max** | 400 – 546 Go/s | TB 4 / TB 5 | **6 Go** (32–64 Go RAM) |
| **M1–M3 Ultra** | 800 Go/s | TB 4 | **8 Go** (≥ 96 Go RAM) |

### 2. Protection mémoire et répartition pondérée
- **Ne jamais allouer 100 % de la RAM :** `iogpu.wired_limit_mb` préserve la fluidité de macOS et de WindowServer.
- **Répartition proportionnelle des couches :** chaque Mac reçoit une part calculée sur sa mémoire utilisable (`Couches_i = Total × Utilisable_i / TotalUtilisable`).
- **Cache KV 4 bits & synchronisation rapide :** `--kv-bits 4` et `MLX_METAL_FAST_SYNCH=1` (45× plus rapide, ~180 µs → ~4 µs).

---

## 📄 Licence

Publié sous [Licence MIT](LICENSE.md).
