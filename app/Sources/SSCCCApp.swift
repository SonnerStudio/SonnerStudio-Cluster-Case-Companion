import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
    }
}

@main
struct SSCCCApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var vm = ClusterViewModel()

    var body: some Scene {
        WindowGroup("SonnerStudio Cluster-Case-Companion (SS-CCC)") {
            MainStudioWindow(vm: vm)
                .frame(minWidth: 960, idealWidth: 1280, maxWidth: .infinity, minHeight: 640, idealHeight: 820, maxHeight: .infinity)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1280, height: 820)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button(vm.t("upd_check_btn")) {
                    Task { await vm.checkForGitHubUpdates(userInitiated: true) }
                }
                .keyboardShortcut("u", modifiers: [.command])
            }
            CommandGroup(replacing: .help) {
                Button(vm.tabTitle(.help)) {
                    vm.selectedTab = .help
                }
                .keyboardShortcut("?", modifiers: [.command])
            }
        }
    }
}

struct MainStudioWindow: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Linke Studio-Sidebar (große Navigation)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [SolarisTheme.amber, SolarisTheme.amberGlow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SS-CCC")
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(vm.t("app_subtitle"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }
                .padding(.bottom, 12)

                ForEach(NavigationTab.allCases) { tab in
                    let active = vm.selectedTab == tab
                    HStack(spacing: 12) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(active ? SolarisTheme.amber : SolarisTheme.textSecondary)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vm.tabTitle(tab))
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(active ? SolarisTheme.textPrimary : SolarisTheme.textSecondary)
                            Text(vm.tabSubtitle(tab))
                                .font(.system(size: 12.5))
                                .foregroundColor(SolarisTheme.textSecondary.opacity(0.8))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(active ? SolarisTheme.cardElevated.opacity(0.90) : Color.black.opacity(0.34))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(active ? SolarisTheme.amber.opacity(0.55) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onTapGesture {
                        vm.selectedTab = tab
                    }
                }

                Spacer()

                // Sprachauswahl (DE / EN / FR / ES / PT)
                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.t("language_label"))
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(SolarisTheme.textSecondary)
                    Menu {
                        ForEach(AppLanguage.allCases) { lang in
                            Button {
                                vm.language = lang
                            } label: {
                                if vm.language == lang {
                                    Label(lang.shortLabel, systemImage: "checkmark")
                                } else {
                                    Text(lang.shortLabel)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(vm.language.shortLabel)
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(SolarisTheme.cardElevated.opacity(0.90))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                        )
                        .contentShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton)
                    .frame(maxWidth: .infinity)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(SolarisTheme.cardBg.opacity(0.84)))

                // Simulations-Schalter (bis Mac Studio per UPS eintrifft)
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        vm.simulateMacStudio.toggle()
                    }
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(vm.t("sim_toggle"))
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.simulateMacStudio ? vm.t("sim_active_desc") : vm.t("sim_single_desc"))
                                .font(.system(size: 13))
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Reiner SwiftUI-Schalter (zuverlässig auf gesamter Fläche klickbar)
                        ZStack(alignment: vm.simulateMacStudio ? .trailing : .leading) {
                            Capsule()
                                .fill(vm.simulateMacStudio ? SolarisTheme.amber : Color.white.opacity(0.22))
                                .frame(width: 42, height: 24)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                                .padding(3)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(SolarisTheme.cardBg.opacity(0.84))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(vm.simulateMacStudio ? SolarisTheme.amber.opacity(0.45) : SolarisTheme.borderSubtle, lineWidth: 1)
                            )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .frame(width: 280)
            .background(SolarisBackgroundLayer(resourceName: "solaris_sidebar_bg", envKey: "SSCCC_SIDEBAR_BG_PATH", imageOpacity: 0.78))

            Divider().background(SolarisTheme.borderSubtle)

            // Hauptbereich
            VStack(spacing: 0) {
                // Header-Leiste
                HStack {
                    Text(vm.tabTitle(vm.selectedTab))
                        .font(SolarisTheme.heroTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    // GitHub Update-Status-Pill / Prüf-Button
                    Button {
                        if vm.updateStatus == .updateAvailable || vm.updateStatus == .updatedNeedsRestart {
                            vm.showUpdatePromptSheet = true
                        } else {
                            Task { await vm.checkForGitHubUpdates(userInitiated: true) }
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: vm.updateStatus == .updateAvailable ? "arrow.down.circle.fill" : "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(vm.updateStatus == .updateAvailable ? .black : SolarisTheme.mint)
                            if vm.updateStatus == .updateAvailable, let info = vm.availableUpdate {
                                Text(String(format: vm.t("upd_available_pill"), info.version))
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(.black)
                            } else if vm.updateStatus == .checking {
                                Text(vm.t("upd_checking"))
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            } else {
                                Text("v\(AppReleaseMetadata.currentVersion)")
                                    .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(vm.updateStatus == .updateAvailable ? SolarisTheme.amber : SolarisTheme.cardElevated)
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 12) {
                        Circle()
                            .fill(vm.daemonConnected ? SolarisTheme.emerald : SolarisTheme.amber)
                            .frame(width: 10, height: 10)
                        Text(vm.daemonConnected ? vm.t("header_online") : String(format: vm.t("header_preview"), Int(vm.totalPhysicalRamGB)))
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(SolarisTheme.cardElevated))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(SolarisTheme.canvasBg.opacity(0.75))

                Divider().background(SolarisTheme.borderSubtle)

                Group {
                    switch vm.selectedTab {
                    case .overview:
                        ClusterOverviewView(vm: vm)
                    case .devices:
                        DevicesCompareView(vm: vm)
                    case .models:
                        ModelStudioView(vm: vm)
                    case .network:
                        NetworkRdmaView(vm: vm)
                    case .internetCluster:
                        InternetClusterView(vm: vm)
                    case .agents:
                        AgentIntegrationsView(vm: vm)
                    case .science:
                        ScienceBenchmarksView(vm: vm)
                    case .console:
                        ApiConsoleView(vm: vm)
                    case .help:
                        HelpDocsView(vm: vm)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SolarisBackgroundLayer(resourceName: "solaris_bg", envKey: "SSCCC_BG_PATH", imageOpacity: 0.78))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $vm.showUpdatePromptSheet) {
            UpdatePromptSheet(vm: vm)
        }
    }
}

private struct SolarisBackgroundLayer: View {
    let resourceName: String
    let envKey: String
    let imageOpacity: Double

    private func loadBackgroundImage() -> NSImage? {
        if let envPath = ProcessInfo.processInfo.environment[envKey],
           let img = NSImage(contentsOfFile: envPath) {
            return img
        }
        if let bundlePath = Bundle.main.path(forResource: resourceName, ofType: "png"),
           let img = NSImage(contentsOfFile: bundlePath) {
            return img
        }
        let cwdPath = FileManager.default.currentDirectoryPath + "/app/Resources/\(resourceName).png"
        if let img = NSImage(contentsOfFile: cwdPath) {
            return img
        }
        return nil
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SolarisTheme.canvasBg
                if let nsImage = loadBackgroundImage() {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .opacity(imageOpacity)
                        .overlay(Color.black.opacity(0.20))
                        .clipped()
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct UpdatePromptSheet: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        let info = vm.availableUpdate
        let hasUpdate = vm.updateStatus == .updateAvailable || vm.updateStatus == .updating || vm.updateStatus == .updatedNeedsRestart

        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(hasUpdate ? SolarisTheme.amber : SolarisTheme.emerald)
                        .frame(width: 48, height: 48)
                    Image(systemName: hasUpdate ? "arrow.down.app.fill" : "checkmark.seal.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(hasUpdate ? vm.t("upd_prompt_title") : String(format: vm.t("upd_up_to_date"), AppReleaseMetadata.currentVersion))
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(vm.t("upd_prompt_subtitle"))
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.t("upd_current_ver"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                    Text("v\(AppReleaseMetadata.currentVersion) (Build \(AppReleaseMetadata.currentBuild))")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(SolarisTheme.textPrimary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))

                if let info {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.t("upd_latest_ver"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Text("v\(info.version) · \(info.sourceLabel)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(hasUpdate ? SolarisTheme.amberGlow : SolarisTheme.emerald)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                }
            }

            if let info, !info.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.t("upd_notes_title"))
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.mint)
                    ScrollView {
                        Text(info.notes)
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundColor(SolarisTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35)))
                }
            }

            if !vm.updateProgressLog.isEmpty {
                ScrollView {
                    Text(vm.updateProgressLog)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(SolarisTheme.mint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 90)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.45)))
            }

            HStack(spacing: 10) {
                if vm.updateStatus == .updatedNeedsRestart {
                    Button {
                        vm.relaunchApp()
                    } label: {
                        Label(vm.t("upd_relaunch_btn"), systemImage: "arrow.clockwise.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SolarisTheme.emerald)
                    .foregroundColor(.black)
                } else if vm.updateStatus == .updateAvailable {
                    if vm.localGitRepoRoot != nil {
                        Button {
                            vm.applyGitHubUpdateAndRebuild()
                        } label: {
                            Label(vm.t("upd_install_git_btn"), systemImage: "arrow.down.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SolarisTheme.amber)
                        .foregroundColor(.black)
                    }

                    Button {
                        vm.openUpdateOnGitHub()
                    } label: {
                        Label(vm.t("upd_open_github_btn"), systemImage: "safari")
                    }
                    .buttonStyle(.bordered)

                    if !(info?.mandatory ?? false) {
                        Button(vm.t("upd_skip_btn")) {
                            vm.skipCurrentUpdate()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if vm.updateStatus == .updating {
                    ProgressView()
                        .controlSize(.small)
                    Text(vm.t("upd_updating"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.amberGlow)
                }

                Spacer()

                Button(vm.t("upd_later_btn")) {
                    vm.showUpdatePromptSheet = false
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 620)
        .background(SolarisTheme.canvasBg)
        .preferredColorScheme(.dark)
    }
}
