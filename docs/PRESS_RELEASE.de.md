# Pressemitteilung: SonnerStudio Cluster-Case-Companion (SS-CCC) v1.6.44 — 17 Sprachen, Multi-Model-Mode, 6-Reiter-Forschungslabor & Menüleisten-Hintergrunddienst

**16. November 2026 — SonnerStudio** veröffentlicht den aktuellen Meilenstein **v1.6.44** des **SonnerStudio Cluster-Case-Companion (SS-CCC)**. Die quelloffene macOS-Anwendung in nativem SwiftUI vereint beliebige Apple-Silicon-Macs (**M1–M12+**) über **Thunderbolt 3/4/5**, **RDMA (`JACCL`)** sowie **weltweite Internet-WAN-Brücken** zu einem gemeinsamen Speicher- und Rechenverbund für lokale KI-Modelle (**MLX**, **oMLX**, **Ollama**, **llama.cpp**) und Entwickler-Agenten.

![SonnerStudio Cluster-Case-Companion Ökosystem](images/ssccc_ecosystem_banner.jpg)

---

### Die wichtigsten Neuerungen & aktueller Entwicklungsstand

1. **Beliebige Apple-Silicon-Macs (M1–M12+) & Hardware-Vollauslesung**
   SS-CCC unterstützt sämtliche **Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio und Mac Pro** von **M1–M6** bis **M7–M12+**. Neben CPU-P/E-Kernen erfasst SS-CCC auch **GPU- und Neural-Engine-(ANE-)Kerne**, NVMe-SSD-Speicher, Thermik sowie Leistungsaufnahme; die Schutzgrenze `iogpu.wired_limit_mb` verhindert Speicherüberläufe.

2. **Weltweiter Internet-WAN-Verbund, Audio-Party & Multi-Model-Mode (MMM)**
   Über **Tailscale / WireGuard**, **QUIC / Iroh P2P (0-RTT)** und **libp2p/DERP** lassen sich lokale TB/RDMA-Cluster als Tier-0-Inseln in weltweite Verbünde (`2–256+` Macs) einkoppeln — begleitet von WebSocket-Chat (`/ws/wan/{room_id}`) und konsolenartigem **`AVAudioEngine` Cluster Audio-Party**. Der **Multi-Model-Mode (MMM)** betreibt mehrere Modelle gleichzeitig (*Parallel Pool*, *MoA*, *EAGLE-3 / Speculative Decoding*, *Tree-MoA*, *Ares*) für **Cursor**, **VS Code**, **Xcode**, **OpenCode**, **Hermes Agent** und **Google Antigravity** über `:8000/v1`.

   ![Weltweiter Internet-WAN-Verbund und Teilnehmergespräch](images/ssccc_internet_wan_mesh.jpg)

3. **6-Reiter-Forschungslabor & Verlaufsaufzeichnung**
   **Forschung & Leistung** bietet sechs spezialisierte Auswertungsbereiche für **Lokal (TB/RDMA)**, **Internet-WAN** und **Direktvergleich**: **Grenzkurve & Engpass (Roofline)**, **WAN-Netz & Skalierung (`N = 1..128`, *Petals/SWARM*, *DiLoCo*)**, **Speicher & KV-Analyse (`ANE-Split`, `3-Tier CacheGen`)**, **Energie, CO₂ & Kosten (`J/Token`, `EDP`)**, **Messreihen (`CI₉₅`, `CV%`, `Goodput%`, `CSV / JSON / LaTeX / BibTeX`)** sowie **Verlaufsaufzeichnung**.

   ![Wissenschaftliche Grenzkurven- und Energieanalyse](images/ssccc_science_roofline_hero.jpg)

4. **Menüleisten-Hintergrunddienst (`⌘⇧M`), Solaris Dock-Symbol, Auto-Setup & 17 Sprachen**
   - **Menüleisten-Modus & Dock-Symbol:** Beim Minimieren wechselt SS-CCC direkt neben **Ollama** in die obere macOS-Menüleiste (`.accessory`-Dienst) samt Live-Anzeigen (Bereitschaft, Pool-GB, Knoten, Modell/Schichten, MMM) und 1-Klick-Kopieren von `:8000/v1` & `:11434`, ergänzt durch ein modernes **Solaris-Dock-Symbol**.
   - **Auto-Setup & Bereitschaftsprüfung:** Der 11. Bereich **Setup & Einrichten** erkennt Macs automatisch und meldet den 4-stufigen Bereitschaftsstatus.
   - **17 Sprachen & globale Qualitätssicherung (`25/25` Tests):** Vollständige Übersetzung der gesamten Oberfläche, des 12-Kapitel-Handbuchs, der Hover-Kurztipps und aller README-Dateien in **Deutsch, Englisch, Französisch, Spanisch, Portugiesisch, Russisch, Japanisch, Chinesisch, Niederländisch, Afrikaans, Polnisch, Tschechisch, Slowakisch, Ungarisch, Koreanisch, Hindi und Tamil**.

---

### Verfügbarkeit, Wiki & Quellcode

- **GitHub-Repository:** https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion
- **Projekt-Wiki:** https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion/wiki
- **Schnellstart auf Apple Silicon (macOS 14.0+):**
  ```bash
  git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
  cd SonnerStudio-Cluster-Case-Companion
  chmod +x scripts/run_ssccc.sh && ./scripts/run_ssccc.sh
  ```
