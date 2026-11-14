<div align="center">

# ☀️ Asistente de conjunto SonnerStudio (SS-CCC)

**🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

*Gestor nativo para macOS de conjuntos Apple Silicon y taller de inferencia distribuida MLX*

<table>
  <tr>
    <td align="center">
      <img src="docs/images/ssccc_cluster_52gb.png" alt="SS-CCC Modo Conjunto 52 GB" width="100%"/><br/>
      <sub><b>Modo Conjunto (52 GB unificados · 2 equipos)</b></sub>
    </td>
    <td align="center">
      <img src="docs/images/ssccc_single_16gb.png" alt="SS-CCC Modo Individual 16 GB" width="100%"/><br/>
      <sub><b>Modo Individual (16 GB local · 1 equipo)</b></sub>
    </td>
  </tr>
</table>

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

- **Unión universal Apple Silicon (M1 – M6):** Conecta libremente varios Mac (Mac mini, MacBook Air/Pro, iMac, Mac Studio, Mac Pro) de las generaciones M1 a M6 en una agrupación común con cálculo automático del ancho de banda de memoria (`68 GB/s` a `819+ GB/s`).
- **Telemetría completa de equipo y sensores:** Lectura directa mediante `sysctl`, `sw_vers`, `system_profiler`, `ioreg`, `pmset` e `ibv_devices`: núcleos CPU (P/E), núcleos GPU, núcleos del motor neuronal (16 / 32 núcleos ANE), espacio SSD total/libre, estado térmico, temperatura de batería (`°C`) y consumo eléctrico (`W`).
- **Clases Thunderbolt 3 / 4 / 5 y RDMA:** Detección y clasificación automáticas para chips M1–M6 (TB3 `40 Gbps`, TB4 `40 Gbps`, TB5 `80/120 Gbps`, además de RDMA sobre Thunderbolt 5), con plano de control LAN/Wi-Fi separado y plano de datos Thunderbolt aislado.
- **Reparto ponderado de capas y protección `iogpu.wired_limit_mb`:** Distribución proporcional según el ancho de banda de memoria (p. ej., `~71 %` en el M5 Max a `460 GB/s`, `~29 %` en el M4 a `120 GB/s`) manteniendo una reserva segura del sistema para macOS.
- **Taller de modelos (MLX, oMLX, Ollama y llama.cpp):** Compresión de caché KV (`FP16 / 8-bit / 4-bit`), selección de motores y ajuste de distribución de capas en la agrupación.
- **Agentes y entornos en un clic:** Configuración inmediata para **OpenCode**, **Hermes Agent**, **Google Antigravity**, **Cursor**, **Visual Studio Code** y **Xcode**.
- **Modo de simulación conmutable y tema amarillo SonnerStudio (`#FFD400`):** El nodo simulado Mac Studio (M5 Max / 36 GB) puede activarse o desactivarse en cualquier momento desde la barra lateral sin alterar la telemetría real.
- **Interfaz multilingüe y centro de ayuda integrado:** Cambio inmediato entre inglés, alemán, francés, español y portugués, además de un centro de ayuda con búsqueda directa dentro de la aplicación.

### 🖥️ Las ocho áreas del programa de un vistazo

| Área | Contenido y función |
| :--- | :--- |
| **1. Resumen de agrupación** | Memoria conjunta, nodos activos, velocidad del enlace de datos, topología visual y barra de asignación `iogpu.wired_limit_mb`. |
| **2. Equipos y comparación** | Telemetría en directo de cada Mac (CPU, GPU, ANE, RAM, ancho de banda, SSD, temperatura, potencia) y adición de Mac M1–M6. |
| **3. Taller de modelos** | Reparto proporcional de capas, ajuste de caché KV y enlace con **oMLX**, **Ollama** y **llama.cpp**. |
| **4. Red y RDMA** | Matriz de clases Thunderbolt 3/4/5 para M1–M6, estado RDMA y enrutamiento del puente LAN/Thunderbolt. |
| **5. Agentes y entornos** | Configuración en un clic para **OpenCode**, **Hermes Agent**, **Antigravity**, **Cursor**, **Visual Studio Code** y **Xcode**. |
| **6. Ciencia y Roofline** | Gráfico logarítmico interactivo (`P = min(β·I, π)`), puntos de inflexión, fórmula GPipe, TTFT/TPOT, energía `J/token`, ensayos reproducibles (`T=0,0`, `p50/p95/p99`) y exportación CSV/JSON/BibTeX |
| **7. API y consola** | Puntos de acceso compatibles con OpenAI / Ollama / oMLX, registro de actividad y órdenes de arranque listas para copiar. |
| **8. Ayuda y documentación** | Manual integrado con búsqueda de texto completo, vista general de arquitectura y guía paso a paso. |

---

## 🛠️ Compilar desde el código fuente (antes del primer uso)

> [!NOTE]
> Este repositorio contiene el **código fuente en Swift** de SS-CCC (no se incluye un programa ya compilado). Para obtener una versión ejecutable, primero debes **compilar el código localmente en tu Mac con Apple Silicon**.

### Requisitos previos
- Un Mac con Apple Silicon (**M1–M6**) y **macOS 14.0 o posterior**
- **Herramientas de línea de comandos de Xcode** (incluyen `swiftc` y el SDK de macOS):
  ```bash
  xcode-select --install
  ```

### Paso a paso hasta el programa ejecutable
```bash
# 1. Clonar el repositorio y entrar en la carpeta
git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
cd SonnerStudio-Cluster-Case-Companion

# 2. Dar permisos de ejecución al guion de compilación y arranque
chmod +x scripts/run_ssccc.sh

# 3. Compilar los archivos Swift en /tmp/SSCCCApp y abrir el programa
./scripts/run_ssccc.sh
```
*(Opcional: también se puede compilar con Swift Package Manager mediante `cd app && swift build -c release`.)*

---

## 🚀 Inicio rápido

```bash
"./scripts/run_ssccc.sh"
```

---

## 📚 Documentación seleccionada (incluida en la ayuda del programa)

### 1. Todos los Mac con procesador M en conjunto (M1–M6)
SS-CCC admite **cualquier Mac con procesador Apple Silicon** (**M1, M2, M3, M4, M5, M6** — Base, Pro, Max y Ultra): **Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio y Mac Pro**. En **Equipos y comparación** puedes añadir tantos Mac como necesites; el equipo con mayor ancho de banda asume automáticamente el **rango 0 (coordinador)**.

| Familia de chip | Ancho de banda | Thunderbolt | Reserva recomendada para macOS |
| :--- | :--- | :--- | :--- |
| **M1 / M2** (Base) | 68 – 100 GB/s | TB 3 / USB4 (26–32 Gbps) | **4 GB** (≤ 24 GB RAM) |
| **M3 / M4** (Base) | 100 – 120 GB/s | TB 4 (30–37 Gbps) | **4 GB** (≤ 24 GB RAM) |
| **M5 / M6** (Base) | 153 – 180 GB/s | TB 5 (65–80 Gbps) | **4 GB** (≤ 24 GB RAM) |
| **M1–M3 Pro** | 150 – 200 GB/s | TB 4 (30–37 Gbps) | **4 – 6 GB** |
| **M4–M6 Pro** | 273 – 310 GB/s | TB 5 (65–80 Gbps) | **4 – 6 GB** |
| **M1–M3 Max** | 400 GB/s | TB 4 (30–37 Gbps) | **6 GB** (32–64 GB RAM) |
| **M4–M6 Max** | 460 – 580 GB/s | TB 5 (65–80 Gbps) | **6 GB** (32–64 GB RAM) |
| **M1–M2 Ultra** / **M3 Ultra** | 800 GB/s | TB 4 / TB 5 | **8 GB** (≥ 96 GB RAM) |

### 2. Protección de memoria y reparto ponderado
- **Nunca asignar el 100 % de la RAM:** `iogpu.wired_limit_mb` protege la estabilidad de macOS y WindowServer.
- **Reparto proporcional de capas:** cada Mac recibe capas según su memoria utilizable (`Capas_i = Total × Utilizable_i / TotalUtilizable`).
- **Caché KV de 4 bits y sincronización rápida:** `--kv-bits 4` y `MLX_METAL_FAST_SYNCH=1` (45× más rápido, ~180 µs → ~4 µs).

---

## 🚧 Estado de desarrollo y colaboración

> [!IMPORTANT]
> **SS-CCC ya se puede compilar y ejecutar, pero sigue en fase activa de desarrollo y pruebas.**
> La interfaz, la lectura del equipo, el reparto ponderado de capas y la conexión con agentes ya funcionan; las pruebas reales con distintas combinaciones de Mac M1–M6, puentes Thunderbolt 4/5 y RDMA/JACCL continúan perfeccionándose.

Animamos a desarrolladores, investigadores y entusiastas de Apple Silicon a **colaborar y seguir haciendo crecer SS-CCC**:
- **Probar en tu equipo:** Ejecuta SS-CCC en tus Mac M1–M6 y comparte resultados de rendimiento, memoria y estabilidad.
- **Enviar avisos e ideas:** Abre un aviso en GitHub para errores, casos concretos o nuevas propuestas.
- **Aportar mejoras:** ¡Cualquier mejora en SwiftUI, en el reparto MLX, en los guiones de Thunderbolt o en las traducciones es bienvenida!

---

## 📄 Licencia

Publicado bajo la [Licencia MIT](LICENSE.md).
