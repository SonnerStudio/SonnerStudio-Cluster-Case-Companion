import SwiftUI

struct NetworkRdmaView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SolarisCard(accent: SolarisTheme.amber) {
                    Text(vm.t("net_title"))
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(vm.t("net_sub"))
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)

                    VStack(spacing: 12) {
                        ForEach(TransportMode.allCases) { mode in
                            let selected = vm.transportMode == mode
                            Button {
                                vm.transportMode = mode
                            } label: {
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(selected ? SolarisTheme.amber : SolarisTheme.textSecondary)
                                        .padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mode.rawValue)
                                            .font(SolarisTheme.cardTitle)
                                            .foregroundColor(SolarisTheme.textPrimary)
                                        Text(mode.description)
                                            .font(SolarisTheme.bodyLarge)
                                            .foregroundColor(SolarisTheme.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selected ? SolarisTheme.amber.opacity(0.14) : SolarisTheme.cardElevated)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(selected ? SolarisTheme.amber : SolarisTheme.borderSubtle, lineWidth: 1.2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Thunderbolt-Klassen der Generationen M1–M9+
                SolarisCard(accent: SolarisTheme.mint) {
                    HStack {
                        Text("Thunderbolt-Klassen (M1–M9+) & Übertragungsraten")
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        Text("\(vm.effectiveLinkStats.badge) · \(vm.effectiveLinkStats.rangeLabel)")
                            .font(SolarisTheme.bodyBold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(SolarisTheme.amber.opacity(0.20)))
                            .foregroundColor(SolarisTheme.amberGlow)
                    }

                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                        GridRow {
                            Text("Klasse").foregroundColor(SolarisTheme.textSecondary)
                            Text("Mac-Generationen").foregroundColor(SolarisTheme.textSecondary)
                            Text("Nenn- / Nutzrate").foregroundColor(SolarisTheme.textSecondary)
                            Text("RDMA / JACCL").foregroundColor(SolarisTheme.textSecondary)
                        }
                        .font(SolarisTheme.bodyBold)

                        Divider().gridCellUnsizedAxes(.horizontal)

                        GridRow {
                            Text("Thunderbolt 3 / USB4").foregroundColor(SolarisTheme.mint)
                            Text("M1 & M2 (Basis)").foregroundColor(SolarisTheme.textPrimary)
                            Text("40 Gbps (26–32 Gbps real)").foregroundColor(SolarisTheme.textPrimary)
                            Text("Opt-In (IP/Bridge)").foregroundColor(SolarisTheme.textSecondary)
                        }
                        GridRow {
                            Text("Thunderbolt 4").foregroundColor(SolarisTheme.amberGlow)
                            Text("M1–M3 Pro/Max/Ultra, M4 (Basis)").foregroundColor(SolarisTheme.textPrimary)
                            Text("40 Gbps (30–37 Gbps real)").foregroundColor(SolarisTheme.textPrimary)
                            Text("Opt-In (34–38 Gbps)").foregroundColor(SolarisTheme.textSecondary)
                        }
                        GridRow {
                            Text("Thunderbolt 5").foregroundColor(SolarisTheme.emerald)
                            Text("M3 Ultra, M4 Pro/Max, M5–M9+").foregroundColor(SolarisTheme.textPrimary)
                            Text("80–120 Gbps (65–80 Gbps real)").foregroundColor(SolarisTheme.textPrimary)
                            Text("Nativ (75–110 Gbps)").foregroundColor(SolarisTheme.emerald)
                        }
                    }
                    .font(SolarisTheme.bodyLarge)
                }

                // MLX Performance & RDMA Hinweise
                SolarisCard {
                    Toggle(isOn: $vm.fastSynchEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("net_fast_synch"))
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.t("net_fast_synch_sub"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(SolarisTheme.amber)

                    Divider().background(SolarisTheme.borderSubtle)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(vm.t("net_checklist"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text("1. Thunderbolt-Kabel zwischen den Macs verbinden & `scripts/setup_tb_network.sh` auf den Knoten ausführen.")
                        Text("2. Mit `iperf3 -c 10.99.1.1` Durchsatz prüfen (TB3/4: ~26–37 Gbps, TB5: ~65–80+ Gbps).")
                        Text("3. Nachbildung unten links bei Bedarf abschalten — Bonjour erkennt verbundene Macs selbsttätig.")
                    }
                    .font(SolarisTheme.bodyLarge)
                    .foregroundColor(SolarisTheme.textSecondary)
                }
            }
            .padding(24)
        }
    }
}
