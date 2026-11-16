import AppKit
import SwiftUI

extension Notification.Name {
    static let sscccRestoreFromMenuBar = Notification.Name("sscccRestoreFromMenuBar")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NotificationCenter.default.post(name: .sscccRestoreFromMenuBar, object: nil)
        }
        return true
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
                Button(vm.isMinimizedToMenuBar ? vm.t("mb_restore_window") : vm.t("mb_hide_to_bar")) {
                    if vm.isMinimizedToMenuBar {
                        vm.restoreWindowFromMenuBar()
                    } else {
                        vm.minimizeWindowToMenuBar()
                    }
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Button(vm.tabTitle(.help)) {
                    vm.selectedTab = .help
                }
                .keyboardShortcut("?", modifiers: [.command])
            }
        }

        MenuBarExtra {
            SSCCCMenuBarExtraView(vm: vm)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: vm.clusterReadinessState == .ready ? "sun.max.fill" : "sun.max")
                Text("SS-CCC · \(Int(vm.totalUsableVramGB))G/\(vm.nodes.count)N")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
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

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(NavigationTab.allCases) { tab in
                            sidebarItemRow(for: tab)
                        }
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
                .solarisShorttip(L10n.tr(vm.language,
                    de: "Sprache der gesamten Benutzeroberfläche inkl. Handbuch & Shorttips (17 Sprachen).",
                    en: "Language for the entire UI including manual & shorttips (17 languages).",
                    fr: "Langue de toute l'interface, y compris le manuel et les infobulles (17 langues).",
                    es: "Idioma de toda la interfaz, incluido el manual y los consejos (17 idiomas).",
                    pt: "Idioma de toda a interface, incluindo manual e dicas rápidas (17 idiomas).",
                    ru: "Язык всего интерфейса, включая руководство и подсказки (17 языков).",
                    ja: "マニュアルとショートチップを含む全UIの言語（17言語対応）。",
                    zh: "整个界面（含手册与提示）的显示语言（支持 17 种语言）。"), id: "sidebar_lang_picker", vm: vm)

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

                HazardStripesBar(height: 5, stripeWidth: 9, cornerRadius: 3, opacity: 0.85)
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
                            Image(
                                systemName: vm.updateStatus == .updateAvailable
                                    ? "arrow.down.circle.fill"
                                    : (vm.updateStatus == .upToDate ? "checkmark.seal.fill" : "arrow.triangle.2.circlepath")
                            )
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(
                                vm.updateStatus == .updateAvailable
                                    ? .black
                                    : (vm.updateStatus == .upToDate ? SolarisTheme.emerald : SolarisTheme.mint)
                            )
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
                                    .foregroundColor(SolarisTheme.textPrimary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(vm.updateStatus == .updateAvailable ? SolarisTheme.amber : SolarisTheme.cardElevated)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        vm.minimizeWindowToMenuBar()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "menubar.dock.rectangle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(SolarisTheme.amber)
                            Text(vm.t("mb_btn_minimize"))
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(SolarisTheme.textPrimary)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(SolarisTheme.cardElevated))
                    }
                    .buttonStyle(.plain)
                    .solarisShorttip(vm.t("mb_btn_minimize_tip"), id: "header_minimize_menubar", vm: vm)

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
                    case .multiModelMode:
                        MultiModelModeView(vm: vm)
                    case .agents:
                        AgentIntegrationsView(vm: vm)
                    case .science:
                        ScienceBenchmarksView(vm: vm)
                    case .console:
                        ApiConsoleView(vm: vm)
                    case .setup:
                        ClusterSetupView(vm: vm)
                    case .help:
                        HelpDocsView(vm: vm)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SolarisBackgroundLayer(resourceName: "solaris_bg", envKey: "SSCCC_BG_PATH", imageOpacity: 0.78))
                .overlay(alignment: .bottom) {
                    SolarisShorttipBanner(text: vm.activeShorttipText)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $vm.showUpdatePromptSheet) {
            UpdatePromptSheet(vm: vm)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { note in
            guard vm.minimizeToMenuBar,
                  let window = note.object as? NSWindow,
                  !(window.className.contains("StatusBar") || window.className.contains("MenuBar") || window.className.contains("Popover"))
            else { return }
            DispatchQueue.main.async {
                vm.minimizeWindowToMenuBar()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sscccRestoreFromMenuBar)) { _ in
            vm.restoreWindowFromMenuBar()
        }
    }

    private func sidebarAccent(for tab: NavigationTab) -> Color {
        switch tab {
        case .overview, .multiModelMode: return SolarisTheme.amber
        case .internetCluster, .science: return SolarisTheme.mint
        case .agents, .console: return SolarisTheme.emerald
        default: return SolarisTheme.amberGlow
        }
    }

    private func sidebarItemRow(for tab: NavigationTab) -> some View {
        let active = vm.selectedTab == tab
        let hovered = vm.hoveredSidebarTab == tab
        let tabAccent = sidebarAccent(for: tab)
        return HStack(spacing: 12) {
            Image(systemName: tab.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor((active || hovered) ? tabAccent : SolarisTheme.textSecondary)
                .shadow(color: (active || hovered) ? tabAccent.opacity(0.65) : .clear, radius: 6)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.tabTitle(tab))
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor((active || hovered) ? SolarisTheme.textPrimary : SolarisTheme.textSecondary)
                Text(vm.tabSubtitle(tab))
                    .font(.system(size: 12.5))
                    .foregroundColor(SolarisTheme.textSecondary.opacity((active || hovered) ? 0.95 : 0.80))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    active
                        ? SolarisTheme.cardElevated.opacity(0.95)
                        : (hovered ? SolarisTheme.cardElevated.opacity(0.68) : Color.black.opacity(0.34))
                )
        )
        .solarisHighlightGlow(accent: tabAccent, isActive: active, isHovered: hovered, cornerRadius: 12)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onHover { isOver in
            vm.hoveredSidebarTab = isOver ? tab : (vm.hoveredSidebarTab == tab ? nil : vm.hoveredSidebarTab)
            if isOver {
                vm.setShorttip(vm.shorttip(tab), id: "sidebar_\(tab.rawValue)")
            } else {
                vm.setShorttip(nil, id: "sidebar_\(tab.rawValue)")
            }
        }
        .help(vm.shorttip(tab))
        .accessibilityHint(vm.shorttip(tab))
        .onTapGesture {
            vm.selectedTab = tab
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

        VStack(alignment: .leading, spacing: 16) {
            HazardStripesBar(height: 6, stripeWidth: 10, cornerRadius: 3, opacity: 0.92)

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
                    Text(hasUpdate ? vm.t("upd_prompt_subtitle") : vm.t("upd_uptodate_subtitle"))
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
                        Text(hasUpdate ? vm.t("upd_latest_ver") : vm.t("upd_github_status_label"))
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        Text("v\(info.version) · \(info.sourceLabel)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(hasUpdate ? SolarisTheme.amberGlow : SolarisTheme.emerald)
                        if !info.commitSHA.isEmpty {
                            Text("GitHub SHA: \(info.commitSHA) · Local: \(vm.localGitCommitSHA.isEmpty ? AppReleaseMetadata.embeddedCommitSHA : vm.localGitCommitSHA)")
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                }
            }

            HStack {
                Toggle(vm.t("upd_auto_toggle"), isOn: $vm.autoUpdateCheckEnabled)
                    .toggleStyle(.switch)
                    .font(Font.caption)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                if !vm.lastUpdateCheckTime.isEmpty {
                    Text("\(vm.t("upd_last_check")): \(vm.lastUpdateCheckTime)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(SolarisTheme.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(SolarisTheme.cardElevated.opacity(0.7)))

            if let info, !info.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(hasUpdate ? vm.t("upd_notes_title") : vm.t("upd_recent_changes_title"))
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
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(SolarisTheme.emerald))
                    }
                    .buttonStyle(.plain)
                } else if vm.updateStatus == .updateAvailable {
                    if vm.localGitRepoRoot != nil {
                        Button {
                            vm.applyGitHubUpdateAndRebuild()
                        } label: {
                            Label(vm.t("upd_install_git_btn"), systemImage: "arrow.down.circle.fill")
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(SolarisTheme.amber))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        vm.openUpdateOnGitHub()
                    } label: {
                        Label(vm.t("upd_open_github_btn"), systemImage: "safari")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(SolarisTheme.cardElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)

                    if !(info?.mandatory ?? false) {
                        Button {
                            vm.skipCurrentUpdate()
                        } label: {
                            Text(vm.t("upd_skip_btn"))
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(SolarisTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(SolarisTheme.cardElevated)
                                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.20), lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                } else if vm.updateStatus == .updating {
                    ProgressView()
                        .controlSize(.small)
                    Text(vm.t("upd_updating"))
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.amberGlow)
                } else if case .failed(let errMsg) = vm.updateStatus {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(SolarisTheme.coral)
                        Text(errMsg)
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.coral)
                            .lineLimit(2)
                    }
                    if vm.localGitRepoRoot != nil {
                        Button {
                            vm.applyGitHubUpdateAndRebuild()
                        } label: {
                            Label(vm.t("upd_install_git_btn"), systemImage: "arrow.clockwise")
                                .font(SolarisTheme.bodyBold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(SolarisTheme.amber))
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        vm.openUpdateOnGitHub()
                    } label: {
                        Label(vm.t("upd_open_github_btn"), systemImage: "safari")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(SolarisTheme.cardElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        Task { await vm.checkForGitHubUpdates(userInitiated: true) }
                    } label: {
                        Label(vm.t("upd_recheck_btn"), systemImage: "arrow.triangle.2.circlepath")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(SolarisTheme.cardElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        vm.openUpdateOnGitHub()
                    } label: {
                        Label(vm.t("upd_open_github_btn"), systemImage: "safari")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(SolarisTheme.cardElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    vm.showUpdatePromptSheet = false
                } label: {
                    Text(hasUpdate ? vm.t("upd_later_btn") : vm.t("upd_close_btn"))
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(hasUpdate ? SolarisTheme.textPrimary : .black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(hasUpdate ? SolarisTheme.cardElevated : SolarisTheme.emerald)
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(hasUpdate ? Color.white.opacity(0.25) : Color.clear, lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }

            HazardStripesBar(height: 5, stripeWidth: 10, cornerRadius: 3, opacity: 0.78)
        }
        .padding(24)
        .frame(width: 620)
        .background(SolarisTheme.canvasBg)
        .preferredColorScheme(.dark)
    }
}

struct SSCCCMenuBarExtraView: View {
    @ObservedObject var vm: ClusterViewModel

    private var overviewScopeLabel: String {
        switch vm.overviewScope {
        case .local: return vm.t("ov_tab_local")
        case .internet: return vm.t("ov_tab_internet")
        case .hybrid: return vm.t("ov_tab_hybrid")
        }
    }

    private var readinessAccent: Color {
        switch vm.clusterReadinessState {
        case .ready: return SolarisTheme.emerald
        case .incomplete: return SolarisTheme.amber
        case .notReady: return SolarisTheme.coral
        case .unconfigured: return SolarisTheme.textSecondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: [SolarisTheme.amber, SolarisTheme.amberGlow], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.t("mb_title"))
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(vm.t("mb_subtitle"))
                        .font(.system(size: 11))
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                Text("v\(AppReleaseMetadata.currentVersion)")
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(SolarisTheme.cardElevated))
                    .foregroundColor(SolarisTheme.textSecondary)
            }

            HazardStripesBar(height: 4, stripeWidth: 8, cornerRadius: 2, opacity: 0.8)

            // Readiness + Service Online Status
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(readinessAccent)
                        .frame(width: 8, height: 8)
                    Text(vm.currentReadinessLabel)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(readinessAccent)
                        .lineLimit(1)
                }
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(vm.daemonConnected ? SolarisTheme.emerald : SolarisTheme.amber)
                        .frame(width: 7, height: 7)
                    Text(vm.daemonConnected ? vm.t("header_online") : String(format: vm.t("header_preview"), Int(vm.totalPhysicalRamGB)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(SolarisTheme.textPrimary)
                        .lineLimit(1)
                }
            }
            .padding(9)
            .background(RoundedRectangle(cornerRadius: 8).fill(SolarisTheme.cardBg))

            // 2x2 Key Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                menuMetricTile(
                    title: vm.t("kpi_memory"),
                    value: "\(Int(vm.totalPhysicalRamGB)) GB RAM",
                    sub: "\(Int(vm.totalUsableVramGB)) GB MLX",
                    accent: SolarisTheme.amber
                )
                menuMetricTile(
                    title: vm.t("kpi_nodes"),
                    value: "\(vm.nodes.count) Macs",
                    sub: overviewScopeLabel,
                    accent: SolarisTheme.mint
                )
                menuMetricTile(
                    title: vm.t("mb_active_model"),
                    value: vm.selectedModel.displayName,
                    sub: "\(vm.selectedModel.totalLayers) \(vm.t("ms_layers_unit"))",
                    accent: SolarisTheme.emerald
                )
                menuMetricTile(
                    title: vm.t("mb_active_runtime"),
                    value: vm.selectedService.localizedTitle(vm.language),
                    sub: "MMM: \(vm.mmmActiveSlots.count) Slots",
                    accent: SolarisTheme.amberGlow
                )
            }

            // Agent & IDE Service Endpoints
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.t("mb_endpoints_label"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(SolarisTheme.textSecondary)

                HStack(spacing: 6) {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.openCodeBaseURL, forType: .string)
                        vm.menuBarCopiedEndpoint = vm.openCodeBaseURL
                    } label: {
                        Label(vm.t("mb_copy_openai"), systemImage: "doc.on.doc")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(SolarisTheme.cardElevated))
                            .foregroundColor(SolarisTheme.textPrimary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("http://127.0.0.1:11434", forType: .string)
                        vm.menuBarCopiedEndpoint = "http://127.0.0.1:11434"
                    } label: {
                        Label(vm.t("mb_copy_ollama"), systemImage: "doc.on.doc")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(SolarisTheme.cardElevated))
                            .foregroundColor(SolarisTheme.textPrimary)
                    }
                    .buttonStyle(.plain)
                }

                Text("OpenCode · Hermes · Antigravity · Cursor · VS Code · Xcode")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(SolarisTheme.mint)
                    .lineLimit(1)

                if !vm.menuBarCopiedEndpoint.isEmpty {
                    Text("✓ \(vm.menuBarCopiedEndpoint)")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(SolarisTheme.emerald)
                }
            }
            .padding(9)
            .background(RoundedRectangle(cornerRadius: 8).fill(SolarisTheme.cardBg))

            // Minimize-to-menu-bar behavior toggle
            Toggle(isOn: $vm.minimizeToMenuBar) {
                Text(vm.t("mb_auto_minimize_toggle"))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(SolarisTheme.textPrimary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Divider().background(SolarisTheme.borderSubtle)

            // Primary Window + Actions
            HStack(spacing: 8) {
                Button {
                    if vm.isMinimizedToMenuBar {
                        vm.restoreWindowFromMenuBar()
                    } else {
                        vm.minimizeWindowToMenuBar()
                    }
                } label: {
                    Label(
                        vm.isMinimizedToMenuBar ? vm.t("mb_restore_window") : vm.t("mb_hide_to_bar"),
                        systemImage: vm.isMinimizedToMenuBar ? "macwindow.on.rectangle" : "menubar.dock.rectangle"
                    )
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(SolarisTheme.amber))
                    .foregroundColor(.black)
                }
                .buttonStyle(.plain)

                Button {
                    vm.verifyClusterReadiness()
                } label: {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 13))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(SolarisTheme.cardElevated))
                        .foregroundColor(SolarisTheme.mint)
                }
                .buttonStyle(.plain)
                .help(vm.t("ov_verify_btn"))

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(SolarisTheme.cardElevated))
                        .foregroundColor(SolarisTheme.coral)
                }
                .buttonStyle(.plain)
                .help(vm.t("mb_quit_app"))
            }
        }
        .padding(14)
        .frame(width: 368)
        .background(SolarisTheme.canvasBg)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .sscccRestoreFromMenuBar)) { _ in
            vm.restoreWindowFromMenuBar()
        }
    }

    private func menuMetricTile(title: String, value: String, sub: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(SolarisTheme.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(accent)
                .lineLimit(1)
            Text(sub)
                .font(.system(size: 10.5))
                .foregroundColor(SolarisTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(SolarisTheme.cardBg))
    }
}
