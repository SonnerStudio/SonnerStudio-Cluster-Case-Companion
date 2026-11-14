import SwiftUI
import AppKit

struct ScienceBenchmarksView: View {
    @ObservedObject var vm: ClusterViewModel

    private let batchOptions = [1, 2, 4, 8, 16]
    private let promptOptions = [512, 2048, 8192, 16384, 32768]
    private let bitOptions = [4, 8, 16]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // 1. Header & Core Methodology Cards
                SolarisCard(accent: SolarisTheme.amber) {
                    Text(vm.t("sci_title"))
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(vm.t("sci_sub"))
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)

                    HStack(spacing: 16) {
                        ScienceBadgeCard(
                            title: "Splitwise / DistServe (ISCA / OSDI '24)",
                            metric: "Chunked Prefill",
                            detail: "Prefill is compute-bound (TTFT); Decode is memory-bandwidth-bound (TPOT). --prefill-step-size \(vm.prefillStepSize) avoids memory spikes.",
                            accent: SolarisTheme.amber
                        )
                        ScienceBadgeCard(
                            title: "KV-Cache Quantization (SOSP '23)",
                            metric: vm.kvPrecision.maxContextEstimate,
                            detail: "With \(vm.kvPrecision.rawValue) and \(Int(vm.totalUsableVramGB)) GB usable pool, long multi-turn contexts remain within iogpu.wired_limit_mb.",
                            accent: SolarisTheme.mint
                        )
                        ScienceBadgeCard(
                            title: "SpecPipe & Metal Sync",
                            metric: vm.fastSynchEnabled ? "~4 µs Fence" : "~180 µs Fence",
                            detail: "MLX_METAL_FAST_SYNCH=\(vm.fastSynchEnabled ? "1" : "0") reduces Metal synchronization fence latency by ~45× during pipeline handoffs.",
                            accent: SolarisTheme.emerald
                        )
                    }
                }

                // 2. Interactive Workload & Log-Log Roofline Plot
                SolarisCard(accent: SolarisTheme.mint) {
                    HStack {
                        Text(vm.t("sci_workload_title"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        Text("P(I) = min(β · I, π)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(SolarisTheme.amberGlow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(SolarisTheme.cardElevated)
                            .cornerRadius(6)
                    }

                    // Workload Pickers
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Batch Size (B)")
                                .font(Font.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            Picker("Batch", selection: $vm.sciBatchSize) {
                                ForEach(batchOptions, id: \.self) { b in
                                    Text("B = \(b)").tag(b)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Prompt Length (S_prompt)")
                                .font(Font.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            Picker("Prompt", selection: $vm.sciPromptTokens) {
                                ForEach(promptOptions, id: \.self) { p in
                                    Text(p >= 1024 ? "\(p / 1024)k" : "\(p)").tag(p)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Weight Precision")
                                .font(Font.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            Picker("Bits", selection: $vm.sciWeightBits) {
                                ForEach(bitOptions, id: \.self) { bits in
                                    Text(bits == 16 ? "FP16" : "\(bits)-bit").tag(bits)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // Log-Log Roofline Canvas
                    RooflineCanvasView(
                        nodes: vm.nodes,
                        decodeIntensity: vm.decodeArithmeticIntensity,
                        prefillIntensity: vm.prefillArithmeticIntensity
                    )
                    .frame(height: 250)
                    .padding(.top, 6)

                    // Legend & Intensity Readout
                    HStack(spacing: 24) {
                        Label(
                            String(format: "Decode I = %.2f FLOP/Byte (Memory-Bound)", vm.decodeArithmeticIntensity),
                            systemImage: "circle.fill"
                        )
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(SolarisTheme.mint)

                        Label(
                            String(format: "Prefill I = %.0f FLOP/Byte (Compute-Bound)", vm.prefillArithmeticIntensity),
                            systemImage: "diamond.fill"
                        )
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(SolarisTheme.amberGlow)

                        Spacer()

                        Text(String(format: "Cluster Peak: %.1f TFLOPS (FP16) · Eff. BW: %.0f GB/s", vm.clusterPeakFP16TFLOPS, vm.effectiveDecodeBandwidthGBs))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }

                // 3. Phase Latency, GPipe Pipeline Efficiency & Energetics
                SolarisCard {
                    Text(vm.t("sci_metrics_title"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    HStack(spacing: 14) {
                        ScienceMetricTile(
                            label: "TTFT (Prefill)",
                            value: vm.estimatedTTFTMs >= 1000
                                ? String(format: "%.2f s", vm.estimatedTTFTMs / 1000.0)
                                : String(format: "%.0f ms", vm.estimatedTTFTMs),
                            sub: "\(vm.sciPromptTokens) tok · ~62% MFU",
                            accent: SolarisTheme.amberGlow
                        )
                        ScienceMetricTile(
                            label: "TPOT (Decode)",
                            value: String(format: "%.1f ms/tok", vm.estimatedTPOTMs),
                            sub: String(format: "%.1f tok/s total (B=%d)", vm.estimatedTokPerSec, vm.sciBatchSize),
                            accent: SolarisTheme.mint
                        )
                        ScienceMetricTile(
                            label: "GPipe Bubble (N-1)/(B+N-1)",
                            value: String(format: "%.1f %%", vm.pipelineBubbleFraction * 100.0),
                            sub: String(format: "Link + Sync: %.3f ms/step", vm.estimatedInterconnectOverheadMs),
                            accent: SolarisTheme.coral
                        )
                        ScienceMetricTile(
                            label: "Energetics (TokenPowerBench)",
                            value: String(format: "%.2f J/tok", vm.estimatedJoulesPerToken),
                            sub: String(format: "%.0f W · %.1f Wh / 1M tok", vm.estimatedClusterWatts, (vm.estimatedJoulesPerToken * 1_000_000.0) / 3600.0),
                            accent: SolarisTheme.emerald
                        )
                    }
                }

                // 4. Dynamic Active-Cluster Node Comparison Table
                SolarisCard {
                    Text(vm.t("sci_roofline"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    let split = vm.shardingSplit
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
                        GridRow {
                            Text("Node / Chip").foregroundColor(SolarisTheme.textSecondary)
                            Text("Bandwidth").foregroundColor(SolarisTheme.textSecondary)
                            Text("Peak FP16").foregroundColor(SolarisTheme.textSecondary)
                            Text("Ridge Point").foregroundColor(SolarisTheme.textSecondary)
                            Text("Layer Share").foregroundColor(SolarisTheme.textSecondary)
                            Text("Interconnect").foregroundColor(SolarisTheme.textSecondary)
                            Text("Power").foregroundColor(SolarisTheme.textSecondary)
                        }
                        .font(SolarisTheme.bodyBold)

                        Divider().gridCellUnsizedAxes(.horizontal)

                        ForEach(Array(vm.nodes.enumerated()), id: \.element.id) { idx, node in
                            let share = idx < split.nodeAllocations.count ? split.nodeAllocations[idx].percent : 100.0
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
                                Text("TB\(node.thunderboltGen)\(node.rdmaEnabled ? " RDMA" : "")")
                                Text("\(Int(node.typicalWatts)) W")
                            }
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(SolarisTheme.textPrimary)
                        }
                    }
                }

                // 5. Reproducible Benchmark Runner & Statistical Evaluation
                SolarisCard(accent: SolarisTheme.emerald) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("sci_bench_title"))
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Fingerprint: \(vm.hardwareFingerprint)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
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

                    if !vm.sciStatusMessage.isEmpty {
                        Text(vm.sciStatusMessage)
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.emerald)
                    }

                    if let summary = vm.sciSummary {
                        HStack(spacing: 14) {
                            ScienceMetricTile(
                                label: "TTFT (p50 / p95 / p99)",
                                value: String(format: "%.1f ms", summary.ttftP50Ms),
                                sub: String(format: "p95: %.1f · p99: %.1f · σ=%.2f", summary.ttftP95Ms, summary.ttftP99Ms, summary.ttftStdDevMs),
                                accent: SolarisTheme.amberGlow
                            )
                            ScienceMetricTile(
                                label: "TPOT (p50 / p95 / p99)",
                                value: String(format: "%.2f ms", summary.tpotP50Ms),
                                sub: String(format: "p95: %.2f · p99: %.2f · σ=%.2f", summary.tpotP95Ms, summary.tpotP99Ms, summary.tpotStdDevMs),
                                accent: SolarisTheme.mint
                            )
                            ScienceMetricTile(
                                label: "Throughput & Energy",
                                value: String(format: "%.1f tok/s", summary.meanTokensPerSec),
                                sub: String(format: "%.2f J/tok · %.1f Wh/1M tok", summary.joulesPerToken, summary.whPerMillionTokens),
                                accent: SolarisTheme.emerald
                            )
                        }

                        // Export Buttons
                        HStack(spacing: 12) {
                            Button("Copy CSV") {
                                copyToClipboard(vm.exportScientificCSV(), label: "CSV copied to clipboard.")
                            }
                            .buttonStyle(.bordered)
                            Button("Copy JSON Manifest") {
                                copyToClipboard(vm.exportScientificJSON(), label: "JSON Reproducibility Manifest copied.")
                            }
                            .buttonStyle(.bordered)
                            Button("Copy BibTeX") {
                                copyToClipboard(vm.exportBibTeX(), label: "BibTeX citations copied.")
                            }
                            .buttonStyle(.bordered)

                            if !vm.sciExportFeedback.isEmpty {
                                Text(vm.sciExportFeedback)
                                    .font(Font.caption)
                                    .foregroundColor(SolarisTheme.amberGlow)
                            }
                        }
                    } else {
                        HStack(spacing: 12) {
                            Button("Copy JSON Manifest") {
                                copyToClipboard(vm.exportScientificJSON(), label: "Analytical JSON Manifest copied.")
                            }
                            .buttonStyle(.bordered)
                            Button("Copy BibTeX") {
                                copyToClipboard(vm.exportBibTeX(), label: "BibTeX citations copied.")
                            }
                            .buttonStyle(.bordered)
                            if !vm.sciExportFeedback.isEmpty {
                                Text(vm.sciExportFeedback)
                                    .font(Font.caption)
                                    .foregroundColor(SolarisTheme.amberGlow)
                            }
                        }
                    }
                }

                // 6. Peer-Reviewed Literature & References
                SolarisCard {
                    Text(vm.t("sci_papers_title"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        LiteratureRow(
                            citation: "Williams, Waterman & Patterson (CACM '09)",
                            topic: "Roofline Model: P = min(β · I, π) & Ridge Point",
                            application: "Quantifies why Apple Silicon UMA bandwidth governs decode (I≈1–4 FLOP/B) while Metal TFLOPS govern prefill."
                        )
                        LiteratureRow(
                            citation: "Patel et al. — Splitwise (ISCA '24) / Zhong et al. — DistServe (OSDI '24)",
                            topic: "Prefill / Decode Phase Disaggregation",
                            application: "Separates compute-heavy prompt ingestion from latency-sensitive token generation across heterogeneous nodes."
                        )
                        LiteratureRow(
                            citation: "Kwon et al. — PagedAttention (ACM SOSP '23)",
                            topic: "KV-Cache Memory Management & Quantization",
                            application: "Eliminates external fragmentation and scales max context length via 4-bit/8-bit KV quantization in oMLX."
                        )
                        LiteratureRow(
                            citation: "Apple MLX / JACCL & TokenPowerBench ('24/'25)",
                            topic: "RDMA over Thunderbolt 5 & Energy per Token (J/tok)",
                            application: "Kernel-bypass tensor collectives over TB5 and phase-aligned Joules/token evaluation across p50/p95/p99."
                        )
                    }
                }
            }
            .padding(24)
        }
    }

    private func copyToClipboard(_ text: String, label: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        vm.sciExportFeedback = label
    }
}

private struct RooflineCanvasView: View {
    let nodes: [ClusterNodeModel]
    let decodeIntensity: Double
    let prefillIntensity: Double

    private let minI: Double = 0.5
    private let maxI: Double = 2048.0
    private let minP: Double = 0.1
    private let maxP: Double = 200.0

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

                // Grid lines
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

                let gridTFLOPS: [Double] = [0.2, 1, 5, 20, 100]
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

                // Axes
                var axes = Path()
                axes.move(to: CGPoint(x: padL, y: padT))
                axes.addLine(to: CGPoint(x: padL, y: padT + plotH))
                axes.addLine(to: CGPoint(x: padL + plotW, y: padT + plotH))
                context.stroke(axes, with: .color(.white.opacity(0.28)), lineWidth: 1.2)

                let colors: [Color] = [SolarisTheme.amberGlow, SolarisTheme.mint, SolarisTheme.emerald, SolarisTheme.coral]

                // Node Roofline curves
                for (idx, node) in nodes.enumerated() {
                    let col = colors[idx % colors.count]
                    let ridge = node.ridgePointFLOPPerByte
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
                    context.stroke(curve, with: .color(col), lineWidth: 2.2)

                    // Ridge marker
                    let dot = Path(ellipseIn: CGRect(x: xRidge - 4, y: yPeak - 4, width: 8, height: 8))
                    context.fill(dot, with: .color(col))

                    let tag = Text(node.chip.replacingOccurrences(of: "Apple ", with: ""))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(col)
                    context.draw(tag, at: CGPoint(x: min(xEnd - 28, xRidge + 28), y: max(padT + 8, yPeak - 10)))
                }

                // Vertical operating lines for Decode & Prefill
                let xDec = padL + xPos(decodeIntensity, width: plotW)
                var decLine = Path()
                decLine.move(to: CGPoint(x: xDec, y: padT))
                decLine.addLine(to: CGPoint(x: xDec, y: padT + plotH))
                context.stroke(decLine, with: .color(SolarisTheme.mint.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                let xPre = padL + xPos(prefillIntensity, width: plotW)
                var preLine = Path()
                preLine.move(to: CGPoint(x: xPre, y: padT))
                preLine.addLine(to: CGPoint(x: xPre, y: padT + plotH))
                context.stroke(preLine, with: .color(SolarisTheme.amberGlow.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
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

private struct ScienceBadgeCard: View {
    let title: String
    let metric: String
    let detail: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(SolarisTheme.bodyBold)
                .foregroundColor(accent)
            Text(metric)
                .font(SolarisTheme.metricMedium)
                .foregroundColor(SolarisTheme.textPrimary)
            Text(detail)
                .font(SolarisTheme.bodyLarge)
                .foregroundColor(SolarisTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SolarisTheme.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.35), lineWidth: 1)
                )
        )
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
