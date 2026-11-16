import SwiftUI
import AppKit

struct MultiModelModeView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerAndScopeCard
                autoSetupCard
                nextGenSotaOrchestrationCard
                vramAndThroughputCard
                modelSlotsCard
                executionAndResultsCard
                multiIdeHarnessConsumptionCard
            }
            .padding(24)
        }
        .solarisShorttip(vm.shorttip(.multiModelMode), id: "view_mmm_root", vm: vm)
        .onAppear {
            if vm.mmmSlots.isEmpty {
                if !vm.loadMultiModelConfiguration() {
                    vm.autoConfigureMultiModelSetup()
                }
            }
        }
    }

    // MARK: - 1. Header, Scope & Orchestration Strategy

    private var headerAndScopeCard: some View {
        SolarisCard(accent: SolarisTheme.amber) {
            HazardStripesBar(height: 5, stripeWidth: 10, cornerRadius: 3, opacity: 0.85)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(L10n.tr(vm.language,
                            de: "Multi-Model-Mode (MMM)",
                            en: "Multi-Model Mode (MMM)",
                            fr: "Mode Multi-Modèle (MMM)",
                            es: "Modo Multimodelo (MMM)",
                            pt: "Modo Multimodelo (MMM)",
                            ru: "Режим нескольких моделей (MMM)",
                            ja: "マルチモデルモード (MMM)",
                            zh: "多模型模式 (MMM)"))
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(vm.simulateMacStudio
                            ? L10n.tr(vm.language, de: "SIMULATION", en: "SIMULATION", fr: "SIMULATION", es: "SIMULACIÓN", pt: "SIMULAÇÃO", ru: "СИМУЛЯЦИЯ", ja: "シミュレーション", zh: "模拟运行")
                            : L10n.tr(vm.language, de: "ECHTZEIT-ORCHESTRIERUNG", en: "LIVE ORCHESTRATION", fr: "ORCHESTRATION EN DIRECT", es: "ORQUESTACIÓN EN VIVO", pt: "ORQUESTRAÇÃO AO VIVO", ru: "ОРКЕСТРОВКА LIVE", ja: "ライブオーケストレーション", zh: "实时编排"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(vm.simulateMacStudio ? SolarisTheme.amber : SolarisTheme.emerald)
                            .cornerRadius(5)
                    }
                    Text(L10n.tr(vm.language,
                        de: "Führe mehrere Modelle innerhalb des lokalen Clusters, des Internet-Clusters oder eines gekoppelten Hybrid-Verbunds zu einer gemeinsamen Gesamtleistung zusammen.",
                        en: "Combine multiple models across the local cluster, the internet cluster, or a coupled hybrid mesh into unified aggregate throughput.",
                        fr: "Combinez plusieurs modèles sur le cluster local, le cluster Internet ou un maillage hybride pour un débit unifié.",
                        es: "Combina varios modelos en el clúster local, el clúster de Internet o una malla híbrida en un rendimiento conjunto.",
                        pt: "Combine vários modelos no cluster local, no cluster Internet ou em rede híbrida para desempenho agregado unificado.",
                        ru: "Объединяйте несколько моделей в локальном, интернет- или гибридном кластере для суммарной пропускной способности.",
                        ja: "ローカル・インターネット・ハイブリッドクラスタ間で複数モデルを統合し、合算スループットを引き出します。",
                        zh: "在本地集群、互联网集群或混合网络中协同调度多个模型，汇聚统一算力输出。"))
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                Button {
                    vm.syncMultiModelSlotsFromCluster()
                } label: {
                    Label(L10n.tr(vm.language,
                        de: "Aus Verbund synchronisieren",
                        en: "Sync from Cluster",
                        fr: "Synchroniser du cluster",
                        es: "Sincronizar del clúster",
                        pt: "Sincronizar do cluster",
                        ru: "Синхр. с кластером",
                        ja: "クラスタから同期",
                        zh: "从集群同步"), systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
            }

            Divider().opacity(0.25)

            // Scope Selector (Lokal / Internet-Cluster / Hybrid)
            HStack(spacing: 12) {
                Text(L10n.tr(vm.language,
                    de: "Cluster-Bereich:",
                    en: "Cluster Scope:",
                    fr: "Portée du cluster :",
                    es: "Ámbito del clúster:",
                    pt: "Âmbito do cluster:",
                    ru: "Область кластера:",
                    ja: "クラスタ範囲:",
                    zh: "集群范围："))
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
                Picker(L10n.tr(vm.language,
                    de: "Cluster-Bereich",
                    en: "Cluster Scope",
                    fr: "Portée du cluster",
                    es: "Ámbito del clúster",
                    pt: "Âmbito do cluster",
                    ru: "Область кластера",
                    ja: "クラスタ範囲",
                    zh: "集群范围"), selection: $vm.mmmScope) {
                    ForEach(MultiModelScope.allCases) { scope in
                        Text(scope.localizedTitle(vm.language)).tag(scope)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .onChange(of: vm.mmmScope) { _, _ in
                    vm.syncMultiModelSlotsFromCluster()
                }
            }

            // Orchestration Strategy Picker
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.tr(vm.language,
                    de: "Orchestrierungs-Strategie:",
                    en: "Orchestration Strategy:",
                    fr: "Stratégie d'orchestration :",
                    es: "Estrategia de orquestación:",
                    pt: "Estratégia de orquestração:",
                    ru: "Стратегия оркестровки:",
                    ja: "オーケストレーション戦略:",
                    zh: "编排策略："))
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
                Picker(L10n.tr(vm.language,
                    de: "Strategie",
                    en: "Strategy",
                    fr: "Stratégie",
                    es: "Estrategia",
                    pt: "Estratégia",
                    ru: "Стратегия",
                    ja: "戦略",
                    zh: "策略"), selection: $vm.mmmStrategy) {
                    ForEach(MultiModelStrategy.allCases) { strategy in
                        Text(strategy.localizedTitle(vm.language)).tag(strategy)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                Text(vm.mmmStrategy.localizedSummary(vm.language))
                    .font(Font.caption)
                    .foregroundColor(SolarisTheme.textSecondary)
            }
        }
    }

    // MARK: - 1b. Automatische Cluster-Einrichtung & Nachträgliche Konfiguration

    private var autoSetupCard: some View {
        SolarisCard(accent: SolarisTheme.mint) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr(vm.language,
                        de: "Automatische MMM-Einrichtung (1-Klick-Assistent)",
                        en: "Automatic MMM Setup (1-Click Wizard)",
                        fr: "Configuration MMM automatique (Assistant 1 clic)",
                        es: "Configuración MMM automática (Asistente 1 clic)",
                        pt: "Configuração MMM automática (Assistente 1 clique)",
                        ru: "Автонастройка MMM (мастер в 1 клик)",
                        ja: "自動 MMM セットアップ（ワンクリック・ウィザード）",
                        zh: "自动 MMM 配置（一键向导）"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(L10n.tr(vm.language,
                        de: "Erkennt automatisch verfügbare Knoten, VRAM-Pools und geladene Modelle. Jede Einstellung lässt sich anschließend jederzeit im Slot-Editor anpassen, umsortieren oder duplizieren.",
                        en: "Automatically detects available nodes, VRAM pools, and loaded models. Every setting can be edited, reordered, or duplicated anytime in the slot editor.",
                        fr: "Détecte automatiquement les nœuds, pools VRAM et modèles chargés. Chaque paramètre reste modifiable, réordonnable ou duplicable dans l'éditeur.",
                        es: "Detecta automáticamente nodos, pools de VRAM y modelos cargados. Cada ajuste se puede editar, reordenar o duplicar luego en el editor de slots.",
                        pt: "Deteta automaticamente nós, pools de VRAM e modelos carregados. Cada definição pode ser editada, reordenada ou duplicada no editor de slots.",
                        ru: "Автоматически определяет доступные узлы, пулы VRAM и загруженные модели. Любой слот можно изменить, переставить или дублировать.",
                        ja: "利用可能なノード、VRAMプール、ロード済みモデルを自動検出します。設定は後からスロットエディタでいつでも編集・並び替え・複製できます。",
                        zh: "自动识别可用节点、显存池与已加载模型。所有参数均可随时在槽位编辑器中修改、排序或复制。"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                Button {
                    vm.autoConfigureMultiModelSetup()
                } label: {
                    Label(L10n.tr(vm.language,
                        de: "Automatisch einrichten",
                        en: "Auto-Configure",
                        fr: "Configurer auto",
                        es: "Configurar auto",
                        pt: "Configurar auto",
                        ru: "Автонастройка",
                        ja: "自動構成",
                        zh: "自动配置"), systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.amber)
                .foregroundColor(.black)
            }

            HStack(spacing: 10) {
                Text(L10n.tr(vm.language,
                    de: "Profil:",
                    en: "Profile:",
                    fr: "Profil :",
                    es: "Perfil:",
                    pt: "Perfil:",
                    ru: "Профиль:",
                    ja: "プロファイル:",
                    zh: "配置文件："))
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
                Picker(L10n.tr(vm.language,
                    de: "Auto-Profil",
                    en: "Auto Profile",
                    fr: "Profil auto",
                    es: "Perfil auto",
                    pt: "Perfil auto",
                    ru: "Автопрофиль",
                    ja: "自動プロファイル",
                    zh: "自动配置方案"), selection: $vm.mmmAutoProfile) {
                    ForEach(MultiModelAutoProfile.allCases) { profile in
                        Text(profile.localizedTitle(vm.language)).tag(profile)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Text(vm.mmmAutoProfile.localizedSummary(vm.language))
                .font(Font.caption)
                .foregroundColor(SolarisTheme.textSecondary)

            HStack(spacing: 10) {
                Button {
                    vm.optimizeMultiModelSlotsForVram()
                } label: {
                    Label(L10n.tr(vm.language,
                        de: "VRAM-Fit optimieren",
                        en: "Optimize VRAM Fit",
                        fr: "Optimiser la VRAM",
                        es: "Optimizar ajuste VRAM",
                        pt: "Otimizar ajuste VRAM",
                        ru: "Оптимизировать VRAM",
                        ja: "VRAM適合を最適化",
                        zh: "优化显存适配"), systemImage: "checkmark.shield")
                }
                .buttonStyle(.bordered)

                Button {
                    vm.saveMultiModelConfiguration()
                    vm.mmmStatusMessage = L10n.tr(vm.language,
                        de: "MMM-Konfiguration dauerhaft gespeichert.",
                        en: "MMM configuration saved persistently.",
                        fr: "Configuration MMM enregistrée.",
                        es: "Configuración MMM guardada de forma permanente.",
                        pt: "Configuração MMM guardada permanentemente.",
                        ru: "Конфигурация MMM сохранена.",
                        ja: "MMM 設定を永続保存しました。",
                        zh: "已永久保存 MMM 配置。")
                } label: {
                    Label(L10n.tr(vm.language,
                        de: "Konfiguration speichern",
                        en: "Save Configuration",
                        fr: "Enregistrer",
                        es: "Guardar configuración",
                        pt: "Guardar configuração",
                        ru: "Сохранить конфигурацию",
                        ja: "設定を保存",
                        zh: "保存配置"), systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)

                Button {
                    let json = vm.exportMultiModelConfigurationJSON()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(json, forType: .string)
                    vm.mmmConfigCopiedBanner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        vm.mmmConfigCopiedBanner = false
                    }
                } label: {
                    Label(vm.mmmConfigCopiedBanner
                        ? L10n.tr(vm.language, de: "JSON kopiert!", en: "JSON copied!", fr: "JSON copié !", es: "¡JSON copiado!", pt: "JSON copiado!", ru: "JSON скопирован!", ja: "JSON をコピー!", zh: "已复制 JSON！")
                        : L10n.tr(vm.language, de: "Config-JSON kopieren", en: "Copy Config JSON", fr: "Copier Config JSON", es: "Copiar JSON", pt: "Copiar JSON", ru: "Копировать Config JSON", ja: "設定 JSON をコピー", zh: "复制配置 JSON"), systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            if !vm.mmmAutoSetupSummary.isEmpty {
                Text(vm.mmmAutoSetupSummary)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(SolarisTheme.emerald)
            }
        }
    }

    // MARK: - 1b. Next-Gen SOTA MMM Controls (EAGLE-3, Tree-MoA Early-Exit, Confidence Router & Thermal/Carbon)

    private var nextGenSotaOrchestrationCard: some View {
        SolarisCard(accent: SolarisTheme.emerald) {
            HStack {
                Label(L10n.tr(vm.language,
                    de: "Next-Gen MMM Engine (EAGLE-3 · Tree-MoA · Thermik/CO₂)",
                    en: "Next-Gen MMM Engine (EAGLE-3 · Tree-MoA · Thermal/Carbon)",
                    fr: "Moteur MMM Next-Gen (EAGLE-3 · Tree-MoA · Thermique/CO₂)",
                    es: "Motor MMM Next-Gen (EAGLE-3 · Tree-MoA · Térmica/CO₂)",
                    pt: "Motor MMM Next-Gen (EAGLE-3 · Tree-MoA · Térmica/CO₂)",
                    ru: "Движок MMM Next-Gen (EAGLE-3 · Tree-MoA · Термо/CO₂)",
                    ja: "次世代 MMM エンジン (EAGLE-3 · Tree-MoA · 熱/CO₂)",
                    zh: "新一代 MMM 引擎 (EAGLE-3 · Tree-MoA · 温控/碳感知)"), systemImage: "sparkles.rectangle.stack.fill")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.emerald)
                Spacer()
                Text(String(format: L10n.tr(vm.language,
                    de: "%.1f tok/s geschätzt",
                    en: "%.1f tok/s est.",
                    fr: "%.1f tok/s est.",
                    es: "%.1f tok/s est.",
                    pt: "%.1f tok/s est.",
                    ru: "%.1f tok/с ож.",
                    ja: "推定 %.1f tok/s",
                    zh: "预计 %.1f tok/s"), vm.mmmEstimatedCombinedTokPerSec))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(SolarisTheme.emerald)
                    .cornerRadius(6)
            }

            // Punkt 3: EAGLE-3 Speculative Engine
            Picker(L10n.tr(vm.language,
                de: "Speculative-Engine",
                en: "Speculative Engine",
                fr: "Moteur spéculatif",
                es: "Motor especulativo",
                pt: "Motor especulativo",
                ru: "Спекулятивный движок",
                ja: "投機的デコードエンジン",
                zh: "投机解码引擎"), selection: $vm.mmmSpeculativeEngine) {
                ForEach(SpeculativeEngineMode.allCases) { engine in
                    Text(engine.localizedTitle(vm.language)).tag(engine)
                }
            }
            .pickerStyle(.segmented)

            // Punkt 3: Tree-MoA Early-Exit & Adaptive Confidence Escalation
            HStack(spacing: 16) {
                Toggle(L10n.tr(vm.language,
                    de: "Tree-MoA Early-Exit",
                    en: "Tree-MoA Early-Exit",
                    fr: "Sortie anticipée Tree-MoA",
                    es: "Salida temprana Tree-MoA",
                    pt: "Saída antecipada Tree-MoA",
                    ru: "Ранний выход Tree-MoA",
                    ja: "Tree-MoA 早期終了",
                    zh: "Tree-MoA 提前退出"), isOn: $vm.mmmEnableTreeMoaEarlyExit)
                    .toggleStyle(.switch)
                    .tint(SolarisTheme.mint)

                Toggle(L10n.tr(vm.language,
                    de: "Adaptive Konfidenz-Eskalation (Ares)",
                    en: "Adaptive Confidence Escalation (Ares)",
                    fr: "Escalade adaptative de confiance (Ares)",
                    es: "Escalada adaptativa de confianza (Ares)",
                    pt: "Escalada adaptativa de confiança (Ares)",
                    ru: "Адаптивная эскалация уверенности (Ares)",
                    ja: "適応型信頼度エスカレーション (Ares)",
                    zh: "自适应置信度升级 (Ares)"), isOn: $vm.mmmConfidenceEscalationEnabled)
                    .toggleStyle(.switch)
                    .tint(SolarisTheme.amber)
            }
            .font(SolarisTheme.bodyBold)
            .foregroundColor(SolarisTheme.textPrimary)

            HStack {
                Text(String(format: L10n.tr(vm.language,
                    de: "MoA-Konfidenz-Schwellenwert: %.0f %%",
                    en: "MoA Confidence Threshold: %.0f %%",
                    fr: "Seuil de confiance MoA : %.0f %%",
                    es: "Umbral de confianza MoA: %.0f %%",
                    pt: "Limiar de confiança MoA: %.0f %%",
                    ru: "Порог уверенности MoA: %.0f %%",
                    ja: "MoA 信頼度しきい値: %.0f %%",
                    zh: "MoA 置信度阈值：%.0f %%"), vm.mmmMoaConfidenceThreshold * 100))
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
                Slider(value: $vm.mmmMoaConfidenceThreshold, in: 0.50...0.95, step: 0.01)
                    .tint(SolarisTheme.emerald)
            }

            Divider().opacity(0.2)

            // Punkt 5: Thermal- & Carbon-Aware Workload Placement
            HStack(spacing: 12) {
                Toggle(L10n.tr(vm.language,
                    de: "Thermik- & CO₂-bewusstes Scheduling",
                    en: "Thermal- & Carbon-Aware Scheduling",
                    fr: "Ordonnancement thermique & bas carbone",
                    es: "Planificación térmica y consciente de carbono",
                    pt: "Escalonamento térmico e de baixo carbono",
                    ru: "Планирование с учётом термо и CO₂",
                    ja: "熱・CO₂認識スケジューリング",
                    zh: "温控与碳感知调度"), isOn: $vm.mmmThermalCarbonAwareScheduling)
                    .toggleStyle(.switch)
                    .tint(SolarisTheme.emerald)
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textPrimary)

                Spacer()

                Picker(L10n.tr(vm.language,
                    de: "Scheduling-Policy",
                    en: "Scheduling Policy",
                    fr: "Politique",
                    es: "Política",
                    pt: "Política",
                    ru: "Политика",
                    ja: "ポリシー",
                    zh: "调度策略"), selection: $vm.thermalCarbonPolicy) {
                    ForEach(ThermalCarbonSchedulingPolicy.allCases) { policy in
                        Text(policy.localizedTitle(vm.language)).tag(policy)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - 2. VRAM Budget & Combined Throughput Overview

    private var vramAndThroughputCard: some View {
        SolarisCard(accent: vm.mmmFitsInClusterPool ? SolarisTheme.mint : SolarisTheme.coral) {
            HStack(spacing: 14) {
                mmmMetricTile(
                    title: L10n.tr(vm.language, de: "Aktive Modelle", en: "Active Models", fr: "Modèles actifs", es: "Modelos activos", pt: "Modelos ativos", ru: "Активные модели", ja: "稼働モデル", zh: "活跃模型"),
                    value: "\(vm.mmmActiveSlots.count) / \(vm.mmmSlots.count)",
                    sub: L10n.tr(vm.language,
                        de: "\(vm.mmmAvailableTargets.count) Ziel-Knoten (\(vm.mmmScope.localizedTitle(vm.language)))",
                        en: "\(vm.mmmAvailableTargets.count) target nodes (\(vm.mmmScope.localizedTitle(vm.language)))",
                        fr: "\(vm.mmmAvailableTargets.count) nœuds cibles (\(vm.mmmScope.localizedTitle(vm.language)))",
                        es: "\(vm.mmmAvailableTargets.count) nodos destino (\(vm.mmmScope.localizedTitle(vm.language)))",
                        pt: "\(vm.mmmAvailableTargets.count) nós destino (\(vm.mmmScope.localizedTitle(vm.language)))",
                        ru: "\(vm.mmmAvailableTargets.count) целевых узлов (\(vm.mmmScope.localizedTitle(vm.language)))",
                        ja: "\(vm.mmmAvailableTargets.count) ノード (\(vm.mmmScope.localizedTitle(vm.language)))",
                        zh: "\(vm.mmmAvailableTargets.count) 个目标节点 (\(vm.mmmScope.localizedTitle(vm.language)))"),
                    accent: SolarisTheme.amberGlow
                )
                mmmMetricTile(
                    title: L10n.tr(vm.language, de: "VRAM-Bedarf vs. Pool", en: "VRAM Demand vs. Pool", fr: "Demande VRAM vs Pool", es: "VRAM requerida vs Pool", pt: "VRAM vs Pool", ru: "VRAM / Пул", ja: "VRAM 必要量 / プール", zh: "显存需求 / 总池"),
                    value: String(format: "%.1f / %.1f GB", vm.mmmTotalRequiredVramGB, vm.mmmUsableVramPoolGB),
                    sub: vm.mmmFitsInClusterPool
                        ? L10n.tr(vm.language, de: "Passt sicher in nutzbaren Pool", en: "Fits safely within usable pool", fr: "Rentre dans le pool disponible", es: "Cabe seguro en el pool usable", pt: "Cabe no pool utilizável", ru: "Помещается в доступный пул", ja: "利用可能プール内に安全に収容", zh: "安全适配可用显存池")
                        : L10n.tr(vm.language, de: "Pool überschritten — Slots reduzieren", en: "Pool exceeded — reduce slots", fr: "Pool dépassé — réduire les slots", es: "Pool superado — reducir slots", pt: "Pool excedido — reduzir slots", ru: "Пул превышен — уменьшите слоты", ja: "プール超過 — スロットを削減", zh: "超出显存池 — 请减少槽位"),
                    accent: vm.mmmFitsInClusterPool ? SolarisTheme.emerald : SolarisTheme.coral
                )
                mmmMetricTile(
                    title: L10n.tr(vm.language, de: "Kombinierte Leistung", en: "Combined Throughput", fr: "Débit combiné", es: "Rendimiento combinado", pt: "Débito combinado", ru: "Совокупная скорость", ja: "合算スループット", zh: "组合吞吐率"),
                    value: String(format: "%.1f tok/s", vm.mmmEstimatedCombinedTokPerSec),
                    sub: vm.mmmStrategy.localizedTitle(vm.language),
                    accent: SolarisTheme.mint
                )
                mmmMetricTile(
                    title: L10n.tr(vm.language, de: "Letzte Ausführung", en: "Last Run", fr: "Dernière exécution", es: "Última ejecución", pt: "Última execução", ru: "Последний запуск", ja: "直近の実行", zh: "最近执行"),
                    value: vm.mmmLastResult.map { String(format: "%.2fx", $0.speedupFactor) } ?? "—",
                    sub: vm.mmmLastResult.map {
                        $0.isLiveExecution
                            ? L10n.tr(vm.language, de: "Live SSE", en: "Live SSE", fr: "SSE direct", es: "SSE en vivo", pt: "SSE ao vivo", ru: "Live SSE", ja: "ライブ SSE", zh: "实时 SSE")
                            : L10n.tr(vm.language, de: "Simulation", en: "Simulation", fr: "Simulation", es: "Simulación", pt: "Simulação", ru: "Симуляция", ja: "シミュレーション", zh: "模拟")
                    } ?? L10n.tr(vm.language, de: "Noch nicht gestartet", en: "Not started yet", fr: "Pas encore lancé", es: "Aún no iniciado", pt: "Ainda não iniciado", ru: "Ещё не запущен", ja: "未実行", zh: "尚未启动"),
                    accent: SolarisTheme.amber
                )
            }

            // Memory Fill Bar
            let pool = max(1.0, vm.mmmUsableVramPoolGB)
            let ratio = min(1.0, vm.mmmTotalRequiredVramGB / pool)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L10n.tr(vm.language,
                        de: "Multi-Modell-Speicherauslastung (inkl. iogpu.wired_limit_mb Schutz)",
                        en: "Multi-Model Memory Utilization (incl. iogpu.wired_limit_mb Guard)",
                        fr: "Utilisation mémoire multi-modèles (garde iogpu.wired_limit_mb incl.)",
                        es: "Uso de memoria multimodelo (incl. protección iogpu.wired_limit_mb)",
                        pt: "Uso de memória multimodelo (incl. proteção iogpu.wired_limit_mb)",
                        ru: "Использование памяти (с защитой iogpu.wired_limit_mb)",
                        ja: "マルチモデルメモリ使用率 (iogpu.wired_limit_mb 保護込み)",
                        zh: "多模型显存占用（含 iogpu.wired_limit_mb 保护）"))
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Text(String(format: L10n.tr(vm.language,
                        de: "%.0f%% belegt",
                        en: "%.0f%% used",
                        fr: "%.0f%% utilisé",
                        es: "%.0f%% usado",
                        pt: "%.0f%% utilizado",
                        ru: "%.0f%% занято",
                        ja: "%.0f%% 使用中",
                        zh: "已使用 %.0f%%"), (vm.mmmTotalRequiredVramGB / pool) * 100.0))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(vm.mmmFitsInClusterPool ? SolarisTheme.emerald : SolarisTheme.coral)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(SolarisTheme.cardElevated)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(vm.mmmFitsInClusterPool ? SolarisTheme.mint : SolarisTheme.coral)
                            .frame(width: max(8, geo.size.width * ratio))
                    }
                }
                .frame(height: 12)
            }
        }
    }

    // MARK: - 3. Multi-Model Slot Configuration

    private var modelSlotsCard: some View {
        SolarisCard {
            HStack {
                Text(L10n.tr(vm.language,
                    de: "Modell-Slots & Knoten-Zuweisung",
                    en: "Model Slots & Node Assignment",
                    fr: "Slots de modèles & affectation des nœuds",
                    es: "Slots de modelos y asignación de nodos",
                    pt: "Slots de modelos e atribuição de nós",
                    ru: "Слоты моделей и привязка к узлам",
                    ja: "モデルスロットとノード割り当て",
                    zh: "模型槽位与节点分配"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                Text(L10n.tr(vm.language,
                    de: "Ziele: \(vm.mmmAvailableTargets.joined(separator: " · "))",
                    en: "Targets: \(vm.mmmAvailableTargets.joined(separator: " · "))",
                    fr: "Cibles : \(vm.mmmAvailableTargets.joined(separator: " · "))",
                    es: "Destinos: \(vm.mmmAvailableTargets.joined(separator: " · "))",
                    pt: "Destinos: \(vm.mmmAvailableTargets.joined(separator: " · "))",
                    ru: "Цели: \(vm.mmmAvailableTargets.joined(separator: " · "))",
                    ja: "ターゲット: \(vm.mmmAvailableTargets.joined(separator: " · "))",
                    zh: "目标节点：\(vm.mmmAvailableTargets.joined(separator: " · "))"))
                    .font(Font.caption)
                    .foregroundColor(SolarisTheme.textSecondary)
                    .lineLimit(1)
            }

            VStack(spacing: 10) {
                ForEach($vm.mmmSlots) { $slot in
                    let isExpanded = vm.mmmExpandedSlotId == slot.id
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Toggle("", isOn: $slot.isEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(slot.displayName)
                                    .font(SolarisTheme.bodyBold)
                                    .foregroundColor(SolarisTheme.textPrimary)
                                Text(slot.modelId)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }
                            .frame(minWidth: 165, alignment: .leading)

                            Picker(L10n.tr(vm.language, de: "Rolle", en: "Role", fr: "Rôle", es: "Rol", pt: "Função", ru: "Роль", ja: "役割", zh: "角色"), selection: $slot.role) {
                                ForEach(MultiModelRole.allCases) { r in
                                    Text(r.localizedTitle(vm.language)).tag(r)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 115)

                            Picker(L10n.tr(vm.language, de: "Knoten", en: "Node", fr: "Nœud", es: "Nodo", pt: "Nó", ru: "Узел", ja: "ノード", zh: "节点"), selection: $slot.assignedTarget) {
                                let localFallback = L10n.tr(vm.language, de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")
                                ForEach(vm.mmmAvailableTargets.isEmpty ? [localFallback] : vm.mmmAvailableTargets, id: \.self) { t in
                                    Text(t).tag(t)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 155)

                            Text(String(format: "%.1f GB", slot.estimatedRamGB))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(SolarisTheme.amberGlow)
                                .frame(width: 62, alignment: .trailing)

                            Text(slot.lastTokPerSec > 0 ? String(format: "%.1f tok/s", slot.lastTokPerSec) : "—")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(SolarisTheme.emerald)
                                .frame(width: 78, alignment: .trailing)

                            HStack(spacing: 4) {
                                Button {
                                    vm.moveMultiModelSlot(slot.id, direction: -1)
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .buttonStyle(.borderless)
                                .help(L10n.tr(vm.language, de: "Nach oben verschieben", en: "Move up", fr: "Monter", es: "Subir", pt: "Mover para cima", ru: "Вверх", ja: "上へ移動", zh: "上移"))

                                Button {
                                    vm.moveMultiModelSlot(slot.id, direction: 1)
                                } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .buttonStyle(.borderless)
                                .help(L10n.tr(vm.language, de: "Nach unten verschieben", en: "Move down", fr: "Descendre", es: "Bajar", pt: "Mover para baixo", ru: "Вниз", ja: "下へ移動", zh: "下移"))

                                Button {
                                    vm.duplicateMultiModelSlot(slot.id)
                                } label: {
                                    Image(systemName: "plus.square.on.square")
                                }
                                .buttonStyle(.borderless)
                                .help(L10n.tr(vm.language, de: "Slot für weiteren Knoten duplizieren", en: "Duplicate slot for another node", fr: "Dupliquer pour un autre nœud", es: "Duplicar slot para otro nodo", pt: "Duplicar slot para outro nó", ru: "Дублировать слот для другого узла", ja: "別ノード用にスロットを複製", zh: "复制槽位至其他节点"))

                                Button {
                                    vm.mmmExpandedSlotId = isExpanded ? nil : slot.id
                                } label: {
                                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "slider.horizontal.3")
                                        .foregroundColor(isExpanded ? SolarisTheme.amber : SolarisTheme.textSecondary)
                                }
                                .buttonStyle(.borderless)
                                .help(L10n.tr(vm.language, de: "Slot-Details nachträglich anpassen", en: "Edit slot details", fr: "Modifier le slot", es: "Editar detalles del slot", pt: "Editar detalhes do slot", ru: "Изменить параметры слота", ja: "スロット詳細を編集", zh: "编辑槽位详情"))

                                Button(role: .destructive) {
                                    vm.removeMultiModelSlot(slot.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help(L10n.tr(vm.language, de: "Slot entfernen", en: "Remove slot", fr: "Supprimer le slot", es: "Eliminar slot", pt: "Remover slot", ru: "Удалить слот", ja: "スロットを削除", zh: "删除槽位"))
                            }
                        }

                        if isExpanded {
                            Divider().opacity(0.2)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(L10n.tr(vm.language, de: "Anzeigename", en: "Display Name", fr: "Nom affiché", es: "Nombre visible", pt: "Nome de exibição", ru: "Имя", ja: "表示名", zh: "显示名称"))
                                            .font(Font.caption)
                                            .foregroundColor(SolarisTheme.textSecondary)
                                        TextField(L10n.tr(vm.language, de: "Anzeigename", en: "Display Name", fr: "Nom affiché", es: "Nombre visible", pt: "Nome de exibição", ru: "Имя", ja: "表示名", zh: "显示名称"), text: $slot.displayName)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(L10n.tr(vm.language, de: "Modell-ID", en: "Model ID", fr: "ID modèle", es: "ID modelo", pt: "ID modelo", ru: "ID модели", ja: "モデルID", zh: "模型 ID"))
                                            .font(Font.caption)
                                            .foregroundColor(SolarisTheme.textSecondary)
                                        TextField(L10n.tr(vm.language, de: "Modell-ID", en: "Model ID", fr: "ID modèle", es: "ID modelo", pt: "ID modelo", ru: "ID модели", ja: "モデルID", zh: "模型 ID"), text: $slot.modelId)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(L10n.tr(vm.language, de: "VRAM-Limit", en: "VRAM Limit", fr: "Limite VRAM", es: "Límite VRAM", pt: "Limite VRAM", ru: "Лимит VRAM", ja: "VRAM 上限", zh: "显存上限"))
                                            .font(Font.caption)
                                            .foregroundColor(SolarisTheme.textSecondary)
                                        Stepper(String(format: "%.0f GB", slot.estimatedRamGB), value: $slot.estimatedRamGB, in: 1...256, step: 2)
                                            .frame(width: 120)
                                    }
                                }
                                HStack(spacing: 10) {
                                    Text(L10n.tr(vm.language, de: "Endpunkt-URL:", en: "Endpoint URL:", fr: "URL endpoint :", es: "URL endpoint:", pt: "URL endpoint:", ru: "URL конечной точки:", ja: "エンドポイント URL:", zh: "端点 URL："))
                                        .font(Font.caption)
                                        .foregroundColor(SolarisTheme.textSecondary)
                                    TextField("http://127.0.0.1:8000/v1", text: $slot.endpointURL)
                                        .textFieldStyle(.roundedBorder)
                                    Button(":8000/v1") {
                                        slot.endpointURL = "http://127.0.0.1:8000/v1"
                                    }
                                    .buttonStyle(.bordered)
                                    Button(":11434/v1") {
                                        slot.endpointURL = "http://127.0.0.1:11434/v1"
                                    }
                                    .buttonStyle(.bordered)
                                    Button(L10n.tr(vm.language, de: "Übernehmen & Speichern", en: "Apply & Save", fr: "Appliquer & Enregistrer", es: "Aplicar y Guardar", pt: "Aplicar e Guardar", ru: "Применить и сохранить", ja: "適用して保存", zh: "应用并保存")) {
                                        vm.saveMultiModelConfiguration()
                                        vm.mmmExpandedSlotId = nil
                                        vm.mmmStatusMessage = L10n.tr(vm.language,
                                            de: "Slot '\(slot.displayName)' aktualisiert und gespeichert.",
                                            en: "Slot '\(slot.displayName)' updated and saved.",
                                            fr: "Slot « \(slot.displayName) » mis à jour et enregistré.",
                                            es: "Slot '\(slot.displayName)' actualizado y guardado.",
                                            pt: "Slot '\(slot.displayName)' atualizado e guardado.",
                                            ru: "Слот '\(slot.displayName)' обновлён и сохранён.",
                                            ja: "スロット '\(slot.displayName)' を更新して保存しました。",
                                            zh: "已更新并保存槽位 '\(slot.displayName)'。")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(SolarisTheme.emerald)
                                    .foregroundColor(.black)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(10)
                    .background(SolarisTheme.cardElevated)
                    .cornerRadius(10)
                    .solarisHighlightGlow(
                        accent: slot.isEnabled ? SolarisTheme.mint : SolarisTheme.amber,
                        isActive: isExpanded,
                        isHovered: vm.hoveredGlowId == "mmm_slot_\(slot.id.uuidString)",
                        cornerRadius: 10
                    )
                    .onHover { hovering in
                        let key = "mmm_slot_\(slot.id.uuidString)"
                        vm.hoveredGlowId = hovering ? key : (vm.hoveredGlowId == key ? nil : vm.hoveredGlowId)
                    }
                }
            }

            Divider().opacity(0.2)

            // Add custom model slot
            HStack(spacing: 10) {
                TextField(L10n.tr(vm.language,
                    de: "Modell-ID (z. B. qwen2.5-coder:7b)",
                    en: "Model ID (e.g., qwen2.5-coder:7b)",
                    fr: "ID modèle (ex. qwen2.5-coder:7b)",
                    es: "ID modelo (p. ej., qwen2.5-coder:7b)",
                    pt: "ID modelo (ex.: qwen2.5-coder:7b)",
                    ru: "ID модели (напр., qwen2.5-coder:7b)",
                    ja: "モデルID (例: qwen2.5-coder:7b)",
                    zh: "模型 ID（例如 qwen2.5-coder:7b）"), text: $vm.mmmNewModelId)
                    .textFieldStyle(.roundedBorder)
                TextField(L10n.tr(vm.language, de: "Anzeigename", en: "Display Name", fr: "Nom affiché", es: "Nombre visible", pt: "Nome de exibição", ru: "Имя", ja: "表示名", zh: "显示名称"), text: $vm.mmmNewModelName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                Picker(L10n.tr(vm.language, de: "Rolle", en: "Role", fr: "Rôle", es: "Rol", pt: "Função", ru: "Роль", ja: "役割", zh: "角色"), selection: $vm.mmmNewModelRole) {
                    ForEach(MultiModelRole.allCases) { r in
                        Text(r.localizedTitle(vm.language)).tag(r)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
                Stepper(String(format: "%.0f GB", vm.mmmNewModelRamGB), value: $vm.mmmNewModelRamGB, in: 1...256, step: 2)
                    .frame(width: 120)
                Button(L10n.tr(vm.language, de: "Slot hinzufügen", en: "Add Slot", fr: "Ajouter slot", es: "Añadir slot", pt: "Adicionar slot", ru: "Добавить слот", ja: "スロット追加", zh: "添加槽位")) {
                    vm.addMultiModelSlot(
                        modelId: vm.mmmNewModelId,
                        displayName: vm.mmmNewModelName,
                        role: vm.mmmNewModelRole,
                        estimatedRamGB: vm.mmmNewModelRamGB
                    )
                    vm.mmmNewModelId = ""
                    vm.mmmNewModelName = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.amber)
                .foregroundColor(.black)
                .disabled(vm.mmmNewModelId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - 4. Prompt Execution & Combined Results

    private var executionAndResultsCard: some View {
        SolarisCard(accent: SolarisTheme.emerald) {
            HStack {
                Text(L10n.tr(vm.language,
                    de: "Multi-Modell-Ausführung & Leistungszusammenführung",
                    en: "Multi-Model Execution & Performance Aggregation",
                    fr: "Exécution multi-modèles & agrégation des performances",
                    es: "Ejecución multimodelo y agregación de rendimiento",
                    pt: "Execução multimodelo e agregação de desempenho",
                    ru: "Запуск моделей и агрегация производительности",
                    ja: "マルチモデル実行・性能統合",
                    zh: "多模型执行与性能汇聚"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                Button {
                    vm.executeMultiModelOrchestration()
                } label: {
                    Label(
                        vm.isRunningMultiModel
                            ? L10n.tr(vm.language, de: "Orchestrierung läuft...", en: "Orchestrating...", fr: "Orchestration en cours...", es: "Orquestando...", pt: "A orquestrar...", ru: "Оркестровка...", ja: "オーケストレーション実行中...", zh: "正在编排运行...")
                            : L10n.tr(vm.language, de: "MMM-Lauf starten", en: "Start MMM Run", fr: "Lancer l'exécution MMM", es: "Iniciar ejecución MMM", pt: "Iniciar execução MMM", ru: "Запустить MMM", ja: "MMM 実行開始", zh: "启动 MMM 运行"),
                        systemImage: vm.isRunningMultiModel ? "hourglass" : "play.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.emerald)
                .foregroundColor(.black)
                .disabled(vm.isRunningMultiModel || vm.mmmActiveSlots.isEmpty)
            }

            TextField(L10n.tr(vm.language,
                de: "Gemeinsamer Prompt für das Multi-Modell-Ensemble...",
                en: "Shared prompt for the multi-model ensemble...",
                fr: "Prompt partagé pour l'ensemble multi-modèles...",
                es: "Prompt compartido para el conjunto multimodelo...",
                pt: "Prompt partilhado para o conjunto multimodelo...",
                ru: "Общий промпт для ансамбля моделей...",
                ja: "マルチモデル・アンサンブル用の共通プロンプト...",
                zh: "用于多模型协同集成的共享提示词..."), text: $vm.mmmPromptInput)
                .textFieldStyle(.roundedBorder)

            if !vm.mmmStatusMessage.isEmpty {
                Text(vm.mmmStatusMessage)
                    .font(Font.caption)
                    .foregroundColor(vm.mmmLastResult == nil && !vm.simulateMacStudio ? SolarisTheme.amberGlow : SolarisTheme.emerald)
            }

            if let res = vm.mmmLastResult {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(res.isLiveExecution
                            ? L10n.tr(vm.language, de: "LIVE SSE ERGEBNIS", en: "LIVE SSE RESULT", fr: "RÉSULTAT SSE DIRECT", es: "RESULTADO SSE EN VIVO", pt: "RESULTADO SSE AO VIVO", ru: "LIVE SSE РЕЗУЛЬТАТ", ja: "ライブ SSE 結果", zh: "实时 SSE 结果")
                            : L10n.tr(vm.language, de: "SIMULATION", en: "SIMULATION", fr: "SIMULATION", es: "SIMULACIÓN", pt: "SIMULAÇÃO", ru: "СИМУЛЯЦИЯ", ja: "シミュレーション", zh: "模拟"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(res.isLiveExecution ? SolarisTheme.emerald : SolarisTheme.amber)
                            .cornerRadius(4)
                        Text("\(res.strategy.localizedTitle(vm.language)) · \(res.scope.localizedTitle(vm.language))")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        Text(String(format: "%.1f tok/s · TTFT %.1f ms · %.2fx", res.combinedTokPerSec, res.aggregateTtftMs, res.speedupFactor))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(SolarisTheme.mint)
                    }
                    Text(res.responsePreview)
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                .padding(10)
                .background(SolarisTheme.cardElevated)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - 5. Multi-IDE & Agent Harness Cluster Consumption

    private var multiIdeHarnessConsumptionCard: some View {
        SolarisCard(accent: SolarisTheme.mint) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr(vm.language,
                        de: "Multi-IDE & Agent-Harness Leistungsentnahme",
                        en: "Multi-IDE & Agent-Harness Performance Consumption",
                        fr: "Consommation multi-IDE & harnais d'agents",
                        es: "Consumo multi-IDE y arnés de agentes",
                        pt: "Consumo multi-IDE e harnesses de agentes",
                        ru: "Подключение Multi-IDE и агентских систем",
                        ja: "マルチ IDE・エージェントハーネス出力共有",
                        zh: "多 IDE 与智能体框架并发算力输出"))
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(L10n.tr(vm.language,
                        de: "Mehrere IDEs (Cursor, VS Code, Xcode) und Agent-Harnesses (OpenCode, Hermes, Antigravity) beziehen gleichzeitig über \(vm.openCodeBaseURL) Leistung aus dem zusammengeführten Verbund.",
                        en: "Multiple IDEs (Cursor, VS Code, Xcode) and agent harnesses (OpenCode, Hermes, Antigravity) simultaneously consume unified performance from the cluster via \(vm.openCodeBaseURL).",
                        fr: "Plusieurs IDE (Cursor, VS Code, Xcode) et agents (OpenCode, Hermes, Antigravity) consomment simultanément la puissance du cluster via \(vm.openCodeBaseURL).",
                        es: "Múltiples IDE (Cursor, VS Code, Xcode) y agentes (OpenCode, Hermes, Antigravity) consumen potencia simultáneamente vía \(vm.openCodeBaseURL).",
                        pt: "Vários IDEs (Cursor, VS Code, Xcode) e agentes (OpenCode, Hermes, Antigravity) consomem desempenho unificado em paralelo via \(vm.openCodeBaseURL).",
                        ru: "Несколько IDE (Cursor, VS Code, Xcode) и агентов (OpenCode, Hermes, Antigravity) одновременно получают мощность кластера через \(vm.openCodeBaseURL).",
                        ja: "複数の IDE (Cursor, VS Code, Xcode) やエージェント (OpenCode, Hermes, Antigravity) が \(vm.openCodeBaseURL) 経由で同時に推論能力を利用します。",
                        zh: "多个 IDE (Cursor、VS Code、Xcode) 与智能体框架 (OpenCode、Hermes、Antigravity) 可通过 \(vm.openCodeBaseURL) 并发共享聚合算力。"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                Button(L10n.tr(vm.language,
                    de: "Multi-IDE-Config kopieren",
                    en: "Copy Multi-IDE Config",
                    fr: "Copier config Multi-IDE",
                    es: "Copiar config Multi-IDE",
                    pt: "Copiar config Multi-IDE",
                    ru: "Копировать конфиг Multi-IDE",
                    ja: "マルチ IDE 設定をコピー",
                    zh: "复制多 IDE 配置")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(vm.exportMultiIdeMmmGatewayConfig(), forType: .string)
                    vm.mmmStatusMessage = L10n.tr(vm.language,
                        de: "Multi-IDE / MMM Gateway-Konfiguration in die Zwischenablage kopiert.",
                        en: "Multi-IDE / MMM Gateway configuration copied to clipboard.",
                        fr: "Configuration Multi-IDE / passerelle MMM copiée dans le presse-papiers.",
                        es: "Configuración Multi-IDE / pasarela MMM copiada al portapapeles.",
                        pt: "Configuração Multi-IDE / gateway MMM copiada para a área de transferência.",
                        ru: "Конфигурация Multi-IDE / шлюза MMM скопирована в буфер обмена.",
                        ja: "マルチ IDE / MMM ゲートウェイ設定をクリップボードにコピーしました。",
                        zh: "已将多 IDE / MMM 网关配置复制到剪贴板。")
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.mint)
                .foregroundColor(.black)
            }

            HStack(spacing: 16) {
                Stepper(L10n.tr(vm.language,
                    de: "Gleichzeitige IDEs / Harnesses: \(vm.mmmActiveClientCount)",
                    en: "Concurrent IDEs / Harnesses: \(vm.mmmActiveClientCount)",
                    fr: "IDE / Harnais simultanés : \(vm.mmmActiveClientCount)",
                    es: "IDE / Arneses simultáneos: \(vm.mmmActiveClientCount)",
                    pt: "IDEs / Harnesses simultâneos: \(vm.mmmActiveClientCount)",
                    ru: "Одновременных IDE / агентов: \(vm.mmmActiveClientCount)",
                    ja: "同時接続 IDE / ハーネス数: \(vm.mmmActiveClientCount)",
                    zh: "并发 IDE / 智能体数量：\(vm.mmmActiveClientCount)"), value: $vm.mmmActiveClientCount, in: 1...8)
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                Text(String(format: L10n.tr(vm.language,
                    de: "≈ %.1f tok/s pro aktivem Client",
                    en: "≈ %.1f tok/s per active client",
                    fr: "≈ %.1f tok/s par client actif",
                    es: "≈ %.1f tok/s por cliente activo",
                    pt: "≈ %.1f tok/s por cliente ativo",
                    ru: "≈ %.1f tok/с на активный клиент",
                    ja: "アクティブクライアントあたり ≈ %.1f tok/s",
                    zh: "每个活跃客户端 ≈ %.1f tok/s"), vm.mmmPerClientTokPerSec))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(SolarisTheme.amberGlow)
            }
            .padding(10)
            .background(SolarisTheme.cardElevated)
            .cornerRadius(10)
        }
    }

    private func mmmMetricTile(title: String, value: String, sub: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Font.caption)
                .foregroundColor(SolarisTheme.textSecondary)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(accent)
            Text(sub)
                .font(Font.caption2)
                .foregroundColor(SolarisTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SolarisTheme.cardElevated)
        .cornerRadius(10)
    }
}
