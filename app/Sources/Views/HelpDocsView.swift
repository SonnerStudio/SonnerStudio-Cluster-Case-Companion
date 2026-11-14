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
                        Text("\(sections.count)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(SolarisTheme.amber)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(SolarisTheme.amber.opacity(0.18)))
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
                        "Gemischte Generationen: Ein MacBook Pro M2 Max arbeitet problemlos mit einem Mac mini M4 oder einem Mac Studio M5 Max zusammen.",
                        "Alle Bauformen unterstützt: Stationäre Workstations (Mac Studio, Mac Pro, Mac mini, iMac) und mobile Macs (MacBook Air/Pro) teilen sich gemeinsam Modell-Schichten."
                    ],
                    codeSample: "Rang 0 = höchster Speicherdurchsatz (GB/s) -> Leitrechner & API-Eingang\nRang 1..N = nachgeschaltete Rechner im gewichteten Schichten-Verbund"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-Reiter-Cluster-Übersicht & Industrie-Warnmarkierungen",
                    summary: "Die Cluster-Übersicht gliedert den gesamten Rechenverbund über drei große, klar getrennte Auswahl-Reiter und markiert sicherheitskritische Leistungs- und Speicherbereiche mit diagonalen gelb-schwarzen Warnstreifen.",
                    bullets: [
                        "Reiter 1 — Lokaler Cluster: Zeigt alle örtlichen Thunderbolt-3/4/5-(RDMA/JACCL)- und 10GbE-Rechner samt Rang 0, nutzbarem Speicherpool und aggregierter Bandbreite.",
                        "Reiter 2 — Internet-Cluster: Stellt entfernte WAN-Teilnehmer sowie verfügbare untergliederte regionale und lokale Teilverbünde (Subcluster) übersichtlich dar.",
                        "Reiter 3 — Lokal + Internet: Vereint den lokalen Thunderbolt-Kern und das globale WAN-Netzwerk in einer gemeinsamen gekoppelten Hybrid-Gesamtansicht.",
                        "Gelb-schwarze Warnstreifen (HazardStripesBar & IndustrialHazardBanner): Schräg gestrichelte 45°-Warnmarkierungen kennzeichnen kritische Rechen-, RDMA-, Modell-, WAN- und Forschungszonen in 6 Kernansichten."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nWarnstreifen-Komponenten: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Gemeinsamer Arbeitsspeicher & Schutzgrenze (iogpu.wired_limit_mb)",
                    summary: "Auf Apple Silicon teilen sich CPU und GPU denselben Speicher. Niemals darf 100 % des Arbeitsspeichers für KI-Modelle freigegeben werden.",
                    bullets: [
                        "Bis 24 GB RAM: Mindestens 4 GB bleiben für macOS und WindowServer frei (z. B. 16 GB → 12 GB nutzbar).",
                        "32 GB bis 64 GB RAM: 6 GB bleiben für das Betriebssystem geschützt (z. B. 36 GB → 30 GB nutzbar).",
                        "Ab 96 GB RAM (Ultra/Max): 8 GB bleiben für macOS geschützt (z. B. 128 GB → 120 GB nutzbar).",
                        "Vor dem Laden prüft SS-CCC den Gesamtbedarf (Modellgewichte + KV-Zwischenspeicher) gegen die nutzbare Summe aller Geräte."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Beispiel für 36-GB-Mac (30 GB nutzbar)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Netzwerk, Thunderbolt-Brücke (TB3/4/5) & RDMA (JACCL)",
                    summary: "SS-CCC trennt Steuerdaten (LAN/WLAN) und Modell-Aktivierungsdaten (Thunderbolt) sauber auf zwei Ebenen.",
                    bullets: [
                        "Steuer-Ebene (LAN/WLAN): Bonjour-Erkennung, API-Anfragen, Telemetrie und Zustandstausch.",
                        "Daten-Ebene (Thunderbolt 3/4/5): Punkt-zu-Punkt-Brücke im Netz 10.99.1.x mit real 30–37 Gbps (TB4) bzw. bis 90 Gbps (TB5 RDMA).",
                        "Schnelle GPU-Abstimmung: MLX_METAL_FAST_SYNCH=1 senkt die Wartezeit an Schichten-Grenzen von ~180 µs auf ~4 µs (45× schneller).",
                        "RDMA / JACCL: Ab Thunderbolt 5 nativ nutzbar; auf Thunderbolt 4 optional zuschaltbar."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # oder: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Gewichtetes Aufteilen, Modell-Laden & Multi-Modell-Betrieb",
                    summary: "Statt starrer Gleichverteilung weist SS-CCC jedem Mac genau den Schichten-Anteil zu, der seinem nutzbaren Speicher entspricht — und regelt exakt, wer lädt und wie viele Modelle parallel Platz finden.",
                    bullets: [
                        "Wer lädt das Modell? Immer Rang 0 (Leitrechner mit höchster Speicherbandbreite) koordiniert den Shard-Plan über POST /v1/cluster/plan; jeder Worker (Rang 1..N) lädt nur seinen zugewiesenen Schichten-Bereich.",
                        "Wie viele Modelle können gleichzeitig geladen werden? Beliebig viele (Multi-Modell-Residenz), solange Summe(Gewichte + KV-Cache) ≤ nutzbarer Verbundspeicher (z. B. 1× 70B–405B+ oder 2–4× 7B–32B parallel).",
                        "Schichten-Formel & KV-Verdichtung: Schichten_i = Gesamtschichten × (Nutzbar_i / Gesamt_Nutzbar); KV-Cache wahlweise in FP16 (~16k), 8-Bit (~32k) oder 4-Bit (~64k+ Kontext).",
                        "Gestückelte Vorbefüllung (--prefill-step-size 512) und SSD-KV-Auslagerung (oMLX) verhindern Arbeitsspeicher-Spitzen bei großen Quelltext-Projekten."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Aufbauanleitung: Lokaler Cluster & Hybrid Lokal + Internet",
                    summary: "Schritt-für-Schritt-Anleitung für die Einrichtung eines lokalen TB/RDMA-Clusters sowie dessen Kopplung mit einem globalen Internet-WAN-Verbund (Tailscale, WireGuard, ZeroTier oder libp2p QUIC).",
                    bullets: [
                        "Schritt 1 (Lokal): Thunderbolt-Brücke (setup_tb_network.sh) und Speicherschutz (setup_wired_limit.sh) auf jedem lokalen Mac einrichten; Rang 0 wird automatisch gewählt.",
                        "Schritt 2 (Gateway & Modell): Auf Rang 0 das FastAPI-Gateway (Port 8000) sowie oMLX/Ollama/llama.cpp starten und das Zielmodell im Modell-Studio laden.",
                        "Schritt 3 (Internet-WAN): Auf entfernten Macs ein verschlüsseltes Mesh (Tailscale/WireGuard) aktivieren und im Reiter Internet-Cluster mit Raum-ID & Einladungs-Token beitreten.",
                        "Schritt 4 (Hybrid-Kopplung & Weltrekord): Im Reiter Übersicht → Lokal + Internet oder Internet-Cluster auf „Lokal + Internet koppeln“ klicken — lokale TB-Inseln bilden den schnellen Tier-0-Kern, WAN-Knoten übernehmen Überhang-Schichten (64–256+ Knoten)."
                    ],
                    codeSample: "WebSocket-Chat-Relais: ws://127.0.0.1:8000/ws/wan-chat\nKopplung: Lokal (TB/RDMA Tier-0) + Internet-WAN -> Hybrid-Supercluster"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Live-Teilnehmer-Chat & Verbund-Audio-Party (Sprachchat)",
                    summary: "Direkt neben dem Text-Chat bietet SS-CCC eine vollwertige Audio-Party nach Konsolen-Vorbild (Xbox / PlayStation), zugeschnitten auf verteilte KI-Teams.",
                    bullets: [
                        "Echtzeit-Sprachübertragung: Nutzt AVAudioEngine (16 kHz PCM16, Opus-kompatibel) über den eigenen Relais-Endpunkt /ws/wan-audio.",
                        "Sprachmodi: Umschaltbar zwischen Push-to-Talk (Sprechtaste) und Open-Mic (Dauersprechen) sowie Mikrofon-Stummschaltung und Taub-Modus.",
                        "Teilnehmer-Anzeige: Zeigt aktive Sprecher mit Live-Pegelanzeige, verbundene Knoten-Rolle und Raum-Status in Echtzeit.",
                        "Minimaler Bandbreitenbedarf: Sprachkanäle benötigen unter 0,02 % eines typischen WAN-Uplinks und stören die Tensor-Übertragung nicht."
                    ],
                    codeSample: "WebSocket-Audio-Relais: ws://127.0.0.1:8000/ws/wan-audio\nAudio-Format: AVAudioEngine 16 kHz PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Forschungslabor (6 Reiter) & Verlaufsaufzeichnung",
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
                    title: "9. Laufzeit-Dienste: MLX, oMLX, Ollama & llama.cpp",
                    summary: "Im Modell-Studio lassen sich Modelle unmittelbar für den gewünschten örtlichen Dienst starten, live erkennen oder zwischen Formaten überführen.",
                    bullets: [
                        "oMLX (Port 8000): Nativer macOS-MLX-Dienst mit ausgelagertem SSD-KV-Zwischenspeicher sowie OpenAI- und Anthropic-Schnittstelle.",
                        "Ollama (Port 11434): Weit verbreiteter Dienst für örtliche GGUF-Modelle; vorhandene Modelle werden live eingelesen.",
                        "llama.cpp (Port 8080): Unmittelbarer GGUF-Dienst ohne Umwege über llama-server.",
                        "Live-Erkennung: SS-CCC fragt laufende Dienste automatisch ab und zeigt aktive sowie lokal heruntergeladene Modelle sofort an."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPorts: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. KI-Agenten (1-Klick) & Lokale API-Schnittstellen",
                    summary: "Alle Entwicklungswerkzeuge greifen über die örtliche Schnittstelle auf den gesamten Verbund zu — komplett ohne Cloud-Übertragung von Quelltext oder Dokumenten.",
                    bullets: [
                        "1-Klick-Einrichtung: Schreibt fertige Konfigurationsdateien für OpenCode, Hermes Agent und Google Antigravity direkt aus dem Reiter KI-Agenten.",
                        "Breite IDE-Kompatibilität: Funktioniert nahtlos mit Cursor, Continue, Open WebUI und Xcode Predictive / Chat.",
                        "OpenAI- & Anthropic-kompatibel: Unterstützt /v1/chat/completions, /v1/messages und /api/chat parallel.",
                        "API-Konsole: Integrierte Live-Konsole zum direkten Testen von Prompts, Latenz und Token-Durchsatz im Verbund."
                    ],
                    codeSample: "OpenAI-Endpunkt:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic-Endpunkt: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub-Updatefunktion & automatische CI-Versionskontrolle",
                    summary: "SS-CCC überwacht automatisch die aktuelle Programmversion auf GitHub und hält Quelltext- wie Release-Installationen bequem auf dem neuesten Stand.",
                    bullets: [
                        "Automatische Prüfung: Vergleicht beim Start sowie alle 30 Minuten (oder manuell per ⌘U bzw. Versions-Pill im Kopf) gegen version.json, GitHub Releases und den main-Commit-SHA.",
                        "UpdatePromptSheet: Zeigt bei neueren Versionen das Änderungsprotokoll sowie die aktuelle Commit-Differenz direkt in der App an.",
                        "1-Klick-Aktualisierung: Für Git-Installationen führt SS-CCC automatisch git pull + swift build + Neustart aus; für Paket-Releases öffnet sich der Browser-Download.",
                        "CI-Versionskontrolle: Jeder Push auf main startet scripts/bump_version.py --part patch --sync-git, synchronisiert version.json & ClusterModels.swift und setzt das Tag vX.Y.Z."
                    ],
                    codeSample: "Tastenkürzel: ⌘U (Update prüfen) | ⌘? (Handbuch öffnen)\nManifest: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Programmstart, Fehlerbehebung & 14-teilige Testsuite",
                    summary: "Ein einziger Befehl kompiliert die macOS-App und startet die Benutzeroberfläche; die globale Prüfsammlung sichert alle Funktionen mit 14 automatisierten Tests ab.",
                    bullets: [
                        "App starten: ./scripts/run_ssccc.sh baut das Swift-Paket im Release-/Debug-Modus und öffnet das SS-CCC-Fenster.",
                        "14/14 globale Tests: python3 -m unittest discover -s tests -v prüft Swift-Build, alle 8 Sprachen, 3-Reiter-Cluster-Übersicht, Warnstreifen, WAN, Forschungslabor und API-Endpunkte.",
                        "Typische Stolpersteine: Bei fehlender Thunderbolt-Verbindung ./scripts/setup_tb_network.sh erneut ausführen; bei Speicherwarnungen iogpu.wired_limit_mb prüfen.",
                        "Sprachumschaltung: Startet standardmäßig auf Englisch und lässt sich jederzeit live zwischen EN, DE, FR, ES, PT, RU, JA und ZH umschalten."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v   # Erwartet: Ran 14 tests ... OK"
                )
            ]

        case .en:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Universal Apple Silicon Clustering (M1–M12+)",
                    summary: "Any Mac with an Apple Silicon chip (M1 through M12+ — Base, Pro, Max, or Ultra) can join the cluster as an equal compute node: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, and Mac Pro.",
                    bullets: [
                        "Future-Proof Generation Parsing: Memory bandwidth, FP16 TFLOPS, and Thunderbolt generation are inferred automatically even for upcoming M7–M12+ chips.",
                        "Automatic Rank Assignment: The Mac with the highest memory bandwidth (e.g., Ultra or Max) automatically becomes Rank 0 (Coordinator).",
                        "Mixed Generations: Combine, for example, a MacBook Pro M2 Max with a Mac mini M4 and a Mac Studio M5 Max in one unified ring.",
                        "All Form Factors Supported: Desktop workstations (Mac Studio, Mac Pro, Mac mini, iMac) and laptops (MacBook Air/Pro) seamlessly share model layers."
                    ],
                    codeSample: "Rank 0 = highest memory bandwidth (GB/s) -> Coordinator & API entry\nRank 1..N = pipeline worker nodes in weighted layer pool"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-Tab Cluster Overview & Industrial Hazard Stripes",
                    summary: "The Cluster Overview organizes your entire compute fabric into three large, dedicated scope tabs and highlights critical compute, memory, and network boundaries with diagonal yellow-black industrial warning markings.",
                    bullets: [
                        "Tab 1 — Local Cluster: Displays all local Thunderbolt 3/4/5 (RDMA/JACCL) and 10GbE machines, Rank 0 coordinator, usable memory pool, and aggregate bandwidth.",
                        "Tab 2 — Internet Cluster: Visualizes remote WAN participants along with sub-grouped regional and local subclusters when available.",
                        "Tab 3 — Local + Internet: Unifies the local Thunderbolt island and global WAN swarm into a single coupled hybrid supercluster overview.",
                        "Yellow-Black Hazard Stripes (HazardStripesBar & IndustrialHazardBanner): 45° diagonal warning stripes mark high-voltage compute, RDMA, model, WAN, and lab zones across 6 core views."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nHazard Components: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Unified Memory Pool & OOM Safety (iogpu.wired_limit_mb)",
                    summary: "CPU and GPU share unified memory on Apple Silicon. Never allocate 100% of physical RAM to MLX workloads.",
                    bullets: [
                        "Up to 24 GB RAM: Keep at least 4 GB reserved for macOS and WindowServer (e.g., 16 GB -> 12 GB usable).",
                        "32 GB to 64 GB RAM: Reserve 6 GB for macOS (e.g., 36 GB -> 30 GB usable).",
                        "96 GB+ RAM (Ultra/Max): Reserve 8 GB for macOS (e.g., 128 GB -> 120 GB usable).",
                        "SS-CCC verifies combined model weights + KV cache reserve against the usable cluster pool before launch."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac -> 30 GB MLX limit\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Networking, Thunderbolt Bridge (TB3/4/5) & RDMA (JACCL)",
                    summary: "SS-CCC isolates control-plane discovery (LAN/Wi-Fi) from high-speed activation tensor transfers (Thunderbolt).",
                    bullets: [
                        "Control Plane (LAN/Wi-Fi): Bonjour discovery, API gateway, telemetry, and health checks.",
                        "Data Plane (Thunderbolt 3/4/5): Dedicated 10.99.1.x bridge delivering 30–37 Gbps (TB4) or up to 90 Gbps (TB5 RDMA).",
                        "Fast Metal Sync: MLX_METAL_FAST_SYNCH=1 cuts GPU/CPU fence overhead from ~180 µs to ~4 µs (45× faster).",
                        "RDMA / JACCL: Native on Thunderbolt 5; opt-in on Thunderbolt 4."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # or: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Weighted Sharding, Model Loading & Multi-Model Hosting",
                    summary: "Instead of equal splits that overload smaller Macs, SS-CCC assigns layers proportionally to each node's usable memory — and defines clearly who loads the model and how many models fit simultaneously.",
                    bullets: [
                        "Who loads the model? Always Rank 0 (the highest-bandwidth Mac) coordinates the shard manifest via POST /v1/cluster/plan; each worker (Rank 1..N) loads only its assigned layer range.",
                        "How many models can be loaded? Multiple models simultaneously (multi-model residency) as long as Sum(Weights + KV Cache) <= UsablePool (e.g., 1× 70B–405B+ frontier model OR 2–4× 7B–32B specialized models).",
                        "Weighted Layer Formula & KV Precision: Layers_i = TotalLayers × (UsableMemory_i / TotalUsableMemory); KV cache in FP16 (~16k), 8-Bit (~32k), or 4-Bit (~64k+ context).",
                        "Chunked Prefill (--prefill-step-size 512) and oMLX paged SSD KV-cache offloading prevent memory spikes on large repositories."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Setup Guide: Local Cluster & Hybrid Local + Internet WAN",
                    summary: "Step-by-step instructions to build a local TB/RDMA cluster and couple it with a global Internet WAN swarm over Tailscale, WireGuard, ZeroTier, or libp2p QUIC.",
                    bullets: [
                        "Step 1 (Local): Configure the Thunderbolt bridge (setup_tb_network.sh) and wired memory limit (setup_wired_limit.sh) on every local Mac; Rank 0 is elected automatically.",
                        "Step 2 (Gateway & Model): Start the FastAPI gateway (port 8000) and oMLX/Ollama/llama.cpp on Rank 0, then load your target model in Model Studio.",
                        "Step 3 (Internet WAN): Enable an encrypted mesh (Tailscale/WireGuard) on remote Macs and join via Room ID & invite token in the Internet Cluster view.",
                        "Step 4 (Hybrid Coupling & World-Record Mode): Click 'Couple Local + Internet' in Overview or Internet Cluster — local TB islands form the fast Tier-0 core while WAN peers handle overflow layers (64–256+ nodes)."
                    ],
                    codeSample: "WebSocket Chat Relay: ws://127.0.0.1:8000/ws/wan-chat\nCoupling: Local (TB/RDMA Tier-0) + Internet WAN -> Hybrid Supercluster"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Live Participant Chat & Cluster Audio-Party",
                    summary: "Right beside the text chat, SS-CCC includes a console-style Audio-Party (Xbox / PlayStation inspired) tailored for distributed AI cluster teams.",
                    bullets: [
                        "Low-Latency Voice: Powered by AVAudioEngine (16 kHz PCM16, Opus-ready) over the dedicated /ws/wan-audio relay.",
                        "Voice Modes: Switch between Push-to-Talk and Open-Mic, with instant Mute, Deafen, and live audio level meters.",
                        "Party Roster: Displays active speakers, connected node roles, and room status in real time.",
                        "Negligible Bandwidth: Voice streams use <0.02% of typical WAN uplinks so tensor transfers remain unaffected."
                    ],
                    codeSample: "WebSocket Audio Relay: ws://127.0.0.1:8000/ws/wan-audio\nAudio Format: AVAudioEngine 16 kHz PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Science & Roofline Lab (6 Tabs) & History Recording",
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
                    title: "9. Runtime Services: MLX, oMLX, Ollama & llama.cpp",
                    summary: "Launch models directly in your preferred local runtime or scan local Ollama/GGUF models into fast MLX.",
                    bullets: [
                        "oMLX (Port 8000): Native macOS MLX server with paged SSD KV-cache and OpenAI + Anthropic endpoints.",
                        "Ollama (Port 11434): Zero-config GGUF runner with live model discovery.",
                        "llama.cpp (Port 8080): Direct llama-server GGUF execution without wrappers.",
                        "Live Discovery: SS-CCC probes active local runtimes automatically and lists both running and downloaded models."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPorts: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI Agents (1-Click) & Local API Endpoints",
                    summary: "Point local coding agents and editors to your unified Apple Silicon cluster with zero cloud data leakage.",
                    bullets: [
                        "1-Click Config: Writes ready-to-use configs for OpenCode, Hermes Agent, and Google Antigravity directly from the AI Agents tab.",
                        "Broad IDE Compatibility: Works seamlessly with Cursor, Continue, Open WebUI, and Xcode.",
                        "OpenAI & Anthropic Compatible: Exposes /v1/chat/completions, /v1/messages, and /api/chat concurrently.",
                        "API Console: Built-in interactive console to test prompts, latency, and token throughput directly against the cluster."
                    ],
                    codeSample: "OpenAI Endpoint:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic Endpoint: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub Auto-Updater & CI Version Control",
                    summary: "SS-CCC automatically monitors GitHub for new releases and commits so both source checkouts and packaged apps stay up to date.",
                    bullets: [
                        "Automatic Polling: Checks version.json, GitHub Releases, and main commit SHA on launch and every 30 minutes (or manually via ⌘U / header version pill).",
                        "UpdatePromptSheet: Displays release notes, changelog, and commit delta directly inside the app.",
                        "1-Click Upgrade: Source installs run git pull + swift build + relaunch automatically; packaged builds open the GitHub Release download.",
                        "CI Version Enforcement: Every push to main runs scripts/bump_version.py --part patch --sync-git, syncs version.json & ClusterModels.swift, and tags vX.Y.Z."
                    ],
                    codeSample: "Shortcuts: ⌘U (Check Updates) | ⌘? (Open Manual)\nManifest: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Launch, Troubleshooting & 14-Test Verification Suite",
                    summary: "A single script compiles and opens the macOS app, while the global verification suite validates all components with 14 automated tests.",
                    bullets: [
                        "Launch App: ./scripts/run_ssccc.sh builds the Swift package and opens the SS-CCC desktop window.",
                        "14/14 Global Tests: python3 -m unittest discover -s tests -v verifies Swift build, all 8 languages, 3-tab Cluster Overview, hazard stripes, WAN, Science Lab, and APIs.",
                        "Troubleshooting: Re-run ./scripts/setup_tb_network.sh if the TB bridge is down; verify iogpu.wired_limit_mb on memory warnings.",
                        "8-Language UI: Defaults to English on launch and switches live between EN, DE, FR, ES, PT, RU, JA, and ZH."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v   # Expected: Ran 14 tests ... OK"
                )
            ]

        case .fr:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Tous les Mac à puce Apple M en grappe (M1 à M12+)",
                    summary: "Tout Mac équipé d'une puce Apple Silicon (M1 à M12+ — Standard, Pro, Max ou Ultra) peut rejoindre la grappe : Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio et Mac Pro.",
                    bullets: [
                        "Détection évolutive des générations : bande passante mémoire, TFLOPS FP16 et génération Thunderbolt sont déduits automatiquement jusqu'aux puces M7–M12+.",
                        "Attribution automatique du rang : le Mac offrant le plus haut débit mémoire (Ultra ou Max) devient automatiquement Rang 0 (coordinateur).",
                        "Générations mixtes : associez sans effort un MacBook Pro M2 Max, un Mac mini M4 et un Mac Studio M5 Max dans un même anneau.",
                        "Tous formats pris en charge : postes fixes (Mac Studio, Mac Pro, Mac mini, iMac) et portables (MacBook Air/Pro) partagent les couches."
                    ],
                    codeSample: "Rang 0 = débit mémoire maximal (Go/s) -> Coordinateur & entrée API\nRang 1..N = nœuds travailleurs dans le pool pondéré"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. Vue d'ensemble en 3 onglets & bandes de signalisation",
                    summary: "La vue d'ensemble organise tout votre supercalculateur en trois grands onglets de portée et signale les zones critiques par des bandes industrielles jaune et noir.",
                    bullets: [
                        "Onglet 1 — Grappe locale : affiche les Mac locaux Thunderbolt 3/4/5 (RDMA/JACCL) et 10GbE, le Rang 0, la mémoire utile et la bande passante agrégée.",
                        "Onglet 2 — Grappe Internet : présente les pairs WAN distants ainsi que les sous-grappes régionales et locales disponibles.",
                        "Onglet 3 — Local + Internet : réunit l'îlot Thunderbolt local et l'essaim WAN mondial dans une vue hybride couplée unifiée.",
                        "Bandes jaune-noir (HazardStripesBar & IndustrialHazardBanner) : des rayures obliques à 45° balisent les zones calcul, RDMA, modèle, WAN et labo sur 6 vues."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nComposants : Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Mémoire unifiée et garde de sécurité (iogpu.wired_limit_mb)",
                    summary: "CPU et GPU partagent la même mémoire unifiée sur Apple Silicon. N'allouez jamais 100 % de la RAM physique aux charges MLX.",
                    bullets: [
                        "Jusqu'à 24 Go de RAM : réservez au moins 4 Go pour macOS et WindowServer (ex. 16 Go -> 12 Go utiles).",
                        "De 32 à 64 Go de RAM : réservez 6 Go pour macOS (ex. 36 Go -> 30 Go utiles).",
                        "96 Go et plus (Ultra/Max) : réservez 8 Go pour macOS (ex. 128 Go -> 120 Go utiles).",
                        "SS-CCC vérifie le poids du modèle + la réserve KV par rapport à la somme utile avant le chargement."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Mac 36 Go -> 30 Go utiles\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Réseau, pont Thunderbolt (TB3/4/5) et RDMA (JACCL)",
                    summary: "SS-CCC sépare nettement le plan de contrôle (LAN/Wi-Fi) du plan de données tenseurs (Thunderbolt).",
                    bullets: [
                        "Plan de contrôle (LAN/Wi-Fi) : découverte Bonjour, passerelle API, télémétrie et supervision.",
                        "Plan de données (Thunderbolt 3/4/5) : pont dédié 10.99.1.x à 30–37 Gbps (TB4) ou jusqu'à 90 Gbps (TB5 RDMA).",
                        "Synchronisation Metal rapide : MLX_METAL_FAST_SYNCH=1 réduit la latence GPU/CPU de ~180 µs à ~4 µs (45× plus rapide).",
                        "RDMA / JACCL : natif sur Thunderbolt 5 ; activable en option sur Thunderbolt 4."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # ou : mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Répartition pondérée, chargement & multi-modèles",
                    summary: "Au lieu d'un découpage égalitaire, SS-CCC répartit les couches selon la mémoire utile de chaque Mac et précise qui charge le modèle et combien tiennent en mémoire.",
                    bullets: [
                        "Qui charge le modèle ? Toujours le Rang 0 (débit maximal) coordonne le plan via POST /v1/cluster/plan ; chaque travailleur (Rang 1..N) ne charge que sa tranche.",
                        "Combien de modèles en parallèle ? Autant que Somme(Poids + KV) ≤ Mémoire utile (ex. 1× 70B–405B+ ou 2–4× 7B–32B simultanés).",
                        "Formule & précision KV : Couches_i = Total × (Utile_i / Total_Utile) ; cache KV en FP16 (~16k), 8-bit (~32k) ou 4-bit (~64k+).",
                        "Le pré-remplissage fractionné (--prefill-step-size 512) et le déchargement KV SSD (oMLX) évitent les pics mémoire."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Guide d'installation : Grappe locale & Hybride Local + Internet",
                    summary: "Procédure pas à pas pour monter une grappe locale TB/RDMA et la coupler à un essaim Internet WAN via Tailscale, WireGuard, ZeroTier ou libp2p QUIC.",
                    bullets: [
                        "Étape 1 (Local) : exécutez setup_tb_network.sh et setup_wired_limit.sh sur chaque Mac local ; le Rang 0 est élu automatiquement.",
                        "Étape 2 (Passerelle & Modèle) : lancez FastAPI (port 8000) et oMLX/Ollama/llama.cpp sur le Rang 0, puis chargez le modèle dans Model Studio.",
                        "Étape 3 (Internet WAN) : activez un maillage chiffré (Tailscale/WireGuard) sur les Mac distants et rejoignez la salle via ID & jeton.",
                        "Étape 4 (Couplage hybride & Record mondial) : cliquez sur « Coupler local + Internet » — les îlots TB locaux forment le cœur Tier-0 et le WAN absorbe le surplus (64–256+ nœuds)."
                    ],
                    codeSample: "Relais Chat WebSocket : ws://127.0.0.1:8000/ws/wan-chat\nCouplage : Local (TB/RDMA Tier-0) + Internet WAN -> Supergrappe hybride"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Messagerie instantanée et salon vocal (Audio-Party)",
                    summary: "Juste à côté du chat texte, SS-CCC intègre un salon vocal inspiré des consoles (Xbox / PlayStation) pensé pour les équipes distribuées.",
                    bullets: [
                        "Voix temps réel : propulsée par AVAudioEngine (16 kHz PCM16) sur le relais dédié /ws/wan-audio.",
                        "Modes audio : basculez entre Appuyer-pour-parler (Push-to-Talk) et Micro ouvert, avec Muet et Sourdine instantanés.",
                        "Liste du groupe : affiche en direct les orateurs actifs, le rôle des nœuds et l'état de la salle.",
                        "Empreinte négligeable : le flux vocal consomme moins de 0,02 % du lien montant sans gêner les tenseurs."
                    ],
                    codeSample: "Relais Audio WebSocket : ws://127.0.0.1:8000/ws/wan-audio\nFormat : AVAudioEngine 16 kHz PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Laboratoire scientifique (6 onglets) et historique",
                    summary: "Analysez les grappes locales TB/RDMA, les essaims Internet-WAN et leur comparaison directe à travers six onglets spécialisés.",
                    bullets: [
                        "Onglets 1–2 (Roofline & WAN) : courbe log-log de Williams, TTFT/TPOT, bulles GPipe, compression Petals/SWARM, N=1..128 et DiLoCo vs DDP.",
                        "Onglets 3–4 (Mémoire & Énergie) : équation mémoire Transformer, TokenPowerBench (J/jeton, EDP), mix carbone régional (gCO₂/1M) et coût électrique vs cloud.",
                        "Onglet 5 (Essais & Export) : N=5/10/20 essais reproductibles avec p50/p95/p99, IC₉₅, Goodput SLO et export CSV, JSON, LaTeX (booktabs) & BibTeX 8 articles.",
                        "Onglet 6 (Historique) : enregistre automatiquement ou manuellement chaque position (débit, latence, énergie, WAN, mémoire) ou globalement avec graphique et CSV."
                    ],
                    codeSample: "Portées : Local (TB/RDMA) | Internet WAN | Comparaison (Local vs WAN)\nHistorique : Enregistrer position | Enregistrer global | Auto-enregistrement"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Moteurs locaux : MLX, oMLX, Ollama et llama.cpp",
                    summary: "Lancez vos modèles directement dans le moteur local souhaité ou détectez en direct vos modèles Ollama/GGUF.",
                    bullets: [
                        "oMLX (Port 8000) : serveur MLX natif macOS avec cache KV paginé sur SSD et endpoints OpenAI + Anthropic.",
                        "Ollama (Port 11434) : moteur GGUF sans configuration avec détection en direct.",
                        "llama.cpp (Port 8080) : exécution directe via llama-server sans surcouche.",
                        "Découverte en direct : SS-CCC interroge automatiquement les moteurs actifs et liste les modèles prêts."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPorts : oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. Agents IA (1 clic) et endpoints API locaux",
                    summary: "Connectez vos agents de programmation et IDE à votre grappe Apple Silicon unifiée sans aucune fuite vers le cloud.",
                    bullets: [
                        "Configuration en 1 clic : génère les fichiers de config pour OpenCode, Hermes Agent et Google Antigravity.",
                        "Compatibilité étendue : prêt pour Cursor, Continue, Open WebUI et Xcode.",
                        "Compatible OpenAI & Anthropic : expose /v1/chat/completions, /v1/messages et /api/chat simultanément.",
                        "Console API : console interactive intégrée pour tester invites, latence et débit directement."
                    ],
                    codeSample: "Endpoint OpenAI :    http://127.0.0.1:8000/v1/chat/completions\nEndpoint Anthropic : http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. Mises à jour GitHub et contrôle automatique CI",
                    summary: "SS-CCC surveille automatiquement GitHub pour maintenir à jour aussi bien les installations sources que les paquets compilés.",
                    bullets: [
                        "Vérification automatique : contrôle version.json, GitHub Releases et le SHA de main au démarrage et toutes les 30 min (ou via ⌘U).",
                        "UpdatePromptSheet : affiche les notes de version et la différence de commits directement dans l'application.",
                        "Mise à jour en 1 clic : exécute git pull + swift build + relance pour les sources, ou ouvre le téléchargement GitHub Release.",
                        "CI automatique : chaque push sur main exécute scripts/bump_version.py --part patch --sync-git et crée le tag vX.Y.Z."
                    ],
                    codeSample: "Raccourcis : ⌘U (Mises à jour) | ⌘? (Manuel)\nManifeste : version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Lancement, dépannage et suite de 14 tests",
                    summary: "Un seul script compile et ouvre l'application macOS, tandis que la suite globale valide l'ensemble via 14 tests automatisés.",
                    bullets: [
                        "Lancer l'app : ./scripts/run_ssccc.sh compile le paquet Swift et ouvre la fenêtre SS-CCC.",
                        "14/14 tests globaux : python3 -m unittest discover -s tests -v vérifie la compilation, les 8 langues, les 3 onglets, les bandes de signalisation, le WAN et les API.",
                        "Dépannage : relancez ./scripts/setup_tb_network.sh si le pont TB manque ; vérifiez iogpu.wired_limit_mb en cas d'alerte mémoire.",
                        "Interface 8 langues : démarre en anglais et bascule en direct entre EN, DE, FR, ES, PT, RU, JA et ZH."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v   # Attendu : Ran 14 tests ... OK"
                )
            ]

        case .es:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Todos los Mac con procesador M en conjunto (M1–M12+)",
                    summary: "Cualquier Mac con Apple Silicon (M1 a M12+ — Base, Pro, Max o Ultra) puede unirse al clúster en igualdad de condiciones: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio y Mac Pro.",
                    bullets: [
                        "Detección preparada para el futuro: ancho de banda, TFLOPS FP16 y generación Thunderbolt se deducen automáticamente hasta M7–M12+.",
                        "Asignación automática de rango: el Mac con mayor ancho de banda de memoria (Ultra o Max) asume el Rango 0 (coordinador).",
                        "Generaciones mixtas: combina sin problemas un MacBook Pro M2 Max con un Mac mini M4 y un Mac Studio M5 Max.",
                        "Todos los formatos: equipos de escritorio y portátiles comparten capas del modelo de forma transparente."
                    ],
                    codeSample: "Rango 0 = mayor ancho de banda (GB/s) -> Coordinador y puerta API\nRango 1..N = nodos trabajadores en reparto ponderado"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. Resumen en 3 pestañas y franjas de advertencia",
                    summary: "El resumen del clúster organiza todo tu sistema en tres grandes pestañas y resalta las zonas críticas de cómputo, memoria y red con franjas industriales amarillo-negro.",
                    bullets: [
                        "Pestaña 1 — Clúster local: muestra todos los Mac locales Thunderbolt 3/4/5 (RDMA/JACCL) y 10GbE, el Rango 0, la memoria útil y el ancho de banda agregado.",
                        "Pestaña 2 — Clúster de Internet: visualiza los nodos WAN remotos junto con subclústeres regionales y locales cuando están disponibles.",
                        "Pestaña 3 — Local + Internet: une la isla Thunderbolt local y el enjambre WAN global en una única vista híbrida acoplada.",
                        "Franjas amarillo-negro (HazardStripesBar y IndustrialHazardBanner): líneas diagonales a 45° señalan zonas de alto rendimiento en 6 vistas clave."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nComponentes: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Memoria unificada y límite seguro (iogpu.wired_limit_mb)",
                    summary: "CPU y GPU comparten memoria unificada en Apple Silicon. Nunca asignes el 100 % de la RAM física a cargas MLX.",
                    bullets: [
                        "Hasta 24 GB de RAM: reserva al menos 4 GB para macOS y WindowServer (ej. 16 GB -> 12 GB útiles).",
                        "De 32 GB a 64 GB de RAM: reserva 6 GB para macOS (ej. 36 GB -> 30 GB útiles).",
                        "96 GB o más (Ultra/Max): reserva 8 GB para macOS (ej. 128 GB -> 120 GB útiles).",
                        "SS-CCC valida los pesos del modelo + reserva KV frente al total útil antes de cargar."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Mac de 36 GB -> 30 GB útiles\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Red, puente Thunderbolt (TB3/4/5) y RDMA (JACCL)",
                    summary: "SS-CCC separa limpiamente el plano de control (LAN/Wi-Fi) del plano de datos de tensores (Thunderbolt).",
                    bullets: [
                        "Plano de control (LAN/Wi-Fi): descubrimiento Bonjour, pasarela API, telemetría y estado.",
                        "Plano de datos (Thunderbolt 3/4/5): puente dedicado 10.99.1.x de 30–37 Gbps (TB4) o hasta 90 Gbps (TB5 RDMA).",
                        "Sincronización Metal rápida: MLX_METAL_FAST_SYNCH=1 reduce la espera GPU/CPU de ~180 µs a ~4 µs (45× más rápido).",
                        "RDMA / JACCL: nativo en Thunderbolt 5; opcional en Thunderbolt 4."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # o: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Reparto ponderado, carga del modelo y multimodelo",
                    summary: "En lugar de dividir por igual, SS-CCC asigna capas según la memoria útil de cada Mac y define quién carga el modelo y cuántos caben a la vez.",
                    bullets: [
                        "¿Quién carga el modelo? Siempre el Rango 0 (mayor ancho de banda) coordina el plan vía POST /v1/cluster/plan; cada trabajador (Rango 1..N) carga solo sus capas.",
                        "¿Cuántos modelos caben a la vez? Tantos como Suma(Pesos + KV) ≤ Memoria útil (ej. 1× 70B–405B+ o 2–4× 7B–32B simultáneos).",
                        "Fórmula y precisión KV: Capas_i = Total × (Útil_i / Total_Útil); caché KV en FP16 (~16k), 8-bit (~32k) o 4-bit (~64k+).",
                        "El prellenado por bloques (--prefill-step-size 512) y la descarga KV en SSD (oMLX) evitan picos de memoria."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Guía de configuración: Clúster local e híbrido Local + Internet",
                    summary: "Pasos exactos para montar un clúster local TB/RDMA y acoplarlo a un enjambre global por Internet mediante Tailscale, WireGuard, ZeroTier o libp2p QUIC.",
                    bullets: [
                        "Paso 1 (Local): ejecuta setup_tb_network.sh y setup_wired_limit.sh en cada Mac local; el Rango 0 se elige automáticamente.",
                        "Paso 2 (Pasarela y modelo): inicia FastAPI (puerto 8000) y oMLX/Ollama/llama.cpp en el Rango 0 y carga el modelo en Model Studio.",
                        "Paso 3 (Internet WAN): activa una malla cifrada (Tailscale/WireGuard) en los Mac remotos y únete con ID de sala y token.",
                        "Paso 4 (Acoplamiento híbrido y récord): pulsa «Acoplar local + Internet» — las islas TB locales forman el núcleo Tier-0 y el WAN asume capas extra (64–256+ nodos)."
                    ],
                    codeSample: "Relé Chat WebSocket: ws://127.0.0.1:8000/ws/wan-chat\nAcoplamiento: Local (TB/RDMA Tier-0) + Internet WAN -> Superclúster híbrido"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Chat en directo y sala de audio (Audio-Party)",
                    summary: "Junto al chat de texto, SS-CCC incluye una sala de voz estilo consola (Xbox / PlayStation) pensada para equipos distribuidos.",
                    bullets: [
                        "Voz de baja latencia: basada en AVAudioEngine (16 kHz PCM16) sobre el relé /ws/wan-audio.",
                        "Modos de voz: alterna entre Pulsar-para-hablar (Push-to-Talk) y Micrófono abierto, con Silenciar y Ensordecer.",
                        "Lista de sala: muestra en tiempo real hablantes activos, rol de cada nodo y estado.",
                        "Consumo mínimo: usa menos del 0,02 % del enlace ascendente sin afectar a los tensores."
                    ],
                    codeSample: "Relé Audio WebSocket: ws://127.0.0.1:8000/ws/wan-audio\nFormato: AVAudioEngine 16 kHz PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Laboratorio científico (6 pestañas) e historial",
                    summary: "Analiza clústeres locales TB/RDMA, enjambres Internet-WAN y comparativas directas en seis pestañas especializadas.",
                    bullets: [
                        "Pestañas 1–2 (Roofline y WAN): curva log-log de Williams, TTFT/TPOT, burbujas GPipe, compresión Petals/SWARM, N=1..128 y DiLoCo vs DDP.",
                        "Pestañas 3–4 (Memoria y energía): ecuación de memoria Transformer, TokenPowerBench (J/token, EDP), carbono regional (gCO₂/1M) y coste eléctrico vs nube.",
                        "Pestaña 5 (Ensayos y exportación): N=5/10/20 ensayos con p50/p95/p99, IC₉₅, Goodput SLO y exportación CSV, JSON, LaTeX (booktabs) y BibTeX de 8 artículos.",
                        "Pestaña 6 (Historial): graba instantáneas automática o manualmente por posición individual o de forma global con gráfico y exportación CSV."
                    ],
                    codeSample: "Ámbitos: Local (TB/RDMA) | Internet WAN | Comparación (Local vs WAN)\nHistorial: Grabar posición | Grabar global | Autograbación"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Motores locales: MLX, oMLX, Ollama y llama.cpp",
                    summary: "Inicia modelos directamente en el motor local que prefieras o descubre en vivo tus modelos Ollama y GGUF.",
                    bullets: [
                        "oMLX (Puerto 8000): servidor MLX nativo para macOS con caché KV paginada en SSD y endpoints OpenAI + Anthropic.",
                        "Ollama (Puerto 11434): ejecutor GGUF sin configuración con detección en directo.",
                        "llama.cpp (Puerto 8080): ejecución directa de llama-server sin intermediarios.",
                        "Detección automática: SS-CCC consulta los motores locales activos y lista los modelos disponibles."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPuertos: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. Agentes IA (1 clic) y endpoints API locales",
                    summary: "Conecta tus agentes de código y editores al clúster Apple Silicon unificado sin enviar datos a la nube.",
                    bullets: [
                        "Configuración en 1 clic: genera archivos para OpenCode, Hermes Agent y Google Antigravity.",
                        "Amplia compatibilidad: listo para Cursor, Continue, Open WebUI y Xcode.",
                        "Compatible con OpenAI y Anthropic: expone /v1/chat/completions, /v1/messages y /api/chat a la vez.",
                        "Consola API: consola interactiva integrada para probar prompts, latencia y rendimiento."
                    ],
                    codeSample: "Endpoint OpenAI:    http://127.0.0.1:8000/v1/chat/completions\nEndpoint Anthropic: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. Actualizador GitHub y control automático CI",
                    summary: "SS-CCC comprueba GitHub automáticamente para mantener al día tanto instalaciones desde código fuente como paquetes compilados.",
                    bullets: [
                        "Comprobación automática: verifica version.json, GitHub Releases y el SHA de main al iniciar y cada 30 min (o con ⌘U).",
                        "UpdatePromptSheet: muestra notas de la versión y diferencia de commits dentro de la app.",
                        "Actualización en 1 clic: ejecuta git pull + swift build + reinicio en instalaciones fuente, o descarga desde GitHub Releases.",
                        "Control CI: cada push a main ejecuta scripts/bump_version.py --part patch --sync-git y etiqueta vX.Y.Z."
                    ],
                    codeSample: "Atajos: ⌘U (Buscar actualizaciones) | ⌘? (Abrir manual)\nManifiesto: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Inicio, solución de problemas y suite de 14 pruebas",
                    summary: "Un único comando compila y abre la app de macOS, mientras la suite global valida todo el sistema con 14 pruebas automatizadas.",
                    bullets: [
                        "Iniciar app: ./scripts/run_ssccc.sh compila el paquete Swift y abre la ventana de SS-CCC.",
                        "14/14 pruebas globales: python3 -m unittest discover -s tests -v valida compilación, 8 idiomas, 3 pestañas, franjas de advertencia, WAN y APIs.",
                        "Solución de problemas: vuelve a ejecutar ./scripts/setup_tb_network.sh si falta el puente TB; revisa iogpu.wired_limit_mb ante avisos de memoria.",
                        "Interfaz en 8 idiomas: inicia en inglés y cambia en vivo entre EN, DE, FR, ES, PT, RU, JA y ZH."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v   # Esperado: Ran 14 tests ... OK"
                )
            ]

        case .pt:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Todos os Mac com processador M em conjunto (M1–M12+)",
                    summary: "Qualquer Mac com Apple Silicon (M1 a M12+ — Base, Pro, Max ou Ultra) pode integrar o cluster em igualdade de condições: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio e Mac Pro.",
                    bullets: [
                        "Deteção preparada para o futuro: largura de banda, TFLOPS FP16 e geração Thunderbolt são inferidos automaticamente até M7–M12+.",
                        "Atribuição automática de nível: o Mac com maior largura de banda de memória (Ultra ou Max) assume o Nível 0 (coordenador).",
                        "Gerações mistas: combine sem esforço um MacBook Pro M2 Max com um Mac mini M4 e um Mac Studio M5 Max.",
                        "Todos os formatos: secretárias e portáteis partilham camadas de modelo de forma transparente."
                    ],
                    codeSample: "Nível 0 = maior largura de banda (GB/s) -> Coordenador e entrada API\nNível 1..N = nós trabalhadores na partilha ponderada"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. Visão geral em 3 separadores e faixas de aviso",
                    summary: "A visão geral organiza todo o sistema em três grandes separadores e destaca zonas críticas de computação, memória e rede com faixas industriais amarelo-preto.",
                    bullets: [
                        "Separador 1 — Cluster local: mostra todos os Mac locais Thunderbolt 3/4/5 (RDMA/JACCL) e 10GbE, Nível 0, memória útil e largura de banda agregada.",
                        "Separador 2 — Cluster da Internet: apresenta nós WAN remotos e subclusters regionais e locais disponíveis.",
                        "Separador 3 — Local + Internet: reúne a ilha Thunderbolt local e o enxame WAN global numa vista híbrida acoplada.",
                        "Faixas amarelo-preto (HazardStripesBar e IndustrialHazardBanner): listas diagonais a 45° assinalam zonas críticas em 6 vistas principais."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nComponentes: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Memória unificada e limite seguro (iogpu.wired_limit_mb)",
                    summary: "CPU e GPU partilham memória unificada no Apple Silicon. Nunca atribua 100% da RAM física a cargas MLX.",
                    bullets: [
                        "Até 24 GB de RAM: reserve pelo menos 4 GB para o macOS e WindowServer (ex.: 16 GB -> 12 GB úteis).",
                        "De 32 GB a 64 GB de RAM: reserve 6 GB para o macOS (ex.: 36 GB -> 30 GB úteis).",
                        "96 GB ou mais (Ultra/Max): reserve 8 GB para o macOS (ex.: 128 GB -> 120 GB úteis).",
                        "O SS-CCC valida pesos do modelo + reserva KV face ao total útil antes de carregar."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Mac de 36 GB -> 30 GB úteis\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Rede, ponte Thunderbolt (TB3/4/5) e RDMA (JACCL)",
                    summary: "O SS-CCC separa claramente o plano de controlo (LAN/Wi-Fi) do plano de dados de tensores (Thunderbolt).",
                    bullets: [
                        "Plano de controlo (LAN/Wi-Fi): descoberta Bonjour, gateway API, telemetria e estado.",
                        "Plano de dados (Thunderbolt 3/4/5): ponte dedicada 10.99.1.x com 30–37 Gbps (TB4) ou até 90 Gbps (TB5 RDMA).",
                        "Sincronização Metal rápida: MLX_METAL_FAST_SYNCH=1 reduz a latência GPU/CPU de ~180 µs para ~4 µs (45× mais rápido).",
                        "RDMA / JACCL: nativo em Thunderbolt 5; opcional em Thunderbolt 4."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # ou: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Repartição ponderada, carregamento e multimodelo",
                    summary: "Em vez de divisões iguais, o SS-CCC atribui camadas conforme a memória útil de cada Mac e define quem carrega o modelo e quantos cabem em simultâneo.",
                    bullets: [
                        "Quem carrega o modelo? Sempre o Nível 0 (maior largura de banda) coordena o plano via POST /v1/cluster/plan; cada trabalhador (Nível 1..N) carrega apenas a sua fatia.",
                        "Quantos modelos cabem ao mesmo tempo? Tantos quanto Soma(Pesos + KV) ≤ Memória útil (ex.: 1× 70B–405B+ ou 2–4× 7B–32B simultâneos).",
                        "Fórmula e precisão KV: Camadas_i = Total × (Útil_i / Total_Útil); cache KV em FP16 (~16k), 8-bit (~32k) ou 4-bit (~64k+).",
                        "O pré-preenchimento em blocos (--prefill-step-size 512) e a descarga KV em SSD (oMLX) evitam picos de memória."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Guia de configuração: Cluster local e híbrido Local + Internet",
                    summary: "Passos exatos para montar um cluster local TB/RDMA e acoplá-lo a um enxame global na Internet via Tailscale, WireGuard, ZeroTier ou libp2p QUIC.",
                    bullets: [
                        "Passo 1 (Local): execute setup_tb_network.sh e setup_wired_limit.sh em cada Mac local; o Nível 0 é eleito automaticamente.",
                        "Passo 2 (Gateway e modelo): inicie o FastAPI (porta 8000) e oMLX/Ollama/llama.cpp no Nível 0 e carregue o modelo no Model Studio.",
                        "Passo 3 (Internet WAN): ative uma malha cifrada (Tailscale/WireGuard) nos Mac remotos e entre com ID da sala e token.",
                        "Passo 4 (Acoplamento híbrido e recorde): clique em «Ligar local + Internet» — as ilhas TB locais formam o núcleo Tier-0 e o WAN absorve camadas extra (64–256+ nós)."
                    ],
                    codeSample: "Retransmissor Chat WebSocket: ws://127.0.0.1:8000/ws/wan-chat\nAcoplamento: Local (TB/RDMA Tier-0) + Internet WAN -> Supercluster híbrido"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Chat em direto e sala de áudio (Audio-Party)",
                    summary: "Ao lado do chat de texto, o SS-CCC inclui uma sala de voz estilo consola (Xbox / PlayStation) para equipas distribuídas.",
                    bullets: [
                        "Voz de baixa latência: alimentada por AVAudioEngine (16 kHz PCM16) sobre o retransmissor /ws/wan-audio.",
                        "Modos de voz: alterne entre Premir-para-falar (Push-to-Talk) e Microfone aberto, com Silenciar e Ensurdecer.",
                        "Lista da sala: mostra em tempo real oradores ativos, função de cada nó e estado.",
                        "Consumo mínimo: utiliza menos de 0,02% da ligação de envio sem afetar os tensores."
                    ],
                    codeSample: "Retransmissor Áudio WebSocket: ws://127.0.0.1:8000/ws/wan-audio\nFormato: AVAudioEngine 16 kHz PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Laboratório científico (6 separadores) e histórico",
                    summary: "Analise clusters locais TB/RDMA, enxames Internet-WAN e comparações diretas em seis separadores especializados.",
                    bullets: [
                        "Separadores 1–2 (Roofline e WAN): curva log-log de Williams, TTFT/TPOT, bolhas GPipe, compressão Petals/SWARM, N=1..128 e DiLoCo vs DDP.",
                        "Separadores 3–4 (Memória e energia): equação de memória Transformer, TokenPowerBench (J/token, EDP), carbono regional (gCO₂/1M) e custo elétrico vs nuvem.",
                        "Separador 5 (Ensaios e exportação): N=5/10/20 ensaios com p50/p95/p99, IC₉₅, Goodput SLO e exportação CSV, JSON, LaTeX (booktabs) e BibTeX de 8 artigos.",
                        "Separador 6 (Histórico): regista instantâneos automática ou manualmente por posição individual ou global com gráfico e exportação CSV."
                    ],
                    codeSample: "Âmbitos: Local (TB/RDMA) | Internet WAN | Comparação (Local vs WAN)\nHistórico: Registar posição | Registar global | Autorregisto"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Motores locais: MLX, oMLX, Ollama e llama.cpp",
                    summary: "Inicie modelos diretamente no motor local pretendido ou detete em tempo real os seus modelos Ollama e GGUF.",
                    bullets: [
                        "oMLX (Porta 8000): servidor MLX nativo para macOS com cache KV paginada em SSD e endpoints OpenAI + Anthropic.",
                        "Ollama (Porta 11434): executor GGUF sem configuração com descoberta em direto.",
                        "llama.cpp (Porta 8080): execução direta via llama-server sem camadas extra.",
                        "Descoberta automática: o SS-CCC sonda os motores ativos e lista os modelos disponíveis."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPortas: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. Agentes IA (1 clique) e endpoints API locais",
                    summary: "Ligue os seus agentes de programação e editores ao cluster Apple Silicon unificado sem enviar dados para a nuvem.",
                    bullets: [
                        "Configuração num clique: gera ficheiros para OpenCode, Hermes Agent e Google Antigravity.",
                        "Compatibilidade alargada: pronto para Cursor, Continue, Open WebUI e Xcode.",
                        "Compatível com OpenAI e Anthropic: expõe /v1/chat/completions, /v1/messages e /api/chat em simultâneo.",
                        "Consola API: consola interativa integrada para testar prompts, latência e débito."
                    ],
                    codeSample: "Endpoint OpenAI:    http://127.0.0.1:8000/v1/chat/completions\nEndpoint Anthropic: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. Atualizador GitHub e controlo automático CI",
                    summary: "O SS-CCC monitoriza automaticamente o GitHub para manter atualizadas tanto instalações a partir do código-fonte como pacotes compilados.",
                    bullets: [
                        "Verificação automática: verifica version.json, GitHub Releases e o SHA de main ao iniciar e a cada 30 min (ou com ⌘U).",
                        "UpdatePromptSheet: apresenta notas de versão e diferença de commits diretamente na app.",
                        "Atualização num clique: executa git pull + swift build + reinício em instalações fonte, ou transferência via GitHub Releases.",
                        "Controlo CI: cada push para main executa scripts/bump_version.py --part patch --sync-git e cria a tag vX.Y.Z."
                    ],
                    codeSample: "Atalhos: ⌘U (Procurar atualizações) | ⌘? (Abrir manual)\nManifesto: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Arranque, resolução de problemas e 14 testes",
                    summary: "Um único comando compila e abre a app macOS, enquanto o conjunto global valida todo o sistema com 14 testes automatizados.",
                    bullets: [
                        "Iniciar app: ./scripts/run_ssccc.sh compila o pacote Swift e abre a janela do SS-CCC.",
                        "14/14 testes globais: python3 -m unittest discover -s tests -v verifica compilação, 8 idiomas, 3 separadores, faixas de aviso, WAN e APIs.",
                        "Resolução de problemas: volte a executar ./scripts/setup_tb_network.sh se faltar a ponte TB; verifique iogpu.wired_limit_mb em avisos de memória.",
                        "Interface em 8 idiomas: arranca em inglês e alterna ao vivo entre EN, DE, FR, ES, PT, RU, JA e ZH."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v   # Esperado: Ran 14 tests ... OK"
                )
            ]

        case .ru:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Универсальная кластеризация Apple Silicon (M1–M12+)",
                    summary: "Любой Mac на базе Apple Silicon (M1–M12+ — Base, Pro, Max или Ultra) может войти в единый кластер на равных правах: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio и Mac Pro.",
                    bullets: [
                        "Перспективный парсер поколений: пропускная способность памяти, FP16 TFLOPS и поколение Thunderbolt определяются автоматически вплоть до будущих M7–M12+.",
                        "Автоматический выбор ранга: Mac с максимальной ПСП памяти (Ultra или Max) автоматически становится Rank 0 (координатором).",
                        "Смешанные поколения: легко объединяйте MacBook Pro M2 Max, Mac mini M4 и Mac Studio M5 Max в одном кольце.",
                        "Все форм-факторы: настольные станции и ноутбуки равномерно делят слои нейросети."
                    ],
                    codeSample: "Rank 0 = максимальная ПСП памяти (ГБ/с) -> Координатор и API-шлюз\nRank 1..N = рабочие узлы во взвешенном пуле"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-вкладочный обзор кластера и промышленные полосы",
                    summary: "Обзор кластера разделяет всю инфраструктуру на три крупные вкладки и выделяет критические зоны вычислений, памяти и сети жёлто-чёрными диагональными полосами.",
                    bullets: [
                        "Вкладка 1 — Локальный кластер: показывает локальные узлы Thunderbolt 3/4/5 (RDMA/JACCL) и 10GbE, Rank 0, доступную память и суммарную ПСП.",
                        "Вкладка 2 — Интернет-кластер: отображает удалённых WAN-участников, а также региональные и локальные подкластеры.",
                        "Вкладка 3 — Локально + Интернет: объединяет локальный TB-остров и глобальный WAN-рой в единый гибридный вид.",
                        "Жёлто-чёрные полосы (HazardStripesBar и IndustrialHazardBanner): 45° маркировка на 6 ключевых экранах предупреждает о нагрузке и границах памяти."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nКомпоненты: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Единая память и защита от OOM (iogpu.wired_limit_mb)",
                    summary: "CPU и GPU на Apple Silicon делят общую память. Никогда не отдавайте 100% физической ОЗУ под задачи MLX.",
                    bullets: [
                        "До 24 ГБ ОЗУ: оставляйте минимум 4 ГБ для macOS и WindowServer (напр., 16 ГБ -> 12 ГБ доступно).",
                        "От 32 до 64 ГБ ОЗУ: резервируйте 6 ГБ для macOS (напр., 36 ГБ -> 30 ГБ доступно).",
                        "От 96 ГБ (Ultra/Max): резервируйте 8 ГБ для macOS (напр., 128 ГБ -> 120 ГБ доступно).",
                        "SS-CCC проверяет сумму весов модели и KV-кэша относительно доступного пула перед запуском."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Mac 36 ГБ -> 30 ГБ для MLX\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Сеть, мост Thunderbolt (TB3/4/5) и RDMA (JACCL)",
                    summary: "SS-CCC чётко изолирует плоскость управления (LAN/Wi-Fi) от высокоскоростной передачи тензоров (Thunderbolt).",
                    bullets: [
                        "Плоскость управления (LAN/Wi-Fi): обнаружение Bonjour, API-шлюз, телеметрия и проверки состояния.",
                        "Плоскость данных (Thunderbolt 3/4/5): выделенный мост 10.99.1.x со скоростью 30–37 Гбит/с (TB4) и до 90 Гбит/с (TB5 RDMA).",
                        "Быстрая синхронизация Metal: MLX_METAL_FAST_SYNCH=1 сокращает задержку GPU/CPU с ~180 мкс до ~4 мкс (в 45× быстрее).",
                        "RDMA / JACCL: нативно на Thunderbolt 5; опционально на Thunderbolt 4."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # или: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Взвешенный шардинг, загрузка моделей и мультимодельность",
                    summary: "Вместо равного деления SS-CCC распределяет слои пропорционально доступной памяти и строго определяет, кто загружает модель и сколько моделей помещается.",
                    bullets: [
                        "Кто загружает модель? Всегда Rank 0 (макс. ПСП) координирует план через POST /v1/cluster/plan; каждый воркер (Rank 1..N) подгружает только свои слои.",
                        "Сколько моделей можно загрузить? Несколько одновременно, пока Сумма(Веса + KV) ≤ Доступный пул (напр., 1× 70B–405B+ или 2–4× 7B–32B).",
                        "Формула и KV-квантование: Layers_i = Total × (Usable_i / TotalUsable); KV-кэш в FP16 (~16k), 8-bit (~32k) или 4-bit (~64k+).",
                        "Порционный prefill (--prefill-step-size 512) и выгрузка KV на SSD (oMLX) исключают пики памяти."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Инструкция: Локальный кластер и гибрид Локально + Интернет",
                    summary: "Пошаговое руководство по развёртыванию локального TB/RDMA-кластера и его связке с глобальным WAN-роем через Tailscale, WireGuard, ZeroTier или libp2p QUIC.",
                    bullets: [
                        "Шаг 1 (Локально): выполните setup_tb_network.sh и setup_wired_limit.sh на каждом локальном Mac; Rank 0 выбирается автоматически.",
                        "Шаг 2 (Шлюз и модель): запустите FastAPI (порт 8000) и oMLX/Ollama/llama.cpp на Rank 0, затем загрузите модель в Model Studio.",
                        "Шаг 3 (Интернет WAN): включите шифрованную сеть (Tailscale/WireGuard) на удалённых Mac и подключитесь по Room ID и токену.",
                        "Шаг 4 (Гибридная связка и рекорд): нажмите «Связать Локально + Интернет» — локальные TB-острова станут ядром Tier-0, а WAN возьмёт остаток слоёв (64–256+ узлов)."
                    ],
                    codeSample: "WebSocket-чат: ws://127.0.0.1:8000/ws/wan-chat\nСвязка: Локальный (TB/RDMA Tier-0) + Интернет WAN -> Гибридный суперкластер"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Живой чат участников и кластерная Audio-Party",
                    summary: "Рядом с текстовым чатом SS-CCC предлагает полноценную голосовую комнату в стиле консолей (Xbox / PlayStation) для распределённых команд.",
                    bullets: [
                        "Голос с малой задержкой: работает через AVAudioEngine (16 кГц PCM16) по выделенному ретранслятору /ws/wan-audio.",
                        "Режимы речи: переключение Push-to-Talk и Open-Mic, а также мгновенные Mute и Deafen.",
                        "Состав комнаты: в реальном времени показывает активных спикеров, роль каждого узла и статус.",
                        "Минимальный трафик: занимает менее 0,02% аплинка WAN, не мешая передаче тензоров."
                    ],
                    codeSample: "WebSocket-аудио: ws://127.0.0.1:8000/ws/wan-audio\nФормат: AVAudioEngine 16 кГц PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Научная лаборатория (6 вкладок) и запись истории",
                    summary: "Исследуйте локальные TB/RDMA-кластеры, глобальные WAN-рои и их прямое сравнение на шести специализированных вкладках.",
                    bullets: [
                        "Вкладки 1–2 (Roofline и WAN): логарифмическая Roofline Уильямса, TTFT/TPOT, пузыри GPipe, сжатие Petals/SWARM, N=1..128 и DiLoCo vs DDP.",
                        "Вкладки 3–4 (Память и энергия): уравнение памяти Transformer, TokenPowerBench (Дж/ток, EDP), углеродный след (гCO₂/1M) и TCO vs облако.",
                        "Вкладка 5 (Серии и экспорт): N=5/10/20 запусков с p50/p95/p99, CI₉₅, Goodput SLO и экспортом CSV, JSON, LaTeX (booktabs) и BibTeX (8 статей).",
                        "Вкладка 6 (Запись истории): фиксирует замеры автоматически или вручную по отдельной позиции или глобально с графиком и CSV-экспортом."
                    ],
                    codeSample: "Режимы: Локально (TB/RDMA) | Интернет WAN | Сравнение\nИстория: Запись позиции | Глобальная запись | Автозапись"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Среды выполнения: MLX, oMLX, Ollama и llama.cpp",
                    summary: "Запускайте модели напрямую в нужном локальном бэкенде или автоматически обнаруживайте модели Ollama/GGUF.",
                    bullets: [
                        "oMLX (Порт 8000): нативный MLX-сервер macOS с выгрузкой KV на SSD и эндпоинтами OpenAI + Anthropic.",
                        "Ollama (Порт 11434): GGUF-движок без сложной настройки с живым поиском моделей.",
                        "llama.cpp (Порт 8080): прямой запуск llama-server без прослоек.",
                        "Автообнаружение: SS-CCC опрашивает активные среды и сразу показывает готовые модели."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nПорты: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. ИИ-агенты (1 клик) и локальные API-эндпоинты",
                    summary: "Подключайте локальных ИИ-агентов и IDE к вашему кластеру Apple Silicon без утечки данных в облако.",
                    bullets: [
                        "Настройка в 1 клик: создаёт готовые конфиги для OpenCode, Hermes Agent и Google Antigravity.",
                        "Широкая совместимость: работает с Cursor, Continue, Open WebUI и Xcode.",
                        "OpenAI и Anthropic API: одновременно обслуживает /v1/chat/completions, /v1/messages и /api/chat.",
                        "API-консоль: встроенная консоль для мгновенной проверки промптов, задержки и скорости генерации."
                    ],
                    codeSample: "OpenAI Endpoint:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic Endpoint: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. Автообновление через GitHub и контроль версий CI",
                    summary: "SS-CCC автоматически отслеживает релизы и коммиты на GitHub, поддерживая актуальность как исходников, так и сборок.",
                    bullets: [
                        "Автоматическая проверка: сверяет version.json, GitHub Releases и SHA ветки main при запуске и каждые 30 минут (или ⌘U).",
                        "UpdatePromptSheet: показывает список изменений и разницу коммитов прямо в приложении.",
                        "Обновление в 1 клик: для исходников запускает git pull + swift build + перезапуск; для релизов открывает загрузку.",
                        "CI-контроль: каждый push в main запускает scripts/bump_version.py --part patch --sync-git и ставит тег vX.Y.Z."
                    ],
                    codeSample: "Клавиши: ⌘U (Проверить обновления) | ⌘? (Открыть справку)\nМанифест: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Запуск, диагностика и 14 автотестов",
                    summary: "Один скрипт собирает и открывает macOS-приложение, а глобальный набор из 14 автотестов подтверждает работоспособность всех модулей.",
                    bullets: [
                        "Запуск: ./scripts/run_ssccc.sh собирает Swift-пакет и открывает окно SS-CCC.",
                        "14/14 автотестов: python3 -m unittest discover -s tests -v проверяет сборку, 8 языков, 3 вкладки, полосы, WAN и API.",
                        "Диагностика: при сбое TB-моста перезапустите ./scripts/setup_tb_network.sh; при нехватке ОЗУ проверьте iogpu.wired_limit_mb.",
                        "8 языков интерфейса: старт на английском с мгновенным переключением между EN, DE, FR, ES, PT, RU, JA и ZH."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v   # Ожидается: Ran 14 tests ... OK"
                )
            ]

        case .ja:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. ユニバーサル Apple Silicon クラスタリング (M1–M12+)",
                    summary: "Apple Silicon (M1〜M12+ — Base / Pro / Max / Ultra) を搭載したすべての Mac (Mac mini、MacBook Air、MacBook Pro、iMac、Mac Studio、Mac Pro) が対等なノードとして参加できます。",
                    bullets: [
                        "将来対応チップ解析: メモリ帯域幅、FP16 TFLOPS、Thunderbolt 世代を将来の M7–M12+ まで自動推定します。",
                        "自動ランク割り当て: メモリ帯域幅が最大の Mac (Ultra や Max) が自動的に Rank 0（コーディネーター）になります。",
                        "混在構成に対応: MacBook Pro M2 Max、Mac mini M4、Mac Studio M5 Max を 1 つのリングで連携可能です。",
                        "全フォームファクタ対応: デスクトップ機とノート機がモデルの層をシームレスに分担します。"
                    ],
                    codeSample: "Rank 0 = 最大メモリ帯域幅 (GB/s) -> コーディネーター & API 入口\nRank 1..N = 重み付きパイプラインのワーカーノード"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3タブ構成のクラスター概要 & 黄黒警告ストライプ",
                    summary: "クラスター概要は 3 つの大型タブで全体構成を整理し、計算・メモリ・通信の重要領域を斜め 45° の黄黒産業用警告ストライプで明示します。",
                    bullets: [
                        "タブ 1 — ローカルクラスター: ローカルの Thunderbolt 3/4/5 (RDMA/JACCL) および 10GbE マシン、Rank 0、利用可能メモリ、合計帯域を表示。",
                        "タブ 2 — インターネットクラスター: リモート WAN ノードと利用可能な地域・ローカルサブクラスターを整理して表示。",
                        "タブ 3 — ローカル + インターネット: ローカル TB 群とグローバル WAN 群を結合したハイブリッド統合ビューを表示。",
                        "黄黒ストライプ (HazardStripesBar & IndustrialHazardBanner): 6 つの主要画面で高負荷・保護領域を直感的に標識します。"
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nUI コンポーネント: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. 統合メモリプールと OOM 保護 (iogpu.wired_limit_mb)",
                    summary: "Apple Silicon では CPU と GPU が統合メモリを共有します。物理 RAM の 100% を MLX に割り当てないでください。",
                    bullets: [
                        "24 GB RAM まで: macOS と WindowServer 用に最低 4 GB を確保 (例: 16 GB -> 12 GB 利用可能)。",
                        "32 GB 〜 64 GB RAM: macOS 用に 6 GB を予約 (例: 36 GB -> 30 GB 利用可能)。",
                        "96 GB 以上 (Ultra/Max): macOS 用に 8 GB を予約 (例: 128 GB -> 120 GB 利用可能)。",
                        "起動前にモデル重み + KV キャッシュ予約量と合計利用可能メモリを自動検証します。"
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac -> 30 GB 上限\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. ネットワーク、Thunderbolt ブリッジ (TB3/4/5) & RDMA",
                    summary: "SS-CCC は制御プレーン (LAN/Wi-Fi) と高速テンソルデータプレーン (Thunderbolt) を明確に分離します。",
                    bullets: [
                        "制御プレーン (LAN/Wi-Fi): Bonjour 検出、API ゲートウェイ、テレメトリ、死活監視を担当。",
                        "データプレーン (Thunderbolt 3/4/5): 専用 10.99.1.x ブリッジにより 30–37 Gbps (TB4) または最大 90 Gbps (TB5 RDMA) を実現。",
                        "高速 Metal 同期: MLX_METAL_FAST_SYNCH=1 により GPU/CPU 境界の待機時間を ~180 µs から ~4 µs へ 45 倍高速化。",
                        "RDMA / JACCL: Thunderbolt 5 でネイティブ対応、Thunderbolt 4 でもオプション有効化が可能です。"
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # または mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. 重み付き分割、モデル読み込み & 複数モデル同時運用",
                    summary: "均等分割ではなく各 Mac の利用可能メモリ比で層を配分し、誰がモデルを読み込み何個まで同時常駐できるかを明確に制御します。",
                    bullets: [
                        "誰がモデルを読み込むか: 常に Rank 0（最大帯域 Mac）が POST /v1/cluster/plan で分割計画を統括し、各ワーカー (Rank 1..N) は担当層のみ読み込みます。",
                        "何個のモデルを同時読み込みできるか: Sum(重み + KV) ≤ 利用可能プール の範囲で複数同時常駐が可能 (例: 70B–405B+ ×1 または 7B–32B ×2–4)。",
                        "分割式と KV 量子化: Layers_i = Total × (Usable_i / TotalUsable)。KV は FP16 (~16k)、8-bit (~32k)、4-bit (~64k+) を選択可能。",
                        "分割プリフィル (--prefill-step-size 512) と oMLX の SSD KV オフロードでメモリスパイクを防止します。"
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. 構築ガイド: ローカルクラスター & ローカル+インターネット",
                    summary: "ローカル TB/RDMA クラスターの構築から、Tailscale / WireGuard / ZeroTier / libp2p QUIC を用いたグローバル WAN 連携までの手順です。",
                    bullets: [
                        "手順 1 (ローカル): 各ローカル Mac で setup_tb_network.sh と setup_wired_limit.sh を実行します（Rank 0 は自動選出）。",
                        "手順 2 (ゲートウェイ & モデル): Rank 0 で FastAPI (8000番) と oMLX/Ollama/llama.cpp を起動し、Model Studio からモデルを読み込みます。",
                        "手順 3 (インターネット WAN): 遠隔 Mac で暗号化メッシュ (Tailscale/WireGuard) を有効化し、Room ID とトークンで参加します。",
                        "手順 4 (ハイブリッド結合 & 世界記録): 「ローカル + インターネット結合」を押すとローカル TB が Tier-0 コアとなり WAN が余剰層を担当します (64–256+ ノード)。"
                    ],
                    codeSample: "WebSocket チャットリレー: ws://127.0.0.1:8000/ws/wan-chat\n結合: ローカル (TB/RDMA Tier-0) + WAN -> ハイブリッドスーパークラスター"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. ライブ参加者チャット & クラスター Audio-Party",
                    summary: "テキストチャットの隣に、分散 AI チーム向けのコンソール風ボイスチャット (Xbox / PlayStation 着想) を統合しています。",
                    bullets: [
                        "低遅延音声: AVAudioEngine (16 kHz PCM16) により専用リレー /ws/wan-audio 経由で通話します。",
                        "通話モード: Push-to-Talk と Open-Mic の切替、即時ミュート、聴取オフ (Deafen)、音量メーターを備えています。",
                        "参加者リスト: 発言中のメンバー、接続ノードの役割、ルーム状態をリアルタイム表示します。",
                        "極小帯域: 音声トラフィックは WAN 上り帯域の 0.02% 未満でテンソル通信を妨げません。"
                    ],
                    codeSample: "WebSocket 音声リレー: ws://127.0.0.1:8000/ws/wan-audio\n形式: AVAudioEngine 16 kHz PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. 科学＆Rooflineラボ (6タブ) と履歴記録",
                    summary: "ローカル TB/RDMA、インターネット WAN、および両者の直接比較を 6 つの専門タブで解析できます。",
                    bullets: [
                        "タブ 1–2 (Roofline & WAN): Williams 対数 Roofline、TTFT/TPOT、GPipe バブル、Petals/SWARM 圧縮、N=1..128、DiLoCo vs DDP。",
                        "タブ 3–4 (メモリ & エネルギー): Transformer メモリ式、TokenPowerBench (J/tok, EDP)、地域別 CO₂ (gCO₂/1M)、クラウド比電力コスト。",
                        "タブ 5 (試行 & 出力): N=5/10/20 試行の p50/p95/p99、95% CI、SLO Goodput、CSV / JSON / LaTeX / 8論文 BibTeX 出力。",
                        "タブ 6 (履歴記録): 単一項目または全体の計測履歴を自動・手動で記録し、推移グラフ表示と CSV 出力を行います。"
                    ],
                    codeSample: "範囲: ローカル (TB/RDMA) | インターネット WAN | 比較\n履歴: 単一項目記録 | 全体記録 | 自動記録"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. ランタイム: MLX, oMLX, Ollama & llama.cpp",
                    summary: "好みのローカルランタイムでモデルを直接起動し、既存の Ollama / GGUF モデルもリアルタイム検出します。",
                    bullets: [
                        "oMLX (8000番): SSD ページング KV キャッシュと OpenAI + Anthropic 両対応エンドポイントを備えた macOS ネイティブ MLX サーバー。",
                        "Ollama (11434番): 設定不要の GGUF ランナーとライブモデル検出。",
                        "llama.cpp (8080番): llama-server による直接 GGUF 実行。",
                        "自動検出: 稼働中のローカルランタイムを自動スキャンし、利用可能モデルを一覧表示します。"
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nポート: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AIエージェント (1クリック) & ローカル API",
                    summary: "ローカルのコーディングエージェントや IDE を、クラウドへ一切データ送信せず統合クラスターに接続します。",
                    bullets: [
                        "1 クリック設定: OpenCode、Hermes Agent、Google Antigravity 用の設定ファイルを自動生成します。",
                        "幅広い IDE 対応: Cursor、Continue、Open WebUI、Xcode とそのまま連携できます。",
                        "OpenAI & Anthropic 互換: /v1/chat/completions、/v1/messages、/api/chat を同時提供します。",
                        "API コンソール: 内蔵コンソールからプロンプト応答、遅延、スループットを即座にテストできます。"
                    ],
                    codeSample: "OpenAI エンドポイント:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic エンドポイント: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub 自動アップデート & CI バージョン管理",
                    summary: "SS-CCC は GitHub のリリースとコミットを自動監視し、ソース導入環境もパッケージ版も常に最新へ保ちます。",
                    bullets: [
                        "自動チェック: 起動時および 30 分ごと（または ⌘U）に version.json、GitHub Releases、main の SHA を照合します。",
                        "UpdatePromptSheet: 更新内容やコミット差分をアプリ内でそのまま確認できます。",
                        "1 クリック更新: ソース版は git pull + swift build + 再起動を自動実行し、配布版はダウンロードページを開きます。",
                        "CI バージョン同期: main への push ごとに scripts/bump_version.py --part patch --sync-git が走り vX.Y.Z タグを付与します。"
                    ],
                    codeSample: "ショートカット: ⌘U (更新確認) | ⌘? (マニュアル)\nマニフェスト: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. 起動方法、トラブルシューティング & 14件の自動テスト",
                    summary: "1 つのスクリプトで macOS アプリをビルド・起動でき、14 項目の総合テストスイートが全機能を自動検証します。",
                    bullets: [
                        "アプリ起動: ./scripts/run_ssccc.sh が Swift パッケージをビルドして SS-CCC ウィンドウを開きます。",
                        "14/14 総合テスト: python3 -m unittest discover -s tests -v でビルド、8 言語、3 タブ概要、警告ストライプ、WAN、API を検証します。",
                        "トラブル対処: TB ブリッジ未認識時は ./scripts/setup_tb_network.sh を再実行し、メモリ警告時は iogpu.wired_limit_mb を確認してください。",
                        "8 言語 UI: 起動時は英語で開始し、EN / DE / FR / ES / PT / RU / JA / ZH をリアルタイムに切り替えられます。"
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v   # 期待結果: Ran 14 tests ... OK"
                )
            ]

        case .zh:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. 全系列 Apple Silicon Mac 通用集群 (M1–M12+)",
                    summary: "任何搭载 Apple Silicon 芯片（M1 至 M12+ — 基础版、Pro、Max 或 Ultra）的 Mac 均可平等加入集群：Mac mini、MacBook Air、MacBook Pro、iMac、Mac Studio 与 Mac Pro。",
                    bullets: [
                        "面向未来的芯片解析：内存带宽、FP16 TFLOPS 与雷雳代际可自动推断至未来的 M7–M12+ 芯片。",
                        "自动秩分配：内存带宽最高的 Mac（如 Ultra 或 Max）自动担任 Rank 0（主控节点）。",
                        "跨代混搭：可轻松将 MacBook Pro M2 Max、Mac mini M4 与 Mac Studio M5 Max 组成同一推理环。",
                        "全形态支持：桌面工作站与便携本无缝分担模型网络层。"
                    ],
                    codeSample: "Rank 0 = 最高内存带宽 (GB/s) -> 主控节点与 API 入口\nRank 1..N = 加权流水线池中的工作节点"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 三标签页集群概览与工业黄黑警示条纹",
                    summary: "集群概览通过三大独立切换标签整理全部算力，并在计算、内存与网络关键边界处采用 45° 斜向黄黑工业警示条纹。",
                    bullets: [
                        "标签 1 — 本地集群：展示所有本地雷雳 3/4/5 (RDMA/JACCL) 与万兆以太网主机、Rank 0 主控、可用显存池与聚合带宽。",
                        "标签 2 — 互联网集群：清晰呈现远程 WAN 节点以及可用的区域与本地子集群分组。",
                        "标签 3 — 本地 + 互联网：将本地雷雳核心与全球 WAN 集群合并为统一的混合超级集群视图。",
                        "黄黑警示条纹 (HazardStripesBar 与 IndustrialHazardBanner)：在 6 大核心视图中直观标识高负载与保护边界。"
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\n主题组件: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. 统一内存池与 OOM 防护 (iogpu.wired_limit_mb)",
                    summary: "Apple Silicon 的 CPU 与 GPU 共享统一内存。切勿将 100% 的物理内存全部分配给 MLX 负载。",
                    bullets: [
                        "24 GB 及以下内存：至少为 macOS 与 WindowServer 保留 4 GB（例如 16 GB -> 12 GB 可用）。",
                        "32 GB 至 64 GB 内存：为 macOS 保留 6 GB（例如 36 GB -> 30 GB 可用）。",
                        "96 GB 及以上（Ultra/Max）：为 macOS 保留 8 GB（例如 128 GB -> 120 GB 可用）。",
                        "加载前自动校验模型权重 + KV 缓存预留总量是否超出集群可用内存池。"
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac -> 30 GB MLX 上限\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. 网络架构、雷雳桥接 (TB3/4/5) 与 RDMA (JACCL)",
                    summary: "SS-CCC 将控制平面发现（LAN/Wi-Fi）与高速激活张量传输平面（Thunderbolt）彻底隔离。",
                    bullets: [
                        "控制平面（LAN/Wi-Fi）：负责 Bonjour 节点发现、API 网关、遥测与健康检查。",
                        "数据平面（Thunderbolt 3/4/5）：专用 10.99.1.x 桥接网段提供 30–37 Gbps (TB4) 或高达 90 Gbps (TB5 RDMA) 吞吐。",
                        "极速 Metal 同步：MLX_METAL_FAST_SYNCH=1 将 GPU/CPU 同步延迟从 ~180 µs 降至 ~4 µs（提速 45×）。",
                        "RDMA / JACCL：Thunderbolt 5 原生支持，Thunderbolt 4 可按需开启。"
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # 或 mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. 加权分片、模型加载机制与多模型驻留",
                    summary: "SS-CCC 按各台 Mac 的可用内存比例分配网络层，并明确规范由谁加载模型以及可同时驻留多少个模型。",
                    bullets: [
                        "谁来加载模型？始终由 Rank 0（最高带宽 Mac）通过 POST /v1/cluster/plan 统筹分片清单；各工作节点 (Rank 1..N) 仅加载分配到的层区间。",
                        "可同时加载多少个模型？只要 权重与KV总和 ≤ 可用内存池 即可多模型并发驻留（如 1× 70B–405B+ 或 2–4× 7B–32B 专用模型）。",
                        "加权公式与 KV 量化：Layers_i = Total × (Usable_i / TotalUsable)；KV 缓存支持 FP16 (~16k)、8-bit (~32k) 与 4-bit (~64k+)。",
                        "分块预填充 (--prefill-step-size 512) 与 oMLX SSD 分页 KV 卸载可避免大仓库上下文导致的内存峰值。"
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. 搭建指南：本地集群与“本地 + 互联网”混合集群",
                    summary: "从本地雷雳 RDMA 集群搭建，到通过 Tailscale、WireGuard、ZeroTier 或 libp2p QUIC 耦合全球互联网 WAN 节点的完整步骤。",
                    bullets: [
                        "步骤 1（本地）：在每台本地 Mac 运行 setup_tb_network.sh 与 setup_wired_limit.sh；系统自动推举 Rank 0。",
                        "步骤 2（网关与模型）：在 Rank 0 启动 FastAPI 网关（8000 端口）与 oMLX/Ollama/llama.cpp，并在模型工作室加载目标模型。",
                        "步骤 3（互联网 WAN）：在远程 Mac 启用加密组网（Tailscale/WireGuard），于互联网集群页凭房间 ID 与令牌加入。",
                        "步骤 4（混合耦合与纪录模式）：点击“耦合本地 + 互联网”，本地 TB 群担任 Tier-0 高速核心，WAN 节点承接溢出层（支持 64–256+ 节点）。"
                    ],
                    codeSample: "WebSocket 聊天中继: ws://127.0.0.1:8000/ws/wan-chat\n混合耦合: 本地 (TB/RDMA Tier-0) + 互联网 WAN -> 混合超级集群"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. 实时参与者聊天与集群 Audio-Party 语音派对",
                    summary: "在文字聊天旁，SS-CCC 内置了主机级（Xbox / PlayStation 风格）集群语音派对，专为分布式 AI 协作打造。",
                    bullets: [
                        "低延迟语音：基于 AVAudioEngine (16 kHz PCM16)，通过专用中继端点 /ws/wan-audio 传输。",
                        "通话模式：支持按键说话 (Push-to-Talk) 与自由麦 (Open-Mic) 切换，提供一键静音、拒听与实时电平表。",
                        "成员列表：实时展示当前发言者、各节点角色及房间连接状态。",
                        "极低带宽占用：语音流仅占常规 WAN 上行带宽的 <0.02%，完全不影响张量同步。"
                    ],
                    codeSample: "WebSocket 音频中继: ws://127.0.0.1:8000/ws/wan-audio\n音频格式: AVAudioEngine 16 kHz PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. 科学与 Roofline 实验室 (6 标签页) 与历史记录",
                    summary: "在六个专业研究标签页中深入分析本地 TB/RDMA、互联网 WAN 以及二者的横向对比。",
                    bullets: [
                        "标签 1–2（Roofline 与 WAN）：Williams 对数 Roofline、TTFT/TPOT、GPipe 气泡、Petals/SWARM 压缩、N=1..128 扩展与 DiLoCo vs DDP。",
                        "标签 3–4（内存与能耗）：Transformer 内存方程、TokenPowerBench (J/tok, EDP)、区域电网碳排 (gCO₂/1M) 与云端电费对比。",
                        "标签 5（实验与导出）：N=5/10/20 次可复现实验，统计 p50/p95/p99、95% CI、SLO Goodput，支持 CSV / JSON / LaTeX / 8篇 BibTeX 导出。",
                        "标签 6（历史记录）：支持按单指标或全局自动/手动记录快照，提供趋势双线图与 CSV 导出。"
                    ],
                    codeSample: "分析域: 本地 (TB/RDMA) | 互联网 WAN | 对比 (本地 vs WAN)\n历史: 记录单指标 | 全局记录 | 自动记录"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. 运行时服务：MLX、oMLX、Ollama 与 llama.cpp",
                    summary: "在模型工作室直接启动偏好的本地运行时，或自动扫描并接管本机已下载的 Ollama / GGUF 模型。",
                    bullets: [
                        "oMLX (8000 端口)：macOS 原生 MLX 服务，支持 SSD 分页 KV 缓存及 OpenAI + Anthropic 双接口。",
                        "Ollama (11434 端口)：零配置 GGUF 运行器，支持实时模型列表发现。",
                        "llama.cpp (8080 端口)：通过 llama-server 直接运行 GGUF 模型。",
                        "实时发现：SS-CCC 自动探测本地运行中的推理后端并列出可用模型。"
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\n端口: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI 智能体一键配置与本地 API 接口",
                    summary: "将本地编程智能体与 IDE 直接接入统一 Apple Silicon 集群，源码与文档全程不出内网。",
                    bullets: [
                        "一键配置：在 AI 智能体页面直接为 OpenCode、Hermes Agent 与 Google Antigravity 生成配置。",
                        "广泛兼容：无缝适配 Cursor、Continue、Open WebUI 与 Xcode。",
                        "双协议兼容：同时提供 OpenAI (/v1/chat/completions)、Anthropic (/v1/messages) 与 /api/chat。",
                        "API 控制台：内置交互式测试台，可即时验证提示词响应、延迟与吞吐率。"
                    ],
                    codeSample: "OpenAI 接口:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic 接口: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub 自动更新器与 CI 版本控制",
                    summary: "SS-CCC 自动监测 GitHub 最新版本与提交，确保源码部署与打包版本始终保持最新。",
                    bullets: [
                        "自动轮询：启动时及每 30 分钟（或按 ⌘U）自动比对 version.json、GitHub Releases 与 main 分支 SHA。",
                        "UpdatePromptSheet：在应用内直接展示更新日志与提交差异。",
                        "一键升级：源码安装自动执行 git pull + swift build + 重启；打包版本直接打开 GitHub 下载。",
                        "CI 版本同步：每次推送 main 自动运行 scripts/bump_version.py --part patch --sync-git 并打上 vX.Y.Z 标签。"
                    ],
                    codeSample: "快捷键: ⌘U (检查更新) | ⌘? (打开手册)\n清单: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. 启动应用、故障排查与 14 项全局测试套件",
                    summary: "单条脚本即可编译并启动 macOS 桌面应用，14 项全局自动化测试全面保障各模块质量。",
                    bullets: [
                        "启动应用：./scripts/run_ssccc.sh 自动编译 Swift 包并打开 SS-CCC 桌面窗口。",
                        "14/14 全局测试：python3 -m unittest discover -s tests -v 全面验证编译、8 种语言、3 标签概览、警示条纹、WAN 与 API。",
                        "常见排查：若雷雳网桥断开请重新运行 ./scripts/setup_tb_network.sh；出现内存告警请检查 iogpu.wired_limit_mb。",
                        "8 语言界面：默认英文启动，支持 EN、DE、FR、ES、PT、RU、JA、ZH 实时热切换。"
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 -m unittest discover -s tests -v   # 预期输出: Ran 14 tests ... OK"
                )
            ]
        }
    }
}
