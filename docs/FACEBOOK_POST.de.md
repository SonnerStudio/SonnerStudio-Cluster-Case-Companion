☀️ **Großes Release-Update: SonnerStudio Cluster-Case-Companion (SS-CCC) v1.6.44 — Wie aus einzelnen Apple-Silicon-Macs ein gemeinsamer KI-Supercomputer wird!** 🚀🍏

Viele Entwicklerinnen und Entwickler, Kreative, Forschungsgruppen und Unternehmen stehen heute vor derselben Frage:
Wie lassen sich moderne, große Sprachmodelle (LLMs mit 32B, 70B, 405B oder sogar 671B+ Parametern) **lokal, datenschutzkonform und ohne laufende Cloud-Gebühren** betreiben – und wie versorgt man gleichzeitig mehrere Entwicklungsumgebungen (IDEs) und autonome KI-Agenten mit voller Rechenleistung?

Genau für diese Aufgabe haben wir den **SonnerStudio Cluster-Case-Companion (SS-CCC)** geschaffen. Die quelloffene, nativ in SwiftUI für macOS entwickelte Studio-Anwendung bündelt den Unified Memory (gemeinsamen Arbeitsspeicher) und die Rechenkraft beliebiger **Apple-Silicon-Macs (M1 bis M12+)** zu einem einzigen, intelligent gesteuerten KI-Rechenverbund!

---

### 💡 Was ist der Sinn und Zweck von SS-CCC?

Ein einzelner Mac mini, iMac oder ein MacBook Pro stößt bei sehr großen Sprachmodellen oder beim parallelen Einsatz mehrerer Spezialmodelle irgendwann an seine Speichergrenze. Sobald jedoch zwei, vier oder noch mehr Macs zusammengeschlossen werden, entsteht ein gewaltiger gemeinsamer Speicherpool:

- **Lokal am Schreibtisch oder im Büro:** Über **Thunderbolt 3, 4 und 5** (Punkt-zu-Punkt, Ring oder Vollvermaschung), **10GbE-LAN** sowie Apples ultraschnelles **Thunderbolt-5-RDMA (`JACCL`)** mit nur `~3 µs` Latenz zwischen den Knoten und `MLX_METAL_FAST_SYNCH=1` (45× schnellere GPU/CPU-Synchronisation).
- **Weltweit über das Internet (WAN):** Über verschlüsselte Brücken (**Tailscale / WireGuard**, **QUIC / Iroh P2P mit 0-RTT** oder **libp2p / DERP**) lassen sich Macs über Städte, Universitäten oder Kontinente hinweg zu einem gemeinsamen Cluster (2 bis 256+ Macs) verbinden.
- **Hybrid-Betrieb (Lokal + Internet gleichzeitig):** Schnelle lokale Thunderbolt-Inseln (Tier 0) lassen sich per 1-Klick-Brücke nahtlos mit entfernten Internet-Knoten (Tier 1) koppeln.
- **100 % Datenschutz & volle Kostenkontrolle:** Alle Prompts, Quellcodes und sensiblen Dokumente aus Kanzleien, Medizin, Forschung oder Software-Studios bleiben auf der eigenen Hardware bzw. in den eigenen verschlüsselten Tunneln – ohne API-Abos und ohne Datenabfluss.

---

### 🛠️ Aktueller Entwicklungsstand (Version v1.6.44 · 25/25 automatisierte Tests bestanden)

SS-CCC ist vollständig lauffähig, im echten Hardwarebetrieb (ohne Mock-Daten bei deaktivierter Simulation) einsetzbar und umfasst aktuell **11 spezialisierte Programm-Module**:

1. **📊 Verbund-Übersicht (Cluster Overview):**
   Drei umschaltbare Ansichten (**Lokaler Cluster**, **Internet-Cluster**, **Lokal + Internet**) mit Echtzeit-Speicherbalken, automatischer Rang-0-Leitrechner-Zuweisung nach Speicherbandbreite, Sicherheitsreserve (`iogpu.wired_limit_mb`, 4–8 GB für macOS geschützt) und 4-stufiger Betriebsbereitschafts-Anzeige.
2. **💻 Geräte & Vergleich (Devices & Compare):**
   Unterstützt alle Apple-Silicon-Generationen von **M1 bis M6** (inkl. M5 Max/Ultra & M6 2nm) und zukunftssicher **M7 bis M12+**. Liest live **CPU-P/E-Kerne, GPU-Kerne, Neural-Engine-(ANE-)Kerne**, NVMe-SSD-Kapazität, thermischen Zustand und Stromverbrauch (Watt) jedes Knotens aus.
3. **🧪 Modell Werkstatt (Model Studio):**
   Erkennt automatisch alle real installierten und laufenden Modelle aus **oMLX**, **Ollama**, **llama.cpp**, lokalen `.gguf`-Dateien und dem HuggingFace-Cache (`~/.cache/huggingface/hub`). Inklusive speichergewichteter Schichten-Aufteilung (Layer Sharding), **Disaggregiertem Prefill/Decode (ANE-Split)** sowie **3-stufigem KV-Cache / CacheGen** (`RAM → NVMe SSD → Peer`).
4. **⚡ Netzwerk & Direktspeicher (Network & RDMA):**
   Umschalten zwischen Auto-Hybrid, Thunderbolt-Only, LAN/WLAN und **TB5 RDMA / JACCL Full-Mesh Tensor Parallelism**, inklusive `bridge0`-Schutz gegen Kernel-Panics und fertigen `mlx.distributed_config`-Hostfiles.
5. **🌐 Internet-Verbund, Live-Chat & Cluster Audio-Party:**
   Integrierter **WAN-Bandbreiten- & Durchsatz-Monitor** (`netstat`, ICMP-Ping/Jitter, `networkQuality`), Echtzeit-WebSocket-Chat (`/ws/wan/{room_id}`) sowie eine Sprachkonferenz im Konsolen-Stil (**Cluster Audio-Party** über `AVAudioEngine` mit Push-to-Talk, Open-Mic, Noise-Gate und Pegelanzeige).
6. **🧠 Multi-Model-Mode (MMM):**
   Orchestriert **mehrere KI-Modelle gleichzeitig** über lokale, WAN- oder Hybrid-Cluster:
   - *Parallel Multi-Model Pool* (mehrere Spezialmodelle gleichzeitig im RAM halten)
   - *Mixture-of-Agents (MoA)* (mehrere Expertenmodelle + Aggregator)
   - *Speculative Decoding & EAGLE-3* (schnelles Draft-Modell auf kleinem Mac + großes 70B+-Target-Modell für $1,6\times$–$2,3\times$ Tempo)
   - *Sequential Pipeline, Tree-MoA Early-Exit & Ares Adaptive Router*
   Inklusive **1-Klick-Auto-Setup** und nachträglichem **Live-Slot-Editor**.
7. **🤖 Agenten & Entwicklungsumgebungen (Agents & IDEs):**
   Sofortige 1-Klick-Konfiguration und gleichzeitige Nutzung über `:8000/v1` für **Cursor**, **Visual Studio Code**, **Apple Xcode**, **OpenCode**, **Hermes Agent** und **Google Antigravity** – inklusive **OpenAI `/v1/responses`**, **MCP Server Registry JSON** und **A2A Agent Cards** (`/.well-known/agent.json`).
8. **🔬 6-Reiter-Forschungslabor (Science & Roofline):**
   Wissenschaftliche Auswertung mit echten SSE-Streaming- & ICMP-Messungen:
   - *Log-Log-Roofline & Engpass-Analyse* ($B^*$ kritische Batch-Größe)
   - *WAN-Topologie & Skalierung* ($N = 1 \dots 128$ Knoten, *Petals/SWARM*-Kompression, *DiLoCo* vs. DDP)
   - *Speicher- & KV-Analyse*
   - *Energie, CO₂ & Stromkosten* (`J/Token`, `EDP`, regionaler Strommix `gCO₂eq/kWh`)
   - *Reproduzierbare Messreihen* (`T = 0,0`, `p50/p95/p99`, `CI₉₅`, `CV%`, `Goodput%`) mit direktem Export als **CSV, JSON-Manifest, LaTeX (`booktabs`) und BibTeX**
   - *Verlaufsaufzeichnung (History Recording)* pro Position oder global mit Trend-Diagrammen.
9. **🖥️ Schnittstelle & Konsole (API & Console):**
   Direktes Testen aller OpenAI-, Ollama- und oMLX-Endpunkte sowie Live-Cluster-Prompts.
10. **🔧 Setup & Einrichten (Setup & Provision):**
    Automatische Erkennung lokaler Macs (Bonjour/mDNS) und WAN-Peers, automatische SSH-Trust- und `iogpu.wired_limit_mb`-Einrichtung sowie **4-stufiger Betriebsbereitschafts-Check** (*Bereit / Nicht bereit / Unvollständig eingerichtet / Uneingerichtet*).
11. **📖 Interaktives 12-Kapitel-Handbuch & Hover-Shorttips:**
    Klickbare Detail-Karten mit Architektur-Grafiken, Schritt-für-Schritt-Anleitungen und programmweiten Kurzerklärungen im **Solaris-Shorttip-Balken**.

---

### 🛰️ NEU: Menüleisten-Hintergrunddienst (`⌘⇧M`) & Modernes Solaris-Dock-Symbol

Sobald der Cluster eingerichtet und betriebsbereit ist, arbeitet SS-CCC auf Wunsch völlig unsichtbar im Hintergrund als reiner **Dienstleister für IDEs und KI-Agenten**:
- Beim Minimieren des Fensters, per Klick auf **„In Menüleiste“** oder per Tastenkürzel **`⌘⇧M`** wandert SS-CCC direkt neben **Ollama** in die obere macOS-Menüleiste.
- Das **Menüleisten-Popover** zeigt übersichtlich alle Live-Werte (**Bereitschaftsstatus**, **Verbund- & nutzbaren RAM in GB**, **aktive Knoten**, **geladenes Modell & Schichten**, **aktive Laufzeit & MMM-Slots** sowie **verbundene IDEs/Agenten**) und bietet **1-Klick-Kopierbuttons** für die Endpunkte `http://127.0.0.1:8000/v1` und `http://127.0.0.1:11434`.
- In der unteren macOS-Programmleiste (Dock) erstrahlt SS-CCC zudem mit einem neuen, hochauflösenden **Solaris-Programmsymbol (`1024×1024`)**.
- Über den integrierten **GitHub Auto-Updater (`⌘U`)** hält sich jede Installation auf Wunsch per 1-Klick auf dem neuesten Stand.

---

### 🌍 Weltweit zu Hause: Vollständig in 17 Sprachen übersetzt!

Sowohl die gesamte Programmoberfläche mit allen 11 Modulen, Untermenüs, Tabellen, Buttons und Kurztipps als auch das komplette 12-Kapitel-Handbuch und alle 17 README-Dokumentationen auf GitHub stehen Wort für Wort in **17 Sprachen** bereit:

1. 🇩🇪🇦🇹🇨🇭 **Deutsch**
2. 🇺🇸🇬🇧🇨🇦 **Englisch (English)**
3. 🇫🇷🇧🇪🇨🇭 **Französisch (Français)**
4. 🇪🇸🇲🇽🇦🇷 **Spanisch (Español)**
5. 🇵🇹🇧🇷 **Portugiesisch (Português)**
6. 🇷🇺 **Russisch (Русский)**
7. 🇯🇵 **Japanisch (日本語)**
8. 🇨🇳 **Chinesisch (中文)**
9. 🇳🇱🇧🇪 **Niederländisch (Nederlands)**
10. 🇿🇦🇳🇦 **Afrikaans**
11. 🇵🇱 **Polnisch (Polski)**
12. 🇨🇿 **Tschechisch (Čeština)**
13. 🇸🇰 **Slowakisch (Slovenčina)**
14. 🇭🇺 **Ungarisch (Magyar)**
15. 🇰🇷 **Koreanisch (한국어)**
16. 🇮🇳 **Hindi (हिन्दी)**
17. 🇮🇳🇱🇰🇸🇬 **Tamil (தமிழ்)**

---

### 🏆 Macht mit beim weltweiten Hybrid-Supercluster-Rekordversuch & testet SS-CCC!

Wir laden Entwickler, KI-Forschende, Universitäten und alle Apple-Silicon-Begeisterten herzlich ein, SS-CCC auf den eigenen Macs auszuprobieren, eigene Cluster aufzubauen oder am weltweiten **SS-CCC Hybrid-Supercluster-Rekordversuch** teilzunehmen!

🔗 **GitHub-Repository (Quellcode, 17 READMEs & Schnellstart, MIT-Lizenz):**
https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion

📖 **Ausführliches Projekt-Wiki:**
https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion/wiki

#AppleSilicon #MacCluster #macOS #LocalAI #DistributedAI #MLX #oMLX #Ollama #LlamaCpp #Thunderbolt5 #RDMA #SwiftUI #MultiModelMode #CodingAgents #Cursor #OpenCode #Antigravity #OpenSource #GreenAI #SonnerStudio
