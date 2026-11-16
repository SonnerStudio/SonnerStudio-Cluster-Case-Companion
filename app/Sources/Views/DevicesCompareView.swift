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
                        DeviceDetailCard(node: node, lang: vm.language)
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
                            label: L10n.tr(vm.language, de: "Physischer RAM", en: "Physical RAM", fr: "RAM physique", es: "RAM física", pt: "RAM física", ru: "Физическая ОЗУ", ja: "物理 RAM", zh: "物理内存"),
                            leftLabel: "\(Int(primary.totalRamGB)) GB",
                            rightLabel: "\(Int(secondary.totalRamGB)) GB",
                            leftValue: primary.totalRamGB,
                            rightValue: secondary.totalRamGB
                        )
                        ComparisonBarRow(
                            label: L10n.tr(vm.language, de: "Nutzbares MLX-Limit", en: "Usable MLX Limit", fr: "Limite MLX utilisable", es: "Límite MLX utilizable", pt: "Limite MLX utilizável", ru: "Доступный лимит MLX", ja: "利用可能 MLX 上限", zh: "可用 MLX 上限"),
                            leftLabel: "\(Int(primary.usableVramGB)) GB",
                            rightLabel: "\(Int(secondary.usableVramGB)) GB",
                            leftValue: primary.usableVramGB,
                            rightValue: secondary.usableVramGB
                        )
                        ComparisonBarRow(
                            label: L10n.tr(vm.language, de: "Speicherbandbreite", en: "Memory Bandwidth", fr: "Bande passante mémoire", es: "Ancho de banda", pt: "Largura de banda", ru: "Пропускная способность", ja: "メモリ帯域幅", zh: "内存带宽"),
                            leftLabel: "\(Int(primary.bandwidthGBs)) GB/s",
                            rightLabel: "\(Int(secondary.bandwidthGBs)) GB/s",
                            leftValue: primary.bandwidthGBs,
                            rightValue: secondary.bandwidthGBs
                        )
                        ComparisonBarRow(
                            label: L10n.tr(vm.language, de: "GPU-Kerne", en: "GPU Cores", fr: "Cœurs GPU", es: "Núcleos GPU", pt: "Núcleos GPU", ru: "Ядра GPU", ja: "GPU コア", zh: "GPU 核心"),
                            leftLabel: "\(primary.gpuCores) \(L10n.text("node_gpu_cores", vm.language))",
                            rightLabel: "\(secondary.gpuCores) \(L10n.text("node_gpu_cores", vm.language))",
                            leftValue: Double(primary.gpuCores),
                            rightValue: Double(secondary.gpuCores)
                        )
                        ComparisonBarRow(
                            label: L10n.tr(vm.language, de: "Neural Engine", en: "Neural Engine", fr: "Neural Engine", es: "Neural Engine", pt: "Neural Engine", ru: "Neural Engine", ja: "Neural Engine", zh: "神经网络引擎"),
                            leftLabel: "\(primary.neuralEngineCores) \(L10n.text("node_ane_cores", vm.language))",
                            rightLabel: "\(secondary.neuralEngineCores) \(L10n.text("node_ane_cores", vm.language))",
                            leftValue: Double(primary.neuralEngineCores),
                            rightValue: Double(secondary.neuralEngineCores)
                        )
                        ComparisonBarRow(
                            label: L10n.tr(vm.language, de: "SSD-Kapazität", en: "SSD Capacity", fr: "Capacité SSD", es: "Capacidad SSD", pt: "Capacidade SSD", ru: "Ёмкость SSD", ja: "SSD 容量", zh: "SSD 容量"),
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
    let lang: AppLanguage

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
                    Text(node.localizedRole(lang))
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(accent)
                }
                Spacer()
                Text(node.isSimulated
                    ? L10n.tr(lang, de: "SIMULIERT", en: "SIMULATED", fr: "SIMULÉ", es: "SIMULADO", pt: "SIMULADO", ru: "СИМУЛЯЦИЯ", ja: "シミュレート", zh: "模拟节点")
                    : L10n.tr(lang, de: "LOKAL LIVE", en: "LOCAL LIVE", fr: "LOCAL EN DIRECT", es: "LOCAL EN VIVO", pt: "LOCAL AO VIVO", ru: "ЛОКАЛЬНО LIVE", ja: "ローカル LIVE", zh: "本地实时"))
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill((node.isSimulated ? SolarisTheme.amber : SolarisTheme.emerald).opacity(0.22)))
                    .foregroundColor(node.isSimulated ? SolarisTheme.amberGlow : SolarisTheme.emerald)
            }

            Divider().background(SolarisTheme.borderSubtle)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 9) {
                GridRow {
                    Text(L10n.tr(lang, de: "Chip / Modell:", en: "Chip / Model:", fr: "Puce / Modèle :", es: "Chip / Modelo:", pt: "Chip / Modelo:", ru: "Чип / Модель:", ja: "チップ / モデル:", zh: "芯片 / 型号：")).foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.chip) · \(node.modelIdentifier)").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "CPU / GPU / ANE:", en: "CPU / GPU / ANE:", fr: "CPU / GPU / ANE :", es: "CPU / GPU / ANE:", pt: "CPU / GPU / ANE:", ru: "CPU / GPU / ANE:", ja: "CPU / GPU / ANE:", zh: "CPU / GPU / ANE：")).foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.cpuTopology) · \(node.gpuCores) \(L10n.text("node_gpu_cores", lang)) · \(node.neuralEngineCores) \(L10n.text("node_ane_cores", lang))").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "Betriebssystem:", en: "Operating System:", fr: "Système :", es: "Sistema operativo:", pt: "Sistema operativo:", ru: "ОС:", ja: "OS:", zh: "操作系统：")).foregroundColor(SolarisTheme.textSecondary)
                    Text(node.osVersion).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "Physischer RAM:", en: "Physical RAM:", fr: "RAM physique :", es: "RAM física:", pt: "RAM física:", ru: "Физическая ОЗУ:", ja: "物理 RAM:", zh: "物理内存：")).foregroundColor(SolarisTheme.textSecondary)
                    Text(L10n.tr(lang,
                        de: "\(Int(node.totalRamGB)) GB Unified Memory",
                        en: "\(Int(node.totalRamGB)) GB Unified Memory",
                        fr: "\(Int(node.totalRamGB)) Go Mémoire Unifiée",
                        es: "\(Int(node.totalRamGB)) GB Memoria Unificada",
                        pt: "\(Int(node.totalRamGB)) GB Memória Unificada",
                        ru: "\(Int(node.totalRamGB)) ГБ объединённой памяти",
                        ja: "\(Int(node.totalRamGB)) GB ユニファイドメモリ",
                        zh: "\(Int(node.totalRamGB)) GB 统一内存")).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "Sicheres MLX-Limit:", en: "Safe MLX Limit:", fr: "Limite MLX sûre :", es: "Límite MLX seguro:", pt: "Limite MLX seguro:", ru: "Безопасный лимит MLX:", ja: "安全 MLX 上限:", zh: "安全 MLX 上限：")).foregroundColor(SolarisTheme.textSecondary)
                    Text("\(Int(node.usableVramGB)) GB (sysctl: \(node.wiredLimitMB == 0 ? L10n.tr(lang, de: "Auto", en: "Auto", fr: "Auto", es: "Auto", pt: "Auto", ru: "Авто", ja: "自動", zh: "自动") : "\(node.wiredLimitMB) MB"))").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "Speicherbandbreite:", en: "Memory Bandwidth:", fr: "Bande passante :", es: "Ancho de banda:", pt: "Largura de banda:", ru: "Пропускная способность:", ja: "メモリ帯域幅:", zh: "内存带宽：")).foregroundColor(SolarisTheme.textSecondary)
                    Text("\(Int(node.bandwidthGBs)) GB/s").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "Thunderbolt & RDMA:", en: "Thunderbolt & RDMA:", fr: "Thunderbolt & RDMA :", es: "Thunderbolt y RDMA:", pt: "Thunderbolt e RDMA:", ru: "Thunderbolt и RDMA:", ja: "Thunderbolt & RDMA:", zh: "Thunderbolt 与 RDMA：")).foregroundColor(SolarisTheme.textSecondary)
                    Text("TB\(node.thunderboltGen) · RDMA \(node.rdmaEnabled ? L10n.tr(lang, de: "Aktiv", en: "Active", fr: "Actif", es: "Activo", pt: "Ativo", ru: "Активно", ja: "有効", zh: "已启用") : L10n.tr(lang, de: "Deaktiviert", en: "Disabled", fr: "Désactivé", es: "Desactivado", pt: "Desativado", ru: "Отключено", ja: "無効", zh: "已禁用"))").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "TB-IP / LAN-IP:", en: "TB IP / LAN IP:", fr: "IP TB / IP LAN :", es: "IP TB / IP LAN:", pt: "IP TB / IP LAN:", ru: "TB IP / LAN IP:", ja: "TB IP / LAN IP:", zh: "TB IP / 局域网 IP：")).foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.tbIP)  |  \(node.lanIP)").font(SolarisTheme.monoCode).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "SSD-Speicher:", en: "SSD Storage:", fr: "Stockage SSD :", es: "Almacenamiento SSD:", pt: "Armazenamento SSD:", ru: "Хранилище SSD:", ja: "SSD ストレージ:", zh: "SSD 存储：")).foregroundColor(SolarisTheme.textSecondary)
                    Text(L10n.tr(lang,
                        de: "\(node.ssdTotalGB) GB NVMe (\(node.ssdFreeGB) GB frei)",
                        en: "\(node.ssdTotalGB) GB NVMe (\(node.ssdFreeGB) GB free)",
                        fr: "\(node.ssdTotalGB) Go NVMe (\(node.ssdFreeGB) Go libres)",
                        es: "\(node.ssdTotalGB) GB NVMe (\(node.ssdFreeGB) GB libres)",
                        pt: "\(node.ssdTotalGB) GB NVMe (\(node.ssdFreeGB) GB livres)",
                        ru: "\(node.ssdTotalGB) ГБ NVMe (\(node.ssdFreeGB) ГБ своб.)",
                        ja: "\(node.ssdTotalGB) GB NVMe (空き \(node.ssdFreeGB) GB)",
                        zh: "\(node.ssdTotalGB) GB NVMe (可用 \(node.ssdFreeGB) GB)")).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "Temperatur / Thermik:", en: "Thermal State:", fr: "Température / Thermique :", es: "Estado térmico:", pt: "Temperatura / Térmica:", ru: "Температура / Термика:", ja: "温度 / サーマル状態:", zh: "温度 / 散热状态：")).foregroundColor(SolarisTheme.textSecondary)
                    Text(node.localizedThermal(lang)).foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.tr(lang, de: "Stromverbrauch:", en: "Power Usage:", fr: "Consommation :", es: "Consumo energético:", pt: "Consumo de energia:", ru: "Энергопотребление:", ja: "消費電力:", zh: "功耗：")).foregroundColor(SolarisTheme.textSecondary)
                    Text(node.localizedPower(lang)).foregroundColor(SolarisTheme.textPrimary)
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
