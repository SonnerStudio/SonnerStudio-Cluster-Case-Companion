import SwiftUI
import AppKit

struct ScienceBenchmarksView: View {
    @ObservedObject var vm: ClusterViewModel

    private let batchOptions = [1, 2, 4, 8, 16, 32]
    private let microBatchOptions = [1, 2, 4, 8, 16]
    private let promptOptions = [512, 2048, 8192, 16384, 32768]
    private let genOptions = [128, 512, 2048]
    private let bitOptions = [4, 8, 16]
    private let trialOptions = [5, 10, 20]
    private let dilocoOptions = [10, 50, 100, 500]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerAndScopeCard
                tabBarCard

                switch vm.sciActiveTab {
                case .roofline:
                    rooflineTabContent
                case .wanTopology:
                    wanTopologyTabContent
                case .memoryKv:
                    memoryKvTabContent
                case .energetics:
                    energeticsTabContent
                case .trialsExport:
                    trialsExportTabContent
                case .historyLog:
                    historyLogTabContent
                }
            }
            .padding(24)
        }
        .solarisShorttip(vm.shorttip(.science), id: "view_science_root", vm: vm)
    }

    // MARK: - Header, Scope Selector & Sub-Tab Bar

    private var headerAndScopeCard: some View {
        SolarisCard(accent: SolarisTheme.amber) {
            HazardStripesBar(height: 5, stripeWidth: 10, cornerRadius: 3, opacity: 0.85)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 12) {
                    Text(vm.t("sci_title"))
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Label(
                        vm.simulateMacStudio
                            ? L10n.tr(vm.language,
                                de: "SIMULATION · Realistische Apple-Silicon-Referenzwerte",
                                en: "SIMULATION · Realistic Apple Silicon Reference Values",
                                fr: "SIMULATION · Valeurs de référence Apple Silicon réalistes",
                                es: "SIMULACIÓN · Valores de referencia realistas Apple Silicon",
                                pt: "SIMULAÇÃO · Valores de referência realistas Apple Silicon",
                                ru: "СИМУЛЯЦИЯ · Эталонные показатели Apple Silicon",
                                ja: "シミュレーション · 実践的な Apple Silicon 参照値",
                                zh: "模拟模式 · Apple Silicon 真实参考基准")
                            : L10n.tr(vm.language,
                                de: "ECHTZEIT-DATEN · Gemessene System- & Endpunkt-Telemetrie",
                                en: "LIVE TELEMETRY · Measured System & Endpoint Metrics",
                                fr: "TÉLÉMÉTRIE EN DIRECT · Métriques système & points d'accès",
                                es: "DATOS EN VIVO · Telemetría medida de sistema y endpoints",
                                pt: "DADOS AO VIVO · Telemetria medida do sistema e endpoints",
                                ru: "ТЕЛЕМЕТРИЯ LIVE · Замеры системы и конечных точек",
                                ja: "ライブデータ · 実測システム＆エンドポイントテレメトリ",
                                zh: "实时遥测 · 实测系统与端点性能数据"),
                        systemImage: vm.simulateMacStudio ? "waveform.path.ecg" : "antenna.radiowaves.left.and.right"
                    )
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(vm.simulateMacStudio ? SolarisTheme.amberGlow : SolarisTheme.emerald)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill((vm.simulateMacStudio ? SolarisTheme.amber : SolarisTheme.emerald).opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke((vm.simulateMacStudio ? SolarisTheme.amber : SolarisTheme.emerald).opacity(0.45), lineWidth: 1)
                            )
                    )
                }
                Text(vm.t("sci_sub"))
                    .font(SolarisTheme.bodyLarge)
                    .foregroundColor(SolarisTheme.textSecondary)
            }

            Divider().opacity(0.25)

            // Full-width Scope Selector (no clipping of localized scope title) + Quick History Capture
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Text(vm.t("sci_scope_label") + ":")
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(ScienceScope.allCases) { scope in
                            let isSelected = vm.sciScope == scope
                            Button {
                                vm.sciScope = scope
                            } label: {
                                Text(scope.localizedTitle(vm.language))
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .black : SolarisTheme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(isSelected ? SolarisTheme.mint : SolarisTheme.cardElevated)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(isSelected ? SolarisTheme.mint : Color.white.opacity(0.10), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer()

                    Button {
                        let snapNote = L10n.tr(vm.language,
                            de: "Schnappschuss (\(vm.sciScope.localizedTitle(vm.language)))",
                            en: "Snapshot (\(vm.sciScope.localizedTitle(vm.language)))",
                            fr: "Capture (\(vm.sciScope.localizedTitle(vm.language)))",
                            es: "Captura (\(vm.sciScope.localizedTitle(vm.language)))",
                            pt: "Captura (\(vm.sciScope.localizedTitle(vm.language)))",
                            ru: "Снимок (\(vm.sciScope.localizedTitle(vm.language)))",
                            ja: "スナップショット (\(vm.sciScope.localizedTitle(vm.language)))",
                            zh: "快照 (\(vm.sciScope.localizedTitle(vm.language)))")
                        vm.recordScienceHistory(position: .globalAll, note: snapNote)
                    } label: {
                        Label(L10n.tr(vm.language,
                            de: "Verlauf aufzeichnen (\(vm.sciHistoryEntries.count))",
                            en: "Record History (\(vm.sciHistoryEntries.count))",
                            fr: "Enregistrer l'historique (\(vm.sciHistoryEntries.count))",
                            es: "Registrar historial (\(vm.sciHistoryEntries.count))",
                            pt: "Registar histórico (\(vm.sciHistoryEntries.count))",
                            ru: "Записать историю (\(vm.sciHistoryEntries.count))",
                            ja: "履歴を記録 (\(vm.sciHistoryEntries.count))",
                            zh: "记录历史 (\(vm.sciHistoryEntries.count))"), systemImage: "record.circle")
                    }
                    .buttonStyle(.bordered)
                    .tint(SolarisTheme.amber)
                }

                HStack(spacing: 10) {
                    Text(L10n.tr(vm.language,
                        de: "\(vm.activeScienceNodes.count) Knoten · \(Int(vm.activeTotalUsableVramGB)) GB nutzbar",
                        en: "\(vm.activeScienceNodes.count) nodes · \(Int(vm.activeTotalUsableVramGB)) GB usable",
                        fr: "\(vm.activeScienceNodes.count) nœuds · \(Int(vm.activeTotalUsableVramGB)) Go utilisables",
                        es: "\(vm.activeScienceNodes.count) nodos · \(Int(vm.activeTotalUsableVramGB)) GB utilizables",
                        pt: "\(vm.activeScienceNodes.count) nós · \(Int(vm.activeTotalUsableVramGB)) GB utilizáveis",
                        ru: "\(vm.activeScienceNodes.count) узл. · \(Int(vm.activeTotalUsableVramGB)) ГБ доступно",
                        ja: "\(vm.activeScienceNodes.count) ノード · \(Int(vm.activeTotalUsableVramGB)) GB 利用可能",
                        zh: "\(vm.activeScienceNodes.count) 个节点 · \(Int(vm.activeTotalUsableVramGB)) GB 可用"))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(vm.isWanScienceActive ? SolarisTheme.mint : SolarisTheme.amberGlow)
                    Text("·")
                        .foregroundColor(SolarisTheme.textSecondary)
                    Text(vm.activeBottleneckRegime)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(SolarisTheme.coral)
                    Spacer()
                    if let last = vm.sciHistoryEntries.last {
                        Text(L10n.tr(vm.language,
                            de: "Letzter Verlauf: \(last.timestamp) (\(last.note))",
                            en: "Last History: \(last.timestamp) (\(last.note))",
                            fr: "Dernière entrée : \(last.timestamp) (\(last.note))",
                            es: "Último registro: \(last.timestamp) (\(last.note))",
                            pt: "Último registo: \(last.timestamp) (\(last.note))",
                            ru: "Последняя запись: \(last.timestamp) (\(last.note))",
                            ja: "最新記録: \(last.timestamp) (\(last.note))",
                            zh: "最新记录：\(last.timestamp) (\(last.note))"))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }
            }

            if vm.isWanScienceActive && vm.wanPeers.count <= 1 {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(SolarisTheme.amberGlow)
                    Text(L10n.tr(vm.language,
                        de: "Im Internet-WAN-Verbund ist aktuell nur der lokale Knoten aktiv. Öffne 'Internet-Cluster & Chat' für einen Forschungs-Schwarm oder Welt-Verbund, um Multi-Region-WAN-Latenzen direkt hier zu vermessen.",
                        en: "Only the local node is currently active in the Internet WAN cluster. Open 'Internet Cluster & Chat' to spin up a research swarm or global mesh and benchmark multi-region WAN latencies here.",
                        fr: "Seul le nœud local est actif dans le cluster WAN. Ouvrez « Cluster Internet & Chat » pour lancer un essaim de recherche et mesurer les latences multi-régions ici.",
                        es: "Solo el nodo local está activo en el clúster WAN. Abre «Clúster Internet y Chat» para lanzar un enjambre de investigación y medir latencias multirregión aquí.",
                        pt: "Apenas o nó local está ativo no cluster WAN. Abra 'Cluster Internet e Chat' para carregar um enxame de investigação e medir latências multi-região aqui.",
                        ru: "В интернет-кластере пока активен только локальный узел. Откройте «Интернет-кластер и Чат», чтобы запустить рой и замерить WAN-задержки.",
                        ja: "現在 WAN クラスタで有効なのはローカルノードのみです。「インターネットクラスタ・チャット」から研究用スウォームを起動して複数リージョンの遅延を計測できます。",
                        zh: "当前互联网广域网集群中仅本地节点处于激活状态。请前往“互联网集群与聊天”加载研究集群，以在此测量跨区域延迟。"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                    Spacer()
                    Button(L10n.tr(vm.language,
                        de: "Forschungs-Schwarm (12 Macs) laden",
                        en: "Load Research Swarm (12 Macs)",
                        fr: "Charger essaim de recherche (12 Macs)",
                        es: "Cargar enjambre científico (12 Macs)",
                        pt: "Carregar enxame científico (12 Macs)",
                        ru: "Загрузить рой (12 Mac)",
                        ja: "研究スウォーム (12台) を読込",
                        zh: "加载科研集群 (12 台 Mac)")) {
                        vm.populateMegaClusterSwarm(count: 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(SolarisTheme.mint)
                }
                .padding(10)
                .background(SolarisTheme.cardElevated)
                .cornerRadius(10)
            }
        }
    }

    private var tabBarCard: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(ScienceLabTab.allCases) { tab in
                let selected = vm.sciActiveTab == tab
                Button {
                    vm.sciActiveTab = tab
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                        Text(tabLabel(for: tab))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .font(.system(size: 13, weight: selected ? .bold : .medium))
                    .foregroundColor(selected ? .black : SolarisTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selected ? SolarisTheme.amber : SolarisTheme.cardElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selected ? SolarisTheme.amberGlow : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tabLabel(for tab: ScienceLabTab) -> String {
        switch tab {
        case .roofline: return vm.t("sci_tab_roofline")
        case .wanTopology: return vm.t("sci_tab_wan")
        case .memoryKv: return vm.t("sci_tab_memory")
        case .energetics: return vm.t("sci_tab_energy")
        case .trialsExport: return vm.t("sci_tab_trials")
        case .historyLog: return vm.t("sci_tab_history")
        }
    }

    // MARK: - Tab 1: Roofline & Bottleneck Analysis

    private var rooflineTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            SolarisCard(accent: SolarisTheme.mint) {
                HStack {
                    Text(vm.t("sci_workload_title"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Text("P(I) = min(β · I, π_eff) · B* = \(vm.criticalBatchSizeBStar)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(SolarisTheme.amberGlow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(SolarisTheme.cardElevated)
                        .cornerRadius(6)
                }

                // Workload Pickers (2x2 Grid with labelsHidden for clean spacing)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language, de: "Batch-Größe (B)", en: "Batch Size (B)", fr: "Taille de batch (B)", es: "Tamaño de lote (B)", pt: "Tamanho de lote (B)", ru: "Размер батча (B)", ja: "バッチサイズ (B)", zh: "批大小 (B)"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Batch", selection: $vm.sciBatchSize) {
                            ForEach(batchOptions, id: \.self) { b in
                                Text("B=\(b)").tag(b)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language, de: "Mikro-Batches (M)", en: "Micro-Batches (M)", fr: "Micro-batchs (M)", es: "Microlotes (M)", pt: "Microlotes (M)", ru: "Микро-батчи (M)", ja: "マイクロバッチ (M)", zh: "微批次 (M)"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Micro", selection: $vm.sciMicroBatches) {
                            ForEach(microBatchOptions, id: \.self) { m in
                                Text("M=\(m)").tag(m)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language, de: "Eingabelänge (S_prompt)", en: "Prompt Length (S_prompt)", fr: "Longueur du prompt (S_prompt)", es: "Longitud de entrada (S_prompt)", pt: "Comprimento de entrada (S_prompt)", ru: "Длина входа (S_prompt)", ja: "プロンプト長 (S_prompt)", zh: "输入长度 (S_prompt)"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Prompt", selection: $vm.sciPromptTokens) {
                            ForEach(promptOptions, id: \.self) { p in
                                Text(p >= 1024 ? "\(p / 1024)k" : "\(p)").tag(p)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language, de: "Gewichts-Genauigkeit", en: "Weight Precision", fr: "Précision des poids", es: "Precisión de pesos", pt: "Precisão dos pesos", ru: "Точность весов", ja: "重み量子化精度", zh: "权重精度"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Bits", selection: $vm.sciWeightBits) {
                            ForEach(bitOptions, id: \.self) { bits in
                                Text(bits == 16 ? "FP16" : L10n.tr(vm.language, de: "\(bits)-Bit", en: "\(bits)-Bit", fr: "\(bits) bits", es: "\(bits) bits", pt: "\(bits) bits", ru: "\(bits) бит", ja: "\(bits)-bit", zh: "\(bits)-bit")).tag(bits)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                }

                RooflineCanvasView(
                    nodes: vm.activeScienceNodes,
                    decodeIntensity: vm.decodeArithmeticIntensity,
                    prefillIntensity: vm.prefillArithmeticIntensity,
                    effectiveCeilingTFLOPS: vm.activeEffectiveRooflineCeilingTFLOPS,
                    showWanCeiling: vm.activeScienceNodes.count > 1
                )
                .frame(height: 260)
                .padding(.top, 6)

                HStack(spacing: 20) {
                    Label(
                        String(format: "Decode I = %.2f FLOP/B", vm.decodeArithmeticIntensity),
                        systemImage: "circle.fill"
                    )
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(SolarisTheme.mint)

                    Label(
                        String(format: "Prefill I = %.0f FLOP/B", vm.prefillArithmeticIntensity),
                        systemImage: "diamond.fill"
                    )
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(SolarisTheme.amberGlow)

                    if vm.activeScienceNodes.count > 1 {
                        Label(
                            String(format: L10n.tr(vm.language,
                                de: "Eff. Netz-Decke: %.1f TFLOPS",
                                en: "Eff. Net Ceiling: %.1f TFLOPS",
                                fr: "Plafond réseau eff. : %.1f TFLOPS",
                                es: "Techo red ef.: %.1f TFLOPS",
                                pt: "Teto rede ef.: %.1f TFLOPS",
                                ru: "Потолок сети: %.1f TFLOPS",
                                ja: "実効ネット上限: %.1f TFLOPS",
                                zh: "有效网络天花板：%.1f TFLOPS"), vm.activeEffectiveRooflineCeilingTFLOPS),
                            systemImage: "line.diagonal"
                        )
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(SolarisTheme.coral)
                    }

                    Spacer()

                    Text(String(format: L10n.tr(vm.language,
                        de: "Spitze: %.1f TFLOPS · Eff. BW: %.0f GB/s",
                        en: "Peak: %.1f TFLOPS · Eff. BW: %.0f GB/s",
                        fr: "Crête : %.1f TFLOPS · BP eff. : %.0f Go/s",
                        es: "Pico: %.1f TFLOPS · AB ef.: %.0f GB/s",
                        pt: "Pico: %.1f TFLOPS · LB ef.: %.0f GB/s",
                        ru: "Пик: %.1f TFLOPS · Эфф. ПС: %.0f ГБ/с",
                        ja: "ピーク: %.1f TFLOPS · 実効帯域: %.0f GB/s",
                        zh: "峰值：%.1f TFLOPS · 有效带宽：%.0f GB/s"), vm.activePeakFP16TFLOPS, vm.activeEffectiveDecodeBandwidthGBs))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(SolarisTheme.textSecondary)
                }
            }

            // Phase Latencies & Bottleneck Classifier
            SolarisCard {
                Text(vm.t("sci_metrics_title"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                HStack(spacing: 14) {
                    ScienceMetricTile(
                        label: "TTFT (Prefill)",
                        value: vm.activeTTFTMs >= 1000
                            ? String(format: "%.2f s", vm.activeTTFTMs / 1000.0)
                            : String(format: "%.0f ms", vm.activeTTFTMs),
                        sub: "\(vm.sciPromptTokens) tok · ~62% MFU",
                        accent: SolarisTheme.amberGlow
                    )
                    ScienceMetricTile(
                        label: "TPOT (Decode)",
                        value: String(format: "%.1f ms/tok", vm.activeTPOTMs),
                        sub: String(format: "%.1f tok/s (B=%d, M=%d)", vm.activeTokPerSec, vm.sciBatchSize, vm.sciMicroBatches),
                        accent: SolarisTheme.mint
                    )
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "GPipe-Blase & B*", en: "GPipe Bubble & B*", fr: "Bulle GPipe & B*", es: "Burbuja GPipe y B*", pt: "Bolha GPipe e B*", ru: "Пузырь GPipe и B*", ja: "GPipe バブル & B*", zh: "GPipe 气泡与 B*"),
                        value: String(format: "%.1f %%", vm.activePipelineBubbleFraction * 100.0),
                        sub: L10n.tr(vm.language,
                            de: "Krit. Batch B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) ms",
                            en: "Crit. Batch B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) ms",
                            fr: "Batch crit. B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) ms",
                            es: "Lote crít. B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) ms",
                            pt: "Lote crít. B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) ms",
                            ru: "Крит. батч B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) мс",
                            ja: "臨界バッチ B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) ms",
                            zh: "临界批 B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) ms"),
                        accent: SolarisTheme.coral
                    )
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "Energie & EDP", en: "Energy & EDP", fr: "Énergie & EDP", es: "Energía y EDP", pt: "Energia e EDP", ru: "Энергия и EDP", ja: "エネルギー & EDP", zh: "能耗与 EDP"),
                        value: String(format: "%.2f J/tok", vm.activeJoulesPerToken),
                        sub: String(format: "%.0f W · EDP %.3f J·s", vm.activeWatts, vm.activeEDPJoulesSec),
                        accent: SolarisTheme.emerald
                    )
                }
            }

            // Hybrid Local vs WAN Comparison Card
            if vm.sciScope == .hybridCompare {
                SolarisCard(accent: SolarisTheme.amber) {
                    Text(L10n.tr(vm.language,
                        de: "Direktvergleich: Lokaler TB/RDMA-Verbund vs. Internet-WAN-Verbund",
                        en: "Direct Comparison: Local TB/RDMA Cluster vs. Internet WAN Cluster",
                        fr: "Comparaison directe : Cluster local TB/RDMA vs Cluster WAN",
                        es: "Comparación directa: Clúster local TB/RDMA vs Clúster WAN",
                        pt: "Comparação direta: Cluster local TB/RDMA vs Cluster WAN",
                        ru: "Прямое сравнение: Локальный TB/RDMA vs Интернет-WAN кластер",
                        ja: "直接比較: ローカル TB/RDMA vs インターネット WAN",
                        zh: "直接对比：本地 TB/RDMA 集群 vs 互联网 WAN 集群"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 10) {
                        GridRow {
                            Text(L10n.tr(vm.language, de: "Kenngröße", en: "Metric", fr: "Métrique", es: "Métrica", pt: "Métrica", ru: "Показатель", ja: "指標", zh: "指标")).foregroundColor(SolarisTheme.textSecondary)
                            Text(L10n.tr(vm.language, de: "Lokal (TB/RDMA)", en: "Local (TB/RDMA)", fr: "Local (TB/RDMA)", es: "Local (TB/RDMA)", pt: "Local (TB/RDMA)", ru: "Локальный (TB/RDMA)", ja: "ローカル (TB/RDMA)", zh: "本地 (TB/RDMA)")).foregroundColor(SolarisTheme.amberGlow)
                            Text(L10n.tr(vm.language, de: "Internet-WAN (\(vm.wanPeers.count) Knoten)", en: "Internet WAN (\(vm.wanPeers.count) nodes)", fr: "WAN Internet (\(vm.wanPeers.count) nœuds)", es: "WAN Internet (\(vm.wanPeers.count) nodos)", pt: "WAN Internet (\(vm.wanPeers.count) nós)", ru: "Интернет-WAN (\(vm.wanPeers.count) узл.)", ja: "インターネット WAN (\(vm.wanPeers.count) ノード)", zh: "互联网 WAN (\(vm.wanPeers.count) 节点)")).foregroundColor(SolarisTheme.mint)
                        }
                        .font(SolarisTheme.bodyBold)
                        Divider().gridCellUnsizedAxes(.horizontal)
                        GridRow {
                            Text(L10n.tr(vm.language, de: "Gesamt-RAM / Nutzbar", en: "Total RAM / Usable", fr: "RAM totale / Utilisable", es: "RAM total / Utilizable", pt: "RAM total / Utilizável", ru: "Всего ОЗУ / Доступно", ja: "総 RAM / 利用可能", zh: "总内存 / 可用显存"))
                            Text("\(Int(vm.totalPhysicalRamGB)) GB / \(Int(vm.totalUsableVramGB)) GB")
                            Text("\(Int(vm.wanTotalRamGB)) GB / \(Int(vm.wanTotalUsableVramGB)) GB")
                        }
                        GridRow {
                            Text(L10n.tr(vm.language, de: "Verbindungs-Latenz pro Schritt", en: "Link Latency per Step", fr: "Latence par pas", es: "Latencia por paso", pt: "Latência por passo", ru: "Задержка связи за шаг", ja: "ステップあたりの通信遅延", zh: "单步通信延迟"))
                            Text(String(format: "%.3f ms", vm.estimatedInterconnectOverheadMs))
                            Text(String(format: "%.1f ms", vm.wanTotalRttMs))
                        }
                        GridRow {
                            Text(L10n.tr(vm.language, de: "Geschätzter Durchsatz (Decode)", en: "Estimated Throughput (Decode)", fr: "Débit estimé (Decode)", es: "Rendimiento estimado (Decode)", pt: "Débito estimado (Decode)", ru: "Оценка скорости (Decode)", ja: "推定スループット (Decode)", zh: "预计解码吞吐率"))
                            Text(String(format: "%.1f tok/s", vm.estimatedTokPerSec))
                            Text(String(format: "%.1f tok/s", vm.wanEstimatedTokPerSec))
                        }
                        GridRow {
                            Text(L10n.tr(vm.language, de: "Energiebedarf pro Token", en: "Energy per Token", fr: "Énergie par jeton", es: "Energía por token", pt: "Energia por token", ru: "Энергия на токен", ja: "トークンあたり消費電力", zh: "单 Token 能耗"))
                            Text(String(format: "%.2f J/tok", vm.estimatedJoulesPerToken))
                            Text(String(format: "%.2f J/tok", vm.activeJoulesPerToken))
                        }
                    }
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(SolarisTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Active Cluster Node Table
            SolarisCard {
                Text(vm.t("sci_roofline"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                let totalBw = max(1.0, vm.activeAggregateBandwidthGBs)
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text(L10n.tr(vm.language, de: "Knoten / Chip", en: "Node / Chip", fr: "Nœud / Puce", es: "Nodo / Chip", pt: "Nó / Chip", ru: "Узел / Чип", ja: "ノード / チップ", zh: "节点 / 芯片")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Bandbreite", en: "Bandwidth", fr: "Bande passante", es: "Ancho de banda", pt: "Largura de banda", ru: "Проп. спос.", ja: "帯域幅", zh: "带宽")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Spitze FP16", en: "Peak FP16", fr: "Crête FP16", es: "Pico FP16", pt: "Pico FP16", ru: "Пик FP16", ja: "ピーク FP16", zh: "峰值 FP16")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Knickpunkt", en: "Ridge Point", fr: "Point de coude", es: "Punto de inflexión", pt: "Ponto de crista", ru: "Точка излома", ja: "リッジ点", zh: "算力拐点")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Schicht-Anteil", en: "Layer Share", fr: "Part couches", es: "Cuota capas", pt: "Quota camadas", ru: "Доля слоёв", ja: "層割り当て", zh: "分层占比")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Verbindung / RTT", en: "Link / RTT", fr: "Lien / RTT", es: "Enlace / RTT", pt: "Ligação / RTT", ru: "Связь / RTT", ja: "リンク / RTT", zh: "链路 / RTT")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Leistung", en: "Power", fr: "Puissance", es: "Potencia", pt: "Potência", ru: "Мощность", ja: "消費電力", zh: "功耗")).foregroundColor(SolarisTheme.textSecondary)
                    }
                    .font(SolarisTheme.bodyBold)

                    Divider().gridCellUnsizedAxes(.horizontal)

                    ForEach(Array(vm.activeScienceNodes.prefix(16).enumerated()), id: \.element.id) { idx, node in
                        let share = (node.bandwidthGBs / totalBw) * 100.0
                        GridRow {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.name)
                                    .font(SolarisTheme.bodyBold)
                                    .foregroundColor(idx == 0 ? SolarisTheme.amberGlow : SolarisTheme.mint)
                                Text("\(node.chip) · \(Int(node.totalRamGB)) GB")
                                    .font(Font.caption)
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }
                            Text("\(Int(node.bandwidthGBs)) GB/s")
                            Text(String(format: "%.1f TFLOPS", node.peakFP16TFLOPS))
                            Text(String(format: "%.1f FLOP/B", node.ridgePointFLOPPerByte))
                            Text(String(format: "%.1f %%", share))
                            Text(node.linkLabel)
                            Text("\(Int(node.typicalWatts)) W")
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(SolarisTheme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if vm.activeScienceNodes.count > 16 {
                    Text(L10n.tr(vm.language,
                        de: "… plus \(vm.activeScienceNodes.count - 16) weitere WAN-Knoten im Verbund.",
                        en: "… plus \(vm.activeScienceNodes.count - 16) additional WAN nodes in cluster.",
                        fr: "… et \(vm.activeScienceNodes.count - 16) autres nœuds WAN dans le cluster.",
                        es: "… más \(vm.activeScienceNodes.count - 16) nodos WAN adicionales en el clúster.",
                        pt: "… mais \(vm.activeScienceNodes.count - 16) nós WAN adicionais no cluster.",
                        ru: "… и ещё \(vm.activeScienceNodes.count - 16) WAN-узлов в кластере.",
                        ja: "… 他 \(vm.activeScienceNodes.count - 16) 台の WAN ノードが参加中。",
                        zh: "… 以及集群中另外 \(vm.activeScienceNodes.count - 16) 个广域网节点。"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
            }

            // Multi-Model-Mode (MMM) Scientific Evaluation Card
            mmmScienceEvaluationCard
        }
    }

    private var mmmScienceEvaluationCard: some View {
        SolarisCard(accent: SolarisTheme.mint) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr(vm.language,
                        de: "Multi-Model-Mode (MMM) — Wissenschaftliche Auswertung",
                        en: "Multi-Model Mode (MMM) — Scientific Evaluation",
                        fr: "Mode Multi-Modèle (MMM) — Évaluation scientifique",
                        es: "Modo Multimodelo (MMM) — Evaluación científica",
                        pt: "Modo Multimodelo (MMM) — Avaliação científica",
                        ru: "Multi-Model-Mode (MMM) — Научная оценка",
                        ja: "マルチモデルモード (MMM) — 科学的評価",
                        zh: "多模型模式 (MMM) — 科学评估"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(L10n.tr(vm.language,
                        de: "Direkte Auswertung der zusammengeführten Multi-Modell-Läufe (\(vm.mmmScope.localizedTitle(vm.language)) · \(vm.mmmStrategy.localizedTitle(vm.language))) inkl. Multi-IDE-Last.",
                        en: "Direct analysis of aggregated multi-model runs (\(vm.mmmScope.localizedTitle(vm.language)) · \(vm.mmmStrategy.localizedTitle(vm.language))) incl. Multi-IDE load.",
                        fr: "Analyse directe des exécutions multi-modèles agrégées (\(vm.mmmScope.localizedTitle(vm.language)) · \(vm.mmmStrategy.localizedTitle(vm.language))) avec charge Multi-IDE.",
                        es: "Análisis directo de ejecuciones multimodelo (\(vm.mmmScope.localizedTitle(vm.language)) · \(vm.mmmStrategy.localizedTitle(vm.language))) incl. carga Multi-IDE.",
                        pt: "Análise direta das execuções multimodelo (\(vm.mmmScope.localizedTitle(vm.language)) · \(vm.mmmStrategy.localizedTitle(vm.language))) incl. carga Multi-IDE.",
                        ru: "Прямой анализ объединённых запусков MMM (\(vm.mmmScope.localizedTitle(vm.language)) · \(vm.mmmStrategy.localizedTitle(vm.language))) с нагрузкой Multi-IDE.",
                        ja: "統合マルチモデル実行 (\(vm.mmmScope.localizedTitle(vm.language)) · \(vm.mmmStrategy.localizedTitle(vm.language))) とマルチ IDE 負荷を直接評価します。",
                        zh: "直接评估多模型聚合运行表现 (\(vm.mmmScope.localizedTitle(vm.language)) · \(vm.mmmStrategy.localizedTitle(vm.language)))，含多 IDE 并发负载。"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                if let lastMmm = vm.mmmLastResult {
                    Button(L10n.tr(vm.language,
                        de: "MMM-Lauf in Verlauf übernehmen",
                        en: "Record MMM Run to History",
                        fr: "Ajouter MMM à l'historique",
                        es: "Guardar ejecución MMM en historial",
                        pt: "Guardar execução MMM no histórico",
                        ru: "Добавить MMM в историю",
                        ja: "MMM 実行を履歴に記録",
                        zh: "将 MMM 运行记入历史")) {
                        vm.recordScienceHistoryFromMMM(lastMmm)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SolarisTheme.mint)
                    .foregroundColor(.black)
                }
            }

            HStack(spacing: 14) {
                ScienceMetricTile(
                    label: L10n.tr(vm.language, de: "MMM Durchsatz (Mittel)", en: "MMM Throughput (Mean)", fr: "Débit MMM (Moyenne)", es: "Rendimiento MMM (Medio)", pt: "Débito MMM (Média)", ru: "Скорость MMM (Средн.)", ja: "MMM 平均スループット", zh: "MMM 平均吞吐"),
                    value: String(format: "%.1f tok/s", vm.mmmMeanObservedTokPerSec),
                    sub: L10n.tr(vm.language,
                        de: "\(vm.mmmHistory.count) Läufe · \(vm.mmmActiveSlots.count) aktive Slots",
                        en: "\(vm.mmmHistory.count) runs · \(vm.mmmActiveSlots.count) active slots",
                        fr: "\(vm.mmmHistory.count) exéc. · \(vm.mmmActiveSlots.count) slots actifs",
                        es: "\(vm.mmmHistory.count) ejec. · \(vm.mmmActiveSlots.count) slots activos",
                        pt: "\(vm.mmmHistory.count) exec. · \(vm.mmmActiveSlots.count) slots ativos",
                        ru: "\(vm.mmmHistory.count) зап. · \(vm.mmmActiveSlots.count) акт. слотов",
                        ja: "\(vm.mmmHistory.count) 回実行 · \(vm.mmmActiveSlots.count) 有効スロット",
                        zh: "\(vm.mmmHistory.count) 次运行 · \(vm.mmmActiveSlots.count) 个活跃槽位"),
                    accent: SolarisTheme.mint
                )
                ScienceMetricTile(
                    label: L10n.tr(vm.language, de: "Speedup vs. Einzelmodell", en: "Speedup vs. Single Model", fr: "Gain vs Modèle unique", es: "Aceleración vs Modelo único", pt: "Ganho vs Modelo único", ru: "Ускорение vs 1 модель", ja: "単体モデル比の高速化", zh: "对比单模型加速比"),
                    value: String(format: "%.2fx", vm.mmmMeanSpeedupFactor),
                    sub: vm.mmmLastResult.map {
                        $0.isLiveExecution
                            ? L10n.tr(vm.language, de: "Live SSE", en: "Live SSE", fr: "SSE direct", es: "SSE en vivo", pt: "SSE ao vivo", ru: "Live SSE", ja: "ライブ SSE", zh: "实时 SSE")
                            : L10n.tr(vm.language, de: "Simulation", en: "Simulation", fr: "Simulation", es: "Simulación", pt: "Simulação", ru: "Симуляция", ja: "シミュレーション", zh: "模拟")
                    } ?? L10n.tr(vm.language, de: "Theoretische Schätzung", en: "Theoretical Estimate", fr: "Estimation théorique", es: "Estimación teórica", pt: "Estimativa teórica", ru: "Теоретическая оценка", ja: "理論推定値", zh: "理论估算"),
                    accent: SolarisTheme.amberGlow
                )
                ScienceMetricTile(
                    label: L10n.tr(vm.language, de: "VRAM-Pool & Multi-IDE", en: "VRAM Pool & Multi-IDE", fr: "Pool VRAM & Multi-IDE", es: "Pool VRAM y Multi-IDE", pt: "Pool VRAM e Multi-IDE", ru: "Пул VRAM и Multi-IDE", ja: "VRAM プール & マルチ IDE", zh: "显存池与多 IDE"),
                    value: String(format: "%.1f / %.1f GB", vm.mmmTotalRequiredVramGB, vm.mmmUsableVramPoolGB),
                    sub: String(format: L10n.tr(vm.language,
                        de: "%.1f tok/s je Client (%d IDEs)",
                        en: "%.1f tok/s per client (%d IDEs)",
                        fr: "%.1f tok/s par client (%d IDE)",
                        es: "%.1f tok/s por cliente (%d IDEs)",
                        pt: "%.1f tok/s por cliente (%d IDEs)",
                        ru: "%.1f tok/с на клиент (%d IDE)",
                        ja: "クライアント別 %.1f tok/s (%d IDE)",
                        zh: "每客户端 %.1f tok/s (%d 个 IDE)"), vm.mmmPerClientTokPerSec, vm.mmmActiveClientCount),
                    accent: vm.mmmFitsInClusterPool ? SolarisTheme.emerald : SolarisTheme.coral
                )
            }

            let aneMetrics = vm.aneSplitSpeedupAndEnergyRatio()
            let kvMetrics = vm.cacheGenCompressionMetrics()
            HStack(spacing: 14) {
                ScienceMetricTile(
                    label: "ANE-Prefill / MLX-Decode",
                    value: String(format: "EDP ×%.2f", aneMetrics.prefillSpeedup),
                    sub: String(format: L10n.tr(vm.language,
                        de: "-%.1f %% Energie · %@",
                        en: "-%.1f %% energy · %@",
                        fr: "-%.1f %% énergie · %@",
                        es: "-%.1f %% energía · %@",
                        pt: "-%.1f %% energia · %@",
                        ru: "-%.1f %% энергии · %@",
                        ja: "-%.1f %% 省電力 · %@",
                        zh: "节能 -%.1f %% · %@"), aneMetrics.energySavingsPct, vm.splitPhaseComputeMode.localizedTitle(vm.language)),
                    accent: SolarisTheme.emerald
                )
                ScienceMetricTile(
                    label: L10n.tr(vm.language, de: "KV-CacheGen & Prefix-Hit", en: "KV CacheGen & Prefix Hit", fr: "KV CacheGen & Préfixe", es: "KV CacheGen y Acierto Prefijo", pt: "KV CacheGen e Acerto Prefixo", ru: "KV CacheGen и Префикс", ja: "KV CacheGen & プレフィックス命中", zh: "KV CacheGen 与前缀命中"),
                    value: String(format: "%.1f× · %.0f %%", kvMetrics.compressionRatio, kvMetrics.prefixHitRatePct),
                    sub: String(format: "%.2f GB → %.2f GB (-%.0f %% TTFT)", kvMetrics.rawKvSizeGB, kvMetrics.compressedTransferGB, kvMetrics.estimatedTtftReductionPct),
                    accent: SolarisTheme.amberGlow
                )
            }
        }
    }

    // MARK: - Tab 2: WAN Topology, Latency Decomposition & Scaling

    private var wanTopologyTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            SolarisCard(accent: SolarisTheme.mint) {
                Text(L10n.tr(vm.language,
                    de: "Internet-WAN-Latenzzerlegung & Aktivierungs-Kompression",
                    en: "Internet WAN Latency Decomposition & Activation Compression",
                    fr: "Décomposition de latence WAN & compression des activations",
                    es: "Desglose de latencia WAN y compresión de activaciones",
                    pt: "Decomposição de latência WAN e compressão de ativações",
                    ru: "Разложение задержки WAN и сжатие активаций",
                    ja: "WAN 遅延内訳とアクティベーション圧縮",
                    zh: "互联网 WAN 延迟拆解与激活张量压缩"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language,
                            de: "Aktivierungs-Kompression (Petals / SWARM)",
                            en: "Activation Compression (Petals / SWARM)",
                            fr: "Compression des activations (Petals / SWARM)",
                            es: "Compresión de activaciones (Petals / SWARM)",
                            pt: "Compressão de ativações (Petals / SWARM)",
                            ru: "Сжатие активаций (Petals / SWARM)",
                            ja: "アクティベーション圧縮 (Petals / SWARM)",
                            zh: "激活压缩 (Petals / SWARM)"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Compression", selection: $vm.sciActivationCompression) {
                            ForEach(ActivationCompressionMode.allCases) { mode in
                                Text(mode.localizedTitle(vm.language)).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        Text(vm.sciActivationCompression.localizedQualityNote(vm.language))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.mint)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language,
                            de: "WAN-Nachzügler / Paketverlust: \(Int(vm.sciStragglerRate * 100)) %",
                            en: "WAN Straggler / Packet Loss Rate: \(Int(vm.sciStragglerRate * 100)) %",
                            fr: "Taux de retardataires / pertes WAN : \(Int(vm.sciStragglerRate * 100)) %",
                            es: "Tasa de rezagados / pérdida WAN: \(Int(vm.sciStragglerRate * 100)) %",
                            pt: "Taxa de atrasados / perda WAN: \(Int(vm.sciStragglerRate * 100)) %",
                            ru: "Доля отст. узлов / потерь WAN: \(Int(vm.sciStragglerRate * 100)) %",
                            ja: "WAN ストラグラー / パケット損失率: \(Int(vm.sciStragglerRate * 100)) %",
                            zh: "WAN 掉队节点 / 丢包率：\(Int(vm.sciStragglerRate * 100)) %"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciStragglerRate, in: 0...0.25, step: 0.01)
                            .tint(SolarisTheme.coral)
                        Text(L10n.tr(vm.language,
                            de: "Simuliert langsame Knoten oder CGNAT-Neuübertragung",
                            en: "Simulates straggler nodes or CGNAT retransmissions",
                            fr: "Simule les nœuds lents ou retransmissions CGNAT",
                            es: "Simula nodos lentos o retransmisiones CGNAT",
                            pt: "Simula nós lentos ou retransmissões CGNAT",
                            ru: "Моделирует медленные узлы или повторы CGNAT",
                            ja: "遅延ノードや CGNAT 再送をシミュレート",
                            zh: "模拟慢节点或 CGNAT 重传延迟"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language,
                            de: "WAN-Schwankung (Tail-Jitter): \(Int(vm.sciWanJitterFactor * 100)) %",
                            en: "WAN Tail-Jitter Variance: \(Int(vm.sciWanJitterFactor * 100)) %",
                            fr: "Gigue de queue WAN : \(Int(vm.sciWanJitterFactor * 100)) %",
                            es: "Variación de cola WAN (Jitter): \(Int(vm.sciWanJitterFactor * 100)) %",
                            pt: "Variância Tail-Jitter WAN: \(Int(vm.sciWanJitterFactor * 100)) %",
                            ru: "Хвостовой джиттер WAN: \(Int(vm.sciWanJitterFactor * 100)) %",
                            ja: "WAN テールジッター変動: \(Int(vm.sciWanJitterFactor * 100)) %",
                            zh: "WAN 尾延迟抖动：\(Int(vm.sciWanJitterFactor * 100)) %"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciWanJitterFactor, in: 0.02...0.50, step: 0.02)
                            .tint(SolarisTheme.amber)
                        Text(L10n.tr(vm.language,
                            de: "Steuert p95/p99-Ausreißer in Messreihen",
                            en: "Controls p95/p99 tail outliers in trial series",
                            fr: "Contrôle les pics p95/p99 dans les séries",
                            es: "Controla valores p95/p99 en las series",
                            pt: "Controla picos p95/p99 nas séries",
                            ru: "Управляет выбросами p95/p99 в замерах",
                            ja: "計測シリーズの p95/p99 スパイクを制御",
                            zh: "控制测量序列中的 p95/p99 尾延迟毛刺"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }

                // Stacked Latency Bar
                let comp = vm.activeStepComputeMs
                let tx = vm.activeStepTransferMs
                let rtt = vm.activeStepRttMs
                let stag = vm.activeStepStragglerMs
                let total = max(0.01, comp + tx + rtt + stag)

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: L10n.tr(vm.language,
                        de: "Schritt-Zeitaufteilung (Gesamt: %.2f ms · Nutzlast/Hop: %.3f MB)",
                        en: "Step Latency Breakdown (Total: %.2f ms · Payload/Hop: %.3f MB)",
                        fr: "Décomposition du pas (Total : %.2f ms · Charge/saut : %.3f Mo)",
                        es: "Desglose por paso (Total: %.2f ms · Carga/salto: %.3f MB)",
                        pt: "Divisão por passo (Total: %.2f ms · Carga/salto: %.3f MB)",
                        ru: "Время шага (Всего: %.2f мс · Нагрузка/хоп: %.3f МБ)",
                        ja: "ステップ内訳（合計: %.2f ms · ペイロード/ホップ: %.3f MB）",
                        zh: "单步耗时拆解（总计：%.2f ms · 每跳载荷：%.3f MB）"), total, vm.activationPayloadMBPerHop))
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textPrimary)

                    GeometryReader { geo in
                        let w = max(20, geo.size.width)
                        HStack(spacing: 2) {
                            Rectangle().fill(SolarisTheme.amber).frame(width: max(4, w * CGFloat(comp / total)))
                            Rectangle().fill(SolarisTheme.mint).frame(width: max(2, w * CGFloat(tx / total)))
                            Rectangle().fill(SolarisTheme.coral).frame(width: max(2, w * CGFloat(rtt / total)))
                            if stag > 0 {
                                Rectangle().fill(Color.purple).frame(width: max(2, w * CGFloat(stag / total)))
                            }
                        }
                        .cornerRadius(6)
                    }
                    .frame(height: 18)

                    HStack(spacing: 18) {
                        Label(String(format: L10n.tr(vm.language, de: "UMA-Rechnung: %.1f ms (%.0f%%)", en: "UMA Compute: %.1f ms (%.0f%%)", fr: "Calcul UMA : %.1f ms (%.0f%%)", es: "Cómputo UMA: %.1f ms (%.0f%%)", pt: "Computação UMA: %.1f ms (%.0f%%)", ru: "Вычисления UMA: %.1f мс (%.0f%%)", ja: "UMA 計算: %.1f ms (%.0f%%)", zh: "UMA 计算：%.1f ms (%.0f%%)"), comp, (comp / total) * 100), systemImage: "square.fill")
                            .foregroundColor(SolarisTheme.amberGlow)
                        Label(String(format: L10n.tr(vm.language, de: "Nutzlast-Transfer: %.2f ms (%.0f%%)", en: "Payload Transfer: %.2f ms (%.0f%%)", fr: "Transfert charge : %.2f ms (%.0f%%)", es: "Transferencia carga: %.2f ms (%.0f%%)", pt: "Transferência carga: %.2f ms (%.0f%%)", ru: "Передача данных: %.2f мс (%.0f%%)", ja: "ペイロード転送: %.2f ms (%.0f%%)", zh: "载荷传输：%.2f ms (%.0f%%)"), tx, (tx / total) * 100), systemImage: "square.fill")
                            .foregroundColor(SolarisTheme.mint)
                        Label(String(format: L10n.tr(vm.language, de: "Netz-RTT + Tunnel: %.1f ms (%.0f%%)", en: "Net RTT + Tunnel: %.1f ms (%.0f%%)", fr: "RTT Réseau + Tunnel : %.1f ms (%.0f%%)", es: "RTT Red + Túnel: %.1f ms (%.0f%%)", pt: "RTT Rede + Túnel: %.1f ms (%.0f%%)", ru: "RTT сети + туннель: %.1f мс (%.0f%%)", ja: "ネットワーク RTT + トンネル: %.1f ms (%.0f%%)", zh: "网络 RTT + 隧道：%.1f ms (%.0f%%)"), rtt, (rtt / total) * 100), systemImage: "square.fill")
                            .foregroundColor(SolarisTheme.coral)
                        if stag > 0 {
                            Label(String(format: L10n.tr(vm.language, de: "Nachzügler: %.1f ms", en: "Stragglers: %.1f ms", fr: "Retardataires : %.1f ms", es: "Rezagados: %.1f ms", pt: "Atrasados: %.1f ms", ru: "Отстающие: %.1f мс", ja: "ストラグラー: %.1f ms", zh: "掉队延迟：%.1f ms"), stag), systemImage: "square.fill")
                                .foregroundColor(.purple)
                        }
                    }
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .padding(12)
                .background(SolarisTheme.cardElevated)
                .cornerRadius(10)
            }

            // Scaling Curve (N = 1 .. 128)
            SolarisCard {
                Text(L10n.tr(vm.language,
                    de: "Skalierungskurve (N = 1 bis 128 Macs): TB5 RDMA vs. TB4 vs. Regional-WAN vs. Welt-WAN",
                    en: "Scaling Curve (N = 1 to 128 Macs): TB5 RDMA vs. TB4 vs. Regional WAN vs. Global WAN",
                    fr: "Courbe de mise à l'échelle (N = 1 à 128 Macs) : TB5 RDMA vs TB4 vs WAN régional vs WAN mondial",
                    es: "Curva de escalado (N = 1 a 128 Macs): TB5 RDMA vs TB4 vs WAN regional vs WAN global",
                    pt: "Curva de escala (N = 1 a 128 Macs): TB5 RDMA vs TB4 vs WAN regional vs WAN global",
                    ru: "Кривая масштабирования (N = 1..128 Mac): TB5 RDMA vs TB4 vs Регион. WAN vs Глоб. WAN",
                    ja: "スケーリング曲線 (N = 1〜128台): TB5 RDMA vs TB4 vs 地域 WAN vs グローバル WAN",
                    zh: "扩展曲线（N = 1 至 128 台 Mac）：TB5 RDMA vs TB4 vs 区域 WAN vs 全球 WAN"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                ScalingCurveCanvasView(
                    tb5Points: vm.scalingCurvePoints(for: "TB5 RDMA"),
                    tb4Points: vm.scalingCurvePoints(for: "TB4 Bridge"),
                    wanRegPoints: vm.scalingCurvePoints(for: "WAN Regional (25ms)"),
                    wanGlobalPoints: vm.scalingCurvePoints(for: "WAN Global (110ms)")
                )
                .frame(height: 220)

                HStack(spacing: 20) {
                    Label("TB5 RDMA (90 Gbps)", systemImage: "circle.fill").foregroundColor(SolarisTheme.emerald)
                    Label(L10n.tr(vm.language, de: "TB4 Brücke (32 Gbps)", en: "TB4 Bridge (32 Gbps)", fr: "Pont TB4 (32 Gbps)", es: "Puente TB4 (32 Gbps)", pt: "Ponte TB4 (32 Gbps)", ru: "TB4 Мост (32 Гбит/с)", ja: "TB4 ブリッジ (32 Gbps)", zh: "TB4 网桥 (32 Gbps)"), systemImage: "circle.fill").foregroundColor(SolarisTheme.amberGlow)
                    Label(L10n.tr(vm.language, de: "WAN Regional (25 ms)", en: "Regional WAN (25 ms)", fr: "WAN Régional (25 ms)", es: "WAN Regional (25 ms)", pt: "WAN Regional (25 ms)", ru: "Регион. WAN (25 мс)", ja: "地域 WAN (25 ms)", zh: "区域 WAN (25 ms)"), systemImage: "circle.fill").foregroundColor(SolarisTheme.mint)
                    Label(L10n.tr(vm.language, de: "WAN Weltweit (110 ms)", en: "Global WAN (110 ms)", fr: "WAN Mondial (110 ms)", es: "WAN Global (110 ms)", pt: "WAN Global (110 ms)", ru: "Глоб. WAN (110 мс)", ja: "グローバル WAN (110 ms)", zh: "全球 WAN (110 ms)"), systemImage: "circle.fill").foregroundColor(SolarisTheme.coral)
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }

            // Training vs Inference over WAN (DiLoCo vs DDP)
            SolarisCard(accent: SolarisTheme.amber) {
                HStack {
                    Text(L10n.tr(vm.language,
                        de: "Feinabstimmung & Training über das Internet: Naives DDP vs. DiLoCo vs. Inferenz-Pipeline",
                        en: "Fine-Tuning & Training over Internet: Naive DDP vs. DiLoCo vs. Inference Pipeline",
                        fr: "Fine-tuning & entraînement sur Internet : DDP naïf vs DiLoCo vs Pipeline d'inférence",
                        es: "Ajuste fino y entrenamiento por Internet: DDP ingenuo vs DiLoCo vs Pipeline de inferencia",
                        pt: "Ajuste fino e treino via Internet: DDP ingénuo vs DiLoCo vs Pipeline de inferência",
                        ru: "Дообучение по интернету: Наивный DDP vs DiLoCo vs Конвейер инференса",
                        ja: "インターネット経由の学習・微調整: 単純 DDP vs DiLoCo vs 推論パイプライン",
                        zh: "互联网微调与训练对比：朴素 DDP vs DiLoCo vs 推理流水线"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Picker("DiLoCo H", selection: $vm.sciDiLoCoLocalSteps) {
                        ForEach(dilocoOptions, id: \.self) { h in
                            Text(L10n.tr(vm.language, de: "H = \(h) Schritte", en: "H = \(h) steps", fr: "H = \(h) pas", es: "H = \(h) pasos", pt: "H = \(h) passos", ru: "H = \(h) шагов", ja: "H = \(h) ステップ", zh: "H = \(h) 步")).tag(h)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 340)
                }

                let comm = vm.trainingCommAnalysis
                HStack(spacing: 14) {
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "Naives DDP (All-Reduce / Schritt)", en: "Naive DDP (All-Reduce / Step)", fr: "DDP naïf (All-Reduce / pas)", es: "DDP ingenuo (All-Reduce / paso)", pt: "DDP ingénuo (All-Reduce / passo)", ru: "Наивный DDP (All-Reduce / шаг)", ja: "単純 DDP (All-Reduce / ステップ)", zh: "朴素 DDP（每步 All-Reduce）"),
                        value: String(format: "%.0f Gbit/s", comm.ddpMbps / 1000.0),
                        sub: L10n.tr(vm.language, de: "Überlastet Internet-WAN vollständig", en: "Completely saturates Internet WAN", fr: "Sature complètement le réseau WAN", es: "Satura por completo el enlace WAN", pt: "Satura completamente a rede WAN", ru: "Полностью перегружает канал WAN", ja: "インターネット WAN を完全に飽和", zh: "完全打满并阻塞广域网链路"),
                        accent: SolarisTheme.coral
                    )
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "DiLoCo (H=\(comm.reductionFactor) lokale Schritte)", en: "DiLoCo (H=\(comm.reductionFactor) local steps)", fr: "DiLoCo (H=\(comm.reductionFactor) pas locaux)", es: "DiLoCo (H=\(comm.reductionFactor) pasos locales)", pt: "DiLoCo (H=\(comm.reductionFactor) passos locais)", ru: "DiLoCo (H=\(comm.reductionFactor) лок. шагов)", ja: "DiLoCo (H=\(comm.reductionFactor) ローカルステップ)", zh: "DiLoCo（H=\(comm.reductionFactor) 本地步）"),
                        value: String(format: "%.1f Mbit/s", comm.diLoCoMbps),
                        sub: L10n.tr(vm.language, de: "\(comm.reductionFactor)× weniger Netzlast (WAN-tauglich)", en: "\(comm.reductionFactor)× less traffic (WAN-viable)", fr: "\(comm.reductionFactor)× moins de trafic (viable WAN)", es: "\(comm.reductionFactor)× menos tráfico (apto WAN)", pt: "\(comm.reductionFactor)× menos tráfego (viável WAN)", ru: "В \(comm.reductionFactor)× меньше трафика (для WAN)", ja: "通信量 1/\(comm.reductionFactor)（WAN 実行可能）", zh: "通信量减少 \(comm.reductionFactor)×（适合广域网）"),
                        accent: SolarisTheme.amberGlow
                    )
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "Pipeline-Inferenz (\(vm.sciActivationCompression.localizedTitle(vm.language)))", en: "Pipeline Inference (\(vm.sciActivationCompression.localizedTitle(vm.language)))", fr: "Inférence pipeline (\(vm.sciActivationCompression.localizedTitle(vm.language)))", es: "Inferencia pipeline (\(vm.sciActivationCompression.localizedTitle(vm.language)))", pt: "Inferência pipeline (\(vm.sciActivationCompression.localizedTitle(vm.language)))", ru: "Конвейерный инференс (\(vm.sciActivationCompression.localizedTitle(vm.language)))", ja: "パイプライン推論 (\(vm.sciActivationCompression.localizedTitle(vm.language)))", zh: "流水线推理 (\(vm.sciActivationCompression.localizedTitle(vm.language)))"),
                        value: String(format: "%.2f Mbit/s", comm.pipelineInfMbps),
                        sub: L10n.tr(vm.language, de: "Überträgt nur Aktivierungsvektoren", en: "Transfers only activation vectors", fr: "Transfère uniquement les activations", es: "Transfiere solo vectores de activación", pt: "Transfere apenas vetores de ativação", ru: "Передаёт только векторы активаций", ja: "アクティベーションベクトルのみ転送", zh: "仅传输隐藏层激活向量"),
                        accent: SolarisTheme.mint
                    )
                }
            }
        }
    }

    // MARK: - Tab 3: Memory, KV-Cache & Quantization

    private var memoryKvTabContent: some View {
        let mem = vm.memoryBreakdownGB
        let pool = max(1.0, vm.activeTotalUsableVramGB)
        let usedTotal = mem.weights + mem.kvTotalGB + mem.activationsGB
        let fits = usedTotal <= pool

        return VStack(alignment: .leading, spacing: 20) {
            SolarisCard(accent: fits ? SolarisTheme.emerald : SolarisTheme.coral) {
                HStack {
                    Text(L10n.tr(vm.language,
                        de: "Transformer-Speichergleichung & iogpu.wired_limit_mb-Sicherheitsanalyse",
                        en: "Transformer Memory Equation & iogpu.wired_limit_mb Safety Analysis",
                        fr: "Équation mémoire Transformer & analyse iogpu.wired_limit_mb",
                        es: "Ecuación de memoria Transformer y análisis iogpu.wired_limit_mb",
                        pt: "Equação de memória Transformer e análise iogpu.wired_limit_mb",
                        ru: "Уравнение памяти Transformer и анализ iogpu.wired_limit_mb",
                        ja: "Transformer メモリ方程式 & iogpu.wired_limit_mb 安全分析",
                        zh: "Transformer 显存方程与 iogpu.wired_limit_mb 安全分析"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Text(fits
                        ? L10n.tr(vm.language, de: "✓ Passt in nutzbaren Pool", en: "✓ Fits usable pool", fr: "✓ Rentre dans le pool", es: "✓ Cabe en el pool", pt: "✓ Cabe no pool", ru: "✓ Помещается в пул", ja: "✓ プール内に収容可能", zh: "✓ 适配可用显存池")
                        : L10n.tr(vm.language, de: "⚠ Überschreitet Pool-Grenze", en: "⚠ Exceeds pool limit", fr: "⚠ Dépasse le pool", es: "⚠ Excede el límite del pool", pt: "⚠ Excede o limite do pool", ru: "⚠ Превышен лимит пула", ja: "⚠ プール上限を超過", zh: "⚠ 超出显存池上限"))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(fits ? SolarisTheme.emerald : SolarisTheme.coral)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language, de: "Antwort-Länge (S_gen)", en: "Generation Length (S_gen)", fr: "Longueur générée (S_gen)", es: "Longitud generada (S_gen)", pt: "Comprimento gerado (S_gen)", ru: "Длина генерации (S_gen)", ja: "生成トークン長 (S_gen)", zh: "生成长度 (S_gen)"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Gen", selection: $vm.sciGenTokens) {
                            ForEach(genOptions, id: \.self) { g in
                                Text("\(g) tok").tag(g)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language, de: "KV-Speicher-Genauigkeit", en: "KV Cache Precision", fr: "Précision du cache KV", es: "Precisión caché KV", pt: "Precisão cache KV", ru: "Точность KV-кэша", ja: "KV キャッシュ精度", zh: "KV 缓存精度"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("KV", selection: $vm.kvPrecision) {
                            ForEach(KVCachePrecision.allCases) { kv in
                                Text(kv.localizedTitle(vm.language)).tag(kv)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                }

                HStack(spacing: 14) {
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "Modell-Gewichte (\(vm.sciWeightBits)-Bit)", en: "Model Weights (\(vm.sciWeightBits)-Bit)", fr: "Poids du modèle (\(vm.sciWeightBits) bits)", es: "Pesos del modelo (\(vm.sciWeightBits) bits)", pt: "Pesos do modelo (\(vm.sciWeightBits) bits)", ru: "Веса модели (\(vm.sciWeightBits) бит)", ja: "モデル重み (\(vm.sciWeightBits)-bit)", zh: "模型权重 (\(vm.sciWeightBits)-bit)"),
                        value: String(format: "%.1f GB", mem.weights),
                        sub: vm.selectedModel.displayName,
                        accent: SolarisTheme.amberGlow
                    )
                    ScienceMetricTile(
                        label: "KV-Cache (B=\(vm.sciBatchSize), S=\(vm.sciPromptTokens + vm.sciGenTokens))",
                        value: String(format: "%.2f GB", mem.kvTotalGB),
                        sub: String(format: "%.3f MB / Token", mem.kvPerTokenMB),
                        accent: SolarisTheme.mint
                    )
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "Aktivierungen & Arbeitsbereich", en: "Activations & Scratchpad", fr: "Activations & tampon", es: "Activaciones y búfer", pt: "Ativações e espaço livre", ru: "Активации и буфер", ja: "アクティベーション・作業領域", zh: "激活张量与工作区"),
                        value: String(format: "%.2f GB", mem.activationsGB),
                        sub: "Chunked Prefill: \(vm.prefillStepSize) tok",
                        accent: SolarisTheme.emerald
                    )
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "Max. Kontext (S_max bei B=\(vm.sciBatchSize))", en: "Max Context (S_max at B=\(vm.sciBatchSize))", fr: "Contexte max (S_max à B=\(vm.sciBatchSize))", es: "Contexto máx (S_max en B=\(vm.sciBatchSize))", pt: "Contexto máx (S_max em B=\(vm.sciBatchSize))", ru: "Макс. контекст (S_max при B=\(vm.sciBatchSize))", ja: "最大コンテキスト (S_max, B=\(vm.sciBatchSize))", zh: "最大上下文 (S_max @ B=\(vm.sciBatchSize))"),
                        value: mem.maxContextTokens >= 1000 ? "\(mem.maxContextTokens / 1000)k tok" : "\(mem.maxContextTokens) tok",
                        sub: String(format: L10n.tr(vm.language, de: "Pool: %.0f GB nutzbar", en: "Pool: %.0f GB usable", fr: "Pool : %.0f Go utilisables", es: "Pool: %.0f GB utilizables", pt: "Pool: %.0f GB utilizáveis", ru: "Пул: %.0f ГБ доступно", ja: "プール: %.0f GB 利用可", zh: "显存池：%.0f GB 可用"), pool),
                        accent: fits ? SolarisTheme.mint : SolarisTheme.coral
                    )
                }

                // Memory Pool Stacked Bar
                GeometryReader { geo in
                    let w = max(20, geo.size.width)
                    let scale = max(pool, usedTotal)
                    HStack(spacing: 2) {
                        Rectangle().fill(SolarisTheme.amber).frame(width: max(4, w * CGFloat(mem.weights / scale)))
                        Rectangle().fill(SolarisTheme.mint).frame(width: max(2, w * CGFloat(mem.kvTotalGB / scale)))
                        Rectangle().fill(SolarisTheme.emerald).frame(width: max(2, w * CGFloat(mem.activationsGB / scale)))
                        Spacer(minLength: 0)
                    }
                    .background(SolarisTheme.cardElevated)
                    .cornerRadius(6)
                }
                .frame(height: 18)
            }

            SolarisCard {
                Text(L10n.tr(vm.language,
                    de: "Genauigkeits- vs. Speicher-Abwägung (Forschungs-Richtwerte)",
                    en: "Precision vs. Memory Trade-off (Research Reference Benchmarks)",
                    fr: "Compromis précision vs mémoire (références de recherche)",
                    es: "Balance precisión vs memoria (referencias científicas)",
                    pt: "Compromisso precisão vs memória (referências científicas)",
                    ru: "Баланс точности и памяти (научные ориентиры)",
                    ja: "精度 vs メモリ消費のトレードオフ（研究参照基準）",
                    zh: "精度与显存权衡（科研参考基准）"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text(L10n.tr(vm.language, de: "Verfahren", en: "Method", fr: "Méthode", es: "Método", pt: "Método", ru: "Метод", ja: "手法", zh: "方法")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Speicherfaktor", en: "Memory Factor", fr: "Facteur mémoire", es: "Factor memoria", pt: "Fator memória", ru: "Коэф. памяти", ja: "メモリ倍率", zh: "显存系数")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Typische PPL-Abweichung", en: "Typical PPL Delta", fr: "Écart PPL typique", es: "Desviación PPL típica", pt: "Desvio PPL típico", ru: "Отклонение PPL", ja: "標準 PPL 劣化", zh: "典型困惑度变化")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Eignung im Verbund", en: "Cluster Suitability", fr: "Usage en cluster", es: "Idoneidad en clúster", pt: "Adequação no cluster", ru: "Применимость в кластере", ja: "クラスタ適合性", zh: "集群适用性")).foregroundColor(SolarisTheme.textSecondary)
                    }
                    .font(SolarisTheme.bodyBold)
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        Text(L10n.tr(vm.language, de: "FP16 / BF16 Referenz", en: "FP16 / BF16 Baseline", fr: "Référence FP16 / BF16", es: "Referencia FP16 / BF16", pt: "Referência FP16 / BF16", ru: "Эталон FP16 / BF16", ja: "FP16 / BF16 基準", zh: "FP16 / BF16 基准"))
                        Text("1.00× (2.0 B/Param)")
                        Text(L10n.tr(vm.language, de: "0,00 (Basislinie)", en: "0.00 (Baseline)", fr: "0,00 (Référence)", es: "0,00 (Línea base)", pt: "0,00 (Linha de base)", ru: "0.00 (Базовая линия)", ja: "0.00 (ベースライン)", zh: "0.00（基线）"))
                        Text(L10n.tr(vm.language, de: "Nur sehr große RAM-Verbünde", en: "Very large RAM clusters only", fr: "Clusters à très grande RAM uniquement", es: "Solo clústeres de RAM muy grande", pt: "Apenas clusters com RAM muito elevada", ru: "Только сверхкрупные кластеры ОЗУ", ja: "超大容量 RAM クラスタ専用", zh: "仅限超大内存集群"))
                    }
                    GridRow {
                        Text("8-Bit MLX / INT8-KV")
                        Text("0.53×")
                        Text("+0.01–0.03 PPL")
                        Text(L10n.tr(vm.language, de: "Höchste Genauigkeit bei moderatem RAM", en: "Highest accuracy with moderate RAM", fr: "Précision maximale à RAM modérée", es: "Máxima precisión con RAM moderada", pt: "Máxima precisão com RAM moderada", ru: "Высшая точность при умеренной ОЗУ", ja: "適度な RAM で最高精度", zh: "中等显存下的最高精度"))
                    }
                    GridRow {
                        Text("4-Bit MLX Affine (g=64)")
                        Text("0.28× (0.56 B/Param)")
                        Text("+0.08–0.18 PPL")
                        Text(L10n.tr(vm.language, de: "Standard für UMA-Bandbreiten-Optimierung", en: "Standard for UMA bandwidth optimization", fr: "Standard pour optimiser la bande passante UMA", es: "Estándar para optimizar ancho de banda UMA", pt: "Padrão para otimizar largura de banda UMA", ru: "Стандарт оптимизации пропускной способности UMA", ja: "UMA 帯域最適化の標準設定", zh: "UMA 统一内存带宽优化标准"))
                    }
                    GridRow {
                        Text(L10n.tr(vm.language, de: "4-Bit KV-Quantisierung (KIVI/oMLX)", en: "4-Bit KV Quantization (KIVI/oMLX)", fr: "Quantification KV 4 bits (KIVI/oMLX)", es: "Cuantización KV 4 bits (KIVI/oMLX)", pt: "Quantização KV 4 bits (KIVI/oMLX)", ru: "4-бит KV-квантование (KIVI/oMLX)", ja: "4ビット KV 量子化 (KIVI/oMLX)", zh: "4-bit KV 量化 (KIVI/oMLX)"))
                        Text(L10n.tr(vm.language, de: "0,25× KV-Bedarf", en: "0.25× KV size", fr: "0,25× taille KV", es: "0,25× tamaño KV", pt: "0,25× tamanho KV", ru: "0.25× объём KV", ja: "KV 使用量 0.25×", zh: "仅占 0.25× KV 显存"))
                        Text(L10n.tr(vm.language, de: "<0,05 MMLU-Delta", en: "<0.05 MMLU delta", fr: "<0,05 écart MMLU", es: "<0,05 variación MMLU", pt: "<0,05 desvio MMLU", ru: "<0.05 дельта MMLU", ja: "<0.05 MMLU 差", zh: "<0.05 MMLU 波动"))
                        Text(L10n.tr(vm.language, de: "Ermöglicht 64k–128k Agenten-Kontexte", en: "Enables 64k–128k agent contexts", fr: "Permet des contextes agents 64k–128k", es: "Habilita contextos de agentes 64k–128k", pt: "Ativa contextos de agentes 64k–128k", ru: "Открывает контексты агентов 64k–128k", ja: "64k–128k エージェントコンテキストを実現", zh: "支持 64k–128k 长上下文智能体"))
                    }
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(SolarisTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Tab 4: Energetics, Carbon & TCO

    private var energeticsTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            SolarisCard(accent: SolarisTheme.emerald) {
                Text(L10n.tr(vm.language,
                    de: "Energiebilanz (TokenPowerBench), CO₂-Fußabdruck & Stromkosten",
                    en: "Energy Balance (TokenPowerBench), CO₂ Footprint & Electricity Costs",
                    fr: "Bilan énergétique (TokenPowerBench), empreinte CO₂ & coût électrique",
                    es: "Balance energético (TokenPowerBench), huella CO₂ y coste eléctrico",
                    pt: "Balanço energético (TokenPowerBench), pegada CO₂ e custo elétrico",
                    ru: "Энергобаланс (TokenPowerBench), след CO₂ и стоимость электричества",
                    ja: "エネルギー収支 (TokenPowerBench)・CO₂ 排出量・電力コスト",
                    zh: "能耗分析 (TokenPowerBench)、碳足迹与电费成本"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr(vm.language,
                            de: "Strommix-Region (CO₂-Intensität)",
                            en: "Grid Carbon Region (CO₂ Intensity)",
                            fr: "Région électrique (Intensité CO₂)",
                            es: "Región eléctrica (Intensidad CO₂)",
                            pt: "Região elétrica (Intensidade CO₂)",
                            ru: "Регион электросети (CO₂)",
                            ja: "電源構成リージョン (CO₂ 強度)",
                            zh: "电网区域（碳排放强度）"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Region", selection: $vm.sciCarbonRegion) {
                            ForEach(CarbonRegionProfile.allCases) { region in
                                Text(region.localizedTitle(vm.language)).tag(region)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: L10n.tr(vm.language,
                            de: "Strompreis: %.2f €/kWh",
                            en: "Electricity Price: %.2f €/kWh",
                            fr: "Tarif électricité : %.2f €/kWh",
                            es: "Precio electricidad: %.2f €/kWh",
                            pt: "Preço eletricidade: %.2f €/kWh",
                            ru: "Тариф электроэн.: %.2f €/кВт·ч",
                            ja: "電力単価: %.2f €/kWh",
                            zh: "电价：%.2f €/kWh"), vm.sciElectricityEurPerKwh))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciElectricityEurPerKwh, in: 0.08...0.60, step: 0.02)
                            .tint(SolarisTheme.amber)
                    }
                }

                HStack(spacing: 14) {
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "Energie pro Token", en: "Energy per Token", fr: "Énergie par jeton", es: "Energía por token", pt: "Energia por token", ru: "Энергия на токен", ja: "トークンあたり電力量", zh: "单 Token 能耗"),
                        value: String(format: "%.2f J/tok", vm.activeJoulesPerToken),
                        sub: String(format: "%.1f Wh / 1M Token", (vm.activeJoulesPerToken * 1_000_000.0) / 3600.0),
                        accent: SolarisTheme.emerald
                    )
                    ScienceMetricTile(
                        label: "Energy-Delay Product (EDP)",
                        value: String(format: "%.3f J·s", vm.activeEDPJoulesSec),
                        sub: L10n.tr(vm.language,
                            de: "Kleiner = besseres Effizienz-Latenz-Verhältnis",
                            en: "Lower = better efficiency-to-latency ratio",
                            fr: "Plus petit = meilleur ratio efficacité/latence",
                            es: "Menor = mejor relación eficiencia/latencia",
                            pt: "Menor = melhor relação eficiência/latência",
                            ru: "Меньше = лучшее соотношение к задержке",
                            ja: "低いほど電力効率と遅延のバランスが優秀",
                            zh: "越低代表能效与延迟比越优"),
                        accent: SolarisTheme.mint
                    )
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "CO₂ pro 1 Mio. Token", en: "CO₂ per 1M Tokens", fr: "CO₂ par 1M jetons", es: "CO₂ por 1M tokens", pt: "CO₂ por 1M tokens", ru: "CO₂ за 1M токенов", ja: "100万トークンあたり CO₂", zh: "每百万 Token 碳排放"),
                        value: String(format: "%.1f gCO₂", vm.activeCO2GramsPerMillionTokens),
                        sub: "\(Int(vm.sciCarbonRegion.gco2PerKwh)) gCO₂eq/kWh",
                        accent: SolarisTheme.amberGlow
                    )
                    ScienceMetricTile(
                        label: L10n.tr(vm.language, de: "Stromkosten / 1M Token", en: "Power Cost / 1M Tokens", fr: "Coût élec. / 1M jetons", es: "Coste eléctrico / 1M tokens", pt: "Custo energia / 1M tokens", ru: "Затраты / 1M токенов", ja: "電力コスト / 1M トークン", zh: "电费 / 百万 Token"),
                        value: String(format: "%.3f €", vm.activeCostEurPerMillionTokens),
                        sub: String(format: L10n.tr(vm.language,
                            de: "%.0f W Gesamtleistung",
                            en: "%.0f W total power",
                            fr: "%.0f W puissance totale",
                            es: "%.0f W potencia total",
                            pt: "%.0f W potência total",
                            ru: "%.0f Вт общая мощность",
                            ja: "合計消費電力 %.0f W",
                            zh: "总功耗 %.0f W"), vm.activeWatts),
                        accent: SolarisTheme.amber
                    )
                }
            }

            SolarisCard {
                Text(L10n.tr(vm.language,
                    de: "Vergleich: Apple-Silicon-Verbund vs. Rechenzentrums-Cloud (70B-Klasse)",
                    en: "Comparison: Apple Silicon Cluster vs. Datacenter Cloud (70B Class)",
                    fr: "Comparaison : Cluster Apple Silicon vs Cloud Datacenter (classe 70B)",
                    es: "Comparación: Clúster Apple Silicon vs Nube Datacenter (clase 70B)",
                    pt: "Comparação: Cluster Apple Silicon vs Cloud Datacenter (classe 70B)",
                    ru: "Сравнение: Кластер Apple Silicon vs Облачный ЦОД (класс 70B)",
                    ja: "比較: Apple Silicon クラスタ vs データセンタークラウド (70B級)",
                    zh: "对比：Apple Silicon 集群 vs 数据中心云端（70B 级）"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 10) {
                    GridRow {
                        Text(L10n.tr(vm.language, de: "Betriebsart", en: "Deployment Mode", fr: "Mode d'exploitation", es: "Modo operativo", pt: "Modo de operação", ru: "Режим работы", ja: "運用形態", zh: "运行模式")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Typische Leistung", en: "Typical Power", fr: "Puissance typique", es: "Potencia típica", pt: "Potência típica", ru: "Типовая мощность", ja: "標準消費電力", zh: "典型功耗")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Energie / Token", en: "Energy / Token", fr: "Énergie / jeton", es: "Energía / token", pt: "Energia / token", ru: "Энергия / токен", ja: "電力 / トークン", zh: "每 Token 能耗")).foregroundColor(SolarisTheme.textSecondary)
                        Text(L10n.tr(vm.language, de: "Betriebskosten / 1M Token", en: "Operating Cost / 1M Tokens", fr: "Coût d'usage / 1M jetons", es: "Coste operativo / 1M tokens", pt: "Custo operativo / 1M tokens", ru: "Стоимость / 1M токенов", ja: "運用コスト / 1M トークン", zh: "运营成本 / 百万 Token")).foregroundColor(SolarisTheme.textSecondary)
                    }
                    .font(SolarisTheme.bodyBold)
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        Text(L10n.tr(vm.language,
                            de: "Aktiver SS-CCC-Verbund (\(vm.activeScienceNodes.count) Macs)",
                            en: "Active SS-CCC Cluster (\(vm.activeScienceNodes.count) Macs)",
                            fr: "Cluster SS-CCC actif (\(vm.activeScienceNodes.count) Macs)",
                            es: "Clúster SS-CCC activo (\(vm.activeScienceNodes.count) Macs)",
                            pt: "Cluster SS-CCC ativo (\(vm.activeScienceNodes.count) Macs)",
                            ru: "Активный кластер SS-CCC (\(vm.activeScienceNodes.count) Mac)",
                            ja: "稼働中 SS-CCC クラスタ (\(vm.activeScienceNodes.count) 台)",
                            zh: "当前 SS-CCC 集群（\(vm.activeScienceNodes.count) 台 Mac）"))
                            .foregroundColor(SolarisTheme.amberGlow)
                        Text("\(Int(vm.activeWatts)) W")
                        Text(String(format: "%.2f J/tok", vm.activeJoulesPerToken))
                        Text(String(format: L10n.tr(vm.language, de: "%.3f € (Strom)", en: "%.3f € (Power)", fr: "%.3f € (Élec.)", es: "%.3f € (Elec.)", pt: "%.3f € (Energ.)", ru: "%.3f € (Эл-во)", ja: "%.3f € (電力)", zh: "%.3f €（电费）"), vm.activeCostEurPerMillionTokens))
                    }
                    GridRow {
                        Text(L10n.tr(vm.language, de: "Typische Cloud-API (70B-Klasse)", en: "Typical Cloud API (70B Class)", fr: "API Cloud typique (classe 70B)", es: "API Cloud típica (clase 70B)", pt: "API Cloud típica (classe 70B)", ru: "Типовой Cloud API (класс 70B)", ja: "一般的なクラウド API (70B級)", zh: "典型云端 API（70B 级）"))
                        Text(L10n.tr(vm.language, de: "~700 W (H100-Anteil)", en: "~700 W (H100 share)", fr: "~700 W (part H100)", es: "~700 W (cuota H100)", pt: "~700 W (fração H100)", ru: "~700 Вт (доля H100)", ja: "~700 W (H100換算)", zh: "~700 W（H100 均摊）"))
                        Text("~4.5–9.0 J/tok")
                        Text(L10n.tr(vm.language, de: "~0,60–1,20 € (API-Gebühr)", en: "~€0.60–1.20 (API fee)", fr: "~0,60–1,20 € (Frais API)", es: "~0,60–1,20 € (Tarifa API)", pt: "~0,60–1,20 € (Taxa API)", ru: "~0.60–1.20 € (Тариф API)", ja: "~0.60–1.20 € (API料金)", zh: "~0.60–1.20 €（API 费用）"))
                    }
                }
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(SolarisTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Tab 5: Reproducible Trials, Statistics & Export

    private var trialsExportTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            SolarisCard(accent: SolarisTheme.emerald) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr(vm.language,
                            de: "Reproduzierbare Messreihe (Aufwärmlauf + N Läufe bei T=0,0)",
                            en: "Reproducible Benchmark Series (Warm-up + N Trials at T=0.0)",
                            fr: "Série reproductible (Échauffement + N essais à T=0,0)",
                            es: "Serie reproducible (Calentamiento + N pruebas en T=0,0)",
                            pt: "Série reproduzível (Aquecimento + N ensaios em T=0,0)",
                            ru: "Воспроизводимая серия (прогрев + N запусков при T=0,0)",
                            ja: "再現可能な測定シリーズ (ウォームアップ + T=0.0 で N 回実行)",
                            zh: "可复现基准测试序列（预热 + T=0.0 下 N 次运行）"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(L10n.tr(vm.language,
                            de: "Fingerabdruck: \(vm.hardwareFingerprint)",
                            en: "Fingerprint: \(vm.hardwareFingerprint)",
                            fr: "Empreinte : \(vm.hardwareFingerprint)",
                            es: "Huella: \(vm.hardwareFingerprint)",
                            pt: "Impressão digital: \(vm.hardwareFingerprint)",
                            ru: "Отпечаток: \(vm.hardwareFingerprint)",
                            ja: "フィンガープリント: \(vm.hardwareFingerprint)",
                            zh: "硬件指纹：\(vm.hardwareFingerprint)"))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                    Spacer()
                    Picker("Trials", selection: $vm.sciTrialCount) {
                        ForEach(trialOptions, id: \.self) { count in
                            Text("N=\(count)").tag(count)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 190)

                    Button {
                        vm.runScientificBenchmark()
                    } label: {
                        Label(
                            vm.isRunningBenchmark ? vm.t("sci_bench_running") : vm.t("sci_bench_run"),
                            systemImage: vm.isRunningBenchmark ? "hourglass" : "play.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SolarisTheme.amber)
                    .foregroundColor(.black)
                    .disabled(vm.isRunningBenchmark)
                }

                // SLO Threshold Controls
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr(vm.language,
                            de: "SLO-Grenze TTFT: ≤ \(Int(vm.sciSloTtftMaxMs)) ms",
                            en: "SLO Threshold TTFT: ≤ \(Int(vm.sciSloTtftMaxMs)) ms",
                            fr: "Seuil SLO TTFT : ≤ \(Int(vm.sciSloTtftMaxMs)) ms",
                            es: "Límite SLO TTFT: ≤ \(Int(vm.sciSloTtftMaxMs)) ms",
                            pt: "Limite SLO TTFT: ≤ \(Int(vm.sciSloTtftMaxMs)) ms",
                            ru: "Порог SLO TTFT: ≤ \(Int(vm.sciSloTtftMaxMs)) мс",
                            ja: "SLO 閾値 TTFT: ≤ \(Int(vm.sciSloTtftMaxMs)) ms",
                            zh: "TTFT SLO 阈值：≤ \(Int(vm.sciSloTtftMaxMs)) ms"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciSloTtftMaxMs, in: 250...8000, step: 250)
                            .tint(SolarisTheme.amber)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr(vm.language,
                            de: "SLO-Grenze TPOT: ≤ \(Int(vm.sciSloTpotMaxMs)) ms/tok",
                            en: "SLO Threshold TPOT: ≤ \(Int(vm.sciSloTpotMaxMs)) ms/tok",
                            fr: "Seuil SLO TPOT : ≤ \(Int(vm.sciSloTpotMaxMs)) ms/tok",
                            es: "Límite SLO TPOT: ≤ \(Int(vm.sciSloTpotMaxMs)) ms/tok",
                            pt: "Limite SLO TPOT: ≤ \(Int(vm.sciSloTpotMaxMs)) ms/tok",
                            ru: "Порог SLO TPOT: ≤ \(Int(vm.sciSloTpotMaxMs)) мс/ток",
                            ja: "SLO 閾値 TPOT: ≤ \(Int(vm.sciSloTpotMaxMs)) ms/tok",
                            zh: "TPOT SLO 阈值：≤ \(Int(vm.sciSloTpotMaxMs)) ms/tok"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciSloTpotMaxMs, in: 15...400, step: 5)
                            .tint(SolarisTheme.mint)
                    }
                }

                if !vm.sciStatusMessage.isEmpty {
                    Text(vm.sciStatusMessage)
                        .font(Font.caption)
                        .foregroundColor(vm.sciSummary == nil && !vm.simulateMacStudio ? SolarisTheme.amberGlow : SolarisTheme.emerald)
                }

                if let summary = vm.sciSummary {
                    HStack(spacing: 8) {
                        Text(L10n.tr(vm.language,
                            de: "Datenquelle: \(summary.backendLabel)",
                            en: "Data Source: \(summary.backendLabel)",
                            fr: "Source des données : \(summary.backendLabel)",
                            es: "Fuente de datos: \(summary.backendLabel)",
                            pt: "Fonte de dados: \(summary.backendLabel)",
                            ru: "Источник данных: \(summary.backendLabel)",
                            ja: "データソース: \(summary.backendLabel)",
                            zh: "数据源：\(summary.backendLabel)"))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(summary.isLiveEndpoint ? SolarisTheme.emerald : SolarisTheme.amberGlow)
                        Spacer()
                        Text(summary.isLiveEndpoint
                            ? L10n.tr(vm.language,
                                de: "LIVE SSE + PING",
                                en: "LIVE SSE + PING",
                                fr: "SSE DIRECT + PING",
                                es: "SSE EN VIVO + PING",
                                pt: "SSE AO VIVO + PING",
                                ru: "LIVE SSE + PING",
                                ja: "ライブ SSE + PING",
                                zh: "实时 SSE + PING")
                            : L10n.tr(vm.language,
                                de: "SIMULATION",
                                en: "SIMULATION",
                                fr: "SIMULATION",
                                es: "SIMULACIÓN",
                                pt: "SIMULAÇÃO",
                                ru: "СИМУЛЯЦИЯ",
                                ja: "シミュレーション",
                                zh: "模拟数据"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(summary.isLiveEndpoint ? SolarisTheme.emerald : SolarisTheme.amber)
                            .cornerRadius(5)
                    }
                    HStack(spacing: 14) {
                        ScienceMetricTile(
                            label: "TTFT (p50 / p95 / p99)",
                            value: String(format: "%.1f ± %.1f ms", summary.ttftP50Ms, summary.ci95TtftMarginMs),
                            sub: String(format: "p95: %.1f · p99: %.1f · σ=%.2f", summary.ttftP95Ms, summary.ttftP99Ms, summary.ttftStdDevMs),
                            accent: SolarisTheme.amberGlow
                        )
                        ScienceMetricTile(
                            label: "TPOT (p50 ± CI₉₅)",
                            value: String(format: "%.2f ± %.2f ms", summary.tpotP50Ms, summary.ci95TpotMarginMs),
                            sub: String(format: "p95: %.2f · p99: %.2f · CV=%.1f%%", summary.tpotP95Ms, summary.tpotP99Ms, summary.cvPercent),
                            accent: SolarisTheme.mint
                        )
                        ScienceMetricTile(
                            label: L10n.tr(vm.language, de: "Goodput & Durchsatz", en: "Goodput & Throughput", fr: "Goodput & Débit", es: "Goodput y Rendimiento", pt: "Goodput e Débito", ru: "Goodput и Скорость", ja: "Goodput & スループット", zh: "有效吞吐量与 Goodput"),
                            value: String(format: "%.1f tok/s", summary.meanTokensPerSec),
                            sub: String(format: L10n.tr(vm.language, de: "SLO-Treffer: %.0f%% · %.2f J/tok", en: "SLO Compliance: %.0f%% · %.2f J/tok", fr: "Conformité SLO : %.0f%% · %.2f J/tok", es: "Cumplimiento SLO: %.0f%% · %.2f J/tok", pt: "Conformidade SLO: %.0f%% · %.2f J/tok", ru: "Соотв. SLO: %.0f%% · %.2f Дж/ток", ja: "SLO 達成率: %.0f%% · %.2f J/tok", zh: "SLO 达标率：%.0f%% · %.2f J/tok"), summary.goodputPercent, summary.joulesPerToken),
                            accent: SolarisTheme.emerald
                        )
                    }

                    // Per-Trial Telemetry Table
                    if !vm.sciTrials.isEmpty {
                        ScrollView {
                            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                                GridRow {
                                    Text("#").foregroundColor(SolarisTheme.textSecondary)
                                    Text(L10n.tr(vm.language, de: "Bereich", en: "Scope", fr: "Portée", es: "Ámbito", pt: "Âmbito", ru: "Область", ja: "範囲", zh: "范围")).foregroundColor(SolarisTheme.textSecondary)
                                    Text("TTFT").foregroundColor(SolarisTheme.textSecondary)
                                    Text("TPOT").foregroundColor(SolarisTheme.textSecondary)
                                    Text("Tok/s").foregroundColor(SolarisTheme.textSecondary)
                                    Text(L10n.tr(vm.language, de: "Netz-RTT", en: "Net RTT", fr: "RTT Réseau", es: "RTT Red", pt: "RTT Rede", ru: "RTT Сети", ja: "Net RTT", zh: "网络 RTT")).foregroundColor(SolarisTheme.textSecondary)
                                    Text("J/tok").foregroundColor(SolarisTheme.textSecondary)
                                    Text("SLO").foregroundColor(SolarisTheme.textSecondary)
                                }
                                .font(SolarisTheme.bodyBold)
                                Divider().gridCellUnsizedAxes(.horizontal)
                                ForEach(vm.sciTrials) { tr in
                                    GridRow {
                                        Text("\(tr.trialIndex)")
                                        Text(tr.scopeLabel)
                                        Text(String(format: "%.1f ms", tr.ttftMs))
                                        Text(String(format: "%.2f ms", tr.tpotMs))
                                        Text(String(format: "%.1f", tr.tokensPerSec))
                                        Text(String(format: "%.1f ms", tr.netRttMs))
                                        Text(String(format: "%.2f", tr.joulesPerToken))
                                        Text(tr.sloPass ? "✓" : "✗")
                                            .foregroundColor(tr.sloPass ? SolarisTheme.emerald : SolarisTheme.coral)
                                    }
                                }
                            }
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(SolarisTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 190)
                        .padding(10)
                        .background(SolarisTheme.cardElevated)
                        .cornerRadius(10)
                    }
                }

                // Publication Export Buttons (available anytime)
                HStack(spacing: 12) {
                    if !vm.sciTrials.isEmpty {
                        Button(L10n.tr(vm.language, de: "CSV kopieren", en: "Copy CSV", fr: "Copier CSV", es: "Copiar CSV", pt: "Copiar CSV", ru: "Копировать CSV", ja: "CSV をコピー", zh: "复制 CSV")) {
                            copyToClipboard(vm.exportScientificCSV(), label: L10n.tr(vm.language, de: "CSV-Messreihe kopiert.", en: "Benchmark CSV copied.", fr: "CSV des mesures copié.", es: "CSV de mediciones copiado.", pt: "CSV de medições copiado.", ru: "CSV-ряды скопированы.", ja: "CSV データをコピーしました。", zh: "已复制基准测试 CSV 数据。"))
                        }
                        .buttonStyle(.bordered)
                    }
                    Button(L10n.tr(vm.language, de: "JSON-Manifest kopieren", en: "Copy JSON Manifest", fr: "Copier manifeste JSON", es: "Copiar manifiesto JSON", pt: "Copiar manifesto JSON", ru: "Копировать JSON-манифест", ja: "JSON マニフェストをコピー", zh: "复制 JSON 清单")) {
                        copyToClipboard(vm.exportScientificJSON(), label: L10n.tr(vm.language, de: "JSON-Reproduzierbarkeits-Manifest kopiert.", en: "JSON reproducibility manifest copied.", fr: "Manifeste JSON de reproductibilité copié.", es: "Manifiesto JSON de reproducibilidad copiado.", pt: "Manifesto JSON de reprodutibilidade copiado.", ru: "JSON-манифест воспроизводимости скопирован.", ja: "JSON 再現性マニフェストをコピーしました。", zh: "已复制 JSON 可复现性清单。"))
                    }
                    .buttonStyle(.bordered)
                    Button(L10n.tr(vm.language, de: "LaTeX-Tabelle kopieren", en: "Copy LaTeX Table", fr: "Copier tableau LaTeX", es: "Copiar tabla LaTeX", pt: "Copiar tabela LaTeX", ru: "Копировать таблицу LaTeX", ja: "LaTeX テーブルをコピー", zh: "复制 LaTeX 表格")) {
                        copyToClipboard(vm.exportScientificLaTeX(), label: L10n.tr(vm.language, de: "LaTeX-Tabelle (booktabs) kopiert.", en: "LaTeX table (booktabs) copied.", fr: "Tableau LaTeX (booktabs) copié.", es: "Tabla LaTeX (booktabs) copiada.", pt: "Tabela LaTeX (booktabs) copiada.", ru: "Таблица LaTeX (booktabs) скопирована.", ja: "LaTeX (booktabs) テーブルをコピーしました。", zh: "已复制 LaTeX (booktabs) 表格。"))
                    }
                    .buttonStyle(.bordered)
                    Button(L10n.tr(vm.language, de: "BibTeX (8 Quellen) kopieren", en: "Copy BibTeX (8 Papers)", fr: "Copier BibTeX (8 articles)", es: "Copiar BibTeX (8 artículos)", pt: "Copiar BibTeX (8 artigos)", ru: "Копировать BibTeX (8 статей)", ja: "BibTeX (8論文) をコピー", zh: "复制 BibTeX（8 篇文献）")) {
                        copyToClipboard(vm.exportBibTeX(), label: L10n.tr(vm.language, de: "BibTeX-Literaturverzeichnis kopiert.", en: "BibTeX bibliography copied.", fr: "Bibliographie BibTeX copiée.", es: "Bibliografía BibTeX copiada.", pt: "Bibliografia BibTeX copiada.", ru: "Библиография BibTeX скопирована.", ja: "BibTeX 参考文献リストをコピーしました。", zh: "已复制 BibTeX 参考文献条目。"))
                    }
                    .buttonStyle(.bordered)

                    if !vm.sciExportFeedback.isEmpty {
                        Text(vm.sciExportFeedback)
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.amberGlow)
                    }
                }
            }

            // Expanded 8-Paper Peer-Reviewed Literature Matrix
            SolarisCard {
                Text(vm.t("sci_papers_title"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    LiteratureRow(
                        citation: "Williams, Waterman & Patterson (CACM '09)",
                        topic: L10n.tr(vm.language,
                            de: "Roofline-Modell: P = min(β · I, π) & Knickpunkt",
                            en: "Roofline Model: P = min(β · I, π) & Ridge Point",
                            fr: "Modèle Roofline : P = min(β · I, π) & point de coude",
                            es: "Modelo Roofline: P = min(β · I, π) y punto de inflexión",
                            pt: "Modelo Roofline: P = min(β · I, π) e ponto de crista",
                            ru: "Модель Roofline: P = min(β · I, π) и точка излома",
                            ja: "ルーフラインモデル: P = min(β · I, π) とリッジ点",
                            zh: "Roofline 模型：P = min(β · I, π) 与算力拐点"),
                        application: L10n.tr(vm.language,
                            de: "Quantifiziert UMA-Bandbreiten-Grenzen (Decode) vs. Metal-TFLOPS-Grenzen (Prefill).",
                            en: "Quantifies UMA bandwidth limits (Decode) vs. Metal TFLOPS compute ceilings (Prefill).",
                            fr: "Quantifie les limites de bande passante UMA (Decode) vs plafonds TFLOPS Metal (Prefill).",
                            es: "Cuantifica los límites de ancho de banda UMA (Decode) frente a TFLOPS Metal (Prefill).",
                            pt: "Quantifica os limites de largura de banda UMA (Decode) vs tetos Metal TFLOPS (Prefill).",
                            ru: "Оценивает лимиты пропускной способности ОЗУ (Decode) и Metal TFLOPS (Prefill).",
                            ja: "UMA 帯域限界（Decode）と Metal TFLOPS 上限（Prefill）を定量化します。",
                            zh: "量化 UMA 内存带宽受限阶段（解码）与 Metal TFLOPS 算力受限阶段（预填充）。")
                    )
                    LiteratureRow(
                        citation: "Patel et al. — Splitwise (ISCA '24) / DistServe (OSDI '24)",
                        topic: L10n.tr(vm.language,
                            de: "Phasen-Zerlegung & Goodput-Optimierung",
                            en: "Phase Disaggregation & Goodput Optimization",
                            fr: "Désagrégation de phase & optimisation du goodput",
                            es: "Desagregación de fases y optimización del goodput",
                            pt: "Desagregação de fases e otimização de goodput",
                            ru: "Разделение фаз и оптимизация Goodput",
                            ja: "フェーズ分離と Goodput 最適化",
                            zh: "预填充/解码分离与 Goodput 优化"),
                        application: L10n.tr(vm.language,
                            de: "Trennt rechenintensive Eingabe-Verarbeitung von latenzkritischer Token-Erzeugung.",
                            en: "Separates compute-bound input processing from latency-critical token generation.",
                            fr: "Sépare le traitement d'entrée intensif de la génération de jetons sensible à la latence.",
                            es: "Separa el preprocesado intensivo de la generación de tokens sensible a la latencia.",
                            pt: "Separa o processamento intensivo de entrada da geração de tokens crítica em latência.",
                            ru: "Отделяет вычисления входа от генерации токенов с критической задержкой.",
                            ja: "計算負荷の高い入力処理とレイテンシ重視のトークン生成を分離します。",
                            zh: "将计算密集的输入处理与延迟敏感的逐字生成分离部署。")
                    )
                    LiteratureRow(
                        citation: "Kwon et al. — PagedAttention (ACM SOSP '23)",
                        topic: L10n.tr(vm.language,
                            de: "KV-Speicher-Verwaltung & Quantisierung",
                            en: "KV Cache Memory Management & Quantization",
                            fr: "Gestion mémoire KV & quantification",
                            es: "Gestión de memoria KV y cuantización",
                            pt: "Gestão de memória KV e quantização",
                            ru: "Управление KV-памятью и квантование",
                            ja: "KV メモリ管理と量子化",
                            zh: "KV 缓存内存分页与量化"),
                        application: L10n.tr(vm.language,
                            de: "Vermeidet Speicher-Fragmentierung und vervierfacht den Kontext über 4-Bit-KV.",
                            en: "Eliminates memory fragmentation and quadruples usable context via 4-bit KV.",
                            fr: "Évite la fragmentation mémoire et quadruple le contexte via le KV 4 bits.",
                            es: "Evita la fragmentación de memoria y cuadruplica el contexto mediante KV de 4 bits.",
                            pt: "Evita fragmentação de memória e quadruplica o contexto via KV de 4 bits.",
                            ru: "Устраняет фрагментацию памяти и вчетверо увеличивает контекст с 4-битным KV.",
                            ja: "メモリの断片化を防ぎ、4ビット KV によりコンテキスト長を 4 倍に拡張します。",
                            zh: "消除显存碎片，并通过 4-bit KV 量化将可用上下文长度扩大四倍。")
                    )
                    LiteratureRow(
                        citation: "Borzunov et al. — Petals (ACL '23)",
                        topic: L10n.tr(vm.language,
                            de: "Kollaborative Inferenz über das Internet-WAN",
                            en: "Collaborative Inference over Internet WAN",
                            fr: "Inférence collaborative sur réseau WAN",
                            es: "Inferencia colaborativa sobre Internet WAN",
                            pt: "Inferência colaborativa em rede WAN",
                            ru: "Совместный инференс через интернет-WAN",
                            ja: "インターネット WAN 越しの協調推論",
                            zh: "基于互联网广域网的协同推理"),
                        application: L10n.tr(vm.language,
                            de: "Zeigt fehlertolerante Pipeline-Verteilung & Aktivierungs-Kompression über WAN.",
                            en: "Demonstrates fault-tolerant pipeline sharding & activation compression across WAN.",
                            fr: "Démontre le pipeline tolérant aux pannes et la compression d'activations sur WAN.",
                            es: "Demuestra distribución pipeline tolerante a fallos y compresión de activaciones WAN.",
                            pt: "Demonstra pipeline tolerante a falhas e compressão de ativações em WAN.",
                            ru: "Описывает отказоустойчивый конвейер и сжатие активаций через WAN.",
                            ja: "耐障害性のあるパイプライン分散と WAN アクティベーション圧縮を実現します。",
                            zh: "支持容错流水线切片与跨广域网激活张量压缩传输。")
                    )
                    LiteratureRow(
                        citation: "Ryabinin et al. — SWARM Parallelism (ICML '23)",
                        topic: L10n.tr(vm.language,
                            de: "Fehlertolerantes Routing in heterogenen WAN-Verbünden",
                            en: "Fault-Tolerant Routing in Heterogeneous WAN Clusters",
                            fr: "Routage tolérant aux pannes en grappe WAN hétérogène",
                            es: "Enrutamiento tolerante a fallos en clústeres WAN heterogéneos",
                            pt: "Encaminhamento tolerante a falhas em clusters WAN heterogéneos",
                            ru: "Отказоустойчивая маршрутизация в разнородных WAN-кластерах",
                            ja: "異種 WAN クラスタにおける耐障害ルーティング",
                            zh: "异构广域网集群中的容错动态路由"),
                        application: L10n.tr(vm.language,
                            de: "Dynamische Umleitung um Nachzügler (Straggler) und instabile WAN-Verbindungen.",
                            en: "Dynamic rerouting around stragglers and unstable WAN links.",
                            fr: "Contournement dynamique des nœuds lents et des liens WAN instables.",
                            es: "Redirección dinámica evitando nodos rezagados y enlaces WAN inestables.",
                            pt: "Reencaminhamento dinâmico contornando nós atrasados e ligações WAN instáveis.",
                            ru: "Динамический обход отстающих узлов и нестабильных WAN-каналов.",
                            ja: "遅延ノードや不安定な WAN 接続を動的に迂回します。",
                            zh: "动态绕过掉队慢节点与不稳定的广域网链路。")
                    )
                    LiteratureRow(
                        citation: "Douillard et al. — DiLoCo (arXiv '24)",
                        topic: L10n.tr(vm.language,
                            de: "Verteiltes Training mit extrem geringer Kommunikation",
                            en: "Low-Communication Distributed Training",
                            fr: "Entraînement distribué à très faible communication",
                            es: "Entrenamiento distribuido con bajísima comunicación",
                            pt: "Treino distribuído com baixíssima comunicação",
                            ru: "Распределённое обучение с минимальным обменом",
                            ja: "超低通信コスト分散トレーニング",
                            zh: "极低通信开销分布式训练"),
                        application: L10n.tr(vm.language,
                            de: "H lokal ausgeführte Schritte reduzieren die WAN-Netzlast gegenüber DDP um Faktor H×.",
                            en: "H local optimizer steps cut WAN bandwidth demand vs. DDP by factor H×.",
                            fr: "H pas locaux réduisent le trafic WAN d'un facteur H× par rapport à DDP.",
                            es: "H pasos locales reducen la carga WAN frente a DDP en un factor H×.",
                            pt: "H passos locais reduzem a carga WAN face ao DDP num fator de H×.",
                            ru: "H локальных шагов снижают трафик WAN в H× раз по сравнению с DDP.",
                            ja: "H 回のローカルステップにより DDP 比で WAN 通信量を 1/H に削減します。",
                            zh: "本地执行 H 步可将广域网通信负载相比 DDP 降低 H× 倍。")
                    )
                    LiteratureRow(
                        citation: "Apple MLX / JACCL ('24/'25)",
                        topic: L10n.tr(vm.language,
                            de: "RDMA über Thunderbolt 5 & Metal Fast Sync",
                            en: "RDMA over Thunderbolt 5 & Metal Fast Sync",
                            fr: "RDMA sur Thunderbolt 5 & Metal Fast Sync",
                            es: "RDMA por Thunderbolt 5 y Metal Fast Sync",
                            pt: "RDMA sobre Thunderbolt 5 e Metal Fast Sync",
                            ru: "RDMA через Thunderbolt 5 и Metal Fast Sync",
                            ja: "Thunderbolt 5 RDMA & Metal Fast Sync",
                            zh: "Thunderbolt 5 RDMA 与 Metal 快速同步"),
                        application: L10n.tr(vm.language,
                            de: "Direktspeicher-Verbindungen und ~4 µs Synchronisations-Schranken bei Übergaben.",
                            en: "Direct-memory transfers and ~4 µs synchronization barriers at handoffs.",
                            fr: "Transferts mémoire directe et barrières de synchronisation ~4 µs.",
                            es: "Transferencias directas de memoria y barreras de sincronización de ~4 µs.",
                            pt: "Transferências diretas de memória e barreiras de sincronização de ~4 µs.",
                            ru: "Прямой доступ к памяти и барьеры синхронизации ~4 мкс.",
                            ja: "ダイレクトメモリアクセスと約 4 µs の超低遅延同期バリア。",
                            zh: "直接内存零拷贝传输以及仅约 4 µs 的阶段同步屏障。")
                    )
                    LiteratureRow(
                        citation: "TokenPowerBench ('25)",
                        topic: L10n.tr(vm.language,
                            de: "Energie pro Token (J/tok), EDP & CO₂-Bilanzierung",
                            en: "Energy per Token (J/tok), EDP & CO₂ Accounting",
                            fr: "Énergie par jeton (J/tok), EDP & bilan CO₂",
                            es: "Energía por token (J/tok), EDP y contabilidad de CO₂",
                            pt: "Energia por token (J/tok), EDP e balanço de CO₂",
                            ru: "Энергия на токен (Дж/ток), EDP и учёт CO₂",
                            ja: "トークンあたり電力 (J/tok)・EDP・CO₂ 算出",
                            zh: "单 Token 能耗 (J/tok)、EDP 与碳排核算"),
                        application: L10n.tr(vm.language,
                            de: "Phasenbezogene Messung von J/Token, Wh/1M Token und gCO₂eq im Verbund.",
                            en: "Phase-aware measurement of J/token, Wh/1M tokens, and gCO₂eq across the cluster.",
                            fr: "Mesure par phase de J/jeton, Wh/1M jetons et gCO₂eq dans le cluster.",
                            es: "Medición por fases de J/token, Wh/1M tokens y gCO₂eq en el clúster.",
                            pt: "Medição por fases de J/token, Wh/1M tokens e gCO₂eq no cluster.",
                            ru: "Пофазный замер Дж/токен, Вт·ч/1M токенов и гCO₂ в кластере.",
                            ja: "クラスタ全体の J/token、Wh/1M トークン、gCO₂eq をフェーズ別に測定します。",
                            zh: "按阶段测量整个集群的焦耳/Token、瓦时/百万 Token 与克二氧化碳当量。")
                    )
                }
            }
        }
    }

    // MARK: - Tab 6: Verlaufsaufzeichnung (Einzel-Position & Global)

    private var historyLogTabContent: some View {
        let entries = vm.filteredScienceHistory

        return VStack(alignment: .leading, spacing: 20) {
            SolarisCard(accent: SolarisTheme.amber) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr(vm.language,
                            de: "Verlaufsaufzeichnung: Einzel-Positionen & Global-Snapshots",
                            en: "History Recording: Per-Position & Global Snapshots",
                            fr: "Historique : par position & captures globales",
                            es: "Registro de historial: por posición y capturas globales",
                            pt: "Registo de histórico: por posição e capturas globais",
                            ru: "Запись истории: по позициям и глобальные снимки",
                            ja: "履歴記録: 項目別・グローバルスナップショット",
                            zh: "历史记录：单指标快照与全局快照"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(L10n.tr(vm.language,
                            de: "Zeichnet automatisch nach jeder Messreihe oder manuell für einzelne Mess-Positionen (Durchsatz, Latenz, Energie, WAN, Speicher) sowie global den Zeitverlauf auf.",
                            en: "Records time series automatically after each benchmark run or manually for individual positions (throughput, latency, energy, WAN, memory) as well as globally.",
                            fr: "Enregistre automatiquement après chaque série ou manuellement pour chaque métrique (débit, latence, énergie, WAN, mémoire) et globalement.",
                            es: "Registra series temporales automáticamente tras cada medición o manualmente por posición (rendimiento, latencia, energía, WAN, memoria) o global.",
                            pt: "Regista séries temporais automaticamente após cada medição ou manualmente por posição (débito, latência, energia, WAN, memória) e global.",
                            ru: "Записывает тренды автоматически после замеров или вручную по отдельным метрикам (скорость, задержка, энергия, WAN, память) и глобально.",
                            ja: "計測シリーズ後または手動で、項目別（スループット・遅延・電力・WAN・メモリ）およびグローバルの時系列履歴を記録します。",
                            zh: "在每次基准测试后自动或手动记录单项指标（吞吐、延迟、能耗、广域网、显存）及全局时间序列历史。"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                    Spacer()
                    Toggle(L10n.tr(vm.language, de: "Auto-Aufzeichnung", en: "Auto-Record", fr: "Auto-enregistrement", es: "Auto-registro", pt: "Auto-registo", ru: "Автозапись", ja: "自動記録", zh: "自动记录"), isOn: $vm.sciAutoRecordHistory)
                        .toggleStyle(.switch)
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textPrimary)
                }

                // Position filter & recording actions
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.tr(vm.language,
                        de: "Aufzeichnungs- & Filter-Position",
                        en: "Recording & Filter Position",
                        fr: "Position d'enregistrement & filtre",
                        es: "Posición de registro y filtro",
                        pt: "Posição de registo e filtro",
                        ru: "Позиция записи и фильтр",
                        ja: "記録・フィルター対象",
                        zh: "记录与筛选维度"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(ScienceHistoryPosition.allCases) { pos in
                            let selected = vm.sciHistoryPositionFilter == pos
                            Button {
                                vm.sciHistoryPositionFilter = pos
                            } label: {
                                Text(pos.localizedTitle(vm.language))
                                    .font(.system(size: 12, weight: selected ? .bold : .medium))
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(selected ? SolarisTheme.amber : SolarisTheme.cardElevated)
                                    )
                                    .foregroundColor(selected ? .black : SolarisTheme.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            vm.recordScienceHistory(
                                position: vm.sciHistoryPositionFilter,
                                note: L10n.tr(vm.language, de: "Einzel-Position", en: "Single Position", fr: "Position unique", es: "Posición individual", pt: "Posição individual", ru: "Отдельная позиция", ja: "単一項目", zh: "单项记录")
                            )
                        } label: {
                            Label(L10n.tr(vm.language,
                                de: "Einzel-Position aufzeichnen",
                                en: "Record Position",
                                fr: "Enregistrer position",
                                es: "Registrar posición",
                                pt: "Registar posição",
                                ru: "Записать позицию",
                                ja: "項目を記録",
                                zh: "记录当前维度"), systemImage: "record.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SolarisTheme.amber)
                        .foregroundColor(.black)

                        Button {
                            vm.recordScienceHistory(
                                position: .globalAll,
                                note: L10n.tr(vm.language, de: "Global-Snapshot", en: "Global Snapshot", fr: "Capture globale", es: "Captura global", pt: "Captura global", ru: "Глобальный снимок", ja: "グローバル記録", zh: "全局快照")
                            )
                        } label: {
                            Label(L10n.tr(vm.language,
                                de: "Global aufzeichnen",
                                en: "Record Global",
                                fr: "Enregistrer global",
                                es: "Registrar global",
                                pt: "Registar global",
                                ru: "Записать всё",
                                ja: "全体を記録",
                                zh: "记录全局快照"), systemImage: "globe")
                        }
                        .buttonStyle(.bordered)
                        .tint(SolarisTheme.mint)

                        if !vm.sciHistoryEntries.isEmpty {
                            Button {
                                copyToClipboard(vm.exportScienceHistoryCSV(), label: L10n.tr(vm.language,
                                    de: "Verlauf als CSV kopiert (\(entries.count) Einträge).",
                                    en: "History copied as CSV (\(entries.count) entries).",
                                    fr: "Historique copié en CSV (\(entries.count) entrées).",
                                    es: "Historial copiado como CSV (\(entries.count) entradas).",
                                    pt: "Histórico copiado como CSV (\(entries.count) registos).",
                                    ru: "История скопирована в CSV (\(entries.count) зап.).",
                                    ja: "履歴を CSV コピーしました (\(entries.count) 件)。",
                                    zh: "已将历史记录复制为 CSV（共 \(entries.count) 条）。"))
                            } label: {
                                Label(L10n.tr(vm.language, de: "Verlauf CSV kopieren", en: "Copy History CSV", fr: "Copier CSV", es: "Copiar historial CSV", pt: "Copiar histórico CSV", ru: "Копировать CSV", ja: "履歴 CSV をコピー", zh: "复制历史 CSV"), systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                vm.clearScienceHistory()
                            } label: {
                                Label(L10n.tr(vm.language, de: "Verlauf leeren", en: "Clear History", fr: "Effacer l'historique", es: "Vaciar historial", pt: "Limpar histórico", ru: "Очистить историю", ja: "履歴を消去", zh: "清空历史"), systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }

                        Spacer()

                        Text(L10n.tr(vm.language,
                            de: "\(entries.count) / \(vm.sciHistoryEntries.count) Einträge",
                            en: "\(entries.count) / \(vm.sciHistoryEntries.count) entries",
                            fr: "\(entries.count) / \(vm.sciHistoryEntries.count) entrées",
                            es: "\(entries.count) / \(vm.sciHistoryEntries.count) entradas",
                            pt: "\(entries.count) / \(vm.sciHistoryEntries.count) registos",
                            ru: "\(entries.count) / \(vm.sciHistoryEntries.count) зап.",
                            ja: "\(entries.count) / \(vm.sciHistoryEntries.count) 件",
                            zh: "\(entries.count) / \(vm.sciHistoryEntries.count) 条"))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }
            }

            // Trend Chart Card
            SolarisCard(accent: SolarisTheme.mint) {
                HStack {
                    Text(L10n.tr(vm.language,
                        de: "Zeitverlauf (\(vm.sciHistoryPositionFilter.localizedTitle(vm.language)))",
                        en: "Time Series (\(vm.sciHistoryPositionFilter.localizedTitle(vm.language)))",
                        fr: "Série temporelle (\(vm.sciHistoryPositionFilter.localizedTitle(vm.language)))",
                        es: "Evolución temporal (\(vm.sciHistoryPositionFilter.localizedTitle(vm.language)))",
                        pt: "Evolução temporal (\(vm.sciHistoryPositionFilter.localizedTitle(vm.language)))",
                        ru: "Динамика (\(vm.sciHistoryPositionFilter.localizedTitle(vm.language)))",
                        ja: "時系列推移 (\(vm.sciHistoryPositionFilter.localizedTitle(vm.language)))",
                        zh: "时间序列趋势 (\(vm.sciHistoryPositionFilter.localizedTitle(vm.language)))"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    HStack(spacing: 14) {
                        Label(L10n.tr(vm.language, de: "Durchsatz (tok/s)", en: "Throughput (tok/s)", fr: "Débit (tok/s)", es: "Rendimiento (tok/s)", pt: "Débito (tok/s)", ru: "Скорость (tok/с)", ja: "スループット (tok/s)", zh: "吞吐率 (tok/s)"), systemImage: "circle.fill")
                            .foregroundColor(SolarisTheme.amberGlow)
                        Label(L10n.tr(vm.language, de: "Energie (J/tok)", en: "Energy (J/tok)", fr: "Énergie (J/tok)", es: "Energía (J/tok)", pt: "Energia (J/tok)", ru: "Энергия (Дж/ток)", ja: "エネルギー (J/tok)", zh: "能耗 (J/tok)"), systemImage: "circle.fill")
                            .foregroundColor(SolarisTheme.emerald)
                    }
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }

                if entries.isEmpty {
                    Text(L10n.tr(vm.language,
                        de: "Noch keine Verlaufsdaten vorhanden. Starte eine Messreihe oder klicke auf „Einzel-Position aufzeichnen“ bzw. „Global aufzeichnen“.",
                        en: "No history entries yet. Run a benchmark series or click 'Record Position' / 'Record Global'.",
                        fr: "Aucune donnée d'historique. Lancez une série ou cliquez sur « Enregistrer position » / « Enregistrer global ».",
                        es: "Aún no hay datos de historial. Inicia una serie o haz clic en «Registrar posición» o «Registrar global».",
                        pt: "Ainda sem dados históricos. Inicie uma série ou clique em 'Registar posição' ou 'Registar global'.",
                        ru: "История пуста. Запустите замер или нажмите «Записать позицию» / «Записать всё».",
                        ja: "履歴データがまだありません。計測シリーズを実行するか、「項目を記録」または「全体を記録」をクリックしてください。",
                        zh: "暂无历史数据。请运行一次基准测试或点击“记录当前维度” / “记录全局快照”。"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    HistoryTimelineCanvasView(entries: entries)
                        .frame(height: 190)
                }
            }

            // Chronological Table Card
            if !entries.isEmpty {
                SolarisCard {
                    Text(L10n.tr(vm.language,
                        de: "Protokollierte Messpunkte (\(entries.count))",
                        en: "Recorded Data Points (\(entries.count))",
                        fr: "Points mesurés enregistrés (\(entries.count))",
                        es: "Puntos medidos registrados (\(entries.count))",
                        pt: "Pontos medidos registados (\(entries.count))",
                        ru: "Записанные точки замеров (\(entries.count))",
                        ja: "記録済み測定ポイント (\(entries.count))",
                        zh: "已记录数据点 (\(entries.count))"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    ScrollView {
                        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                            GridRow {
                                Text(L10n.tr(vm.language, de: "Zeit", en: "Time", fr: "Heure", es: "Hora", pt: "Hora", ru: "Время", ja: "時刻", zh: "时间")).foregroundColor(SolarisTheme.textSecondary)
                                Text(L10n.tr(vm.language, de: "Position", en: "Position", fr: "Position", es: "Posición", pt: "Posição", ru: "Позиция", ja: "項目", zh: "维度")).foregroundColor(SolarisTheme.textSecondary)
                                Text(L10n.tr(vm.language, de: "Bereich", en: "Scope", fr: "Portée", es: "Ámbito", pt: "Âmbito", ru: "Область", ja: "範囲", zh: "范围")).foregroundColor(SolarisTheme.textSecondary)
                                Text(L10n.tr(vm.language, de: "Modell", en: "Model", fr: "Modèle", es: "Modelo", pt: "Modelo", ru: "Модель", ja: "モデル", zh: "模型")).foregroundColor(SolarisTheme.textSecondary)
                                Text("Tok/s").foregroundColor(SolarisTheme.textSecondary)
                                Text("TTFT").foregroundColor(SolarisTheme.textSecondary)
                                Text("TPOT").foregroundColor(SolarisTheme.textSecondary)
                                Text("J/tok").foregroundColor(SolarisTheme.textSecondary)
                                Text(L10n.tr(vm.language, de: "Engpass", en: "Bottleneck", fr: "Goulot", es: "Cuello", pt: "Gargalo", ru: "Узкое место", ja: "ボトルネック", zh: "瓶颈")).foregroundColor(SolarisTheme.textSecondary)
                            }
                            .font(SolarisTheme.bodyBold)
                            Divider().gridCellUnsizedAxes(.horizontal)
                            ForEach(entries.reversed()) { entry in
                                GridRow {
                                    Text(entry.timestamp)
                                    Text(entry.positionFilter.localizedTitle(vm.language))
                                        .foregroundColor(SolarisTheme.amberGlow)
                                    Text(entry.scopeLabel)
                                    Text(entry.modelName)
                                        .lineLimit(1)
                                    Text(String(format: "%.1f", entry.tokPerSec))
                                        .foregroundColor(SolarisTheme.mint)
                                    Text(String(format: "%.1f ms", entry.ttftMs))
                                    Text(String(format: "%.1f ms", entry.tpotMs))
                                    Text(String(format: "%.2f", entry.joulesPerToken))
                                        .foregroundColor(SolarisTheme.emerald)
                                    Text(entry.bottleneckRegime)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(SolarisTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 240)
                }
            }
        }
    }

    private func copyToClipboard(_ text: String, label: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        vm.sciExportFeedback = label
    }
}

// MARK: - Roofline Log-Log Canvas

private struct RooflineCanvasView: View {
    let nodes: [ScientificNodeSnapshot]
    let decodeIntensity: Double
    let prefillIntensity: Double
    let effectiveCeilingTFLOPS: Double
    let showWanCeiling: Bool

    private let minI: Double = 0.5
    private let maxI: Double = 2048.0
    private let minP: Double = 0.1
    private let maxP: Double = 400.0

    private func xPos(_ intensity: Double, width: CGFloat) -> CGFloat {
        let clamped = min(max(intensity, minI), maxI)
        let norm = (log2(clamped) - log2(minI)) / (log2(maxI) - log2(minI))
        return CGFloat(norm) * width
    }

    private func yPos(_ tflops: Double, height: CGFloat) -> CGFloat {
        let clamped = min(max(tflops, minP), maxP)
        let norm = (log10(clamped) - log10(minP)) / (log10(maxP) - log10(minP))
        return height - CGFloat(norm) * height
    }

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let padL: CGFloat = 46
                let padR: CGFloat = 18
                let padT: CGFloat = 14
                let padB: CGFloat = 28
                let plotW = max(10, size.width - padL - padR)
                let plotH = max(10, size.height - padT - padB)

                let gridIntensities: [Double] = [1, 4, 16, 64, 256, 1024]
                for gi in gridIntensities {
                    let x = padL + xPos(gi, width: plotW)
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: padT))
                    path.addLine(to: CGPoint(x: x, y: padT + plotH))
                    context.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 1)

                    let label = Text("\(Int(gi))").font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                    context.draw(label, at: CGPoint(x: x, y: padT + plotH + 12))
                }

                let gridTFLOPS: [Double] = [0.2, 1, 5, 20, 100, 300]
                for gp in gridTFLOPS {
                    let y = padT + yPos(gp, height: plotH)
                    var path = Path()
                    path.move(to: CGPoint(x: padL, y: y))
                    path.addLine(to: CGPoint(x: padL + plotW, y: y))
                    context.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 1)

                    let txt = gp < 1 ? String(format: "%.1f", gp) : "\(Int(gp))"
                    let label = Text(txt).font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                    context.draw(label, at: CGPoint(x: padL - 22, y: y))
                }

                var axes = Path()
                axes.move(to: CGPoint(x: padL, y: padT))
                axes.addLine(to: CGPoint(x: padL, y: padT + plotH))
                axes.addLine(to: CGPoint(x: padL + plotW, y: padT + plotH))
                context.stroke(axes, with: .color(.white.opacity(0.28)), lineWidth: 1.2)

                let colors: [Color] = [SolarisTheme.amberGlow, SolarisTheme.mint, SolarisTheme.emerald, SolarisTheme.coral]

                for (idx, node) in nodes.prefix(8).enumerated() {
                    let col = colors[idx % colors.count]
                    let ridge = max(minI, node.ridgePointFLOPPerByte)
                    let peak = node.peakFP16TFLOPS
                    let bw = node.bandwidthGBs

                    let startTFLOPS = (bw * minI) / 1000.0
                    let x0 = padL + xPos(minI, width: plotW)
                    let y0 = padT + yPos(startTFLOPS, height: plotH)
                    let xRidge = padL + xPos(ridge, width: plotW)
                    let yPeak = padT + yPos(peak, height: plotH)
                    let xEnd = padL + xPos(maxI, width: plotW)

                    var curve = Path()
                    curve.move(to: CGPoint(x: x0, y: y0))
                    curve.addLine(to: CGPoint(x: xRidge, y: yPeak))
                    curve.addLine(to: CGPoint(x: xEnd, y: yPeak))
                    context.stroke(curve, with: .color(col), lineWidth: 2.0)

                    let dot = Path(ellipseIn: CGRect(x: xRidge - 4, y: yPeak - 4, width: 8, height: 8))
                    context.fill(dot, with: .color(col))

                    let tag = Text(node.chip.replacingOccurrences(of: "Apple ", with: ""))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(col)
                    context.draw(tag, at: CGPoint(x: min(xEnd - 28, xRidge + 26), y: max(padT + 8, yPeak - 10)))
                }

                // Effective WAN / Interconnect Ceiling
                if showWanCeiling && effectiveCeilingTFLOPS > minP {
                    let yEff = padT + yPos(effectiveCeilingTFLOPS, height: plotH)
                    var ceilPath = Path()
                    ceilPath.move(to: CGPoint(x: padL, y: yEff))
                    ceilPath.addLine(to: CGPoint(x: padL + plotW, y: yEff))
                    context.stroke(ceilPath, with: .color(SolarisTheme.coral.opacity(0.85)), style: StrokeStyle(lineWidth: 1.6, dash: [6, 4]))
                }

                let xDec = padL + xPos(decodeIntensity, width: plotW)
                var decLine = Path()
                decLine.move(to: CGPoint(x: xDec, y: padT))
                decLine.addLine(to: CGPoint(x: xDec, y: padT + plotH))
                context.stroke(decLine, with: .color(SolarisTheme.mint.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                let xPre = padL + xPos(prefillIntensity, width: plotW)
                var preLine = Path()
                preLine.move(to: CGPoint(x: xPre, y: padT))
                preLine.addLine(to: CGPoint(x: xPre, y: padT + plotH))
                context.stroke(preLine, with: .color(SolarisTheme.amberGlow.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SolarisTheme.cardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Multi-Regime Scaling Curve Canvas

private struct ScalingCurveCanvasView: View {
    let tb5Points: [(nodes: Int, tokPerSec: Double)]
    let tb4Points: [(nodes: Int, tokPerSec: Double)]
    let wanRegPoints: [(nodes: Int, tokPerSec: Double)]
    let wanGlobalPoints: [(nodes: Int, tokPerSec: Double)]

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let padL: CGFloat = 48
                let padR: CGFloat = 18
                let padT: CGFloat = 14
                let padB: CGFloat = 26
                let plotW = max(10, size.width - padL - padR)
                let plotH = max(10, size.height - padT - padB)

                let allTps = (tb5Points + tb4Points + wanRegPoints + wanGlobalPoints).map(\.tokPerSec)
                let maxTps = max(20.0, allTps.max() ?? 100.0)

                let nodeTicks = [1, 2, 4, 8, 16, 32, 64, 128]
                for (i, n) in nodeTicks.enumerated() {
                    let x = padL + (CGFloat(i) / CGFloat(nodeTicks.count - 1)) * plotW
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: padT))
                    p.addLine(to: CGPoint(x: x, y: padT + plotH))
                    context.stroke(p, with: .color(.white.opacity(0.08)), lineWidth: 1)
                    context.draw(Text("\(n)N").font(.system(size: 10, design: .monospaced)).foregroundColor(.gray),
                                 at: CGPoint(x: x, y: padT + plotH + 12))
                }

                for frac in [0.25, 0.5, 0.75, 1.0] {
                    let y = padT + plotH * CGFloat(1.0 - frac)
                    var p = Path()
                    p.move(to: CGPoint(x: padL, y: y))
                    p.addLine(to: CGPoint(x: padL + plotW, y: y))
                    context.stroke(p, with: .color(.white.opacity(0.08)), lineWidth: 1)
                    let val = Int(maxTps * frac)
                    context.draw(Text("\(val)").font(.system(size: 10, design: .monospaced)).foregroundColor(.gray),
                                 at: CGPoint(x: padL - 22, y: y))
                }

                let series: [([(nodes: Int, tokPerSec: Double)], Color)] = [
                    (tb5Points, SolarisTheme.emerald),
                    (tb4Points, SolarisTheme.amberGlow),
                    (wanRegPoints, SolarisTheme.mint),
                    (wanGlobalPoints, SolarisTheme.coral)
                ]

                for (pts, color) in series where pts.count >= 2 {
                    var line = Path()
                    for (idx, pt) in pts.enumerated() {
                        let x = padL + (CGFloat(idx) / CGFloat(pts.count - 1)) * plotW
                        let y = padT + plotH * CGFloat(1.0 - min(1.0, pt.tokPerSec / maxTps))
                        if idx == 0 { line.move(to: CGPoint(x: x, y: y)) }
                        else { line.addLine(to: CGPoint(x: x, y: y)) }
                        context.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)), with: .color(color))
                    }
                    context.stroke(line, with: .color(color), lineWidth: 2.0)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SolarisTheme.cardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}

private struct ScienceMetricTile: View {
    let label: String
    let value: String
    let sub: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.caption)
                .foregroundColor(SolarisTheme.textSecondary)
            Text(value)
                .font(SolarisTheme.metricMedium)
                .foregroundColor(accent)
            Text(sub)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SolarisTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(SolarisTheme.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.opacity(0.28), lineWidth: 1)
                )
        )
    }
}

private struct LiteratureRow: View {
    let citation: String
    let topic: String
    let application: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(citation)
                .font(SolarisTheme.bodyBold)
                .foregroundColor(SolarisTheme.amberGlow)
            Text(topic)
                .font(Font.caption)
                .foregroundColor(SolarisTheme.mint)
            Text(application)
                .font(Font.caption)
                .foregroundColor(SolarisTheme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(SolarisTheme.cardElevated)
        )
    }
}

private struct HistoryTimelineCanvasView: View {
    let entries: [ScienceHistoryEntry]

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let padL: CGFloat = 48
                let padR: CGFloat = 48
                let padT: CGFloat = 14
                let padB: CGFloat = 24
                let plotW = max(20, size.width - padL - padR)
                let plotH = max(20, size.height - padT - padB)

                let maxTps = max(10.0, entries.map(\.tokPerSec).max() ?? 10.0) * 1.15
                let maxJ = max(1.0, entries.map(\.joulesPerToken).max() ?? 1.0) * 1.15

                for frac in [0.0, 0.5, 1.0] {
                    let y = padT + plotH * CGFloat(1.0 - frac)
                    var grid = Path()
                    grid.move(to: CGPoint(x: padL, y: y))
                    grid.addLine(to: CGPoint(x: padL + plotW, y: y))
                    context.stroke(grid, with: .color(Color.white.opacity(0.08)), lineWidth: 1)

                    let tpsVal = Int((maxTps * frac).rounded())
                    context.draw(
                        Text("\(tpsVal)").font(.system(size: 9, design: .monospaced)).foregroundColor(SolarisTheme.amberGlow),
                        at: CGPoint(x: padL - 22, y: y)
                    )
                    let jVal = String(format: "%.1fJ", maxJ * frac)
                    context.draw(
                        Text(jVal).font(.system(size: 9, design: .monospaced)).foregroundColor(SolarisTheme.emerald),
                        at: CGPoint(x: padL + plotW + 24, y: y)
                    )
                }

                let count = entries.count
                var tpsPath = Path()
                var jPath = Path()

                for (idx, item) in entries.enumerated() {
                    let xNorm = count == 1 ? 0.5 : CGFloat(idx) / CGFloat(count - 1)
                    let x = padL + xNorm * plotW
                    let yTps = padT + plotH * CGFloat(1.0 - min(1.0, item.tokPerSec / maxTps))
                    let yJ = padT + plotH * CGFloat(1.0 - min(1.0, item.joulesPerToken / maxJ))

                    if idx == 0 {
                        tpsPath.move(to: CGPoint(x: x, y: yTps))
                        jPath.move(to: CGPoint(x: x, y: yJ))
                    } else {
                        tpsPath.addLine(to: CGPoint(x: x, y: yTps))
                        jPath.addLine(to: CGPoint(x: x, y: yJ))
                    }

                    context.fill(Path(ellipseIn: CGRect(x: x - 3.5, y: yTps - 3.5, width: 7, height: 7)), with: .color(SolarisTheme.amberGlow))
                    context.fill(Path(ellipseIn: CGRect(x: x - 3, y: yJ - 3, width: 6, height: 6)), with: .color(SolarisTheme.emerald))
                }

                if count >= 2 {
                    context.stroke(tpsPath, with: .color(SolarisTheme.amberGlow), lineWidth: 2.2)
                    context.stroke(jPath, with: .color(SolarisTheme.emerald), lineWidth: 2.0)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SolarisTheme.cardElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}
