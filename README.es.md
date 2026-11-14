<div align="center">

# ☀️ Asistente de conjunto SonnerStudio (SS-CCC)

**🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

*Gestor nativo para macOS de conjuntos Apple Silicon y taller de inferencia distribuida MLX*

![Interfaz SS-CCC](docs/images/ssccc_hero_screenshot_v2.png)

</div>

---

## 🧭 Resumen

El **Asistente de conjunto SonnerStudio (SS-CCC)** une la memoria unificada de varios equipos Apple Silicon — por ejemplo, un **Mac Studio M5 Max (36 GB, Thunderbolt 5)** y un **Mac mini M4 (16 GB, Thunderbolt 4)** — en un **conjunto de 52 GB físicos (~42 GB útiles)** mediante **Thunderbolt (puente o acceso directo)**, **red cableada/inalámbrica** o modo **híbrido**.

<div align="center">
  <img src="docs/images/cluster_topology_graphic.png" alt="Mac Studio M5 Max y Mac mini M4 unidos por Thunderbolt" width="88%"/>
</div>

---

## 🏗️ Arquitectura híbrida (plano de control y plano de datos)

```mermaid
flowchart LR
  Clients["OpenCode · Hermes Agent · Antigravity · oMLX · Ollama · llama.cpp"] -->|"Interfaz (:8000 / :11434)"| Studio
  subgraph Control["Plano de control (red cableada / inalámbrica)"]
    Discovery["Descubrimiento Bonjour y latidos"]
  end
  subgraph Data["Plano de datos (Thunderbolt 4/5 · 30–37 Gbps)"]
    Studio["Mac Studio M5 Max (36 GB · ~71 % capas)"] <-->|"MLX ring / jaccl + FAST_SYNCH=1 (~4 µs)"| Mini["Mac mini M4 (16 GB · ~29 % capas)"]
  end
```

---

## ✨ Funciones principales

- **Unión heterogénea de 52 GB:** Reparto proporcional de capas (`~71 %` en el M5 Max a `460 GB/s`, `~29 %` en el M4 a `120 GB/s`) con protección segura de `iogpu.wired_limit_mb`.
- **Interfaz nativa macOS:**
  - **Resumen y comparación de equipos:** Lectura directa (`sysctl`, `sw_vers`, `ibv_devices`, `ipconfig`) con comparación visual.
  - **Taller de modelos:** Reparto de capas, compresión de caché KV (`FP16 / 8-bit / 4-bit`) y enlace directo con **oMLX**, **Ollama** y **llama.cpp**.
  - **Agentes y entornos (un clic):** Configuración directa para **OpenCode**, **Hermes Agent** y **Google Antigravity**.
  - **Interfaz multilingüe:** Selector de idioma en el menú lateral izquierdo.

---

## 🚀 Inicio rápido

```bash
"./scripts/run_ssccc.sh"
```

---

## 📄 Licencia

Publicado bajo la [Licencia MIT](LICENSE.md).
