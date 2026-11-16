import SwiftUI
import AppKit

struct InternetClusterView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Header & Room / Overlay Connection Controls
                SolarisCard(accent: vm.wanConnected ? SolarisTheme.emerald : SolarisTheme.amber) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("wan_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.t("wan_sub"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.toggleWanConnection()
                        } label: {
                            Label(
                                vm.wanConnected
                                    ? L10n.tr(vm.language, de: "Verbund trennen", en: "Disconnect Cluster", fr: "Déconnecter le cluster", es: "Desconectar clúster", pt: "Desligar cluster", ru: "Отключить кластер", ja: "クラスタを切断", zh: "断开集群连接")
                                    : L10n.tr(vm.language, de: "Internet-Verbund verbinden", en: "Connect Internet Cluster", fr: "Connecter le cluster Internet", es: "Conectar clúster de Internet", pt: "Ligar cluster Internet", ru: "Подключить интернет-кластер", ja: "インターネットクラスタに接続", zh: "连接互联网集群"),
                                systemImage: vm.wanConnected ? "wifi.slash" : "globe.americas.fill"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(vm.wanConnected ? SolarisTheme.coral : SolarisTheme.amber)
                        .foregroundColor(.black)
                    }

                    HazardStripesBar(height: 5, stripeWidth: 10, cornerRadius: 3, opacity: 0.88)
                        .solarisShorttip(vm.shorttip(.internetCluster), id: "view_internet_header", vm: vm)

                    // Room Code, Relay URL & Scale Mode
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tr(vm.language,
                                de: "Raum-Kennung / Einladungs-Code",
                                en: "Room ID / Invite Code",
                                fr: "ID de salle / Code d'invitation",
                                es: "ID de sala / Código de invitación",
                                pt: "ID da sala / Código de convite",
                                ru: "ID комнаты / Код приглашения",
                                ja: "ルーム ID / 招待コード",
                                zh: "房间标识 / 邀请码"))
                                .font(.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            HStack {
                                TextField("SSCCC-WAN-...", text: $vm.wanRoomCode)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 13, design: .monospaced))
                                Button(L10n.tr(vm.language, de: "Kopieren", en: "Copy", fr: "Copier", es: "Copiar", pt: "Copiar", ru: "Копировать", ja: "コピー", zh: "复制")) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(vm.wanRoomCode, forType: .string)
                                    vm.wanStatusNote = L10n.tr(vm.language,
                                        de: "Raum-Code \(vm.wanRoomCode) kopiert.",
                                        en: "Room code \(vm.wanRoomCode) copied.",
                                        fr: "Code de salle \(vm.wanRoomCode) copié.",
                                        es: "Código de sala \(vm.wanRoomCode) copiado.",
                                        pt: "Código da sala \(vm.wanRoomCode) copiado.",
                                        ru: "Код комнаты \(vm.wanRoomCode) скопирован.",
                                        ja: "ルームコード \(vm.wanRoomCode) をコピーしました。",
                                        zh: "已复制房间码 \(vm.wanRoomCode)。")
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tr(vm.language,
                                de: "Overlay-Protokoll & NAT-Durchquerung",
                                en: "Overlay Protocol & NAT Traversal",
                                fr: "Protocole overlay & traversée NAT",
                                es: "Protocolo overlay y cruce NAT",
                                pt: "Protocolo overlay e travessia NAT",
                                ru: "Overlay-протокол и обход NAT",
                                ja: "オーバーレイプロトコル・NAT越え",
                                zh: "覆盖网络协议与 NAT 穿透"))
                                .font(.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            Picker(L10n.tr(vm.language, de: "Transport", en: "Transport", fr: "Transport", es: "Transporte", pt: "Transporte", ru: "Транспорт", ja: "トランスポート", zh: "传输协议"), selection: $vm.wanTransport) {
                                ForEach(WanOverlayTransport.allCases) { mode in
                                    Text(mode.localizedTitle(vm.language)).tag(mode)
                                }
                            }
                            .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tr(vm.language,
                                de: "Verbund-Größe",
                                en: "Cluster Scale",
                                fr: "Taille du cluster",
                                es: "Tamaño del clúster",
                                pt: "Escala do cluster",
                                ru: "Размер кластера",
                                ja: "クラスタ規模",
                                zh: "集群规模"))
                                .font(.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            Picker(L10n.tr(vm.language, de: "Größe", en: "Scale", fr: "Taille", es: "Escala", pt: "Escala", ru: "Размер", ja: "規模", zh: "规模"), selection: $vm.wanScaleMode) {
                                ForEach(InternetClusterScale.allCases) { scale in
                                    Text(scale.localizedTitle(vm.language)).tag(scale)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    Text(vm.wanTransport.localizedNatNote(vm.language))
                        .font(.caption)
                        .foregroundColor(SolarisTheme.mint)

                    HStack(spacing: 14) {
                        Label(
                            vm.wanTailscaleInstalled
                                ? L10n.tr(vm.language,
                                    de: "Tailscale: Bereit (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))",
                                    en: "Tailscale: Ready (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))",
                                    fr: "Tailscale : Prêt (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))",
                                    es: "Tailscale: Listo (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))",
                                    pt: "Tailscale: Pronto (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))",
                                    ru: "Tailscale: Готов (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))",
                                    ja: "Tailscale: 準備完了 (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))",
                                    zh: "Tailscale：就绪 (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))")
                                : L10n.tr(vm.language,
                                    de: "Tailscale: Nicht installiert",
                                    en: "Tailscale: Not installed",
                                    fr: "Tailscale : Non installé",
                                    es: "Tailscale: No instalado",
                                    pt: "Tailscale: Não instalado",
                                    ru: "Tailscale: Не установлен",
                                    ja: "Tailscale: 未インストール",
                                    zh: "Tailscale：未安装"),
                            systemImage: vm.wanTailscaleInstalled ? "checkmark.shield.fill" : "exclamationmark.circle"
                        )
                        .font(.caption)
                        .foregroundColor(vm.wanTailscaleInstalled ? SolarisTheme.emerald : SolarisTheme.textSecondary)

                        Label(
                            vm.wanWireGuardInstalled
                                ? L10n.tr(vm.language,
                                    de: "WireGuard: Bereit",
                                    en: "WireGuard: Ready",
                                    fr: "WireGuard : Prêt",
                                    es: "WireGuard: Listo",
                                    pt: "WireGuard: Pronto",
                                    ru: "WireGuard: Готов",
                                    ja: "WireGuard: 準備完了",
                                    zh: "WireGuard：就绪")
                                : L10n.tr(vm.language,
                                    de: "WireGuard: Optional (brew install wireguard-tools)",
                                    en: "WireGuard: Optional (brew install wireguard-tools)",
                                    fr: "WireGuard : Optionnel (brew install wireguard-tools)",
                                    es: "WireGuard: Opcional (brew install wireguard-tools)",
                                    pt: "WireGuard: Opcional (brew install wireguard-tools)",
                                    ru: "WireGuard: Опционально (brew install wireguard-tools)",
                                    ja: "WireGuard: 任意 (brew install wireguard-tools)",
                                    zh: "WireGuard：可选 (brew install wireguard-tools)"),
                            systemImage: vm.wanWireGuardInstalled ? "lock.shield.fill" : "network"
                        )
                        .font(.caption)
                        .foregroundColor(vm.wanWireGuardInstalled ? SolarisTheme.emerald : SolarisTheme.textSecondary)

                        Spacer()

                        Button(L10n.tr(vm.language,
                            de: "Tailscale/Peers neu einlesen",
                            en: "Reload Tailscale/Peers",
                            fr: "Recharger Tailscale/Pairs",
                            es: "Recargar Tailscale/Pares",
                            pt: "Recarregar Tailscale/Pares",
                            ru: "Обновить Tailscale/пиры",
                            ja: "Tailscale/ピアを再読込",
                            zh: "重新扫描 Tailscale / 节点")) {
                            vm.probeWanOverlayTools()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // 1b. Hybrid Bridge: Couple Local Thunderbolt/RDMA Cluster with Internet WAN Cluster
                SolarisCard(accent: vm.isLocalClusterCoupledWithWan ? SolarisTheme.mint : SolarisTheme.amber) {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: vm.isLocalClusterCoupledWithWan ? "link.circle.fill" : "link.badge.plus")
                                    .foregroundColor(vm.isLocalClusterCoupledWithWan ? SolarisTheme.mint : SolarisTheme.amberGlow)
                                Text(L10n.tr(vm.language,
                                    de: "Hybrid-Brücke: Lokalen TB/RDMA-Verbund mit Internet-Cluster koppeln",
                                    en: "Hybrid Bridge: Couple Local TB/RDMA Cluster with Internet Cluster",
                                    fr: "Pont hybride : coupler le cluster local TB/RDMA au cluster Internet",
                                    es: "Puente híbrido: acoplar clúster local TB/RDMA con clúster de Internet",
                                    pt: "Ponte híbrida: ligar cluster local TB/RDMA ao cluster Internet",
                                    ru: "Гибридный мост: объединить локальный TB/RDMA и интернет-кластер",
                                    ja: "ハイブリッドブリッジ: ローカル TB/RDMA とインターネットクラスタを結合",
                                    zh: "混合桥接：将本地 TB/RDMA 集群与互联网集群耦合"))
                                    .font(SolarisTheme.cardTitle)
                                    .foregroundColor(SolarisTheme.textPrimary)
                            }
                            Text(
                                vm.isLocalClusterCoupledWithWan
                                    ? L10n.tr(vm.language,
                                        de: "Aktiv: \(vm.coupledLocalBridgeCount) lokale Thunderbolt/RDMA-Macs (\(Int(vm.totalPhysicalRamGB)) GB) bilden eine schnelle Tier-0-Insel und teilen Schichten mit \(vm.coupledRemoteWanCount) WAN-Partnern.",
                                        en: "Active: \(vm.coupledLocalBridgeCount) local Thunderbolt/RDMA Macs (\(Int(vm.totalPhysicalRamGB)) GB) form a fast Tier-0 island sharing layers with \(vm.coupledRemoteWanCount) WAN peers.",
                                        fr: "Actif : \(vm.coupledLocalBridgeCount) Macs TB/RDMA locaux (\(Int(vm.totalPhysicalRamGB)) Go) forment un îlot Tier-0 partagé avec \(vm.coupledRemoteWanCount) pairs WAN.",
                                        es: "Activo: \(vm.coupledLocalBridgeCount) Macs locales TB/RDMA (\(Int(vm.totalPhysicalRamGB)) GB) forman una isla Tier-0 compartida con \(vm.coupledRemoteWanCount) pares WAN.",
                                        pt: "Ativo: \(vm.coupledLocalBridgeCount) Macs locais TB/RDMA (\(Int(vm.totalPhysicalRamGB)) GB) formam uma ilha Tier-0 com \(vm.coupledRemoteWanCount) parceiros WAN.",
                                        ru: "Активно: \(vm.coupledLocalBridgeCount) локальных Mac TB/RDMA (\(Int(vm.totalPhysicalRamGB)) ГБ) образуют быстрый Tier-0 остров с \(vm.coupledRemoteWanCount) WAN-узлами.",
                                        ja: "有効: ローカル TB/RDMA Mac \(vm.coupledLocalBridgeCount) 台 (\(Int(vm.totalPhysicalRamGB)) GB) が高速 Tier-0 アイランドを形成し、WANピア \(vm.coupledRemoteWanCount) 台と層を共有しています。",
                                        zh: "已启用：\(vm.coupledLocalBridgeCount) 台本地 Thunderbolt/RDMA Mac (\(Int(vm.totalPhysicalRamGB)) GB) 组成高速 Tier-0 岛，并与 \(vm.coupledRemoteWanCount) 个广域网节点共享模型层。")
                                    : L10n.tr(vm.language,
                                        de: "Fügt alle \(vm.nodes.count) lokalen Thunderbolt/RDMA-Macs (\(Int(vm.totalPhysicalRamGB)) GB RAM) über deinen Rang-0-Leitrechner als gemeinsame Speicher- und Rechen-Insel in den Internet-Cluster ein.",
                                        en: "Adds all \(vm.nodes.count) local Thunderbolt/RDMA Macs (\(Int(vm.totalPhysicalRamGB)) GB RAM) via your Rank-0 head node as a unified compute and memory island into the Internet cluster.",
                                        fr: "Ajoute vos \(vm.nodes.count) Macs TB/RDMA locaux (\(Int(vm.totalPhysicalRamGB)) Go) via le nœud maître Rang 0 dans le cluster Internet.",
                                        es: "Agrega tus \(vm.nodes.count) Macs locales TB/RDMA (\(Int(vm.totalPhysicalRamGB)) GB RAM) vía el nodo maestro Rango 0 al clúster de Internet.",
                                        pt: "Adiciona os \(vm.nodes.count) Macs locais TB/RDMA (\(Int(vm.totalPhysicalRamGB)) GB RAM) via nó líder Rank-0 ao cluster Internet.",
                                        ru: "Добавляет все \(vm.nodes.count) локальных Mac TB/RDMA (\(Int(vm.totalPhysicalRamGB)) ГБ ОЗУ) через узел Rank-0 в интернет-кластер.",
                                        ja: "Rank-0 マスターノード経由でローカル TB/RDMA Mac \(vm.nodes.count) 台 (\(Int(vm.totalPhysicalRamGB)) GB) を統合計算・メモリ島として参加させます。",
                                        zh: "通过 Rank-0 主节点将全部 \(vm.nodes.count) 台本地 Thunderbolt/RDMA Mac (\(Int(vm.totalPhysicalRamGB)) GB 内存) 作为统一计算与显存岛接入互联网集群。")
                            )
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        }

                        Spacer()

                        Button {
                            vm.toggleLocalClusterWanCoupling()
                        } label: {
                            Label(
                                vm.isLocalClusterCoupledWithWan
                                    ? L10n.tr(vm.language, de: "Kopplung lösen", en: "Uncouple Bridge", fr: "Découpler", es: "Desacoplar", pt: "Desacoplar", ru: "Отсоединить", ja: "結合解除", zh: "解除耦合")
                                    : L10n.tr(vm.language, de: "Lokal + Internet koppeln", en: "Couple Local + Internet", fr: "Coupler Local + Internet", es: "Acoplar Local + Internet", pt: "Acoplar Local + Internet", ru: "Объединить локал. + WAN", ja: "ローカル＋インターネット結合", zh: "耦合本地 + 互联网"),
                                systemImage: vm.isLocalClusterCoupledWithWan ? "xmark.circle" : "bolt.horizontal.fill"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(vm.isLocalClusterCoupledWithWan ? SolarisTheme.coral : SolarisTheme.mint)
                        .foregroundColor(.black)

                        Button {
                            vm.sciScope = .internetWan
                            vm.selectedTab = .science
                        } label: {
                            Label(L10n.tr(vm.language,
                                de: "Im Forschungslabor analysieren",
                                en: "Analyze in Science Lab",
                                fr: "Analyser dans le labo",
                                es: "Analizar en laboratorio",
                                pt: "Analisar no laboratório",
                                ru: "Анализ в лаборатории",
                                ja: "研究ラボで分析",
                                zh: "在科研实验室中分析"), systemImage: "waveform.path.ecg")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // 2. WAN Pool Summary Tiles
                HStack(spacing: 14) {
                    WanMetricTile(
                        title: L10n.tr(vm.language, de: "WAN-Teilnehmer", en: "WAN Participants", fr: "Participants WAN", es: "Participantes WAN", pt: "Participantes WAN", ru: "Участники WAN", ja: "WAN 参加ノード", zh: "广域网参与节点"),
                        value: "\(vm.wanPeers.count) Macs",
                        sub: vm.wanScaleMode.localizedTitle(vm.language),
                        accent: SolarisTheme.amberGlow
                    )
                    WanMetricTile(
                        title: L10n.tr(vm.language, de: "Verbund-RAM (WAN)", en: "Cluster RAM (WAN)", fr: "RAM Cluster (WAN)", es: "RAM del clúster (WAN)", pt: "RAM do cluster (WAN)", ru: "ОЗУ кластера (WAN)", ja: "クラスタ RAM (WAN)", zh: "集群内存 (WAN)"),
                        value: "\(Int(vm.wanTotalRamGB)) GB",
                        sub: L10n.tr(vm.language,
                            de: "\(Int(vm.wanTotalUsableVramGB)) GB nutzbar",
                            en: "\(Int(vm.wanTotalUsableVramGB)) GB usable",
                            fr: "\(Int(vm.wanTotalUsableVramGB)) Go utilisables",
                            es: "\(Int(vm.wanTotalUsableVramGB)) GB utilizables",
                            pt: "\(Int(vm.wanTotalUsableVramGB)) GB utilizáveis",
                            ru: "\(Int(vm.wanTotalUsableVramGB)) ГБ доступно",
                            ja: "\(Int(vm.wanTotalUsableVramGB)) GB 利用可能",
                            zh: "\(Int(vm.wanTotalUsableVramGB)) GB 可用"),
                        accent: SolarisTheme.mint
                    )
                    WanMetricTile(
                        title: L10n.tr(vm.language, de: "Pipeline-RTT (Summe)", en: "Pipeline RTT (Sum)", fr: "RTT Pipeline (Total)", es: "RTT Pipeline (Suma)", pt: "RTT Pipeline (Soma)", ru: "RTT конвейера (сумма)", ja: "パイプライン RTT (合計)", zh: "流水线 RTT (总计)"),
                        value: String(format: "%.1f ms", vm.wanTotalRttMs),
                        sub: L10n.tr(vm.language,
                            de: "MTU \(vm.wanTransport.mtuBytes) B · PP-Modus",
                            en: "MTU \(vm.wanTransport.mtuBytes) B · PP Mode",
                            fr: "MTU \(vm.wanTransport.mtuBytes) o · Mode PP",
                            es: "MTU \(vm.wanTransport.mtuBytes) B · Modo PP",
                            pt: "MTU \(vm.wanTransport.mtuBytes) B · Modo PP",
                            ru: "MTU \(vm.wanTransport.mtuBytes) Б · Режим PP",
                            ja: "MTU \(vm.wanTransport.mtuBytes) B · PP モード",
                            zh: "MTU \(vm.wanTransport.mtuBytes) B · 流水线并行模式"),
                        accent: SolarisTheme.amber
                    )
                    WanMetricTile(
                        title: L10n.tr(vm.language, de: "Geschätzte WAN-Rate", en: "Estimated WAN Rate", fr: "Débit WAN estimé", es: "Tasa WAN estimada", pt: "Taxa WAN estimada", ru: "Оценка скорости WAN", ja: "推定 WAN 速度", zh: "预计 WAN 速率"),
                        value: String(format: "%.2f tok/s", vm.wanEstimatedTokPerSec),
                        sub: L10n.tr(vm.language,
                            de: "Pipeline Parallelism (kein All-Reduce)",
                            en: "Pipeline Parallelism (no All-Reduce)",
                            fr: "Parallélisme pipeline (sans All-Reduce)",
                            es: "Paralelismo de pipeline (sin All-Reduce)",
                            pt: "Paralelismo em pipeline (sem All-Reduce)",
                            ru: "Конвейерный параллелизм (без All-Reduce)",
                            ja: "パイプライン並列（All-Reduce 不要）",
                            zh: "流水线并行（无需 All-Reduce）"),
                        accent: SolarisTheme.emerald
                    )
                }

                // 2b. Internet Bandwidth, Throughput & Cluster Performance Impact Monitor
                wanBandwidthMonitorCard

                // 3. Connected Internet Macs & Mega-Cluster Builder
                SolarisCard {
                        HStack {
                            Text(L10n.tr(vm.language,
                                de: "Verbundene Internet-Macs",
                                en: "Connected Internet Macs",
                                fr: "Macs Internet connectés",
                                es: "Macs de Internet conectados",
                                pt: "Macs Internet ligados",
                                ru: "Подключённые интернет-Mac",
                                ja: "接続中のインターネット Mac",
                                zh: "已连接的互联网 Mac"))
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Spacer()
                            Button(L10n.tr(vm.language,
                                de: "32-Mac Schwarm",
                                en: "32-Mac Swarm",
                                fr: "Essaim 32 Macs",
                                es: "Enjambre 32 Macs",
                                pt: "Enxame 32 Macs",
                                ru: "Рой 32 Mac",
                                ja: "32台スウォーム",
                                zh: "32 台集群模拟")) {
                                vm.populateMegaClusterSwarm(count: 32)
                            }
                            .buttonStyle(.bordered)
                            Button(L10n.tr(vm.language,
                                de: "64-Mac Mega-Verbund",
                                en: "64-Mac Mega Cluster",
                                fr: "Méga-cluster 64 Macs",
                                es: "Megaclúster 64 Macs",
                                pt: "Megacluster 64 Macs",
                                ru: "Мега-кластер 64 Mac",
                                ja: "64台メガクラスタ",
                                zh: "64 台超大集群")) {
                                vm.populateMegaClusterSwarm(count: 64)
                            }
                            .buttonStyle(.bordered)
                        }

                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(vm.wanPeers) { peer in
                                    HStack {
                                        Circle()
                                            .fill(peer.isOnline ? SolarisTheme.emerald : SolarisTheme.coral)
                                            .frame(width: 8, height: 8)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(peer.displayName) · \(peer.region)")
                                                .font(SolarisTheme.bodyBold)
                                                .foregroundColor(peer.isLocalHost ? SolarisTheme.amberGlow : SolarisTheme.textPrimary)
                                            Text("\(peer.chip) · \(Int(peer.ramGB)) GB · \(peer.overlayIP) · RTT \(Int(peer.rttMs)) ms")
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(SolarisTheme.textSecondary)
                                        }
                                        Spacer()
                                        Text(peer.assignedLayers)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(SolarisTheme.mint.opacity(0.18)))
                                            .foregroundColor(SolarisTheme.mint)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(SolarisTheme.cardElevated)
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 280)

                        Divider().background(SolarisTheme.borderSubtle)

                        // Add Remote Mac via Tailscale / WireGuard IP
                        Text(L10n.tr(vm.language,
                            de: "Entfernten Mac (M1–M9+) per IP hinzufügen",
                            en: "Add Remote Mac (M1–M9+) by IP",
                            fr: "Ajouter un Mac distant (M1–M9+) par IP",
                            es: "Añadir Mac remoto (M1–M9+) por IP",
                            pt: "Adicionar Mac remoto (M1–M9+) por IP",
                            ru: "Добавить удалённый Mac (M1–M9+) по IP",
                            ja: "リモート Mac (M1–M9+) を IP で追加",
                            zh: "通过 IP 添加远程 Mac (M1–M9+)"))
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)

                        HStack(spacing: 8) {
                            TextField(L10n.tr(vm.language, de: "Name (z. B. Studio-Berlin)", en: "Name (e.g., Studio-Berlin)", fr: "Nom (ex. Studio-Paris)", es: "Nombre (ej. Studio-Madrid)", pt: "Nome (ex. Studio-Lisboa)", ru: "Имя (напр. Studio-Berlin)", ja: "名前 (例: Studio-Tokyo)", zh: "名称（如 Studio-Beijing）"), text: $vm.wanPeerNameInput)
                                .textFieldStyle(.roundedBorder)
                            TextField(L10n.tr(vm.language, de: "Region", en: "Region", fr: "Région", es: "Región", pt: "Região", ru: "Регион", ja: "リージョン", zh: "区域"), text: $vm.wanPeerRegionInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 95)
                            TextField(L10n.tr(vm.language, de: "Overlay-IP", en: "Overlay IP", fr: "IP overlay", es: "IP overlay", pt: "IP overlay", ru: "Overlay IP", ja: "オーバーレイ IP", zh: "覆盖网络 IP"), text: $vm.wanPeerIpInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                        }
                        HStack(spacing: 8) {
                            Picker(L10n.tr(vm.language, de: "Chip", en: "Chip", fr: "Puce", es: "Chip", pt: "Chip", ru: "Чип", ja: "チップ", zh: "芯片"), selection: $vm.wanPeerChip) {
                                ForEach(AppleSiliconChipFamily.allCases) { chip in
                                    Text(chip.rawValue.replacingOccurrences(of: "Apple ", with: "")).tag(chip)
                                }
                            }
                            .labelsHidden()
                            Stepper("RAM: \(Int(vm.wanPeerRamGB)) GB", value: $vm.wanPeerRamGB, in: 8...512, step: 8)
                                .font(.caption)
                            Stepper("RTT: \(Int(vm.wanPeerRttMs)) ms", value: $vm.wanPeerRttMs, in: 2...250, step: 5)
                                .font(.caption)
                            Button(L10n.tr(vm.language, de: "Hinzufügen", en: "Add", fr: "Ajouter", es: "Añadir", pt: "Adicionar", ru: "Добавить", ja: "追加", zh: "添加")) {
                                vm.addManualWanPeer()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SolarisTheme.mint)
                            .foregroundColor(.black)
                        }
                }

                // 4. Side-by-Side: Cluster Audio-Party (Left) & Live Participant Chat (Right)
                HStack(alignment: .top, spacing: 18) {
                    audioPartyCard
                        .frame(maxWidth: .infinity)

                    // Right: Live Participant Chat
                    SolarisCard(accent: SolarisTheme.mint) {
                        HStack {
                            Text(vm.t("wan_chat_title"))
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Spacer()
                            Button("/status") { vm.sendClusterChatMessage("/status") }
                                .buttonStyle(.bordered)
                            Button("/layers") { vm.sendClusterChatMessage("/layers") }
                                .buttonStyle(.bordered)
                            Button("/ping") { vm.sendClusterChatMessage("/ping") }
                                .buttonStyle(.bordered)
                        }

                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(vm.chatMessages) { msg in
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(msg.senderName)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(msg.isSystemEvent ? SolarisTheme.amberGlow : (msg.isSelf ? SolarisTheme.mint : SolarisTheme.emerald))
                                            if !msg.senderRegion.isEmpty {
                                                Text("(\(msg.senderRegion))")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(SolarisTheme.textSecondary)
                                            }
                                            Spacer()
                                            Text(msg.timestamp)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(SolarisTheme.textSecondary)
                                        }
                                        Text(msg.text)
                                            .font(SolarisTheme.bodyLarge)
                                            .foregroundColor(SolarisTheme.textPrimary)
                                            .textSelection(.enabled)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(msg.isSelf ? SolarisTheme.mint.opacity(0.12) : SolarisTheme.cardElevated)
                                    )
                                }
                            }
                        }
                        .frame(height: 330)

                        HStack(spacing: 10) {
                            TextField(L10n.tr(vm.language,
                                de: "Nachricht an Internet-Verbund (oder /status, /layers, /ping)...",
                                en: "Message to Internet cluster (or /status, /layers, /ping)...",
                                fr: "Message au cluster Internet (ou /status, /layers, /ping)...",
                                es: "Mensaje al clúster de Internet (o /status, /layers, /ping)...",
                                pt: "Mensagem para o cluster Internet (ou /status, /layers, /ping)...",
                                ru: "Сообщение в интернет-кластер (или /status, /layers, /ping)...",
                                ja: "インターネットクラスタへ送信（または /status, /layers, /ping）...",
                                zh: "向互联网集群发送消息（或输入 /status、/layers、/ping）..."), text: $vm.chatInput)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    vm.sendClusterChatMessage()
                                }
                            Button {
                                vm.sendClusterChatMessage()
                            } label: {
                                Label(L10n.tr(vm.language, de: "Senden", en: "Send", fr: "Envoyer", es: "Enviar", pt: "Enviar", ru: "Отправить", ja: "送信", zh: "发送"), systemImage: "paperplane.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SolarisTheme.amber)
                            .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .onAppear {
            if vm.audioPartyMembers.isEmpty {
                vm.syncAudioPartyMembers()
            }
        }
    }

    // MARK: - Internet Bandwidth & Throughput Performance Monitor

    private var wanBandwidthMonitorCard: some View {
        SolarisCard(accent: vm.simulateMacStudio ? SolarisTheme.amber : SolarisTheme.emerald) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "speedometer")
                            .foregroundColor(vm.simulateMacStudio ? SolarisTheme.amberGlow : SolarisTheme.emerald)
                        Text(L10n.tr(vm.language,
                            de: "Internetbandbreite & WAN-Datendurchsatz",
                            en: "Internet Bandwidth & WAN Throughput",
                            fr: "Bande passante Internet & débit WAN",
                            es: "Ancho de banda de Internet y rendimiento WAN",
                            pt: "Largura de banda e débito WAN",
                            ru: "Интернет-канал и пропускная способность WAN",
                            ja: "インターネット帯域幅・WAN スループット",
                            zh: "互联网带宽与 WAN 吞吐量"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(vm.simulateMacStudio
                            ? L10n.tr(vm.language, de: "SIMULATION", en: "SIMULATION", fr: "SIMULATION", es: "SIMULACIÓN", pt: "SIMULAÇÃO", ru: "СИМУЛЯЦИЯ", ja: "シミュレーション", zh: "模拟运行")
                            : L10n.tr(vm.language, de: "ECHTZEIT-MESSUNG", en: "LIVE MEASUREMENT", fr: "MESURE EN DIRECT", es: "MEDICIÓN EN VIVO", pt: "MEDIÇÃO AO VIVO", ru: "ЗАМЕР LIVE", ja: "実測中", zh: "实时测量"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(vm.simulateMacStudio ? SolarisTheme.amber : SolarisTheme.emerald)
                            .cornerRadius(5)
                    }
                    Text("\(vm.wanBandwidthSourceLabel) · \(L10n.tr(vm.language, de: "Interface", en: "Interface", fr: "Interface", es: "Interfaz", pt: "Interface", ru: "Интерфейс", ja: "IF", zh: "接口")): \(vm.wanActiveInterfaceName) · \(L10n.tr(vm.language, de: "Letztes Update", en: "Last Update", fr: "Dernière MAJ", es: "Última actualización", pt: "Última atualização", ru: "Обновлено", ja: "最終更新", zh: "最后更新")): \(vm.wanBandwidthLastUpdated)")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        vm.probeWanBandwidthAndThroughput(runActiveSpeedTest: false)
                    } label: {
                        Label(
                            vm.isProbingWanBandwidth
                                ? L10n.tr(vm.language, de: "Messe...", en: "Measuring...", fr: "Mesure...", es: "Midiendo...", pt: "A medir...", ru: "Замер...", ja: "計測中...", zh: "测量中...")
                                : L10n.tr(vm.language, de: "Live-Check (Ping + Net)", en: "Live Check (Ping + Net)", fr: "Test direct (Ping + Net)", es: "Comprobar (Ping + Red)", pt: "Teste ao vivo (Ping + Rede)", ru: "Проверка (Ping + Сеть)", ja: "ライブチェック (Ping + Net)", zh: "实时检测 (Ping + 网络)"),
                            systemImage: "waveform.path.ecg"
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(vm.isProbingWanBandwidth)

                    Button {
                        vm.probeWanBandwidthAndThroughput(runActiveSpeedTest: true)
                    } label: {
                        Label(L10n.tr(vm.language,
                            de: "Speedtest (networkQuality)",
                            en: "Speedtest (networkQuality)",
                            fr: "Test de débit (networkQuality)",
                            es: "Test de velocidad (networkQuality)",
                            pt: "Teste de velocidade (networkQuality)",
                            ru: "Тест скорости (networkQuality)",
                            ja: "スピードテスト (networkQuality)",
                            zh: "网速测试 (networkQuality)"), systemImage: "gauge.with.dots.needle.67percent")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SolarisTheme.mint)
                    .foregroundColor(.black)
                    .disabled(vm.isProbingWanBandwidth)
                }
            }

            // 4 Network & Throughput KPIs
            HStack(spacing: 12) {
                WanMetricTile(
                    title: L10n.tr(vm.language, de: "Download-Bandbreite", en: "Download Bandwidth", fr: "Bande passante descendante", es: "Ancho de banda descarga", pt: "Largura de banda download", ru: "Скорость скачивания", ja: "下り帯域幅", zh: "下行带宽"),
                    value: String(format: "%.1f Mbps", vm.wanMeasuredDownloadMbps),
                    sub: String(format: "≈ %.1f MB/s RX", vm.wanMeasuredDownloadMbps / 8.0),
                    accent: SolarisTheme.mint
                )
                WanMetricTile(
                    title: L10n.tr(vm.language, de: "Upload / Cluster-Uplink", en: "Upload / Cluster Uplink", fr: "Upload / Lien montant", es: "Subida / Enlace clúster", pt: "Upload / Ligação cluster", ru: "Аплоад / Канал кластера", ja: "上り / クラスタアップリンク", zh: "上行 / 集群带宽"),
                    value: String(format: "%.1f Mbps", vm.wanMeasuredUploadMbps),
                    sub: String(format: L10n.tr(vm.language,
                        de: "Engpass: %.1f Mbps (%.1f MB/s)",
                        en: "Bottleneck: %.1f Mbps (%.1f MB/s)",
                        fr: "Goulot : %.1f Mbps (%.1f Mo/s)",
                        es: "Cuello: %.1f Mbps (%.1f MB/s)",
                        pt: "Gargalo: %.1f Mbps (%.1f MB/s)",
                        ru: "Узкое место: %.1f Мбит/с (%.1f МБ/с)",
                        ja: "ボトルネック: %.1f Mbps (%.1f MB/s)",
                        zh: "瓶颈：%.1f Mbps (%.1f MB/s)"), vm.wanBottleneckUplinkMbps, vm.wanEffectivePayloadMBs),
                    accent: SolarisTheme.amberGlow
                )
                WanMetricTile(
                    title: L10n.tr(vm.language, de: "WAN-Ping & Jitter", en: "WAN Ping & Jitter", fr: "Ping WAN & Gigue", es: "Ping WAN y Jitter", pt: "Ping WAN e Jitter", ru: "WAN Ping и джиттер", ja: "WAN Ping・ジッター", zh: "WAN 延迟与抖动"),
                    value: String(format: "%.1f ms", vm.wanMeasuredPingMs),
                    sub: String(format: L10n.tr(vm.language,
                        de: "Jitter ±%.2f ms · Hop-Sync %.1f ms",
                        en: "Jitter ±%.2f ms · Hop Sync %.1f ms",
                        fr: "Gigue ±%.2f ms · Sync saut %.1f ms",
                        es: "Jitter ±%.2f ms · Sinc salto %.1f ms",
                        pt: "Jitter ±%.2f ms · Sinc salto %.1f ms",
                        ru: "Джиттер ±%.2f мс · Синхр %.1f мс",
                        ja: "ジッター ±%.2f ms · ホップ同期 %.1f ms",
                        zh: "抖动 ±%.2f ms · 跳同步 %.1f ms"), vm.wanMeasuredJitterMs, vm.wanActivationSyncOverheadMs),
                    accent: SolarisTheme.amber
                )
                WanMetricTile(
                    title: L10n.tr(vm.language, de: "Paketverlust & Effizienz", en: "Packet Loss & Efficiency", fr: "Pertes & Efficacité", es: "Pérdida y Eficiencia", pt: "Perda e Eficiência", ru: "Потери и эффективность", ja: "パケット損失・効率", zh: "丢包率与效率"),
                    value: String(format: "%.1f%% / %.1f%%", vm.wanMeasuredPacketLossPct, vm.wanPipelineEfficiencyPct),
                    sub: L10n.tr(vm.language,
                        de: "Loss % / GPU-Compute-Anteil",
                        en: "Loss % / GPU Compute Ratio",
                        fr: "Pertes % / Ratio calcul GPU",
                        es: "Pérdida % / Ratio GPU",
                        pt: "Perda % / Rácio GPU",
                        ru: "Потери % / Доля вычислений GPU",
                        ja: "損失率 % / GPU計算比率",
                        zh: "丢包率 / GPU 计算占比"),
                    accent: vm.wanMeasuredPacketLossPct > 1.0 ? SolarisTheme.coral : SolarisTheme.emerald
                )
            }

            // Cluster Performance Impact Summary Banner
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr(vm.language,
                        de: "Leistungsauswirkung auf den Internet-Cluster",
                        en: "Performance Impact on Internet Cluster",
                        fr: "Impact sur les performances du cluster Internet",
                        es: "Impacto en el rendimiento del clúster de Internet",
                        pt: "Impacto de desempenho no cluster Internet",
                        ru: "Влияние на производительность интернет-кластера",
                        ja: "インターネットクラスタ性能への影響",
                        zh: "对互联网集群性能的影响"))
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("\(L10n.tr(vm.language, de: "Bewertung", en: "Rating", fr: "Évaluation", es: "Valoración", pt: "Avaliação", ru: "Оценка", ja: "評価", zh: "评级")): \(vm.wanConnectionQualityGrade)")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: L10n.tr(vm.language,
                        de: "Netto-Nutzdaten: %.2f MB/s",
                        en: "Net Payload: %.2f MB/s",
                        fr: "Débit utile net : %.2f Mo/s",
                        es: "Datos útiles netos: %.2f MB/s",
                        pt: "Dados úteis líquidos: %.2f MB/s",
                        ru: "Полезный поток: %.2f МБ/с",
                        ja: "実効ペイロード: %.2f MB/s",
                        zh: "净有效载荷：%.2f MB/s"), vm.wanEffectivePayloadMBs))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(SolarisTheme.emerald)
                    Text(String(format: L10n.tr(vm.language,
                        de: "Resultierender Durchsatz: %.2f tok/s",
                        en: "Resulting Throughput: %.2f tok/s",
                        fr: "Débit résultant : %.2f tok/s",
                        es: "Rendimiento resultante: %.2f tok/s",
                        pt: "Débito resultante: %.2f tok/s",
                        ru: "Итоговая скорость: %.2f tok/с",
                        ja: "実効スループット: %.2f tok/s",
                        zh: "最终吞吐率：%.2f tok/s"), vm.wanEstimatedTokPerSec))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(SolarisTheme.amberGlow)
                }
            }
            .padding(10)
            .background(SolarisTheme.cardElevated)
            .cornerRadius(10)

            // Throughput History Bar Chart (Download vs Upload)
            if !vm.wanThroughputHistory.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n.tr(vm.language,
                            de: "Durchsatz-Verlauf (letzte \(vm.wanThroughputHistory.count) Messungen)",
                            en: "Throughput History (last \(vm.wanThroughputHistory.count) checks)",
                            fr: "Historique du débit (\(vm.wanThroughputHistory.count) dernières mesures)",
                            es: "Historial de rendimiento (últimas \(vm.wanThroughputHistory.count) mediciones)",
                            pt: "Histórico de débito (últimas \(vm.wanThroughputHistory.count) medições)",
                            ru: "История скорости (последние \(vm.wanThroughputHistory.count) замеров)",
                            ja: "スループット履歴（直近 \(vm.wanThroughputHistory.count) 回）",
                            zh: "吞吐历史（最近 \(vm.wanThroughputHistory.count) 次测量）"))
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        HStack(spacing: 12) {
                            Label("Download (Mbps)", systemImage: "square.fill")
                                .font(Font.caption2)
                                .foregroundColor(SolarisTheme.mint)
                            Label("Upload (Mbps)", systemImage: "square.fill")
                                .font(Font.caption2)
                                .foregroundColor(SolarisTheme.amber)
                        }
                    }
                    let maxMbps = max(10.0, vm.wanThroughputHistory.map { max($0.downloadMbps, $0.uploadMbps) }.max() ?? 100.0)
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(vm.wanThroughputHistory) { sample in
                            VStack(spacing: 2) {
                                HStack(alignment: .bottom, spacing: 2) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(SolarisTheme.mint)
                                        .frame(width: 8, height: max(4, CGFloat(sample.downloadMbps / maxMbps) * 56.0))
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(SolarisTheme.amber)
                                        .frame(width: 8, height: max(4, CGFloat(sample.uploadMbps / maxMbps) * 56.0))
                                }
                                Text(String(format: "%.0fms", sample.pingRttMs))
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(SolarisTheme.cardElevated)
                    .cornerRadius(10)
                }
            }

            // Punkt 1: QUIC / Iroh P2P WAN-Transport (0-RTT Multiplex ohne TCP HoL-Blocking)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(L10n.tr(vm.language,
                        de: "WAN-Transport-Protokoll (QUIC / Iroh P2P)",
                        en: "WAN Transport Protocol (QUIC / Iroh P2P)",
                        fr: "Protocole de transport WAN (QUIC / Iroh P2P)",
                        es: "Protocolo de transporte WAN (QUIC / Iroh P2P)",
                        pt: "Protocolo de transporte WAN (QUIC / Iroh P2P)",
                        ru: "Транспортный протокол WAN (QUIC / Iroh P2P)",
                        ja: "WAN トランスポートプロトコル (QUIC / Iroh P2P)",
                        zh: "WAN 传输协议 (QUIC / Iroh P2P)"), systemImage: "bolt.horizontal.circle.fill")
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.mint)
                    Spacer()
                    let zeroRttState = vm.wanTransportProtocol.zeroRttEnabled
                        ? L10n.tr(vm.language, de: "AKTIV", en: "ACTIVE", fr: "ACTIF", es: "ACTIVO", pt: "ATIVO", ru: "АКТИВЕН", ja: "有効", zh: "已启用")
                        : L10n.tr(vm.language, de: "AUS", en: "OFF", fr: "DÉSACTIVÉ", es: "DESACTIVADO", pt: "DESATIVADO", ru: "ВЫКЛ", ja: "無効", zh: "关闭")
                    Text(String(format: L10n.tr(vm.language,
                        de: "Latenz-Faktor %.2f× · 0-RTT %@",
                        en: "Latency Factor %.2f× · 0-RTT %@",
                        fr: "Facteur latence %.2f× · 0-RTT %@",
                        es: "Factor latencia %.2f× · 0-RTT %@",
                        pt: "Fator latência %.2f× · 0-RTT %@",
                        ru: "Коэф. задержки %.2f× · 0-RTT %@",
                        ja: "遅延係数 %.2f× · 0-RTT %@",
                        zh: "延迟系数 %.2f× · 0-RTT %@"), vm.wanTransportLatencyFactor, zeroRttState))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(vm.wanTransportProtocol.zeroRttEnabled ? SolarisTheme.emerald : SolarisTheme.amber)
                        .cornerRadius(5)
                }

                Picker(L10n.tr(vm.language, de: "WAN-Transport", en: "WAN Transport", fr: "Transport WAN", es: "Transporte WAN", pt: "Transporte WAN", ru: "WAN-транспорт", ja: "WAN トランスポート", zh: "WAN 传输"), selection: $vm.wanTransportProtocol) {
                    ForEach(WanTransportProtocol.allCases) { proto in
                        Text(proto.localizedTitle(vm.language)).tag(proto)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(10)
            .background(SolarisTheme.cardElevated)
            .cornerRadius(10)
        }
    }

    // MARK: - Cluster Audio-Party Card (Xbox / PlayStation-Style for Distributed AI)

    private var audioPartyCard: some View {
        SolarisCard(accent: vm.audioPartyJoined ? SolarisTheme.emerald : SolarisTheme.amber) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Image(systemName: vm.audioPartyJoined ? "headphones.circle.fill" : "mic.circle.fill")
                            .foregroundColor(vm.audioPartyJoined ? SolarisTheme.emerald : SolarisTheme.amberGlow)
                        Text(L10n.tr(vm.language,
                            de: "Cluster Audio-Party",
                            en: "Cluster Audio Party",
                            fr: "Salon Audio Cluster",
                            es: "Sala de Audio del Clúster",
                            pt: "Festa Áudio do Cluster",
                            ru: "Аудио-комната кластера",
                            ja: "クラスタ・オーディオパーティ",
                            zh: "集群语音派对"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                    }
                    Text(vm.audioPartyStatusText)
                        .font(.caption)
                        .foregroundColor(vm.audioPartyJoined ? SolarisTheme.emerald : SolarisTheme.textSecondary)
                }
                Spacer()
                Button {
                    vm.toggleAudioParty()
                } label: {
                    Label(
                        vm.audioPartyJoined
                            ? L10n.tr(vm.language, de: "Party verlassen", en: "Leave Party", fr: "Quitter le salon", es: "Salir de la sala", pt: "Sair da festa", ru: "Покинуть комнату", ja: "パーティを退出", zh: "离开派对")
                            : L10n.tr(vm.language, de: "Party beitreten", en: "Join Party", fr: "Rejoindre le salon", es: "Unirse a la sala", pt: "Entrar na festa", ru: "Войти в комнату", ja: "パーティに参加", zh: "加入派对"),
                        systemImage: vm.audioPartyJoined ? "phone.down.fill" : "phone.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.audioPartyJoined ? SolarisTheme.coral : SolarisTheme.emerald)
                .foregroundColor(.black)
            }

            // Party Controls: Mute, Deafen, Push-to-Talk, Noise Gate
            HStack(spacing: 10) {
                Button {
                    vm.togglePartyMute()
                } label: {
                    Label(vm.audioPartyMuted
                        ? L10n.tr(vm.language, de: "Stumm", en: "Muted", fr: "Muet", es: "Silenciado", pt: "Silenciado", ru: "Без звука", ja: "ミュート", zh: "已静音")
                        : L10n.tr(vm.language, de: "Mikro an", en: "Mic On", fr: "Micro activé", es: "Micro activo", pt: "Micro ativo", ru: "Микр. вкл", ja: "マイクオン", zh: "麦克风开启"),
                          systemImage: vm.audioPartyMuted ? "mic.slash.fill" : "mic.fill")
                }
                .buttonStyle(.bordered)
                .tint(vm.audioPartyMuted ? SolarisTheme.coral : SolarisTheme.mint)

                Button {
                    vm.togglePartyDeafen()
                } label: {
                    Label(vm.audioPartyDeafened
                        ? L10n.tr(vm.language, de: "Ton aus", en: "Deafened", fr: "Sourdine", es: "Audio apagado", pt: "Som desligado", ru: "Звук выкл", ja: "スピーカーオフ", zh: "静音输出")
                        : L10n.tr(vm.language, de: "Ton an", en: "Audio On", fr: "Audio activé", es: "Audio activo", pt: "Som ativo", ru: "Звук вкл", ja: "スピーカーオン", zh: "声音开启"),
                          systemImage: vm.audioPartyDeafened ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                .tint(vm.audioPartyDeafened ? SolarisTheme.coral : SolarisTheme.amber)

                if vm.audioPartyMicMode == .pushToTalk {
                    Button {
                        vm.triggerPushToTalk(active: !vm.audioPartyPushToTalkActive)
                    } label: {
                        Label(vm.audioPartyPushToTalkActive
                            ? L10n.tr(vm.language, de: "Funk aktiv", en: "PTT Active", fr: "PTT actif", es: "PTT activo", pt: "PTT ativo", ru: "Рация активна", ja: "送信中", zh: "正在通话")
                            : L10n.tr(vm.language, de: "Funk-Taste", en: "Push-to-Talk", fr: "Appuyer pour parler", es: "Pulsar para hablar", pt: "Premir para falar", ru: "Рация (PTT)", ja: "プッシュトゥトーク", zh: "按键通话"),
                              systemImage: "waveform.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(vm.audioPartyPushToTalkActive ? SolarisTheme.amber : SolarisTheme.cardElevated)
                }

                Spacer()

                // Live Mic Level Bar
                HStack(spacing: 6) {
                    Text(L10n.tr(vm.language, de: "Pegel", en: "Level", fr: "Niveau", es: "Nivel", pt: "Nível", ru: "Уровень", ja: "レベル", zh: "音量"))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(SolarisTheme.textSecondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(SolarisTheme.cardElevated)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(vm.audioPartyMicLevel > 0.14 ? SolarisTheme.emerald : SolarisTheme.mint)
                                .frame(width: max(2, geo.size.width * CGFloat(vm.audioPartyMicLevel)))
                        }
                    }
                    .frame(width: 72, height: 8)
                }
            }

            // Codec, Mic Mode & Bandwidth Footprint
            HStack(spacing: 12) {
                Picker(L10n.tr(vm.language, de: "Mikro-Modus", en: "Mic Mode", fr: "Mode micro", es: "Modo micro", pt: "Modo micro", ru: "Режим микрофона", ja: "マイクモード", zh: "麦克风模式"), selection: $vm.audioPartyMicMode) {
                    ForEach(AudioPartyMicMode.allCases) { m in
                        Text(m.localizedTitle(vm.language)).tag(m)
                    }
                }
                .labelsHidden()

                Picker(L10n.tr(vm.language, de: "Codec", en: "Codec", fr: "Codec", es: "Códec", pt: "Codec", ru: "Кодек", ja: "コーデック", zh: "编解码器"), selection: $vm.audioPartyCodec) {
                    ForEach(AudioPartyCodec.allCases) { c in
                        Text(c.localizedTitle(vm.language)).tag(c)
                    }
                }
                .labelsHidden()

                Toggle(L10n.tr(vm.language, de: "Rausch-Sperre", en: "Noise Gate", fr: "Réduction bruit", es: "Supresor de ruido", pt: "Porta de ruído", ru: "Шумоподавл.", ja: "ノイズゲート", zh: "噪声门限"), isOn: $vm.audioPartyNoiseGate)
                    .toggleStyle(.switch)
                    .font(.caption)
            }

            Text(String(format: L10n.tr(vm.language,
                de: "Sprach-Anteil am WAN-Uplink: %.3f %% (Rest bleibt frei für Tensor-Aktivierungen)",
                en: "Voice share of WAN uplink: %.3f %% (remainder reserved for tensor activations)",
                fr: "Part vocale du lien WAN : %.3f %% (reste dédié aux tenseurs)",
                es: "Uso de voz en WAN: %.3f %% (el resto queda libre para activaciones)",
                pt: "Parcela de voz no WAN: %.3f %% (restante livre para tensores)",
                ru: "Доля речи в канале WAN: %.3f %% (остальное свободно для тензоров)",
                ja: "WAN 上り回線の音声占有率: %.3f %% (残りはテンソル転送用)",
                zh: "语音占用 WAN 上行比例：%.3f %%（其余带宽保留给张量激活）"), vm.audioPartyBandwidthSharePercent))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SolarisTheme.mint)

            // Party Member Roster (Xbox/PS-style cards with speaking rings & per-peer volume)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(vm.audioPartyMembers) { member in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(member.isSelf ? SolarisTheme.amber.opacity(0.22) : SolarisTheme.mint.opacity(0.18))
                                    .frame(width: 34, height: 34)
                                Circle()
                                    .stroke(member.isSpeaking ? SolarisTheme.emerald : (member.isMuted ? SolarisTheme.coral.opacity(0.5) : Color.white.opacity(0.14)),
                                            lineWidth: member.isSpeaking ? 2.5 : 1.0)
                                    .frame(width: 34, height: 34)
                                Image(systemName: member.isMuted ? "mic.slash" : (member.isSpeaking ? "waveform" : "desktopcomputer"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(member.isSpeaking ? SolarisTheme.emerald : SolarisTheme.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(member.displayName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(SolarisTheme.textPrimary)
                                    Text(member.roleBadge)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(member.isSelf ? SolarisTheme.amberGlow : SolarisTheme.mint)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(SolarisTheme.cardElevated)
                                        .cornerRadius(4)
                                }
                                Text("\(member.chip) · \(member.assignedLayers) · \(Int(member.voicePingMs)) ms")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }

                            Spacer()

                            if !member.isSelf {
                                Slider(
                                    value: Binding(
                                        get: { member.volumePercent },
                                        set: { vm.setMemberVolume(id: member.id, volume: $0) }
                                    ),
                                    in: 0...150,
                                    step: 10
                                )
                                .frame(width: 70)
                                .tint(SolarisTheme.mint)
                            }

                            Button {
                                vm.toggleMemberMute(id: member.id)
                            } label: {
                                Image(systemName: member.isMuted ? "speaker.slash.fill" : "speaker.wave.2")
                                    .foregroundColor(member.isMuted ? SolarisTheme.coral : SolarisTheme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(member.isSpeaking ? SolarisTheme.emerald.opacity(0.10) : SolarisTheme.cardElevated)
                        )
                    }
                }
            }
            .frame(height: 175)

            // Cluster-Specific Quick Callouts
            HStack(spacing: 8) {
                Button(L10n.tr(vm.language, de: "✓ Bereit", en: "✓ Ready", fr: "✓ Prêt", es: "✓ Listo", pt: "✓ Pronto", ru: "✓ Готов", ja: "✓ 準備完了", zh: "✓ 就绪")) {
                    vm.sendPartyCallout(L10n.tr(vm.language,
                        de: "Knoten bereit für verteilte Inferenz.",
                        en: "Node ready for distributed inference.",
                        fr: "Nœud prêt pour l'inférence distribuée.",
                        es: "Nodo listo para inferencia distribuida.",
                        pt: "Nó pronto para inferência distribuída.",
                        ru: "Узел готов к распределённому инференсу.",
                        ja: "分散推論の準備が整いました。",
                        zh: "节点已准备好进行分布式推理。"))
                }
                .buttonStyle(.bordered)
                Button(L10n.tr(vm.language, de: "⚠ KV knapp", en: "⚠ KV Tight", fr: "⚠ KV limite", es: "⚠ KV justo", pt: "⚠ KV apertado", ru: "⚠ Мало KV", ja: "⚠ KV 逼迫", zh: "⚠ KV 紧张")) {
                    vm.sendPartyCallout(L10n.tr(vm.language,
                        de: "Speicher/KV-Cache knapp — bitte auf 4-Bit KV wechseln!",
                        en: "Memory/KV cache tight — please switch to 4-bit KV!",
                        fr: "Mémoire/cache KV serré — passez en KV 4-bit !",
                        es: "Memoria/caché KV justa — ¡cambia a KV de 4 bits!",
                        pt: "Memória/cache KV apertado — mude para KV de 4 bits!",
                        ru: "Мало памяти/KV-кэша — переключитесь на 4-битный KV!",
                        ja: "メモリ/KVキャッシュが逼迫しています — 4-bit KV へ切替えてください！",
                        zh: "显存/KV 缓存紧张 — 请切换至 4-bit KV 量化！"))
                }
                .buttonStyle(.bordered)
                Button(L10n.tr(vm.language, de: "↻ Schichten", en: "↻ Layers", fr: "↻ Couches", es: "↻ Capas", pt: "↻ Camadas", ru: "↻ Слои", ja: "↻ 層再配分", zh: "↻ 重算分层")) {
                    vm.recomputeWanLayerAssignments()
                    vm.syncAudioPartyMembers()
                    vm.sendPartyCallout(L10n.tr(vm.language,
                        de: "Schichtenverteilung im Verbund neu berechnet.",
                        en: "Cluster layer sharding recomputed.",
                        fr: "Répartition des couches recalculée.",
                        es: "Distribución de capas recalculada.",
                        pt: "Distribuição de camadas recalculada.",
                        ru: "Распределение слоёв в кластере пересчитано.",
                        ja: "クラスタ内の層分割を再計算しました。",
                        zh: "已重新计算集群层分配。"))
                }
                .buttonStyle(.bordered)
                Button(L10n.tr(vm.language, de: "▶ T=0,0 Start", en: "▶ T=0.0 Start", fr: "▶ Départ T=0,0", es: "▶ Inicio T=0,0", pt: "▶ Início T=0,0", ru: "▶ Старт T=0,0", ja: "▶ T=0.0 開始", zh: "▶ T=0.0 开始")) {
                    vm.sendPartyCallout(L10n.tr(vm.language,
                        de: "Wissenschaftliche Messreihe (T=0,0) startet jetzt.",
                        en: "Scientific benchmark run (T=0.0) starting now.",
                        fr: "La série de mesures scientifiques (T=0,0) démarre maintenant.",
                        es: "La serie científica (T=0,0) comienza ahora.",
                        pt: "A série de medição científica (T=0,0) começa agora.",
                        ru: "Научный запуск (T=0,0) начинается сейчас.",
                        ja: "科学的ベンチマーク計測 (T=0.0) を開始します。",
                        zh: "科学基准测试系列 (T=0.0) 现已启动。"))
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)
        }
    }
}

private struct WanMetricTile: View {
    let title: String
    let value: String
    let sub: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(SolarisTheme.textSecondary)
            Text(value)
                .font(SolarisTheme.metricMedium)
                .foregroundColor(accent)
            Text(sub)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SolarisTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SolarisTheme.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.30), lineWidth: 1)
                )
        )
    }
}
