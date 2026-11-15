import SwiftUI

struct ModelStudioView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        let split = vm.shardingSplit

        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SolarisCard {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("ms_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.t("ms_sub"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            Task { await vm.refreshLiveModels() }
                        } label: {
                            Label(vm.isRefreshingModels ? "..." : "Modelle neu einlesen", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SolarisTheme.amber)
                        .foregroundColor(.black)
                        .disabled(vm.isRefreshingModels)
                    }

                    if !vm.modelDiscoveryNote.isEmpty {
                        Text(vm.modelDiscoveryNote)
                            .font(.caption)
                            .foregroundColor(SolarisTheme.mint)
                    }

                    HazardStripesBar(height: 5, stripeWidth: 9, cornerRadius: 3, opacity: 0.85)

                    if vm.modelPresets.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 10) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(SolarisTheme.amberGlow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(vm.t("ms_no_models_note"))
                                        .font(SolarisTheme.cardTitle)
                                        .foregroundColor(SolarisTheme.textPrimary)
                                    Text(vm.t("ms_empty_guide"))
                                        .font(SolarisTheme.bodyLarge)
                                        .foregroundColor(SolarisTheme.textSecondary)
                                }
                            }

                            Divider().background(SolarisTheme.borderSubtle)

                            // Runtime Readiness Matrix: oMLX, Ollama, llama.cpp
                            ForEach(RuntimeService.allCases) { svc in
                                let status = vm.runtimeReadiness[svc]
                                let isRunning = status?.running ?? false
                                let isInstalled = status?.installed ?? false
                                let badgeText = isRunning ? "Bereit (Läuft)" : (isInstalled ? "Installiert (Gestoppt)" : "Nicht gefunden")
                                let badgeColor = isRunning ? SolarisTheme.emerald : (isInstalled ? SolarisTheme.amberGlow : SolarisTheme.coral)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(svc.rawValue)
                                            .font(SolarisTheme.bodyBold)
                                            .foregroundColor(SolarisTheme.textPrimary)
                                        Spacer()
                                        Text(badgeText)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(badgeColor.opacity(0.20)))
                                            .foregroundColor(badgeColor)
                                    }
                                    if let path = status?.binaryPath, !path.isEmpty {
                                        Text("Pfad: \(path)")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(SolarisTheme.textSecondary)
                                    }
                                    let cmd = isInstalled ? (status?.pullModelCommand ?? "") : (status?.installCommand ?? "")
                                    if !cmd.isEmpty {
                                        HStack {
                                            Text(cmd)
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(SolarisTheme.mint)
                                                .textSelection(.enabled)
                                            Spacer()
                                            Button("Kopieren") {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(cmd, forType: .string)
                                                vm.bridgeStatusMessage = "Befehl kopiert: \(cmd)"
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(SolarisTheme.cardElevated)
                                )
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(SolarisTheme.cardElevated.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(SolarisTheme.amber.opacity(0.35), lineWidth: 1)
                                )
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(vm.modelPresets) { preset in
                                let isSelected = preset.id == vm.selectedModel.id
                                Button {
                                    vm.selectedModel = preset
                                    vm.kvCacheReserveGB = preset.kvReserveGB
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(preset.displayName)
                                                    .font(SolarisTheme.cardTitle)
                                                    .foregroundColor(SolarisTheme.textPrimary)
                                                Text(preset.sourceLabel)
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Capsule().fill((preset.isLiveDiscovered ? SolarisTheme.emerald : SolarisTheme.amber).opacity(0.22)))
                                                    .foregroundColor(preset.isLiveDiscovered ? SolarisTheme.emerald : SolarisTheme.amberGlow)
                                            }
                                            Text("\(preset.quantization) · \(preset.totalLayers) Layer · ~\(String(format: "%.1f", preset.estimatedGB)) GB · \(preset.notes)")
                                                .font(SolarisTheme.bodyLarge)
                                                .foregroundColor(SolarisTheme.textSecondary)
                                        }
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(SolarisTheme.amber)
                                        }
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isSelected ? SolarisTheme.amber.opacity(0.14) : SolarisTheme.cardElevated)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(isSelected ? SolarisTheme.amber : SolarisTheme.borderSubtle, lineWidth: 1.2)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Sharding Plan Vorschau
                SolarisCard(accent: split.fits ? SolarisTheme.emerald : SolarisTheme.coral) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("ms_plan_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Bedarf inkl. \(String(format: "%.1f", vm.kvCacheReserveGB)) GB KV-Cache: \(String(format: "%.1f", split.totalRequiredGB)) GB von \(Int(split.totalUsableGB)) GB verfügbar")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Label(
                            split.fits ? vm.t("ms_fits") : vm.t("ms_oom"),
                            systemImage: split.fits ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(SolarisTheme.bodyBold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill((split.fits ? SolarisTheme.emerald : SolarisTheme.coral).opacity(0.20)))
                        .foregroundColor(split.fits ? SolarisTheme.emerald : SolarisTheme.coral)
                    }

                    // Visueller Layer-Split Balken für alle aktiven M-Series Nodes
                    GeometryReader { geo in
                        let palette: [Color] = [SolarisTheme.amber, SolarisTheme.mint, SolarisTheme.emerald, Color.cyan, Color.purple]
                        HStack(spacing: 4) {
                            ForEach(Array(split.nodeAllocations.enumerated()), id: \.element.id) { idx, alloc in
                                if alloc.layers > 0 {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(palette[idx % palette.count])
                                        .frame(width: max(50, geo.size.width * (alloc.percent / 100.0) - 4))
                                        .overlay(
                                            Text("\(alloc.nodeName): \(alloc.layers)L (\(String(format: "%.0f", alloc.percent))%)")
                                                .font(SolarisTheme.bodyBold)
                                                .foregroundColor(.black)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                                .padding(.horizontal, 4)
                                        )
                                }
                            }
                        }
                    }
                    .frame(height: 44)

                    HStack {
                        Text(vm.t("ms_kv_reserve"))
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Slider(value: $vm.kvCacheReserveGB, in: 1...12, step: 0.5)
                            .tint(SolarisTheme.amber)
                        Text("\(String(format: "%.1f", vm.kvCacheReserveGB)) GB")
                            .font(SolarisTheme.metricMedium)
                            .foregroundColor(SolarisTheme.amberGlow)
                            .frame(width: 85, alignment: .trailing)
                    }

                    Divider().background(SolarisTheme.borderSubtle)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("ms_kv_quant"))
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Empfohlenes Kontext-Fenster: \(vm.kvPrecision.maxContextEstimate) · --prefill-step-size \(vm.prefillStepSize)")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Picker("KV-Cache", selection: $vm.kvPrecision) {
                            ForEach(KVCachePrecision.allCases) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 420)
                    }
                }

                // Schnelle MLX-Modelle: oMLX, Ollama & llama.cpp Dienste
                SolarisCard(accent: SolarisTheme.mint) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("ms_services_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.t("ms_services_sub"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                    }

                    // Dienst-Auswahl (oMLX / Ollama / llama.cpp)
                    HStack(spacing: 12) {
                        ForEach(RuntimeService.allCases) { svc in
                            let selected = vm.selectedService == svc
                            let installed = vm.serviceAvailability[svc] ?? false
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(svc.rawValue)
                                        .font(SolarisTheme.cardTitle)
                                        .foregroundColor(SolarisTheme.textPrimary)
                                    Spacer()
                                    Text(installed ? vm.t("ms_installed") : "PORT :\(svc.defaultPort)")
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill((installed ? SolarisTheme.emerald : SolarisTheme.amber).opacity(0.22)))
                                        .foregroundColor(installed ? SolarisTheme.emerald : SolarisTheme.amberGlow)
                                }
                                Text(svc.description)
                                    .font(.system(size: 13.5))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selected ? SolarisTheme.amber.opacity(0.14) : SolarisTheme.cardElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(selected ? SolarisTheme.amber : SolarisTheme.borderSubtle, lineWidth: 1.2)
                                    )
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onTapGesture {
                                vm.selectedService = svc
                            }
                        }
                    }

                    HStack(spacing: 14) {
                        Button {
                            vm.loadModelInSelectedService()
                        } label: {
                            Label("Modell in \(vm.selectedService.rawValue) laden", systemImage: "play.circle.fill")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.emerald))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)

                        Button {
                            vm.scanOllamaAndLlamaCppToMLX()
                        } label: {
                            Label(vm.t("ms_scan_btn"), systemImage: "magnifyingglass.circle.fill")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.mint))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)

                        Button {
                            vm.exportForOllamaAndLlamaCpp()
                        } label: {
                            Label(vm.t("ms_export_btn"), systemImage: "arrow.up.forward.app.fill")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.amber))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(vm.bridgeStatusMessage)
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.emerald)

                    if !vm.discoveredExternalModels.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(vm.discoveredExternalModels, id: \.self) { item in
                                Text("• \(item)")
                                    .font(SolarisTheme.monoCode)
                                    .foregroundColor(SolarisTheme.textPrimary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35)))
                    }
                }

                // Punkt 2: Disaggregiertes Prefill/Decode (ANE-Split) & 3-Tier KV-Cache / CacheGen
                SolarisCard(accent: SolarisTheme.mint) {
                    let aneMetrics = vm.aneSplitSpeedupAndEnergyRatio()
                    let kvMetrics = vm.cacheGenCompressionMetrics()

                    HStack {
                        Label("Disaggregiertes Prefill/Decode (ANE-Split) & 3-Tier KV-Cache", systemImage: "cpu.fill")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.mint)
                        Spacer()
                        Text(String(format: "EDP ×%.2f · -%.1f%% Watt", aneMetrics.prefillSpeedup, aneMetrics.energySavingsPct))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SolarisTheme.mint)
                            .cornerRadius(6)
                    }

                    Picker("Compute-Aufteilung", selection: $vm.splitPhaseComputeMode) {
                        ForEach(SplitPhaseComputeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("KV-Cache Tiering & CacheGen", selection: $vm.kvCacheTierMode) {
                        ForEach(KVCacheTierMode.allCases) { tier in
                            Text(tier.rawValue).tag(tier)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(String(format: "Prefix-Cache-Trefferrate: %.0f %%", vm.kvPrefixCacheHitRatePct))
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Slider(value: $vm.kvPrefixCacheHitRatePct, in: 0...100, step: 1)
                            .tint(SolarisTheme.mint)
                    }

                    HStack(spacing: 14) {
                        Text(String(format: "Roh-KV (32K): %.2f GB", kvMetrics.rawKvSizeGB))
                        Text(String(format: "CacheGen-Transfer: %.2f GB (%.1f×)", kvMetrics.compressedTransferGB, kvMetrics.compressionRatio))
                            .foregroundColor(SolarisTheme.emerald)
                        Text(String(format: "TTFT-Reduktion: -%.1f %%", kvMetrics.estimatedTtftReductionPct))
                            .foregroundColor(SolarisTheme.amberGlow)
                    }
                    .font(SolarisTheme.monoCode)
                    .foregroundColor(SolarisTheme.textSecondary)
                }
            }
            .padding(24)
        }
        .solarisShorttip(vm.shorttip(.models), id: "view_models_root", vm: vm)
    }
}
