import SwiftUI

struct ModelStudioView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        let split = vm.shardingSplit

        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ModelSwitcherCard(vm: vm)
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
                            Label(vm.isRefreshingModels ? "..." : L10n.tr(vm.language,
                                de: "Modelle neu einlesen",
                                en: "Reload Models",
                                fr: "Recharger les modèles",
                                es: "Recargar modelos",
                                pt: "Recarregar modelos",
                                ru: "Обновить модели",
                                ja: "モデルを再読込",
                                zh: "重新加载模型"), systemImage: "arrow.clockwise")
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
                                let badgeText = runtimeBadgeText(for: svc, isRunning: isRunning, isInstalled: isInstalled)
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
                                        Text(L10n.tr(vm.language,
                                            de: "Pfad: \(path)",
                                            en: "Path: \(path)",
                                            fr: "Chemin : \(path)",
                                            es: "Ruta: \(path)",
                                            pt: "Caminho: \(path)",
                                            ru: "Путь: \(path)",
                                            ja: "パス: \(path)",
                                            zh: "路径：\(path)"))
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(SolarisTheme.textSecondary)
                                    }
                                    let cmd = (isInstalled || isRunning) ? (status?.pullModelCommand ?? "") : (status?.installCommand ?? "")
                                    if !cmd.isEmpty {
                                        HStack {
                                            Text(cmd)
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(SolarisTheme.mint)
                                                .textSelection(.enabled)
                                            Spacer()
                                            if svc == .ollama && (isInstalled || isRunning) {
                                                Button(L10n.tr(vm.language,
                                                    de: "Modell laden",
                                                    en: "Pull Model",
                                                    fr: "Télécharger le modèle",
                                                    es: "Descargar modelo",
                                                    pt: "Baixar modelo",
                                                    ru: "Загрузить модель",
                                                    ja: "モデルを取得",
                                                    zh: "拉取模型")) {
                                                    Task { await vm.pullRecommendedOllamaModel() }
                                                }
                                                .buttonStyle(.borderedProminent)
                                                .tint(SolarisTheme.amber)
                                                .foregroundColor(.black)
                                            }
                                            Button(L10n.tr(vm.language,
                                                de: "Kopieren",
                                                en: "Copy",
                                                fr: "Copier",
                                                es: "Copiar",
                                                pt: "Copiar",
                                                ru: "Копировать",
                                                ja: "コピー",
                                                zh: "复制")) {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(cmd, forType: .string)
                                                vm.bridgeStatusMessage = L10n.tr(vm.language,
                                                    de: "Befehl kopiert: \(cmd)",
                                                    en: "Command copied: \(cmd)",
                                                    fr: "Commande copiée : \(cmd)",
                                                    es: "Comando copiado: \(cmd)",
                                                    pt: "Comando copiado: \(cmd)",
                                                    ru: "Команда скопирована: \(cmd)",
                                                    ja: "コマンドをコピーしました: \(cmd)",
                                                    zh: "已复制命令：\(cmd)")
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
                                                Text(preset.localizedSourceLabel(vm.language))
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Capsule().fill((preset.isLiveDiscovered ? SolarisTheme.emerald : SolarisTheme.amber).opacity(0.22)))
                                                    .foregroundColor(preset.isLiveDiscovered ? SolarisTheme.emerald : SolarisTheme.amberGlow)
                                            }
                                            Text("\(preset.quantization) · \(preset.totalLayers) \(L10n.text("ms_layers_unit", vm.language)) · ~\(String(format: "%.1f", preset.estimatedGB)) GB · \(preset.localizedNotes(vm.language))")
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
                let hasModel = !vm.modelPresets.isEmpty
                let planAccent: Color = hasModel ? (split.fits ? SolarisTheme.emerald : SolarisTheme.coral) : SolarisTheme.amber
                SolarisCard(accent: planAccent) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("ms_plan_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            if hasModel {
                                Text(L10n.tr(vm.language,
                                    de: "Bedarf inkl. \(String(format: "%.1f", vm.kvCacheReserveGB)) GB KV-Cache: \(String(format: "%.1f", split.totalRequiredGB)) GB von \(Int(split.totalUsableGB)) GB verfügbar",
                                    en: "Required incl. \(String(format: "%.1f", vm.kvCacheReserveGB)) GB KV Cache: \(String(format: "%.1f", split.totalRequiredGB)) GB of \(Int(split.totalUsableGB)) GB available",
                                    fr: "Requis (cache KV \(String(format: "%.1f", vm.kvCacheReserveGB)) Go incl.) : \(String(format: "%.1f", split.totalRequiredGB)) Go sur \(Int(split.totalUsableGB)) Go disponibles",
                                    es: "Requerido (incl. \(String(format: "%.1f", vm.kvCacheReserveGB)) GB caché KV): \(String(format: "%.1f", split.totalRequiredGB)) GB de \(Int(split.totalUsableGB)) GB disponibles",
                                    pt: "Necessário (incl. \(String(format: "%.1f", vm.kvCacheReserveGB)) GB cache KV): \(String(format: "%.1f", split.totalRequiredGB)) GB de \(Int(split.totalUsableGB)) GB disponíveis",
                                    ru: "Требуется (вкл. \(String(format: "%.1f", vm.kvCacheReserveGB)) ГБ KV-кэш): \(String(format: "%.1f", split.totalRequiredGB)) ГБ из \(Int(split.totalUsableGB)) ГБ доступно",
                                    ja: "必要容量（KVキャッシュ \(String(format: "%.1f", vm.kvCacheReserveGB)) GB 含む）: \(String(format: "%.1f", split.totalRequiredGB)) GB / \(Int(split.totalUsableGB)) GB 利用可能",
                                    zh: "所需容量（含 \(String(format: "%.1f", vm.kvCacheReserveGB)) GB KV 缓存）：\(String(format: "%.1f", split.totalRequiredGB)) GB / 可用 \(Int(split.totalUsableGB)) GB"))
                                    .font(SolarisTheme.bodyLarge)
                                    .foregroundColor(SolarisTheme.textSecondary)
                            } else {
                                Text(String(format: vm.t("ms_pool_ready_hint"), Int(split.totalUsableGB)))
                                    .font(SolarisTheme.bodyLarge)
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }
                        }
                        Spacer()
                        if hasModel {
                            Label(
                                split.fits ? vm.t("ms_fits") : vm.t("ms_oom"),
                                systemImage: split.fits ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
                            )
                            .font(SolarisTheme.bodyBold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill((split.fits ? SolarisTheme.emerald : SolarisTheme.coral).opacity(0.20)))
                            .foregroundColor(split.fits ? SolarisTheme.emerald : SolarisTheme.coral)
                        } else {
                            Label(vm.t("ms_no_model_loaded"), systemImage: "tray.fill")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(SolarisTheme.amber.opacity(0.20)))
                                .foregroundColor(SolarisTheme.amberGlow)
                        }
                    }

                    // Visueller Layer-Split Balken für alle aktiven M-Series Nodes
                    GeometryReader { geo in
                        let palette: [Color] = [SolarisTheme.amber, SolarisTheme.mint, SolarisTheme.emerald, Color.cyan, Color.purple]
                        HStack(spacing: 4) {
                            ForEach(Array(split.nodeAllocations.enumerated()), id: \.element.id) { idx, alloc in
                                if alloc.layers > 0 || !hasModel {
                                    let sharePct = hasModel ? alloc.percent : (split.totalUsableGB > 0 ? (alloc.usableGB / split.totalUsableGB) * 100.0 : 100.0)
                                    let layerUnit = L10n.text("ms_layers_unit", vm.language)
                                    let barText = hasModel
                                        ? "\(alloc.nodeName): \(alloc.layers) \(layerUnit) (\(String(format: "%.0f", alloc.percent))%)"
                                        : "\(alloc.nodeName): \(Int(alloc.usableGB)) GB (\(String(format: "%.0f", sharePct))%)"
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(palette[idx % palette.count].opacity(hasModel ? 1.0 : 0.7))
                                        .frame(width: max(50, geo.size.width * (sharePct / 100.0) - 4))
                                        .overlay(
                                            Text(barText)
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
                            Text(L10n.tr(vm.language,
                                de: "Empfohlenes Kontext-Fenster: \(vm.kvPrecision.localizedMaxContextEstimate(vm.language)) · --prefill-step-size \(vm.prefillStepSize)",
                                en: "Recommended Context Window: \(vm.kvPrecision.localizedMaxContextEstimate(vm.language)) · --prefill-step-size \(vm.prefillStepSize)",
                                fr: "Fenêtre de contexte recommandée : \(vm.kvPrecision.localizedMaxContextEstimate(vm.language)) · --prefill-step-size \(vm.prefillStepSize)",
                                es: "Ventana de contexto recomendada: \(vm.kvPrecision.localizedMaxContextEstimate(vm.language)) · --prefill-step-size \(vm.prefillStepSize)",
                                pt: "Janela de contexto recomendada: \(vm.kvPrecision.localizedMaxContextEstimate(vm.language)) · --prefill-step-size \(vm.prefillStepSize)",
                                ru: "Рекомендуемое окно контекста: \(vm.kvPrecision.localizedMaxContextEstimate(vm.language)) · --prefill-step-size \(vm.prefillStepSize)",
                                ja: "推奨コンテキスト長: \(vm.kvPrecision.localizedMaxContextEstimate(vm.language)) · --prefill-step-size \(vm.prefillStepSize)",
                                zh: "推荐上下文窗口：\(vm.kvPrecision.localizedMaxContextEstimate(vm.language)) · --prefill-step-size \(vm.prefillStepSize)"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Picker(L10n.tr(vm.language,
                            de: "KV-Cache",
                            en: "KV Cache",
                            fr: "Cache KV",
                            es: "Caché KV",
                            pt: "Cache KV",
                            ru: "KV-кэш",
                            ja: "KVキャッシュ",
                            zh: "KV 缓存"), selection: $vm.kvPrecision) {
                            ForEach(KVCachePrecision.allCases) { p in
                                Text(p.localizedTitle(vm.language)).tag(p)
                            }
                        }
                        .labelsHidden()
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
                                    Text(svc.localizedTitle(vm.language))
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
                                Text(svc.localizedDescription(vm.language))
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
                            Label(L10n.tr(vm.language,
                                de: "Modell in \(vm.selectedService.localizedTitle(vm.language)) laden",
                                en: "Load model in \(vm.selectedService.localizedTitle(vm.language))",
                                fr: "Charger le modèle dans \(vm.selectedService.localizedTitle(vm.language))",
                                es: "Cargar modelo en \(vm.selectedService.localizedTitle(vm.language))",
                                pt: "Carregar modelo em \(vm.selectedService.localizedTitle(vm.language))",
                                ru: "Загрузить модель в \(vm.selectedService.localizedTitle(vm.language))",
                                ja: "\(vm.selectedService.localizedTitle(vm.language)) にモデルを読込",
                                zh: "加载模型到 \(vm.selectedService.localizedTitle(vm.language))"), systemImage: "play.circle.fill")
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
                        Label(L10n.tr(vm.language,
                            de: "Disaggregiertes Prefill/Decode (ANE-Split) & 3-Tier KV-Cache",
                            en: "Disaggregated Prefill/Decode (ANE-Split) & 3-Tier KV Cache",
                            fr: "Prefill/Decode désagrégé (ANE-Split) & cache KV à 3 niveaux",
                            es: "Prefill/Decode desagregado (ANE-Split) y caché KV de 3 niveles",
                            pt: "Prefill/Decode desagregado (ANE-Split) e cache KV de 3 níveis",
                            ru: "Дезагрегированный Prefill/Decode (ANE-Split) и 3-уровневый KV-кэш",
                            ja: "分離型 Prefill/Decode (ANE-Split) & 3階層 KVキャッシュ",
                            zh: "分离式 Prefill/Decode (ANE-Split) 与 3 层 KV 缓存"), systemImage: "cpu.fill")
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

                    Picker(L10n.tr(vm.language,
                        de: "Compute-Aufteilung",
                        en: "Compute Split",
                        fr: "Répartition du calcul",
                        es: "División de cómputo",
                        pt: "Divisão de computação",
                        ru: "Разделение вычислений",
                        ja: "計算分割",
                        zh: "计算拆分"), selection: $vm.splitPhaseComputeMode) {
                        ForEach(SplitPhaseComputeMode.allCases) { mode in
                            Text(mode.localizedTitle(vm.language)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(L10n.tr(vm.language,
                        de: "KV-Cache Tiering & CacheGen",
                        en: "KV Cache Tiering & CacheGen",
                        fr: "Hiérarchisation du cache KV & CacheGen",
                        es: "Niveles de caché KV y CacheGen",
                        pt: "Camadas de cache KV e CacheGen",
                        ru: "Уровни KV-кэша и CacheGen",
                        ja: "KVキャッシュ階層化 & CacheGen",
                        zh: "KV 缓存分级与 CacheGen"), selection: $vm.kvCacheTierMode) {
                        ForEach(KVCacheTierMode.allCases) { tier in
                            Text(tier.localizedTitle(vm.language)).tag(tier)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(String(format: L10n.tr(vm.language,
                            de: "Prefix-Cache-Trefferrate: %.0f %%",
                            en: "Prefix Cache Hit Rate: %.0f %%",
                            fr: "Taux de succès du cache préfixe : %.0f %%",
                            es: "Tasa de aciertos de caché prefijo: %.0f %%",
                            pt: "Taxa de acerto do cache de prefixo: %.0f %%",
                            ru: "Попадание в префиксный кэш: %.0f %%",
                            ja: "プレフィックスキャッシュヒット率: %.0f %%",
                            zh: "前缀缓存命中率：%.0f %%"), vm.kvPrefixCacheHitRatePct))
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Slider(value: $vm.kvPrefixCacheHitRatePct, in: 0...100, step: 1)
                            .tint(SolarisTheme.mint)
                    }

                    HStack(spacing: 14) {
                        Text(String(format: L10n.tr(vm.language,
                            de: "Roh-KV (32K): %.2f GB",
                            en: "Raw KV (32K): %.2f GB",
                            fr: "KV brut (32K) : %.2f Go",
                            es: "KV bruto (32K): %.2f GB",
                            pt: "KV bruto (32K): %.2f GB",
                            ru: "Сырой KV (32K): %.2f ГБ",
                            ja: "生KV (32K): %.2f GB",
                            zh: "原始 KV (32K)：%.2f GB"), kvMetrics.rawKvSizeGB))
                        Text(String(format: L10n.tr(vm.language,
                            de: "CacheGen-Transfer: %.2f GB (%.1f×)",
                            en: "CacheGen Transfer: %.2f GB (%.1f×)",
                            fr: "Transfert CacheGen : %.2f Go (%.1f×)",
                            es: "Transferencia CacheGen: %.2f GB (%.1f×)",
                            pt: "Transferência CacheGen: %.2f GB (%.1f×)",
                            ru: "Передача CacheGen: %.2f ГБ (%.1f×)",
                            ja: "CacheGen 転送: %.2f GB (%.1f×)",
                            zh: "CacheGen 传输：%.2f GB (%.1f×)"), kvMetrics.compressedTransferGB, kvMetrics.compressionRatio))
                            .foregroundColor(SolarisTheme.emerald)
                        Text(String(format: L10n.tr(vm.language,
                            de: "TTFT-Reduktion: -%.1f %%",
                            en: "TTFT Reduction: -%.1f %%",
                            fr: "Réduction TTFT : -%.1f %%",
                            es: "Reducción TTFT: -%.1f %%",
                            pt: "Redução TTFT: -%.1f %%",
                            ru: "Снижение TTFT: -%.1f %%",
                            ja: "TTFT削減: -%.1f %%",
                            zh: "TTFT 降低：-%.1f %%"), kvMetrics.estimatedTtftReductionPct))
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

    private func runtimeBadgeText(for svc: RuntimeService, isRunning: Bool, isInstalled: Bool) -> String {
        if isRunning {
            if svc == .ollama {
                let modelCount = vm.modelPresets.filter {
                    $0.isLiveDiscovered && ($0.sourceLabel.localizedCaseInsensitiveContains("ollama") || $0.quantization.localizedCaseInsensitiveContains("ollama"))
                }.count
                return L10n.tr(vm.language,
                    de: "Bereit (Läuft · \(modelCount) Modelle)",
                    en: "Ready (Running · \(modelCount) models)",
                    fr: "Prêt (Actif · \(modelCount) modèles)",
                    es: "Listo (Activo · \(modelCount) modelos)",
                    pt: "Pronto (Ativo · \(modelCount) modelos)",
                    ru: "Готово (Запущен · \(modelCount) мод.)",
                    ja: "準備完了 (稼働中 · \(modelCount) モデル)",
                    zh: "就绪 (运行中 · \(modelCount) 个模型)")
            }
            return L10n.tr(vm.language,
                de: "Bereit (Läuft)",
                en: "Ready (Running)",
                fr: "Prêt (Actif)",
                es: "Listo (Activo)",
                pt: "Pronto (Ativo)",
                ru: "Готово (Запущен)",
                ja: "準備完了 (稼働中)",
                zh: "就绪 (运行中)")
        } else if isInstalled {
            return L10n.tr(vm.language,
                de: "Installiert (Gestoppt)",
                en: "Installed (Stopped)",
                fr: "Installé (Arrêté)",
                es: "Instalado (Detenido)",
                pt: "Instalado (Parado)",
                ru: "Установлен (Остановлен)",
                ja: "インストール済み (停止中)",
                zh: "已安装 (已停止)")
        } else {
            return L10n.tr(vm.language,
                de: "Nicht gefunden",
                en: "Not found",
                fr: "Introuvable",
                es: "No encontrado",
                pt: "Não encontrado",
                ru: "Не найден",
                ja: "未検出",
                zh: "未找到")
        }
    }
}
