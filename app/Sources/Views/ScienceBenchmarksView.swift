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
                            ? "SIMULATION · Realistische Apple-Silicon-Referenzwerte"
                            : "ECHTZEIT-DATEN · Gemessene System- & Endpunkt-Telemetrie",
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

            // Full-width Scope Selector (no clipping of "Vergleich (Lokal vs. WAN)") + Quick History Capture
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
                                Text(scope.rawValue)
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
                        vm.recordScienceHistory(position: .globalAll, note: "Schnappschuss (\(vm.sciScope.rawValue))")
                    } label: {
                        Label("Verlauf aufzeichnen (\(vm.sciHistoryEntries.count))", systemImage: "record.circle")
                    }
                    .buttonStyle(.bordered)
                    .tint(SolarisTheme.amber)
                }

                HStack(spacing: 10) {
                    Text("\(vm.activeScienceNodes.count) Knoten · \(Int(vm.activeTotalUsableVramGB)) GB nutzbar")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(vm.isWanScienceActive ? SolarisTheme.mint : SolarisTheme.amberGlow)
                    Text("·")
                        .foregroundColor(SolarisTheme.textSecondary)
                    Text(vm.activeBottleneckRegime)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(SolarisTheme.coral)
                    Spacer()
                    if let last = vm.sciHistoryEntries.last {
                        Text("Letzter Verlauf: \(last.timestamp) (\(last.note))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }
            }

            if vm.isWanScienceActive && vm.wanPeers.count <= 1 {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(SolarisTheme.amberGlow)
                    Text("Im Internet-WAN-Verbund ist aktuell nur der lokale Knoten aktiv. Öffne 'Internet-Cluster & Chat' für einen Forschungs-Schwarm oder Welt-Verbund, um Multi-Region-WAN-Latenzen direkt hier zu vermessen.")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                    Spacer()
                    Button("Forschungs-Schwarm (12 Macs) laden") {
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
                        Text("Batch-Größe (B)")
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
                        Text("Mikro-Batches (M)")
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
                        Text("Eingabelänge (S_prompt)")
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
                        Text("Gewichts-Genauigkeit")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Bits", selection: $vm.sciWeightBits) {
                            ForEach(bitOptions, id: \.self) { bits in
                                Text(bits == 16 ? "FP16" : "\(bits)-Bit").tag(bits)
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
                            String(format: "Eff. Netz-Decke: %.1f TFLOPS", vm.activeEffectiveRooflineCeilingTFLOPS),
                            systemImage: "line.diagonal"
                        )
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(SolarisTheme.coral)
                    }

                    Spacer()

                    Text(String(format: "Spitze: %.1f TFLOPS · Eff. BW: %.0f GB/s", vm.activePeakFP16TFLOPS, vm.activeEffectiveDecodeBandwidthGBs))
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
                        label: "GPipe-Blase & B*",
                        value: String(format: "%.1f %%", vm.activePipelineBubbleFraction * 100.0),
                        sub: "Krit. Batch B* = \(vm.criticalBatchSizeBStar) · RTT \(String(format: "%.1f", vm.activeStepRttMs)) ms",
                        accent: SolarisTheme.coral
                    )
                    ScienceMetricTile(
                        label: "Energie & EDP",
                        value: String(format: "%.2f J/tok", vm.activeJoulesPerToken),
                        sub: String(format: "%.0f W · EDP %.3f J·s", vm.activeWatts, vm.activeEDPJoulesSec),
                        accent: SolarisTheme.emerald
                    )
                }
            }

            // Hybrid Local vs WAN Comparison Card
            if vm.sciScope == .hybridCompare {
                SolarisCard(accent: SolarisTheme.amber) {
                    Text("Direktvergleich: Lokaler TB/RDMA-Verbund vs. Internet-WAN-Verbund")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 10) {
                        GridRow {
                            Text("Kenngröße").foregroundColor(SolarisTheme.textSecondary)
                            Text("Lokal (TB/RDMA)").foregroundColor(SolarisTheme.amberGlow)
                            Text("Internet-WAN (\(vm.wanPeers.count) Knoten)").foregroundColor(SolarisTheme.mint)
                        }
                        .font(SolarisTheme.bodyBold)
                        Divider().gridCellUnsizedAxes(.horizontal)
                        GridRow {
                            Text("Gesamt-RAM / Nutzbar")
                            Text("\(Int(vm.totalPhysicalRamGB)) GB / \(Int(vm.totalUsableVramGB)) GB")
                            Text("\(Int(vm.wanTotalRamGB)) GB / \(Int(vm.wanTotalUsableVramGB)) GB")
                        }
                        GridRow {
                            Text("Verbindungs-Latenz pro Schritt")
                            Text(String(format: "%.3f ms", vm.estimatedInterconnectOverheadMs))
                            Text(String(format: "%.1f ms", vm.wanTotalRttMs))
                        }
                        GridRow {
                            Text("Geschätzter Durchsatz (Decode)")
                            Text(String(format: "%.1f tok/s", vm.estimatedTokPerSec))
                            Text(String(format: "%.1f tok/s", vm.wanEstimatedTokPerSec))
                        }
                        GridRow {
                            Text("Energiebedarf pro Token")
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
                        Text("Knoten / Chip").foregroundColor(SolarisTheme.textSecondary)
                        Text("Bandbreite").foregroundColor(SolarisTheme.textSecondary)
                        Text("Spitze FP16").foregroundColor(SolarisTheme.textSecondary)
                        Text("Knickpunkt").foregroundColor(SolarisTheme.textSecondary)
                        Text("Schicht-Anteil").foregroundColor(SolarisTheme.textSecondary)
                        Text("Verbindung / RTT").foregroundColor(SolarisTheme.textSecondary)
                        Text("Leistung").foregroundColor(SolarisTheme.textSecondary)
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
                    Text("… plus \(vm.activeScienceNodes.count - 16) weitere WAN-Knoten im Verbund.")
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
                    Text("Multi-Model-Mode (MMM) — Wissenschaftliche Auswertung")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("Direkte Auswertung der zusammengeführten Multi-Modell-Läufe (\(vm.mmmScope.rawValue) · \(vm.mmmStrategy.rawValue)) inkl. Multi-IDE-Last.")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                if let lastMmm = vm.mmmLastResult {
                    Button("MMM-Lauf in Verlauf übernehmen") {
                        vm.recordScienceHistoryFromMMM(lastMmm)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SolarisTheme.mint)
                    .foregroundColor(.black)
                }
            }

            HStack(spacing: 14) {
                ScienceMetricTile(
                    label: "MMM Durchsatz (Mittel)",
                    value: String(format: "%.1f tok/s", vm.mmmMeanObservedTokPerSec),
                    sub: "\(vm.mmmHistory.count) Läufe · \(vm.mmmActiveSlots.count) aktive Slots",
                    accent: SolarisTheme.mint
                )
                ScienceMetricTile(
                    label: "Speedup vs. Einzelmodell",
                    value: String(format: "%.2fx", vm.mmmMeanSpeedupFactor),
                    sub: vm.mmmLastResult.map { $0.isLiveExecution ? "Live SSE" : "Simulation" } ?? "Theoretische Schätzung",
                    accent: SolarisTheme.amberGlow
                )
                ScienceMetricTile(
                    label: "VRAM-Pool & Multi-IDE",
                    value: String(format: "%.1f / %.1f GB", vm.mmmTotalRequiredVramGB, vm.mmmUsableVramPoolGB),
                    sub: String(format: "%.1f tok/s je Client (%d IDEs)", vm.mmmPerClientTokPerSec, vm.mmmActiveClientCount),
                    accent: vm.mmmFitsInClusterPool ? SolarisTheme.emerald : SolarisTheme.coral
                )
            }
        }
    }

    // MARK: - Tab 2: WAN Topology, Latency Decomposition & Scaling

    private var wanTopologyTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            SolarisCard(accent: SolarisTheme.mint) {
                Text("Internet-WAN-Latenzzerlegung & Aktivierungs-Kompression")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Aktivierungs-Kompression (Petals / SWARM)")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Compression", selection: $vm.sciActivationCompression) {
                            ForEach(ActivationCompressionMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        Text(vm.sciActivationCompression.qualityNote)
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.mint)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("WAN-Nachzügler / Paketverlust: \(Int(vm.sciStragglerRate * 100)) %")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciStragglerRate, in: 0...0.25, step: 0.01)
                            .tint(SolarisTheme.coral)
                        Text("Simuliert langsame Knoten oder CGNAT-Neuübertragung")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("WAN-Schwankung (Tail-Jitter): \(Int(vm.sciWanJitterFactor * 100)) %")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciWanJitterFactor, in: 0.02...0.50, step: 0.02)
                            .tint(SolarisTheme.amber)
                        Text("Steuert p95/p99-Ausreißer in Messreihen")
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
                    Text(String(format: "Schritt-Zeitaufteilung (Gesamt: %.2f ms · Nutzlast/Hop: %.3f MB)", total, vm.activationPayloadMBPerHop))
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
                        Label(String(format: "UMA-Rechnung: %.1f ms (%.0f%%)", comp, (comp / total) * 100), systemImage: "square.fill")
                            .foregroundColor(SolarisTheme.amberGlow)
                        Label(String(format: "Nutzlast-Transfer: %.2f ms (%.0f%%)", tx, (tx / total) * 100), systemImage: "square.fill")
                            .foregroundColor(SolarisTheme.mint)
                        Label(String(format: "Netz-RTT + Tunnel: %.1f ms (%.0f%%)", rtt, (rtt / total) * 100), systemImage: "square.fill")
                            .foregroundColor(SolarisTheme.coral)
                        if stag > 0 {
                            Label(String(format: "Nachzügler: %.1f ms", stag), systemImage: "square.fill")
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
                Text("Skalierungskurve (N = 1 bis 128 Macs): TB5 RDMA vs. TB4 vs. Regional-WAN vs. Welt-WAN")
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
                    Label("TB4 Brücke (32 Gbps)", systemImage: "circle.fill").foregroundColor(SolarisTheme.amberGlow)
                    Label("WAN Regional (25 ms)", systemImage: "circle.fill").foregroundColor(SolarisTheme.mint)
                    Label("WAN Weltweit (110 ms)", systemImage: "circle.fill").foregroundColor(SolarisTheme.coral)
                }
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }

            // Training vs Inference over WAN (DiLoCo vs DDP)
            SolarisCard(accent: SolarisTheme.amber) {
                HStack {
                    Text("Feinabstimmung & Training über das Internet: Naives DDP vs. DiLoCo vs. Inferenz-Pipeline")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Picker("DiLoCo H", selection: $vm.sciDiLoCoLocalSteps) {
                        ForEach(dilocoOptions, id: \.self) { h in
                            Text("H = \(h) Schritte").tag(h)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 340)
                }

                let comm = vm.trainingCommAnalysis
                HStack(spacing: 14) {
                    ScienceMetricTile(
                        label: "Naives DDP (All-Reduce / Schritt)",
                        value: String(format: "%.0f Gbit/s", comm.ddpMbps / 1000.0),
                        sub: "Überlastet Internet-WAN vollständig",
                        accent: SolarisTheme.coral
                    )
                    ScienceMetricTile(
                        label: "DiLoCo (H=\(comm.reductionFactor) lokale Schritte)",
                        value: String(format: "%.1f Mbit/s", comm.diLoCoMbps),
                        sub: "\(comm.reductionFactor)× weniger Netzlast (WAN-tauglich)",
                        accent: SolarisTheme.amberGlow
                    )
                    ScienceMetricTile(
                        label: "Pipeline-Inferenz (\(vm.sciActivationCompression.rawValue))",
                        value: String(format: "%.2f Mbit/s", comm.pipelineInfMbps),
                        sub: "Überträgt nur Aktivierungsvektoren",
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
                    Text("Transformer-Speichergleichung & iogpu.wired_limit_mb-Sicherheitsanalyse")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Text(fits ? "✓ Passt in nutzbaren Pool" : "⚠ Überschreitet Pool-Grenze")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(fits ? SolarisTheme.emerald : SolarisTheme.coral)
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Antwort-Länge (S_gen)")
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
                        Text("KV-Speicher-Genauigkeit")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("KV", selection: $vm.kvPrecision) {
                            ForEach(KVCachePrecision.allCases) { kv in
                                Text(kv.rawValue).tag(kv)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                }

                HStack(spacing: 14) {
                    ScienceMetricTile(
                        label: "Modell-Gewichte (\(vm.sciWeightBits)-Bit)",
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
                        label: "Aktivierungen & Arbeitsbereich",
                        value: String(format: "%.2f GB", mem.activationsGB),
                        sub: "Chunked Prefill: \(vm.prefillStepSize) tok",
                        accent: SolarisTheme.emerald
                    )
                    ScienceMetricTile(
                        label: "Max. Kontext (S_max bei B=\(vm.sciBatchSize))",
                        value: mem.maxContextTokens >= 1000 ? "\(mem.maxContextTokens / 1000)k tok" : "\(mem.maxContextTokens) tok",
                        sub: String(format: "Pool: %.0f GB nutzbar", pool),
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
                Text("Genauigkeits- vs. Speicher-Abwägung (Forschungs-Richtwerte)")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text("Verfahren").foregroundColor(SolarisTheme.textSecondary)
                        Text("Speicherfaktor").foregroundColor(SolarisTheme.textSecondary)
                        Text("Typische PPL-Abweichung").foregroundColor(SolarisTheme.textSecondary)
                        Text("Eignung im Verbund").foregroundColor(SolarisTheme.textSecondary)
                    }
                    .font(SolarisTheme.bodyBold)
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        Text("FP16 / BF16 Referenz")
                        Text("1,00× (2,0 B/Param)")
                        Text("0,00 (Basislinie)")
                        Text("Nur sehr große RAM-Verbünde")
                    }
                    GridRow {
                        Text("8-Bit MLX / INT8-KV")
                        Text("0,53×")
                        Text("+0,01–0,03 PPL")
                        Text("Höchste Genauigkeit bei moderatem RAM")
                    }
                    GridRow {
                        Text("4-Bit MLX Affine (g=64)")
                        Text("0,28× (0,56 B/Param)")
                        Text("+0,08–0,18 PPL")
                        Text("Standard für UMA-Bandbreiten-Optimierung")
                    }
                    GridRow {
                        Text("4-Bit KV-Quantisierung (KIVI/oMLX)")
                        Text("0,25× KV-Bedarf")
                        Text("<0,05 MMLU-Delta")
                        Text("Ermöglicht 64k–128k Agenten-Kontexte")
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
                Text("Energiebilanz (TokenPowerBench), CO₂-Fußabdruck & Stromkosten")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Strommix-Region (CO₂-Intensität)")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Picker("Region", selection: $vm.sciCarbonRegion) {
                            ForEach(CarbonRegionProfile.allCases) { region in
                                Text(region.rawValue).tag(region)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: "Strompreis: %.2f €/kWh", vm.sciElectricityEurPerKwh))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciElectricityEurPerKwh, in: 0.08...0.60, step: 0.02)
                            .tint(SolarisTheme.amber)
                    }
                }

                HStack(spacing: 14) {
                    ScienceMetricTile(
                        label: "Energie pro Token",
                        value: String(format: "%.2f J/tok", vm.activeJoulesPerToken),
                        sub: String(format: "%.1f Wh / 1M Token", (vm.activeJoulesPerToken * 1_000_000.0) / 3600.0),
                        accent: SolarisTheme.emerald
                    )
                    ScienceMetricTile(
                        label: "Energy-Delay Product (EDP)",
                        value: String(format: "%.3f J·s", vm.activeEDPJoulesSec),
                        sub: "Kleiner = besseres Effizienz-Latenz-Verhältnis",
                        accent: SolarisTheme.mint
                    )
                    ScienceMetricTile(
                        label: "CO₂ pro 1 Mio. Token",
                        value: String(format: "%.1f gCO₂", vm.activeCO2GramsPerMillionTokens),
                        sub: "\(Int(vm.sciCarbonRegion.gco2PerKwh)) gCO₂eq/kWh",
                        accent: SolarisTheme.amberGlow
                    )
                    ScienceMetricTile(
                        label: "Stromkosten / 1M Token",
                        value: String(format: "%.3f €", vm.activeCostEurPerMillionTokens),
                        sub: String(format: "%.0f W Gesamtleistung", vm.activeWatts),
                        accent: SolarisTheme.amber
                    )
                }
            }

            SolarisCard {
                Text("Vergleich: Apple-Silicon-Verbund vs. Rechenzentrums-Cloud (70B-Klasse)")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)

                Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 10) {
                    GridRow {
                        Text("Betriebsart").foregroundColor(SolarisTheme.textSecondary)
                        Text("Typische Leistung").foregroundColor(SolarisTheme.textSecondary)
                        Text("Energie / Token").foregroundColor(SolarisTheme.textSecondary)
                        Text("Betriebskosten / 1M Token").foregroundColor(SolarisTheme.textSecondary)
                    }
                    .font(SolarisTheme.bodyBold)
                    Divider().gridCellUnsizedAxes(.horizontal)
                    GridRow {
                        Text("Aktiver SS-CCC-Verbund (\(vm.activeScienceNodes.count) Macs)")
                            .foregroundColor(SolarisTheme.amberGlow)
                        Text("\(Int(vm.activeWatts)) W")
                        Text(String(format: "%.2f J/tok", vm.activeJoulesPerToken))
                        Text(String(format: "%.3f € (Strom)", vm.activeCostEurPerMillionTokens))
                    }
                    GridRow {
                        Text("Typische Cloud-API (70B-Klasse)")
                        Text("~700 W (H100-Anteil)")
                        Text("~4,5–9,0 J/tok")
                        Text("~0,60–1,20 € (API-Gebühr)")
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
                        Text("Reproduzierbare Messreihe (Aufwärmlauf + N Läufe bei T=0,0)")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text("Fingerabdruck: \(vm.hardwareFingerprint)")
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
                        Text("SLO-Grenze TTFT: ≤ \(Int(vm.sciSloTtftMaxMs)) ms")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Slider(value: $vm.sciSloTtftMaxMs, in: 250...8000, step: 250)
                            .tint(SolarisTheme.amber)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SLO-Grenze TPOT: ≤ \(Int(vm.sciSloTpotMaxMs)) ms/tok")
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
                        Text("Datenquelle: \(summary.backendLabel)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(summary.isLiveEndpoint ? SolarisTheme.emerald : SolarisTheme.amberGlow)
                        Spacer()
                        Text(summary.isLiveEndpoint ? "LIVE SSE + PING" : "SIMULATION")
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
                            label: "Goodput & Durchsatz",
                            value: String(format: "%.1f tok/s", summary.meanTokensPerSec),
                            sub: String(format: "SLO-Treffer: %.0f%% · %.2f J/tok", summary.goodputPercent, summary.joulesPerToken),
                            accent: SolarisTheme.emerald
                        )
                    }

                    // Per-Trial Telemetry Table
                    if !vm.sciTrials.isEmpty {
                        ScrollView {
                            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                                GridRow {
                                    Text("#").foregroundColor(SolarisTheme.textSecondary)
                                    Text("Bereich").foregroundColor(SolarisTheme.textSecondary)
                                    Text("TTFT").foregroundColor(SolarisTheme.textSecondary)
                                    Text("TPOT").foregroundColor(SolarisTheme.textSecondary)
                                    Text("Tok/s").foregroundColor(SolarisTheme.textSecondary)
                                    Text("Netz-RTT").foregroundColor(SolarisTheme.textSecondary)
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
                        Button("CSV kopieren") {
                            copyToClipboard(vm.exportScientificCSV(), label: "CSV-Messreihe kopiert.")
                        }
                        .buttonStyle(.bordered)
                    }
                    Button("JSON-Manifest kopieren") {
                        copyToClipboard(vm.exportScientificJSON(), label: "JSON-Reproduzierbarkeits-Manifest kopiert.")
                    }
                    .buttonStyle(.bordered)
                    Button("LaTeX-Tabelle kopieren") {
                        copyToClipboard(vm.exportScientificLaTeX(), label: "LaTeX-Tabelle (booktabs) kopiert.")
                    }
                    .buttonStyle(.bordered)
                    Button("BibTeX (8 Quellen) kopieren") {
                        copyToClipboard(vm.exportBibTeX(), label: "BibTeX-Literaturverzeichnis kopiert.")
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
                        topic: "Roofline-Modell: P = min(β · I, π) & Knickpunkt",
                        application: "Quantifiziert UMA-Bandbreiten-Grenzen (Decode) vs. Metal-TFLOPS-Grenzen (Prefill)."
                    )
                    LiteratureRow(
                        citation: "Patel et al. — Splitwise (ISCA '24) / DistServe (OSDI '24)",
                        topic: "Phasen-Zerlegung & Goodput-Optimierung",
                        application: "Trennt rechenintensive Eingabe-Verarbeitung von latenzkritischer Token-Erzeugung."
                    )
                    LiteratureRow(
                        citation: "Kwon et al. — PagedAttention (ACM SOSP '23)",
                        topic: "KV-Speicher-Verwaltung & Quantisierung",
                        application: "Vermeidet Speicher-Fragmentierung und vervierfacht den Kontext über 4-Bit-KV."
                    )
                    LiteratureRow(
                        citation: "Borzunov et al. — Petals (ACL '23)",
                        topic: "Kollaborative Inferenz über das Internet-WAN",
                        application: "Zeigt fehlertolerante Pipeline-Verteilung & Aktivierungs-Kompression über WAN."
                    )
                    LiteratureRow(
                        citation: "Ryabinin et al. — SWARM Parallelism (ICML '23)",
                        topic: "Fehlertolerantes Routing in heterogenen WAN-Verbünden",
                        application: "Dynamische Umleitung um Nachzügler (Straggler) und instabile WAN-Verbindungen."
                    )
                    LiteratureRow(
                        citation: "Douillard et al. — DiLoCo (arXiv '24)",
                        topic: "Verteiltes Training mit extrem geringer Kommunikation",
                        application: "H lokal ausgeführte Schritte reduzieren die WAN-Netzlast gegenüber DDP um Faktor H×."
                    )
                    LiteratureRow(
                        citation: "Apple MLX / JACCL ('24/'25)",
                        topic: "RDMA über Thunderbolt 5 & Metal Fast Sync",
                        application: "Direktspeicher-Verbindungen und ~4 µs Synchronisations-Schranken bei Übergaben."
                    )
                    LiteratureRow(
                        citation: "TokenPowerBench ('25)",
                        topic: "Energie pro Token (J/tok), EDP & CO₂-Bilanzierung",
                        application: "Phasenbezogene Messung von J/Token, Wh/1M Token und gCO₂eq im Verbund."
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
                        Text("Verlaufsaufzeichnung: Einzel-Positionen & Global-Snapshots")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text("Zeichnet automatisch nach jeder Messreihe oder manuell für einzelne Mess-Positionen (Durchsatz, Latenz, Energie, WAN, Speicher) sowie global den Zeitverlauf auf.")
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                    Spacer()
                    Toggle("Auto-Aufzeichnung", isOn: $vm.sciAutoRecordHistory)
                        .toggleStyle(.switch)
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textPrimary)
                }

                // Position filter & recording actions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Aufzeichnungs- & Filter-Position")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(ScienceHistoryPosition.allCases) { pos in
                            let selected = vm.sciHistoryPositionFilter == pos
                            Button {
                                vm.sciHistoryPositionFilter = pos
                            } label: {
                                Text(pos.rawValue)
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
                            vm.recordScienceHistory(position: vm.sciHistoryPositionFilter, note: "Einzel-Position")
                        } label: {
                            Label("Einzel-Position aufzeichnen", systemImage: "record.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SolarisTheme.amber)
                        .foregroundColor(.black)

                        Button {
                            vm.recordScienceHistory(position: .globalAll, note: "Global-Snapshot")
                        } label: {
                            Label("Global aufzeichnen", systemImage: "globe")
                        }
                        .buttonStyle(.bordered)
                        .tint(SolarisTheme.mint)

                        if !vm.sciHistoryEntries.isEmpty {
                            Button {
                                copyToClipboard(vm.exportScienceHistoryCSV(), label: "Verlauf als CSV kopiert (\(entries.count) Einträge).")
                            } label: {
                                Label("Verlauf CSV kopieren", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                vm.clearScienceHistory()
                            } label: {
                                Label("Verlauf leeren", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }

                        Spacer()

                        Text("\(entries.count) / \(vm.sciHistoryEntries.count) Einträge")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }
            }

            // Trend Chart Card
            SolarisCard(accent: SolarisTheme.mint) {
                HStack {
                    Text("Zeitverlauf (\(vm.sciHistoryPositionFilter.rawValue))")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    HStack(spacing: 14) {
                        Label("Durchsatz (tok/s)", systemImage: "circle.fill")
                            .foregroundColor(SolarisTheme.amberGlow)
                        Label("Energie (J/tok)", systemImage: "circle.fill")
                            .foregroundColor(SolarisTheme.emerald)
                    }
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }

                if entries.isEmpty {
                    Text("Noch keine Verlaufsdaten vorhanden. Starte eine Messreihe oder klicke auf „Einzel-Position aufzeichnen“ bzw. „Global aufzeichnen“.")
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
                    Text("Protokollierte Messpunkte (\(entries.count))")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    ScrollView {
                        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                            GridRow {
                                Text("Zeit").foregroundColor(SolarisTheme.textSecondary)
                                Text("Position").foregroundColor(SolarisTheme.textSecondary)
                                Text("Bereich").foregroundColor(SolarisTheme.textSecondary)
                                Text("Modell").foregroundColor(SolarisTheme.textSecondary)
                                Text("Tok/s").foregroundColor(SolarisTheme.textSecondary)
                                Text("TTFT").foregroundColor(SolarisTheme.textSecondary)
                                Text("TPOT").foregroundColor(SolarisTheme.textSecondary)
                                Text("J/tok").foregroundColor(SolarisTheme.textSecondary)
                                Text("Engpass").foregroundColor(SolarisTheme.textSecondary)
                            }
                            .font(SolarisTheme.bodyBold)
                            Divider().gridCellUnsizedAxes(.horizontal)
                            ForEach(entries.reversed()) { entry in
                                GridRow {
                                    Text(entry.timestamp)
                                    Text(entry.positionFilter.rawValue)
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
