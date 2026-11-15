import SwiftUI

struct DevicesCompareView: View {
    @ObservedObject var vm: ClusterViewModel

    private let ramChoices: [Double] = [8, 16, 24, 32, 36, 48, 64, 96, 128, 192]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SolarisCard(accent: SolarisTheme.amber) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("dev_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("sysctl / sw_vers / ibv_devices / ipconfig (\(vm.lastProbeTimestamp))")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.refreshLocalHardwareProbe()
                        } label: {
                            Label(vm.t("dev_refresh"), systemImage: "arrow.clockwise")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.amber))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .solarisShorttip(vm.shorttip(.devices), id: "view_devices_header", vm: vm)

                // Beliebigen Apple Mac mit M-Prozessor (M1–M6) zum Verbund hinzufügen
                SolarisCard(accent: SolarisTheme.emerald) {
                    Text(vm.t("dev_add_title"))
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(vm.t("dev_add_sub"))
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)

                    HStack(spacing: 12) {
                        Picker("", selection: $vm.newFormFactor) {
                            ForEach(MacFormFactor.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .frame(width: 150)

                        Picker("", selection: $vm.newChip) {
                            ForEach(AppleSiliconChipFamily.allCases) { chip in
                                Text(chip.rawValue).tag(chip)
                            }
                        }
                        .frame(width: 170)

                        Picker("", selection: $vm.newRamGB) {
                            ForEach(ramChoices, id: \.self) { ram in
                                Text("\(Int(ram)) GB").tag(ram)
                            }
                        }
                        .frame(width: 110)

                        TextField(vm.t("dev_add_name_ph"), text: $vm.newCustomName)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            vm.addCustomNode(
                                formFactor: vm.newFormFactor,
                                chip: vm.newChip,
                                ramGB: vm.newRamGB,
                                customName: vm.newCustomName
                            )
                            vm.newCustomName = ""
                        } label: {
                            Label(vm.t("dev_add_btn"), systemImage: "plus.circle.fill")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.emerald))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                    }

                    if !vm.customNodes.isEmpty {
                        HStack(spacing: 10) {
                            ForEach(vm.customNodes) { custom in
                                Button {
                                    vm.removeCustomNode(id: custom.id)
                                } label: {
                                    Label("\(custom.name) (\(Int(custom.totalRamGB)) GB) ×", systemImage: "trash")
                                        .font(.system(size: 12.5, weight: .semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(SolarisTheme.coral.opacity(0.22)))
                                        .foregroundColor(SolarisTheme.coral)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Einzelkarten pro Gerät nebeneinander
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 18)], spacing: 18) {
                    ForEach(vm.nodes) { node in
                        DeviceDetailCard(node: node)
                    }
                }

                // Direkter Side-by-Side Vergleich (wenn 2+ Geräte aktiv)
                if vm.nodes.count >= 2 {
                    let primary = vm.nodes[0]
                    let secondary = vm.nodes[1]

                    SolarisCard(accent: SolarisTheme.mint) {
                        Text("\(vm.t("dev_compare")): \(primary.name) vs. \(secondary.name)")
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)

                        ComparisonBarRow(
                            label: "Physischer RAM",
                            leftLabel: "\(Int(primary.totalRamGB)) GB",
                            rightLabel: "\(Int(secondary.totalRamGB)) GB",
                            leftValue: primary.totalRamGB,
                            rightValue: secondary.totalRamGB
                        )
                        ComparisonBarRow(
                            label: "Nutzbares MLX-Limit",
                            leftLabel: "\(Int(primary.usableVramGB)) GB",
                            rightLabel: "\(Int(secondary.usableVramGB)) GB",
                            leftValue: primary.usableVramGB,
                            rightValue: secondary.usableVramGB
                        )
                        ComparisonBarRow(
                            label: "Speicherbandbreite",
                            leftLabel: "\(Int(primary.bandwidthGBs)) GB/s",
                            rightLabel: "\(Int(secondary.bandwidthGBs)) GB/s",
                            leftValue: primary.bandwidthGBs,
                            rightValue: secondary.bandwidthGBs
                        )
                        ComparisonBarRow(
                            label: "GPU-Kerne",
                            leftLabel: "\(primary.gpuCores) Kerne",
                            rightLabel: "\(secondary.gpuCores) Kerne",
                            leftValue: Double(primary.gpuCores),
                            rightValue: Double(secondary.gpuCores)
                        )
                        ComparisonBarRow(
                            label: "Neural Engine",
                            leftLabel: "\(primary.neuralEngineCores) ANE-Kerne",
                            rightLabel: "\(secondary.neuralEngineCores) ANE-Kerne",
                            leftValue: Double(primary.neuralEngineCores),
                            rightValue: Double(secondary.neuralEngineCores)
                        )
                        ComparisonBarRow(
                            label: "SSD-Kapazität",
                            leftLabel: "\(primary.ssdTotalGB) GB",
                            rightLabel: "\(secondary.ssdTotalGB) GB",
                            leftValue: Double(primary.ssdTotalGB),
                            rightValue: Double(secondary.ssdTotalGB)
                        )
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct DeviceDetailCard: View {
    let node: ClusterNodeModel

    var accent: Color {
        node.totalRamGB >= 32 ? SolarisTheme.amber : SolarisTheme.mint
    }

    var body: some View {
        SolarisCard(accent: accent) {
            HStack {
                Image(systemName: node.totalRamGB >= 32 ? "macstudio.fill" : "macmini.fill")
                    .font(.system(size: 30))
                    .foregroundColor(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name)
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(node.role)
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(accent)
                }
                Spacer()
                Text(node.isSimulated ? "SIMULIERT" : "LOKAL LIVE")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill((node.isSimulated ? SolarisTheme.amber : SolarisTheme.emerald).opacity(0.22)))
                    .foregroundColor(node.isSimulated ? SolarisTheme.amberGlow : SolarisTheme.emerald)
            }

            Divider().background(SolarisTheme.borderSubtle)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 9) {
                GridRow {
                    Text("Chip / Modell:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.chip) · \(node.modelIdentifier)").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("CPU / GPU / ANE:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.cpuTopology) · \(node.gpuCores) GPU · \(node.neuralEngineCores) Neural Engine").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Betriebssystem:").foregroundColor(SolarisTheme.textSecondary)
                    Text(node.osVersion).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Physischer RAM:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(Int(node.totalRamGB)) GB Unified Memory").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Sicheres MLX-Limit:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(Int(node.usableVramGB)) GB (sysctl: \(node.wiredLimitMB == 0 ? "Auto" : "\(node.wiredLimitMB) MB"))").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Speicherbandbreite:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(Int(node.bandwidthGBs)) GB/s").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Thunderbolt & RDMA:").foregroundColor(SolarisTheme.textSecondary)
                    Text("TB\(node.thunderboltGen) · RDMA \(node.rdmaEnabled ? "Aktiv" : "Deaktiviert")").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("TB-IP / LAN-IP:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.tbIP)  |  \(node.lanIP)").font(SolarisTheme.monoCode).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("SSD-Speicher:").foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.ssdTotalGB) GB NVMe (\(node.ssdFreeGB) GB frei)").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Temperatur / Thermik:").foregroundColor(SolarisTheme.textSecondary)
                    Text(node.thermalLabel).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text("Stromverbrauch:").foregroundColor(SolarisTheme.textSecondary)
                    Text(node.powerLabel).foregroundColor(SolarisTheme.textPrimary)
                }
            }
            .font(SolarisTheme.bodyLarge)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ComparisonBarRow: View {
    let label: String
    let leftLabel: String
    let rightLabel: String
    let leftValue: Double
    let rightValue: Double

    var body: some View {
        let maxVal = max(leftValue, rightValue, 1.0)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                Text("\(leftLabel)  vs.  \(rightLabel)")
                    .font(SolarisTheme.monoCode)
                    .foregroundColor(SolarisTheme.textSecondary)
            }
            GeometryReader { geo in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(SolarisTheme.amber)
                        .frame(width: max(20, (geo.size.width * 0.48) * (leftValue / maxVal)), height: 14)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(SolarisTheme.mint)
                        .frame(width: max(20, (geo.size.width * 0.48) * (rightValue / maxVal)), height: 14)
                    Spacer()
                }
            }
            .frame(height: 16)
        }
        .padding(.vertical, 4)
    }
}
