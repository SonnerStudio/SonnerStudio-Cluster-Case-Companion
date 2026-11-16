import SwiftUI
import AppKit

struct ClusterSetupView: View {
    @ObservedObject var vm: ClusterViewModel

    private var readinessColor: Color {
        switch vm.clusterReadinessState {
        case .ready: return SolarisTheme.emerald
        case .incomplete: return SolarisTheme.amber
        case .notReady: return SolarisTheme.coral
        case .unconfigured: return SolarisTheme.textSecondary
        }
    }

    private var readinessIcon: String {
        switch vm.clusterReadinessState {
        case .ready: return "checkmark.seal.fill"
        case .incomplete: return "exclamationmark.triangle.fill"
        case .notReady: return "xmark.octagon.fill"
        case .unconfigured: return "questionmark.diamond.fill"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                readinessStatusBannerCard
                setupVariantAndDiscoveryCard
                discoveredTargetsCard
                readinessVerificationCard
            }
            .padding(24)
        }
        .onAppear {
            vm.discoverClusterSetupTargets()
            vm.verifyClusterReadiness()
        }
        .onChange(of: vm.simulateMacStudio) { _, _ in
            vm.discoverClusterSetupTargets()
            vm.verifyClusterReadiness()
        }
    }

    // MARK: - 1. Prominent Readiness Status Banner

    private var readinessStatusBannerCard: some View {
        SolarisCard(accent: readinessColor) {
            HazardStripesBar(height: 5, stripeWidth: 10, cornerRadius: 3, opacity: 0.85)

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: readinessIcon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(readinessColor)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(vm.t("setup_title"))
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)

                        Text(vm.currentReadinessLabel.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(readinessColor)
                            .cornerRadius(6)
                    }

                    Text(vm.t("setup_sub"))
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)

                    if !vm.setupStatusMessage.isEmpty {
                        Text("\(vm.setupStatusMessage) (\(L10n.text("ov_last_check", vm.language)): \(vm.lastReadinessCheckedAt))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(readinessColor)
                    }
                }

                Spacer()
            }
        }
        .solarisShorttip(vm.shorttip(.setup), id: "setup_banner", vm: vm)
    }

    // MARK: - 2. Cluster Variant Selection & 1-Click Auto-Setup

    private var setupVariantAndDiscoveryCard: some View {
        SolarisCard(accent: SolarisTheme.amber) {
            Text(L10n.tr(vm.language,
                de: "1. Verbund-Variante wählen & Automatisch Einrichten",
                en: "1. Choose Cluster Variant & Auto-Configure",
                fr: "1. Choisir le type de grappe & configurer automatiquement",
                es: "1. Elegir variante de clúster y configurar automáticamente",
                pt: "1. Escolher variante do cluster e configurar automaticamente",
                ru: "1. Выбрать тип кластера и настроить автоматически",
                ja: "1. クラスタ方式の選択と自動セットアップ",
                zh: "1. 选择集群模式并自动配置"))
                .font(SolarisTheme.cardTitle)
                .foregroundColor(SolarisTheme.textPrimary)

            Picker(L10n.tr(vm.language,
                de: "Verbund-Variante",
                en: "Cluster Variant",
                fr: "Type de grappe",
                es: "Variante de clúster",
                pt: "Variante do cluster",
                ru: "Тип кластера",
                ja: "クラスタ方式",
                zh: "集群模式"), selection: $vm.clusterSetupVariant) {
                ForEach(ClusterSetupVariant.allCases) { variant in
                    Text(variant.localizedTitle(vm.language)).tag(variant)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.clusterSetupVariant) { _, _ in
                vm.discoverClusterSetupTargets()
                vm.verifyClusterReadiness()
            }
            .solarisShorttip(L10n.tr(vm.language,
                de: "Wähle Lokal (TB/RDMA), Internet-WAN (QUIC/Iroh/Tailscale) oder Hybrid (Lokal + Internet).",
                en: "Select Local (TB/RDMA), Internet WAN (QUIC/Iroh/Tailscale), or Hybrid (Local + Internet).",
                fr: "Choisissez Local (TB/RDMA), Internet WAN (QUIC/Iroh/Tailscale) ou Hybride (Local + Internet).",
                es: "Elige Local (TB/RDMA), Internet WAN (QUIC/Iroh/Tailscale) o Híbrido (Local + Internet).",
                pt: "Escolha Local (TB/RDMA), Internet WAN (QUIC/Iroh/Tailscale) ou Híbrido (Local + Internet).",
                ru: "Выберите: Локальный (TB/RDMA), Интернет WAN (QUIC/Iroh/Tailscale) или Гибридный.",
                ja: "ローカル (TB/RDMA)、インターネットWAN (QUIC/Iroh/Tailscale)、ハイブリッドから選択します。",
                zh: "选择本地 (TB/RDMA)、互联网 WAN (QUIC/Iroh/Tailscale) 或混合（本地 + 互联网）。"), id: "setup_variant_picker", vm: vm)

            HStack(spacing: 12) {
                Button {
                    vm.discoverClusterSetupTargets()
                } label: {
                    Label(L10n.tr(vm.language,
                        de: "Macs im Verbund suchen (Bonjour / WAN)",
                        en: "Discover Cluster Macs (Bonjour / WAN)",
                        fr: "Rechercher les Macs (Bonjour / WAN)",
                        es: "Buscar Macs en el clúster (Bonjour / WAN)",
                        pt: "Procurar Macs no cluster (Bonjour / WAN)",
                        ru: "Найти Mac в кластере (Bonjour / WAN)",
                        ja: "クラスタ内Macを検索 (Bonjour / WAN)",
                        zh: "搜索集群 Mac (Bonjour / WAN)"), systemImage: "magnifyingglass.circle.fill")
                }
                .buttonStyle(.bordered)
                .solarisShorttip(L10n.tr(vm.language,
                    de: "Scannt per Bonjour/mDNS, Thunderbolt, LAN und WAN-Peers nach verfügbaren Apple-Silicon-Macs.",
                    en: "Scans Bonjour/mDNS, Thunderbolt, LAN, and WAN peers for available Apple Silicon Macs.",
                    fr: "Analyse Bonjour/mDNS, Thunderbolt, LAN et pairs WAN pour trouver les Macs Apple Silicon.",
                    es: "Escanea Bonjour/mDNS, Thunderbolt, LAN y pares WAN para encontrar Macs Apple Silicon.",
                    pt: "Pesquisa Bonjour/mDNS, Thunderbolt, LAN e pares WAN por Macs Apple Silicon disponíveis.",
                    ru: "Сканирует Bonjour/mDNS, Thunderbolt, LAN и WAN для поиска доступных Mac.",
                    ja: "Bonjour/mDNS、Thunderbolt、LAN、WANピアから利用可能なAppleシリコンMacを検出します。",
                    zh: "通过 Bonjour/mDNS、Thunderbolt、局域网与广域网节点扫描可用的 Apple Silicon Mac。"), id: "setup_discover_btn", vm: vm)

                Button {
                    vm.runAutomaticClusterSetup()
                } label: {
                    Label(
                        vm.isRunningClusterSetup
                            ? L10n.tr(vm.language,
                                de: "Richte Verbund ein...",
                                en: "Setting up cluster...",
                                fr: "Configuration en cours...",
                                es: "Configurando clúster...",
                                pt: "Configurando cluster...",
                                ru: "Настройка кластера...",
                                ja: "セットアップ中...",
                                zh: "正在配置集群...")
                            : L10n.tr(vm.language,
                                de: "Verbund auf allen Macs automatisch einrichten",
                                en: "Auto-Configure Cluster on All Macs",
                                fr: "Configurer automatiquement sur tous les Macs",
                                es: "Configurar automáticamente en todos los Macs",
                                pt: "Configurar automaticamente em todos os Macs",
                                ru: "Автоматически настроить кластер на всех Mac",
                                ja: "全Macでクラスタを自動構成",
                                zh: "在所有 Mac 上自动配置集群"),
                        systemImage: "wand.and.stars"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.amber)
                .foregroundColor(.black)
                .disabled(vm.isRunningClusterSetup)
                .solarisShorttip(L10n.tr(vm.language,
                    de: "Konfiguriert SSH-Trust, iogpu.wired_limit_mb, mlx.distributed_config und Scope-Kopplung auf allen gewählten Macs.",
                    en: "Configures SSH trust, iogpu.wired_limit_mb, mlx.distributed_config, and scope coupling on all selected Macs.",
                    fr: "Configure SSH, iogpu.wired_limit_mb, mlx.distributed_config et le couplage sur tous les Macs.",
                    es: "Configura confianza SSH, iogpu.wired_limit_mb, mlx.distributed_config y alcance en los Macs.",
                    pt: "Configura confiança SSH, iogpu.wired_limit_mb, mlx.distributed_config e escopo nos Macs.",
                    ru: "Настраивает SSH-доверие, iogpu.wired_limit_mb, mlx.distributed_config и связку на всех Mac.",
                    ja: "選択した全MacでSSH信頼、iogpu.wired_limit_mb、mlx.distributed_config、スコープ結合を設定します。",
                    zh: "为所选 Mac 自动配置 SSH 互信、iogpu.wired_limit_mb、mlx.distributed_config 与作用域耦合。"), id: "setup_run_btn", vm: vm)

                Button {
                    vm.verifyClusterReadiness()
                } label: {
                    Label(
                        vm.isVerifyingReadiness
                            ? L10n.tr(vm.language,
                                de: "Prüfe...",
                                en: "Checking...",
                                fr: "Vérification...",
                                es: "Verificando...",
                                pt: "Verificando...",
                                ru: "Проверка...",
                                ja: "確認中...",
                                zh: "检查中...")
                            : L10n.tr(vm.language,
                                de: "Betriebsbereitschaft prüfen",
                                en: "Verify Readiness",
                                fr: "Vérifier l'état de préparation",
                                es: "Verificar operatividad",
                                pt: "Verificar prontidão",
                                ru: "Проверить готовность",
                                ja: "稼働準備を確認",
                                zh: "检查就绪状态"),
                        systemImage: "checklist.checked"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.emerald)
                .foregroundColor(.black)
                .disabled(vm.isVerifyingReadiness)
                .solarisShorttip(L10n.tr(vm.language,
                    de: "Prüft Discovery, SSH, Thunderbolt/RDMA/WAN-Links, Speicherschutz und API-Gateway auf Betriebsbereitschaft.",
                    en: "Verifies discovery, SSH, Thunderbolt/RDMA/WAN links, memory guard, and API gateway readiness.",
                    fr: "Vérifie la découverte, SSH, les liens TB/RDMA/WAN, la garde mémoire et la passerelle API.",
                    es: "Comprueba descubrimiento, SSH, enlaces TB/RDMA/WAN, guardia de memoria y pasarela API.",
                    pt: "Verifica descoberta, SSH, links TB/RDMA/WAN, proteção de memória e gateway API.",
                    ru: "Проверяет обнаружение, SSH, каналы TB/RDMA/WAN, защиту памяти и готовность API.",
                    ja: "検出、SSH、Thunderbolt/RDMA/WANリンク、メモリ保護、APIゲートウェイの稼働準備を確認します。",
                    zh: "检测节点发现、SSH、TB/RDMA/WAN 链路、显存保护与 API 网关就绪状态。"), id: "setup_verify_btn", vm: vm)
            }
        }
    }

    // MARK: - 3. Discovered Cluster Nodes Table

    private var discoveredTargetsCard: some View {
        SolarisCard(accent: SolarisTheme.mint) {
            HStack {
                Label(L10n.tr(vm.language,
                    de: "2. Erkannte Macs & Einrichtungsstatus (\(vm.discoveredProvisionTargets.count))",
                    en: "2. Discovered Macs & Setup Status (\(vm.discoveredProvisionTargets.count))",
                    fr: "2. Macs détectés & état de configuration (\(vm.discoveredProvisionTargets.count))",
                    es: "2. Macs detectados y estado de configuración (\(vm.discoveredProvisionTargets.count))",
                    pt: "2. Macs detetados e estado de configuração (\(vm.discoveredProvisionTargets.count))",
                    ru: "2. Обнаруженные Mac и статус настройки (\(vm.discoveredProvisionTargets.count))",
                    ja: "2. 検出されたMacとセットアップ状態 (\(vm.discoveredProvisionTargets.count))",
                    zh: "2. 已发现的 Mac 与配置状态 (\(vm.discoveredProvisionTargets.count))"), systemImage: "macstudio.fill")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.mint)
                Spacer()
                Button(L10n.tr(vm.language,
                    de: "mlx.distributed_config kopieren",
                    en: "Copy mlx.distributed_config",
                    fr: "Copier mlx.distributed_config",
                    es: "Copiar mlx.distributed_config",
                    pt: "Copiar mlx.distributed_config",
                    ru: "Копировать mlx.distributed_config",
                    ja: "mlx.distributed_config をコピー",
                    zh: "复制 mlx.distributed_config")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(vm.generateMlxDistributedHostfileJSON(), forType: .string)
                    vm.setupStatusMessage = L10n.tr(vm.language,
                        de: "mlx.distributed_config Hostfile JSON in Zwischenablage kopiert.",
                        en: "Copied mlx.distributed_config hostfile JSON to clipboard.",
                        fr: "JSON mlx.distributed_config copié dans le presse-papiers.",
                        es: "JSON hostfile mlx.distributed_config copiado al portapapeles.",
                        pt: "JSON hostfile mlx.distributed_config copiado para a área de transferência.",
                        ru: "JSON hostfile mlx.distributed_config скопирован в буфер обмена.",
                        ja: "mlx.distributed_config ホストファイル JSON をクリップボードにコピーしました。",
                        zh: "已将 mlx.distributed_config 主机列表 JSON 复制到剪贴板。")
                }
                .buttonStyle(.bordered)
                .solarisShorttip(L10n.tr(vm.language,
                    de: "Kopiert die automatisch erzeugte mlx.distributed_config (JACCL/Ring) für alle erkannten Macs.",
                    en: "Copies the auto-generated mlx.distributed_config (JACCL/Ring) for all discovered Macs.",
                    fr: "Copie le fichier mlx.distributed_config (JACCL/Ring) généré pour tous les Macs détectés.",
                    es: "Copia el archivo mlx.distributed_config (JACCL/Ring) generado para los Macs detectados.",
                    pt: "Copia o mlx.distributed_config (JACCL/Ring) gerado para todos os Macs detetados.",
                    ru: "Копирует автоматически созданный mlx.distributed_config (JACCL/Ring) для всех найденных Mac.",
                    ja: "検出された全Mac向けに自動生成された mlx.distributed_config (JACCL/Ring) をコピーします。",
                    zh: "复制为所有已发现 Mac 自动生成的 mlx.distributed_config (JACCL/Ring) 配置。"), id: "setup_copy_hostfile", vm: vm)
            }

            if vm.discoveredProvisionTargets.isEmpty {
                Text(L10n.tr(vm.language,
                    de: "Noch keine Ziel-Macs erkannt. Klicke auf 'Macs im Verbund suchen'.",
                    en: "No target Macs discovered yet. Click 'Discover Cluster Macs'.",
                    fr: "Aucun Mac cible détecté pour l'instant. Cliquez sur « Rechercher les Macs ».",
                    es: "Aún no hay Macs detectados. Haz clic en «Buscar Macs en el clúster».",
                    pt: "Nenhum Mac alvo detetado ainda. Clique em 'Procurar Macs no cluster'.",
                    ru: "Целевые Mac ещё не найдены. Нажмите «Найти Mac в кластере».",
                    ja: "対象Macがまだ検出されていません。「クラスタ内Macを検索」をクリックしてください。",
                    zh: "尚未发现目标 Mac，请点击“搜索集群 Mac”。"))
                    .font(SolarisTheme.bodyLarge)
                    .foregroundColor(SolarisTheme.textSecondary)
            } else {
                ForEach($vm.discoveredProvisionTargets) { $target in
                    HStack(spacing: 12) {
                        Toggle("", isOn: $target.isSelected)
                            .labelsHidden()
                            .toggleStyle(.checkbox)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.hostname)
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("\(target.chipLabel) · \(target.address) · \(target.transport)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(SolarisTheme.textSecondary)
                        }

                        Spacer()

                        statusPill("SSH", ok: target.sshTrusted)
                        statusPill(L10n.tr(vm.language, de: "VRAM-Schutz", en: "VRAM Guard", fr: "Garde VRAM", es: "Guardia VRAM", pt: "Guarda VRAM", ru: "Защита VRAM", ja: "VRAM保護", zh: "显存保护"), ok: target.wiredLimitConfigured)
                        statusPill(L10n.tr(vm.language, de: "Verbindung", en: "Link", fr: "Lien", es: "Enlace", pt: "Ligação", ru: "Связь", ja: "リンク", zh: "链路"), ok: target.rdmaOrWanReady)

                        Text(String(format: "%.0f GB", target.usableVramGB))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(SolarisTheme.amberGlow)
                            .frame(width: 56, alignment: .trailing)
                    }
                    .padding(10)
                    .background(SolarisTheme.cardElevated)
                    .cornerRadius(8)
                    .solarisShorttip(L10n.tr(vm.language,
                        de: "Knoten \(target.hostname) (\(target.address)) — zeigt SSH-Vertrauen, Speicherschutz und Link-Bereitschaft.",
                        en: "Node \(target.hostname) (\(target.address)) — shows SSH trust, memory guard, and link readiness.",
                        fr: "Nœud \(target.hostname) (\(target.address)) — confiance SSH, garde mémoire et état du lien.",
                        es: "Nodo \(target.hostname) (\(target.address)) — muestra confianza SSH, guardia de memoria y estado del enlace.",
                        pt: "Nó \(target.hostname) (\(target.address)) — mostra confiança SSH, proteção de memória e prontidão de ligação.",
                        ru: "Узел \(target.hostname) (\(target.address)) — доверие SSH, защита памяти и готовность канала.",
                        ja: "ノード \(target.hostname) (\(target.address)) — SSH信頼、メモリ保護、リンク状態を表示します。",
                        zh: "节点 \(target.hostname) (\(target.address)) — 显示 SSH 互信、显存保护与链路就绪状态。"), id: "setup_node_\(target.id)", vm: vm)
                }
            }
        }
    }

    // MARK: - 4. Readiness Verification Checklist

    private var readinessVerificationCard: some View {
        SolarisCard(accent: readinessColor) {
            HStack {
                Label(L10n.tr(vm.language,
                    de: "3. Prüf-Protokoll & Betriebsbereitschaft",
                    en: "3. Verification Log & Operational Readiness",
                    fr: "3. Journal de vérification & état opérationnel",
                    es: "3. Registro de verificación y operatividad",
                    pt: "3. Registo de verificação e prontidão operacional",
                    ru: "3. Журнал проверки и готовность к работе",
                    ja: "3. 検証ログと稼働準備状況",
                    zh: "3. 验证日志与运行就绪状态"), systemImage: "shield.checkered")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(readinessColor)
                Spacer()
                Text(vm.currentReadinessLabel)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(readinessColor)
            }

            ForEach(vm.clusterReadinessChecks) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.status == .pass ? "checkmark.circle.fill" : (item.status == .warn ? "exclamationmark.triangle.fill" : "xmark.circle.fill"))
                        .foregroundColor(item.status == .pass ? SolarisTheme.emerald : (item.status == .warn ? SolarisTheme.amber : SolarisTheme.coral))
                        .font(.system(size: 16, weight: .bold))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        if item.status != .pass {
                            Text(L10n.tr(vm.language,
                                de: "Empfehlung: \(item.remediation)",
                                en: "Recommendation: \(item.remediation)",
                                fr: "Recommandation : \(item.remediation)",
                                es: "Recomendación: \(item.remediation)",
                                pt: "Recomendação: \(item.remediation)",
                                ru: "Рекомендация: \(item.remediation)",
                                ja: "推奨対応: \(item.remediation)",
                                zh: "建议操作：\(item.remediation)"))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(SolarisTheme.amberGlow)
                        }
                    }

                    Spacer()
                }
                .padding(10)
                .background(SolarisTheme.cardElevated)
                .cornerRadius(8)
                .solarisShorttip("\(item.title): \(item.detail)", id: "setup_chk_\(item.id)", vm: vm)
            }
        }
    }

    private func statusPill(_ title: String, ok: Bool) -> some View {
        Text(ok ? "\(title) ✓" : "\(title) ✗")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(ok ? SolarisTheme.emerald : SolarisTheme.amber)
            .cornerRadius(5)
    }
}
