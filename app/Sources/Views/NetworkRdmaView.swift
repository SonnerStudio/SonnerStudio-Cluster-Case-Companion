import SwiftUI

struct NetworkRdmaView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SolarisCard(accent: SolarisTheme.amber) {
                    Text("Transport-Verfahren (Hybrid LAN/WLAN + Thunderbolt)")
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("Wähle, wie Aktivierungs-Tensoren zwischen Mac Studio M5 Max (TB5) und Mac mini M4 (TB4) übertragen werden.")
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

                // MLX Performance & RDMA Hinweise
                SolarisCard {
                    Toggle(isOn: $vm.fastSynchEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MLX_METAL_FAST_SYNCH=1 aktivieren")
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Senkt den GPU/CPU-Synchronisations-Overhead von ~180 µs auf ~4 µs (45× schneller bei Pipeline-Übergängen).")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(SolarisTheme.amber)

                    Divider().background(SolarisTheme.borderSubtle)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Checkliste sobald der Mac Studio M5 Max eintrifft:")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text("1. Thunderbolt-Kabel verbinden & `scripts/setup_tb_network.sh studio` bzw. `mini` ausführen.")
                        Text("2. Mit `iperf3 -c 10.99.1.1` Durchsatz prüfen (Ziel: 30–37 Gbps).")
                        Text("3. Simulation oben rechts ausschalten — Bonjour erkennt den Mac Studio automatisch.")
                    }
                    .font(SolarisTheme.bodyLarge)
                    .foregroundColor(SolarisTheme.textSecondary)
                }
            }
            .padding(24)
        }
    }
}
