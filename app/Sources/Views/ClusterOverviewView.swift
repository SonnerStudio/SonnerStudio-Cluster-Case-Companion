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
                    Text("\(vm.clusterSetupVariant.rawValue) · Letzte Prüfung: \(vm.lastReadinessCheckedAt)")
                        .font(.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }

                Spacer()

                Button {
                    vm.verifyClusterReadiness()
                } label: {
                    Label("Prüfen", systemImage: "checklist.checked")
                }
                .buttonStyle(.bordered)
                .solarisShorttip("Prüft Discovery, SSH, Thunderbolt/WAN-Links, VRAM-Schutz und API-Gateway.", id: "ov_verify_btn", vm: vm)

                Button {
                    vm.selectedTab = .setup
                } label: {
                    Label("Setup öffnen", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .tint(stateColor)
                .foregroundColor(.black)
                .solarisShorttip(vm.shorttip(.setup), id: "ov_open_setup_btn", vm: vm)
            }
        }
        .solarisShorttip("Aktueller Betriebszustand des Verbunds (Bereit / Nicht bereit / Unvollständig / Uneingerichtet).", id: "ov_readiness_card", vm: vm)
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
                    title: "WAN Speicherpool",
                    value: "\(Int(vm.wanTotalRamGB)) GB",
                    subtitle: "\(Int(vm.wanTotalUsableVramGB)) GB nutzbar über \(vm.wanPeers.count) Knoten",
                    accent: SolarisTheme.mint,
                    icon: "globe.americas.fill"
                )
                MetricTile(
                    title: "Teilverbünde & Knoten",
                    value: "\(vm.wanSubclustersByRegion.count + (vm.wanLocalIslandPeers.isEmpty ? 0 : 1))",
                    subtitle: "\(vm.wanLocalIslandPeers.count) lokal gekoppelt · \(vm.wanRemotePeers.count) WAN-Peers",
                    accent: SolarisTheme.amber,
                    icon: "network"
                )
                MetricTile(
                    title: "WAN Transport & RTT",
                    value: "\(Int(vm.wanTotalRttMs)) ms",
                    subtitle: vm.wanTransport.rawValue,
                    accent: SolarisTheme.emerald,
                    icon: "antenna.radiowaves.left.and.right"
                )
            }

            // Gekoppelter lokaler Clusterverbund im Internet-Mesh (falls verfügbar)
            if !vm.wanLocalIslandPeers.isEmpty || vm.isLocalClusterCoupledWithWan {
                SolarisCard(accent: SolarisTheme.amber) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Untergliederter lokaler Clusterverbund (Tier-0 Insel)")
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Lokale Thunderbolt/LAN-Rechner, die als schneller Rang-0-Kern im Internet-Cluster mitwirken.")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Label("\(vm.wanLocalIslandPeers.count) Knoten · \(Int(vm.wanLocalIslandPeers.reduce(0) { $0 + $1.ramGB })) GB", systemImage: "bolt.horizontal.circle.fill")
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
                            Text("Noch keine externen WAN-Rechner verbunden")
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Verbinde deinen Mac über Tailscale, WireGuard oder einen Raum-Code im Tab „Internet-Verbund & Chat“, oder teste den 32-Mac-Demo-Schwarm.")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.selectedTab = .internetCluster
                        } label: {
                            Label("Internet-Verbund öffnen", systemImage: "arrow.right.circle.fill")
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
                            Text("Internet-Clusterverbünde nach Region / Standort")
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Untergliederte WAN-Teilverbünde mit Latenz-, Uplink- und Layer-Zuteilung.")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Text("Raum: \(vm.wanRoomCode)")
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
                                    Text("\(group.peers.count) Rechner · \(groupRam) GB RAM")
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
                    title: "Kombinierter Gesamt-RAM",
                    value: "\(Int(vm.hybridCombinedRamGB)) GB",
                    subtitle: "\(Int(vm.hybridCombinedUsableVramGB)) GB nutzbarer Hybrid-Pool",
                    accent: SolarisTheme.emerald,
                    icon: "point.3.connected.trianglepath.dotted"
                )
                MetricTile(
                    title: "Rechner Lokal + WAN",
                    value: "\(vm.hybridCombinedNodeCount)",
                    subtitle: "\(vm.nodes.count) Lokal (TB/LAN) + \(vm.wanRemotePeers.count) Internet (WAN)",
                    accent: SolarisTheme.amber,
                    icon: "square.grid.3x3.fill"
                )
                MetricTile(
                    title: "Hybrid-Brückenstatus",
                    value: vm.isLocalClusterCoupledWithWan ? "GEKOPPELT" : "BEREIT",
                    subtitle: vm.isLocalClusterCoupledWithWan ? "Tier-0 TB + Tier-1 WAN aktiv" : "Mit 1 Klick koppelbar",
                    accent: vm.isLocalClusterCoupledWithWan ? SolarisTheme.emerald : SolarisTheme.amber,
                    icon: vm.isLocalClusterCoupledWithWan ? "link.badge.plus" : "bolt.badge.a.fill"
                )
            }

            // Industrielles Hybrid-Brücken-Banner mit 1-Klick-Kopplung
            IndustrialHazardBanner(
                icon: vm.isLocalClusterCoupledWithWan ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                title: vm.isLocalClusterCoupledWithWan
                    ? "Hybrid-Brücke aktiv: Lokaler TB/RDMA-Kern ↔ Internet-WAN-Schwarm"
                    : "Hybrid-Kopplungszone: Lokalen Cluster mit Internet-WAN zusammenführen",
                subtitle: "Ebene 1 (Lokal, ~3–180 µs) übernimmt Rang 0 + Hochfrequenz-Schichten; Ebene 2 (WAN) erweitert den VRAM-Pool weltweit.",
                accent: vm.isLocalClusterCoupledWithWan ? SolarisTheme.emerald : SolarisTheme.amber
            ) {
                HStack(spacing: 10) {
                    Button {
                        vm.toggleLocalClusterWanCoupling()
                    } label: {
                        Label(
                            vm.isLocalClusterCoupledWithWan ? "Kopplung lösen" : "Lokal + Internet koppeln",
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
                    Label("Ebene 1 (Tier-0): Lokaler Thunderbolt / LAN Verbund", systemImage: "bolt.fill")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.amberGlow)
                    Spacer()
                    Text("\(vm.nodes.count) lokale(r) Mac(s) · \(Int(vm.totalPhysicalRamGB)) GB RAM")
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
                    Label("Ebene 2 (Tier-1): Verteilte Internet-WAN-Verbünde", systemImage: "globe.americas.fill")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.mint)
                    Spacer()
                    Text("\(vm.wanRemotePeers.count) externe WAN-Macs · \(Int(vm.wanRemotePeers.reduce(0) { $0 + $1.ramGB })) GB RAM")
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textSecondary)
                }

                if vm.wanRemotePeers.isEmpty {
                    HStack {
                        Text("Keine externen WAN-Peers verbunden. Öffne „Internet-Verbund & Chat“, um Remote-Macs oder einen Schwarm hinzuzufügen.")
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Spacer()
                        Button("Internet-Verbund öffnen") {
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
                    Text(node.role)
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
                    Text("\(node.chip) · \(node.cpuCores) \(L10n.text("node_cpu_cores", lang))").foregroundColor(SolarisTheme.textPrimary)
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
