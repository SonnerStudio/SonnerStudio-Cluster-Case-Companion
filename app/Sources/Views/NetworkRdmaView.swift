import SwiftUI

struct NetworkRdmaView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SolarisCard(accent: SolarisTheme.amber) {
                    Text(vm.t("net_title"))
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(vm.t("net_sub"))
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)

                    HazardStripesBar(height: 6, stripeWidth: 10, cornerRadius: 3, opacity: 0.88)

                    VStack(spacing: 12) {
                        ForEach(TransportMode.allCases) { mode in
                            let selected = vm.transportMode == mode
                            Button {
                                vm.transportMode = mode
                            } label: {
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                                        .font(.system(size: 22))
                                        .foregroundColor(selected ? SolarisTheme.amber : SolarisTheme.textSecondary)
                                        .padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mode.localizedTitle(vm.language))
                                            .font(SolarisTheme.cardTitle)
                                            .foregroundColor(SolarisTheme.textPrimary)
                                        Text(mode.localizedDescription(vm.language))
                                            .font(SolarisTheme.bodyLarge)
                                            .foregroundColor(SolarisTheme.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selected ? SolarisTheme.amber.opacity(0.14) : SolarisTheme.cardElevated)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(selected ? SolarisTheme.amber : SolarisTheme.borderSubtle, lineWidth: 1.2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Thunderbolt-Klassen der Generationen M1–M9+
                SolarisCard(accent: SolarisTheme.mint) {
                    HStack {
                        Text(L10n.tr(vm.language,
                            de: "Thunderbolt-Klassen (M1–M9+) & Übertragungsraten",
                            en: "Thunderbolt Classes (M1–M9+) & Transfer Rates",
                            fr: "Classes Thunderbolt (M1–M9+) & débits",
                            es: "Clases Thunderbolt (M1–M9+) y tasas de transferencia",
                            pt: "Classes Thunderbolt (M1–M9+) e taxas de transferência",
                            ru: "Классы Thunderbolt (M1–M9+) и пропускная способность",
                            ja: "Thunderbolt クラス (M1–M9+) と転送速度",
                            zh: "Thunderbolt 级别 (M1–M9+) 与传输速率"))
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        Text("\(vm.effectiveLinkStats.badge) · \(vm.effectiveLinkStats.rangeLabel)")
                            .font(SolarisTheme.bodyBold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(SolarisTheme.amber.opacity(0.20)))
                            .foregroundColor(SolarisTheme.amberGlow)
                    }

                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                        GridRow {
                            Text(L10n.tr(vm.language, de: "Klasse", en: "Class", fr: "Classe", es: "Clase", pt: "Classe", ru: "Класс", ja: "クラス", zh: "级别")).foregroundColor(SolarisTheme.textSecondary)
                            Text(L10n.tr(vm.language, de: "Mac-Generationen", en: "Mac Generations", fr: "Générations de Mac", es: "Generaciones de Mac", pt: "Gerações de Mac", ru: "Поколения Mac", ja: "Mac 世代", zh: "Mac 世代")).foregroundColor(SolarisTheme.textSecondary)
                            Text(L10n.tr(vm.language, de: "Nenn- / Nutzrate", en: "Nominal / Effective Rate", fr: "Débit nominal / utile", es: "Tasa nominal / útil", pt: "Taxa nominal / efetiva", ru: "Номин. / факт. скорость", ja: "理論値 / 実効速度", zh: "标称 / 实测速率")).foregroundColor(SolarisTheme.textSecondary)
                            Text("RDMA / JACCL").foregroundColor(SolarisTheme.textSecondary)
                        }
                        .font(SolarisTheme.bodyBold)

                        Divider().gridCellUnsizedAxes(.horizontal)

                        GridRow {
                            Text("Thunderbolt 3 / USB4").foregroundColor(SolarisTheme.mint)
                            Text(L10n.tr(vm.language,
                                de: "M1 & M2 (Basis)",
                                en: "M1 & M2 (Base)",
                                fr: "M1 & M2 (Base)",
                                es: "M1 y M2 (Base)",
                                pt: "M1 & M2 (Base)",
                                ru: "M1 и M2 (базовые)",
                                ja: "M1 & M2 (ベース)",
                                zh: "M1 & M2（基础款）")).foregroundColor(SolarisTheme.textPrimary)
                            Text(L10n.tr(vm.language,
                                de: "40 Gbps (26–32 Gbps real)",
                                en: "40 Gbps (26–32 Gbps real)",
                                fr: "40 Gbps (26–32 Gbps réels)",
                                es: "40 Gbps (26–32 Gbps reales)",
                                pt: "40 Gbps (26–32 Gbps reais)",
                                ru: "40 Гбит/с (26–32 Гбит/с факт.)",
                                ja: "40 Gbps (実効 26–32 Gbps)",
                                zh: "40 Gbps（实测 26–32 Gbps）")).foregroundColor(SolarisTheme.textPrimary)
                            Text(L10n.tr(vm.language,
                                de: "Opt-In (IP/Bridge)",
                                en: "Opt-In (IP/Bridge)",
                                fr: "Opt-In (IP/Bridge)",
                                es: "Opt-In (IP/Bridge)",
                                pt: "Opt-In (IP/Bridge)",
                                ru: "Opt-In (IP/Bridge)",
                                ja: "オプトイン (IP/Bridge)",
                                zh: "可选开启 (IP/Bridge)")).foregroundColor(SolarisTheme.textSecondary)
                        }
                        GridRow {
                            Text("Thunderbolt 4").foregroundColor(SolarisTheme.amberGlow)
                            Text(L10n.tr(vm.language,
                                de: "M1–M3 Pro/Max/Ultra, M4 (Basis)",
                                en: "M1–M3 Pro/Max/Ultra, M4 (Base)",
                                fr: "M1–M3 Pro/Max/Ultra, M4 (Base)",
                                es: "M1–M3 Pro/Max/Ultra, M4 (Base)",
                                pt: "M1–M3 Pro/Max/Ultra, M4 (Base)",
                                ru: "M1–M3 Pro/Max/Ultra, M4 (базовый)",
                                ja: "M1–M3 Pro/Max/Ultra, M4 (ベース)",
                                zh: "M1–M3 Pro/Max/Ultra, M4（基础款）")).foregroundColor(SolarisTheme.textPrimary)
                            Text(L10n.tr(vm.language,
                                de: "40 Gbps (30–37 Gbps real)",
                                en: "40 Gbps (30–37 Gbps real)",
                                fr: "40 Gbps (30–37 Gbps réels)",
                                es: "40 Gbps (30–37 Gbps reales)",
                                pt: "40 Gbps (30–37 Gbps reais)",
                                ru: "40 Гбит/с (30–37 Гбит/с факт.)",
                                ja: "40 Gbps (実効 30–37 Gbps)",
                                zh: "40 Gbps（实测 30–37 Gbps）")).foregroundColor(SolarisTheme.textPrimary)
                            Text(L10n.tr(vm.language,
                                de: "Opt-In (34–38 Gbps)",
                                en: "Opt-In (34–38 Gbps)",
                                fr: "Opt-In (34–38 Gbps)",
                                es: "Opt-In (34–38 Gbps)",
                                pt: "Opt-In (34–38 Gbps)",
                                ru: "Opt-In (34–38 Гбит/с)",
                                ja: "オプトイン (34–38 Gbps)",
                                zh: "可选开启 (34–38 Gbps)")).foregroundColor(SolarisTheme.textSecondary)
                        }
                        GridRow {
                            Text("Thunderbolt 5").foregroundColor(SolarisTheme.emerald)
                            Text("M3 Ultra, M4 Pro/Max, M5–M9+").foregroundColor(SolarisTheme.textPrimary)
                            Text(L10n.tr(vm.language,
                                de: "80–120 Gbps (65–80 Gbps real)",
                                en: "80–120 Gbps (65–80 Gbps real)",
                                fr: "80–120 Gbps (65–80 Gbps réels)",
                                es: "80–120 Gbps (65–80 Gbps reales)",
                                pt: "80–120 Gbps (65–80 Gbps reais)",
                                ru: "80–120 Гбит/с (65–80 Гбит/с факт.)",
                                ja: "80–120 Gbps (実効 65–80 Gbps)",
                                zh: "80–120 Gbps（实测 65–80 Gbps）")).foregroundColor(SolarisTheme.textPrimary)
                            Text(L10n.tr(vm.language,
                                de: "Nativ (75–110 Gbps)",
                                en: "Native (75–110 Gbps)",
                                fr: "Natif (75–110 Gbps)",
                                es: "Nativo (75–110 Gbps)",
                                pt: "Nativo (75–110 Gbps)",
                                ru: "Нативно (75–110 Гбит/с)",
                                ja: "ネイティブ (75–110 Gbps)",
                                zh: "原生支持 (75–110 Gbps)")).foregroundColor(SolarisTheme.emerald)
                        }
                    }
                    .font(SolarisTheme.bodyLarge)
                }

                // MLX Performance & RDMA Hinweise
                SolarisCard {
                    Toggle(isOn: $vm.fastSynchEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("net_fast_synch"))
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.t("net_fast_synch_sub"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(SolarisTheme.amber)

                    Divider().background(SolarisTheme.borderSubtle)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(vm.t("net_checklist"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(L10n.tr(vm.language,
                            de: "1. Thunderbolt-Kabel zwischen den Macs verbinden & `scripts/setup_tb_network.sh` auf den Knoten ausführen.",
                            en: "1. Connect Thunderbolt cables between Macs & run `scripts/setup_tb_network.sh` on each node.",
                            fr: "1. Reliez les Macs par câble Thunderbolt & exécutez `scripts/setup_tb_network.sh` sur chaque nœud.",
                            es: "1. Conecta cables Thunderbolt entre los Macs y ejecuta `scripts/setup_tb_network.sh` en cada nodo.",
                            pt: "1. Conecte os cabos Thunderbolt entre os Macs e execute `scripts/setup_tb_network.sh` nos nós.",
                            ru: "1. Соедините Mac кабелями Thunderbolt и выполните `scripts/setup_tb_network.sh` на узлах.",
                            ja: "1. Mac間をThunderboltケーブルで接続し、各ノードで `scripts/setup_tb_network.sh` を実行します。",
                            zh: "1. 使用 Thunderbolt 线缆连接各台 Mac，并在节点上执行 `scripts/setup_tb_network.sh`。"))
                        Text(L10n.tr(vm.language,
                            de: "2. Mit `iperf3 -c 10.99.1.1` Durchsatz prüfen (TB3/4: ~26–37 Gbps, TB5: ~65–80+ Gbps).",
                            en: "2. Check throughput via `iperf3 -c 10.99.1.1` (TB3/4: ~26–37 Gbps, TB5: ~65–80+ Gbps).",
                            fr: "2. Testez le débit avec `iperf3 -c 10.99.1.1` (TB3/4 : ~26–37 Gbps, TB5 : ~65–80+ Gbps).",
                            es: "2. Comprueba el rendimiento con `iperf3 -c 10.99.1.1` (TB3/4: ~26–37 Gbps, TB5: ~65–80+ Gbps).",
                            pt: "2. Verifique o débito com `iperf3 -c 10.99.1.1` (TB3/4: ~26–37 Gbps, TB5: ~65–80+ Gbps).",
                            ru: "2. Проверьте скорость через `iperf3 -c 10.99.1.1` (TB3/4: ~26–37 Гбит/с, TB5: ~65–80+ Гбит/с).",
                            ja: "2. `iperf3 -c 10.99.1.1` で実効帯域を確認します（TB3/4: ~26–37 Gbps、TB5: ~65–80+ Gbps）。",
                            zh: "2. 使用 `iperf3 -c 10.99.1.1` 测试带宽（TB3/4：~26–37 Gbps，TB5：~65–80+ Gbps）。"))
                        Text(L10n.tr(vm.language,
                            de: "3. Nachbildung unten links bei Bedarf abschalten — Bonjour erkennt verbundene Macs selbsttätig.",
                            en: "3. Toggle simulation off at bottom-left if needed — Bonjour detects connected Macs automatically.",
                            fr: "3. Désactivez la simulation en bas à gauche si besoin — Bonjour détecte automatiquement les Macs connectés.",
                            es: "3. Desactiva la simulación abajo a la izquierda si hace falta — Bonjour detecta Macs conectados automáticamente.",
                            pt: "3. Desative a simulação no canto inferior esquerdo se necessário — o Bonjour deteta Macs automaticamente.",
                            ru: "3. При необходимости отключите симуляцию слева внизу — Bonjour сам обнаружит подключённые Mac.",
                            ja: "3. 必要に応じて左下のシミュレーションをオフにしてください — Bonjour が接続済みのMacを自動検出します。",
                            zh: "3. 如需关闭左下角的模拟节点，Bonjour 会自动发现已连接的 Mac。"))
                    }
                    .font(SolarisTheme.bodyLarge)
                    .foregroundColor(SolarisTheme.textSecondary)
                }

                // Punkt 1: TB5 RDMA Tensor Parallelism (JACCL Full-Mesh vs. Ring) & mlx.distributed_config
                SolarisCard(accent: SolarisTheme.emerald) {
                    HStack {
                        Label(L10n.tr(vm.language,
                            de: "TB5 RDMA Tensor Parallelism & JACCL Full-Mesh",
                            en: "TB5 RDMA Tensor Parallelism & JACCL Full-Mesh",
                            fr: "Parallélisme tensoriel TB5 RDMA & Full-Mesh JACCL",
                            es: "Paralelismo tensorial TB5 RDMA y malla completa JACCL",
                            pt: "Paralelismo tensorial TB5 RDMA e Full-Mesh JACCL",
                            ru: "Тензорный параллелизм TB5 RDMA и JACCL Full-Mesh",
                            ja: "TB5 RDMA テンソル並列 & JACCL フルメッシュ",
                            zh: "TB5 RDMA 张量并行与 JACCL 全互联"), systemImage: "point.3.connected.trianglepath.dotted")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.emerald)
                        Spacer()
                        Text(vm.clusterMeshTopology.shortLabel)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SolarisTheme.emerald)
                            .cornerRadius(6)
                    }

                    Picker(L10n.tr(vm.language,
                        de: "Cluster-Topologie",
                        en: "Cluster Topology",
                        fr: "Topologie du cluster",
                        es: "Topología del clúster",
                        pt: "Topologia do cluster",
                        ru: "Топология кластера",
                        ja: "クラスタトポロジ",
                        zh: "集群拓扑"), selection: $vm.clusterMeshTopology) {
                        ForEach(ClusterMeshTopology.allCases) { topo in
                            Text(topo.localizedTitle(vm.language)).tag(topo)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(L10n.tr(vm.language,
                        de: "• `bridge0`-Schutz & `rdma_ctl enable`: Verhindert Kernel-Panics durch parallele Thunderbolt-IP-Bridges und nutzt dedizierte Per-Port-IPs (`10.99.x.y`).",
                        en: "• `bridge0` protection & `rdma_ctl enable`: Prevents kernel panics caused by parallel Thunderbolt-IP bridges and assigns dedicated per-port IPs (`10.99.x.y`).",
                        fr: "• Protection `bridge0` & `rdma_ctl enable` : évite les kernel panics liés aux ponts IP Thunderbolt parallèles et utilise des IP dédiées par port (`10.99.x.y`).",
                        es: "• Protección `bridge0` y `rdma_ctl enable`: evita kernel panics por puentes IP Thunderbolt paralelos y usa IPs dedicadas por puerto (`10.99.x.y`).",
                        pt: "• Proteção `bridge0` e `rdma_ctl enable`: evita kernel panics por bridges IP Thunderbolt paralelas e usa IPs dedicados por porta (`10.99.x.y`).",
                        ru: "• Защита `bridge0` и `rdma_ctl enable`: предотвращает kernel panic от параллельных IP-мостов Thunderbolt и выделяет IP на каждый порт (`10.99.x.y`).",
                        ja: "• `bridge0` 保護と `rdma_ctl enable`: 並列Thunderbolt-IPブリッジによるカーネルパニックを防ぎ、ポート専用IP（`10.99.x.y`）を使用します。",
                        zh: "• `bridge0` 保护与 `rdma_ctl enable`：避免并行 Thunderbolt-IP 网桥引发内核崩溃，并使用端口专用 IP (`10.99.x.y`)。"))
                        .font(.caption)
                        .foregroundColor(SolarisTheme.textSecondary)

                    Text(vm.rdmaPreflightCommand())
                        .font(SolarisTheme.monoCode)
                        .foregroundColor(SolarisTheme.mint)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.45))
                        .cornerRadius(8)

                    HStack(spacing: 12) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.generateMlxDistributedHostfileJSON(), forType: .string)
                            vm.sotaConfigCopiedBanner = L10n.tr(vm.language,
                                de: "mlx.distributed_config JSON kopiert",
                                en: "mlx.distributed_config JSON copied",
                                fr: "JSON mlx.distributed_config copié",
                                es: "JSON mlx.distributed_config copiado",
                                pt: "JSON mlx.distributed_config copiado",
                                ru: "JSON mlx.distributed_config скопирован",
                                ja: "mlx.distributed_config JSON をコピーしました",
                                zh: "已复制 mlx.distributed_config JSON")
                        } label: {
                            Label(L10n.tr(vm.language,
                                de: "mlx.distributed_config kopieren",
                                en: "Copy mlx.distributed_config",
                                fr: "Copier mlx.distributed_config",
                                es: "Copiar mlx.distributed_config",
                                pt: "Copiar mlx.distributed_config",
                                ru: "Копировать mlx.distributed_config",
                                ja: "mlx.distributed_config をコピー",
                                zh: "复制 mlx.distributed_config"), systemImage: "doc.on.doc.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SolarisTheme.emerald)
                        .foregroundColor(.black)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.rdmaPreflightCommand(), forType: .string)
                            vm.sotaConfigCopiedBanner = L10n.tr(vm.language,
                                de: "RDMA-Preflight-Befehl kopiert",
                                en: "RDMA preflight command copied",
                                fr: "Commande preflight RDMA copiée",
                                es: "Comando preflight RDMA copiado",
                                pt: "Comando preflight RDMA copiado",
                                ru: "Команда RDMA preflight скопирована",
                                ja: "RDMA プリフライトコマンドをコピーしました",
                                zh: "已复制 RDMA 预检命令")
                        } label: {
                            Label(L10n.tr(vm.language,
                                de: "Preflight-Befehl kopieren",
                                en: "Copy Preflight Command",
                                fr: "Copier commande preflight",
                                es: "Copiar comando preflight",
                                pt: "Copiar comando preflight",
                                ru: "Копировать команду preflight",
                                ja: "プリフライトコマンドをコピー",
                                zh: "复制预检命令"), systemImage: "terminal.fill")
                        }
                        .buttonStyle(.bordered)

                        if !vm.sotaConfigCopiedBanner.isEmpty {
                            Text(vm.sotaConfigCopiedBanner)
                                .font(.caption.bold())
                                .foregroundColor(SolarisTheme.amberGlow)
                        }
                    }
                }
            }
            .padding(24)
        }
        .solarisShorttip(vm.shorttip(.network), id: "view_network_root", vm: vm)
    }
}
