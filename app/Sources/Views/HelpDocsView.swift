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
                    title: "1. Alle Apple Mac mit M-Prozessor im Verbund (M1–M9+)",
                    summary: "Jeder Mac mit Apple-Silicon-Chip (M1, M2, M3, M4, M5, M6 — Basis, Pro, Max oder Ultra) kann als gleichberechtigter Rechner in den Verbund aufgenommen werden: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio und Mac Pro.",
                    bullets: [
                        "Automatische Rang-Vergabe: Der Mac mit dem höchsten Speicherdurchsatz (z. B. Ultra oder Max) übernimmt selbsttätig Rang 0 (Leitrechner).",
                        "Beliebig erweiterbar: Unter ‚Geräte & Vergleich‘ lassen sich weitere M-Macs mit Modellreihe, Chip und Arbeitsspeicher hinzufügen.",
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
                        "Schutzregel: Bis 24 GB RAM bleiben mindestens 4 GB für macOS und WindowServer frei.",
                        "Ab 32 GB bis 64 GB RAM bleiben 6 GB für das Betriebssystem geschützt.",
                        "Ab 96 GB RAM (z. B. Ultra-Modelle) bleiben 8 GB für macOS geschützt.",
                        "Vor dem Laden prüft SS-CCC den Gesamtbedarf (Modellgewicht + KV-Zwischenspeicher) gegen die nutzbare Summe aller Geräte."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Beispiel für 36-GB-Mac (30 GB nutzbar)"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. Netzwerk, Thunderbolt-Brücke & RDMA",
                    summary: "SS-CCC trennt Steuerdaten und Modell-Aktivierungsdaten sauber auf zwei Ebenen, um Funkstörungen auszuschließen.",
                    bullets: [
                        "Steuer-Ebene (LAN/WLAN): Erkennung über Bonjour, API-Anfragen und Zustandstausch.",
                        "Daten-Ebene (Thunderbolt 4/5): Punkt-zu-Punkt-Brücke im Netz 10.99.1.x mit real 30–37 Gbps Durchsatz.",
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
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Laufzeit-Dienste: MLX, oMLX, Ollama & llama.cpp",
                    summary: "Im Modell-Studio lassen sich Modelle unmittelbar für den gewünschten örtlichen Dienst starten oder zwischen Formaten überführen.",
                    bullets: [
                        "oMLX (Port 8000): Nativer macOS-MLX-Dienst mit ausgelagertem SSD-KV-Zwischenspeicher sowie OpenAI- und Anthropic-Schnittstelle.",
                        "Ollama (Port 11434): Weit verbreiteter Dienst für örtliche GGUF-Modelle; vorhandene Modelle lassen sich in SS-CCC einlesen.",
                        "llama.cpp (Port 8080): Unmittelbarer GGUF-Dienst ohne Umwege."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "6. KI-Agenten & Entwicklungsumgebungen (1-Klick-Einrichtung)",
                    summary: "Alle Werkzeuge greifen über die einheitliche örtliche Schnittstelle auf den gesamten Mac-Verbund zu — ohne Cloud-Übertragung.",
                    bullets: [
                        "OpenCode: Schreibt ~/.config/opencode/opencode.json auf http://127.0.0.1:8000/v1.",
                        "Hermes Agent: Konfiguriert ~/.hermes/config.yaml für ausdauernde Agenten-Schleifen.",
                        "Google Antigravity: Erzeugt ~/.gemini/antigravity/local_cluster_config.json für lokale Modelle.",
                        "Weitere Werkzeuge: Cursor, Continue, Open WebUI und Xcode nutzen denselben OpenAI-/Ollama-Endpunkt."
                    ],
                    codeSample: "OpenAI-Endpunkt: http://127.0.0.1:8000/v1\nOllama-Endpunkt: http://127.0.0.1:8000/api/tags"
                )
            ]

        case .en:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Universal Apple Silicon M-Series Clustering (M1–M9+)",
                    summary: "Any Mac with an Apple Silicon M-series processor (M1, M2, M3, M4, M5, M6 — Base, Pro, Max, or Ultra) can join the cluster: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, and Mac Pro.",
                    bullets: [
                        "Automatic Rank Assignment: The Mac with the highest memory bandwidth (e.g., Ultra or Max) automatically becomes Rank 0 (Coordinator).",
                        "Flexible Scaling: Add 2, 3, or more M-series Macs under 'Devices & Compare' with exact chip and memory profiles.",
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
                        "Up to 24 GB RAM: Keep at least 4 GB reserved for macOS and WindowServer.",
                        "32 GB to 64 GB RAM: Reserve 6 GB for macOS.",
                        "96 GB+ RAM (Ultra/Max): Reserve 8 GB for macOS.",
                        "SS-CCC verifies model weights + KV cache reserve against the combined usable pool before launch."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac -> 30 GB MLX limit"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "3. Networking, Thunderbolt Bridge & RDMA",
                    summary: "SS-CCC isolates control-plane discovery from high-speed activation tensor transfers.",
                    bullets: [
                        "Control Plane (LAN/Wi-Fi): Bonjour discovery, API gateway, and health checks.",
                        "Data Plane (Thunderbolt 4/5): Dedicated 10.99.1.x bridge delivering 30–37 Gbps real throughput.",
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
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Runtime Services: MLX, oMLX, Ollama & llama.cpp",
                    summary: "Launch the active model directly in your preferred local runtime or scan local Ollama/GGUF models into fast MLX.",
                    bullets: [
                        "oMLX (Port 8000): Native macOS MLX server with paged SSD KV-cache and OpenAI + Anthropic endpoints.",
                        "Ollama (Port 11434): Zero-config GGUF runner; SS-CCC can scan local Ollama models.",
                        "llama.cpp (Port 8080): Direct llama-server GGUF execution."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "6. AI Agents, IDEs & SDKs (1-Click Setup)",
                    summary: "Point local coding agents and editors to your unified Apple Silicon cluster with zero cloud leakage.",
                    bullets: [
                        "OpenCode: Writes ~/.config/opencode/opencode.json pointing to http://127.0.0.1:8000/v1.",
                        "Hermes Agent: Configures ~/.hermes/config.yaml for long-running autonomous loops.",
                        "Google Antigravity: Generates ~/.gemini/antigravity/local_cluster_config.json.",
                        "Also compatible with Cursor, Continue, Open WebUI, and Xcode."
                    ],
                    codeSample: "OpenAI Endpoint: http://127.0.0.1:8000/v1\nOllama Endpoint: http://127.0.0.1:8000/api/tags"
                )
            ]

        case .fr:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Tous les Mac à puce Apple M en grappe (M1 à M6)",
                    summary: "Tout Mac équipé d'une puce Apple Silicon (M1, M2, M3, M4, M5, M6 — Base, Pro, Max ou Ultra) peut rejoindre la grappe : Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio et Mac Pro.",
                    bullets: [
                        "Attribution automatique du rang : le Mac ayant le plus fort débit mémoire devient le maître (rang 0).",
                        "Extension libre : ajoutez 2, 3 Mac ou plus sous « Appareils et comparaison ».",
                        "Générations mixtes : associez par exemple un MacBook Pro M2 Max, un Mac mini M4 et un Mac Studio M5 Max."
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
                    title: "3. Réseau, pont Thunderbolt et RDMA",
                    summary: "SS-CCC sépare le plan de commande (LAN/Wi-Fi) du transfert des tenseurs sur Thunderbolt 4/5 (10.99.1.x, 30–37 Gbps).",
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
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Moteurs locaux : MLX, oMLX, Ollama et llama.cpp",
                    summary: "Lancez vos modèles directement dans oMLX (cache SSD paginé), Ollama ou llama.cpp.",
                    bullets: [
                        "oMLX (port 8000), Ollama (port 11434) et llama.cpp (port 8080) sont gérés depuis le Studio de modèles."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "6. Agents et environnements locaux (1 clic)",
                    summary: "Reliez OpenCode, Hermes Agent et Google Antigravity à la grappe locale sans fuite vers le nuage.",
                    bullets: [
                        "Compatible avec OpenCode, Hermes Agent, Google Antigravity, Cursor, Continue et Xcode."
                    ],
                    codeSample: "http://127.0.0.1:8000/v1"
                )
            ]

        case .es:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Todos los Mac con procesador M en conjunto (M1–M9+)",
                    summary: "Cualquier Mac con Apple Silicon (M1, M2, M3, M4, M5, M6 — Base, Pro, Max o Ultra) puede unirse al conjunto: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio y Mac Pro.",
                    bullets: [
                        "Asignación automática de rango: el Mac con mayor ancho de banda de memoria asume el rango 0.",
                        "Escalable libremente: añade 2, 3 o más Mac en «Equipos y comparación».",
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
                    title: "3. Red, puente Thunderbolt y RDMA",
                    summary: "Control por LAN/Wi-Fi y transferencia de tensores aislada por Thunderbolt 4/5 (10.99.1.x, 30–37 Gbps).",
                    bullets: [
                        "MLX_METAL_FAST_SYNCH=1 reduce la espera GPU/CPU de ~180 µs a ~4 µs (45× más rápido)."
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
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Motores locales: MLX, oMLX, Ollama y llama.cpp",
                    summary: "Carga modelos en oMLX (caché SSD paginada), Ollama o llama.cpp desde el Estudio de modelos.",
                    bullets: [
                        "Puertos predeterminados: oMLX (8000), Ollama (11434), llama.cpp (8080)."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "6. Agentes y entornos locales (1 clic)",
                    summary: "Conecta OpenCode, Hermes Agent y Google Antigravity al conjunto local en un clic.",
                    bullets: [
                        "Compatible también con Cursor, Continue, Open WebUI y Xcode."
                    ],
                    codeSample: "http://127.0.0.1:8000/v1"
                )
            ]

        case .pt:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Todos os Mac com processador M em conjunto (M1–M9+)",
                    summary: "Qualquer Mac com Apple Silicon (M1, M2, M3, M4, M5, M6 — Base, Pro, Max ou Ultra) pode integrar o conjunto: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio e Mac Pro.",
                    bullets: [
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
                    title: "3. Rede, ponte Thunderbolt e RDMA",
                    summary: "Controlo por LAN/Wi-Fi e tensores isolados por Thunderbolt 4/5 (10.99.1.x, 30–37 Gbps).",
                    bullets: [
                        "MLX_METAL_FAST_SYNCH=1 reduz a sincronização GPU/CPU de ~180 µs para ~4 µs (45× mais rápida)."
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
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "5. Motores locais: MLX, oMLX, Ollama e llama.cpp",
                    summary: "Carregue modelos no oMLX, Ollama ou llama.cpp diretamente a partir do Estúdio de Modelos.",
                    bullets: [
                        "Portas predefinidas: oMLX (8000), Ollama (11434), llama.cpp (8080)."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000"
                ),
                HelpDocSection(
                    id: "agents",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "6. Agentes e ambientes locais (1 clique)",
                    summary: "Ligue o OpenCode, o Hermes Agent e o Google Antigravity ao conjunto local num clique.",
                    bullets: [
                        "Compatível também com Cursor, Continue, Open WebUI e Xcode."
                    ],
                    codeSample: "http://127.0.0.1:8000/v1"
                )
            ]
        }
    }
}
