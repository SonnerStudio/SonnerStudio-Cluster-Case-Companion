import SwiftUI

struct ScienceBenchmarksView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SolarisCard(accent: SolarisTheme.amber) {
                    Text("Wissenschaftliche Grundlagen & Roofline-Analyse")
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("Erkenntnisse aus aktueller IT-Systemforschung (OSDI '24, arXiv, Apple MLX) direkt auf deinen 36-GB-M5-Max + 16-GB-M4-Cluster übertragen.")
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)

                    HStack(spacing: 16) {
                        ScienceBadgeCard(
                            title: "Splitwise / DistServe (OSDI '24)",
                            metric: "Chunked Prefill",
                            detail: "Prefill ist rechenlimitiert (TTFT), Decode speicherbandbreiten-limitiert (TPOT). --prefill-step-size \(vm.prefillStepSize) verhindert Speicherspitzen.",
                            accent: SolarisTheme.amber
                        )
                        ScienceBadgeCard(
                            title: "KV-Cache-Quantisierung",
                            metric: vm.kvPrecision.maxContextEstimate,
                            detail: "Mit --kv-bits 4 und --quantized-kv-start 5000 passen lange OpenCode-/Hermes-Kontexte sicher in den 42-GB-Pool.",
                            accent: SolarisTheme.mint
                        )
                        ScienceBadgeCard(
                            title: "SpecPipe & Metal Sync",
                            metric: vm.fastSynchEnabled ? "~4 µs Fence" : "~180 µs Fence",
                            detail: "Auf Apple Silicon bremst naives Speculative Decoding oft durch Metal-Sync-Overhead. MLX_METAL_FAST_SYNCH=1 senkt Latenzen um Faktor 45×.",
                            accent: SolarisTheme.emerald
                        )
                    }
                }

                // Roofline Vergleich: M5 Max vs M4
                SolarisCard {
                    Text("Hardware-Roofline: Warum Rank 0 auf den Mac Studio M5 Max gehört")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                        GridRow {
                            Text("Eigenschaft").foregroundColor(SolarisTheme.textSecondary)
                            Text("Mac Studio M5 Max (36 GB)").foregroundColor(SolarisTheme.amberGlow)
                            Text("Mac mini M4 (16 GB)").foregroundColor(SolarisTheme.mint)
                        }
                        .font(SolarisTheme.bodyBold)

                        Divider().gridCellUnsizedAxes(.horizontal)

                        GridRow {
                            Text("Speicherbandbreite (Decode-Limit)").foregroundColor(SolarisTheme.textSecondary)
                            Text("460 GB/s (3,8× schneller)").foregroundColor(SolarisTheme.textPrimary)
                            Text("120 GB/s").foregroundColor(SolarisTheme.textPrimary)
                        }
                        GridRow {
                            Text("Optimaler Layer-Anteil").foregroundColor(SolarisTheme.textSecondary)
                            Text("~71 % + Embeddings + LM-Head").foregroundColor(SolarisTheme.textPrimary)
                            Text("~29 % (Worker Rank 1)").foregroundColor(SolarisTheme.textPrimary)
                        }
                        GridRow {
                            Text("Data-Plane-Durchsatz (TB4/5 Bridge)").foregroundColor(SolarisTheme.textSecondary)
                            Text("30–37 Gbps (real iperf3)").foregroundColor(SolarisTheme.textPrimary)
                            Text("40 Gbps Link-Cap (TB4)").foregroundColor(SolarisTheme.textPrimary)
                        }
                    }
                    .font(SolarisTheme.bodyLarge)
                }
            }
            .padding(24)
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
