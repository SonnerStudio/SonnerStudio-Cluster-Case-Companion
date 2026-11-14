import SwiftUI

struct ModelStudioView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        let split = vm.shardingSplit

        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SolarisCard {
                    Text("Modell-Auswahl & Speicher-Prüfung")
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("Wähle ein MLX-Modell — SS-CCC berechnet automatisch die proportionale Layer-Verteilung auf 36 GB + 16 GB.")
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)

                    VStack(spacing: 12) {
                        ForEach(vm.modelPresets) { preset in
                            let isSelected = preset.id == vm.selectedModel.id
                            Button {
                                vm.selectedModel = preset
                                vm.kvCacheReserveGB = preset.kvReserveGB
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(preset.displayName)
                                            .font(SolarisTheme.cardTitle)
                                            .foregroundColor(SolarisTheme.textPrimary)
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

                // Sharding Plan Vorschau
                SolarisCard(accent: split.fits ? SolarisTheme.emerald : SolarisTheme.coral) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weighted Pipeline Sharding Plan")
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Bedarf inkl. \(String(format: "%.1f", vm.kvCacheReserveGB)) GB KV-Cache: \(String(format: "%.1f", split.totalRequiredGB)) GB von \(Int(split.totalUsableGB)) GB verfügbar")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Label(
                            split.fits ? "Passt in Cluster" : "Zu groß (OOM-Schutz)",
                            systemImage: split.fits ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
                        )
                        .font(SolarisTheme.bodyBold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill((split.fits ? SolarisTheme.emerald : SolarisTheme.coral).opacity(0.20)))
                        .foregroundColor(split.fits ? SolarisTheme.emerald : SolarisTheme.coral)
                    }

                    // Visueller Layer-Split Balken
                    GeometryReader { geo in
                        HStack(spacing: 4) {
                            if split.studioLayers > 0 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(SolarisTheme.amber)
                                    .frame(width: geo.size.width * (split.studioPercent / 100.0))
                                    .overlay(
                                        Text("Mac Studio: Layer 0–\(split.studioLayers - 1) (\(split.studioLayers) Layer · \(String(format: "%.0f", split.studioPercent))%)")
                                            .font(SolarisTheme.bodyBold)
                                            .foregroundColor(.black)
                                    )
                            }
                            RoundedRectangle(cornerRadius: 8)
                                .fill(SolarisTheme.mint)
                                .overlay(
                                    Text("Mac mini: \(split.miniLayers) Layer (\(String(format: "%.0f", split.miniPercent))%)")
                                        .font(SolarisTheme.bodyBold)
                                        .foregroundColor(.black)
                                )
                        }
                    }
                    .frame(height: 44)

                    HStack {
                        Text("KV-Cache-Reserve:")
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
                            Text("KV-Cache-Quantisierung (für lange Agenten-Kontexte)")
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

                // Schnelle MLX-Modelle: Import aus Ollama/llama.cpp & Export-Bridge
                SolarisCard(accent: SolarisTheme.mint) {
                    Text("Schnelle MLX-Modelle: Ollama & llama.cpp Brücke")
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("SS-CCC rechnet ausschließlich mit nativen MLX-Modellen. Vorhandene Ollama- oder llama.cpp-Modelle lassen sich als MLX einbinden — und dein 52-GB-MLX-Cluster wird gleichzeitig für Ollama- & llama.cpp-Clients bereitgestellt.")
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)

                    HStack(spacing: 14) {
                        Button {
                            vm.scanOllamaAndLlamaCppToMLX()
                        } label: {
                            Label("Ollama / GGUF → MLX scannen", systemImage: "magnifyingglass.circle.fill")
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
                            Label("Für Ollama & llama.cpp bereitstellen", systemImage: "arrow.up.forward.app.fill")
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
            }
            .padding(24)
        }
    }
}
