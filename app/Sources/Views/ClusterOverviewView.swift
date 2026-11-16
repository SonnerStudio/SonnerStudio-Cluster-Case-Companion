import SwiftUI

struct ClusterOverviewView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Große 3-Reiter-Auswahl mit industrieller gelb-schwarzer Warnbereichsmarkierung
                scopeSelectorCard

                // Betriebsbereitschafts-Zustand direkt in der Verbund-Übersicht
                readinessStatusOverviewCard

                switch vm.overviewScope {
                case .local:
                    localClusterContent
                case .internet:
                    internetClusterContent
                case .hybrid:
                    hybridClusterContent
                }
            }
            .padding(24)
        }
        .onAppear {
            vm.verifyClusterReadiness()
        }
    }

    // MARK: - 3 Große Reiter / Buttons + Gelb-Schwarze Industrie-Warnstreifen

    private var scopeSelectorCard: some View {
        VStack(spacing: 0) {
            HazardStripesBar(height: 8, stripeWidth: 11, cornerRadius: 0, opacity: 0.94)

            HStack(spacing: 14) {
                ForEach(ClusterOverviewScope.allCases) { scope in
                    let isSelected = vm.overviewScope == scope
                    let scopeGlowKey = "overview_\(scope.rawValue)"
                    let isHovered = vm.hoveredGlowId == scopeGlowKey
                    let meta = scopeMetadata(for: scope)

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            vm.overviewScope = scope
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? meta.accent.opacity(0.24) : Color.white.opacity(0.06))
                                    .frame(width: 44, height: 44)
                                Image(systemName: scope.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(isSelected ? meta.accent : SolarisTheme.textSecondary)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(meta.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(isSelected ? SolarisTheme.textPrimary : SolarisTheme.textSecondary)
                                    .lineLimit(1)
                                Text(meta.subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(SolarisTheme.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 4)

                            Text(meta.badge)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? meta.accent : Color.white.opacity(0.08))
                                )
                                .foregroundColor(isSelected ? .black : SolarisTheme.textPrimary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? meta.accent.opacity(0.14) : SolarisTheme.cardElevated.opacity(0.72))
                        )
                        .solarisHighlightGlow(accent: meta.accent, isActive: isSelected, isHovered: isHovered, cornerRadius: 14)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            vm.hoveredGlowId = hovering ? scopeGlowKey : (vm.hoveredGlowId == scopeGlowKey ? nil : vm.hoveredGlowId)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(SolarisTheme.cardBg.opacity(0.92))

            HazardStripesBar(height: 6, stripeWidth: 11, cornerRadius: 0, opacity: 0.86)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SolarisTheme.amber.opacity(0.42), lineWidth: 1.2)
        )
    }

    private var readinessStatusOverviewCard: some View {
        let stateColor: Color = {
            switch vm.clusterReadinessState {
            case .ready: return SolarisTheme.emerald
            case .incomplete: return SolarisTheme.amber
            case .notReady: return SolarisTheme.coral
            case .unconfigured: return SolarisTheme.textSecondary
            }
        }()
        let stateIcon: String = {
            switch vm.clusterReadinessState {
            case .ready: return "checkmark.seal.fill"
            case .incomplete: return "exclamationmark.triangle.fill"
            case .notReady: return "xmark.octagon.fill"
            case .unconfigured: return "questionmark.diamond.fill"
            }
        }()

        return SolarisCard(accent: stateColor) {
            HStack(spacing: 12) {
                Image(systemName: stateIcon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(stateColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(vm.t("setup_title"))
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(vm.currentReadinessLabel.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(stateColor)
                            .cornerRadius(5)
                    }
                    Text("\(vm.clusterSetupVariant.localizedTitle(vm.language)) · \(vm.t("ov_last_check")): \(vm.lastReadinessCheckedAt)")
                        .font(.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }

                Spacer()

                Button {
                    vm.verifyClusterReadiness()
                } label: {
                    Label(vm.t("ov_verify_btn"), systemImage: "checklist.checked")
                }
                .buttonStyle(.bordered)
                .solarisShorttip(
                    vm.tr(
                        de: "Prüft Discovery, SSH, Thunderbolt/WAN-Links, VRAM-Schutz und API-Gateway.",
                        en: "Checks Discovery, SSH, Thunderbolt/WAN links, VRAM Guard, and API Gateway.",
                        fr: "Vérifie découverte, SSH, liaisons TB/WAN, garde VRAM et passerelle API.",
                        es: "Comprueba descubrimiento, SSH, enlaces TB/WAN, VRAM Guard y pasarela API.",
                        pt: "Verifica descoberta, SSH, ligações TB/WAN, VRAM Guard e gateway API.",
                        ru: "Проверяет поиск узлов, SSH, каналы TB/WAN, защиту VRAM и API-шлюз.",
                        ja: "検出・SSH・TB/WANリンク・VRAM保護・APIゲートウェイを確認します。",
                        zh: "检查节点发现、SSH 互信、TB/WAN 链路、显存保护与 API 网关。"
                    ),
                    id: "ov_verify_btn",
                    vm: vm
                )

                Button {
                    vm.selectedTab = .setup
                } label: {
                    Label(vm.t("ov_open_setup_btn"), systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .tint(stateColor)
                .foregroundColor(.black)
                .solarisShorttip(vm.shorttip(.setup), id: "ov_open_setup_btn", vm: vm)
            }
        }
        .solarisShorttip(
            vm.tr(
                de: "Aktueller Betriebszustand des Verbunds (Bereit / Nicht bereit / Unvollständig / Uneingerichtet).",
                en: "Current cluster operational readiness (Ready / Not Ready / Partially Configured / Unconfigured).",
                fr: "État opérationnel actuel de la grappe (Prêt / Non prêt / Incomplet / Non configuré).",
                es: "Estado operativo actual del clúster (Listo / No listo / Incompleto / Sin configurar).",
                pt: "Estado operacional atual do cluster (Pronto / Não pronto / Incompleto / Não configurado).",
                ru: "Текущая готовность кластера (Готов / Не готов / Не полностью / Не настроен).",
                ja: "クラスターの現在の稼働準備状態（稼働可能 / 未準備 / 一部未完了 / 未設定）。",
                zh: "集群当前运行就绪状态（就绪 / 未就绪 / 配置不完整 / 未配置）。"
            ),
            id: "ov_readiness_card",
            vm: vm
        )
    }

    private func scopeMetadata(for scope: ClusterOverviewScope) -> (title: String, subtitle: String, badge: String, accent: Color) {
        switch scope {
        case .local:
            return (
                vm.t("ov_tab_local"),
                vm.t("ov_tab_local_sub"),
                "\(vm.nodes.count) · \(Int(vm.totalPhysicalRamGB)) GB",
                SolarisTheme.amber
            )
        case .internet:
            let count = vm.wanPeers.count
            let ram = Int(vm.wanTotalRamGB)
            return (
                vm.t("ov_tab_internet"),
                vm.t("ov_tab_internet_sub"),
                "\(count) · \(ram) GB",
                SolarisTheme.mint
            )
        case .hybrid:
            return (
                vm.t("ov_tab_hybrid"),
                vm.t("ov_tab_hybrid_sub"),
                "\(vm.hybridCombinedNodeCount) · \(Int(vm.hybridCombinedRamGB)) GB",
                SolarisTheme.emerald
            )
        }
    }

    // MARK: - Reiter 1: Lokaler Cluster (Thunderbolt / LAN)

    private var localClusterContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 16) {
                MetricTile(
                    title: vm.t("kpi_memory"),
                    value: "\(Int(vm.totalPhysicalRamGB)) GB",
                    subtitle: String(format: vm.t("kpi_memory_sub"), Int(vm.totalUsableVramGB)),
                    accent: SolarisTheme.amber,
                    icon: "memorychip.fill"
                )
                MetricTile(
                    title: vm.t("kpi_nodes"),
                    value: "\(vm.nodes.count)",
                    subtitle: vm.nodes.map(\.name).joined(separator: " + "),
                    accent: SolarisTheme.mint,
                    icon: "desktopcomputer"
                )
                MetricTile(
                    title: vm.t("kpi_link"),
                    value: vm.effectiveLinkStats.rangeLabel,
                    subtitle: vm.activeLinkHeadline,
                    accent: SolarisTheme.emerald,
                    icon: "bolt.fill"
                )
            }

            SolarisCard(accent: SolarisTheme.amber) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.t("topo_title"))
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(vm.t("topo_sub"))
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                    Spacer()
                    Label(
                        String(
                            format: vm.t(vm.nodes.count > 1 ? "ov_cluster_active" : "ov_standalone_mode"),
                            Int(vm.totalPhysicalRamGB)
                        ),
                        systemImage: vm.nodes.count > 1 ? "link.circle.fill" : "circle.dashed"
                    )
                    .font(SolarisTheme.bodyBold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(SolarisTheme.amber.opacity(0.18)))
                    .foregroundColor(SolarisTheme.amberGlow)
                }

                HStack(spacing: 20) {
                    ForEach(Array(vm.nodes.enumerated()), id: \.element.id) { index, node in
                        NodeCardView(node: node, lang: vm.language)

                        if index < vm.nodes.count - 1 {
                            LinkBridgeConnector(
                                leftGen: node.thunderboltGen,
                                rightGen: vm.nodes[index + 1].thunderboltGen,
                                mode: vm.transportMode
                            )
                        }
                    }
                }
                .padding(.top, 8)
            }

            localMemoryPoolCard
        }
    }

    private var localMemoryPoolCard: some View {
        SolarisCard {
            HStack {
                Text(vm.t("pool_bar_title"))
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                Text(
                    String(
                        format: vm.t("ov_ai_os_split"),
                        Int(vm.totalUsableVramGB),
                        Int(vm.totalPhysicalRamGB - vm.totalUsableVramGB)
                    )
                )
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
            }

            GeometryReader { geo in
                let total = max(vm.totalPhysicalRamGB, 1)
                let palette: [Color] = [SolarisTheme.amber, SolarisTheme.mint, SolarisTheme.emerald, Color.cyan, Color.purple]
                HStack(spacing: 4) {
                    ForEach(Array(vm.nodes.enumerated()), id: \.element.id) { idx, node in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(palette[idx % palette.count])
                            .frame(width: max(42, geo.size.width * (node.usableVramGB / total) - 4))
                            .overlay(
                                Text("\(node.name): \(Int(node.usableVramGB)) GB")
                                    .font(SolarisTheme.bodyBold)
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .padding(.horizontal, 4)
                            )
                    }
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            Text(vm.t("node_os_short"))
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(SolarisTheme.textSecondary)
                        )
                }
            }
            .frame(height: 40)

            IndustrialHazardBanner(
                icon: "shield.lefthalf.filled",
                title: vm.t("ov_guard_zone"),
                subtitle: vm.t("pool_bar_note"),
                accent: SolarisTheme.amber
            )
        }
    }

    // MARK: - Reiter 2: Internet-Cluster (mit untergliederten lokalen Clusterverbünden)

    private var internetClusterContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 16) {
                MetricTile(
                    title: vm.tr(de: "WAN Speicherpool", en: "WAN Memory Pool", fr: "Pool mémoire WAN", es: "Pool de memoria WAN", pt: "Pool de memória WAN", ru: "Пул памяти WAN", ja: "WAN メモリプール", zh: "WAN 内存池"),
                    value: "\(Int(vm.wanTotalRamGB)) GB",
                    subtitle: vm.tr(de: "\(Int(vm.wanTotalUsableVramGB)) GB nutzbar über \(vm.wanPeers.count) Knoten", en: "\(Int(vm.wanTotalUsableVramGB)) GB usable across \(vm.wanPeers.count) node(s)", fr: "\(Int(vm.wanTotalUsableVramGB)) Go utilisables sur \(vm.wanPeers.count) nœud(s)", es: "\(Int(vm.wanTotalUsableVramGB)) GB útiles en \(vm.wanPeers.count) nodo(s)", pt: "\(Int(vm.wanTotalUsableVramGB)) GB úteis em \(vm.wanPeers.count) nó(s)", ru: "\(Int(vm.wanTotalUsableVramGB)) ГБ доступно на \(vm.wanPeers.count) узл.", ja: "\(vm.wanPeers.count) ノードで \(Int(vm.wanTotalUsableVramGB)) GB 利用可能", zh: "跨越 \(vm.wanPeers.count) 个节点 · \(Int(vm.wanTotalUsableVramGB)) GB 可用"),
                    accent: SolarisTheme.mint,
                    icon: "globe.americas.fill"
                )
                MetricTile(
                    title: vm.tr(de: "Teilverbünde & Knoten", en: "Subclusters & Nodes", fr: "Sous-grappes & Nœuds", es: "Subclústeres y nodos", pt: "Subclusters e nós", ru: "Подкластеры и узлы", ja: "部分クラスターとノード", zh: "子集群与节点"),
                    value: "\(vm.wanSubclustersByRegion.count + (vm.wanLocalIslandPeers.isEmpty ? 0 : 1))",
                    subtitle: vm.tr(de: "\(vm.wanLocalIslandPeers.count) lokal gekoppelt · \(vm.wanRemotePeers.count) WAN-Peers", en: "\(vm.wanLocalIslandPeers.count) locally coupled · \(vm.wanRemotePeers.count) WAN peer(s)", fr: "\(vm.wanLocalIslandPeers.count) couplés locaux · \(vm.wanRemotePeers.count) pair(s) WAN", es: "\(vm.wanLocalIslandPeers.count) acoplados locales · \(vm.wanRemotePeers.count) par(es) WAN", pt: "\(vm.wanLocalIslandPeers.count) acoplados locais · \(vm.wanRemotePeers.count) par(es) WAN", ru: "\(vm.wanLocalIslandPeers.count) локально · \(vm.wanRemotePeers.count) WAN-узлов", ja: "ローカル連携 \(vm.wanLocalIslandPeers.count) · WANピア \(vm.wanRemotePeers.count)", zh: "本地耦合 \(vm.wanLocalIslandPeers.count) · WAN 节点 \(vm.wanRemotePeers.count)"),
                    accent: SolarisTheme.amber,
                    icon: "network"
                )
                MetricTile(
                    title: vm.tr(de: "WAN Transport & RTT", en: "WAN Transport & RTT", fr: "Transport WAN & RTT", es: "Transporte WAN y RTT", pt: "Transporte WAN e RTT", ru: "Транспорт WAN и RTT", ja: "WAN 転送・RTT", zh: "WAN 传输与 RTT"),
                    value: "\(Int(vm.wanTotalRttMs)) ms",
                    subtitle: vm.wanTransport.localizedTitle(vm.language),
                    accent: SolarisTheme.emerald,
                    icon: "antenna.radiowaves.left.and.right"
                )
            }

            // Gekoppelter lokaler Clusterverbund im Internet-Mesh (falls verfügbar)
            if !vm.wanLocalIslandPeers.isEmpty || vm.isLocalClusterCoupledWithWan {
                SolarisCard(accent: SolarisTheme.amber) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.tr(de: "Untergliederter lokaler Clusterverbund (Tier-0 Insel)", en: "Coupled Local Cluster Island (Tier-0)", fr: "Îlot de grappe locale couplée (Tier-0)", es: "Isla de clúster local acoplado (Tier-0)", pt: "Ilha de cluster local acoplado (Tier-0)", ru: "Присоединённый локальный подкластер (Tier-0)", ja: "結合済みローカルクラスター島 (Tier-0)", zh: "耦合本地集群岛 (Tier-0)"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.tr(de: "Lokale Thunderbolt/LAN-Rechner, die als schneller Rang-0-Kern im Internet-Cluster mitwirken.", en: "Local Thunderbolt/LAN Macs operating as a high-speed Rank-0 core inside the Internet cluster.", fr: "Mac locaux Thunderbolt/LAN agissant comme cœur rapide Rang-0 dans la grappe Internet.", es: "Macs locales Thunderbolt/LAN que operan como núcleo rápido Rango-0 en el clúster Internet.", pt: "Macs locais Thunderbolt/LAN a operar como núcleo rápido Ranque-0 no cluster Internet.", ru: "Локальные Mac (TB/LAN), работающие быстрым ядром Ранг-0 в Интернет-кластере.", ja: "インターネットクラスター内で高速 Rank-0 コアとして機能するローカル TB/LAN マシン群。", zh: "在互联网集群中作为高速 Rank-0 核心协同工作的本地 Thunderbolt/LAN Mac 节点。"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Label(
                            vm.tr(
                                de: "\(vm.wanLocalIslandPeers.count) Knoten · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) GB",
                                en: "\(vm.wanLocalIslandPeers.count) Nodes · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) GB",
                                fr: "\(vm.wanLocalIslandPeers.count) Nœuds · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) Go",
                                es: "\(vm.wanLocalIslandPeers.count) Nodos · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) GB",
                                pt: "\(vm.wanLocalIslandPeers.count) Nós · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) GB",
                                ru: "\(vm.wanLocalIslandPeers.count) узл. · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) ГБ",
                                ja: "\(vm.wanLocalIslandPeers.count) ノード · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) GB",
                                zh: "\(vm.wanLocalIslandPeers.count) 节点 · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) GB"
                            ),
                            systemImage: "bolt.horizontal.circle.fill"
                        )
                            .font(SolarisTheme.bodyBold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(SolarisTheme.amber.opacity(0.20)))
                            .foregroundColor(SolarisTheme.amberGlow)
                    }

                    HazardStripesBar(height: 5, stripeWidth: 9, cornerRadius: 3, opacity: 0.85)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                        ForEach(vm.wanLocalIslandPeers) { peer in
                            WanPeerMiniCard(peer: peer, accent: SolarisTheme.amber)
                        }
                    }
                }
            }

            // Untergliederte regionale Internet-Clusterverbünde
            if vm.wanRemotePeers.isEmpty {
                SolarisCard(accent: SolarisTheme.mint) {
                    HStack(spacing: 14) {
                        Image(systemName: "globe.europe.africa.fill")
                            .font(.system(size: 32))
                            .foregroundColor(SolarisTheme.mint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.tr(de: "Noch keine externen WAN-Rechner verbunden", en: "No external WAN Macs connected yet", fr: "Aucun Mac WAN externe connecté pour l'instant", es: "Aún no hay Macs WAN externos conectados", pt: "Ainda sem Macs WAN externos ligados", ru: "Внешние WAN-узлы пока не подключены", ja: "外部 WAN マシンはまだ接続されていません", zh: "暂未连接外部 WAN 节点"))
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.tr(de: "Verbinde deinen Mac über Tailscale, WireGuard oder einen Raum-Code im Tab „Internet-Verbund & Chat“, oder teste den 32-Mac-Demo-Schwarm.", en: "Connect your Mac via Tailscale, WireGuard, or a room code in “Internet Cluster & Chat”, or test the 32-Mac demo swarm.", fr: "Connectez votre Mac via Tailscale, WireGuard ou un code de salle dans « Grappe Internet », ou testez l'essaim démo 32 Mac.", es: "Conecta tu Mac mediante Tailscale, WireGuard o un código de sala en «Red Internet y chat», o prueba el enjambre demo de 32 Mac.", pt: "Ligue o seu Mac por Tailscale, WireGuard ou código de sala em «Rede Internet e conversa», ou teste o enxame demo 32 Mac.", ru: "Подключите Mac через Tailscale, WireGuard или код комнаты во вкладке «Интернет-кластер и чат» либо проверьте 32-Mac рой.", ja: "「インターネットクラスターとチャット」から Tailscale・WireGuard・ルームコードで接続するか 32-Mac デモをお試しください。", zh: "请在“互联网集群与聊天”标签页通过 Tailscale、WireGuard 或房间码连接 Mac，或试用 32-Mac 演示集群。"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.selectedTab = .internetCluster
                        } label: {
                            Label(vm.tr(de: "Internet-Verbund öffnen", en: "Open Internet Cluster", fr: "Ouvrir Grappe Internet", es: "Abrir Clúster Internet", pt: "Abrir Cluster Internet", ru: "Открыть Интернет-кластер", ja: "インターネットクラスターを開く", zh: "打开互联网集群"), systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SolarisTheme.mint)
                        .foregroundColor(.black)
                    }
                }
            } else {
                SolarisCard(accent: SolarisTheme.mint) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.tr(de: "Internet-Clusterverbünde nach Region / Standort", en: "Internet Subclusters by Region / Location", fr: "Sous-grappes Internet par région", es: "Subclústeres Internet por región / ubicación", pt: "Subclusters Internet por região / localização", ru: "Интернет-подкластеры по регионам", ja: "リージョン別インターネット部分クラスター", zh: "按区域/位置划分的互联网子集群"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.tr(de: "Untergliederte WAN-Teilverbünde mit Latenz-, Uplink- und Layer-Zuteilung.", en: "Segmented WAN subclusters with latency, uplink, and layer assignment.", fr: "Sous-grappes WAN avec latence, lien montant et attribution des couches.", es: "Subclústeres WAN segmentados con latencia, subida y asignación de capas.", pt: "Subclusters WAN segmentados com latência, uplink e atribuição de camadas.", ru: "Сегментированные WAN-подкластеры с задержкой, аплинком и распределением слоёв.", ja: "レイテンシ・アップリンク・層割当を含むリージョン別WANサブクラスター。", zh: "显示延迟、上行带宽与模型层分配的分区域 WAN 子集群。"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Text("\(vm.tr(de: "Raum", en: "Room", fr: "Salle", es: "Sala", pt: "Sala", ru: "Комната", ja: "ルーム", zh: "房间")): \(vm.wanRoomCode)")
                            .font(SolarisTheme.monoCode)
                            .foregroundColor(SolarisTheme.mint)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(vm.wanSubclustersByRegion, id: \.region) { group in
                            let groupRam = Int(group.peers.reduce(0.0) { $0 + $1.ramGB })
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label(group.region, systemImage: "mappin.and.ellipse")
                                        .font(SolarisTheme.cardTitle)
                                        .foregroundColor(SolarisTheme.mint)
                                    Spacer()
                                    Text(vm.tr(de: "\(group.peers.count) Rechner · \(groupRam) GB RAM", en: "\(group.peers.count) Macs · \(groupRam) GB RAM", fr: "\(group.peers.count) Mac · \(groupRam) Go RAM", es: "\(group.peers.count) equipos · \(groupRam) GB RAM", pt: "\(group.peers.count) Macs · \(groupRam) GB RAM", ru: "\(group.peers.count) машин · \(groupRam) ГБ RAM", ja: "\(group.peers.count) 台 · \(groupRam) GB RAM", zh: "\(group.peers.count) 台设备 · \(groupRam) GB 内存"))
                                        .font(SolarisTheme.bodyBold)
                                        .foregroundColor(SolarisTheme.textSecondary)
                                }
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                                    ForEach(group.peers) { peer in
                                        WanPeerMiniCard(peer: peer, accent: SolarisTheme.mint)
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(SolarisTheme.cardElevated.opacity(0.65))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(SolarisTheme.mint.opacity(0.28), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reiter 3: Lokal + Internet zusammen (Hybrid-Gesamtverbund)

    private var hybridClusterContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 16) {
                MetricTile(
                    title: vm.tr(de: "Kombinierter Gesamt-RAM", en: "Combined Total RAM", fr: "RAM totale combinée", es: "RAM total combinada", pt: "RAM total combinada", ru: "Суммарная память", ja: "統合総メモリ容量", zh: "混合总内存"),
                    value: "\(Int(vm.hybridCombinedRamGB)) GB",
                    subtitle: vm.tr(de: "\(Int(vm.hybridCombinedUsableVramGB)) GB nutzbarer Hybrid-Pool", en: "\(Int(vm.hybridCombinedUsableVramGB)) GB usable hybrid pool", fr: "\(Int(vm.hybridCombinedUsableVramGB)) Go pool hybride utilisable", es: "\(Int(vm.hybridCombinedUsableVramGB)) GB pool híbrido utilizable", pt: "\(Int(vm.hybridCombinedUsableVramGB)) GB pool híbrido utilizável", ru: "\(Int(vm.hybridCombinedUsableVramGB)) ГБ доступно в гибриде", ja: "\(Int(vm.hybridCombinedUsableVramGB)) GB 利用可能ハイブリッドプール", zh: "\(Int(vm.hybridCombinedUsableVramGB)) GB 可用混合显存池"),
                    accent: SolarisTheme.emerald,
                    icon: "point.3.connected.trianglepath.dotted"
                )
                MetricTile(
                    title: vm.tr(de: "Rechner Lokal + WAN", en: "Local + WAN Macs", fr: "Machines Local + WAN", es: "Equipos Local + WAN", pt: "Máquinas Local + WAN", ru: "Узлы: Локально + WAN", ja: "ノード数 (ローカル+WAN)", zh: "节点数（本地 + WAN）"),
                    value: "\(vm.hybridCombinedNodeCount)",
                    subtitle: vm.tr(de: "\(vm.nodes.count) Lokal (TB/LAN) + \(vm.wanRemotePeers.count) Internet (WAN)", en: "\(vm.nodes.count) Local (TB/LAN) + \(vm.wanRemotePeers.count) Internet (WAN)", fr: "\(vm.nodes.count) Local (TB/LAN) + \(vm.wanRemotePeers.count) Internet (WAN)", es: "\(vm.nodes.count) Local (TB/LAN) + \(vm.wanRemotePeers.count) Internet (WAN)", pt: "\(vm.nodes.count) Local (TB/LAN) + \(vm.wanRemotePeers.count) Internet (WAN)", ru: "\(vm.nodes.count) Лок. (TB/LAN) + \(vm.wanRemotePeers.count) WAN", ja: "ローカル \(vm.nodes.count) + WAN \(vm.wanRemotePeers.count)", zh: "本地 \(vm.nodes.count) + WAN \(vm.wanRemotePeers.count)"),
                    accent: SolarisTheme.amber,
                    icon: "square.grid.3x3.fill"
                )
                MetricTile(
                    title: vm.tr(de: "Hybrid-Brückenstatus", en: "Hybrid Bridge Status", fr: "État du pont hybride", es: "Estado del puente híbrido", pt: "Estado da ponte híbrida", ru: "Статус гибридного моста", ja: "ハイブリッドブリッジ状態", zh: "混合桥接状态"),
                    value: vm.isLocalClusterCoupledWithWan
                        ? vm.tr(de: "GEKOPPELT", en: "COUPLED", fr: "COUPLÉ", es: "ACOPLADO", pt: "ACOPLADO", ru: "СОЕДИНЕНО", ja: "結合済み", zh: "已耦合")
                        : vm.tr(de: "BEREIT", en: "READY", fr: "PRÊT", es: "LISTO", pt: "PRONTO", ru: "ГОТОВ", ja: "待機中", zh: "就绪"),
                    subtitle: vm.isLocalClusterCoupledWithWan
                        ? vm.tr(de: "Tier-0 TB + Tier-1 WAN aktiv", en: "Tier-0 TB + Tier-1 WAN active", fr: "Tier-0 TB + Tier-1 WAN actif", es: "Tier-0 TB + Tier-1 WAN activo", pt: "Tier-0 TB + Tier-1 WAN ativo", ru: "Tier-0 TB + Tier-1 WAN активны", ja: "Tier-0 TB + Tier-1 WAN 稼働中", zh: "Tier-0 TB + Tier-1 WAN 已激活")
                        : vm.tr(de: "Mit 1 Klick koppelbar", en: "1-click coupling ready", fr: "Couplage possible en 1 clic", es: "Acoplamiento en 1 clic", pt: "Acoplamento num clique", ru: "Соединение в 1 клик", ja: "ワンクリックで結合可能", zh: "支持一键耦合"),
                    accent: vm.isLocalClusterCoupledWithWan ? SolarisTheme.emerald : SolarisTheme.amber,
                    icon: vm.isLocalClusterCoupledWithWan ? "link.badge.plus" : "bolt.badge.a.fill"
                )
            }

            // Industrielles Hybrid-Brücken-Banner mit 1-Klick-Kopplung
            IndustrialHazardBanner(
                icon: vm.isLocalClusterCoupledWithWan ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                title: vm.isLocalClusterCoupledWithWan
                    ? vm.tr(de: "Hybrid-Brücke aktiv: Lokaler TB/RDMA-Kern ↔ Internet-WAN-Schwarm", en: "Hybrid Bridge Active: Local TB/RDMA Core ↔ Internet WAN Swarm", fr: "Pont hybride actif : Cœur TB/RDMA local ↔ Essaim WAN", es: "Puente híbrido activo: Núcleo TB/RDMA local ↔ Enjambre WAN", pt: "Ponte híbrida ativa: Núcleo TB/RDMA local ↔ Enxame WAN", ru: "Гибридный мост активен: Локальное ядро TB/RDMA ↔ WAN-рой", ja: "ハイブリッドブリッジ稼働中：ローカル TB/RDMA コア ↔ WAN スウォーム", zh: "混合桥接已激活：本地 TB/RDMA 核心 ↔ 互联网 WAN 集群")
                    : vm.tr(de: "Hybrid-Kopplungszone: Lokalen Cluster mit Internet-WAN zusammenführen", en: "Hybrid Coupling Zone: Merge Local Cluster with Internet WAN", fr: "Zone de couplage hybride : fusionner grappe locale et WAN", es: "Zona de acoplamiento híbrido: unir clúster local con WAN", pt: "Zona de acoplamento híbrido: unir cluster local e WAN", ru: "Зона гибридного слияния: объединение локального и WAN-кластера", ja: "ハイブリッド結合ゾーン：ローカルクラスターとインターネット WAN を統合", zh: "混合耦合区：将本地集群与互联网 WAN 节点融合"),
                subtitle: vm.tr(de: "Ebene 1 (Lokal, ~3–180 µs) übernimmt Rang 0 + Hochfrequenz-Schichten; Ebene 2 (WAN) erweitert den VRAM-Pool weltweit.", en: "Tier-0 (Local, ~3–180 µs) handles Rank 0 + high-frequency layers; Tier-1 (WAN) expands VRAM capacity globally.", fr: "Le niveau 0 (local, ~3–180 µs) gère le rang 0 ; le niveau 1 (WAN) étend la VRAM à l'échelle mondiale.", es: "El nivel 0 (local, ~3–180 µs) gestiona el rango 0; el nivel 1 (WAN) amplía la VRAM globalmente.", pt: "O nível 0 (local, ~3–180 µs) gere o ranque 0; o nível 1 (WAN) expande a VRAM globalmente.", ru: "Уровень 0 (локально, ~3–180 мкс) берёт Ранг 0; Уровень 1 (WAN) глобально расширяет пул VRAM.", ja: "Tier-0（ローカル ~3–180 µs）が Rank 0 と高頻度層を担当し、Tier-1（WAN）が VRAM プールを世界規模へ拡張します。", zh: "第 0 层（本地 ~3–180 µs）负责 Rank 0 与高频层；第 1 层（WAN）将显存池扩展至全球。"),
                accent: vm.isLocalClusterCoupledWithWan ? SolarisTheme.emerald : SolarisTheme.amber
            ) {
                HStack(spacing: 10) {
                    Button {
                        vm.toggleLocalClusterWanCoupling()
                    } label: {
                        Label(
                            vm.isLocalClusterCoupledWithWan
                                ? vm.tr(de: "Kopplung lösen", en: "Decouple", fr: "Séparer", es: "Desacoplar", pt: "Desacoplar", ru: "Отключить", ja: "結合解除", zh: "解除耦合")
                                : vm.tr(de: "Lokal + Internet koppeln", en: "Couple Local + Internet", fr: "Coupler Local + Internet", es: "Acoplar Local + Internet", pt: "Acoplar Local + Internet", ru: "Объединить Локально + WAN", ja: "ローカル + WAN 結合", zh: "耦合本地与互联网"),
                            systemImage: vm.isLocalClusterCoupledWithWan ? "link.badge.minus" : "link.badge.plus"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(vm.isLocalClusterCoupledWithWan ? SolarisTheme.coral : SolarisTheme.amber)
                    .foregroundColor(.black)
                }
            }

            // Ebene 1: Lokaler TB/RDMA-Kern
            SolarisCard(accent: SolarisTheme.amber) {
                HStack {
                    Label(vm.tr(de: "Ebene 1 (Tier-0): Lokaler Thunderbolt / LAN Verbund", en: "Tier-0: Local Thunderbolt / LAN Cluster", fr: "Niveau 0 : Grappe locale Thunderbolt / LAN", es: "Nivel 0: Clúster local Thunderbolt / LAN", pt: "Nível 0: Cluster local Thunderbolt / LAN", ru: "Уровень 0: Локальный кластер Thunderbolt / LAN", ja: "Tier-0：ローカル Thunderbolt / LAN クラスター", zh: "第 0 层 (Tier-0)：本地 Thunderbolt / LAN 集群"), systemImage: "bolt.fill")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.amberGlow)
                    Spacer()
                    Text(vm.tr(de: "\(vm.nodes.count) lokale(r) Mac(s) · \(Int(vm.totalPhysicalRamGB)) GB RAM", en: "\(vm.nodes.count) local Mac(s) · \(Int(vm.totalPhysicalRamGB)) GB RAM", fr: "\(vm.nodes.count) Mac locaux · \(Int(vm.totalPhysicalRamGB)) Go RAM", es: "\(vm.nodes.count) Mac local(es) · \(Int(vm.totalPhysicalRamGB)) GB RAM", pt: "\(vm.nodes.count) Mac(s) locais · \(Int(vm.totalPhysicalRamGB)) GB RAM", ru: "\(vm.nodes.count) лок. Mac · \(Int(vm.totalPhysicalRamGB)) ГБ RAM", ja: "ローカル Mac \(vm.nodes.count) 台 · \(Int(vm.totalPhysicalRamGB)) GB RAM", zh: "本地 \(vm.nodes.count) 台 Mac · \(Int(vm.totalPhysicalRamGB)) GB 内存"))
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textSecondary)
                }

                HStack(spacing: 16) {
                    ForEach(Array(vm.nodes.enumerated()), id: \.element.id) { index, node in
                        NodeCardView(node: node, lang: vm.language)
                        if index < vm.nodes.count - 1 {
                            LinkBridgeConnector(
                                leftGen: node.thunderboltGen,
                                rightGen: vm.nodes[index + 1].thunderboltGen,
                                mode: vm.transportMode
                            )
                        }
                    }
                }
            }

            // Ebene 2: Gekoppelter Internet-WAN-Verbund
            SolarisCard(accent: SolarisTheme.mint) {
                HStack {
                    Label(vm.tr(de: "Ebene 2 (Tier-1): Verteilte Internet-WAN-Verbünde", en: "Tier-1: Distributed Internet WAN Clusters", fr: "Niveau 1 : Grappes WAN Internet distribuées", es: "Nivel 1: Clústeres WAN de Internet distribuidos", pt: "Nível 1: Clusters WAN da Internet distribuídos", ru: "Уровень 1: Распределённые Интернет-кластеры WAN", ja: "Tier-1：分散インターネット WAN クラスター", zh: "第 1 层 (Tier-1)：分布式互联网 WAN 集群"), systemImage: "globe.americas.fill")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.mint)
                    Spacer()
                    Text(vm.tr(de: "\(vm.wanRemotePeers.count) externe WAN-Macs · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) GB RAM", en: "\(vm.wanRemotePeers.count) external WAN Mac(s) · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) GB RAM", fr: "\(vm.wanRemotePeers.count) Mac WAN externes · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) Go RAM", es: "\(vm.wanRemotePeers.count) Macs WAN externos · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) GB RAM", pt: "\(vm.wanRemotePeers.count) Macs WAN externos · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) GB RAM", ru: "\(vm.wanRemotePeers.count) внешн. WAN Mac · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) ГБ RAM", ja: "外部 WAN Mac \(vm.wanRemotePeers.count) 台 · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) GB RAM", zh: "外部 WAN Mac \(vm.wanRemotePeers.count) 台 · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) GB 内存"))
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textSecondary)
                }

                if vm.wanRemotePeers.isEmpty {
                    HStack {
                        Text(vm.tr(de: "Keine externen WAN-Peers verbunden. Öffne „Internet-Verbund & Chat“, um Remote-Macs oder einen Schwarm hinzuzufügen.", en: "No external WAN peers connected. Open “Internet Cluster & Chat” to add remote Macs or a swarm.", fr: "Aucun pair WAN externe connecté. Ouvrez « Grappe Internet » pour ajouter des Mac distants.", es: "Sin pares WAN externos. Abre «Red Internet y chat» para añadir Macs remotos o un enjambre.", pt: "Sem pares WAN externos. Abra «Rede Internet e conversa» para adicionar Macs remotos.", ru: "Внешние WAN-узлы не подключены. Откройте «Интернет-кластер и чат», чтобы добавить удалённые Mac.", ja: "外部 WAN ピアが未接続です。「インターネットクラスターとチャット」から追加できます。", zh: "未连接外部 WAN 节点。请打开“互联网集群与聊天”添加远程节点或演示集群。"))
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Spacer()
                        Button(vm.tr(de: "Internet-Verbund öffnen", en: "Open Internet Cluster", fr: "Ouvrir Grappe Internet", es: "Abrir Clúster Internet", pt: "Abrir Cluster Internet", ru: "Открыть Интернет-кластер", ja: "インターネットクラスターを開く", zh: "打开互联网集群")) {
                            vm.selectedTab = .internetCluster
                        }
                        .buttonStyle(.bordered)
                        .tint(SolarisTheme.mint)
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                        ForEach(vm.wanRemotePeers) { peer in
                            WanPeerMiniCard(peer: peer, accent: SolarisTheme.mint)
                        }
                    }
                }
            }
        }
    }
}

private struct WanPeerMiniCard: View {
    let peer: WanPeerNode
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(peer.isOnline ? SolarisTheme.emerald : SolarisTheme.coral)
                    .frame(width: 8, height: 8)
                Text(peer.displayName)
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(peer.region)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(accent.opacity(0.18)))
                    .foregroundColor(accent)
            }
            Text("\(peer.chip) · \(Int(peer.ramGB)) GB (\(Int(peer.usableVramGB)) GB MLX)")
                .font(.system(size: 12))
                .foregroundColor(SolarisTheme.textSecondary)
            HStack(spacing: 10) {
                Text("RTT: \(Int(peer.rttMs)) ms")
                Text("Up: \(Int(peer.uplinkMbps)) Mbps")
                if !peer.assignedLayers.isEmpty {
                    Text("L: \(peer.assignedLayers)")
                        .foregroundColor(accent)
                }
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(SolarisTheme.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(SolarisTheme.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(accent.opacity(0.30), lineWidth: 1)
                )
        )
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
    var lang: AppLanguage = .de

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
                    Text(node.localizedRole(lang))
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(accent)
                }
                Spacer()
                if node.isSimulated {
                    Text(L10n.text("node_simulated_badge", lang))
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
                    Text(L10n.text("node_chip", lang)).foregroundColor(SolarisTheme.textSecondary)
                    Text("\(node.chip) · \(node.cpuCores) \(L10n.text("node_cpu_cores", lang)) · \(node.gpuCores) \(L10n.text("node_gpu_cores", lang)) · \(node.neuralEngineCores) \(L10n.text("node_ane_cores", lang))").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.text("node_memory", lang)).foregroundColor(SolarisTheme.textSecondary)
                    Text("\(Int(node.totalRamGB)) GB RAM (\(Int(node.usableVramGB)) GB MLX)").foregroundColor(SolarisTheme.textPrimary)
                }
                GridRow {
                    Text(L10n.text("node_bandwidth", lang)).foregroundColor(SolarisTheme.textSecondary)
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
    let leftGen: Int
    let rightGen: Int
    let mode: TransportMode

    var body: some View {
        let stats = AppleSiliconChipFamily.linkTransferStats(genA: leftGen, genB: rightGen, mode: mode)
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let phase = CGFloat(context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6)
            VStack(spacing: 8) {
                Text(stats.badge)
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

                Text(stats.rangeLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(SolarisTheme.textSecondary)
            }
            .frame(width: 110)
        }
    }
}
