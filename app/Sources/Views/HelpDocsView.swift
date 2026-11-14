import SwiftUI

struct HelpDocSection: Identifiable {
    let id: String
    let icon: String
    let accent: Color
    let title: String
    let summary: String
    let bullets: [String]
    let codeSample: String?
}

struct HelpDocsView: View {
    @ObservedObject var vm: ClusterViewModel

    private var sections: [HelpDocSection] {
        HelpDocsContent.sections(for: vm.language)
    }

    private var filteredSections: [HelpDocSection] {
        let q = vm.helpSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sections }
        return sections.filter {
            $0.title.lowercased().contains(q)
                || $0.summary.lowercased().contains(q)
                || $0.bullets.contains(where: { $0.lowercased().contains(q) })
                || ($0.codeSample?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SolarisCard(accent: SolarisTheme.amber) {
                    HStack(alignment: .center, spacing: 14) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 32))
                            .foregroundColor(SolarisTheme.amber)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("help_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.t("help_sub"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                    }

                    TextField(vm.t("help_search_ph"), text: $vm.helpSearchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 4)
                }

                ForEach(filteredSections) { section in
                    SolarisCard(accent: section.accent) {
                        HStack(spacing: 10) {
                            Image(systemName: section.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(section.accent)
                            Text(section.title)
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                        }

                        Text(section.summary)
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(section.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(SolarisTheme.bodyBold)
                                        .foregroundColor(section.accent)
                                    Text(bullet)
                                        .font(SolarisTheme.bodyLarge)
                                        .foregroundColor(SolarisTheme.textPrimary)
                                }
                            }
                        }

                        if let code = section.codeSample {
                            Text(code)
                                .font(SolarisTheme.monoCode)
                                .foregroundColor(SolarisTheme.mint)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.38)))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

enum HelpDocsContent {
    static func sections(for lang: AppLanguage) -> [HelpDocSection] {
        switch lang {
        case .de:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Alle Apple Mac mit M-Prozessor im Verbund (M1–M12+)",
                    summary: "Jeder Mac mit Apple-Silicon-Chip (M1 bis M12+ — Basis, Pro, Max oder Ultra) kann als gleichberechtigter Rechner in den Verbund aufgenommen werden: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio und Mac Pro.",
                    bullets: [
                        "Zukunftssichere Generationen-Erkennung: Speicherbandbreite, FP16-TFLOPS und Thunderbolt-Generation werden auch für künftige M-Chips (M7–M12+) automatisch abgeleitet.",
                        "Automatische Rang-Vergabe: Der Mac mit dem höchsten Speicherdurchsatz (z. B. Ultra oder Max) übernimmt selbsttätig Rang 0 (Leitrechner).",
                        "Gemischte Generationen: Ein MacBook Pro M2 Max arbeitet problemlos mit einem Mac mini M4 oder einem Mac Studio M5 Max zusammen."
                    ],
                    codeSample: "Rang 0 = höchster Speicherdurchsatz (GB/s)\nRang 1..N = nachgeschaltete Rechner im Schichten-Verbund"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "2. Gemeinsamer Arbeitsspeicher & Schutzgrenze (iogpu.wired_limit_mb)",
                    summary: "Auf Apple Silicon teilen sich CPU und GPU denselben Speicher. Niemals darf 100 % des Arbeitsspeichers für KI-Modelle freigegeben werden.",
                    bullets: [
                        "Bis 24 GB RAM: Mindestens 4 GB bleiben für macOS und WindowServer frei (z. B. 16 GB → 12 GB nutzbar).",
                        "32 GB bis 64 GB RAM: 6 GB bleiben für das Betriebssystem geschützt (z. B. 36 GB → 30 GB nutzbar).",
                        "Ab 96 GB RAM (Ultra/Max): 8 GB bleiben für macOS geschützt (z. B. 128 GB → 120 GB nutzbar).",
                        "Vor dem Laden prüft SS-CCC den Gesamtbedarf (Modellgewicht + KV-Zwischenspeicher) gegen die nutzbare Summe aller Geräte."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Beispiel für 36-GB-Mac (30 GB nutzbar)"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. Netzwerk, Thunderbolt-Brücke (TB3/4/5) & RDMA",
                    summary: "SS-CCC trennt Steuerdaten (LAN/WLAN) und Modell-Aktivierungsdaten (Thunderbolt) sauber auf zwei Ebenen.",
                    bullets: [
                        "Steuer-Ebene (LAN/WLAN): Bonjour-Erkennung, API-Anfragen und Zustandstausch.",
                        "Daten-Ebene (Thunderbolt 3/4/5): Punkt-zu-Punkt-Brücke im Netz 10.99.1.x mit real 30–37 Gbps (TB4) bzw. bis 90 Gbps (TB5 RDMA).",
                        "Schnelle GPU-Abstimmung: MLX_METAL_FAST_SYNCH=1 senkt die Wartezeit an Schichten-Grenzen von ~180 µs auf ~4 µs (45× schneller).",
                        "RDMA / JACCL: Ab Thunderbolt 5 nativ nutzbar; auf Thunderbolt 4 optional zuschaltbar."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # oder: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-kv",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "4. Gewichtetes Schichten-Aufteilen & KV-Verdichtung",
                    summary: "Statt starrer Gleichverteilung weist SS-CCC jedem Mac genau den Schichten-Anteil zu, der seinem nutzbaren Speicher entspricht.",
                    bullets: [
                        "Formel: Schichten_i = Gesamtschichten × (Nutzbarer_Speicher_i / Gesamtspeicher).",
                        "KV-Zwischenspeicher: FP16 (~16k Zeichenblöcke), 8-Bit (~32k) oder 4-Bit (~64k+ für lange Agenten-Sitzungen).",
                        "Gestückelte Vorbefüllung (--prefill-step-size 512) verhindert Arbeitsspeicher-Spitzen beim Einlesen großer Quelltext-Dateien."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512"
                ),
                HelpDocSection(
                    id: "internet-coupling",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Internet-Verbund (WAN), Lokal-Kopplung & Weltrekord-Skalierung",
                    summary: "Verbinde mehrere Macs weltweit über Tailscale, WireGuard, ZeroTier oder QUIC zu einem gemeinsamen Verbund — oder kopple deinen lokalen Thunderbolt-Verbund direkt mit dem Internet-Verbund.",
                    bullets: [
                        "Hybrid-Kopplung (Lokal ↔ Internet): Der lokale TB4/TB5-Verbund arbeitet als schneller Kern (Rang 0), während entfernte WAN-Knoten zusätzliche Schichten übernehmen.",
                        "Schwarm-Baukasten & Weltrekord-Modus: Unterstützt auch Großverbünde mit 64, 128 oder 256+ verteilten Rechnern (Petals / SWARM / DiLoCo).",
                        "Echtzeit-Synchronisation: WebSocket-Relais (/ws/wan-chat) verteilt Raum-Einladungen, Topologie-Änderungen und Systemmeldungen."
                    ],
                    codeSample: "WebSocket-Chat-Relais: ws://127.0.0.1:8000/ws/wan-chat\nKopplung: Lokal (TB/RDMA) + Internet-WAN -> Hybrid-Verbund"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "6. Live-Teilnehmer-Chat & Verbund-Audio-Party (Sprachchat)",
                    summary: "Direkt neben dem Text-Chat bietet SS-CCC eine vollwertige Audio-Party nach Konsolen-Vorbild (Xbox / PlayStation), zugeschnitten auf verteilte KI-Teams.",
                    bullets: [
                        "Echtzeit-Sprachübertragung: Nutzt AVAudioEngine (16 kHz PCM16) über den eigenen Relais-Endpunkt /ws/wan-audio.",
                        "Sprachmodi: Umschaltbar zwischen Push-to-Talk (Sprechtaste) und Open-Mic (Dauersprechen) sowie Mikrofon-Stummschaltung und Taub-Modus.",
                        "Teilnehmer-Anzeige: Zeigt aktive Sprecher mit Pegelanzeige, verbundene Knoten-Rolle und Raum-Status in Echtzeit."
                    ],
                    codeSample: "WebSocket-Audio-Relais: ws://127.0.0.1:8000/ws/wan-audio"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "7. Forschungslabor (6 Reiter) & Verlaufsaufzeichnung",
                    summary: "Der wissenschaftliche Bereich untersucht lokale TB/RDMA-Verbünde, Internet-WAN-Verbünde sowie den direkten Vergleich beider Welten in sechs Fachreitern.",
                    bullets: [
                        "Reiter 1–2 (Grenzkurve & WAN): Williams-Roofline (Log-Log), TTFT/TPOT, GPipe-Blasen, Petals/SWARM-Kompression, N=1..128 Skalierung und DiLoCo vs. DDP.",
                        "Reiter 3–4 (Speicher & Energie): Transformer-Speichergleichung, TokenPowerBench (J/Token, EDP), regionaler Strommix (gCO₂/1M Token) und Stromkosten vs. Cloud.",
                        "Reiter 5 (Messreihen & Ausgabe): N=5/10/20 Läufe mit p50/p95/p99, 95-%-Konfidenzintervall, SLO-Goodput sowie CSV-, JSON-, LaTeX-(booktabs)- und 8-Quellen-BibTeX-Export.",
                        "Reiter 6 (Verlaufsaufzeichnung): Zeichnet Messwerte automatisch oder manuell für einzelne Positionen (Durchsatz, Latenz, Energie, WAN, Speicher) oder global als Zeitverlauf mit Trendgrafik und CSV-Export auf."
                    ],
                    codeSample: "Untersuchungs-Bereiche: Lokal (TB/RDMA) | Internet-WAN | Vergleich (Lokal vs. WAN)\nVerlauf: Einzel-Position aufzeichnen | Global aufzeichnen | Auto-Aufzeichnung"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "8. Laufzeit-Dienste: MLX, oMLX, Ollama & llama.cpp",
                    summary: "Im Modell-Studio lassen sich Modelle unmittelbar für den gewünschten örtlichen Dienst starten, live erkennen oder zwischen Formaten überführen.",
                    bullets: [
                        "oMLX (Port 8000): Nativer macOS-MLX-Dienst mit ausgelagertem SSD-KV-Zwischenspeicher sowie OpenAI- und Anthropic-Schnittstelle.",
                        "Ollama (Port 11434): Weit verbreiteter Dienst für örtliche GGUF-Modelle; vorhandene Modelle werden live eingelesen.",
                        "llama.cpp (Port 8080): Unmittelbarer GGUF-Dienst ohne Umwege."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents-launch",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "9. KI-Agenten (1-Klick), Start & Testsuite",
                    summary: "Alle Entwicklungswerkzeuge greifen über die örtliche Schnittstelle auf den gesamten Verbund zu — ohne Cloud-Übertragung.",
                    bullets: [
                        "1-Klick-Einrichtung: Schreibt Konfigurationsdateien für OpenCode, Hermes Agent und Google Antigravity; kompatibel mit Cursor, Continue, Open WebUI und Xcode.",
                        "App starten: ./scripts/run_ssccc.sh baut und öffnet die macOS-Oberfläche automatisch.",
                        "Qualitätsprüfung: python3 -m unittest discover -s tests -v prüft alle Swift-Modelle, Lokalisierungen und Endpunkte."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v\nOpenAI-Endpunkt: http://127.0.0.1:8000/v1"
                )
            ]

        case .en:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Universal Apple Silicon Clustering (M1–M12+)",
                    summary: "Any Mac with an Apple Silicon chip (M1 through M12+ — Base, Pro, Max, or Ultra) can join the cluster: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, and Mac Pro.",
                    bullets: [
                        "Future-Proof Generation Parsing: Memory bandwidth, FP16 TFLOPS, and Thunderbolt generation are inferred automatically even for upcoming M7–M12+ chips.",
                        "Automatic Rank Assignment: The Mac with the highest memory bandwidth automatically becomes Rank 0 (Coordinator).",
                        "Mixed Generations: Combine, for example, a MacBook Pro M2 Max with a Mac mini M4 and a Mac Studio M5 Max."
                    ],
                    codeSample: "Rank 0 = highest memory bandwidth (GB/s)\nRank 1..N = pipeline worker nodes"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "2. Unified Memory Pool & OOM Safety (iogpu.wired_limit_mb)",
                    summary: "CPU and GPU share unified memory on Apple Silicon. Never allocate 100% of physical RAM to MLX workloads.",
                    bullets: [
                        "Up to 24 GB RAM: Keep at least 4 GB reserved for macOS and WindowServer (e.g., 16 GB -> 12 GB usable).",
                        "32 GB to 64 GB RAM: Reserve 6 GB for macOS (e.g., 36 GB -> 30 GB usable).",
                        "96 GB+ RAM (Ultra/Max): Reserve 8 GB for macOS (e.g., 128 GB -> 120 GB usable).",
                        "SS-CCC verifies model weights + KV cache reserve against the combined usable pool before launch."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac -> 30 GB MLX limit"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. Networking, Thunderbolt Bridge (TB3/4/5) & RDMA",
                    summary: "SS-CCC isolates control-plane discovery (LAN/Wi-Fi) from high-speed activation tensor transfers (Thunderbolt).",
                    bullets: [
                        "Control Plane (LAN/Wi-Fi): Bonjour discovery, API gateway, and health checks.",
                        "Data Plane (Thunderbolt 3/4/5): Dedicated 10.99.1.x bridge delivering 30–37 Gbps (TB4) or up to 90 Gbps (TB5 RDMA).",
                        "Fast Metal Sync: MLX_METAL_FAST_SYNCH=1 cuts GPU/CPU fence overhead from ~180 µs to ~4 µs (45× faster).",
                        "RDMA / JACCL: Native on Thunderbolt 5; opt-in on Thunderbolt 4."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # or: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-kv",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "4. Weighted Pipeline Sharding & KV-Cache Quantization",
                    summary: "Instead of equal splits that overload smaller Macs, SS-CCC assigns layers proportionally to each node's usable memory.",
                    bullets: [
                        "Formula: Layers_i = TotalLayers × (UsableMemory_i / TotalUsableMemory).",
                        "KV-Cache Precision: FP16 (~16k tokens), 8-Bit (~32k), or 4-Bit (~64k+ for long agent sessions).",
                        "Chunked Prefill (--prefill-step-size 512) prevents memory spikes on large repositories."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512"
                ),
                HelpDocSection(
                    id: "internet-coupling",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Internet WAN Cluster, Local Coupling & World-Record Scaling",
                    summary: "Connect Macs globally over Tailscale, WireGuard, ZeroTier, or QUIC — or couple your local Thunderbolt cluster directly with an Internet WAN swarm.",
                    bullets: [
                        "Hybrid Coupling (Local <-> Internet): Your local TB4/TB5 cluster acts as the fast Rank-0 core while remote WAN peers contribute extra layers.",
                        "Mega-Cluster & Record Attempt Mode: Scales to 64, 128, or 256+ distributed nodes using Petals / SWARM / DiLoCo strategies.",
                        "Real-Time Relay: WebSocket endpoint (/ws/wan-chat) synchronizes room invites, topology updates, and participant messages."
                    ],
                    codeSample: "WebSocket Chat Relay: ws://127.0.0.1:8000/ws/wan-chat\nCoupling: Local (TB/RDMA) + Internet WAN -> Hybrid Cluster"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "6. Live Participant Chat & Cluster Audio-Party",
                    summary: "Right beside the text chat, SS-CCC includes a console-style Audio-Party (Xbox / PlayStation inspired) tailored for distributed AI cluster teams.",
                    bullets: [
                        "Low-Latency Voice: Powered by AVAudioEngine (16 kHz PCM16) over the dedicated /ws/wan-audio relay.",
                        "Voice Modes: Switch between Push-to-Talk and Open-Mic, with instant Mute, Deafen, and live audio level indicators.",
                        "Party Roster: Displays active speakers, node roles, and room status in real time."
                    ],
                    codeSample: "WebSocket Audio Relay: ws://127.0.0.1:8000/ws/wan-audio"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "7. Science & Roofline Lab (6 Tabs) & History Recording",
                    summary: "Analyze local TB/RDMA clusters, Internet WAN swarms, or side-by-side comparisons across six dedicated research tabs.",
                    bullets: [
                        "Tabs 1–2 (Roofline & WAN): Williams Log-Log Roofline, TTFT/TPOT, GPipe bubbles, Petals/SWARM compression, N=1..128 scaling, and DiLoCo vs. DDP.",
                        "Tabs 3–4 (Memory & Energetics): Transformer memory equation, TokenPowerBench (J/tok, EDP), regional carbon intensity (gCO2/1M tok), and electricity TCO vs. cloud.",
                        "Tab 5 (Trials & Export): N=5/10/20 reproducible trials with p50/p95/p99, 95% CI, SLO Goodput, plus CSV, JSON, LaTeX (booktabs), and 8-paper BibTeX export.",
                        "Tab 6 (History Recording): Records snapshots automatically or manually per single position (Throughput, Latency, Energetics, WAN, Memory) or globally with dual-line trend chart and CSV export."
                    ],
                    codeSample: "Scopes: Local (TB/RDMA) | Internet WAN | Comparison (Local vs. WAN)\nHistory: Record Single Position | Record Global | Auto-Record"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "8. Runtime Services: MLX, oMLX, Ollama & llama.cpp",
                    summary: "Launch models directly in your preferred local runtime or scan local Ollama/GGUF models into fast MLX.",
                    bullets: [
                        "oMLX (Port 8000): Native macOS MLX server with paged SSD KV-cache and OpenAI + Anthropic endpoints.",
                        "Ollama (Port 11434): Zero-config GGUF runner with live model discovery.",
                        "llama.cpp (Port 8080): Direct llama-server GGUF execution."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents-launch",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "9. AI Agents (1-Click), Launch & Verification",
                    summary: "Point local coding agents and editors to your unified Apple Silicon cluster with zero cloud leakage.",
                    bullets: [
                        "1-Click Config: Writes configs for OpenCode, Hermes Agent, and Google Antigravity; compatible with Cursor, Continue, Open WebUI, and Xcode.",
                        "Launch App: ./scripts/run_ssccc.sh builds and opens the macOS UI.",
                        "Test Suite: python3 -m unittest discover -s tests -v verifies Swift models, localizations, and endpoints."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v\nOpenAI Endpoint: http://127.0.0.1:8000/v1"
                )
            ]

        case .fr:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Tous les Mac à puce Apple M en grappe (M1 à M12+)",
                    summary: "Tout Mac équipé d'une puce Apple Silicon (M1 à M12+ — Base, Pro, Max ou Ultra) peut rejoindre la grappe : Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio et Mac Pro.",
                    bullets: [
                        "Détection évolutive : bande passante mémoire, FP16 TFLOPS et génération Thunderbolt sont déduits automatiquement jusqu'aux puces M12+.",
                        "Attribution automatique du rang : le Mac ayant le plus fort débit mémoire devient le maître (rang 0).",
                        "Générations mixtes : associez un MacBook Pro M2 Max, un Mac mini M4 et un Mac Studio M5 Max."
                    ],
                    codeSample: "Rang 0 = débit mémoire maximal (Go/s)\nRang 1..N = nœuds de calcul suivants"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "2. Mémoire unifiée et garde de sécurité (iogpu.wired_limit_mb)",
                    summary: "Sur Apple Silicon, le processeur et le GPU partagent la même mémoire. N'allouez jamais 100 % de la RAM aux modèles.",
                    bullets: [
                        "Jusqu'à 24 Go : gardez au moins 4 Go réservés pour macOS.",
                        "De 32 Go à 64 Go : réservez 6 Go pour le système.",
                        "À partir de 96 Go : réservez 8 Go pour macOS."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. Réseau, pont Thunderbolt (TB3/4/5) et RDMA",
                    summary: "SS-CCC sépare le plan de commande (LAN/Wi-Fi) du transfert des tenseurs sur Thunderbolt 3/4/5 (10.99.1.x, 30–90 Gbps).",
                    bullets: [
                        "MLX_METAL_FAST_SYNCH=1 réduit la latence de synchronisation GPU/CPU de ~180 µs à ~4 µs (45× plus rapide).",
                        "RDMA / JACCL disponible nativement dès Thunderbolt 5."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-kv",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "4. Répartition pondérée et compression du cache KV",
                    summary: "Chaque Mac reçoit une part de couches proportionnelle à sa mémoire disponible.",
                    bullets: [
                        "Compression 4 bits (--kv-bits 4) pour les longs contextes d'agents (64k+ jetons).",
                        "Pré-remplissage découpé (--prefill-step-size 512) contre les pics mémoire."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512"
                ),
                HelpDocSection(
                    id: "internet-coupling",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Grappe Internet (WAN), couplage local et record mondial",
                    summary: "Reliez des Mac à travers le monde via Tailscale, WireGuard, ZeroTier ou QUIC, ou couplez votre grappe Thunderbolt locale avec la grappe Internet.",
                    bullets: [
                        "Couplage hybride (Local <-> Internet) : la grappe Thunderbolt locale forme le cœur rapide (rang 0) étendu par les nœuds WAN.",
                        "Passage à l'échelle (64, 128, 256+ nœuds) avec Petals, SWARM et DiLoCo via le relais /ws/wan-chat."
                    ],
                    codeSample: "Relais WebSocket : ws://127.0.0.1:8000/ws/wan-chat"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "6. Messagerie instantanée et salon vocal (Audio-Party)",
                    summary: "À côté de la messagerie écrite, un salon vocal inspiré des consoles (Xbox / PlayStation) permet de coordonner les essais distribués.",
                    bullets: [
                        "Audio temps réel via AVAudioEngine (PCM16 16 kHz) sur le relais /ws/wan-audio.",
                        "Modes Appuyer-pour-parler ou Micro ouvert, coupure micro/son et indicateur de parole."
                    ],
                    codeSample: "Relais audio WebSocket : ws://127.0.0.1:8000/ws/wan-audio"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "7. Laboratoire scientifique (6 onglets) et historique",
                    summary: "Analysez la grappe locale, la grappe Internet ou leur comparaison directe avec enregistrement chronologique.",
                    bullets: [
                        "Onglets 1 à 5 : Roofline (Williams), décomposition WAN, DiLoCo vs DDP, équation mémoire, énergie (J/jeton, EDP, CO₂), essais p50/p95/p99 et export CSV/JSON/LaTeX/BibTeX.",
                        "Onglet 6 (Historique) : enregistrement automatique ou manuel par position unique (débit, latence, énergie, WAN, mémoire) ou global avec graphique et export CSV."
                    ],
                    codeSample: "Portées : Local (TB/RDMA) | Internet-WAN | Comparaison (Local vs WAN)"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "8. Moteurs locaux : MLX, oMLX, Ollama et llama.cpp",
                    summary: "Lancez vos modèles directement dans oMLX (cache SSD paginé), Ollama ou llama.cpp.",
                    bullets: [
                        "oMLX (port 8000), Ollama (port 11434) et llama.cpp (port 8080) sont gérés depuis le Studio de modèles."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents-launch",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "9. Agents locaux (1 clic), lancement et tests",
                    summary: "Reliez OpenCode, Hermes Agent et Google Antigravity à la grappe locale sans fuite vers le nuage.",
                    bullets: [
                        "Compatible avec OpenCode, Hermes Agent, Google Antigravity, Cursor, Continue et Xcode.",
                        "Lancement : ./scripts/run_ssccc.sh · Tests : python3 -m unittest discover -s tests -v"
                    ],
                    codeSample: "./scripts/run_ssccc.sh\nhttp://127.0.0.1:8000/v1"
                )
            ]

        case .es:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Todos los Mac con procesador M en conjunto (M1–M12+)",
                    summary: "Cualquier Mac con Apple Silicon (M1 a M12+ — Base, Pro, Max o Ultra) puede unirse al conjunto: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio y Mac Pro.",
                    bullets: [
                        "Detección preparada para el futuro: ancho de banda, FP16 TFLOPS y generación Thunderbolt se calculan automáticamente hasta M12+.",
                        "Asignación automática de rango: el Mac con mayor ancho de banda de memoria asume el rango 0.",
                        "Generaciones mixtas totalmente compatibles."
                    ],
                    codeSample: "Rango 0 = mayor ancho de banda (GB/s)"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "2. Memoria unificada y límite seguro (iogpu.wired_limit_mb)",
                    summary: "Nunca asignes el 100 % de la RAM al cálculo gráfico; reserva siempre espacio para macOS.",
                    bullets: [
                        "Hasta 24 GB: reserva al menos 4 GB para macOS.",
                        "De 32 GB a 64 GB: reserva 6 GB.",
                        "Desde 96 GB: reserva 8 GB."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. Red, puente Thunderbolt (TB3/4/5) y RDMA",
                    summary: "Control por LAN/Wi-Fi y transferencia de tensores aislada por Thunderbolt 3/4/5 (10.99.1.x, 30–90 Gbps).",
                    bullets: [
                        "MLX_METAL_FAST_SYNCH=1 reduce la espera GPU/CPU de ~180 µs a ~4 µs (45× más rápido).",
                        "RDMA / JACCL nativo desde Thunderbolt 5."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-kv",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "4. Reparto ponderado de capas y compresión KV",
                    summary: "Cada Mac recibe capas proporcionales a su memoria utilizable.",
                    bullets: [
                        "Compresión de caché KV de 4 bits (--kv-bits 4) para contextos largos de agentes."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512"
                ),
                HelpDocSection(
                    id: "internet-coupling",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Conjunto de Internet (WAN), acoplamiento local y récord mundial",
                    summary: "Conecta Macs por Internet mediante Tailscale, WireGuard, ZeroTier o QUIC, o acopla tu conjunto local Thunderbolt con el conjunto de Internet.",
                    bullets: [
                        "Acoplamiento híbrido (Local <-> Internet): el núcleo Thunderbolt local actúa como rango 0 ampliado por nodos WAN.",
                        "Escalado a 64, 128 o 256+ nodos con Petals, SWARM y DiLoCo mediante /ws/wan-chat."
                    ],
                    codeSample: "Retransmisión WebSocket: ws://127.0.0.1:8000/ws/wan-chat"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "6. Chat en directo y sala de audio (Audio-Party)",
                    summary: "Junto al chat de texto, una sala de voz estilo consola (Xbox / PlayStation) permite coordinar pruebas distribuidas en tiempo real.",
                    bullets: [
                        "Voz en tiempo real con AVAudioEngine (PCM16 16 kHz) mediante /ws/wan-audio.",
                        "Modos Pulsar para hablar / Micrófono abierto, silencio y nivel de voz activo."
                    ],
                    codeSample: "Audio WebSocket: ws://127.0.0.1:8000/ws/wan-audio"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "7. Laboratorio científico (6 pestañas) e historial",
                    summary: "Evalúa el conjunto local, el conjunto WAN o su comparación directa con registro histórico.",
                    bullets: [
                        "Pestañas 1–5: Roofline (Williams), latencia WAN, DiLoCo vs DDP, memoria/KV, energía (J/token, EDP, CO₂), ensayos p50/p95/p99 y exportación CSV/JSON/LaTeX/BibTeX.",
                        "Pestaña 6 (Historial): grabación automática o manual por posición individual o global con gráfico de tendencia y exportación CSV."
                    ],
                    codeSample: "Ámbitos: Local (TB/RDMA) | Internet-WAN | Comparación (Local vs. WAN)"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "8. Motores locales: MLX, oMLX, Ollama y llama.cpp",
                    summary: "Carga modelos en oMLX (caché SSD paginada), Ollama o llama.cpp desde el Estudio de modelos.",
                    bullets: [
                        "Puertos predeterminados: oMLX (8000), Ollama (11434), llama.cpp (8080)."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents-launch",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "9. Agentes locales (1 clic), inicio y pruebas",
                    summary: "Conecta OpenCode, Hermes Agent y Google Antigravity al conjunto local en un clic.",
                    bullets: [
                        "Compatible también con Cursor, Continue, Open WebUI y Xcode.",
                        "Inicio: ./scripts/run_ssccc.sh · Pruebas: python3 -m unittest discover -s tests -v"
                    ],
                    codeSample: "./scripts/run_ssccc.sh\nhttp://127.0.0.1:8000/v1"
                )
            ]

        case .pt:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Todos os Mac com processador M em conjunto (M1–M12+)",
                    summary: "Qualquer Mac com Apple Silicon (M1 a M12+ — Base, Pro, Max ou Ultra) pode integrar o conjunto: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio e Mac Pro.",
                    bullets: [
                        "Deteção preparada para o futuro: largura de banda, FP16 TFLOPS e geração Thunderbolt são inferidos automaticamente até M12+.",
                        "Atribuição automática de nível: o Mac com maior largura de banda assume o nível 0.",
                        "Expansível livremente em «Dispositivos e Comparação»."
                    ],
                    codeSample: "Nível 0 = maior largura de banda (GB/s)"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "2. Memória unificada e limite seguro (iogpu.wired_limit_mb)",
                    summary: "Nunca aloque 100 % da RAM; mantenha sempre uma reserva fixa para o macOS.",
                    bullets: [
                        "Até 24 GB: reserve 4 GB para o macOS.",
                        "De 32 GB a 64 GB: reserve 6 GB.",
                        "A partir de 96 GB: reserve 8 GB."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. Rede, ponte Thunderbolt (TB3/4/5) e RDMA",
                    summary: "Controlo por LAN/Wi-Fi e tensores isolados por Thunderbolt 3/4/5 (10.99.1.x, 30–90 Gbps).",
                    bullets: [
                        "MLX_METAL_FAST_SYNCH=1 reduz a sincronização GPU/CPU de ~180 µs para ~4 µs (45× mais rápida).",
                        "RDMA / JACCL nativo a partir do Thunderbolt 5."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-kv",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "4. Repartição ponderada de camadas e compressão KV",
                    summary: "Cada Mac recebe camadas proporcionais à sua memória utilizável.",
                    bullets: [
                        "Compressão de cache KV de 4 bits (--kv-bits 4) para contextos longos de agentes."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512"
                ),
                HelpDocSection(
                    id: "internet-coupling",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Conjunto Internet (WAN), acoplamento local e recorde mundial",
                    summary: "Ligue Macs pela Internet via Tailscale, WireGuard, ZeroTier ou QUIC, ou acople o seu conjunto Thunderbolt local ao conjunto Internet.",
                    bullets: [
                        "Acoplamento híbrido (Local <-> Internet): o núcleo Thunderbolt local atua como nível 0 estendido por nós WAN.",
                        "Escala para 64, 128 ou 256+ nós com Petals, SWARM e DiLoCo através de /ws/wan-chat."
                    ],
                    codeSample: "Relé WebSocket: ws://127.0.0.1:8000/ws/wan-chat"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "6. Chat em direto e sala de áudio (Audio-Party)",
                    summary: "Ao lado do chat de texto, uma sala de voz estilo consola (Xbox / PlayStation) permite coordenar testes distribuídos em tempo real.",
                    bullets: [
                        "Voz em tempo real com AVAudioEngine (PCM16 16 kHz) através de /ws/wan-audio.",
                        "Modos Premir para falar / Microfone aberto, silenciar e indicador de voz ativo."
                    ],
                    codeSample: "Áudio WebSocket: ws://127.0.0.1:8000/ws/wan-audio"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "7. Laboratório científico (6 separadores) e histórico",
                    summary: "Analise o conjunto local, o conjunto WAN ou a comparação direta com registo histórico.",
                    bullets: [
                        "Separadores 1–5: Roofline (Williams), latência WAN, DiLoCo vs DDP, memória/KV, energia (J/token, EDP, CO₂), ensaios p50/p95/p99 e exportação CSV/JSON/LaTeX/BibTeX.",
                        "Separador 6 (Histórico): gravação automática ou manual por posição individual ou global com gráfico de tendência e exportação CSV."
                    ],
                    codeSample: "Âmbitos: Local (TB/RDMA) | Internet-WAN | Comparação (Local vs. WAN)"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "8. Motores locais: MLX, oMLX, Ollama e llama.cpp",
                    summary: "Carregue modelos no oMLX, Ollama ou llama.cpp diretamente a partir do Estúdio de Modelos.",
                    bullets: [
                        "Portas predefinidas: oMLX (8000), Ollama (11434), llama.cpp (8080)."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents-launch",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "9. Agentes locais (1 clique), arranque e testes",
                    summary: "Ligue o OpenCode, o Hermes Agent e o Google Antigravity ao conjunto local num clique.",
                    bullets: [
                        "Compatível também com Cursor, Continue, Open WebUI e Xcode.",
                        "Arranque: ./scripts/run_ssccc.sh · Testes: python3 -m unittest discover -s tests -v"
                    ],
                    codeSample: "./scripts/run_ssccc.sh\nhttp://127.0.0.1:8000/v1"
                )
            ]
        }
    }
}
