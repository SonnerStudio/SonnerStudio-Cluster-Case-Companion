import SwiftUI
import AppKit

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
                if let selectedId = vm.selectedHelpSectionId,
                   let selectedIndex = sections.firstIndex(where: { $0.id == selectedId }) {
                    detailView(for: sections[selectedIndex], index: selectedIndex)
                } else {
                    overviewView
                }
            }
            .padding(24)
        }
        .solarisShorttip(vm.shorttip(.help), id: "view_help_root", vm: vm)
    }

    // MARK: - Overview List (Clickable Chapter Cards)

    private var overviewView: some View {
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
                let isHovered = vm.hoveredHelpSectionId == section.id
                SolarisCard(accent: section.accent, isHovered: isHovered) {
                    HStack(spacing: 10) {
                        Image(systemName: section.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(section.accent)
                            .shadow(color: isHovered ? section.accent.opacity(0.65) : .clear, radius: 6)
                        Text(section.title)
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        HStack(spacing: 5) {
                            Text(L10n.tr(vm.language,
                                de: "Details & Grafiken",
                                en: "Details & Visuals",
                                fr: "Détails & Schémas",
                                es: "Detalles y Gráficos",
                                pt: "Detalhes e Gráficos",
                                ru: "Детали и схемы",
                                ja: "詳細・図解",
                                zh: "详情与架构图"))
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(isHovered ? .black : section.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(isHovered ? section.accent : section.accent.opacity(0.14)))
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
                .contentShape(Rectangle())
                .onHover { hovering in
                    vm.hoveredHelpSectionId = hovering ? section.id : (vm.hoveredHelpSectionId == section.id ? nil : vm.hoveredHelpSectionId)
                }
                .onTapGesture {
                    vm.selectedHelpSectionId = section.id
                }
            }
        }
    }

    // MARK: - Detailed In-Place Chapter View

    private func detailView(for section: HelpDocSection, index: Int) -> some View {
        let deep = HelpDocDeepDiveCatalog.deepDive(for: section.id, section: section, lang: vm.language)

        return VStack(alignment: .leading, spacing: 18) {
            // Top Navigation Bar
            HStack(spacing: 12) {
                Button {
                    vm.selectedHelpSectionId = nil
                } label: {
                    Label(
                        L10n.tr(vm.language,
                            de: "Zurück zur Handbuch-Übersicht",
                            en: "Back to Manual Overview",
                            fr: "Retour au sommaire du manuel",
                            es: "Volver al índice del manual",
                            pt: "Voltar ao índice do manual",
                            ru: "Назад к оглавлению",
                            ja: "マニュアル一覧へ戻る",
                            zh: "返回手册目录"),
                        systemImage: "chevron.left"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.amber)
                .foregroundColor(.black)

                Spacer()

                Text("\(L10n.tr(vm.language, de: "Kapitel", en: "Chapter", fr: "Chapitre", es: "Capítulo", pt: "Capítulo", ru: "Глава", ja: "第", zh: "章节")) \(index + 1) / \(sections.count)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(SolarisTheme.textSecondary)

                Button {
                    if index > 0 {
                        vm.selectedHelpSectionId = sections[index - 1].id
                    }
                } label: {
                    Image(systemName: "arrow.left")
                }
                .buttonStyle(.bordered)
                .disabled(index == 0)

                Button {
                    if index + 1 < sections.count {
                        vm.selectedHelpSectionId = sections[index + 1].id
                    }
                } label: {
                    Image(systemName: "arrow.right")
                }
                .buttonStyle(.bordered)
                .disabled(index + 1 >= sections.count)
            }

            // Hero Card + Key Metrics
            SolarisCard(accent: section.accent) {
                HazardStripesBar(height: 5, stripeWidth: 10, cornerRadius: 3, opacity: 0.8)

                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: section.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(section.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(deep.subtitle)
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(section.accent)
                    }
                }

                Text(section.summary)
                    .font(SolarisTheme.bodyLarge)
                    .foregroundColor(SolarisTheme.textSecondary)

                HStack(spacing: 12) {
                    ForEach(deep.keyMetrics, id: \.label) { metric in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(metric.label)
                                .font(Font.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            Text(metric.value)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(SolarisTheme.textPrimary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SolarisTheme.cardElevated)
                        .cornerRadius(8)
                    }
                }
            }

            // Explanatory Images & Graphics
            if !deep.visuals.isEmpty {
                SolarisCard(accent: SolarisTheme.mint) {
                    Text(L10n.tr(vm.language,
                        de: "Erklärende Architektur-Grafiken & Ansichten",
                        en: "Explanatory Architecture Graphics & Diagrams",
                        fr: "Schémas d'architecture & vues explicatives",
                        es: "Gráficos y diagramas explicativos de arquitectura",
                        pt: "Gráficos e diagramas explicativos da arquitetura",
                        ru: "Пояснительные архитектурные схемы и диаграммы",
                        ja: "アーキテクチャ解説図・ビジュアル",
                        zh: "架构说明图示与视图"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    ForEach(deep.visuals, id: \.imageFile) { visual in
                        VStack(alignment: .leading, spacing: 8) {
                            if let nsImg = HelpDocImageLoader.loadImage(named: visual.imageFile) {
                                Image(nsImage: nsImg)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: 380)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(section.accent.opacity(0.4), lineWidth: 1)
                                    )
                            }
                            Text(visual.caption)
                                .font(Font.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                    }
                }
            }

            // Detailed Technical Explanation & Step-by-Step Guide
            SolarisCard {
                Text(L10n.tr(vm.language,
                    de: "Ausführliche Erklärung & Funktionsweise",
                    en: "In-Depth Technical Explanation",
                    fr: "Explication technique approfondie",
                    es: "Explicación técnica en profundidad",
                    pt: "Explicação técnica aprofundada",
                    ru: "Подробное техническое описание",
                    ja: "詳細な技術解説・動作仕組み",
                    zh: "深入技术原理解析"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(deep.detailedParagraphs, id: \.self) { para in
                        Text(para)
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Divider().opacity(0.25)

                Text(L10n.tr(vm.language,
                    de: "Schritt-für-Schritt-Einrichtung",
                    en: "Step-by-Step Setup",
                    fr: "Configuration étape par étape",
                    es: "Configuración paso a paso",
                    pt: "Configuração passo a passo",
                    ru: "Пошаговая настройка",
                    ja: "ステップ別セットアップ手順",
                    zh: "分步配置指南"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.amberGlow)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(deep.stepByStep, id: \.self) { step in
                        Text(step)
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textPrimary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(SolarisTheme.cardElevated)
                            .cornerRadius(8)
                    }
                }
            }

            // Key Specifications, Best Practices & Copyable Commands
            SolarisCard(accent: SolarisTheme.emerald) {
                Text(L10n.tr(vm.language,
                    de: "Kernpunkte & Empfehlungen (Best Practices)",
                    en: "Key Points & Best Practices",
                    fr: "Points clés & bonnes pratiques",
                    es: "Puntos clave y buenas prácticas",
                    pt: "Pontos-chave e boas práticas",
                    ru: "Ключевые рекомендации (Best Practices)",
                    ja: "重要ポイント・ベストプラクティス",
                    zh: "核心要点与最佳实践"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(section.bullets + deep.bestPractices, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("✓")
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(SolarisTheme.emerald)
                            Text(item)
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textPrimary)
                        }
                    }
                }

                if let code = section.codeSample {
                    Divider().opacity(0.25)
                    HStack {
                        Text(L10n.tr(vm.language,
                            de: "Direkte Terminal- & API-Referenz",
                            en: "Direct Terminal & API Reference",
                            fr: "Référence directe Terminal & API",
                            es: "Referencia directa de Terminal y API",
                            pt: "Referência direta de Terminal e API",
                            ru: "Справочник команд и API",
                            ja: "ターミナル & API リファレンス",
                            zh: "终端命令与 API 直接参考"))
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.mint)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(code, forType: .string)
                        } label: {
                            Label(L10n.tr(vm.language, de: "Kopieren", en: "Copy", fr: "Copier", es: "Copiar", pt: "Copiar", ru: "Копировать", ja: "コピー", zh: "复制"), systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }

                    Text(code)
                        .font(SolarisTheme.monoCode)
                        .foregroundColor(SolarisTheme.mint)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.42)))
                        .textSelection(.enabled)
                }
            }
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

        case .nl:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Elke Apple Mac met M-processor in het cluster (M1–M12+)",
                    summary: "Elke Mac met Apple Silicon-chip (M1 tot M12+ — Basis, Pro, Max of Ultra) kan als volwaardige rekenknooppunt aan het cluster deelnemen: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio en Mac Pro.",
                    bullets: [
                        "Toekomstbestendige generatiedetectie: Geheugenbandbreedte, FP16-TFLOPS en Thunderbolt-generatie worden ook voor toekomstige M-chips (M7–M12+) automatisch afgeleid.",
                        "Automatische rangtoewijzing: De Mac met de hoogste geheugendoorvoer (bijv. Ultra of Max) krijgt automatisch Rang 0 (coördinator).",
                        "Gemengde generaties: Een MacBook Pro M2 Max werkt probleemloos samen met een Mac mini M4 of een Mac Studio M5 Max.",
                        "Alle modellen ondersteund: Vaste werkstations (Mac Studio, Mac Pro, Mac mini, iMac) en draagbare Macs (MacBook Air/Pro) delen gezamenlijk modellagen."
                    ],
                    codeSample: "Rang 0 = hoogste geheugendoorvoer (GB/s) -> Coördinator & API-ingang\nRang 1..N = gekoppelde werknodes in gewogen laagverdeling"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-tabbladen clusteroverzicht & industriële waarschuwingsstrepen",
                    summary: "Het clusteroverzicht verdeelt het volledige rekencluster in drie grote, duidelijk gescheiden selectietabbladen en markeert veiligheidskritische prestatie- en geheugenzones met diagonale geel-zwarte waarschuwingsstrepen.",
                    bullets: [
                        "Tabblad 1 — Lokaal cluster: Toont alle lokale Thunderbolt-3/4/5- (RDMA/JACCL) en 10GbE-Macs inclusief Rang 0, bruikbare geheugenpool en gezamenlijke bandbreedte.",
                        "Tabblad 2 — Internetcluster: Toont externe WAN-deelnemers en onderverdeelde regionale en lokale deelclusters (subclusters) overzichtelijk.",
                        "Tabblad 3 — Lokaal + Internet: Verenigt de lokale Thunderbolt-kern en het wereldwijde WAN-netwerk in één gekoppelde hybride totaalweergave.",
                        "Geel-zwarte waarschuwingsstrepen (HazardStripesBar & IndustrialHazardBanner): Diagonale 45°-markeringen duiden kritische reken-, RDMA-, model-, WAN- en onderzoeks­zones aan in alle kernweergaven."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nWaarschuwingscomponenten: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Verenigd geheugen & veiligheidsgrens (iogpu.wired_limit_mb)",
                    summary: "Op Apple Silicon delen CPU en GPU hetzelfde fysieke geheugen. Nooit mag 100 % van het werkgeheugen aan AI-modellen worden toegewezen.",
                    bullets: [
                        "Tot 24 GB RAM: Minimaal 4 GB blijft vrij voor macOS en WindowServer (bijv. 16 GB → 12 GB bruikbaar).",
                        "32 GB tot 64 GB RAM: 6 GB blijft gereserveerd voor het besturingssysteem (bijv. 36 GB → 30 GB bruikbaar).",
                        "Vanaf 96 GB RAM (Ultra/Max): 8 GB blijft gereserveerd voor macOS (bijv. 128 GB → 120 GB bruikbaar).",
                        "Vóór het laden controleert SS-CCC de totale behoefte (modelgewichten + KV-cache) ten opzichte van de bruikbare som van alle apparaten."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Voorbeeld voor 36-GB-Mac (30 GB bruikbaar)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Netwerk, Thunderbolt-brug (TB3/4/5) & RDMA (JACCL)",
                    summary: "SS-CCC scheidt besturingsgegevens (LAN/wifi) en model-activeringsdata (Thunderbolt) strikt op twee gescheiden netwerklagen.",
                    bullets: [
                        "Besturingsvlak (LAN/wifi): Bonjour-detectie, API-verzoeken, telemetrie en statusuitwisseling.",
                        "Gegevensvlak (Thunderbolt 3/4/5): Punt-naar-punt-brug in subnet 10.99.1.x met reële 30–37 Gbps (TB4) en tot 90 Gbps (TB5 RDMA).",
                        "Snelle GPU-synchronisatie: MLX_METAL_FAST_SYNCH=1 verlaagt de wachttijd bij laagovergangen van ~180 µs naar ~4 µs (45× sneller).",
                        "RDMA / JACCL: Vanaf Thunderbolt 5 systeemeigen bruikbaar; op Thunderbolt 4 optioneel inschakelbaar."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # of: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Gewogen sharding, modellen laden & multi-modelgebruik",
                    summary: "In plaats van starre gelijke verdeling wijst SS-CCC elke Mac precies het aantal lagen toe dat bij zijn bruikbare geheugen past — en regelt exact wie laadt en hoeveel modellen parallel passen.",
                    bullets: [
                        "Wie laadt het model? Altijd Rang 0 (coördinator met hoogste geheugenbandbreedte) stuurt het shardplan via POST /v1/cluster/plan; elke worker (Rang 1..N) laadt alleen zijn toegewezen laagbereik.",
                        "Hoeveel modellen kunnen tegelijk draaien? Onbeperkt (multi-modelresidentie) zolang som(gewichten + KV-cache) ≤ bruikbaar clustergeheugen (bijv. 1× 70B–405B+ of 2–4× 7B–32B parallel).",
                        "Laagformule & KV-compressie: Lagen_i = Totaallagen × (Bruikbaar_i / Totaal_Bruikbaar); KV-cache naar keuze in FP16 (~16k), 8-bits (~32k) of 4-bits (~64k+ context).",
                        "Gefragmenteerde voorvulling (--prefill-step-size 512) en SSD-KV-offloading (oMLX) voorkomen geheugenpieken bij grote broncodeprojecten."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Installatiegids: Lokaal cluster & Hybride Lokaal + Internet",
                    summary: "Stapsgewijze handleiding voor het opzetten van een lokaal TB/RDMA-cluster en de koppeling met een wereldwijd internet-WAN-netwerk (Tailscale, WireGuard, ZeroTier of libp2p QUIC).",
                    bullets: [
                        "Stap 1 (Lokaal): Thunderbolt-brug (setup_tb_network.sh) en geheugenbeveiliging (setup_wired_limit.sh) op elke lokale Mac instellen; Rang 0 wordt automatisch gekozen.",
                        "Stap 2 (Gateway & Model): Op Rang 0 de FastAPI-gateway (poort 8000) en oMLX/Ollama/llama.cpp starten en het doelmodel laden in de Modelwerkplaats.",
                        "Stap 3 (Internet-WAN): Op externe Macs een versleuteld mesh (Tailscale/WireGuard) inschakelen en in Internetcluster met kamer-ID en uitnodigingstoken deelnemen.",
                        "Stap 4 (Hybride koppeling): In Overzicht → Lokaal + Internet of Internetcluster op ‘Lokaal + Internet koppelen’ klikken — lokale TB-eilanden vormen de snelle Tier-0-kern, WAN-knooppunten nemen extra lagen over."
                    ],
                    codeSample: "WebSocket-chatrelais: ws://127.0.0.1:8000/ws/wan-chat\nKoppeling: Lokaal (TB/RDMA Tier-0) + Internet-WAN -> Hybride supercluster"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Live deelnemerschat & Cluster Audio-Party (spraakchat)",
                    summary: "Direct naast de tekstchat biedt SS-CCC een volwaardige Audio-Party geïnspireerd op console-partykamers, afgestemd op gedistribueerde AI-teams.",
                    bullets: [
                        "Realtime spraakoverdracht: Gebruikt AVAudioEngine (16 kHz PCM16, Opus-compatibel) via het eigen relais-eindpunt /ws/wan-audio.",
                        "Spraakmodi: Schakelbaar tussen Push-to-Talk (spreektoets) en Open-Mic (continu), plus microfoondemping en geluid-uitmodus.",
                        "Deelnemersweergave: Toont actieve sprekers met live niveaumeter, rol van verbonden knooppunten en kamerstatus in realtime.",
                        "Minimaal bandbreedtegebruik: Spraakkanalen gebruiken minder dan 0,02 % van een normale WAN-uplink en verstoren de tensoroverdracht niet."
                    ],
                    codeSample: "WebSocket-audiorelais: ws://127.0.0.1:8000/ws/wan-audio\nAudioformaat: AVAudioEngine 16 kHz PCM16 (Push-to-Talk / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Onderzoekslaboratorium (6 tabbladen) & Geschiedenisopname",
                    summary: "De wetenschappelijke module onderzoekt lokale TB/RDMA-clusters, internet-WAN-clusters en de directe vergelijking tussen beide over zes gespecialiseerde tabbladen.",
                    bullets: [
                        "Tabblad 1–2 (Roofline & WAN): Williams-Roofline (Log-Log), TTFT/TPOT, GPipe-bubbels, Petals/SWARM-compressie, N=1..128 schaling en DiLoCo vs. DDP.",
                        "Tabblad 3–4 (Geheugen & Energie): Transformer-geheugenvergelijking, TokenPowerBench (J/token, EDP), regionale stroommix (gCO₂/1M tokens) en stroomkosten vs. cloud.",
                        "Tabblad 5 (Meetreeksen & Export): N=5/10/20 metingen met p50/p95/p99, 95%-betrouwbaarheidsinterval, SLO-goodput en export naar CSV, JSON, LaTeX (booktabs) en 8-bronnen BibTeX.",
                        "Tabblad 6 (Geschiedenislogboek): Legt meetwaarden automatisch of handmatig per positie of globaal als tijdreeks vast met trendgrafiek en CSV-export."
                    ],
                    codeSample: "Analysebereik: Lokaal (TB/RDMA) | Internet-WAN | Vergelijken\nGeschiedenis: Positie vastleggen | Globaal vastleggen | Auto-opname"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Runtimeservices: MLX, oMLX, Ollama & llama.cpp",
                    summary: "In de Modelwerkplaats kunnen modellen rechtstreeks voor de gewenste lokale service worden gestart, live gedetecteerd of tussen formaten geconverteerd.",
                    bullets: [
                        "oMLX (poort 8000): Systeemeigen macOS MLX-service met SSD KV-cache en zowel OpenAI- als Anthropic-API.",
                        "Ollama (poort 11434): Veelgebruikte service voor lokale GGUF-modellen; aanwezige modellen worden live ingelezen.",
                        "llama.cpp (poort 8080): Directe GGUF-service rechtstreeks via llama-server.",
                        "Live detectie: SS-CCC bevraagt actieve services automatisch en toont draaiende en lokaal gedownloade modellen direct."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPoorten: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI-agenten (1-klik), Menüleiste & Lokale API-eindpunten",
                    summary: "Alle ontwikkeltools benaderen via de lokale interface het volledige cluster — volledig zonder cloudoverdracht van broncode of documenten.",
                    bullets: [
                        "1-klikconfiguratie: Schrijft kant-en-klare configuraties voor OpenCode, Hermes Agent en Google Antigravity vanuit Agenten & IDE's.",
                        "Brede IDE-compatibiliteit: Werkt naadloos samen met Cursor, Continue, Open WebUI en Apple Xcode.",
                        "Menüleist-achtergrondmodus: Minimaliseer naar de bovenste menubalk (⌘⇧M) om het cluster stil op de achtergrond actief te houden voor agenten & IDE's.",
                        "API-console: Ingebouwde liveconsole om prompts, latentie en tokendoorvoer direct te testen."
                    ],
                    codeSample: "OpenAI-eindpunt:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic-eindpunt: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub-updater & automatische CI-versiecontrole",
                    summary: "SS-CCC controleert automatisch de nieuwste programmaversie op GitHub en houdt broncode- en release-installaties eenvoudig up-to-date.",
                    bullets: [
                        "Automatische controle: Vergelijkt bij opstarten en elke 30 minuten (of handmatig via ⌘U) met version.json, GitHub Releases en main-SHA.",
                        "UpdatePromptSheet: Toont nieuwere versies inclusief wijzigingslogboek en commitverschil direct in de app.",
                        "1-klikupdate: Voert git pull + swift build uit en wacht op klik op de knop 'App nu opnieuw starten'.",
                        "CI-versiebeheer: Elke push naar main voert scripts/bump_version.py uit, synchroniseert version.json & ClusterModels.swift en zet tag vX.Y.Z."
                    ],
                    codeSample: "Sneltoetsen: ⌘U (Update check) | ⌘⇧M (Menubalk) | ⌘? (Handleiding)\nManifest: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Opstarten, probleemoplossing & 25-delige testsuite",
                    summary: "Eén enkel commando bouwt de macOS-app en opent het venster; de globale testsuite bewaakt alle functies met 25 geautomatiseerde tests.",
                    bullets: [
                        "App starten: ./scripts/run_ssccc.sh bouwt het Swift-pakket en opent het SS-CCC-venster.",
                        "25/25 globale tests: python3 tests/test_global_suite.py controleert Swift-build, alle 17 talen, menubalkmodus, 3-tabbladenoverzicht, WAN, onderzoekslaboratorium en API's.",
                        "Veelvoorkomende problemen: Bij ontbrekende Thunderbolt-verbinding ./scripts/setup_tb_network.sh opnieuw uitvoeren; bij geheugenwaarschuwingen iogpu.wired_limit_mb controleren.",
                        "17 talen: Start standaard in het Engels en schakelt live tussen DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI en TA."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # Verwacht: Ran 25 tests ... OK"
                )
            ]

        case .af:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Enige Apple Mac met M-verwerker in die kluster (M1–M12+)",
                    summary: "Elke Mac met 'n Apple Silicon-skyfie (M1 tot M12+ — Basis, Pro, Max of Ultra) kan as gelykwaardige rekennodus by die kluster aansluit: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio en Mac Pro.",
                    bullets: [
                        "Toekomsvaste generasie-opsporing: Geheuebandwydte, FP16-TFLOPS en Thunderbolt-generasie word ook vir toekomstige M-skyfies (M7–M12+) outomaties afgelei.",
                        "Outomatiese rangtoewysing: Die Mac met die hoogste geheuedeurvloei (bv. Ultra of Max) neem outomaties Rang 0 (koördineerder) oor.",
                        "Gemengde generasies: 'n MacBook Pro M2 Max werk naatloos saam met 'n Mac mini M4 of 'n Mac Studio M5 Max.",
                        "Alle vormfaktore ondersteun: Werkstasies (Mac Studio, Mac Pro, Mac mini, iMac) en draagbare Macs (MacBook Air/Pro) deel modellae saam."
                    ],
                    codeSample: "Rang 0 = hoogste geheuedeurvloei (GB/s) -> Koördineerder & API-poort\nRang 1..N = werknodusse in geweegde laagverdeling"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-oortjie kluster-oorsig & industriële gevaarstrepe",
                    summary: "Die Kluster-oorsig verdeel die hele rekenkluster oor drie duidelike keuse-oortjies en merk veiligheids-kritiese werkverrigting- en geheuesones met skuins geel-swart waarskuwingstrepe.",
                    bullets: [
                        "Oortjie 1 — Plaaslike kluster: Wys alle plaaslike Thunderbolt-3/4/5- (RDMA/JACCL) en 10GbE-Macs met Rang 0, bruikbare geheuepoel en gesamentlike bandwydte.",
                        "Oortjie 2 — Internetkluster: Stel afgeleë WAN-deelnemers sowel as onderverdeelde streeks- en plaaslike subklusters duidelik voor.",
                        "Oortjie 3 — Plaaslik + Internet: Verenig die plaaslike Thunderbolt-kern en die wêreldwye WAN-netwerk in een gekoppelde hibriede aansig.",
                        "Geel-swart waarskuwingstrepe (HazardStripesBar & IndustrialHazardBanner): Skuins 45°-merkers dui kritiese reken-, RDMA-, model-, WAN- en navorsingssones aan."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nStreepkomponente: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Verenigde geheue & veiligheidsgrens (iogpu.wired_limit_mb)",
                    summary: "Op Apple Silicon deel die CPU en GPU dieselfde fisiese geheuepoel. 100 % van die RAM mag nooit vir KI-modelle vrygestel word nie.",
                    bullets: [
                        "Tot 24 GB RAM: Ten minste 4 GB bly gereserveer vir macOS en WindowServer (bv. 16 GB → 12 GB bruikbaar).",
                        "32 GB tot 64 GB RAM: 6 GB bly beskerm vir die bedryfstelsel (bv. 36 GB → 30 GB bruikbaar).",
                        "Vanaf 96 GB RAM (Ultra/Max): 8 GB bly beskerm vir macOS (bv. 128 GB → 120 GB bruikbaar).",
                        "Voor elke laai kontroleer SS-CCC die totale aanvraag (modelgewigte + KV-kas) teenoor die bruikbare som van alle toestelle."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Voorbeeld vir 36-GB-Mac (30 GB bruikbaar)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Netwerk, Thunderbolt-brug (TB3/4/5) & RDMA (JACCL)",
                    summary: "SS-CCC skei beheervlak-verkeer (LAN/Wi-Fi) en model-aktiveringsdata (Thunderbolt) skoon oor twee vlakke.",
                    bullets: [
                        "Beheervlak (LAN/Wi-Fi): Bonjour-ontdekking, API-versoeke, telemetrie en toestandsuitruiling.",
                        "Datavlak (Thunderbolt 3/4/5): Punt-tot-punt-brug in netwerk 10.99.1.x met werklike 30–37 Gbps (TB4) of tot 90 Gbps (TB5 RDMA).",
                        "Vinnige GPU-sinchronisasie: MLX_METAL_FAST_SYNCH=1 verlaag wagtye by laaggrense van ~180 µs na ~4 µs (45× vinniger).",
                        "RDMA / JACCL: Inheems beskikbaar vanaf Thunderbolt 5; opsioneel op Thunderbolt 4."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # of: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Geweegde skeiding, modelloop & multi-modelmodus",
                    summary: "In plaas van starre gelyke verdeling ken SS-CCC aan elke Mac presies die lae toe wat by sy bruikbare geheue pas — en reël wie laai en hoeveel modelle gelyk pas.",
                    bullets: [
                        "Wie laai die model? Altyd Rang 0 (koördineerder) koördineer die skurfplan via POST /v1/cluster/plan; elke werker (Rang 1..N) laai slegs sy toegekende laagomvang.",
                        "Hoeveel modelle gelyk? Enige aantal (multi-model-residensie) solank som(gewigte + KV-kas) ≤ bruikbare klustergeheue.",
                        "Laagformule & KV-kompressie: Lae_i = TotaleLae × (Bruikbaar_i / Totaal_Bruikbaar); KV-kas in FP16 (~16k), 8-bis (~32k) of 4-bis (~64k+ konteks).",
                        "Verdeelde voorvulling (--prefill-step-size 512) en SSD-KV-aflaaier (oMLX) voorkom geheuepieke by groot kodebasisse."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Opstelgids: Plaaslike kluster & Hibried Plaaslik + Internet",
                    summary: "Stap-vir-stap gids vir die opstel van 'n plaaslike TB/RDMA-kluster en koppeling met 'n wêreldwye internet-WAN-netwerk (Tailscale, WireGuard, ZeroTier of libp2p QUIC).",
                    bullets: [
                        "Stap 1 (Plaaslik): Stel Thunderbolt-brug (setup_tb_network.sh) en geheuebeskerming (setup_wired_limit.sh) op elke Mac op; Rang 0 word outomaties gekies.",
                        "Stap 2 (Poort & Model): Begin FastAPI-poort (8000) en oMLX/Ollama/llama.cpp op Rang 0 en laai die teikenmodel in Modelwerkwinkel.",
                        "Stap 3 (Internet-WAN): Aktiveer geënkripteerde maas (Tailscale/WireGuard) op afgeleë Macs en sluit aan met kamer-ID in Internetkluster.",
                        "Stap 4 (Hibriede koppeling): Klik op ‘Koppel Plaaslik + Internet’ — plaaslike TB-eilande vorm die vinnige Vlak-0-kern terwyl WAN-nodusse oorblywende lae hanteer."
                    ],
                    codeSample: "WebSocket-kletsaflosser: ws://127.0.0.1:8000/ws/wan-chat\nKoppeling: Plaaslik (TB/RDMA Vlak-0) + Internet-WAN -> Hibriede superkluster"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Lewendige deelnemerklets & Kluster Oudio-Partytjie",
                    summary: "Direk langs die teksklets bied SS-CCC 'n volwaardige Oudio-Partytjie geïnspireer deur konsole-partytjiekamers vir verspreide KI-spanne.",
                    bullets: [
                        "Intydse stemoordrag: Gebruik AVAudioEngine (16 kHz PCM16, Opus-versoenbaar) oor /ws/wan-audio.",
                        "Stemmodusse: Skakel tussen Druk-om-te-praat (PTT) en Oop Mikrofoon sowel as demp- en stilmaakmodusse.",
                        "Deelnemer-aansig: Wys aktiewe sprekers met lewendige klankvlakmeter, nodusrolle en kamerstatus intyds.",
                        "Lae bandwydte: Stemkanale gebruik minder as 0,02 % van 'n tipiese WAN-oplaaiskakel."
                    ],
                    codeSample: "WebSocket-oudio-aflosser: ws://127.0.0.1:8000/ws/wan-audio\nOudioformaat: AVAudioEngine 16 kHz PCM16 (PTT / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Navorsingslaboratorium (6 oortjies) & Geskiedenisopname",
                    summary: "Die wetenskaplike afdeling ontleed plaaslike TB/RDMA-klusters, internet-WAN-klusters en direkte vergelykings oor ses spesialisoortjies.",
                    bullets: [
                        "Oortjie 1–2 (Roofline & WAN): Williams-Roofline (Log-Log), TTFT/TPOT, GPipe-borrels, Petals/SWARM-kompressie, N=1..128 skalering en DiLoCo.",
                        "Oortjie 3–4 (Geheue & Energie): Transformator-geheuevergelyking, TokenPowerBench (J/teken, EDP), streekkragmengsel (gCO₂/1M) en kragkoste teenoor wolk.",
                        "Oortjie 5 (Meetreekse & Uitvoer): N=5/10/20 lope met p50/p95/p99, CI95, SLO-goodput en CSV-, JSON-, LaTeX- en 8-bron-BibTeX-uitvoer.",
                        "Oortjie 6 (Geskiedenislogboek): Teken meetwaardes outomaties of handmatig as tydreeks aan met CSV-uitvoer."
                    ],
                    codeSample: "Ontledingsomvang: Plaaslik (TB/RDMA) | Internet-WAN | Vergelyk\nGeskiedenis: Teken posisie aan | Teken globaal aan | Outo-opname"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Looptyddienste: MLX, oMLX, Ollama & llama.cpp",
                    summary: "In Modelwerkwinkel kan modelle direk vir die gekose plaaslike diens begin, lewendig bespeur of tussen formate omgeskakel word.",
                    bullets: [
                        "oMLX (poort 8000): Inheemse macOS MLX-diens met SSD KV-kas en OpenAI-/Anthropic-koppelvlakke.",
                        "Ollama (poort 11434): Gewilde diens vir plaaslike GGUF-modelle; beskikbare modelle word lewendig gelaai.",
                        "llama.cpp (poort 8080): Direkte GGUF-bediener oor llama-server.",
                        "Lewendige ontdekking: SS-CCC ondersoek aktiewe dienste outomaties en wys dadelik alle gereed modelle."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPoorte: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. KI-agente (1-klik), Kieslysbalk & Plaaslike API's",
                    summary: "Alle ontwikkelhulpmiddels kry toegang tot die hele kluster oor die plaaslike koppelvlak — sonder wolk-oordrag van bronkode.",
                    bullets: [
                        "1-klik opstelling: Skryf klaargemaakte konfigurasies vir OpenCode, Hermes Agent en Google Antigravity.",
                        "Wye IDE-ondersteuning: Werk naatloos met Cursor, Continue, Open WebUI en Apple Xcode.",
                        "Kieslysbalk-agtergrondmodus: Minimaliseer na die boonste kieslysbalk (⌘⇧M) sodat SS-CCC stil as diensverskaffer in die agtergrond aanhou werk.",
                        "API-konsole: Ingeboude toetskonsole vir aanwysings, latensie en tokendeurvloei."
                    ],
                    codeSample: "OpenAI-eindpunt:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic-eindpunt: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub-opdateerder & outomatiese CI-weergawebeheer",
                    summary: "SS-CCC monitor outomaties die nuutste programweergawe op GitHub en hou bronkode- en vrystellinginstallasies op datum.",
                    bullets: [
                        "Outomatiese kontrole: Vergelyk by begin en elke 30 minute (of met ⌘U) teen version.json, GitHub Releases en main-SHA.",
                        "UpdatePromptSheet: Wys veranderingslogboek en commit-verskille direk in die program.",
                        "1-klik opdatering: Voer git pull + swift build uit en wag totdat die gebruiker op 'Herbegin program nou' klik.",
                        "CI-weergawebeheer: Elke stoot na main laat scripts/bump_version.py loop en skep merker vX.Y.Z."
                    ],
                    codeSample: "Kortpaaie: ⌘U (Soek opdaterings) | ⌘⇧M (Kieslysbalk) | ⌘? (Handleiding)\nManifes: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Begin, foutsporing & 25-delige toetspakket",
                    summary: "Een opdrag kompileer die macOS-toepassing en maak die venster oop; 25 globale toetse verifieer elke module.",
                    bullets: [
                        "Begin program: ./scripts/run_ssccc.sh bou die Swift-pakket en maak die SS-CCC-venster oop.",
                        "25/25 globale toetse: python3 tests/test_global_suite.py verifieer Swift-bou, 17 tale, kieslysbalkmodus, 3-oortjie-oorsig, WAN en API's.",
                        "Algemene probleme: Indien Thunderbolt ontbreek, voer ./scripts/setup_tb_network.sh weer uit; kontroleer iogpu.wired_limit_mb vir geheuewaarskuwings.",
                        "17 tale: Begin in Engels en wissel regstreeks tussen DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI en TA."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # Verwag: Ran 25 tests ... OK"
                )
            ]

        case .pl:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Dowolny Apple Mac z procesorem serii M w klastrze (M1–M12+)",
                    summary: "Każdy komputer Mac z układem Apple Silicon (od M1 do M12+ — wersje Base, Pro, Max lub Ultra) może dołączyć do klastra jako pełnoprawny węzeł obliczeniowy: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio oraz Mac Pro.",
                    bullets: [
                        "Przyszłościowe wykrywanie generacji: Przepustowość pamięci, moc FP16 TFLOPS i klasa Thunderbolt są automatycznie wyznaczane także dla przyszłych układów M7–M12+.",
                        "Automatyczne nadawanie rang: Mac o najwyższej przepustowości pamięci (np. Ultra lub Max) automatycznie obejmuje Rangę 0 (koordynator).",
                        "Mieszane generacje: MacBook Pro M2 Max bezproblemowo współpracuje z Maciem mini M4 lub Mac Studio M5 Max.",
                        "Wszystkie obudowy wspierane: Stacjonarne stacje robocze i mobilne MacBooki wspólnie dzielą warstwy modeli."
                    ],
                    codeSample: "Ranga 0 = najwyższa przepustowość pamięci (GB/s) -> Koordynator i brama API\nRanga 1..N = węzły robocze w ważonym podziale warstw"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-kartowy przegląd klastra i przemysłowe pasy ostrzegawcze",
                    summary: "Przegląd klastra dzieli cały klaster obliczeniowy na trzy przejrzyste karty zakresu i oznacza krytyczne strefy mocy oraz pamięci ukośnymi żółto-czarnymi pasami ostrzegawczymi.",
                    bullets: [
                        "Karta 1 — Klaster lokalny: Wyświetla wszystkie lokalne komputery Thunderbolt 3/4/5 (RDMA/JACCL) i 10GbE wraz z Rangą 0, użyteczną pulą pamięci oraz łączną przepustowością.",
                        "Karta 2 — Klaster internetowy: Przejrzyście prezentuje zdalnych uczestników WAN oraz podzielone podklastry regionalne i lokalne.",
                        "Karta 3 — Lokalnie + Internet: Łączy lokalny rdzeń Thunderbolt i globalną sieć WAN w jednym sprzężonym widoku hybrydowym.",
                        "Żółto-czarne pasy ostrzegawcze (HazardStripesBar i IndustrialHazardBanner): Oznaczenia pod kątem 45° wskazują krytyczne strefy obliczeniowe, RDMA, modeli i WAN."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nKomponenty ostrzegawcze: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Zunifikowana pamięć i limit bezpieczeństwa (iogpu.wired_limit_mb)",
                    summary: "W układach Apple Silicon CPU i GPU dzielą tę samą pamięć fizyczną. Nigdy nie wolno przydzielać 100 % pamięci RAM dla modeli AI.",
                    bullets: [
                        "Do 24 GB RAM: Co najmniej 4 GB pozostają zarezerwowane dla macOS i WindowServer (np. 16 GB → 12 GB użyteczne).",
                        "Od 32 GB do 64 GB RAM: 6 GB pozostaje chronione dla systemu operacyjnego (np. 36 GB → 30 GB użyteczne).",
                        "Od 96 GB RAM (Ultra/Max): 8 GB pozostaje chronione dla macOS (np. 128 GB → 120 GB użyteczne).",
                        "Przed załadowaniem SS-CCC sprawdza łączne zapotrzebowanie (wagi modelu + pamięć KV) wobec użytecznej sumy wszystkich urządzeń."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Przykład dla Maca 36 GB (30 GB użyteczne)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Sieć, mostek Thunderbolt (TB3/4/5) i RDMA (JACCL)",
                    summary: "SS-CCC wyraźnie rozdziela dane sterowania (LAN/Wi-Fi) oraz tensory aktywacji modeli (Thunderbolt) na dwie warstwy.",
                    bullets: [
                        "Płaszczyzna sterowania (LAN/Wi-Fi): Wykrywanie Bonjour, zapytania API, telemetria i wymiana stanu.",
                        "Płaszczyzna danych (Thunderbolt 3/4/5): Mostek punkt-punkt w sieci 10.99.1.x osiągający realnie 30–37 Gbps (TB4) oraz do 90 Gbps (TB5 RDMA).",
                        "Szybka synchronizacja GPU: MLX_METAL_FAST_SYNCH=1 skraca czas oczekiwania na granicach warstw z ~180 µs do ~4 µs (45× szybciej).",
                        "RDMA / JACCL: Dostępne natywnie od Thunderbolt 5; opcjonalnie włączane na Thunderbolt 4."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # lub: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Podział ważony, ładowanie modeli i tryb wielomodelowy",
                    summary: "Zamiast sztywnego podziału po równo SS-CCC przydziela każdemu Macowi dokładnie tyle warstw, ile odpowiada jego użytecznej pamięci — oraz zarządza równoległym ładowaniem wielu modeli.",
                    bullets: [
                        "Kto ładuje model? Zawsze Ranga 0 koordynuje plan podziału przez POST /v1/cluster/plan; każdy Worker (Ranga 1..N) ładuje tylko swój zakres warstw.",
                        "Ile modeli naraz? Dowolna liczba, dopóki suma(wag + KV Cache) ≤ użytecznej pamięci klastra (np. 1× 70B–405B+ lub 2–4× 7B–32B równolegle).",
                        "Wzór na warstwy i kwantyzacja KV: Warstwy_i = SumaWarstw × (Użyteczne_i / Suma_Użyteczne); pamięć KV w FP16 (~16k), 8-bit (~32k) lub 4-bit (~64k+ kontekstu).",
                        "Krokowe wstępne wypełnianie (--prefill-step-size 512) i zrzut KV na SSD (oMLX) zapobiegają skokom zużycia pamięci."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Instrukcja konfiguracji: Klaster lokalny i Hybryda Lokalnie + Internet",
                    summary: "Przewodnik krok po kroku do uruchomienia lokalnego klastra TB/RDMA i połączenia go z globalną siecią Internet WAN (Tailscale, WireGuard, ZeroTier lub libp2p QUIC).",
                    bullets: [
                        "Krok 1 (Lokalnie): Skonfiguruj mostek Thunderbolt (setup_tb_network.sh) i ochronę pamięci (setup_wired_limit.sh) na każdym lokalnym Macu; Ranga 0 wybierana automatycznie.",
                        "Krok 2 (Bramka i Model): Uruchom bramkę FastAPI (port 8000) oraz oMLX/Ollama/llama.cpp na Randze 0 i załaduj model w Warsztacie modeli.",
                        "Krok 3 (Internet WAN): Włącz szyfrowaną sieć Mesh (Tailscale/WireGuard) na zdalnych Macach i dołącz podając ID pokoju w Klastrze internetowym.",
                        "Krok 4 (Łączenie hybrydowe): Kliknij „Połącz Lokalnie + Internet” — lokalne wyspy TB tworzą szybki rdzeń Tier-0, a węzły WAN przejmują pozostałe warstwy."
                    ],
                    codeSample: "Przekaźnik czatu WebSocket: ws://127.0.0.1:8000/ws/wan-chat\nSprzężenie: Lokalnie (TB/RDMA Tier-0) + Internet WAN -> Superklaster hybrydowy"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Czat uczestników na żywo i Klaster Audio-Party (czat głosowy)",
                    summary: "Tuż obok czatu tekstowego SS-CCC oferuje pełnoprawne Audio-Party wzorowane na czatach konsolowych, stworzone dla rozproszonych zespołów AI.",
                    bullets: [
                        "Dźwięk w czasie rzeczywistym: Wykorzystuje AVAudioEngine (16 kHz PCM16, zgodny z Opus) przez własny punkt przekaźnikowy /ws/wan-audio.",
                        "Tryby głosowe: Przełączane między Naciśnij i mów (PTT) a Otwartym mikrofonem oraz wyciszaniem mikrofonu i dźwięku.",
                        "Podgląd uczestników: Wyświetla aktywnych mówców ze wskaźnikiem poziomu na żywo, rolą węzła i statusem pokoju.",
                        "Minimalne zużycie pasma: Kanał głosowy zajmuje poniżej 0,02 % typowego łącza wysyłającego WAN."
                    ],
                    codeSample: "Przekaźnik audio WebSocket: ws://127.0.0.1:8000/ws/wan-audio\nFormat audio: AVAudioEngine 16 kHz PCM16 (PTT / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Laboratorium badawcze (6 kart) i Dziennik historii",
                    summary: "Sekcja naukowa analizuje klastry lokalne TB/RDMA, klastry Internet WAN oraz bezpośrednie porównania na sześciu specjalistycznych kartach.",
                    bullets: [
                        "Karty 1–2 (Roofline i WAN): Model Williams-Roofline (Log-Log), TTFT/TPOT, bąbel GPipe, kompresja Petals/SWARM, skalowanie N=1..128 i DiLoCo.",
                        "Karty 3–4 (Pamięć i Energia): Równanie pamięci Transformera, TokenPowerBench (J/token, EDP), regionalny miks energii (gCO₂/1M) i koszt vs. chmura.",
                        "Karta 5 (Pomiary i Eksport): Serie N=5/10/20 z p50/p95/p99, CI95, SLO-goodput oraz eksportem do CSV, JSON, LaTeX (booktabs) i BibTeX (8 prac).",
                        "Karta 6 (Historia): Automatycznie lub ręcznie zapisuje przebiegi dla pojedynczych pozycji i globalnie z wykresem trendu i eksportem CSV."
                    ],
                    codeSample: "Zakresy analizy: Lokalnie (TB/RDMA) | Internet WAN | Porównanie\nHistoria: Zapisz pozycję | Zapisz globalnie | Autozapis"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Usługi uruchomieniowe: MLX, oMLX, Ollama i llama.cpp",
                    summary: "W Warsztacie modeli można uruchamiać modele bezpośrednio dla wybranej usługi lokalnej, wykrywać je na żywo lub konwertować między formatami.",
                    bullets: [
                        "oMLX (port 8000): Natywny serwer macOS MLX z pamięcią podręczną KV na SSD oraz API OpenAI i Anthropic.",
                        "Ollama (port 11434): Popularna usługa dla lokalnych modeli GGUF; obecne modele są wczytywane na żywo.",
                        "llama.cpp (port 8080): Bezpośrednia usługa GGUF przez llama-server.",
                        "Wykrywanie na żywo: SS-CCC automatycznie odpytuje działające usługi i od razu pokazuje dostępne modele."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPorty: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. Agenci AI (1 kliknięcie), Pasek menu i Lokalne API",
                    summary: "Wszystkie narzędzia programistyczne łączą się z klastrem przez lokalny interfejs — bez wysyłania kodu źródłowego ani dokumentów do chmury.",
                    bullets: [
                        "Konfiguracja 1 kliknięciem: Tworzy gotowe pliki dla OpenCode, Hermes Agent i Google Antigravity z karty Agenci i IDE.",
                        "Szeroka obsługa IDE: Bezproblemowo współpracuje z Cursor, Continue, Open WebUI i Apple Xcode.",
                        "Tryb paska menu w tle: Zminimalizuj do górnego paska menu (⌘⇧M), aby klaster dyskretnie w tle obsługiwał agentów i IDE jak Ollama.",
                        "Konsola API: Wbudowana konsola na żywo do testowania zapytań, opóźnień i przepustowości."
                    ],
                    codeSample: "Punkt końcowy OpenAI:    http://127.0.0.1:8000/v1/chat/completions\nPunkt końcowy Anthropic: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. Aktualizator GitHub i automatyczna kontrola wersji CI",
                    summary: "SS-CCC automatycznie sprawdza aktualną wersję programu na GitHubie i dba o aktualność instalacji źródłowych oraz wydań.",
                    bullets: [
                        "Automatyczne sprawdzanie: Porównuje przy starcie i co 30 minut (lub skrótem ⌘U) z version.json, GitHub Releases i SHA gałęzi main.",
                        "UpdatePromptSheet: Wyświetla listę zmian oraz różnice commitów bezpośrednio w aplikacji.",
                        "Aktualizacja 1 kliknięciem: Wykonuje git pull + swift build i czeka na kliknięcie przycisku 'Uruchom ponownie aplikację teraz'.",
                        "Kontrola wersji CI: Każdy push na main uruchamia scripts/bump_version.py i tworzy tag vX.Y.Z."
                    ],
                    codeSample: "Skróty: ⌘U (Aktualizacje) | ⌘⇧M (Pasek menu) | ⌘? (Podręcznik)\nManifest: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Uruchamianie, rozwiązywanie problemów i 25 testów globalnych",
                    summary: "Jedno polecenie kompiluje aplikację macOS i otwiera okno; globalny zestaw testów weryfikuje wszystkie funkcje za pomocą 25 automatycznych sprawdzeń.",
                    bullets: [
                        "Uruchomienie aplikacji: ./scripts/run_ssccc.sh kompiluje pakiet Swift i otwiera okno SS-CCC.",
                        "25/25 testów globalnych: python3 tests/test_global_suite.py sprawdza kompilację Swift, 17 języków, tryb paska menu, 3-kartowy przegląd, WAN, laboratorium i API.",
                        "Rozwiązywanie problemów: W razie braku łącza Thunderbolt uruchom ponownie ./scripts/setup_tb_network.sh; przy ostrzeżeniach pamięci sprawdź iogpu.wired_limit_mb.",
                        "17 języków interfejsu: Domyślnie startuje po angielsku z przełączaniem na żywo między DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI i TA."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # Oczekiwano: Ran 25 tests ... OK"
                )
            ]

        case .cs:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Libovolný Apple Mac s čipem řady M v clusteru (M1–M12+)",
                    summary: "Každý Mac s čipem Apple Silicon (M1 až M12+ — Base, Pro, Max nebo Ultra) se může zapojit do clusteru jako rovnocenný výpočetní uzel: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio i Mac Pro.",
                    bullets: [
                        "Budoucí detekce generací: Propustnost paměti, FP16 TFLOPS a generace Thunderbolt jsou automaticky odvozeny i pro budoucí čipy M7–M12+.",
                        "Automatické přiřazení pořadí: Mac s nejvyšší propustností paměti (např. Ultra nebo Max) automaticky přebírá Pořadí 0 (koordinátor).",
                        "Smíšené generace: MacBook Pro M2 Max plynule spolupracuje s Macem mini M4 nebo Mac Studio M5 Max.",
                        "Podpora všech modelů: Stolní pracovní stanice i přenosné Macy společně sdílejí vrstvy modelů."
                    ],
                    codeSample: "Pořadí 0 = nejvyšší propustnost paměti (GB/s) -> Koordinátor & brána API\nPořadí 1..N = podřízené uzly ve váženém rozdělení vrstev"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. Přehled clusteru se 3 kartami a průmyslovým výstražným značením",
                    summary: "Přehled clusteru rozděluje celý výpočetní cluster na tři jasně oddělené karty a kritické zóny výkonu a paměti označuje šikmými žlutočernými výstražnými pruhy.",
                    bullets: [
                        "Karta 1 — Lokální cluster: Zobrazuje všechny místní Macy Thunderbolt 3/4/5 (RDMA/JACCL) a 10GbE včetně Pořadí 0, využitelného fondu paměti a agregované šířky pásma.",
                        "Karta 2 — Internetový cluster: Přehledně zobrazuje vzdálené WAN účastníky i členěné regionální a místní podclustery.",
                        "Karta 3 — Lokální + Internet: Spojuje místní jádro Thunderbolt a globální síť WAN do jednoho propojeného hybridního pohledu.",
                        "Žlutočerné výstražné pruhy (HazardStripesBar & IndustrialHazardBanner): Šikmé pruhy pod úhlem 45° označují kritické výpočetní, RDMA, modelové a WAN zóny."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nVýstražné prvky: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Sjednocená paměť a ochranný limit (iogpu.wired_limit_mb)",
                    summary: "Na čipech Apple Silicon sdílejí CPU a GPU tutéž fyzickou paměť. Pro modely AI nesmí být nikdy uvolněno 100 % paměti RAM.",
                    bullets: [
                        "Do 24 GB RAM: Minimálně 4 GB zůstávají vyhrazeny pro macOS a WindowServer (např. 16 GB → 12 GB využitelných).",
                        "32 GB až 64 GB RAM: 6 GB zůstává chráněno pro operační systém (např. 36 GB → 30 GB využitelných).",
                        "Od 96 GB RAM (Ultra/Max): 8 GB zůstává chráněno pro macOS (např. 128 GB → 120 GB využitelných).",
                        "Před každým načtením SS-CCC ověří celkovou potřebu (váhy modelu + KV cache) vůči využitelnému součtu všech zařízení."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Příklad pro 36 GB Mac (30 GB využitelných)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Síť, most Thunderbolt (TB3/4/5) a RDMA (JACCL)",
                    summary: "SS-CCC čistě odděluje řídicí provoz (LAN/Wi-Fi) a přenosy aktivačních dat modelů (Thunderbolt) ve dvou rovinách.",
                    bullets: [
                        "Řídicí rovina (LAN/Wi-Fi): Vyhledávání Bonjour, požadavky API, telemetrie a výměna stavů.",
                        "Datová rovina (Thunderbolt 3/4/5): Point-to-point most v síti 10.99.1.x s reálnou rychlostí 30–37 Gbps (TB4) až 90 Gbps (TB5 RDMA).",
                        "Rychlá synchronizace GPU: MLX_METAL_FAST_SYNCH=1 zkracuje čekání na hranicích vrstev z ~180 µs na ~4 µs (45× rychlejší).",
                        "RDMA / JACCL: Nativně od Thunderbolt 5; na Thunderbolt 4 volitelně aktivovatelné."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # nebo: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Vážené dělení, načítání modelů a více-modelový režim",
                    summary: "Místo pevného rovného dělení přiřadí SS-CCC každému Macu přesně tolik vrstev, kolik odpovídá jeho využitelné paměti — a řídí paralelní běh více modelů.",
                    bullets: [
                        "Kdo načítá model? Vždy Pořadí 0 koordinuje plán přes POST /v1/cluster/plan; každý Worker (Pořadí 1..N) načte jen svůj rozsah vrstev.",
                        "Kolik modelů najednou? Libovolně mnoho, dokud součet(váhy + KV cache) ≤ využitelná paměť clusteru (např. 1× 70B–405B+ nebo 2–4× 7B–32B paralelně).",
                        "Vzorec vrstev a kvantizace KV: Vrstvy_i = CelkemVrstev × (Využitelné_i / Celkem_Využitelné); KV cache ve FP16 (~16k), 8-bit (~32k) nebo 4-bit (~64k+ kontextu).",
                        "Dávkový prefill (--prefill-step-size 512) a odkládání KV na SSD (oMLX) brání paměťovým špičkám."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Návod k sestavení: Lokální cluster a Hybrid Lokální + Internet",
                    summary: "Podrobný průvodce nastavením místního clusteru TB/RDMA a jeho propojením s globální sítí Internet WAN (Tailscale, WireGuard, ZeroTier nebo libp2p QUIC).",
                    bullets: [
                        "Krok 1 (Lokálně): Nastavte most Thunderbolt (setup_tb_network.sh) a ochranu paměti (setup_wired_limit.sh) na každém místním Macu; Pořadí 0 se zvolí automaticky.",
                        "Krok 2 (Brána a Model): Spusťte FastAPI bránu (port 8000) a oMLX/Ollama/llama.cpp na Pořadí 0 a načtěte model v Dílně modelů.",
                        "Krok 3 (Internet WAN): Aktivujte šifrovanou síť (Tailscale/WireGuard) na vzdálených Macích a připojte se kódem místnosti v Internetovém clusteru.",
                        "Krok 4 (Hybridní propojení): Klikněte na ‚Propojit Lokální + Internet‘ — místní TB ostrovy tvoří rychlé jádro Tier-0, uzly WAN přebírají zbývající vrstvy."
                    ],
                    codeSample: "WebSocket přenašeč chatu: ws://127.0.0.1:8000/ws/wan-chat\nPropojení: Lokální (TB/RDMA Tier-0) + Internet WAN -> Hybridní supercluster"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Živý chat účastníků a Cluster Audio-Party (hlasový chat)",
                    summary: "Hned vedle textového chatu nabízí SS-CCC plnohodnotnou Audio-Party po vzoru konzolových party místností pro distribuované AI týmy.",
                    bullets: [
                        "Hlas v reálném čase: Využívá AVAudioEngine (16 kHz PCM16, kompatibilní s Opus) přes vlastní endpoint /ws/wan-audio.",
                        "Hlasové režimy: Přepínání mezi Stiskni a mluv (PTT) a Otevřeným mikrofonem i ztlumením.",
                        "Přehled účastníků: Zobrazuje aktivní mluvčí se živým ukazatelem úrovně, rolí uzlu a stavem místnosti.",
                        "Minimální šířka pásma: Hlasový kanál spotřebuje méně než 0,02 % běžného WAN uplinku."
                    ],
                    codeSample: "WebSocket audio přenašeč: ws://127.0.0.1:8000/ws/wan-audio\nFormát audia: AVAudioEngine 16 kHz PCM16 (PTT / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Vědecká laboratoř (6 karet) a Záznam historie",
                    summary: "Vědecká část analyzuje místní TB/RDMA clustery, internetové WAN clustery i jejich přímé srovnání na šesti odborných kartách.",
                    bullets: [
                        "Karty 1–2 (Roofline & WAN): Williams-Roofline (Log-Log), TTFT/TPOT, bublina GPipe, komprese Petals/SWARM, škálování N=1..128 a DiLoCo.",
                        "Karty 3–4 (Paměť & Energie): Paměťová rovnice Transformeru, TokenPowerBench (J/token, EDP), regionální mix elektřiny (gCO₂/1M) a srovnání s cloudem.",
                        "Karta 5 (Měření & Export): Série N=5/10/20 s p50/p95/p99, CI95, SLO-goodput a export do CSV, JSON, LaTeX (booktabs) a BibTeX.",
                        "Karta 6 (Historie): Automaticky nebo ručně zaznamenává časové řady pro jednotlivé pozice i globálně včetně grafu trendu a CSV exportu."
                    ],
                    codeSample: "Rozsah analýzy: Místní (TB/RDMA) | Internet WAN | Srovnání\nHistorie: Zaznamenat pozici | Zaznamenat globálně | Auto-záznam"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Běhové služby: MLX, oMLX, Ollama a llama.cpp",
                    summary: "V Dílně modelů lze modely přímo spouštět pro vybranou místní službu, živě je detekovat nebo převádět mezi formáty.",
                    bullets: [
                        "oMLX (port 8000): Nativní macOS služba MLX s SSD KV mezipamětí a rozhraním OpenAI i Anthropic.",
                        "Ollama (port 11434): Rozšířená služba pro místní modely GGUF; dostupné modely se načítají živě.",
                        "llama.cpp (port 8080): Přímá služba GGUF přes llama-server.",
                        "Živé vyhledávání: SS-CCC automaticky dotazuje běžící služby a ihned zobrazuje dostupné modely."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPorty: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI agenti (1 kliknutí), Řádek nabídek a Místní API",
                    summary: "Všechny vývojářské nástroje využívají celý cluster přes místní rozhraní — zcela bez odesílání zdrojového kódu do cloudu.",
                    bullets: [
                        "Nastavení 1 kliknutím: Zapíše hotové konfigurace pro OpenCode, Hermes Agent a Google Antigravity z karty Agenti a IDE.",
                        "Široká podpora IDE: Funguje bezproblémově s Cursor, Continue, Open WebUI a Apple Xcode.",
                        "Režim na pozadí v řádku nabídek: Minimalizujte do horního řádku nabídek (⌘⇧M), aby cluster tiše na pozadí obsluhoval agenty a IDE stejně jako Ollama.",
                        "API konzole: Integrovaná živá konzole pro přímé testování výzev, latence a propustnosti."
                    ],
                    codeSample: "Koncový bod OpenAI:    http://127.0.0.1:8000/v1/chat/completions\nKoncový bod Anthropic: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. Aktualizátor GitHub a automatická kontrola verzí CI",
                    summary: "SS-CCC automaticky sleduje nejnovější verzi programu na GitHubu a udržuje zdrojové i vydané instalace aktuální.",
                    bullets: [
                        "Automatická kontrola: Porovnává při spuštění a každých 30 minut (nebo zkratkou ⌘U) oproti version.json, GitHub Releases a main SHA.",
                        "UpdatePromptSheet: Zobrazuje seznam změn i rozdíly revizí přímo v aplikaci.",
                        "Aktualizace 1 kliknutím: Spustí git pull + swift build a vyčká na kliknutí na tlačítko 'Restartovat aplikaci nyní'.",
                        "Správa verzí CI: Každý push na main spustí scripts/bump_version.py a nastaví značku vX.Y.Z."
                    ],
                    codeSample: "Zkratky: ⌘U (Aktualizace) | ⌘⇧M (Řádek nabídek) | ⌘? (Příručka)\nManifest: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Spuštění, řešení potíží a 25dílná sada testů",
                    summary: "Jediný příkaz zkompiluje aplikaci macOS a otevře okno; globální sada ověřuje všechny funkce pomocí 25 automatických testů.",
                    bullets: [
                        "Spuštění aplikace: ./scripts/run_ssccc.sh sestaví balíček Swift a otevře okno SS-CCC.",
                        "25/25 globálních testů: python3 tests/test_global_suite.py ověřuje sestavení Swift, 17 jazyků, režim řádku nabídek, 3kartový přehled, WAN a API.",
                        "Řešení potíží: Pokud chybí spojení Thunderbolt, spusťte znovu ./scripts/setup_tb_network.sh; při varování paměti zkontrolujte iogpu.wired_limit_mb.",
                        "17 jazyků rozhraní: Výchozí start v angličtině s okamžitým přepínáním mezi DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI a TA."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # Očekáváno: Ran 25 tests ... OK"
                )
            ]

        case .sk:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Akýkoľvek Apple Mac s procesorom radu M v klastri (M1–M12+)",
                    summary: "Každý Mac s čipom Apple Silicon (M1 až M12+ — Base, Pro, Max alebo Ultra) sa môže zapojiť do klastra ako rovnocenný výpočtový uzol: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio aj Mac Pro.",
                    bullets: [
                        "Budúca detekcia generácií: Priepustnosť pamäte, FP16 TFLOPS a generácia Thunderbolt sa automaticky odvodia aj pre budúce čipy M7–M12+.",
                        "Automatické prideľovanie poradia: Mac s najvyššou priepustnosťou pamäte (napr. Ultra alebo Max) automaticky preberá Poradie 0 (koordinátor).",
                        "Zmiešané generácie: MacBook Pro M2 Max plynulo spolupracuje s Macom mini M4 alebo Mac Studio M5 Max.",
                        "Podpora všetkých modelov: Stolné pracovné stanice aj prenosné Macy spoločne zdieľajú vrstvy modelov."
                    ],
                    codeSample: "Poradie 0 = najvyššia priepustnosť pamäte (GB/s) -> Koordinátor & brána API\nPoradie 1..N = podriadené uzly vo váženom delení vrstiev"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. Prehľad klastra s 3 kartami a priemyselným výstražným značením",
                    summary: "Prehľad klastra rozdeľuje celý výpočtový klaster do troch jasne oddelených kariet a kritické zóny výkonu a pamäte označuje šikmými žltočiernymi výstražnými pruhmi.",
                    bullets: [
                        "Karta 1 — Lokálny klaster: Zobrazuje všetky miestne Macy Thunderbolt 3/4/5 (RDMA/JACCL) a 10GbE vrátane Poradia 0, využiteľného fondu pamäte a agregovanej šírky pásma.",
                        "Karta 2 — Internetový klaster: Prehľadne zobrazuje vzdialených WAN účastníkov aj členené regionálne a miestne podklastre.",
                        "Karta 3 — Lokálne + Internet: Spája miestne jadro Thunderbolt a globálnu sieť WAN do jedného prepojeného hybridného pohľadu.",
                        "Žltočierne výstražné pruhy (HazardStripesBar & IndustrialHazardBanner): Šikmé pruhy pod uhlom 45° označujú kritické výpočtové, RDMA, modelové a WAN zóny."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nVýstražné prvky: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Zjednotená pamäť a ochranný limit (iogpu.wired_limit_mb)",
                    summary: "Na čipoch Apple Silicon zdieľajú CPU a GPU tú istú fyzickú pamäť. Pre modely AI nesmie byť nikdy uvoľnených 100 % pamäte RAM.",
                    bullets: [
                        "Do 24 GB RAM: Minimálne 4 GB zostávajú vyhradené pre macOS a WindowServer (napr. 16 GB → 12 GB využiteľných).",
                        "32 GB až 64 GB RAM: 6 GB zostáva chránených pre operačný systém (napr. 36 GB → 30 GB využiteľných).",
                        "Od 96 GB RAM (Ultra/Max): 8 GB zostáva chránených pre macOS (napr. 128 GB → 120 GB využiteľných).",
                        "Pred každým načítaním SS-CCC overí celkovú potrebu (váhy modelu + KV cache) voči využiteľnému súčtu všetkých zariadení."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Príklad pre 36 GB Mac (30 GB využiteľných)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Sieť, most Thunderbolt (TB3/4/5) a RDMA (JACCL)",
                    summary: "SS-CCC čisto oddeľuje riadiacu prevádzku (LAN/Wi-Fi) a prenosy aktivačných dát modelov (Thunderbolt) v dvoch rovinách.",
                    bullets: [
                        "Riadiaca rovina (LAN/Wi-Fi): Vyhľadávanie Bonjour, požiadavky API, telemetria a výmena stavov.",
                        "Dátová rovina (Thunderbolt 3/4/5): Point-to-point most v sieti 10.99.1.x s reálnou rýchlosťou 30–37 Gbps (TB4) až 90 Gbps (TB5 RDMA).",
                        "Rýchla synchronizácia GPU: MLX_METAL_FAST_SYNCH=1 skracuje čakanie na hraniciach vrstiev z ~180 µs na ~4 µs (45× rýchlejšie).",
                        "RDMA / JACCL: Natívne od Thunderbolt 5; na Thunderbolt 4 voliteľne aktivovateľné."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # alebo: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Vážené delenie, načítanie modelov a viacmodelový režim",
                    summary: "Namiesto pevného rovného delenia priradí SS-CCC každému Macu presne toľko vrstiev, koľko zodpovedá jeho využiteľnej pamäti — a riadi paralelný beh viacerých modelov.",
                    bullets: [
                        "Kto načítava model? Vždy Poradie 0 koordinuje plán cez POST /v1/cluster/plan; každý Worker (Poradie 1..N) načíta len svoj rozsah vrstiev.",
                        "Koľko modelov naraz? Ľubovoľne veľa, pokiaľ súčet(váhy + KV cache) ≤ využiteľná pamäť klastra.",
                        "Vzorec vrstiev a kvantizácia KV: Vrstvy_i = CelkomVrstiev × (Využiteľné_i / Celkom_Využiteľné); KV cache vo FP16 (~16k), 8-bit (~32k) alebo 4-bit (~64k+ kontextu).",
                        "Dávkový prefill (--prefill-step-size 512) a odkladanie KV na SSD (oMLX) bránia pamäťovým špičkám."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Návod na zostavenie: Lokálny klaster a Hybrid Lokálne + Internet",
                    summary: "Podrobný sprievodca nastavením miestneho klastra TB/RDMA a jeho prepojením s globálnou sieťou Internet WAN (Tailscale, WireGuard, ZeroTier alebo libp2p QUIC).",
                    bullets: [
                        "Krok 1 (Lokálne): Nastavte most Thunderbolt (setup_tb_network.sh) a ochranu pamäte (setup_wired_limit.sh) na každom miestnom Macu; Poradie 0 sa zvolí automaticky.",
                        "Krok 2 (Brána a Model): Spustite FastAPI bránu (port 8000) a oMLX/Ollama/llama.cpp na Poradí 0 a načítajte model v Dielni modelov.",
                        "Krok 3 (Internet WAN): Aktivujte šifrovanú sieť (Tailscale/WireGuard) na vzdialených Macoch a pripojte sa kódom miestnosti v Internetovom klastri.",
                        "Krok 4 (Hybridné prepojenie): Kliknite na ‚Prepojiť Lokálne + Internet‘ — miestne TB ostrovy tvoria rýchle jadro Tier-0, uzly WAN preberajú zvyšné vrstvy."
                    ],
                    codeSample: "WebSocket prenášač četu: ws://127.0.0.1:8000/ws/wan-chat\nPrepojenie: Lokálne (TB/RDMA Tier-0) + Internet WAN -> Hybridný superklaster"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Živý čet účastníkov a Cluster Audio-Party (hlasový čet)",
                    summary: "Hneď vedľa textového četu ponúka SS-CCC plnohodnotnú Audio-Party podľa vzoru konzolových party miestností pre distribuované AI tímy.",
                    bullets: [
                        "Hlas v reálnom čase: Využíva AVAudioEngine (16 kHz PCM16, kompatibilný s Opus) cez vlastný endpoint /ws/wan-audio.",
                        "Hlasové režimy: Prepínanie medzi Stlač a hovor (PTT) a Otvoreným mikrofónom vrátane stlmenia.",
                        "Prehľad účastníkov: Zobrazuje aktívnych rečníkov so živým ukazovateľom úrovne, rolou uzla a stavom miestnosti.",
                        "Minimálna šírka pásma: Hlasový kanál spotrebuje menej než 0,02 % bežného WAN uplinku."
                    ],
                    codeSample: "WebSocket audio prenášač: ws://127.0.0.1:8000/ws/wan-audio\nFormát audia: AVAudioEngine 16 kHz PCM16 (PTT / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Vedecké laboratórium (6 kariet) a Záznam histórie",
                    summary: "Vedecká časť analyzuje miestne TB/RDMA klastre, internetové WAN klastre aj ich priame porovnanie na šiestich odborných kartách.",
                    bullets: [
                        "Karty 1–2 (Roofline & WAN): Williams-Roofline (Log-Log), TTFT/TPOT, bublina GPipe, kompresia Petals/SWARM, škálovanie N=1..128 a DiLoCo.",
                        "Karty 3–4 (Pamäť & Energia): Pamäťová rovnica Transformera, TokenPowerBench (J/token, EDP), regionálny mix elektriny (gCO₂/1M) a porovnanie s cloudom.",
                        "Karta 5 (Merania & Export): Série N=5/10/20 s p50/p95/p99, CI95, SLO-goodput a export do CSV, JSON, LaTeX (booktabs) a BibTeX.",
                        "Karta 6 (História): Automaticky alebo ručne zaznamenáva časové rady pre jednotlivé pozície aj globálne vrátane grafu trendu a CSV exportu."
                    ],
                    codeSample: "Rozsah analýzy: Miestne (TB/RDMA) | Internet WAN | Porovnanie\nHistória: Zaznamenať pozíciu | Zaznamenať globálne | Auto-záznam"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Behové služby: MLX, oMLX, Ollama a llama.cpp",
                    summary: "V Dielni modelov je možné modely priamo spúšťať pre zvolenú miestnu službu, naživo ich detekovať alebo prevádzať medzi formátmi.",
                    bullets: [
                        "oMLX (port 8000): Natívna macOS služba MLX s SSD KV vyrovnávacou pamäťou a rozhraním OpenAI aj Anthropic.",
                        "Ollama (port 11434): Rozšírená služba pre miestne modely GGUF; dostupné modely sa načítavajú naživo.",
                        "llama.cpp (port 8080): Priama služba GGUF cez llama-server.",
                        "Živé vyhľadávanie: SS-CCC automaticky dopytuje bežiace služby a hneď zobrazuje dostupné modely."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPorty: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI agenti (1 kliknutie), Lišta menu a Miestne API",
                    summary: "Všetky vývojárske nástroje využívajú celý klaster cez miestne rozhranie — úplne bez odosielania zdrojového kódu do cloudu.",
                    bullets: [
                        "Nastavenie 1 kliknutím: Zapíše hotové konfigurácie pre OpenCode, Hermes Agent a Google Antigravity z karty Agenti a IDE.",
                        "Široká podpora IDE: Funguje bezproblémovo s Cursor, Continue, Open WebUI a Apple Xcode.",
                        "Režim na pozadí v lište menu: Minimalizujte do hornej lišty menu (⌘⇧M), aby klaster potichu na pozadí obsluhoval agentov a IDE rovnako ako Ollama.",
                        "API konzola: Integrovaná živá konzola na priame testovanie výziev, latencie a priepustnosti."
                    ],
                    codeSample: "Koncový bod OpenAI:    http://127.0.0.1:8000/v1/chat/completions\nKoncový bod Anthropic: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. Aktualizátor GitHub a automatická kontrola verzií CI",
                    summary: "SS-CCC automaticky sleduje najnovšiu verziu programu na GitHube a udržuje zdrojové aj vydané inštalácie aktuálne.",
                    bullets: [
                        "Automatická kontrola: Porovnáva pri spustení a každých 30 minút (alebo skratkou ⌘U) oproti version.json, GitHub Releases a main SHA.",
                        "UpdatePromptSheet: Zobrazuje zoznam zmien aj rozdiely revízií priamo v aplikácii.",
                        "Aktualizácia 1 kliknutím: Spustí git pull + swift build a počká na kliknutie na tlačidlo 'Reštartovať aplikáciu teraz'.",
                        "Správa verzií CI: Každý push na main spustí scripts/bump_version.py a nastaví značku vX.Y.Z."
                    ],
                    codeSample: "Skratky: ⌘U (Aktualizácie) | ⌘⇧M (Lišta menu) | ⌘? (Príručka)\nManifest: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Spustenie, riešenie problémov a 25-dielny balík testov",
                    summary: "Jediný príkaz skompiluje aplikáciu macOS a otvorí okno; globálny balík overuje všetky funkcie pomocou 25 automatických testov.",
                    bullets: [
                        "Spustenie aplikácie: ./scripts/run_ssccc.sh zostaví balík Swift a otvorí okno SS-CCC.",
                        "25/25 globálnych testov: python3 tests/test_global_suite.py overuje zostavenie Swift, 17 jazykov, režim lišty menu, 3-kartový prehľad, WAN a API.",
                        "Riešenie problémov: Ak chýba spojenie Thunderbolt, spustite znova ./scripts/setup_tb_network.sh; pri varovaní pamäte skontrolujte iogpu.wired_limit_mb.",
                        "17 jazykov rozhrania: Predvolený štart v angličtine s okamžitým prepínaním medzi DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI a TA."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # Očakáva sa: Ran 25 tests ... OK"
                )
            ]

        case .hu:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. Bármely M-sorozatú Apple Mac a klaszterben (M1–M12+)",
                    summary: "Minden Apple Silicon chippel szerelt Mac (M1-től M12+-ig — Base, Pro, Max vagy Ultra) egyenrangú számítási csomópontként csatlakozhat a klaszterhez: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio és Mac Pro.",
                    bullets: [
                        "Jövőbiztos generáció-felismerés: A memória-sávszélesség, FP16 TFLOPS és Thunderbolt generáció a jövőbeli M7–M12+ chipekre is automatikusan meghatározásra kerül.",
                        "Automatikus rang-kiosztás: A legnagyobb memória-sávszélességű Mac (pl. Ultra vagy Max) automatikusan átveszi a Rank 0 (koordinátor) szerepet.",
                        "Vegyes generációk: Egy MacBook Pro M2 Max zökkenőmentesen működik együtt egy Mac mini M4-gyel vagy Mac Studio M5 Max-szal.",
                        "Minden kialakítás támogatott: Asztali munkaállomások és hordozható Macek közösen osztják meg a modellrétegeket."
                    ],
                    codeSample: "Rank 0 = legnagyobb memória-sávszélesség (GB/s) -> Koordinátor & API-kapu\nRank 1..N = munkacsomópontok súlyozott rétegfelosztásban"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-füles klaszter-áttekintés és ipari figyelmeztető csíkok",
                    summary: "A Klaszter-áttekintés három jól elkülönített fülre bontja a teljes számítási klasztert, és átlós sárga-fekete figyelmeztető csíkokkal jelöli a kritikus memória- és teljesítményzónákat.",
                    bullets: [
                        "1. fül — Helyi klaszter: Megjeleníti az összes helyi Thunderbolt 3/4/5 (RDMA/JACCL) és 10GbE Mac-et a Rank 0-val, használható memóriakerettel és sávszélességgel.",
                        "2. fül — Internetklaszter: Áttekinthetően mutatja a távoli WAN-résztvevőket és a tagolt regionális/helyi alklasztereket.",
                        "3. fül — Helyi + Internet: Egyetlen összekapcsolt hibrid nézetben egyesíti a helyi Thunderbolt-magot és a globális WAN-hálózatot.",
                        "Sárga-fekete figyelmeztető csíkok (HazardStripesBar & IndustrialHazardBanner): A 45°-os csíkok a kritikus számítási, RDMA-, modell- és WAN-zónákat jelzik."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nFigyelmeztető elemek: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. Egyesített memória és védelmi határ (iogpu.wired_limit_mb)",
                    summary: "Apple Siliconon a CPU és a GPU ugyanazon a fizikai memórián osztozik. A RAM 100%-át soha nem szabad AI-modellek számára zárolni.",
                    bullets: [
                        "24 GB RAM-ig: Legalább 4 GB fenntartva marad a macOS és a WindowServer számára (pl. 16 GB → 12 GB használható).",
                        "32 GB–64 GB RAM: 6 GB védett az operációs rendszer részére (pl. 36 GB → 30 GB használható).",
                        "96 GB RAM-tól (Ultra/Max): 8 GB védett a macOS számára (pl. 128 GB → 120 GB használható).",
                        "Minden betöltés előtt az SS-CCC összeveti a teljes igényt (modellsúlyok + KV-gyorsítótár) az eszközök használható összegével."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # Példa 36 GB-os Machez (30 GB használható)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. Hálózat, Thunderbolt-híd (TB3/4/5) és RDMA (JACCL)",
                    summary: "Az SS-CCC két elkülönített síkon választja szét a vezérlőadatokat (LAN/Wi-Fi) és a modell-aktivációs adatokat (Thunderbolt).",
                    bullets: [
                        "Vezérlősík (LAN/Wi-Fi): Bonjour felderítés, API-kérések, telemetria és állapotcsere.",
                        "Adatsík (Thunderbolt 3/4/5): Pont-pont híd a 10.99.1.x alhálózaton valós 30–37 Gbps (TB4) illetve akár 90 Gbps (TB5 RDMA) sebességgel.",
                        "Gyors GPU-szinkronizáció: Az MLX_METAL_FAST_SYNCH=1 ~180 µs-ról ~4 µs-ra csökkenti a réteghatári várakozást (45× gyorsabb).",
                        "RDMA / JACCL: Thunderbolt 5-től natív módon elérhető; Thunderbolt 4-en opcionálisan bekapcsolható."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # vagy: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. Súlyozott felosztás, modellbetöltés és többmodelles mód",
                    summary: "Merev egyenlő elosztás helyett az SS-CCC pontosan a használható memóriával arányos rétegszámot oszt minden Macre, és kezeli a párhuzamos modelleket.",
                    bullets: [
                        "Ki tölti be a modellt? Mindig a Rank 0 koordinálja a tervet a POST /v1/cluster/plan végponton; minden munkacsomópont csak a saját rétegeit tölti be.",
                        "Hány modell futhat egyszerre? Bármennyi, amíg összeg(súlyok + KV-gyorsítótár) ≤ használható klasztermemória.",
                        "Rétegképlet és KV-tömörítés: Rétegek_i = ÖsszesRéteg × (Használható_i / Összes_Használható); KV-tár FP16 (~16k), 8-bit (~32k) vagy 4-bit (~64k+).",
                        "Szakaszos előtöltés (--prefill-step-size 512) és SSD KV-áttöltés (oMLX) előzi meg a memóriacsúcsokat."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. Beállítási útmutató: Helyi klaszter és Hibrid Helyi + Internet",
                    summary: "Lépésről lépésre útmutató helyi TB/RDMA klaszter kiépítéséhez és globális Internet WAN hálózattal (Tailscale, WireGuard, ZeroTier vagy libp2p QUIC) való összekapcsolásához.",
                    bullets: [
                        "1. lépés (Helyi): Állítsa be a Thunderbolt-hidat (setup_tb_network.sh) és memóriavédelmet (setup_wired_limit.sh) minden helyi Macen.",
                        "2. lépés (Átjáró és Modell): Indítsa el a FastAPI átjárót (:8000) és az oMLX/Ollama/llama.cpp szolgáltatást a Rank 0 gépen, és töltsön be modellt.",
                        "3. lépés (Internet WAN): Kapcsoljon be titkosított hálót (Tailscale/WireGuard) a távoli Maceken, és csatlakozzon szobakóddal az Internetklaszterben.",
                        "4. lépés (Hibrid kapcsolat): Kattintson a „Helyi + Internet összekapcsolása” gombra — a helyi TB-sziget alkotja a gyors Tier-0 magot, a WAN-csomópontok átveszik a többletrétegeket."
                    ],
                    codeSample: "WebSocket csevegés-relé: ws://127.0.0.1:8000/ws/wan-chat\nKapcsolás: Helyi (TB/RDMA Tier-0) + Internet WAN -> Hibrid szuperklaszter"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. Élő résztvevői csevegés és Klaszter Audio-Party (hangcsevegés)",
                    summary: "Közvetlenül a szöveges csevegés mellett az SS-CCC konzolos party szobák mintájára teljes értékű Audio-Partyt biztosít elosztott AI csapatoknak.",
                    bullets: [
                        "Valós idejű hangátvitel: AVAudioEngine (16 kHz PCM16, Opus-kompatibilis) használata a /ws/wan-audio végponton.",
                        "Hangmódok: Váltható Adóvevő gomb (PTT) és Nyitott mikrofon, valamint némítási lehetőségek.",
                        "Résztvevők kijelzése: Mutatja az aktív beszélőket élő jelszintmérővel és szobaállapottal.",
                        "Minimális sávszélesség: A hangcsatorna egy átlagos WAN feltöltés kevesebb mint 0,02 %-át foglalja el."
                    ],
                    codeSample: "WebSocket hang-relé: ws://127.0.0.1:8000/ws/wan-audio\nHangformátum: AVAudioEngine 16 kHz PCM16 (PTT / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. Tudományos labor (6 fül) és Előzménynapló",
                    summary: "A tudományos modul hat szakszerű fülön elemzi a helyi TB/RDMA klasztereket, Internet WAN klasztereket és közvetlen összehasonlításukat.",
                    bullets: [
                        "1–2. fül (Roofline & WAN): Williams-Roofline (Log-Log), TTFT/TPOT, GPipe-buborékok, Petals/SWARM tömörítés, N=1..128 skálázás és DiLoCo.",
                        "3–4. fül (Memória & Energia): Transformer memóriaegyenlet, TokenPowerBench (J/token, EDP), regionális energiamix (gCO₂/1M) és költség vs. felhő.",
                        "5. fül (Mérések & Export): N=5/10/20 mérések p50/p95/p99, CI95, SLO-goodput adatokkal, CSV, JSON, LaTeX és BibTeX exporttal.",
                        "6. fül (Előzménynapló): Automatikusan vagy manuálisan idősorokat rögzít pozíciónként és globálisan, trenddiagrammal és CSV exporttal."
                    ],
                    codeSample: "Elemzési hatókör: Helyi (TB/RDMA) | Internet WAN | Összevetés\nElőzmények: Pozíció rögzítése | Globális rögzítés | Auto-rögzítés"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. Futásidejű szolgáltatások: MLX, oMLX, Ollama és llama.cpp",
                    summary: "A Modellműhelyben a modellek közvetlenül elindíthatók a kívánt helyi szolgáltatáshoz, élőben felderíthetők vagy konvertálhatók.",
                    bullets: [
                        "oMLX (8000-es port): Natív macOS MLX szolgáltatás SSD KV-tárral, valamint OpenAI és Anthropic API-val.",
                        "Ollama (11434-es port): Népszerű szolgáltatás helyi GGUF modellekhez; élő beolvasással.",
                        "llama.cpp (8080-as port): Közvetlen GGUF szolgáltatás a llama-server segítségével.",
                        "Élő felderítés: Az SS-CCC automatikusan lekérdezi a futó szolgáltatásokat és azonnal listázza a modelleket."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nPortok: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI-ügynökök (1 kattintás), Menüsor és Helyi API-k",
                    summary: "Minden fejlesztői eszköz a helyi felületen keresztül éri el a teljes klasztert — forráskódok felhőbe töltése nélkül.",
                    bullets: [
                        "1 kattintásos beállítás: Kész konfigurációkat ír az OpenCode, Hermes Agent és Google Antigravity eszközökhöz.",
                        "Széles IDE-kompatibilitás: Zökkenőmentesen működik Cursor, Continue, Open WebUI és Apple Xcode alatt.",
                        "Menüsoros háttérmód: Minimalizálja a felső menüsorba (⌘⇧M), hogy a klaszter az Ollamához hasonlóan a háttérből szolgálja ki az ügynököket és IDE-ket.",
                        "API-konzol: Beépített élő konzol promptok, késleltetés és sebesség azonnali teszteléséhez."
                    ],
                    codeSample: "OpenAI végpont:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic végpont: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub-frissítő és automatikus CI verziókövetés",
                    summary: "Az SS-CCC automatikusan figyeli a legújabb GitHub kiadást, és egyszerűen naprakészen tartja a forrás- és csomagtelepítéseket.",
                    bullets: [
                        "Automatikus ellenőrzés: Indításkor és 30 percenként (vagy ⌘U-val) összehasonlít a version.json, GitHub Releases és main SHA alapján.",
                        "UpdatePromptSheet: Közvetlenül az alkalmazásban jeleníti meg a változásnaplót és a commit-eltéréseket.",
                        "1 kattintásos frissítés: Lefuttatja a git pull + swift build lépést, és vár az 'Alkalmazás újraindítása most' gombra kattintásra.",
                        "CI verziókövetés: Minden main push elindítja a scripts/bump_version.py szkriptet és vX.Y.Z címkét helyez el."
                    ],
                    codeSample: "Gyorsbillentyűk: ⌘U (Frissítés) | ⌘⇧M (Menüsor) | ⌘? (Kézikönyv)\nJegyzék: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. Indítás, hibaelhárítás és 25 részes tesztcsomag",
                    summary: "Egyetlen parancs lefordítja és megnyitja a macOS alkalmazást; 25 automatizált globális teszt biztosítja a megbízhatóságot.",
                    bullets: [
                        "Alkalmazás indítása: A ./scripts/run_ssccc.sh lefordítja a Swift csomagot és megnyitja az SS-CCC ablakot.",
                        "25/25 globális teszt: A python3 tests/test_global_suite.py ellenőrzi a Swift fordítást, 17 nyelvet, menüsor-módot, 3-füles áttekintést, WAN-t és API-kat.",
                        "Gyakori hibák: Hiányzó Thunderbolt kapcsolat esetén futtassa újra a ./scripts/setup_tb_network.sh szkriptet; memóriariasztásnál ellenőrizze az iogpu.wired_limit_mb értéket.",
                        "17 nyelvű felület: Alapértelmezés szerint angolul indul, és élőben váltható DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI és TA között."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # Elvárt: Ran 25 tests ... OK"
                )
            ]

        case .ko:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. 클러스터 내 모든 M 시리즈 Apple Mac 지원 (M1–M12+)",
                    summary: "Apple Silicon 칩(M1부터 M12+까지 — Base, Pro, Max 또는 Ultra)이 탑재된 모든 Mac(Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio 및 Mac Pro)은 동등한 연산 노드로 클러스터에 참여할 수 있습니다.",
                    bullets: [
                        "미래 세대 자동 인식: 메모리 대역폭, FP16 TFLOPS 및 Thunderbolt 세대는 향후 출시될 M7–M12+ 칩에 대해서도 자동으로 추론됩니다.",
                        "자동 순위 할당: 메모리 대역폭이 가장 높은 Mac(예: Ultra 또는 Max)이 자동으로 순위 0(코디네이터)이 됩니다.",
                        "혼합 세대 협업: MacBook Pro M2 Max가 Mac mini M4 또는 Mac Studio M5 Max와 매끄럽게 협업합니다.",
                        "모든 폼팩터 지원: 데스크톱 워크스테이션(Mac Studio, Mac Pro, Mac mini, iMac)과 휴대용 Mac(MacBook Air/Pro)이 모델 계층을 함께 공유합니다."
                    ],
                    codeSample: "순위 0 = 최고 메모리 대역폭 (GB/s) -> 코디네이터 및 API 게이트웨이\n순위 1..N = 가중 계층 분할에 참여하는 워커 노드"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-탭 클러스터 개요 및 산업용 경고 줄무늬",
                    summary: "클러스터 개요는 전체 컴퓨팅 클러스터를 세 개의 명확한 범위 탭으로 구분하며, 안전이 중요한 성능 및 메모리 영역을 대각선 노란색-검은색 경고 줄무늬로 강조합니다.",
                    bullets: [
                        "탭 1 — 로컬 클러스터: 순위 0, 가용 메모리 풀 및 총 대역폭과 함께 모든 로컬 Thunderbolt 3/4/5(RDMA/JACCL) 및 10GbE Mac을 표시합니다.",
                        "탭 2 — 인터넷 클러스터: 원격 WAN 참여자 및 세분화된 지역/로컬 서브클러스터를 명확하게 보여줍니다.",
                        "탭 3 — 로컬 + 인터넷: 로컬 Thunderbolt 코어와 글로벌 WAN 네트워크를 단일 결합 하이브리드 보기로 통합합니다.",
                        "노란색-검은색 경고 줄무늬 (HazardStripesBar & IndustrialHazardBanner): 45° 대각선 표식이 핵심 화면의 주요 연산, RDMA, 모델 및 WAN 구역을 나타냅니다."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\n경고 UI 구성 요소: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. 통합 메모리 및 안전 보호 한계 (iogpu.wired_limit_mb)",
                    summary: "Apple Silicon에서는 CPU와 GPU가 동일한 물리 메모리를 공유합니다. AI 모델을 위해 시스템 RAM의 100%를 할당해서는 절대 안 됩니다.",
                    bullets: [
                        "24 GB RAM 이하: macOS와 WindowServer를 위해 최소 4 GB를 예약합니다(예: 16 GB → 12 GB 사용 가능).",
                        "32 GB ~ 64 GB RAM: 운영 체제를 위해 6 GB가 안전하게 보호됩니다(예: 36 GB → 30 GB 사용 가능).",
                        "96 GB 이상 RAM (Ultra/Max): macOS를 위해 8 GB가 보호됩니다(예: 128 GB → 120 GB 사용 가능).",
                        "모델 로드 전 SS-CCC는 총 요구량(모델 가중치 + KV 캐시)을 모든 기기의 가용 총합과 비교 검증합니다."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac 예시 (30 GB 사용 가능)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. 네트워크, Thunderbolt 브리지 (TB3/4/5) 및 RDMA (JACCL)",
                    summary: "SS-CCC는 제어 데이터(LAN/Wi-Fi)와 모델 활성화 데이터(Thunderbolt)를 두 개의 독립된 네트워크 평면으로 cleanly 분리합니다.",
                    bullets: [
                        "제어 평면 (LAN/Wi-Fi): Bonjour 검색, API 요청, 텔레메트리 및 상태 교환.",
                        "데이터 평면 (Thunderbolt 3/4/5): 10.99.1.x 대역의 점대점 브리지로 실제 30–37 Gbps(TB4) 및 최대 90 Gbps(TB5 RDMA) 지원.",
                        "고속 GPU 동기화: MLX_METAL_FAST_SYNCH=1 설정으로 계층 전환 대기 시간을 ~180 µs에서 ~4 µs로 단축합니다(45× 가속).",
                        "RDMA / JACCL: Thunderbolt 5 이상에서 기본 지원되며, Thunderbolt 4에서는 선택적으로 활성화할 수 있습니다."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # 또는: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. 가중 샤딩, 모델 로드 및 멀티 모델 운영",
                    summary: "고정 균등 분할 대신 SS-CCC는 각 Mac에 가용 메모리에 비례한 정확한 계층 비율을 할당하며, 여러 모델의 병렬 상주를 제어합니다.",
                    bullets: [
                        "모델 로드는 누가 하나요? 항상 순위 0이 POST /v1/cluster/plan을 통해 샤딩 계획을 조율하며, 각 워커(순위 1..N)는 할당된 계층 범위만 로드합니다.",
                        "동시에 몇 개까지 로드할 수 있나요? 합계(가중치 + KV 캐시) ≤ 가용 클러스터 메모리를 만족하는 한 무제한(예: 70B–405B+ 1개 또는 7B–32B 2–4개 병렬 실행)입니다.",
                        "계층 공식 및 KV 압축: Layers_i = TotalLayers × (Usable_i / Total_Usable); KV 캐시는 FP16(~16k), 8비트(~32k), 4비트(~64k+ 컨텍스트) 선택 가능.",
                        "분할 프리필(--prefill-step-size 512) 및 SSD KV 오프로딩(oMLX)으로 대형 코드베이스에서 메모리 급증을 방지합니다."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. 구축 가이드: 로컬 클러스터 및 로컬 + 인터넷 하이브리드",
                    summary: "로컬 TB/RDMA 클러스터를 구성하고 글로벌 인터넷 WAN 네트워크(Tailscale, WireGuard, ZeroTier 또는 libp2p QUIC)와 결합하는 단계별 안내입니다.",
                    bullets: [
                        "1단계 (로컬): 각 로컬 Mac에 Thunderbolt 브리지(setup_tb_network.sh)와 메모리 보호(setup_wired_limit.sh)를 설정하세요; 순위 0은 자동 지정됩니다.",
                        "2단계 (게이트웨이 및 모델): 순위 0에서 FastAPI 게이트웨이(:8000)와 oMLX/Ollama/llama.cpp를 시작하고 모델 스튜디오에서 대상 모델을 로드하세요.",
                        "3단계 (인터넷 WAN): 원격 Mac에서 암호화된 메시(Tailscale/WireGuard)를 활성화하고 인터넷 클러스터 탭에서 방 ID로 참여하세요.",
                        "4단계 (하이브리드 결합): ‘로컬 + 인터넷 결합’을 클릭하면 로컬 TB 아일랜드가 고속 Tier-0 코어가 되고 WAN 노드가 나머지 계층을 분담합니다."
                    ],
                    codeSample: "WebSocket 채팅 릴레이: ws://127.0.0.1:8000/ws/wan-chat\n결합 구조: 로컬 (TB/RDMA Tier-0) + 인터넷 WAN -> 하이브리드 슈퍼클러스터"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. 실시간 참여자 채팅 및 클러스터 오디오 파티 (음성 채팅)",
                    summary: "텍스트 채팅 바로 옆에 분산 AI 팀을 위해 콘솔 파티 룸에서 영감을 받은 완벽한 클러스터 오디오 파티 기능을 제공합니다.",
                    bullets: [
                        "실시간 음성 전송: 전용 릴레이 /ws/wan-audio를 통해 AVAudioEngine(16 kHz PCM16, Opus 호환)을 사용합니다.",
                        "음성 모드: 눌러서 말하기(PTT)와 오픈 마이크 전환, 마이크 음소거 및 듣기 끄기 모드를 지원합니다.",
                        "참여자 표시: 활성 화자의 실시간 오디오 레벨 미터, 노드 역할 및 방 상태를 실시간으로 보여줍니다.",
                        "초저대역폭 사용: 음성 채널은 일반 WAN 업링크의 0.02% 미만을 사용하여 텐서 전송을 방해하지 않습니다."
                    ],
                    codeSample: "WebSocket 오디오 릴레이: ws://127.0.0.1:8000/ws/wan-audio\n오디오 포맷: AVAudioEngine 16 kHz PCM16 (PTT / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. 과학 연구실 (6개 탭) 및 기록 로깅",
                    summary: "과학 분석 영역은 6개의 전문 탭에서 로컬 TB/RDMA 클러스터, 인터넷 WAN 클러스터 및 두 환경의 직접 비교를 심층 분석합니다.",
                    bullets: [
                        "탭 1–2 (Roofline & WAN): Williams-Roofline(로그-로그), TTFT/TPOT, GPipe 버블, Petals/SWARM 압축, N=1..128 확장성 및 DiLoCo.",
                        "탭 3–4 (메모리 & 에너지): 트랜스포머 메모리 방정식, TokenPowerBench(J/tok, EDP), 지역 전력 믹스(gCO₂/1M) 및 클라우드 대비 비용.",
                        "탭 5 (실험 & 내보내기): p50/p95/p99가 포함된 N=5/10/20 실행, CI95, SLO 굿풋 및 CSV·JSON·LaTeX(booktabs)·8종 BibTeX 내보내기.",
                        "탭 6 (기록 로그): 항목별 또는 전체 시계열 데이터를 자동·수동으로 기록하며 추세 그래프와 CSV 내보내기를 제공합니다."
                    ],
                    codeSample: "분석 범위: 로컬 (TB/RDMA) | 인터넷 WAN | 비교 (로컬 vs WAN)\n기록: 항목 기록 | 전체 기록 | 자동 기록"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. 런타임 서비스: MLX, oMLX, Ollama 및 llama.cpp",
                    summary: "모델 스튜디오에서 원하는 로컬 서비스에 맞춰 모델을 즉시 실행하거나, 실시간 감지 및 형식 변환을 수행할 수 있습니다.",
                    bullets: [
                        "oMLX (포트 8000): SSD KV 캐시와 OpenAI 및 Anthropic API를 함께 제공하는 네이티브 macOS MLX 서비스.",
                        "Ollama (포트 11434): 로컬 GGUF 모델을 위한 널리 쓰이는 서비스로, 보유 모델을 실시간으로 불러옵니다.",
                        "llama.cpp (포트 8080): llama-server를 통한 직접 GGUF 추론 서비스.",
                        "실시간 검색: SS-CCC가 실행 중인 백엔드를 자동으로 확인하여 활성 및 로컬 다운로드 모델을 즉시 표시합니다."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\n포트: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI 에이전트 (원클릭), 메뉴 막대 모드 및 로컬 API",
                    summary: "모든 개발 도구는 소스 코드나 문서를 클라우드로 전송하지 않고 로컬 인터페이스를 통해 전체 클러스터를 활용합니다.",
                    bullets: [
                        "원클릭 설정: 에이전트 및 IDE 탭에서 OpenCode, Hermes Agent, Google Antigravity용 구성 파일을 한 번에 생성합니다.",
                        "폭넓은 IDE 호환성: Cursor, Continue, Open WebUI 및 Apple Xcode와 매끄럽게 연동됩니다.",
                        "메뉴 막대 백그라운드 서비스 모드: 창을 상단 메뉴 막대로 최소화(⌘⇧M)하면 Ollama처럼 백그라운드에서 에이전트와 IDE를 계속 지원합니다.",
                        "API 콘솔: 프롬프트, 지연 시간 및 토큰 처리량을 즉시 검증할 수 있는 내장 실시간 콘솔."
                    ],
                    codeSample: "OpenAI 엔드포인트:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic 엔드포인트: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub 업데이터 및 자동 CI 버전 관리",
                    summary: "SS-CCC는 GitHub에서 최신 프로그램 버전을 자동으로 확인하며 소스 및 릴리스 설치를 손쉽게 최신 상태로 유지합니다.",
                    bullets: [
                        "자동 확인: 앱 시작 시 및 30분마다(또는 ⌘U) version.json, GitHub Releases 및 main 커밋 SHA를 비교합니다.",
                        "UpdatePromptSheet: 변경 로그와 커밋 차이를 앱 내부에서 바로 확인합니다.",
                        "원클릭 업데이트: git pull + swift build를 수행한 뒤 사용자가 '지금 앱 다시 시작' 버튼을 누를 때까지 제어권을 유지합니다.",
                        "CI 버전 관리: main 푸시마다 scripts/bump_version.py가 실행되어 version.json과 태그 vX.Y.Z를 동기화합니다."
                    ],
                    codeSample: "단축키: ⌘U (업데이트 확인) | ⌘⇧M (메뉴 막대) | ⌘? (설명서)\n매니페스트: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. 앱 실행, 문제 해결 및 25종 글로벌 테스트 스위트",
                    summary: "단 한 줄의 명령으로 macOS 앱을 빌드하고 창을 열 수 있으며, 25개의 자동화된 글로벌 테스트가 모든 기능을 검증합니다.",
                    bullets: [
                        "앱 실행: ./scripts/run_ssccc.sh가 Swift 패키지를 컴파일하고 SS-CCC 창을 엽니다.",
                        "25/25 글로벌 테스트: python3 tests/test_global_suite.py가 Swift 빌드, 17개 언어, 메뉴 막대 모드, 3-탭 개요, WAN 및 API를 검증합니다.",
                        "문제 해결: Thunderbolt 연결이 없으면 ./scripts/setup_tb_network.sh를 다시 실행하고, 메모리 경고 시 iogpu.wired_limit_mb를 확인하세요.",
                        "17개 언어 지원: 기본 영어로 시작하며 DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI, TA 간 즉시 전환됩니다."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # 예상 결과: Ran 25 tests ... OK"
                )
            ]

        case .hi:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. क्लस्टर में कोई भी M-सीरीज़ Apple Mac (M1–M12+)",
                    summary: "Apple Silicon चिप (M1 से M12+ — Base, Pro, Max या Ultra) वाला हर Mac समान कंप्यूट नोड के रूप में क्लस्टर में जुड़ सकता है: Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio और Mac Pro।",
                    bullets: [
                        "भविष्य-तैयार पीढ़ी पहचान: मेमोरी बैंडविड्थ, FP16 TFLOPS और Thunderbolt पीढ़ी आने वाले M7–M12+ चिप्स के लिए भी स्वचालित रूप से निकाली जाती है।",
                        "स्वचालित रैंक असाइनमेंट: सबसे अधिक मेमोरी बैंडविड्थ वाला Mac (जैसे Ultra या Max) स्वतः रैंक 0 (समन्वयक) बन जाता है।",
                        "मिश्रित पीढ़ियाँ: एक MacBook Pro M2 Max आसानी से Mac mini M4 या Mac Studio M5 Max के साथ काम करता है।",
                        "सभी फॉर्म-फ़ैक्टर समर्थित: डेस्कटॉप वर्कस्टेशन और पोर्टेबल Macs मिलकर मॉडल लेयर्स साझा करते हैं।"
                    ],
                    codeSample: "रैंक 0 = उच्चतम मेमोरी बैंडविड्थ (GB/s) -> समन्वयक और API गेटवे\nरैंक 1..N = भारित लेयर शार्डिंग में वर्कर नोड्स"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-टैब क्लस्टर अवलोकन और औद्योगिक चेतावनी धारियाँ",
                    summary: "क्लस्टर अवलोकन पूरे कंप्यूट क्लस्टर को तीन स्पष्ट टैब्स में विभाजित करता है और महत्वपूर्ण प्रदर्शन व मेमोरी क्षेत्रों को 45° पीली-काली चेतावनी धारियों से चिह्नित करता है।",
                    bullets: [
                        "टैब 1 — स्थानीय क्लस्टर: रैंक 0, उपयोग योग्य मेमोरी पूल और कुल बैंडविड्थ के साथ सभी स्थानीय Thunderbolt 3/4/5 (RDMA/JACCL) और 10GbE Macs दिखाता है।",
                        "टैब 2 — इंटरनेट क्लस्टर: दूरस्थ WAN प्रतिभागियों और क्षेत्रीय/स्थानीय उप-क्लस्टरों को स्पष्ट रूप से प्रस्तुत करता है।",
                        "टैब 3 — स्थानीय + इंटरनेट: स्थानीय Thunderbolt कोर और वैश्विक WAN नेटवर्क को एक एकीकृत हाइब्रिड दृश्य में जोड़ता है।",
                        "पीली-काली चेतावनी धारियाँ (HazardStripesBar और IndustrialHazardBanner): 45° धारियाँ महत्वपूर्ण कंप्यूट, RDMA, मॉडल और WAN क्षेत्रों को इंगित करती हैं।"
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nचेतावनी घटक: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. यूनिफाइड मेमोरी और सुरक्षा सीमा (iogpu.wired_limit_mb)",
                    summary: "Apple Silicon पर CPU और GPU एक ही भौतिक मेमोरी साझा करते हैं। AI मॉडलों के लिए कभी भी 100 % RAM आवंटित नहीं किया जाना चाहिए।",
                    bullets: [
                        "24 GB RAM तक: macOS और WindowServer के लिए कम से कम 4 GB सुरक्षित रहता है (जैसे 16 GB → 12 GB उपयोग योग्य)।",
                        "32 GB से 64 GB RAM: ऑपरेटिंग सिस्टम के लिए 6 GB आरक्षित रहता है (जैसे 36 GB → 30 GB उपयोग योग्य)।",
                        "96 GB+ RAM (Ultra/Max): macOS के लिए 8 GB आरक्षित रहता है (जैसे 128 GB → 120 GB उपयोग योग्य)।",
                        "मॉडल लोड करने से पहले SS-CCC सभी उपकरणों की उपयोग योग्य सीमा के विरुद्ध कुल आवश्यकता (वेट्स + KV कैश) की जांच करता है।"
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac का उदाहरण (30 GB उपयोग योग्य)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. नेटवर्क, Thunderbolt ब्रिज (TB3/4/5) और RDMA (JACCL)",
                    summary: "SS-CCC नियंत्रण डेटा (LAN/Wi-Fi) और मॉडल सक्रियण डेटा (Thunderbolt) को दो अलग-अलग नेटवर्क तलों में साफ-सुथरे ढंग से अलग करता है।",
                    bullets: [
                        "नियंत्रण तल (LAN/Wi-Fi): Bonjour खोज, API अनुरोध, टेलीमेट्री और स्थिति विनिमय।",
                        "डेटा तल (Thunderbolt 3/4/5): 10.99.1.x सबनेट में पॉइंट-टू-पॉइंट ब्रिज जो वास्तविक 30–37 Gbps (TB4) या 90 Gbps तक (TB5 RDMA) प्रदान करता है।",
                        "तेज़ GPU सिंक्रनाइज़ेशन: MLX_METAL_FAST_SYNCH=1 लेयर सीमाओं पर प्रतीक्षा समय को ~180 µs से घटाकर ~4 µs (45× तेज़) करता है।",
                        "RDMA / JACCL: Thunderbolt 5 से नेटिव रूप से उपलब्ध; Thunderbolt 4 पर वैकल्पिक रूप से सक्षम।"
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # या: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. भारित शार्डिंग, मॉडल लोडिंग और मल्टी-मॉडल संचालन",
                    summary: "समान विभाजन के बजाय SS-CCC प्रत्येक Mac को उसकी उपयोग योग्य मेमोरी के अनुपात में ठीक उतनी ही लेयर्स देता है, और समानांतर मॉडलों का प्रबंधन करता है।",
                    bullets: [
                        "मॉडल कौन लोड करता है? हमेशा रैंक 0 POST /v1/cluster/plan के माध्यम से शार्डिंग योजना समन्वित करता है; प्रत्येक वर्कर केवल अपनी लेयर सीमा लोड करता है।",
                        "एक साथ कितने मॉडल? जब तक योग(वेट्स + KV कैश) ≤ उपयोग योग्य क्लस्टर मेमोरी है, तब तक कितने भी मॉडल समानांतर चल सकते हैं।",
                        "लेयर सूत्र और KV क्वांटाइज़ेशन: Layers_i = TotalLayers × (Usable_i / Total_Usable); FP16 (~16k), 8-बिट (~32k) या 4-बिट (~64k+) KV कैश।",
                        "विभाजित प्रीफ़िल (--prefill-step-size 512) और SSD KV ऑफ़लोडिंग (oMLX) बड़े प्रोजेक्ट्स में मेमोरी स्पाइक्स रोकते हैं।"
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. सेटअप गाइड: स्थानीय क्लस्टर और हाइब्रिड स्थानीय + इंटरनेट",
                    summary: "स्थानीय TB/RDMA क्लस्टर स्थापित करने और उसे वैश्विक इंटरनेट WAN नेटवर्क (Tailscale, WireGuard, ZeroTier या libp2p QUIC) से जोड़ने की चरण-दर-चरण मार्गदर्शिका।",
                    bullets: [
                        "चरण 1 (स्थानीय): प्रत्येक स्थानीय Mac पर Thunderbolt ब्रिज (setup_tb_network.sh) और मेमोरी सुरक्षा (setup_wired_limit.sh) सेट करें।",
                        "चरण 2 (गेटवे और मॉडल): रैंक 0 पर FastAPI गेटवे (:8000) और oMLX/Ollama/llama.cpp लॉन्च करें तथा मॉडल कार्यशाला में मॉडल लोड करें।",
                        "चरण 3 (इंटरनेट WAN): दूरस्थ Macs पर एन्क्रिप्टेड मेश (Tailscale/WireGuard) सक्रिय करें और इंटरनेट क्लस्टर टैब में कक्ष ID से जुड़ें।",
                        "चरण 4 (हाइब्रिड युग्मन): ‘स्थानीय + इंटरनेट जोड़ें’ पर क्लिक करें — स्थानीय TB द्वीप तेज़ Tier-0 कोर बनाते हैं और WAN नोड्स अतिरिक्त लेयर्स संभालते हैं।"
                    ],
                    codeSample: "WebSocket चैट रिले: ws://127.0.0.1:8000/ws/wan-chat\nयुग्मन: स्थानीय (TB/RDMA Tier-0) + इंटरनेट WAN -> हाइब्रिड सुपरक्लस्टर"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. लाइव प्रतिभागी चैट और क्लस्टर ऑडियो-पार्टी (वॉयस चैट)",
                    summary: "टेक्स्ट चैट के ठीक बगल में, SS-CCC वितरित AI टीमों के लिए कंसोल पार्टी रूम से प्रेरित एक पूर्ण ऑडियो-पार्टी प्रदान करता है।",
                    bullets: [
                        "रीयल-टाइम वॉयस: समर्पित /ws/wan-audio रिले पर AVAudioEngine (16 kHz PCM16, Opus-संगत) का उपयोग करता है।",
                        "वॉयस मोड: पुश-टू-टॉक (PTT) और ओपन-माइक के बीच स्विच, साथ ही माइक म्यूट और ऑडियो बंद मोड।",
                        "प्रतिभागी दृश्य: सक्रिय वक्ताओं को लाइव लेवल मीटर, नोड भूमिका और कक्ष स्थिति के साथ दिखाता है।",
                        "न्यूनतम बैंडविड्थ: वॉयस चैनल सामान्य WAN अपलिंक के 0.02% से कम उपयोग करता है और टेंसर डेटा को बाधित नहीं करता।"
                    ],
                    codeSample: "WebSocket ऑडियो रिले: ws://127.0.0.1:8000/ws/wan-audio\nऑडियो प्रारूप: AVAudioEngine 16 kHz PCM16 (PTT / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. विज्ञान प्रयोगशाला (6 टैब्स) और इतिहास रिकॉर्डिंग",
                    summary: "वैज्ञानिक अनुभाग छह विशेष टैब्स में स्थानीय TB/RDMA क्लस्टर, इंटरनेट WAN क्लस्टर और दोनों की सीधी तुलना का विश्लेषण करता है।",
                    bullets: [
                        "टैब 1–2 (Roofline और WAN): Williams-Roofline (लॉग-लॉग), TTFT/TPOT, GPipe बबल, Petals/SWARM संपीड़न, N=1..128 स्केलिंग और DiLoCo।",
                        "टैब 3–4 (मेमोरी और ऊर्जा): ट्रांसफ़ॉर्मर मेमोरी समीकरण, TokenPowerBench (J/tok, EDP), क्षेत्रीय कार्बन मिक्स (gCO₂/1M) और क्लाउड बनाम लागत।",
                        "टैब 5 (परीक्षण और निर्यात): p50/p95/p99, CI95, SLO गुडपुट के साथ N=5/10/20 रन और CSV, JSON, LaTeX, BibTeX निर्यात।",
                        "टैब 6 (इतिहास लॉग): प्रति-स्थिति या वैश्विक रूप से समय श्रृंखला को स्वचालित/मैन्युअल रूप से ट्रेंड चार्ट व CSV निर्यात सहित सहेजता है।"
                    ],
                    codeSample: "विश्लेषण दायरा: स्थानीय (TB/RDMA) | इंटरनेट WAN | तुलना\nइतिहास: स्थिति रिकॉर्ड करें | वैश्विक रिकॉर्ड करें | ऑटो-रिकॉर्ड"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. रनटाइम सेवाएं: MLX, oMLX, Ollama और llama.cpp",
                    summary: "मॉडल कार्यशाला में, मॉडलों को सीधे चुनी हुई स्थानीय सेवा के लिए लॉन्च किया जा सकता है, लाइव खोजा जा सकता है या प्रारूपों के बीच परिवर्तित किया जा सकता है।",
                    bullets: [
                        "oMLX (पोर्ट 8000): SSD KV कैश और OpenAI व Anthropic API के साथ नेटिव macOS MLX सेवा।",
                        "Ollama (पोर्ट 11434): स्थानीय GGUF मॉडलों के लिए लोकप्रिय सेवा; उपलब्ध मॉडल लाइव पढ़े जाते हैं।",
                        "llama.cpp (पोर्ट 8080): llama-server के माध्यम से प्रत्यक्ष GGUF सेवा।",
                        "लाइव खोज: SS-CCC स्वचालित रूप से चल रही सेवाओं की जांच करता है और सक्रिय व डाउनलोड किए गए मॉडल तुरंत दिखाता है।"
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nपोर्ट्स: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI एजेंट (1-क्लिक), मेनू बार मोड और स्थानीय API",
                    summary: "सभी डेवलपर टूल्स स्थानीय इंटरफ़ेस के माध्यम से पूरे क्लस्टर का उपयोग करते हैं — बिना किसी क्लाउड पर सोर्स कोड भेजे।",
                    bullets: [
                        "1-क्लिक सेटअप: एजेंट और IDE टैब से OpenCode, Hermes Agent और Google Antigravity के लिए तैयार कॉन्फ़िग लिखता है।",
                        "व्यापक IDE संगतता: Cursor, Continue, Open WebUI और Apple Xcode के साथ सहजता से काम करता है।",
                        "मेनू बार बैकग्राउंड सेवा मोड: विंडो को शीर्ष मेनू बार में मिनिमाइज़ करें (⌘⇧M) ताकि क्लस्टर Ollama की तरह पृष्ठभूमि में एजेंट्स और IDEs की सेवा करता रहे।",
                        "API कंसोल: प्रॉम्प्ट, विलंबता और टोकन थ्रूपुट के प्रत्यक्ष परीक्षण के लिए अंतर्निहित लाइव कंसोल।"
                    ],
                    codeSample: "OpenAI एंडपॉइंट:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic एंडपॉइंट: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub अपडेटर और स्वचालित CI संस्करण नियंत्रण",
                    summary: "SS-CCC स्वचालित रूप से GitHub पर नवीनतम प्रोग्राम संस्करण की निगरानी करता है और स्रोत व रिलीज़ इंस्टॉलेशन को अद्यतित रखता है।",
                    bullets: [
                        "स्वचालित जांच: स्टार्टअप पर और हर 30 मिनट में (या ⌘U से) version.json, GitHub Releases और main SHA की तुलना करता है।",
                        "UpdatePromptSheet: सीधे ऐप के भीतर चेंजलॉग और कमिट अंतर दिखाता है।",
                        "1-क्लिक अपडेट: git pull + swift build चलाता है और 'ऐप अभी पुनः आरंभ करें' बटन दबाने की प्रतीक्षा करता है।",
                        "CI संस्करण नियंत्रण: main पर प्रत्येक पुश scripts/bump_version.py चलाता है और vX.Y.Z टैग सेट करता है।"
                    ],
                    codeSample: "शॉर्टकट्स: ⌘U (अपडेट जांच) | ⌘⇧M (मेनू बार) | ⌘? (पुस्तिका)\nमेनिफ़ेस्ट: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. ऐप लॉन्च, समस्या निवारण और 25-भाग परीक्षण सूट",
                    summary: "एक कमांड macOS ऐप को संकलित करता है और विंडो खोलता है; वैश्विक परीक्षण सूट 25 स्वचालित परीक्षणों से हर सुविधा की पुष्टि करता है।",
                    bullets: [
                        "ऐप लॉन्च करें: ./scripts/run_ssccc.sh Swift पैकेज बनाता है और SS-CCC विंडो खोलता है।",
                        "25/25 वैश्विक परीक्षण: python3 tests/test_global_suite.py Swift बिल्ड, 17 भाषाएं, मेनू बार मोड, 3-टैब अवलोकन, WAN और API सत्यापित करता है।",
                        "समस्या निवारण: Thunderbolt लिंक न होने पर ./scripts/setup_tb_network.sh पुनः चलाएं; मेमोरी चेतावनी पर iogpu.wired_limit_mb जांचें।",
                        "17 भाषाएं: डिफ़ॉल्ट रूप से अंग्रेजी में शुरू होता है और DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI और TA के बीच लाइव स्विच करता है।"
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # अपेक्षित: Ran 25 tests ... OK"
                )
            ]

        case .ta:
            return [
                HelpDocSection(
                    id: "universal-m",
                    icon: "macstudio.fill",
                    accent: SolarisTheme.amber,
                    title: "1. கிளஸ்டரில் எந்த M-தொடர் Apple Mac உம் (M1–M12+)",
                    summary: "Apple Silicon சில்லு (M1 முதல் M12+ வரை — Base, Pro, Max அல்லது Ultra) கொண்ட எந்த Mac உம் (Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio மற்றும் Mac Pro) சமமான கணிப்பு முனையாகக் கிளஸ்டரில் இணையலாம்.",
                    bullets: [
                        "எதிர்காலத் தலைமுறைக் கண்டறிதல்: எதிர்கால M7–M12+ சில்லுகளுக்கும் நினைவக அலைவரிசை, FP16 TFLOPS மற்றும் Thunderbolt தலைமுறை தானாகக் கணிக்கப்படும்.",
                        "தானியங்கி வரிசை ஒதுக்கீடு: அதிக நினைவக அலைவரிசை கொண்ட Mac (எ.கா. Ultra அல்லது Max) தானாகவே வரிசை 0 (ஒருங்கிணைப்பாளர்) ஆக மாறும்.",
                        "கலப்புத் தலைமுறைகள்: MacBook Pro M2 Max ஆனது Mac mini M4 அல்லது Mac Studio M5 Max உடன் எளிதாக இணைந்து செயல்படும்.",
                        "அனைத்து வடிவங்களும் ஆதரிக்கப்படுகின்றன: டெஸ்க்டாப் பணிநிலையங்கள் மற்றும் மடிக்கணினி Macகள் மாதிரி அடுக்குகளைப் பகிர்ந்து கொள்கின்றன."
                    ],
                    codeSample: "வரிசை 0 = அதிகபட்ச நினைவக அலைவரிசை (GB/s) -> ஒருங்கிணைப்பாளர் & API நுழைவாயில்\nவரிசை 1..N = எடையிட்ட அடுக்குப் பிரிப்பில் பணியாளர் முனைகள்"
                ),
                HelpDocSection(
                    id: "overview-hazard",
                    icon: "rectangle.3.group.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "2. 3-தாவல் கிளஸ்டர் மேலோட்டம் & தொழில்துறை எச்சரிக்கைக் கோடுகள்",
                    summary: "கிளஸ்டர் மேலோட்டம் முழு கிளஸ்டரையும் மூன்று தெளிவான தாவல்களாகப் பிரித்து, பாதுகாப்பு-முக்கிய செயல்திறன் மற்றும் நினைவக மண்டலங்களை 45° மஞ்சள்-கருப்பு எச்சரிக்கைக் கோடுகளால் குறிக்கிறது.",
                    bullets: [
                        "தாவல் 1 — உள்ளூர் கிளஸ்டர்: வரிசை 0, பயன்படுத்தக்கூடிய நினைவகத் தொகுப்பு மற்றும் மொத்த அலைவரிசையுடன் அனைத்து உள்ளூர் Thunderbolt 3/4/5 (RDMA/JACCL) & 10GbE Macகளையும் காட்டுகிறது.",
                        "தாவல் 2 — இணைய கிளஸ்டர்: தொலைநிலை WAN பங்கேற்பாளர்கள் மற்றும் பிராந்திய/உள்ளூர் துணை கிளஸ்டர்களைத் தெளிவாகக் காட்டுகிறது.",
                        "தாவல் 3 — உள்ளூர் + இணையம்: உள்ளூர் Thunderbolt மையத்தையும் உலகளாவிய WAN வலையமைப்பையும் ஒரே கலப்பினக் காட்சியில் இணைக்கிறது.",
                        "மஞ்சள்-கருப்பு எச்சரிக்கைக் கோடுகள் (HazardStripesBar & IndustrialHazardBanner): முக்கிய கணிப்பு, RDMA, மாதிரி மற்றும் WAN மண்டலங்களைக் குறிக்கின்றன."
                    ],
                    codeSample: "ClusterOverviewScope: .local | .internet | .hybrid\nஎச்சரிக்கைக் கூறுகள்: Theme.swift -> HazardStripesBar & IndustrialHazardBanner"
                ),
                HelpDocSection(
                    id: "memory-safety",
                    icon: "memorychip.fill",
                    accent: SolarisTheme.emerald,
                    title: "3. ஒருங்கிணைந்த நினைவகம் & பாதுகாப்பு வரம்பு (iogpu.wired_limit_mb)",
                    summary: "Apple Silicon இல் CPU மற்றும் GPU ஒரே இயற்பியல் நினைவகத்தைப் பகிர்கின்றன. AI மாதிரிகளுக்காக ஒருபோதும் 100 % RAM ஐயும் ஒதுக்கக் கூடாது.",
                    bullets: [
                        "24 GB RAM வரை: macOS மற்றும் WindowServer க்கு குறைந்தது 4 GB ஒதுக்கப்படும் (எ.கா. 16 GB → 12 GB பயன்படும்).",
                        "32 GB முதல் 64 GB RAM: இயக்க முறைமைக்காக 6 GB பாதுகாக்கப்படும் (எ.கா. 36 GB → 30 GB பயன்படும்).",
                        "96 GB+ RAM (Ultra/Max): macOS க்கு 8 GB பாதுகாக்கப்படும் (எ.கா. 128 GB → 120 GB பயன்படும்).",
                        "ஏற்றுவதற்கு முன், SS-CCC மொத்தத் தேவையை (மாதிரி எடைகள் + KV கேச்) அனைத்து சாதனங்களின் பயன்பாட்டு வரம்போடு சரிபார்க்கிறது."
                    ],
                    codeSample: "sudo ./scripts/setup_wired_limit.sh 30720   # 36 GB Mac க்கான எடுத்துக்காட்டு (30 GB பயன்படும்)\nsysctl iogpu.wired_limit_mb"
                ),
                HelpDocSection(
                    id: "network-tb",
                    icon: "bolt.horizontal.circle.fill",
                    accent: SolarisTheme.mint,
                    title: "4. பிணையம், Thunderbolt பாலம் (TB3/4/5) & RDMA (JACCL)",
                    summary: "SS-CCC கட்டுப்பாட்டுத் தரவு (LAN/Wi-Fi) மற்றும் மாதிரி செயலாக்கத் தரவு (Thunderbolt) ஆகியவற்றை இரண்டு தளங்களாகத் தெளிவாகப் பிரிக்கிறது.",
                    bullets: [
                        "கட்டுப்பாட்டுத் தளம் (LAN/Wi-Fi): Bonjour கண்டறிதல், API கோரிக்கைகள், அளவீடு மற்றும் நிலைப் பரிமாற்றம்.",
                        "தரவுத் தளம் (Thunderbolt 3/4/5): 10.99.1.x வலைப்பின்னலில் புள்ளி-க்கு-புள்ளி பாலம் — உண்மையான 30–37 Gbps (TB4) மற்றும் 90 Gbps வரை (TB5 RDMA).",
                        "வேகமான GPU ஒத்திசைவு: MLX_METAL_FAST_SYNCH=1 அடுக்கு எல்லைகளில் காத்திருப்பு நேரத்தை ~180 µs இலிருந்து ~4 µs ஆகக் குறைக்கிறது (45× வேகம்).",
                        "RDMA / JACCL: Thunderbolt 5 முதல் இயல்பாகவே கிடைக்கும்; Thunderbolt 4 இல் விருப்பத்தேர்வாக இயக்கலாம்."
                    ],
                    codeSample: "./scripts/setup_tb_network.sh studio   # அல்லது: mini\niperf3 -c 10.99.1.1"
                ),
                HelpDocSection(
                    id: "sharding-loading",
                    icon: "square.stack.3d.up.fill",
                    accent: SolarisTheme.amberGlow,
                    title: "5. எடையிட்ட பிரிப்பு, மாதிரி ஏற்றுதல் & பல்மாதிரி இயக்கம்",
                    summary: "நிலையான சமப் பிரிப்புக்குப் பதிலாக, SS-CCC ஒவ்வொரு Mac க்கும் அதன் பயன்படுத்தக்கூடிய நினைவகத்திற்கு ஏற்ப சரியான அடுக்குப் பங்கை ஒதுக்குகிறது மற்றும் பல மாதிரிகளை இணையாக நிர்வகிக்கிறது.",
                    bullets: [
                        "மாதிரியை யார் ஏற்றுவது? எப்போதும் வரிசை 0 POST /v1/cluster/plan வழியாகத் திட்டத்தை ஒருங்கிணைக்கும்; ஒவ்வொரு பணியாளரும் தனக்கு ஒதுக்கப்பட்ட அடுக்குகளை மட்டுமே ஏற்றும்.",
                        "ஒரே நேரத்தில் எத்தனை மாதிரிகள்? கூட்டுத்தொகை(எடைகள் + KV கேச்) ≤ பயன்படுத்தக்கூடிய கிளஸ்டர் நினைவகம் வரை எத்தனை மாதிரிகளையும் இணையாக இயக்கலாம்.",
                        "அடுக்கு சூத்திரம் & KV சுருக்கம்: அடுக்குகள்_i = மொத்தஅடுக்குகள் × (பயன்படும்_i / மொத்த_பயன்படும்); FP16 (~16k), 8-பிட் (~32k) அல்லது 4-பிட் (~64k+ சூழல்).",
                        "துண்டாக்கப்பட்ட முன்நிரப்பு (--prefill-step-size 512) மற்றும் SSD KV இறக்கம் (oMLX) பெரிய குறியீட்டுத் திட்டங்களில் நினைவக உயர்வைத் தடுக்கின்றன."
                    ],
                    codeSample: "--kv-bits 4 --quantized-kv-start 5000 --prefill-step-size 512\nPOST http://127.0.0.1:8000/v1/cluster/plan"
                ),
                HelpDocSection(
                    id: "setup-hybrid",
                    icon: "globe.europe.africa.fill",
                    accent: SolarisTheme.mint,
                    title: "6. அமைப்பு வழிகாட்டி: உள்ளூர் கிளஸ்டர் & கலப்பின உள்ளூர் + இணையம்",
                    summary: "உள்ளூர் TB/RDMA கிளஸ்டரை அமைத்து உலகளாவிய இணைய WAN வலையமைப்புடன் (Tailscale, WireGuard, ZeroTier அல்லது libp2p QUIC) இணைப்பதற்கான படிப்படியான வழிகாட்டி.",
                    bullets: [
                        "படி 1 (உள்ளூர்): ஒவ்வொரு உள்ளூர் Mac இலும் Thunderbolt பாலம் (setup_tb_network.sh) மற்றும் நினைவகப் பாதுகாப்பை (setup_wired_limit.sh) அமைக்கவும்.",
                        "படி 2 (நுழைவாயில் & மாதிரி): வரிசை 0 இல் FastAPI நுழைவாயில் (:8000) மற்றும் oMLX/Ollama/llama.cpp ஐத் தொடங்கி மாதிரி பணிமனையில் மாதிரியை ஏற்றவும்.",
                        "படி 3 (இணைய WAN): தொலைநிலை Macகளில் மறைகுறியாக்கப்பட்ட வலையை (Tailscale/WireGuard) இயக்கி அறை ID உடன் இணைய கிளஸ்டரில் சேரவும்.",
                        "படி 4 (கலப்பின இணைப்பு): ‘உள்ளூர் + இணையத்தை இணை’ என்பதைக் கிளிக் செய்யவும் — உள்ளூர் TB தீவுகள் விரைவான Tier-0 மையமாகவும் WAN முனைகள் கூடுதல் அடுக்குகளாகவும் செயல்படும்."
                    ],
                    codeSample: "WebSocket உரையாடல் ரிலே: ws://127.0.0.1:8000/ws/wan-chat\nஇணைப்பு: உள்ளூர் (TB/RDMA Tier-0) + இணைய WAN -> கலப்பின சூப்பர்கிளஸ்டர்"
                ),
                HelpDocSection(
                    id: "audio-party",
                    icon: "headphones.circle.fill",
                    accent: SolarisTheme.coral,
                    title: "7. நேரலை பங்கேற்பாளர் உரையாடல் & கிளஸ்டர் ஆடியோ-பார்ட்டி",
                    summary: "உரை உரையாடலுக்கு அருகிலேயே, பரவலாக்கப்பட்ட AI குழுக்களுக்காகக் கன்சோல் பார்ட்டி அறைகள் போன்ற முழுமையான ஆடியோ-பார்ட்டியை SS-CCC வழங்குகிறது.",
                    bullets: [
                        "நிகழ்நேர குரல்: பிரத்யேக /ws/wan-audio ரிலே வழியாக AVAudioEngine (16 kHz PCM16, Opus-இணக்கம்) பயன்படுத்துகிறது.",
                        "குரல் பயன்முறைகள்: அழுத்திப் பேசு (PTT) மற்றும் திறந்த மைக் மாற்றம், மைக் ஒலியடக்கம் & கேட்டல் நிறுத்தம்.",
                        "பங்கேற்பாளர் காட்சி: செயலில் பேசுவோரை நேரலை ஒலி அளவு மீட்டர், முனைப் பங்கு மற்றும் அறை நிலையுடன் காட்டுகிறது.",
                        "குறைந்தபட்ச அலைவரிசை: குரல் அலைவரிசை சாதாரண WAN அப்லிங்கின் 0.02% க்கும் குறைவாகவே பயன்படுத்துகிறது."
                    ],
                    codeSample: "WebSocket ஆடியோ ரிலே: ws://127.0.0.1:8000/ws/wan-audio\nஆடியோ வடிவம்: AVAudioEngine 16 kHz PCM16 (PTT / Open-Mic)"
                ),
                HelpDocSection(
                    id: "science-history",
                    icon: "chart.xyaxis.line",
                    accent: SolarisTheme.amber,
                    title: "8. அறிவியல் ஆய்வகம் (6 தாவல்கள்) & வரலாற்றுப் பதிவு",
                    summary: "அறிவியல் பகுதி ஆறு சிறப்புத் தாவல்களில் உள்ளூர் TB/RDMA கிளஸ்டர்கள், இணைய WAN கிளஸ்டர்கள் மற்றும் இரண்டின் நேரடி ஒப்பீட்டைப் பகுப்பாய்வு செய்கிறது.",
                    bullets: [
                        "தாவல் 1–2 (Roofline & WAN): Williams-Roofline (லாக்-லாக்), TTFT/TPOT, GPipe குமிழி, Petals/SWARM சுருக்கம், N=1..128 அளவிடுதல் & DiLoCo.",
                        "தாவல் 3–4 (நினைவகம் & ஆற்றல்): டிரான்ஸ்ஃபார்மர் நினைவகச் சமன்பாடு, TokenPowerBench (J/tok, EDP), பிராந்திய மின் கலவை (gCO₂/1M) & மேகக்கணி ஒப்பீடு.",
                        "தாவல் 5 (சோதனைகள் & ஏற்றுமதி): p50/p95/p99, CI95, SLO குட்புட் கொண்ட N=5/10/20 சோதனைகள் மற்றும் CSV, JSON, LaTeX, BibTeX ஏற்றுமதி.",
                        "தாவல் 6 (வரலாறு): தனிப்பட்ட நிலைகள் மற்றும் உலகளாவிய அளவீடுகளைத் தானாகவோ கைமுறையாகவோ காலத் தொடராகப் பதிவு செய்கிறது."
                    ],
                    codeSample: "பகுப்பாய்வு வரம்பு: உள்ளூர் (TB/RDMA) | இணைய WAN | ஒப்பீடு\nவரலாறு: நிலையைப் பதிவு செய் | உலகளாவியதைப் பதிவு செய் | தானியங்கிப் பதிவு"
                ),
                HelpDocSection(
                    id: "runtimes",
                    icon: "cpu.fill",
                    accent: SolarisTheme.mint,
                    title: "9. இயக்கநேரச் சேவைகள்: MLX, oMLX, Ollama & llama.cpp",
                    summary: "மாதிரி பணிமனையில், மாதிரிகளைத் தேர்ந்தெடுத்த உள்ளூர் சேவைக்காக நேரடியாகத் தொடங்கலாம், நேரலையில் கண்டறியலாம் அல்லது வடிவங்களுக்கு இடையே மாற்றலாம்.",
                    bullets: [
                        "oMLX (போர்ட் 8000): SSD KV கேச் மற்றும் OpenAI & Anthropic API களுடன் இயல்பு macOS MLX சேவை.",
                        "Ollama (போர்ட் 11434): உள்ளூர் GGUF மாதிரிகளுக்கான பிரபல சேவை; உள்ள மாதிரிகள் நேரலையில் படிக்கப்படும்.",
                        "llama.cpp (போர்ட் 8080): llama-server வழியாக நேரடி GGUF சேவை.",
                        "நேரலைக் கண்டறிதல்: SS-CCC இயங்கும் சேவைகளைத் தானாக ஆராய்ந்து கிடைக்கும் மாதிரிகளை உடனே காட்டும்."
                    ],
                    codeSample: "uvicorn core.api.gateway:app --host 127.0.0.1 --port 8000\nபோர்ட்கள்: oMLX :8000 | Ollama :11434 | llama.cpp :8080"
                ),
                HelpDocSection(
                    id: "agents-api",
                    icon: "sparkles.rectangle.stack.fill",
                    accent: SolarisTheme.emerald,
                    title: "10. AI முகவர்கள் (1-கிளிக்), மெனு பட்டி & உள்ளூர் APIகள்",
                    summary: "அனைத்து மேம்பாட்டுக் கருவிகளும் உள்ளூர் இடைமுகம் வழியாக முழு கிளஸ்டரையும் அணுகுகின்றன — மூலக் குறியீடு மேகக்கணிக்கு அனுப்பப்படுவதே இல்லை.",
                    bullets: [
                        "1-கிளிக் அமைப்பு: முகவர்கள் & IDEகள் தாவலில் இருந்து OpenCode, Hermes Agent மற்றும் Google Antigravity க்கான கட்டமைப்புகளை உருவாக்குகிறது.",
                        "பரந்த IDE ஆதரவு: Cursor, Continue, Open WebUI மற்றும் Apple Xcode உடன் தடையின்றி செயல்படுகிறது.",
                        "மெனு பட்டி பின்னணிப் பயன்முறை: Ollama போல பின்னணியில் முகவர்கள் & IDEகளுக்குத் தொடர்ந்து சேவையாற்ற மேல் மெனு பட்டியில் (⌘⇧M) சுருக்கவும்.",
                        "API கன்சோல்: தூண்டுதல்கள், தாமதம் மற்றும் செயல்திறனை நேரலையில் சோதிக்கும் உள்ளமைக்கப்பட்ட கன்சோல்."
                    ],
                    codeSample: "OpenAI முனையம்:    http://127.0.0.1:8000/v1/chat/completions\nAnthropic முனையம்: http://127.0.0.1:8000/v1/messages"
                ),
                HelpDocSection(
                    id: "updater-ci",
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    accent: SolarisTheme.amber,
                    title: "11. GitHub புதுப்பிப்பி & தானியங்கி CI பதிப்புக் கட்டுப்பாடு",
                    summary: "SS-CCC தானாகவே GitHub இல் புதிய நிரல் பதிப்பைக் கண்காணித்து மூல மற்றும் வெளியீட்டு நிறுவல்களைப் புதுப்பித்த நிலையில் வைத்திருக்கும்.",
                    bullets: [
                        "தானியங்கி சரிபார்ப்பு: தொடக்கத்திலும் ஒவ்வொரு 30 நிமிடங்களுக்கும் (அல்லது ⌘U) version.json, GitHub Releases மற்றும் main SHA உடன் ஒப்பிடுகிறது.",
                        "UpdatePromptSheet: மாற்றப் பதிவு மற்றும் கமிட் வேறுபாடுகளைச் செயலியிலேயே நேரடியாகக் காட்டுகிறது.",
                        "1-கிளிக் புதுப்பிப்பு: git pull + swift build ஐ இயக்கி, பயனர் 'செயலியை இப்போது மறுதொடக்கம் செய்' என்பதைக் கிளிக் செய்யும் வரை காத்திருக்கும்.",
                        "CI பதிப்புக் கட்டுப்பாடு: main க்கான ஒவ்வொரு தள்ளுதலும் scripts/bump_version.py ஐ இயக்கி vX.Y.Z குறியை அமைக்கும்."
                    ],
                    codeSample: "குறுக்குவழிகள்: ⌘U (புதுப்பிப்பு) | ⌘⇧M (மெனு பட்டி) | ⌘? (கையேடு)\nமேனிஃபெஸ்ட்: version.json + .github/workflows/auto-version-control.yml"
                ),
                HelpDocSection(
                    id: "launch-tests",
                    icon: "checkmark.shield.fill",
                    accent: SolarisTheme.emerald,
                    title: "12. தொடக்கம், பிழைத்திருத்தம் & 25-பகுதி சோதனைத் தொகுப்பு",
                    summary: "ஒரே கட்டளை macOS செயலியைத் தொகுத்து சாளரத்தைத் திறக்கும்; 25 தானியங்கி உலகளாவிய சோதனைகள் அனைத்து அம்சங்களையும் உறுதி செய்கின்றன.",
                    bullets: [
                        "செயலியைத் தொடங்கு: ./scripts/run_ssccc.sh Swift தொகுப்பை உருவாக்கி SS-CCC சாளரத்தைத் திறக்கும்.",
                        "25/25 உலகளாவிய சோதனைகள்: python3 tests/test_global_suite.py Swift உருவாக்கம், 17 மொழிகள், மெனு பட்டி பயன்முறை, 3-தாவல் மேலோட்டம், WAN & APIகளைச் சரிபார்க்கிறது.",
                        "பிழைத்திருத்தம்: Thunderbolt இணைப்பு இல்லாவிட்டால் ./scripts/setup_tb_network.sh ஐ மீண்டும் இயக்கவும்; நினைவக எச்சரிக்கைக்கு iogpu.wired_limit_mb ஐச் சரிபார்க்கவும்.",
                        "17 மொழிகள்: இயல்பாக ஆங்கிலத்தில் தொடங்கி DE, EN, FR, ES, PT, RU, JA, ZH, NL, AF, PL, CS, SK, HU, KO, HI மற்றும் TA இடையே நேரலையில் மாறும்."
                    ],
                    codeSample: "./scripts/run_ssccc.sh\npython3 tests/test_global_suite.py   # எதிர்பார்ப்பு: Ran 25 tests ... OK"
                )
            ]
        }
    }
}
