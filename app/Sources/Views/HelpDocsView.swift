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

        case .ru:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Универсальная кластеризация Apple Silicon (M1–M12+)",
                    summary: "Любой Mac с чипом Apple Silicon (M1–M12+ — Base, Pro, Max, Ultra) может войти в кластер: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio и Mac Pro.",
                    bullets: [
                        "Перспективное распознавание: ПСП, FP16 TFLOPS и поколение Thunderbolt определяются автоматически даже для будущих M7–M12+.",
                        "Автоназначение ранга: Mac с максимальной ПСП автоматически становится Рангом 0 (Координатор).",
                        "Смешанные поколения: объединяйте MacBook Pro M2 Max, Mac mini M4 и Mac Studio M5 Max."
                    ],
                    codeSample: "Rank 0 = максимальная ПСП (ГБ/с)\nRank 1..N = рабочие узлы конвейера"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "2. Единая память и защита от OOM (iogpu.wired_limit_mb)",
                    summary: "CPU и GPU делят единую память. Никогда не отдавайте MLX 100% физической RAM.",
                    bullets: [
                        "До 24 ГБ RAM: резервируйте минимум 4 ГБ для macOS и WindowServer (16 ГБ -> 12 ГБ доступно).",
                        "32–64 ГБ RAM: резервируйте 6 ГБ для macOS (36 ГБ -> 30 ГБ доступно).",
                        "96+ ГБ RAM (Ultra/Max): резервируйте 8 ГБ для macOS (128 ГБ -> 120 ГБ доступно).",
                        "SS-CCC проверяет веса модели + резерв KV-кэша до запуска."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Mac 36 ГБ -> лимит 30 ГБ"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. Сеть, мост Thunderbolt (TB3/4/5) и RDMA",
                    summary: "SS-CCC разделяет плоскость управления (LAN/Wi-Fi) и скоростную передачу тензоров (Thunderbolt).",
                    bullets: [
                        "Управление (LAN/Wi-Fi): Bonjour, API-шлюз и проверка здоровья.",
                        "Данные (Thunderbolt 3/4/5): мост 10.99.1.x со скоростью 30–37 Гбит/с (TB4) или до 90+ Гбит/с (TB5 RDMA).",
                        "Fast Metal Sync: MLX_METAL_FAST_SYNCH=1 сокращает синхронизацию со ~180 мкс до ~4 мкс (в 45× быстрее).",
                        "RDMA / JACCL: нативно на Thunderbolt 5 (macOS 26.2+)."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # или: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-kv",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "4. Взвешенный шардинг и квантование KV-кэша",
                    summary: "Вместо равного деления SS-CCC назначает слои пропорционально доступной памяти каждого узла.",
                    bullets: [
                        "Формула: Layers_i = TotalLayers × (Usable_i / TotalUsable).",
                        "Точность KV-кэша: FP16 (~16k), 8-Bit (~32k) или 4-Bit (~64k+ для длинных сессий агентов).",
                        "Chunked Prefill (--prefill-step-size 512) предотвращает пики памяти."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512"
                ),
                HelpDocSection(
                    id: "internet-coupling",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Интернет-кластер WAN, гибридная связка и мировой рекорд",
                    summary: "Объединяйте Mac по всему миру через Tailscale, WireGuard или QUIC — или свяжите локальный Thunderbolt-кластер с роем WAN.",
                    bullets: [
                        "Гибрид (Локальный <-> Интернет): локальное кольцо TB4/TB5 работает как ядро Ранга 0, а удалённые WAN-узлы добавляют слои.",
                        "Мега-кластер: масштабируется до 64, 128 и 256+ узлов по стратегиям Petals / SWARM / DiLoCo.",
                        "Чат в реальном времени: WebSocket (/ws/wan-chat) синхронизирует комнаты, топологию и сообщения."
                    ],
                    codeSample: "WebSocket-чат: ws://127.0.0.1:8000/ws/wan-chat"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "6. Живой чат участников и кластерная Audio-Party",
                    summary: "Консольный голосовой чат (в духе Xbox / PlayStation) прямо рядом с текстовым чатом.",
                    bullets: [
                        "Низкая задержка: AVAudioEngine (16 кГц PCM16) через ретранслятор /ws/wan-audio.",
                        "Режимы: Push-to-Talk и Open-Mic, мгновенное отключение микрофона/звука и индикатор уровня.",
                        "Список участников: показывает активных спикеров и роли узлов."
                    ],
                    codeSample: "WebSocket-аудио: ws://127.0.0.1:8000/ws/wan-audio"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "7. Научная лаборатория (6 вкладок) и запись истории",
                    summary: "Анализируйте локальные TB/RDMA-кластеры, WAN-рои или сравнение бок о бок на 6 вкладках.",
                    bullets: [
                        "Вкладки 1–2: Williams Log-Log Roofline, TTFT/TPOT, пузыри GPipe, Petals/SWARM, масштаб N=1..128.",
                        "Вкладки 3–4: уравнение памяти, TokenPowerBench (Дж/ток, EDP), углеродный след и TCO.",
                        "Вкладка 5: воспроизводимые серии N=5/10/20 с p50/p95/p99, CI95 и экспортом CSV, JSON, LaTeX, BibTeX.",
                        "Вкладка 6 (История): запись по отдельным позициям или глобально с графиком тренда и экспортом CSV."
                    ],
                    codeSample: "Режимы: Локально (TB/RDMA) | Интернет WAN | Сравнение (Локально vs WAN)"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "8. Среды выполнения: MLX, oMLX, Ollama и llama.cpp",
                    summary: "Запускайте модели напрямую или сканируйте локальные модели Ollama/GGUF в быстрый MLX.",
                    bullets: [
                        "oMLX (порт 8000): нативный сервер macOS MLX с подкачкой KV-кэша на SSD и API OpenAI + Anthropic.",
                        "Ollama (порт 11434): быстрый запуск GGUF.",
                        "llama.cpp (порт 8080): прямой запуск llama-server."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents-launch",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "9. ИИ-агенты (1 клик), запуск и проверка",
                    summary: "Подключите локальных кодинг-агентов и IDE к вашему кластеру без утечки данных в облако.",
                    bullets: [
                        "1-клик настройка: OpenCode, Hermes Agent, Google Antigravity; совместимо с Cursor, Continue, Xcode.",
                        "Запуск приложения: ./scripts/run_ssccc.sh собирает и открывает UI macOS.",
                        "Тесты: python3 -m unittest discover -s tests -v."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\nOpenAI Endpoint: http://127.0.0.1:8000/v1"
                )
            ]

        case .ja:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. ユニバーサル Apple Silicon クラスタリング (M1–M12+)",
                    summary: "Apple Silicon（M1〜M12+ — Base, Pro, Max, Ultra）搭載のすべてのMac（Mac mini, MacBook Air/Pro, iMac, Mac Studio, Mac Pro）が参加可能です。",
                    bullets: [
                        "将来対応の自動判別: メモリ帯域幅・FP16 TFLOPS・Thunderbolt世代を自動推定します。",
                        "自動ランク割り当て: 最もメモリ帯域が広いMacが自動的にランク0（コーディネーター）になります。",
                        "異種世代混在: 例として MacBook Pro M2 Max、Mac mini M4、Mac Studio M5 Max を組み合わせ可能。"
                    ],
                    codeSample: "Rank 0 = 最大メモリ帯域 (GB/s)\nRank 1..N = パイプラインワーカー"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "2. 統合メモリプールとOOM保護 (iogpu.wired_limit_mb)",
                    summary: "CPUとGPUがメモリを共有するため、物理RAMの100%をMLXに割り当てないでください。",
                    bullets: [
                        "24 GB以下: macOSとWindowServer用に最低4 GBを確保（16 GB → 12 GB利用可能）。",
                        "32〜64 GB: macOS用に6 GBを確保（36 GB → 30 GB利用可能）。",
                        "96 GB以上 (Ultra/Max): macOS用に8 GBを確保（128 GB → 120 GB利用可能）。",
                        "起動前にモデル重み＋KVキャッシュ予備を合計プールと照合します。"
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac -> 30 GB 上限"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. ネットワーク、Thunderboltブリッジ (TB3/4/5) とRDMA",
                    summary: "制御プレーン（LAN/Wi-Fi）と高速テンソル転送（Thunderbolt）を完全に分離します。",
                    bullets: [
                        "制御プレーン (LAN/Wi-Fi): Bonjour探索、APIゲートウェイ、ヘルスチェック。",
                        "データプレーン (TB3/4/5): 専用 10.99.1.x ブリッジで 30–37 Gbps (TB4) または最大 90+ Gbps (TB5 RDMA)。",
                        "Fast Metal Sync: MLX_METAL_FAST_SYNCH=1 により同期遅延を ~180 µs から ~4 µs へ45倍高速化。",
                        "RDMA / JACCL: Thunderbolt 5 (macOS 26.2+) でネイティブ対応。"
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # または mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-kv",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "4. 重み付きパイプライン分割とKVキャッシュ量子化",
                    summary: "均等分割ではなく、各ノードの利用可能メモリに比例してレイヤーを割り当てます。",
                    bullets: [
                        "計算式: Layers_i = TotalLayers × (Usable_i / TotalUsable)。",
                        "KVキャッシュ精度: FP16 (~16k)、8-Bit (~32k)、4-Bit (~64k+ 長文エージェント向け)。",
                        "Chunked Prefill (--prefill-step-size 512) でメモリスパイクを防止。"
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512"
                ),
                HelpDocSection(
                    id: "internet-coupling",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "5. インターネットWANクラスター、ローカル連携＆世界記録挑戦",
                    summary: "Tailscale・WireGuard・QUIC経由で世界中のMacを接続し、ローカルTBクラスターとWAN群を直結できます。",
                    bullets: [
                        "ハイブリッド連携: ローカルTB4/TB5リングが高速Rank 0コアとして動作し、遠隔WANノードが追加レイヤーを担当。",
                        "メガクラスター: Petals / SWARM / DiLoCo戦略で 64〜256+ ノードへ拡張。",
                        "リアルタイムリレー: WebSocket (/ws/wan-chat) で招待・構成・メッセージを同期。"
                    ],
                    codeSample: "WebSocketチャット: ws://127.0.0.1:8000/ws/wan-chat"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "6. ライブ参加者チャット＆クラスター Audio-Party",
                    summary: "テキストチャットのすぐ隣にコンソール風の音声パーティー（Xbox / PlayStation風）を内蔵。",
                    bullets: [
                        "低遅延音声: AVAudioEngine (16 kHz PCM16) と専用 /ws/wan-audio リレー。",
                        "音声モード: Push-to-Talk / Open-Mic 切替、ミュート・スピーカーオフ・音量メーター対応。",
                        "参加者一覧: 発言中スピーカーとノード役割をリアルタイム表示。"
                    ],
                    codeSample: "WebSocket音声: ws://127.0.0.1:8000/ws/wan-audio"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "7. 科学＆Rooflineラボ (6タブ) と履歴記録",
                    summary: "ローカルTB/RDMA、インターネットWAN、または両者の並列比較を6つの研究タブで分析します。",
                    bullets: [
                        "タブ1–2: Williams両対数Roofline、TTFT/TPOT、GPipeバブル、Petals/SWARM圧縮、N=1..128拡張。",
                        "タブ3–4: メモリ方程式、TokenPowerBench (J/tok, EDP)、CO₂排出量、電力TCO比較。",
                        "タブ5: N=5/10/20 再現ベンチマーク (p50/p95/p99, CI95) と CSV/JSON/LaTeX/BibTeX 出力。",
                        "タブ6 (履歴): 単一項目または全体のスナップショットを自動・手動記録し、2軸グラフとCSV出力に対応。"
                    ],
                    codeSample: "スコープ: ローカル (TB/RDMA) | インターネットWAN | 比較 (ローカル vs WAN)"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "8. ランタイム: MLX, oMLX, Ollama & llama.cpp",
                    summary: "お好みのローカルランタイムで直接モデルを起動、またはOllama/GGUFを高速MLXへ取り込みます。",
                    bullets: [
                        "oMLX (ポート8000): SSDページングKVキャッシュ対応のネイティブmacOS MLXサーバー。",
                        "Ollama (ポート11434): ゼロ設定GGUFランナー。",
                        "llama.cpp (ポート8080): llama-server による直接GGUF実行。"
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents-launch",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "9. AIエージェント連携 (1クリック)、起動と検証",
                    summary: "クラウドへのデータ流出なしでローカルのコーディングエージェントやIDEを接続します。",
                    bullets: [
                        "1クリック設定: OpenCode, Hermes Agent, Google Antigravity に対応（Cursor, Continue, Xcode互換）。",
                        "起動: ./scripts/run_ssccc.sh でビルド＆起動。",
                        "テスト: python3 -m unittest discover -s tests -v でモデル・翻訳・APIを検証。"
                    ],
                    codeSample: "./scripts/run_ssccc.sh\nOpenAI Endpoint: http://127.0.0.1:8000/v1"
                )
            ]

        case .zh:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. 全系列 Apple Silicon Mac 通用集群 (M1–M12+)",
                    summary: "任何搭载 Apple Silicon（M1 至 M12+ — Base、Pro、Max、Ultra）的 Mac 均可加入集群：Mac mini、MacBook Air、MacBook Pro、iMac、Mac Studio 与 Mac Pro。",
                    bullets: [
                        "面向未来的芯片解析：自动推断内存带宽、FP16 TFLOPS 与 Thunderbolt 代际，原生兼容未来 M7–M12+。",
                        "自动分配排名：内存带宽最高的 Mac 自动成为 Rank 0（协调器）。",
                        "跨代混搭：例如可将 MacBook Pro M2 Max、Mac mini M4 与 Mac Studio M5 Max 混合组网。"
                    ],
                    codeSample: "Rank 0 = 最高内存带宽 (GB/s)\nRank 1..N = 流水线工作节点"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "2. 统一内存池与 OOM 防护 (iogpu.wired_limit_mb)",
                    summary: "Apple Silicon 的 CPU 与 GPU 共享统一内存，切勿将 100% 物理内存分配给 MLX。",
                    bullets: [
                        "24 GB 及以下：至少为 macOS 与 WindowServer 保留 4 GB（如 16 GB → 12 GB 可用）。",
                        "32–64 GB：为 macOS 保留 6 GB（如 36 GB → 30 GB 可用）。",
                        "96 GB+ (Ultra/Max)：为 macOS 保留 8 GB（如 128 GB → 120 GB 可用）。",
                        "启动前自动校验模型权重与 KV 缓存预留是否超出总可用内存池。"
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac -> 30 GB 上限"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. 网络架构、Thunderbolt 桥接 (TB3/4/5) 与 RDMA",
                    summary: "SS-CCC 将控制平面（LAN/Wi-Fi）与高速张量传输（Thunderbolt）彻底隔离。",
                    bullets: [
                        "控制平面 (LAN/Wi-Fi)：Bonjour 服务发现、API 网关与健康检查。",
                        "数据平面 (TB3/4/5)：专用 10.99.1.x 桥接，提供 30–37 Gbps (TB4) 或高达 90+ Gbps (TB5 RDMA)。",
                        "Fast Metal Sync：MLX_METAL_FAST_SYNCH=1 将 GPU/CPU 同步延迟从 ~180 µs 降至 ~4 µs（提速 45×）。",
                        "RDMA / JACCL：Thunderbolt 5 (macOS 26.2+) 原生支持。"
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # 或 mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-kv",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "4. 加权流水线分片与 KV 缓存量化",
                    summary: "不同于易使小内存 Mac 过载的均分策略，SS-CCC 按各节点可用内存比例分配层数。",
                    bullets: [
                        "分配公式：Layers_i = TotalLayers × (Usable_i / TotalUsable)。",
                        "KV 缓存精度：FP16 (~16k)、8-Bit (~32k) 或 4-Bit (~64k+ 长上下文智能体会话)。",
                        "分块预填充 (--prefill-step-size 512) 防止大型代码库引发内存尖峰。"
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512"
                ),
                HelpDocSection(
                    id: "internet-coupling",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "5. 互联网 WAN 集群、本地混合耦合与世界纪录挑战",
                    summary: "通过 Tailscale、WireGuard 或 QUIC 连接全球 Mac，或将本地 Thunderbolt 集群直接耦合至互联网 WAN 集群。",
                    bullets: [
                        "混合耦合 (本地 <-> 互联网)：本地 TB4/TB5 环作为高速 Rank 0 核心，远程 WAN 节点分担额外层数。",
                        "超大规模挑战：结合 Petals / SWARM / DiLoCo 策略扩展至 64、128 甚至 256+ 节点。",
                        "实时中继：WebSocket (/ws/wan-chat) 同步房间邀请、拓扑更新与聊天消息。"
                    ],
                    codeSample: "WebSocket 聊天中继: ws://127.0.0.1:8000/ws/wan-chat"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "6. 实时参与者聊天与集群 Audio-Party 语音派对",
                    summary: "在文字聊天旁内置主机风格语音派对（灵感源自 Xbox / PlayStation），专为分布式 AI 团队打造。",
                    bullets: [
                        "低延迟语音：基于 AVAudioEngine (16 kHz PCM16) 与专用 /ws/wan-audio 中继。",
                        "语音模式：支持按键通话 (Push-to-Talk) 与自由麦 (Open-Mic)、一键静音/闭麦与电平指示。",
                        "成员列表：实时显示当前发言者与节点角色。"
                    ],
                    codeSample: "WebSocket 音频中继: ws://127.0.0.1:8000/ws/wan-audio"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "7. 科学与 Roofline 实验室 (6 个标签页) 与历史记录",
                    summary: "在六个专业研究标签页中分析本地 TB/RDMA 集群、互联网 WAN 集群或两者并排对比。",
                    bullets: [
                        "标签 1–2：Williams 双对数 Roofline、TTFT/TPOT、GPipe 气泡、Petals/SWARM 压缩与 N=1..128 扩展。",
                        "标签 3–4：Transformer 内存方程、TokenPowerBench (J/tok, EDP)、碳足迹与电力 TCO 对比。",
                        "标签 5：N=5/10/20 可复现基准测试（p50/p95/p99, 95% CI），支持 CSV、JSON、LaTeX 与 BibTeX 导出。",
                        "标签 6 (历史记录)：支持单指标或全局自动/手动快照录制、双曲线趋势图与 CSV 导出。"
                    ],
                    codeSample: "分析范围: 本地 (TB/RDMA) | 互联网 WAN | 对比 (本地 vs WAN)"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "8. 运行时服务：MLX、oMLX、Ollama 与 llama.cpp",
                    summary: "直接在首选本地运行时加载模型，或将本地 Ollama/GGUF 模型扫描导入高速 MLX。",
                    bullets: [
                        "oMLX (端口 8000)：原生 macOS MLX 服务器，支持 SSD 分页 KV 缓存及 OpenAI + Anthropic 接口。",
                        "Ollama (端口 11434)：零配置 GGUF 运行时。",
                        "llama.cpp (端口 8080)：直接运行 llama-server GGUF。"
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents-launch",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "9. AI 智能体一键配置、启动与验证",
                    summary: "将本地编程智能体与编辑器接入统一 Apple Silicon 集群，零云端数据泄漏。",
                    bullets: [
                        "一键配置：自动生成 OpenCode、Hermes Agent、Google Antigravity 配置，兼容 Cursor、Continue、Xcode。",
                        "启动应用：./scripts/run_ssccc.sh 自动编译并打开 macOS 界面。",
                        "测试套件：python3 -m unittest discover -s tests -v 校验模型、本地化与接口。"
                    ],
                    codeSample: "./scripts/run_ssccc.sh\nOpenAI Endpoint: http://127.0.0.1:8000/v1"
                )
            ]
        }
    }
}
