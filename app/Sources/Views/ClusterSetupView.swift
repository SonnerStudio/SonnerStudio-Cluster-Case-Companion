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
                        Text("\(vm.setupStatusMessage) (Letzte Prüfung: \(vm.lastReadinessCheckedAt))")
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
            Text("1. Verbund-Variante wählen & Automatisch Einrichten")
                .font(SolarisTheme.cardTitle)
                .foregroundColor(SolarisTheme.textPrimary)

            Picker("Verbund-Variante", selection: $vm.clusterSetupVariant) {
                ForEach(ClusterSetupVariant.allCases) { variant in
                    Text(variant.rawValue).tag(variant)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.clusterSetupVariant) { _, _ in
                vm.discoverClusterSetupTargets()
                vm.verifyClusterReadiness()
            }
            .solarisShorttip("Wähle Lokal (TB/RDMA), Internet-WAN (QUIC/Iroh/Tailscale) oder Hybrid (Lokal + Internet).", id: "setup_variant_picker", vm: vm)

            HStack(spacing: 12) {
                Button {
                    vm.discoverClusterSetupTargets()
                } label: {
                    Label("Macs im Verbund suchen (Bonjour / WAN)", systemImage: "magnifyingglass.circle.fill")
                }
                .buttonStyle(.bordered)
                .solarisShorttip("Scannt per Bonjour/mDNS, Thunderbolt, LAN und WAN-Peers nach verfügbaren Apple-Silicon-Macs.", id: "setup_discover_btn", vm: vm)

                Button {
                    vm.runAutomaticClusterSetup()
                } label: {
                    Label(
                        vm.isRunningClusterSetup ? "Richte Verbund ein..." : "Verbund auf allen Macs automatisch einrichten",
                        systemImage: "wand.and.stars"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.amber)
                .foregroundColor(.black)
                .disabled(vm.isRunningClusterSetup)
                .solarisShorttip("Konfiguriert SSH-Trust, iogpu.wired_limit_mb, mlx.distributed_config und Scope-Kopplung auf allen gewählten Macs.", id: "setup_run_btn", vm: vm)

                Button {
                    vm.verifyClusterReadiness()
                } label: {
                    Label(
                        vm.isVerifyingReadiness ? "Prüfe..." : "Betriebsbereitschaft prüfen",
                        systemImage: "checklist.checked"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.emerald)
                .foregroundColor(.black)
                .disabled(vm.isVerifyingReadiness)
                .solarisShorttip("Prüft Discovery, SSH, Thunderbolt/RDMA/WAN-Links, Speicherschutz und API-Gateway auf Betriebsbereitschaft.", id: "setup_verify_btn", vm: vm)
            }
        }
    }

    // MARK: - 3. Discovered Cluster Nodes Table

    private var discoveredTargetsCard: some View {
        SolarisCard(accent: SolarisTheme.mint) {
            HStack {
                Label("2. Erkannte Macs & Einrichtungsstatus (\(vm.discoveredProvisionTargets.count))", systemImage: "macstudio.fill")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.mint)
                Spacer()
                Button("mlx.distributed_config kopieren") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(vm.generateMlxDistributedHostfileJSON(), forType: .string)
                    vm.setupStatusMessage = "mlx.distributed_config Hostfile JSON in Zwischenablage kopiert."
                }
                .buttonStyle(.bordered)
                .solarisShorttip("Kopiert die automatisch erzeugte mlx.distributed_config (JACCL/Ring) für alle erkannten Macs.", id: "setup_copy_hostfile", vm: vm)
            }

            if vm.discoveredProvisionTargets.isEmpty {
                Text("Noch keine Ziel-Macs erkannt. Klicke auf 'Macs im Verbund suchen'.")
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
                        statusPill("VRAM-Guard", ok: target.wiredLimitConfigured)
                        statusPill("Link", ok: target.rdmaOrWanReady)

                        Text(String(format: "%.0f GB", target.usableVramGB))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(SolarisTheme.amberGlow)
                            .frame(width: 56, alignment: .trailing)
                    }
                    .padding(10)
                    .background(SolarisTheme.cardElevated)
                    .cornerRadius(8)
                    .solarisShorttip("Knoten \(target.hostname) (\(target.address)) — zeigt SSH-Vertrauen, Speicherschutz und Link-Bereitschaft.", id: "setup_node_\(target.id)", vm: vm)
                }
            }
        }
    }

    // MARK: - 4. Readiness Verification Checklist

    private var readinessVerificationCard: some View {
        SolarisCard(accent: readinessColor) {
            HStack {
                Label("3. Prüf-Protokoll & Betriebsbereitschaft", systemImage: "shield.checkered")
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
                            Text("Empfehlung: \(item.remediation)")
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
