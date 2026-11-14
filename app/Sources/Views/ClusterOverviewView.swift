import SwiftUI

struct ClusterOverviewView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Top KPI-Leiste (Große Kennzahlen)
                HStack(spacing: 16) {
                    MetricTile(
                        title: "Gekoppelter Speicher",
                        value: "\(Int(vm.totalPhysicalRamGB)) GB",
                        subtitle: "\(Int(vm.totalUsableVramGB)) GB nutzbares MLX-Limit",
                        accent: SolarisTheme.amber,
                        icon: "memorychip.fill"
                    )
                    MetricTile(
                        title: "Aktive Nodes",
                        value: "\(vm.nodes.count)",
                        subtitle: vm.simulateMacStudio ? "Studio (Sim) + Mac mini M4" : "Nur lokaler Mac mini M4",
                        accent: SolarisTheme.mint,
                        icon: "desktopcomputer"
                    )
                    MetricTile(
                        title: "Data-Plane-Link",
                        value: vm.transportMode == .lanWlanOnly ? "1–10 Gbps" : "30–37 Gbps",
                        subtitle: vm.activeLinkHeadline,
                        accent: SolarisTheme.emerald,
                        icon: "bolt.fill"
                    )
                }

                // Interaktive Topologie-Ansicht
                SolarisCard(accent: SolarisTheme.amber) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cluster-Topologie & Speicher-Pool")
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Control Plane über LAN/WLAN · Aktivierungs-Tensoren isoliert über Thunderbolt")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Label(
                            vm.simulateMacStudio ? "52 GB Verbund aktiv" : "16 GB Einzelbetrieb",
                            systemImage: vm.simulateMacStudio ? "link.circle.fill" : "circle.dashed"
                        )
                        .font(SolarisTheme.bodyBold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(SolarisTheme.amber.opacity(0.18)))
                        .foregroundColor(SolarisTheme.amberGlow)
                    }

                    HStack(spacing: 20) {
                        ForEach(Array(vm.nodes.enumerated()), id: \.element.id) { index, node in
                            NodeCardView(node: node)

                            if index < vm.nodes.count - 1 {
                                LinkBridgeConnector(mode: vm.transportMode)
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                // 52-GB Unified Memory Pool Balken
                SolarisCard {
                    HStack {
                        Text("52-GB-Speicherpool-Aufteilung (iogpu.wired_limit_mb)")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        Text("\(Int(vm.totalUsableVramGB)) GB für KI · \(Int(vm.totalPhysicalRamGB - vm.totalUsableVramGB)) GB macOS-Reserve")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }

                    GeometryReader { geo in
                        let total = max(vm.totalPhysicalRamGB, 1)
                        HStack(spacing: 4) {
                            if vm.simulateMacStudio {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(SolarisTheme.amber)
                                    .frame(width: geo.size.width * (30.0 / total))
                                    .overlay(
                                        Text("Studio: 30 GB (58%)")
                                            .font(SolarisTheme.bodyBold)
                                            .foregroundColor(.black)
                                    )
                            }
                            RoundedRectangle(cornerRadius: 8)
                                .fill(SolarisTheme.mint)
                                .frame(width: geo.size.width * (12.0 / total))
                                .overlay(
                                    Text("Mini: 12 GB")
                                        .font(SolarisTheme.bodyBold)
                                        .foregroundColor(.black)
                                )
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    Text("OS")
                                        .font(SolarisTheme.bodyBold)
                                        .foregroundColor(SolarisTheme.textSecondary)
                                )
                        }
                    }
                    .frame(height: 40)

                    Text("Hinweis: Niemals 100 % des RAM zuweisen — 6 GB (Studio) bzw. 4 GB (Mini) bleiben fest für macOS & WindowServer reserviert.")
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
            }
            .padding(24)
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let accent: Color
    let icon: String

    var body: some View {
        SolarisCard(accent: accent) {
            HStack {
                Text(title)
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accent)
            }
            Text(value)
                .font(SolarisTheme.metricHuge)
                .foregroundColor(SolarisTheme.textPrimary)
            Text(subtitle)
                .font(SolarisTheme.bodyLarge)
                .foregroundColor(SolarisTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct NodeCardView: View {
    let node: ClusterNodeModel

    var accent: Color {
        node.totalRamGB >= 32 ? SolarisTheme.amber : SolarisTheme.mint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: node.totalRamGB >= 32 ? "macstudio.fill" : "macmini.fill")
                    .font(.system(size: 26))
                    .foregroundColor(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name)
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(node.role)
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(accent)
                }
                Spacer()
                if node.isSimulated {
                    Text("SIMULIERT")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(SolarisTheme.amber.opacity(0.22)))
                        .foregroundColor(SolarisTheme.amberGlow)
                }
            }

            Divider().background(SolarisTheme.borderSubtle)

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                GridRow {
                    Text("Chip:").foregroundColor(SolarisTheme.textSecondary)
                    Text(node.chip).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Speicher:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(Int(node.totalRamGB)) GB RAM (\(Int(node.usableVramGB)) GB MLX)").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Bandbreite:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(Int(node.bandwidthGBs)) GB/s · TB\(node.thunderboltGen)").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("TB-IP / LAN:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.tbIP) · \(node.lanIP)").font(SolarisTheme.monoCode).foregroundColor(SolarisTheme.textPrimary)
                }
            }
            .font(SolarisTheme.bodyLarge)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SolarisTheme.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

private struct LinkBridgeConnector: View {
    let mode: TransportMode

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let phase = CGFloat(context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6)
            VStack(spacing: 8) {
                Text(mode == .rdmaExperimental ? "RDMA" : "TB4/5")
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.amberGlow)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(SolarisTheme.amber.opacity(0.25))
                        .frame(width: 96, height: 8)
                    Circle()
                        .fill(SolarisTheme.amberGlow)
                        .frame(width: 12, height: 12)
                        .offset(x: phase * 84)
                }

                Text(mode == .lanWlanOnly ? "LAN/Wi-Fi" : "30–37 Gbps")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(SolarisTheme.textSecondary)
            }
            .frame(width: 105)
        }
    }
}
