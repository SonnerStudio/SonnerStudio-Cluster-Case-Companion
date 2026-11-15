import SwiftUI
import AppKit

struct HelpDocVisual {
    let imageFile: String
    let caption: String
}

struct HelpDocMetric {
    let label: String
    let value: String
}

struct HelpDocDeepDive {
    let id: String
    let subtitle: String
    let visuals: [HelpDocVisual]
    let detailedParagraphs: [String]
    let stepByStep: [String]
    let keyMetrics: [HelpDocMetric]
    let bestPractices: [String]
}

enum HelpDocDeepDiveCatalog {
    static func deepDive(for id: String, section: HelpDocSection, lang: AppLanguage) -> HelpDocDeepDive {
        let isGerman = (lang == .de)
        switch id {
        case "universal-m":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "Heterogener Apple-Silicon-Verbund von M1 bis M12+ mit automatischer Rang-0-Zuweisung"
                    : "Heterogeneous Apple Silicon Clustering (M1–M12+) with Automatic Rank 0 Assignment",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_cluster_52gb.png",
                        caption: isGerman
                            ? "Verbund-Übersicht: Koordinator (Rang 0) + Worker-Knoten über Thunderbolt & LAN"
                            : "Cluster Overview: Coordinator (Rank 0) + Worker nodes over Thunderbolt & LAN"
                    ),
                    HelpDocVisual(
                        imageFile: "cluster_topology_graphic.png",
                        caption: isGerman
                            ? "Hardware-Topologie: Getrennte Steuer- (LAN/WLAN) und Rechendaten-Ebene (TB3/4/5)"
                            : "Hardware Topology: Separated Control Plane (LAN/WLAN) and Data Plane (TB3/4/5)"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "Jeder Apple-Silicon-Mac (Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, Mac Pro) kann unabhängig von seiner Generation als gleichberechtigter Rechenknoten in den Verbund aufgenommen werden. SS-CCC liest per sysctl und system_profiler automatisch CPU-P/E-Kerne, GPU-Kerne, Neural Engine (ANE), RAM-Größe und die reale Speicherbandbreite (GB/s) aus.",
                    "Für künftige Chip-Generationen (M7 bis M12+) leitet AppleSiliconChipFamily Speicherbandbreite, FP16-TFLOPS und Thunderbolt-Generation konsistent ab, sodass auch kommende Hardware ohne manuelle Tabellen sofort korrekt als Koordinator oder Worker eingestuft wird.",
                    "Der Knoten mit dem höchsten Speicherdurchsatz (z. B. Ultra oder Max) übernimmt automatisch Rang 0 (Leitrechner & OpenAI/Ollama-API-Eingang). Alle weiteren Macs arbeiten als nachgeschaltete Worker (Rang 1..N) mit speichergewichteter Layer-Aufteilung."
                ] : [
                    "Every Apple Silicon Mac (Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, Mac Pro) can join the cluster on equal terms regardless of generation. SS-CCC inspects CPU P/E cores, GPU cores, Neural Engine (ANE), RAM capacity, and memory bandwidth (GB/s) via sysctl and system_profiler.",
                    "For future Apple Silicon generations (M7–M12+), AppleSiliconChipFamily extrapolates memory bandwidth, FP16 TFLOPS, and Thunderbolt class automatically so upcoming hardware is ranked accurately out of the box.",
                    "The Mac with the highest memory bandwidth automatically becomes Rank 0 (Coordinator & OpenAI/Ollama API gateway), while all remaining Macs serve as Rank 1..N Workers receiving proportional model layers."
                ],
                stepByStep: isGerman ? [
                    "1. Verbinde alle Macs per Thunderbolt-Kabel (TB3/4/5) oder über das lokale LAN/WLAN bzw. WAN.",
                    "2. Öffne 'Verbund-Übersicht' oder 'Geräte & Vergleich', um die automatisch erkannte Hardware und Rang-Vergabe zu prüfen.",
                    "3. Starte auf dem Rang-0-Leitrechner die gewünschte Laufzeit (oMLX, Ollama oder llama.cpp) — SS-CCC verteilt die Schichten entsprechend des verfügbaren RAMs."
                ] : [
                    "1. Connect your Macs via Thunderbolt cables (TB3/4/5) or local LAN/WLAN/WAN.",
                    "2. Open 'Cluster Overview' or 'Devices & Compare' to verify detected hardware and Rank 0 assignment.",
                    "3. Launch your runtime (oMLX, Ollama, or llama.cpp) on Rank 0 — SS-CCC shards model layers proportionally across available memory."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "Chip-Support", value: "M1 – M12+ (Base/Pro/Max/Ultra)"),
                    HelpDocMetric(label: "Koordinator", value: isGerman ? "Max. Speicherbandbreite → Rang 0" : "Max Bandwidth → Rank 0"),
                    HelpDocMetric(label: "Layer-Verteilung", value: isGerman ? "Speichergewichtet (proportional)" : "Memory-Weighted Sharding")
                ],
                bestPractices: isGerman ? [
                    "Den Mac mit der höchsten Speicherbandbreite (z. B. Mac Studio Max/Ultra) immer als Rang-0-Leitrechner vorsehen.",
                    "Unterschiedliche RAM-Größen (z. B. 36 GB + 16 GB) sind ausdrücklich vorgesehen — SS-CCC verteilt die Gewichte automatisch proportional."
                ] : [
                    "Always designate the Mac with highest memory bandwidth (e.g., Mac Studio Max/Ultra) as Rank 0 Coordinator.",
                    "Asymmetric RAM sizes (e.g., 36 GB + 16 GB) work seamlessly via proportional layer sharding."
                ]
            )

        case "overview-hazard":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "Strukturierte Trennung nach Lokal, Internet & Hybrid mit industriellen Warnmarkierungen"
                    : "Structured Local, Internet & Hybrid Topology Scopes with Industrial Hazard Striping",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_single_16gb.png",
                        caption: isGerman
                            ? "Einzelbetrieb & 3-Reiter-Umschaltung mit Speicherschutz-Zone"
                            : "Standalone & 3-Tab Scope Switcher with Memory Protection Zone"
                    ),
                    HelpDocVisual(
                        imageFile: "ssccc_cluster_52gb.png",
                        caption: isGerman
                            ? "Aktiver Verbund mit gelb-schwarzen Industrie-Warnstreifen an kritischen Zonen"
                            : "Active Cluster with Yellow-Black Industrial Hazard Stripes on Critical Zones"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "Die Verbund-Übersicht gliedert die gesamte Cluster-Topologie in drei klar getrennte Auswahl-Reiter: 'Lokaler Cluster' (Thunderbolt-3/4/5-, RDMA/JACCL- und 10GbE-Rechner vor Ort), 'Internet-Cluster' (entfernte WAN-Partner und regionale Subcluster) sowie 'Lokal + Internet' (gekoppelter Gesamtverbund).",
                    "Sicherheitskritische Zonen — insbesondere der aktive Verbund-Speicher, das iogpu.wired_limit_mb-Limit, RDMA-Direktspeicherpfade und aktive Ausführungsbereiche — werden mit diagonalen gelb-schwarzen 45°-Industrie-Warnstreifen (HazardStripesBar) hervorgehoben.",
                    "Durch diese visuelle Trennung erkennst du auf einen Blick, ob ein Modell rein lokal, rein über WAN oder im gekoppelten Hybrid-Verbund läuft und wie viel Betriebssystem-Reserve geschützt bleibt."
                ] : [
                    "Cluster Overview divides your topology into three clear scopes: 'Local Cluster' (TB3/4/5, RDMA/JACCL & 10GbE), 'Internet Cluster' (remote WAN peers & regional subclusters), and 'Local + Internet' (coupled hybrid mesh).",
                    "Safety-critical zones — including wired VRAM pools, iogpu.wired_limit_mb guards, RDMA zero-copy paths, and active execution blocks — are highlighted with 45-degree yellow-black industrial hazard stripes (HazardStripesBar).",
                    "This visual grammar makes it immediately clear whether workloads run locally, over WAN, or in coupled hybrid mode, while keeping macOS memory reserves visible."
                ],
                stepByStep: isGerman ? [
                    "1. Wähle in der Verbund-Übersicht den gewünschten Reiter (Lokaler Cluster, Internet-Cluster oder Lokal + Internet).",
                    "2. Prüfe im Balken 'Verbund-Speicheraufteilung' den genauen Anteil für KI-Modelle vs. macOS-Reserve.",
                    "3. Nutze bei Bedarf die Nachbildungs-Umschaltung links unten in der Seitenleiste, um größere Mehrknoten-Topologien risikofrei zu testen."
                ] : [
                    "1. Select your target scope in Cluster Overview (Local, Internet, or Local + Internet).",
                    "2. Inspect the 'Unified Memory Allocation' bar showing AI VRAM vs. protected macOS OS reserve.",
                    "3. Toggle the sidebar simulation switch whenever you want to preview multi-node topologies safely."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "Scope-Modi", value: "Local · Internet · Hybrid"),
                    HelpDocMetric(label: "Warn-Elemente", value: "HazardStripesBar & IndustrialBanner"),
                    HelpDocMetric(label: "Ansichts-Abdeckung", value: isGerman ? "Alle 10 Hauptansichten" : "All 10 Primary Views")
                ],
                bestPractices: isGerman ? [
                    "Vor großen Modell-Starts stets prüfen, ob der gewählte Reiter (Lokal vs. Hybrid) zur gewünschten Latenzklasse passt.",
                    "Gelb-schwarze Warnbereiche signalisieren direkte Kernel-/Speicher- oder Netzwerk-Eingriffe — Werte dort mit Bedacht anpassen."
                ] : [
                    "Verify the active scope tab (Local vs. Hybrid) before loading large multi-node models.",
                    "Yellow-black hazard zones indicate direct kernel memory or high-speed link boundaries."
                ]
            )

        case "memory-safety":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "macOS Kernel-Schutzgrenze (iogpu.wired_limit_mb) gegen OOM-Abstürze und WindowServer-Freezes"
                    : "macOS Kernel Memory Guard (iogpu.wired_limit_mb) Preventing OOM Crashes & WindowServer Freezes",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_tb5_rdma_jaccl.jpg",
                        caption: isGerman
                            ? "Unified Memory Pool & iogpu.wired_limit_mb Schutzarchitektur"
                            : "Unified Memory Pool & iogpu.wired_limit_mb Protection Architecture"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "Auf Apple Silicon teilen sich CPU, GPU und Neural Engine denselben physikalischen Unified-Memory-Pool. Wird versucht, 100 % des Arbeitsspeichers als GPU-Wired-Memory für ein LLM zu sperren, drohen dem macOS WindowServer und Kernel sofortige System-Freezes oder Out-of-Memory-Panics.",
                    "SS-CCC berechnet deshalb auf jedem Knoten automatisch die geschützte Betriebssystem-Reserve: 4 GB bei Macs bis 24 GB RAM (z. B. 16 GB → 12 GB nutzbar), 6 GB bei 32–64 GB RAM (z. B. 36 GB → 30 GB nutzbar) und 8 GB ab 96 GB RAM (z. B. 128 GB → 120 GB nutzbar).",
                    "Vor jedem Modellstart prüft die Modell-Werkstatt sowie der Multi-Model-Mode (MMM), ob Modellgewichte + KV-Zwischenspeicher sicher in die nutzbare Gesamtsumme passen."
                ] : [
                    "On Apple Silicon, CPU, GPU, and Neural Engine share a single Unified Memory pool. Allocating 100% of system RAM as wired GPU memory starves macOS WindowServer and causes freezes or kernel panics.",
                    "SS-CCC enforces an automatic per-node OS safety reserve: 4 GB for Macs up to 24 GB RAM (16 GB → 12 GB usable), 6 GB for 32–64 GB RAM (36 GB → 30 GB usable), and 8 GB for 96 GB+ RAM (128 GB → 120 GB usable).",
                    "Before loading any model or MMM multi-model pool, Model Studio and MMM validate weights + KV-cache against this safe limit."
                ],
                stepByStep: isGerman ? [
                    "1. Ermittle das sichere Wired-Limit deines Macs (z. B. 30720 MB bei 36 GB RAM oder 12288 MB bei 16 GB RAM).",
                    "2. Setze das Limit über 'scripts/setup_wired_limit.sh <MB>' (oder in 'Netzwerk & Direktspeicher').",
                    "3. Aktiviere in MMM bei Bedarf 'VRAM-Fit optimieren', um überschüssige Slots automatisch zu pausieren."
                ] : [
                    "1. Determine your Mac's safe wired limit (e.g., 30720 MB on 36 GB or 12288 MB on 16 GB).",
                    "2. Apply the limit using 'scripts/setup_wired_limit.sh <MB>' or from Network & RDMA.",
                    "3. Use 'Optimize VRAM-Fit' in MMM if switching to a smaller cluster scope."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "≤ 24 GB RAM", value: "4 GB OS-Reserve"),
                    HelpDocMetric(label: "32 – 64 GB RAM", value: "6 GB OS-Reserve"),
                    HelpDocMetric(label: "≥ 96 GB RAM", value: "8 GB OS-Reserve")
                ],
                bestPractices: isGerman ? [
                    "Niemals 100 % des RAMs per sysctl iogpu.wired_limit_mb freigeben.",
                    "Bei großen Kontextfenstern (32k–128k Tokens) 8-bit oder 4-bit KV-Cache-Quantisierung aktivieren."
                ] : [
                    "Never assign 100% of physical RAM to iogpu.wired_limit_mb.",
                    "Enable 8-bit or 4-bit KV-cache quantization for long 32k–128k context windows."
                ]
            )

        case "network-tb":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "Getrennte Control- und Data-Plane, Thunderbolt-3/4/5-Bridge & RDMA (JACCL) Zero-Copy"
                    : "Dual-Plane Networking, Thunderbolt 3/4/5 Bridge & RDMA (JACCL) Zero-Copy",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_tb5_rdma_jaccl.jpg",
                        caption: isGerman
                            ? "Thunderbolt 5 RDMA (JACCL) & MLX_METAL_FAST_SYNCH=1 (~4 µs Latenz)"
                            : "Thunderbolt 5 RDMA (JACCL) & MLX_METAL_FAST_SYNCH=1 (~4 µs latency)"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "SS-CCC trennt Netzwerkverkehr sauber auf zwei Ebenen: Steuerdaten, mDNS/Bonjour-Erkennung und WebSocket-Chat laufen über LAN/WLAN bzw. Tailscale-WAN, während hochfrequente Tensor-Aktivierungen dediziert über eine Punkt-zu-Punkt-Thunderbolt-Bridge (10.99.1.x) fließen.",
                    "Bei gemischten Generationen (z. B. TB5 Mac Studio + TB4 Mac mini) skaliert die Verbindung dynamisch auf die gemeinsam unterstützte Bandbreite (TB3/USB4: 26–32 Gbps, TB4: 30–37 Gbps, TB5: 65–80 Gbps, TB5 RDMA: 75–110 Gbps).",
                    "Mit MLX_METAL_FAST_SYNCH=1 und JACCL RDMA auf macOS 26.2+ werden GPU-Synchronisationswartezeiten von ~180 µs auf ~4 µs reduziert (45× schnellere Synchronisation)."
                ] : [
                    "SS-CCC cleanly separates Control Plane (LAN/WLAN/Tailscale discovery & chat) from Data Plane (dedicated 10.99.1.x point-to-point Thunderbolt bridge for tensor activations).",
                    "Mixed generations negotiate link throughput dynamically (TB3/USB4: 26–32 Gbps, TB4: 30–37 Gbps, TB5: 65–80 Gbps, TB5 RDMA: 75–110 Gbps).",
                    "Enabling MLX_METAL_FAST_SYNCH=1 with JACCL RDMA on macOS 26.2+ cuts GPU synchronization latency from ~180 µs down to ~4 µs (45× speedup)."
                ],
                stepByStep: isGerman ? [
                    "1. Verbinde beide Macs direkt mit einem zertifizierten Thunderbolt-4/5-Kabel (max. 1–2 m).",
                    "2. Richte im Bereich 'Netzwerk & Direktspeicher' die TB-Bridge-IPs (10.99.1.1 / 10.99.1.2) ein.",
                    "3. Prüfe mit 'ibv_devices' im RDMA-Panel, ob RDMA-Verbs aktiv sind (ab macOS 26.2 + TB5)."
                ] : [
                    "1. Connect Macs directly with a certified Thunderbolt 4/5 cable.",
                    "2. Configure the 10.99.1.x Thunderbolt Bridge in 'Network & RDMA'.",
                    "3. Verify RDMA verbs via 'ibv_devices' on macOS 26.2+ TB5 hardware."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "TB4 Bridge", value: "30–37 Gbps"),
                    HelpDocMetric(label: "TB5 RDMA (JACCL)", value: "75–110 Gbps · ~4 µs"),
                    HelpDocMetric(label: "FAST_SYNCH", value: "45× schnelleres GPU-Sync")
                ],
                bestPractices: isGerman ? [
                    "Thunderbolt-Bridge in der macOS-Netzwerkreihenfolge unterhalb von WLAN/Ethernet belassen, damit normaler Internetverkehr ungestört bleibt.",
                    "Für RDMA über JACCL kurze passive oder aktive TB5-Kabel direkt ohne Hub anschließen."
                ] : [
                    "Keep Thunderbolt Bridge below Wi-Fi/Ethernet in macOS Network service order so internet routing stays intact.",
                    "Connect TB5 cables directly host-to-host without intermediate docks for RDMA."
                ]
            )

        case "sharding-loading":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "Multi-Model-Mode (MMM), Auto-Setup & Speichergewichtete Schichtenverteilung"
                    : "Multi-Model-Mode (MMM), 1-Click Auto-Setup & Memory-Weighted Sharding",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_multi_model_mode.jpg",
                        caption: isGerman
                            ? "Multi-Model-Mode (MMM): 4 Orchestrierungsstrategien & Multi-IDE-Verbrauch (:8000/v1)"
                            : "Multi-Model-Mode (MMM): 4 Orchestration Strategies & Multi-IDE Consumption (:8000/v1)"
                    ),
                    HelpDocVisual(
                        imageFile: "ssccc_mmm_autosetup_editor.jpg",
                        caption: isGerman
                            ? "MMM 1-Klick-Auto-Einrichtung & Nachträglicher Live-Slot-Editor"
                            : "MMM 1-Click Auto-Setup Wizard & Post-Configuration Live Slot Editor"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "Beim klassischen Sharding teilt SS-CCC große Einzelmodelle speichergewichtet über alle verfügbaren Knoten auf (z. B. 70 % der Transformer-Layer auf einen 36-GB-Studio, 30 % auf einen 16-GB-mini).",
                    "Der Multi-Model-Mode (MMM, 10. Menüpunkt) geht noch weiter: Er bündelt mehrere spezialisierte Modelle gleichzeitig im lokalen Cluster, Internet-Cluster oder gekoppelten Hybrid-Verbund (Parallel Pool, Mixture-of-Agents, Speculative Decoding, Sequenzielle Pipeline).",
                    "Mit dem neuen Auto-Setup-Assistenten richtest du komplette Multi-Modell-Topologien mit 1 Klick ein und kannst jeden Slot anschließend im Live-Editor umsortieren, duplizieren, umbenennen, auf andere Endpunkte legen oder im VRAM-Limit anpassen."
                ] : [
                    "In classic sharding, SS-CCC splits large single models proportionally across all nodes' usable VRAM.",
                    "Multi-Model-Mode (MMM, 10th sidebar item) goes further by orchestrating multiple specialized models simultaneously across Local, Internet-WAN, or Hybrid clusters (Parallel Pool, Mixture-of-Agents, Speculative Decoding, Sequential Pipeline).",
                    "Using the 1-Click Auto-Setup Wizard, you can configure optimal multi-model pools instantly and customize every slot afterwards in the inline Live Editor."
                ],
                stepByStep: isGerman ? [
                    "1. Öffne 'Multi-Model-Mode' (10. Menüpunkt) und wähle deinen Bereich (Lokal, Internet oder Hybrid).",
                    "2. Wähle ein Auto-Setup-Profil (z. B. Coding & IDE-Schwarm oder Stufen-Pipeline) und klicke auf 'Automatisch einrichten'.",
                    "3. Passe bei Bedarf einzelne Slots nachträglich über das Regler-Symbol an (Reihenfolge, URL, Modell-ID, VRAM) und speichere."
                ] : [
                    "1. Open 'Multi-Model-Mode' (10th sidebar item) and pick your scope (Local, Internet, or Hybrid).",
                    "2. Select an Auto-Setup profile and click 'Auto-Configure'.",
                    "3. Fine-tune any slot afterwards (reorder, duplicate, edit model ID, URL, or VRAM) and save."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "Strategien", value: "4 (Pool · MoA · Spec · Pipe)"),
                    HelpDocMetric(label: "Auto-Profile", value: isGerman ? "4 1-Klick-Presets" : "4 1-Click Presets"),
                    HelpDocMetric(label: "Shared Gateway", value: "OpenAI :8000/v1")
                ],
                bestPractices: isGerman ? [
                    "Bei knapper VRAM-Grenze 'VRAM-Fit optimieren' nutzen, um niedrig priorisierte Slots sauber zu pausieren.",
                    "Für Multi-IDE-Betrieb (Xcode + Cursor + Claude Code gleichzeitig) das Profil 'Coding & IDE-Schwarm' wählen."
                ] : [
                    "Use 'Optimize VRAM-Fit' after switching to a smaller cluster scope to prevent OOM.",
                    "Choose 'Coding & IDE Swarm' when serving Xcode, Cursor, and CLI agents concurrently."
                ]
            )

        case "setup-hybrid":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "Weltweiter Internet-Cluster, Tailscale/DERP-Mesh & Live WAN-Bandbreiten-Monitor"
                    : "Global Internet-Cluster, Tailscale/DERP Mesh & Live WAN Bandwidth Monitor",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_internet_wan_mesh.jpg",
                        caption: isGerman
                            ? "Weltweiter Internet-Mac-Verbund & Gekoppeltes Hybrid-Mesh"
                            : "Global Internet Mac Cluster & Coupled Hybrid Mesh"
                    ),
                    HelpDocVisual(
                        imageFile: "ssccc_wan_bandwidth_monitor.jpg",
                        caption: isGerman
                            ? "Live WAN Bandbreiten- & Datendurchsatz-Monitor (Downlink/Uplink, RTT, Jitter, tok/s)"
                            : "Live WAN Bandwidth & Throughput Monitor (Downlink/Uplink, RTT, Jitter, tok/s)"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "Mit dem Internet-Verbund lassen sich beliebige Apple-Silicon-Macs weltweit über verschlüsselte Tunnel (Tailscale/WireGuard, libp2p/DERP oder direkte Endpunkte) zu regionalen Subclustern oder einem gekoppelten Hybrid-Verbund zusammenschließen.",
                    "Der integrierte WAN-Bandbreiten- & Datendurchsatz-Monitor misst in Echtzeit über netstat, ping und macOS networkQuality die tatsächliche Download-/Upload-Bandbreite, WAN-RTT-Latenz (ms), Jitter und Paketverlust.",
                    "So siehst du direkt, wie stark die Internetleitung die verteilte Token-Rate (tok/s) beeinflusst und ob DiLoCo/Pipeline-Stufen optimal getaktet sind."
                ] : [
                    "Internet-Cluster links Macs globally over encrypted tunnels (Tailscale/WireGuard, libp2p/DERP, or direct endpoints) into regional subclusters or coupled Local+WAN hybrid meshes.",
                    "The integrated WAN Bandwidth & Throughput Monitor measures real Downlink/Uplink Mbps, WAN RTT latency (ms), jitter, and packet loss via netstat, ping, and networkQuality.",
                    "You can immediately observe how WAN throughput correlates with distributed tok/s and tune pipeline/DiLoCo intervals accordingly."
                ],
                stepByStep: isGerman ? [
                    "1. Öffne 'Internet-Verbund & Chat' und verbinde dich mit deinem Raum oder füge Partner-Endpunkte hinzu.",
                    "2. Starte die Live-WAN-Messung im Bandbreiten-Monitor, um Downlink, Uplink und RTT-Latenz zu erfassen.",
                    "3. Kopple in der 'Verbund-Übersicht' (Reiter 'Lokal + Internet') deinen lokalen TB-Kern mit dem WAN-Pool."
                ] : [
                    "1. Open 'Internet Cluster & Chat' and join your room or add remote peer endpoints.",
                    "2. Run the WAN Bandwidth Monitor to capture live downlink, uplink, and RTT latency.",
                    "3. Couple your local Thunderbolt core with the WAN pool via 'Local + Internet' scope."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "Transport", value: "Tailscale · WireGuard · DERP"),
                    HelpDocMetric(label: "WAN-Telemetrie", value: "netstat · ping · networkQuality"),
                    HelpDocMetric(label: "Chat-Relay", value: "WebSocket /ws/wan/{room}")
                ],
                bestPractices: isGerman ? [
                    "Für niedrige WAN-Latenz möglichst direkte WireGuard/Tailscale-Peers ohne DERP-Relay verwenden.",
                    "Bei hohen RTT-Werten (> 60 ms) größere Pipeline-Microbatches oder FP8-Aktivierungskompression nutzen."
                ] : [
                    "Prefer direct WireGuard/Tailscale connections over relayed paths for lowest WAN RTT.",
                    "Enable FP8 activation compression when WAN RTT exceeds 60 ms."
                ]
            )

        case "audio-party":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "Echtzeit-Sprachkoordination für verteilte Cluster-Teams im Konsolen-Party-Stil"
                    : "Real-Time Console-Style Voice Coordination for Distributed Cluster Teams",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_audio_party_collab.jpg",
                        caption: isGerman
                            ? "Cluster Audio-Party: AVAudioEngine Opus-16kHz-Sprachkanal neben dem Live-Chat"
                            : "Cluster Audio-Party: AVAudioEngine Opus-16kHz Voice Channel alongside Live Chat"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "Direkt neben dem WAN-Teilnehmer-Chat bietet SS-CCC eine integrierte Cluster Audio-Party (inspiriert von Xbox/PlayStation-Party-Räumen). So können verteilte Entwickler- und Forscher-Teams während laufender Benchmarks oder Multi-Node-Setups direkt per Sprache zusammenarbeiten.",
                    "Technisch nutzt das System macOS AVAudioEngine für Low-Latency-Mikrofonaufnahme mit optionalem Push-to-Talk, Noise-Gate, Stummschaltung und automatischem Audio-Ducking (80 % Sprachmix / 20 % Cluster-Alarme) über den WebSocket-Endpunkt /ws/wan-audio.",
                    "Im Offline-/Vorschau-Modus bleiben alle UI-Kontrollen sicher simuliert, ohne unautorisiert auf Mikrofonhardware zuzugreifen."
                ] : [
                    "Alongside the WAN participant chat, SS-CCC provides a built-in Cluster Audio-Party (inspired by console party rooms) so distributed teams can coordinate live during multi-node benchmarks.",
                    "Built on macOS AVAudioEngine with Push-to-Talk, Noise Gate, Mute/Deafen, and 80/20 voice-vs-alert mixing over /ws/wan-audio using Opus-16kHz framing.",
                    "In preview/offline mode, controls remain safe without capturing microphone audio unintentionally."
                ],
                stepByStep: isGerman ? [
                    "1. Öffne 'Internet-Verbund & Chat' und scrolle zur Audio-Party-Leiste.",
                    "2. Wähle zwischen Open-Mic und Push-to-Talk und trete dem Sprachraum bei.",
                    "3. Nutze den Mix-Regler, um Cluster-Statusmeldungen dezent im Hintergrund zu halten."
                ] : [
                    "1. Open 'Internet Cluster & Chat' and locate the Audio-Party bar.",
                    "2. Choose Open-Mic or Push-to-Talk and join the voice room.",
                    "3. Adjust the Voice/Alert mix ratio for clear team communication."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "Audio-Engine", value: "macOS AVAudioEngine"),
                    HelpDocMetric(label: "Codec / Mixing", value: "Opus 16 kHz · 80/20 Ducking"),
                    HelpDocMetric(label: "Signaling", value: "WebSocket /ws/wan-audio")
                ],
                bestPractices: isGerman ? [
                    "Bei offenen Lautsprechern Push-to-Talk und Noise-Gate aktivieren, um Echos zu vermeiden.",
                    "Audio-Party gemeinsam mit der Weltrekord-Challenge oder Hybrid-MMM-Sessions nutzen."
                ] : [
                    "Enable Push-to-Talk and Noise Gate when using external speakers.",
                    "Ideal for coordinating live Hybrid MMM runs and distributed benchmarks."
                ]
            )

        case "science-history":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "6-Tab-Forschungslabor: Roofline, WAN-DiLoCo, Splitwise KV, CO₂/EDP & Echtzeit-Historie"
                    : "6-Tab Science Lab: Roofline, WAN/DiLoCo, Splitwise KV, Energy/CO₂ & History Telemetry",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_science_roofline_hero.jpg",
                        caption: isGerman
                            ? "Roofline-Grenzkurve, Ridge-Point-Analyse & Splitwise Prefill/Decode"
                            : "Roofline Ceiling Analysis, Ridge-Point & Splitwise Prefill/Decode"
                    ),
                    HelpDocVisual(
                        imageFile: "ssccc_history_telemetry_lab.jpg",
                        caption: isGerman
                            ? "6-Tab Forschungslabor & Positionsbezogene Verlaufsaufzeichnung (CSV/Markdown/LaTeX)"
                            : "6-Tab Science Lab & Per-Position History Recording (CSV/Markdown/LaTeX)"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "Der Bereich 'Forschung & Leistung' arbeitet im Echtbetrieb konsequent mit realen SSE-Token-Streams, echten RTT-Pings und gemessener Hardware-Bandbreite — vollständig ohne Mock-Daten. Im Simulationsmodus liefert er klar gekennzeichnete, physikalisch konsistente Referenzwerte.",
                    "Auf 6 spezialisierten Reitern (Roofline & Leistung, WAN & DiLoCo, Speicher & KV-Budget, Energie & CO₂, Live-Messreihen & Statistik, Verlauf & Telemetrie) wertet das Labor Prefill vs. Decode, CI95-Konfidenzintervalle, Energy-Delay-Product (EDP) und regionale CO₂-Bilanzen aus.",
                    "Alle Messläufe — einschließlich der Läufe aus dem neuen Multi-Model-Mode (MMM) — fließen automatisch in die Verlaufsaufzeichnung und können als CSV, Markdown-Report oder IEEE/ACM-LaTeX-Tabelle exportiert werden."
                ] : [
                    "Science & Performance runs exclusively on real SSE token streams, real RTT pings, and measured hardware bandwidth in live mode — with zero mock data. Simulation mode provides clearly badged, physically consistent reference values.",
                    "Across 6 specialized tabs (Roofline, WAN & DiLoCo, Memory & KV, Energy & CO₂, Live Trials & CI95, History & Export), the lab evaluates Prefill vs. Decode, Energy-Delay Product (EDP), and carbon footprint.",
                    "Every run — including Multi-Model-Mode (MMM) orchestrations — feeds directly into the Science History table for CSV, Markdown, or LaTeX export."
                ],
                stepByStep: isGerman ? [
                    "1. Wähle oben im Forschungslabor den Analyse-Scope (Lokal, WAN oder gekoppelt).",
                    "2. Starte eine Live-Messreihe (N Trials) im Reiter 'Live-Messreihen & Statistik' oder führe einen MMM-Lauf aus.",
                    "3. Exportiere die Ergebnisse unter 'Verlauf & Telemetrie' direkt als CSV, Markdown oder LaTeX-Tabelle."
                ] : [
                    "1. Select the analysis scope at the top of Science & Performance.",
                    "2. Run N live benchmark trials or execute a Multi-Model-Mode (MMM) orchestration.",
                    "3. Export results as CSV, Markdown, or IEEE/ACM LaTeX from the History tab."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "Analyse-Tabs", value: "6 (inkl. Verlauf & MMM)"),
                    HelpDocMetric(label: "Statistik", value: "p50 · p95 · p99 · CI95"),
                    HelpDocMetric(label: "Exporte", value: "CSV · Markdown · LaTeX")
                ],
                bestPractices: isGerman ? [
                    "Für belastbare Paper-Werte mindestens 5–10 Live-Trials pro Modellkonfiguration ausführen.",
                    "MMM-Orchestrierungsläufe über die eingebaute MMM-Auswertungskarte direkt mit Einzelmodell-Baselines vergleichen."
                ] : [
                    "Run at least 5–10 live trials per configuration for tight CI95 confidence intervals.",
                    "Compare MMM multi-model speedups directly against single-model baselines in the MMM evaluation card."
                ]
            )

        case "runtimes":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "Live-Erkennung für oMLX, Ollama, llama.cpp, GGUF & HuggingFace-Hub"
                    : "Live Runtime Discovery for oMLX, Ollama, llama.cpp, GGUF & HuggingFace Hub",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_ecosystem_banner.jpg",
                        caption: isGerman
                            ? "Unterstützte MLX-, oMLX-, Ollama- und llama.cpp-Backends auf macOS"
                            : "Supported MLX, oMLX, Ollama & llama.cpp Backends on macOS"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "SS-CCC erkennt automatisch lokal laufende Inferenz-Server auf ihren Standard-Ports (:8000 für oMLX/MLX, :11434 für Ollama, :8080 für llama.cpp) sowie lokale .gguf-Dateien und Modelle im ~/.cache/huggingface/hub-Verzeichnis.",
                    "Sind keine Laufzeiten aktiv, zeigt die Modell-Werkstatt keine gefälschten Modelle an, sondern liefert eine präzise Runtime-Bereitschaftsprüfung inklusive passender Startbefehle.",
                    "Gefundene Live-Modelle stehen sofort auch im Multi-Model-Mode (MMM) für die automatische 1-Klick-Einrichtung bereit."
                ] : [
                    "SS-CCC probes active local inference servers (:8000 oMLX/MLX, :11434 Ollama, :8080 llama.cpp) and scans local .gguf files plus ~/.cache/huggingface/hub.",
                    "When no runtimes are active, Model Studio never fabricates fake models — it displays live readiness status and exact startup commands instead.",
                    "Discovered live models are immediately available in Multi-Model-Mode (MMM) for 1-click Auto-Setup."
                ],
                stepByStep: isGerman ? [
                    "1. Starte oMLX, Ollama oder llama-server auf deinem Rang-0-Mac.",
                    "2. Klicke in 'Modell-Werkstatt' auf 'Modelle aktualisieren'.",
                    "3. Wähle ein Modell oder übernimm alle erkannten Live-Modelle direkt in MMM."
                ] : [
                    "1. Launch oMLX, Ollama, or llama-server on your Rank 0 Mac.",
                    "2. Click 'Refresh Models' in Model Studio.",
                    "3. Load a single model or auto-import all discovered models into MMM."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "oMLX / MLX", value: "Port :8000 (/v1/models)"),
                    HelpDocMetric(label: "Ollama", value: "Port :11434 (/api/tags)"),
                    HelpDocMetric(label: "llama.cpp", value: "Port :8080 (/v1/models)")
                ],
                bestPractices: isGerman ? [
                    "Für Apple Silicon bevorzugt MLX-4bit/8bit-Quantisierungen (oMLX) für maximalen Speicherdurchsatz verwenden.",
                    "Ollama eignet sich ideal als schneller Fallback oder für heterogene GGUF-Modelle."
                ] : [
                    "Prefer MLX 4-bit/8-bit models via oMLX on Apple Silicon for peak memory bandwidth utilization.",
                    "Use Ollama alongside oMLX for hybrid multi-runtime MMM pools."
                ]
            )

        case "agents-api":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "1-Klick-Anbindung für OpenCode, Hermes, Antigravity, Cursor, VS Code & Xcode"
                    : "1-Click Integration for OpenCode, Hermes, Antigravity, Cursor, VS Code & Xcode",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_agents_ide_ecosystem.jpg",
                        caption: isGerman
                            ? "Lokales KI-Ökosystem: 6 IDEs & Agent-Harnesses an einem gemeinsamen Cluster-Endpunkt"
                            : "Local AI Ecosystem: 6 IDEs & Agent Harnesses Sharing One Unified Cluster Endpoint"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "SS-CCC stellt über :8000/v1 (OpenAI-kompatibel) und :11434 (Ollama-kompatibel) einen zentralen API-Eingang bereit. Im Bereich 'Agenten & Umgebungen' generierst du mit einem Klick fertige JSON-/YAML-/Shell-Konfigurationen für OpenCode, Hermes Agent, Google Antigravity, Cursor, VS Code und Apple Xcode.",
                    "In Kombination mit Multi-Model-Mode (MMM) können mehrere IDEs und CLI-Agenten (z. B. Xcode + Cursor + Claude Code) gleichzeitig auf denselben Cluster zugreifen — SS-CCC berechnet in Echtzeit den verfügbaren tok/s-Durchsatz pro Client."
                ] : [
                    "SS-CCC exposes :8000/v1 (OpenAI-compatible) and :11434 (Ollama-compatible) as unified gateways. In 'Agents & Environments', 1-click exports configure OpenCode, Hermes Agent, Google Antigravity, Cursor, VS Code, and Apple Xcode.",
                    "Combined with Multi-Model-Mode (MMM), multiple IDEs and CLI harnesses can consume the cluster simultaneously with real-time per-client tok/s estimation."
                ],
                stepByStep: isGerman ? [
                    "1. Öffne 'Agenten & Umgebungen' und wähle deine Ziel-IDE oder deinen Agent-Harness.",
                    "2. Kopiere die generierte Konfiguration (Base-URL http://127.0.0.1:8000/v1) oder schreibe sie direkt in die Config-Datei.",
                    "3. Prüfe im Tab 'Schnittstelle & Konsole' oder 'Multi-Model-Mode' den Live-API-Status."
                ] : [
                    "1. Open 'Agents & Environments' and pick your IDE or Agent Harness.",
                    "2. Copy or apply the generated config pointing to http://127.0.0.1:8000/v1.",
                    "3. Monitor live client throughput in 'API & Console' or 'Multi-Model-Mode'."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "OpenAI-API", value: "http://127.0.0.1:8000/v1"),
                    HelpDocMetric(label: "Ollama-API", value: "http://127.0.0.1:11434"),
                    HelpDocMetric(label: "1-Klick-IDEs", value: "6+ (Xcode, Cursor, VS Code...)")
                ],
                bestPractices: isGerman ? [
                    "Im Multi-IDE-Betrieb die erwartete Anzahl gleichzeitiger Clients in MMM einstellen, um realistische tok/s pro IDE zu sehen.",
                    "API-Key-Feld in IDEs bei lokalem Betrieb beliebig auf 'ss-ccc-local' setzen."
                ] : [
                    "Set the concurrent client count in MMM to see realistic per-IDE tok/s headroom.",
                    "Use 'ss-ccc-local' as placeholder API key for local OpenAI-compatible clients."
                ]
            )

        case "updater-ci":
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "GitHub-gesteuerte Programm-Updates, Release-Tracking & sichere SHA-Prüfung"
                    : "GitHub-Controlled Program Updates, Release Tracking & Safe SHA Verification",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_github_auto_updater.jpg",
                        caption: isGerman
                            ? "Automatische GitHub-Update-Pipeline mit Version-Check & Deadlock-freier Ausführung"
                            : "Automatic GitHub Update Pipeline with Version Tracking & Deadlock-Free Execution"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "SS-CCC prüft automatisch gegen das GitHub-Repository (version.json & GitHub Releases), ob eine neuere Version vorliegt. Sobald ein neues Release erkannt wird, informiert dich das Update-Banner mit Changelog und einem 1-Klick-Aktualisierungsbefehl.",
                    "Technisch nutzt der Updater getrennte stdout/stderr-Pipes ohne Prozess-Deadlocks, validiert Commit-SHAs sauber und meldet Fehlerzustände transparent im UI."
                ] : [
                    "SS-CCC checks GitHub (version.json & Releases) automatically for newer builds. When an update is available, a clean banner displays the changelog and 1-click update action.",
                    "Under the hood, the updater separates stdout/stderr pipes to prevent process deadlocks, validates commit SHAs cleanly, and surfaces clear status diagnostics."
                ],
                stepByStep: isGerman ? [
                    "1. Klicke oben rechts auf das Versions-Badge oder öffne den Update-Dialog.",
                    "2. Prüfe die angezeigte Zielversion gegenüber deiner installierten Version.",
                    "3. Starte das Update per 1-Klick oder führe 'git pull && swift build' im Projektordner aus."
                ] : [
                    "1. Click the version badge in the top bar or open the Update prompt.",
                    "2. Compare the available remote version against your local build.",
                    "3. Apply the update in 1 click or pull and rebuild via SwiftPM."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "Quelle", value: "GitHub Releases + version.json"),
                    HelpDocMetric(label: "Sync-Modus", value: "Asynchron · Non-blocking"),
                    HelpDocMetric(label: "Aktuelle Version", value: AppReleaseMetadata.currentVersion)
                ],
                bestPractices: isGerman ? [
                    "Vor eigenen Code-Änderungen lokale Änderungen committen, damit Auto-Updates sauber mergen können.",
                    "Nach jedem Update einmal './scripts/run_ssccc.sh' neu starten, um die aktuelle Binary zu laden."
                ] : [
                    "Commit local tweaks before running auto-update so merges stay clean.",
                    "Restart via './scripts/run_ssccc.sh' after pulling updates."
                ]
            )

        default: // "launch-tests"
            return HelpDocDeepDive(
                id: id,
                subtitle: isGerman
                    ? "Starten über scripts/run_ssccc.sh, Swift-Kompilierung & 19-stufige Test-Suite"
                    : "Launching via scripts/run_ssccc.sh, Swift Compilation & 19-Point Test Suite",
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_use_cases_showcase.jpg",
                        caption: isGerman
                            ? "Praxiseinsatz & Verifizierte Architektur-Suite über alle 19 Global-Tests"
                            : "Production Use Cases & Verified Architecture across all 19 Global Suite Tests"
                    )
                ],
                detailedParagraphs: isGerman ? [
                    "SS-CCC wird als natives macOS-SwiftUI-Programm über SwiftPM (swift build) oder direkt über das Startskript ./scripts/run_ssccc.sh gestartet. Das Startskript stellt sicher, dass alle Swift-Quelldateien inklusive Theme, ViewModel, allen 10 Ansichten und Ressourcen gebündelt werden.",
                    "Die integrierte Qualitätssicherung besteht aus kompilierten Swift-Laufzeittests (tests/run_swift_checks.swift) und der 19-teiligen Python-Verifikationssuite (tests/test_global_suite.py), die sowohl Hardware-Logik, Lokalisierung in 8 Sprachen als auch UI-Symbole absichert."
                ] : [
                    "SS-CCC launches as a native macOS SwiftUI application via SwiftPM (swift build) or ./scripts/run_ssccc.sh, ensuring all models, view models, and 10 primary views compile together.",
                    "Quality assurance combines compiled Swift runtime checks (tests/run_swift_checks.swift) with a 19-test global verification suite (tests/test_global_suite.py) covering M1–M12+ scaling, 8-language parity, WAN monitors, and MMM."
                ],
                stepByStep: isGerman ? [
                    "1. Öffne ein Terminal im Repository-Wurzelverzeichnis.",
                    "2. Starte die App mit './scripts/run_ssccc.sh'.",
                    "3. Führe bei Änderungen 'python3 tests/test_global_suite.py' aus, um alle 19 Prüfungen zu verifizieren."
                ] : [
                    "1. Open Terminal in the repository root directory.",
                    "2. Launch the app using './scripts/run_ssccc.sh'.",
                    "3. Run 'python3 tests/test_global_suite.py' after edits to verify all 19 checks pass."
                ],
                keyMetrics: [
                    HelpDocMetric(label: "App-Start", value: "./scripts/run_ssccc.sh"),
                    HelpDocMetric(label: "Swift-Build", value: "swift build --package-path app"),
                    HelpDocMetric(label: "Test-Suite", value: "19 / 19 Global Checks")
                ],
                bestPractices: isGerman ? [
                    "Nach jedem Hinzufügen neuer Swift-Dateien prüfen, ob scripts/run_ssccc.sh alle Quellen auflistet (Test 12 prüft dies automatisch).",
                    "Für schnelle Entwicklungsschleifen 'swift build --package-path app' nutzen."
                ] : [
                    "Ensure any newly added .swift files are listed in scripts/run_ssccc.sh (enforced by Test 12).",
                    "Use 'swift build --package-path app' for fast incremental compilation."
                ]
            )
        }
    }
}

struct HelpDocImageLoader {
    static func loadImage(named filename: String) -> NSImage? {
        var candidates: [URL] = []
        if let res = Bundle.main.resourceURL {
            candidates.append(res.appendingPathComponent("images").appendingPathComponent(filename))
            candidates.append(res.appendingPathComponent("docs/images").appendingPathComponent(filename))
        }
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        candidates.append(cwd.appendingPathComponent("docs/images").appendingPathComponent(filename))

        // Walk up from app/Sources/Views/HelpDocDeepDiveContent.swift -> repo root -> docs/images
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        candidates.append(repoRoot.appendingPathComponent("docs/images").appendingPathComponent(filename))

        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path),
               let img = NSImage(contentsOf: url) {
                return img
            }
        }
        return nil
    }
}
