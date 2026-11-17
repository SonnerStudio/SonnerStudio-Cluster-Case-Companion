import SwiftUI

/// Live-Telemetrie aus dem Gateway (GET /ssccc/metrics) – gemessene statt berechnete Werte.
struct LiveTelemetryCard: View {
    @ObservedObject var vm: ClusterViewModel
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        SolarisCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "waveform.path.ecg").foregroundColor(SolarisTheme.mint)
                    Text(GS.t("tel_title", vm.language)).font(SolarisTheme.cardTitle).foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Text(GS.t("tel_measured", vm.language)).font(.caption).foregroundColor(SolarisTheme.emerald)
                }
                if let m = vm.gwMetrics {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 4), spacing: 12) {
                        metric(GS.t("tel_toks", vm.language), m.lastTokS.map { String(format: "%.1f", $0) } ?? "—")
                        metric(GS.t("tel_ttft", vm.language), m.avgTTFT.map { String(format: "%.2f s", $0) } ?? "—")
                        metric(GS.t("tel_requests", vm.language), "\(m.requests) · \(m.rejected) \(GS.t("tel_rejected", vm.language))")
                        metric(GS.t("tel_images", vm.language), "\(m.images)")
                        metric(GS.t("tel_queue", vm.language), "\(m.queueWaiting) · \(m.activeChats) Chat")
                        metric(GS.t("tel_memory", vm.language), m.memoryAvailableGB.map {
                            String(format: "%.1f / %.0f GB", $0, m.memoryTotalGB ?? 0) } ?? "—")
                        metric("Swap", m.swapUsedGB.map { String(format: "%.1f GB", $0) } ?? "—")
                        metric(GS.t("tel_restarts", vm.language), "\(m.crashRestarts)")
                    }
                    if m.recentTokS.count > 1 {
                        sparkline(m.recentTokS).frame(height: 40)
                    }
                    Text(m.model).font(.caption).foregroundColor(SolarisTheme.textSecondary)
                } else {
                    Text(GS.t("img_no_gateway", vm.language)).foregroundColor(SolarisTheme.textSecondary)
                }
            }
        }
        .task { await vm.refreshGatewayMetrics() }
        .onReceive(timer) { _ in Task { await vm.refreshGatewayMetrics() } }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundColor(SolarisTheme.textSecondary)
            Text(value).font(SolarisTheme.metricMedium).foregroundColor(SolarisTheme.amber).lineLimit(1).minimumScaleFactor(0.6)
        }
    }

    private func sparkline(_ values: [Double]) -> some View {
        GeometryReader { g in
            let maxV = max(values.max() ?? 1, 1)
            Path { p in
                for (i, v) in values.enumerated() {
                    let x = g.size.width * CGFloat(i) / CGFloat(max(values.count - 1, 1))
                    let y = g.size.height * (1 - CGFloat(v / maxV))
                    i == 0 ? p.move(to: CGPoint(x: x, y: y)) : p.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(SolarisTheme.mint, lineWidth: 2)
        }
    }
}

/// Betriebsart umschalten: Multi-Model (Tempo) gegen Verbund (Kapazität).
struct OperatingModeCard: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        SolarisCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "switch.2").foregroundColor(SolarisTheme.amber)
                    Text(GS.t("mode_title", vm.language)).font(SolarisTheme.cardTitle).foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    if vm.modeSwitching { ProgressView().controlSize(.small) }
                }
                HStack(alignment: .top, spacing: 14) {
                    option("multimodel", GS.t("mode_multi", vm.language), GS.t("mode_multi_desc", vm.language), "bolt.fill")
                    option("verbund", GS.t("mode_verbund", vm.language), GS.t("mode_verbund_desc", vm.language), "square.stack.3d.up.fill")
                }
            }
        }
        .task { await vm.refreshGatewayMode() }
    }

    private func option(_ mode: String, _ title: String, _ desc: String, _ icon: String) -> some View {
        let active = vm.gwMode == mode
        return VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(SolarisTheme.bodyBold)
                .foregroundColor(active ? SolarisTheme.amber : SolarisTheme.textPrimary)
            Text(desc).font(.callout).foregroundColor(SolarisTheme.textSecondary).fixedSize(horizontal: false, vertical: true)
            if active {
                Text(GS.t("mode_current", vm.language)).font(.caption.bold()).foregroundColor(SolarisTheme.emerald)
            } else {
                Button(GS.t("mode_switch", vm.language)) { vm.switchGatewayMode(mode) }
                    .disabled(vm.modeSwitching || vm.gwMode.isEmpty)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(active ? SolarisTheme.amber.opacity(0.10) : SolarisTheme.cardElevated)
        .cornerRadius(10)
    }
}

/// Sprachmodell wechseln: Katalog mit Größe, Speicherprüfung, Download mit Fortschritt.
struct ModelSwitcherCard: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        SolarisCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(SolarisTheme.amber)
                    Text(GS.t("mdl_title", vm.language)).font(SolarisTheme.cardTitle).foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                }
                if let d = vm.gwDownload, d.state == "download" || d.state == "switch" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(d.state == "download" ? "\(GS.t("mdl_downloading", vm.language)): \(d.repo)" : GS.t("mdl_switching", vm.language))
                            .font(.callout).foregroundColor(SolarisTheme.textSecondary)
                        ProgressView(value: (d.percent ?? 0) / 100)
                    }
                } else if let d = vm.gwDownload, d.state == "error", let e = d.error {
                    Text(e).font(.caption).foregroundColor(SolarisTheme.coral)
                }
                if vm.gwModels.isEmpty {
                    Text(GS.t("img_no_gateway", vm.language)).foregroundColor(SolarisTheme.textSecondary)
                }
                ForEach(vm.gwModels) { m in
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.label).font(SolarisTheme.bodyBold).foregroundColor(SolarisTheme.textPrimary)
                            Text("\(m.note) · \(String(format: "%.1f GB", m.sizeGB))")
                                .font(.caption).foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Text(m.fits ? "\(GS.t("mdl_fits", vm.language)) (\(String(format: "%.0f/%.0f GB", m.needGB, m.limitGB)))"
                                    : GS.t("mdl_too_big", vm.language))
                            .font(.caption).foregroundColor(m.fits ? SolarisTheme.emerald : SolarisTheme.coral)
                        if m.active {
                            Text(GS.t("mdl_active", vm.language)).font(.caption.bold()).foregroundColor(SolarisTheme.amber)
                        } else {
                            Button(m.installed ? GS.t("mdl_use", vm.language) : GS.t("mdl_download_use", vm.language)) {
                                vm.selectGatewayModel(m.repo)
                            }
                            .disabled(!m.fits || ["download", "switch"].contains(vm.gwDownload?.state ?? ""))
                        }
                    }
                    .padding(10)
                    .background(m.active ? SolarisTheme.amber.opacity(0.08) : SolarisTheme.cardElevated)
                    .cornerRadius(8)
                }
            }
        }
        .task { await vm.refreshGatewayModels() }
    }
}
