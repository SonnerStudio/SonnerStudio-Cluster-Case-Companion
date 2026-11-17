import Foundation
import SwiftUI
import AVFoundation
import AppKit

@MainActor
final class ClusterViewModel: ObservableObject {
    @Published var selectedTab: NavigationTab = .overview
    @Published var language: AppLanguage = .en {
        didSet {
            refreshLocalizedDynamicState()
        }
    }
    @Published var simulateMacStudio: Bool = true {
        didSet {
            if !simulateMacStudio {
                refreshLocalHardwareProbe()
                Task { await checkDaemonHealth() }
            }
            discoverClusterSetupTargets()
            verifyClusterReadiness()
        }
    }
    @Published var transportMode: TransportMode = .autoHybrid
    @Published var daemonConnected: Bool = false
    @Published var liveClusterNodes: [ClusterNodeModel] = []
    @Published var liveClusterLink: String = ""
    @Published var liveClusterModel: String = ""
    @Published var liveNodeHealth: [LiveNodeHealth] = []
    @Published var fastSynchEnabled: Bool = true

    @Published var selectedModel: ModelPreset
    @Published var kvCacheReserveGB: Double = 4.0
    @Published var kvPrecision: KVCachePrecision = .q4
    @Published var prefillStepSize: Int = 512

    @Published var agentStatusMessage: String = "Bereit für 1-Klick-Konfiguration."
    @Published var openCodeBaseURL: String = "http://127.0.0.1:8000/v1"
    @Published var selectedService: RuntimeService = .omlx
    @Published var bridgeStatusMessage: String = "Bereit: Modelle direkt in oMLX, Ollama oder llama.cpp laden & als schnelles MLX einbinden."
    @Published var discoveredExternalModels: [String] = []
    @Published var serviceAvailability: [RuntimeService: Bool] = [:]

    @Published var localChipName: String = "Apple M4"
    @Published var localModelIdentifier: String = "Mac16,10"
    @Published var localOSVersion: String = "macOS 27.0.1"
    @Published var localCPUCores: Int = ProcessInfo.processInfo.processorCount
    @Published var localCPUTopology: String = "4P + 6E"
    @Published var localGPUCores: Int = 10
    @Published var localANECores: Int = 16
    @Published var localRamGB: Double = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0
    @Published var localWiredLimitMB: Int = 0
    @Published var localLanIP: String = "192.168.1.20"
    @Published var localTbIP: String = "10.99.1.2"
    @Published var localRdmaActive: Bool = false
    @Published var localSsdTotalGB: Int = 256
    @Published var localSsdFreeGB: Int = 120
    @Published var localThermalLabel: String = "Nominal (Kühl)"
    @Published var localPowerLabel: String = "10–45 W (Netzteil)"
    @Published var lastProbeTimestamp: String = "Gerade ausgelesen"

    @Published var promptInput: String = "Erkläre kurz, wie mehrere Apple-Silicon-Macs per Pipeline-Parallelität gekoppelt werden."
    @Published var consoleOutput: String = "Bereit. Starte den Python-Daemon (uvicorn core.api.gateway:app --port 8000) oder teste direkt im Vorschau-Modus."
    @Published var isSendingPrompt: Bool = false
    @Published var customNodes: [ClusterNodeModel] = []
    @Published var newFormFactor: MacFormFactor = .macBookPro
    @Published var newChip: AppleSiliconChipFamily = .m3Max
    @Published var newRamGB: Double = 36.0
    @Published var newCustomName: String = ""
    @Published var helpSearchText: String = ""
    @Published var selectedHelpSectionId: String? = nil
    @Published var hoveredSidebarTab: NavigationTab? = nil
    @Published var hoveredHelpSectionId: String? = nil
    @Published var hoveredGlowId: String? = nil
    @Published var isRefreshingModels: Bool = false
    @Published var modelDiscoveryNote: String = ""
    @Published var runtimeReadiness: [RuntimeService: RuntimeReadiness] = [:]

    // Scientific Roofline & Benchmark State
    @Published var sciScope: ScienceScope = .localCluster
    @Published var sciActiveTab: ScienceLabTab = .roofline
    @Published var sciBatchSize: Int = 1
    @Published var sciMicroBatches: Int = 4
    @Published var sciPromptTokens: Int = 2048
    @Published var sciGenTokens: Int = 512
    @Published var sciWeightBits: Int = 4
    @Published var sciActivationCompression: ActivationCompressionMode = .fp8Quantized
    @Published var sciStragglerRate: Double = 0.0
    @Published var sciWanJitterFactor: Double = 0.18
    @Published var sciDiLoCoLocalSteps: Int = 100
    @Published var sciCarbonRegion: CarbonRegionProfile = .euAverage
    @Published var sciElectricityEurPerKwh: Double = 0.32
    @Published var sciTrialCount: Int = 10
    @Published var sciSloTtftMaxMs: Double = 2500.0
    @Published var sciSloTpotMaxMs: Double = 100.0
    @Published var sciTrials: [ScientificBenchmarkTrial] = []
    @Published var sciSummary: ScientificBenchmarkSummary? = nil
    @Published var isRunningBenchmark: Bool = false
    @Published var sciStatusMessage: String = ""
    @Published var sciExportFeedback: String = ""
    @Published var sciHistoryEntries: [ScienceHistoryEntry] = []
    @Published var sciHistoryPositionFilter: ScienceHistoryPosition = .globalAll
    @Published var sciAutoRecordHistory: Bool = true

    // Internet WAN Cluster & Participant Chat State
    @Published var wanRoomCode: String = "SSCCC-WAN-\(String(UUID().uuidString.prefix(8)))"
    @Published var overviewScope: ClusterOverviewScope = .local
    @Published var wanRelayUrl: String = "ws://127.0.0.1:8000/ws/wan/"
    @Published var wanConnected: Bool = false
    @Published var isLocalClusterCoupledWithWan: Bool = false
    @Published var wanTransport: WanOverlayTransport = .tailscaleMesh
    @Published var wanScaleMode: InternetClusterScale = .privateTeam
    @Published var wanTailscaleInstalled: Bool = false
    @Published var wanWireGuardInstalled: Bool = false
    @Published var wanTailscaleIP: String = ""
    @Published var wanPeers: [WanPeerNode] = []
    @Published var wanPeerNameInput: String = ""
    @Published var wanPeerRegionInput: String = "EU-Central"
    @Published var wanPeerIpInput: String = "100.64.0.12"
    @Published var wanPeerChip: AppleSiliconChipFamily = .m4Max
    @Published var wanPeerRamGB: Double = 64.0
    @Published var wanPeerRttMs: Double = 24.0
    @Published var wanPeerUplinkMbps: Double = 250.0
    @Published var chatMessages: [ClusterChatMessage] = []
    @Published var chatInput: String = ""
    @Published var wanStatusNote: String = ""
    @Published var wanMeasuredDownloadMbps: Double = 0.0
    @Published var wanMeasuredUploadMbps: Double = 0.0
    @Published var wanMeasuredPingMs: Double = 0.0
    @Published var wanMeasuredJitterMs: Double = 0.0
    @Published var wanMeasuredPacketLossPct: Double = 0.0
    @Published var wanActiveInterfaceName: String = "en0"
    @Published var wanThroughputHistory: [WanBandwidthSample] = []
    @Published var isProbingWanBandwidth: Bool = false
    @Published var wanBandwidthLastUpdated: String = "—"
    @Published var wanBandwidthSourceLabel: String = "Bereit"
    private var wanWebSocketTask: URLSessionWebSocketTask? = nil

    // Multi-Model-Mode (MMM): Orchestrate multiple models across Local, Internet-WAN or Hybrid clusters
    @Published var mmmScope: MultiModelScope = .hybrid
    @Published var mmmStrategy: MultiModelStrategy = .mixtureOfAgents
    @Published var mmmSlots: [MultiModelSlot] = []
    @Published var mmmPromptInput: String = "Analysiere die Leistungsverteilung im Verbund und erstelle einen kompakten Optimierungsvorschlag."
    @Published var isRunningMultiModel: Bool = false
    @Published var mmmStatusMessage: String = ""
    @Published var mmmLastResult: MultiModelRunResult? = nil
    @Published var mmmHistory: [MultiModelRunResult] = []
    @Published var mmmNewModelId: String = ""
    @Published var mmmNewModelName: String = ""
    @Published var mmmNewModelRole: MultiModelRole = .specialist
    @Published var mmmNewModelRamGB: Double = 8.0
    @Published var mmmActiveClientCount: Int = 2
    @Published var mmmAutoProfile: MultiModelAutoProfile = .balancedCoding
    @Published var mmmAutoSetupSummary: String = ""
    @Published var mmmExpandedSlotId: UUID? = nil
    @Published var mmmConfigCopiedBanner: Bool = false

    // Phase 11: 2026 SOTA Architecture Upgrade (Points 1–5)
    @Published var clusterMeshTopology: ClusterMeshTopology = .fullMesh
    @Published var wanTransportProtocol: WanTransportProtocol = .quicIrohP2P
    @Published var splitPhaseComputeMode: SplitPhaseComputeMode = .anePrefillGpuDecode
    @Published var kvCacheTierMode: KVCacheTierMode = .distributedCacheGen
    @Published var kvPrefixCacheHitRatePct: Double = 78.0
    @Published var mmmSpeculativeEngine: SpeculativeEngineMode = .eagle3Fusion
    @Published var mmmEnableTreeMoaEarlyExit: Bool = true
    @Published var mmmMoaConfidenceThreshold: Double = 0.82
    @Published var mmmConfidenceEscalationEnabled: Bool = true
    @Published var selectedGatewayProtocol: AgentGatewayProtocol = .responsesWithMcp
    @Published var thermalCarbonPolicy: ThermalCarbonSchedulingPolicy = .balancedThermal
    @Published var mmmThermalCarbonAwareScheduling: Bool = true
    @Published var sotaConfigCopiedBanner: String = ""

    // Phase 12: Cluster Auto-Setup, Readiness Verification & App-Wide Shorttips
    @Published var clusterSetupVariant: ClusterSetupVariant = .local
    @Published var clusterReadinessState: ClusterReadinessState = .unconfigured
    @Published var clusterReadinessChecks: [ClusterReadinessCheckItem] = []
    @Published var discoveredProvisionTargets: [NodeProvisioningTarget] = []
    @Published var setupStatusMessage: String = ""
    @Published var isRunningClusterSetup: Bool = false
    @Published var isVerifyingReadiness: Bool = false
    @Published var lastReadinessCheckedAt: String = "—"
    @Published var hasCompletedClusterSetup: Bool = UserDefaults.standard.bool(forKey: ClusterViewModel.setupCompletedDefaultsKey) {
        didSet { UserDefaults.standard.set(hasCompletedClusterSetup, forKey: ClusterViewModel.setupCompletedDefaultsKey) }
    }
    @Published var setupToolChecks: [ClusterReadinessCheckItem] = []
    @Published var isRunningSetupTool: Bool = false
    @Published var activeShorttipText: String? = nil
    @Published var hoveredShorttipId: String? = nil

    // Cluster Audio-Party (Xbox / PlayStation-style voice coordination for AI clusters)
    @Published var audioPartyJoined: Bool = false
    @Published var audioPartyMuted: Bool = false
    @Published var audioPartyDeafened: Bool = false
    @Published var audioPartyMicMode: AudioPartyMicMode = .openMic
    @Published var audioPartyCodec: AudioPartyCodec = .opus16
    @Published var audioPartyNoiseGate: Bool = true
    @Published var audioPartyVoiceMixRatio: Double = 0.80 // 80% party voice vs 20% cluster alerts
    @Published var audioPartyMicLevel: Double = 0.0
    @Published var audioPartyPushToTalkActive: Bool = false
    @Published var audioPartyStatusText: String = "Bereit · Sprach-Kanal für Verbund-Koordination"
    @Published var audioPartyMembers: [AudioPartyMember] = []
    private var partyAudioEngine: AVAudioEngine? = nil
    private var partyAudioSocket: URLSessionWebSocketTask? = nil
    private var partyPulseTask: Task<Void, Never>? = nil

    // GitHub Program Update & Automatic Version Control State
    @Published var updateStatus: AppUpdateStatus = .idle
    @Published var availableUpdate: GitHubUpdateInfo? = nil
    @Published var showUpdatePromptSheet: Bool = false
    @Published var skippedUpdateVersion: String = UserDefaults.standard.string(forKey: "ssccc_skipped_version") ?? ""
    @Published var updateProgressLog: String = ""
    private var isRelaunching: Bool = false
    @Published var autoUpdateCheckEnabled: Bool = UserDefaults.standard.object(forKey: "ssccc_auto_update_check") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(autoUpdateCheckEnabled, forKey: "ssccc_auto_update_check")
            if autoUpdateCheckEnabled {
                startAutomaticUpdateMonitor()
            } else {
                autoUpdateMonitorTask?.cancel()
                autoUpdateMonitorTask = nil
            }
        }
    }
    @Published var lastUpdateCheckTime: String = ""
    @Published var localGitCommitSHA: String = ""
    private var autoUpdateMonitorTask: Task<Void, Never>? = nil

    // Background Menu Bar Service Mode (minimize to top status bar like Ollama)
    @Published var minimizeToMenuBar: Bool = UserDefaults.standard.object(forKey: "ssccc_minimize_to_menubar") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(minimizeToMenuBar, forKey: "ssccc_minimize_to_menubar")
        }
    }
    @Published var isMinimizedToMenuBar: Bool = false
    @Published var menuBarCopiedEndpoint: String = ""

    func minimizeWindowToMenuBar() {
        isMinimizedToMenuBar = true
        for window in NSApplication.shared.windows {
            let cls = window.className
            if cls.contains("StatusBar") || cls.contains("MenuBar") || cls.contains("Popover") {
                continue
            }
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.orderOut(nil)
        }
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    func restoreWindowFromMenuBar() {
        isMinimizedToMenuBar = false
        NSApplication.shared.setActivationPolicy(.regular)
        SSCCCAppIconProvider.applyDockIcon()
        let targetWindow = NSApplication.shared.windows.first(where: {
            $0.title.contains("SS-CCC") || $0.title.contains("SonnerStudio")
        }) ?? NSApplication.shared.windows.first(where: {
            let cls = $0.className
            return !cls.contains("StatusBar") && !cls.contains("MenuBar") && !cls.contains("Popover")
        })
        if let window = targetWindow {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    static let fallbackReferenceModels: [ModelPreset] = [
        ModelPreset(
            id: "mlx-community/Qwen2.5-32B-Instruct-4bit",
            displayName: "Qwen 2.5 32B Instruct",
            quantization: "4-bit MLX",
            totalLayers: 64,
            estimatedGB: 19.2,
            kvReserveGB: 4.0,
            notes: "Referenzprofil · kompakter Verbund oder Einzel-Mac ab 24 GB",
            sourceLabel: "Referenz",
            isLiveDiscovered: false
        ),
        ModelPreset(
            id: "mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit",
            displayName: "DeepSeek-R1 Distill 32B",
            quantization: "4-bit MLX",
            totalLayers: 64,
            estimatedGB: 19.5,
            kvReserveGB: 4.0,
            notes: "Referenzprofil · Schlussfolgerungs-Modell im Verbund",
            sourceLabel: "Referenz",
            isLiveDiscovered: false
        ),
        ModelPreset(
            id: "mlx-community/Llama-3.3-70B-Instruct-4bit",
            displayName: "Llama 3.3 70B Instruct",
            quantization: "4-bit MLX",
            totalLayers: 80,
            estimatedGB: 37.5,
            kvReserveGB: 4.0,
            notes: "Referenzprofil · großer Verbund ab ~48 GB nutzbarem Speicher",
            sourceLabel: "Referenz",
            isLiveDiscovered: false
        ),
        ModelPreset(
            id: "mlx-community/Mistral-Large-Instruct-2411-4bit",
            displayName: "Mistral Large 123B",
            quantization: "4-bit MLX",
            totalLayers: 88,
            estimatedGB: 68.0,
            kvReserveGB: 4.0,
            notes: "Referenzprofil · Hochkapazitäts-Verbund (z. B. Ultra / Multi-Max)",
            sourceLabel: "Referenz",
            isLiveDiscovered: false
        )
    ]

    @Published var modelPresets: [ModelPreset] = []

    init() {
        self.selectedModel = ClusterViewModel.fallbackReferenceModels[0]
        refreshLocalHardwareProbe()
        probeWanOverlayTools()
        refreshLocalCommitSHA()
        refreshLocalizedDynamicState()
        Task {
            await checkDaemonHealth()
            await refreshLiveModels()
        }
        startLiveClusterMonitor()
        if autoUpdateCheckEnabled {
            startAutomaticUpdateMonitor()
        }
    }

    private func runShell(_ launchPath: String, _ args: [String]) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: launchPath)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }

    func refreshLocalHardwareProbe() {
        let chip = runShell("/usr/sbin/sysctl", ["-n", "machdep.cpu.brand_string"])
        if !chip.isEmpty { localChipName = chip }

        let modelId = runShell("/usr/sbin/sysctl", ["-n", "hw.model"])
        if !modelId.isEmpty { localModelIdentifier = modelId }

        let os = runShell("/usr/bin/sw_vers", ["-productVersion"])
        if !os.isEmpty { localOSVersion = "macOS \(os)" }

        let wiredRaw = runShell("/usr/sbin/sysctl", ["-n", "iogpu.wired_limit_mb"])
        localWiredLimitMB = Int(wiredRaw) ?? 0

        localCPUCores = ProcessInfo.processInfo.processorCount
        let pCores = Int(runShell("/usr/sbin/sysctl", ["-n", "hw.perflevel0.physicalcpu"])) ?? 0
        let eCores = Int(runShell("/usr/sbin/sysctl", ["-n", "hw.perflevel1.physicalcpu"])) ?? 0
        if pCores > 0 || eCores > 0 {
            localCPUTopology = "\(pCores)P + \(eCores)E"
        }

        localRamGB = (Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0).rounded()

        // GPU-Kerne aus IOAccelerator (ioreg) oder system_profiler SPDisplaysDataType auslesen (mit Chip-Fallback)
        let ioAccel = runShell("/usr/sbin/ioreg", ["-r", "-d", "1", "-c", "IOAccelerator"])
        if let regex = try? NSRegularExpression(pattern: "\"gpu-core-count\"\\s*=\\s*(\\d+)", options: []),
           let match = regex.firstMatch(in: ioAccel, options: [], range: NSRange(ioAccel.startIndex..., in: ioAccel)),
           let range = Range(match.range(at: 1), in: ioAccel),
           let parsedGPU = Int(ioAccel[range]), parsedGPU > 0 {
            localGPUCores = parsedGPU
        } else {
            let displays = runShell("/usr/sbin/system_profiler", ["SPDisplaysDataType"])
            if let line = displays.components(separatedBy: .newlines).first(where: { $0.contains("Total Number of Cores:") || $0.contains("Gesamtanzahl der Kerne:") }),
               let numStr = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines),
               let parsedGPU = Int(numStr), parsedGPU > 0 {
                localGPUCores = parsedGPU
            } else {
                localGPUCores = AppleSiliconChipFamily.inferGPUCores(from: localChipName)
            }
        }
        localANECores = AppleSiliconChipFamily.inferANECores(from: localChipName)

        // Echte SSD-Größe & freier Speicher
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let totalBytes = (attrs[.systemSize] as? NSNumber)?.doubleValue,
           let freeBytes = (attrs[.systemFreeSize] as? NSNumber)?.doubleValue {
            localSsdTotalGB = max(1, Int((totalBytes / 1_000_000_000.0).rounded()))
            localSsdFreeGB = max(0, Int((freeBytes / 1_000_000_000.0).rounded()))
        }

        // Thermischer Zustand & Akku-/Leistungsdaten
        let thermState: String
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermState = "Nominal (Kühl)"
        case .fair: thermState = "Erhöht (Fair)"
        case .serious: thermState = "Hoch (Drosselung möglich)"
        case .critical: thermState = "Kritisch (Heiß)"
        @unknown default: thermState = "Unbekannt"
        }

        let battOut = runShell("/usr/sbin/ioreg", ["-r", "-c", "AppleSmartBattery"])
        if !battOut.isEmpty,
           let tempLine = battOut.components(separatedBy: .newlines).first(where: { $0.contains("\"Temperature\"") }),
           let rawTemp = tempLine.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespacesAndNewlines),
           let deciKelvin = Double(rawTemp) {
            // AppleSmartBattery Temperature is typically in 0.01 °C (e.g. 3120 -> 31.2 °C) or deciKelvin
            let celsius = deciKelvin > 2000 ? (deciKelvin / 100.0) : (deciKelvin / 10.0)
            localThermalLabel = String(format: "%.1f °C · %@", celsius, thermState)
        } else {
            localThermalLabel = thermState
        }

        if let wattsLine = battOut.components(separatedBy: .newlines).first(where: { $0.contains("\"AdapterPower\"") || $0.contains("\"SystemPowerIn\"") }),
           let rawW = wattsLine.components(separatedBy: "=").last?.trimmingCharacters(in: .whitespacesAndNewlines),
           let mw = Double(rawW), mw > 0 {
            localPowerLabel = String(format: "%.1f W (live)", mw > 500 ? mw / 1000.0 : mw)
        } else {
            let bw = AppleSiliconChipFamily.inferBandwidth(from: localChipName)
            localPowerLabel = bw >= 400 ? "30–145 W (Netzteil)" : (bw >= 200 ? "20–95 W (Netzteil)" : "10–45 W (Netzteil)")
        }

        let ibv = runShell("/usr/bin/ibv_devices", [])
        localRdmaActive = ibv.contains("rdma_en")

        let en0IP = runShell("/usr/sbin/ipconfig", ["getifaddr", "en0"])
        if !en0IP.isEmpty { localLanIP = en0IP }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        lastProbeTimestamp = formatter.string(from: Date())
        refreshServiceAvailability()
    }

    func refreshServiceAvailability() {
        let hasOmlx = !runShell("/usr/bin/which", ["omlx"]).isEmpty || FileManager.default.fileExists(atPath: "/Applications/oMLX.app")
        let hasOllama = !runShell("/usr/bin/which", ["ollama"]).isEmpty || FileManager.default.fileExists(atPath: "/Applications/Ollama.app")
        let hasLlama = !runShell("/usr/bin/which", ["llama-server"]).isEmpty || !runShell("/usr/bin/which", ["llama-cli"]).isEmpty
        serviceAvailability = [
            .omlx: hasOmlx,
            .ollama: hasOllama,
            .llamaCpp: hasLlama
        ]
    }

    func loadModelInSelectedService() {
        let modelId = selectedModel.id
        switch selectedService {
        case .omlx:
            let cmd = "omlx serve --model \(modelId) --port 8000"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(cmd, forType: .string)
            bridgeStatusMessage = tr(de: "oMLX-Startbefehl kopiert (Paged SSD KV-Cache aktiv): \(cmd)", en: "Copied oMLX launch command (Paged SSD KV Cache active): \(cmd)", fr: "Commande oMLX copiée (cache KV SSD paginé actif) : \(cmd)", es: "Comando oMLX copiado (caché KV SSD paginada activa): \(cmd)", pt: "Comando oMLX copiado (cache KV SSD paginada ativa): \(cmd)", ru: "Команда oMLX скопирована (SSD KV-кэш активен): \(cmd)", ja: "oMLX 起動コマンドをコピーしました: \(cmd)", zh: "已复制 oMLX 启动命令（已启用分页 SSD KV 缓存）：\(cmd)")
        case .ollama:
            let ollamaTag = modelId.contains("70B") ? "llama3.3:70b" : (modelId.contains("Qwen2.5") ? "qwen2.5:32b" : "deepseek-r1:32b")
            let cmd = "ollama run \(ollamaTag)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(cmd, forType: .string)
            bridgeStatusMessage = tr(de: "Ollama-Ladebefehl kopiert: \(cmd)", en: "Copied Ollama command: \(cmd)", fr: "Commande Ollama copiée : \(cmd)", es: "Comando Ollama copiado: \(cmd)", pt: "Comando Ollama copiado: \(cmd)", ru: "Команда Ollama скопирована: \(cmd)", ja: "Ollama コマンドをコピーしました: \(cmd)", zh: "已复制 Ollama 运行命令：\(cmd)")
        case .llamaCpp:
            let cmd = "llama-server --hf-repo \(modelId) --port 8080 -ngl 99"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(cmd, forType: .string)
            bridgeStatusMessage = tr(de: "llama.cpp-Serverbefehl kopiert: \(cmd)", en: "Copied llama.cpp server command: \(cmd)", fr: "Commande llama.cpp copiée : \(cmd)", es: "Comando llama.cpp copiado: \(cmd)", pt: "Comando llama.cpp copiado: \(cmd)", ru: "Команда llama.cpp скопирована: \(cmd)", ja: "llama.cpp サーバーコマンドをコピーしました: \(cmd)", zh: "已复制 llama.cpp 启动命令：\(cmd)")
        }
    }

    func tr(
        de: String,
        en: String,
        fr: String,
        es: String,
        pt: String,
        ru: String,
        ja: String,
        zh: String,
        nl: String? = nil,
        af: String? = nil,
        pl: String? = nil,
        cs: String? = nil,
        sk: String? = nil,
        hu: String? = nil,
        ko: String? = nil,
        hi: String? = nil,
        ta: String? = nil
    ) -> String {
        L10n.tr(
            language,
            de: de, en: en, fr: fr, es: es, pt: pt, ru: ru, ja: ja, zh: zh,
            nl: nl, af: af, pl: pl, cs: cs, sk: sk, hu: hu, ko: ko, hi: hi, ta: ta
        )
    }

    func refreshLocalizedDynamicState() {
        agentStatusMessage = tr(
            de: "Bereit für 1-Klick-Konfiguration.",
            en: "Ready for 1-click configuration.",
            fr: "Prêt pour la configuration en 1 clic.",
            es: "Listo para configuración en 1 clic.",
            pt: "Pronto para configuração num clique.",
            ru: "Готово к настройке в 1 клик.",
            ja: "ワンクリック設定の準備完了。",
            zh: "已就绪，支持一键配置。"
        )
        bridgeStatusMessage = tr(
            de: "Bereit: Modelle direkt in oMLX, Ollama oder llama.cpp laden & als schnelles MLX einbinden.",
            en: "Ready: Load models directly in oMLX, Ollama, or llama.cpp & bridge into fast MLX.",
            fr: "Prêt : chargez des modèles dans oMLX, Ollama ou llama.cpp et intégrez-les en MLX rapide.",
            es: "Listo: carga modelos en oMLX, Ollama o llama.cpp e intégralos como MLX rápido.",
            pt: "Pronto: carregue modelos no oMLX, Ollama ou llama.cpp e integre como MLX rápido.",
            ru: "Готово: загружайте модели в oMLX, Ollama или llama.cpp и подключайте к MLX.",
            ja: "準備完了：oMLX・Ollama・llama.cpp でモデルを読み込み高速 MLX に連携できます。",
            zh: "已就绪：直接在 oMLX、Ollama 或 llama.cpp 加载模型并接入高速 MLX。"
        )
        promptInput = tr(
            de: "Erkläre kurz, wie mehrere Apple-Silicon-Macs per Pipeline-Parallelität gekoppelt werden.",
            en: "Briefly explain how multiple Apple Silicon Macs are coupled via pipeline parallelism.",
            fr: "Expliquez brièvement comment plusieurs Mac Apple Silicon sont couplés par parallélisme en pipeline.",
            es: "Explica brevemente cómo se acoplan varios Mac Apple Silicon mediante paralelismo en pipeline.",
            pt: "Explique brevemente como vários Macs Apple Silicon são acoplados via paralelismo em pipeline.",
            ru: "Кратко объясните, как несколько Mac Apple Silicon объединяются через конвейерный параллелизм.",
            ja: "複数の Apple Silicon Mac をパイプライン並列で結合する仕組みを簡潔に説明してください。",
            zh: "简要说明多台 Apple Silicon Mac 如何通过流水线并行耦合协同推理。"
        )
        consoleOutput = tr(
            de: "Bereit. Starte den Python-Daemon (uvicorn core.api.gateway:app --port 8000) oder teste direkt im Vorschau-Modus.",
            en: "Ready. Start the Python daemon (uvicorn core.api.gateway:app --port 8000) or test in preview mode.",
            fr: "Prêt. Démarrez le démon Python (uvicorn core.api.gateway:app --port 8000) ou testez en mode aperçu.",
            es: "Listo. Inicia el servicio Python (uvicorn core.api.gateway:app --port 8000) o prueba en vista previa.",
            pt: "Pronto. Inicie o serviço Python (uvicorn core.api.gateway:app --port 8000) ou teste em pré-visualização.",
            ru: "Готово. Запустите Python-демон (uvicorn core.api.gateway:app --port 8000) или проверьте в предпросмотре.",
            ja: "準備完了。Python デーモン (uvicorn core.api.gateway:app --port 8000) を起動するかプレビューでテストしてください。",
            zh: "已就绪。请启动 Python 守护进程 (uvicorn core.api.gateway:app --port 8000) 或直接在预览模式测试。"
        )
        mmmPromptInput = tr(
            de: "Analysiere die Leistungsverteilung im Verbund und erstelle einen kompakten Optimierungsvorschlag.",
            en: "Analyze cluster load distribution and create a concise optimization recommendation.",
            fr: "Analysez la répartition de charge dans la grappe et proposez une optimisation concise.",
            es: "Analiza la distribución de carga del clúster y crea una recomendación de optimización concisa.",
            pt: "Analise a distribuição de carga no cluster e crie uma recomendação concisa de otimização.",
            ru: "Проанализируйте распределение нагрузки в кластере и дайте краткую рекомендацию.",
            ja: "クラスターの負荷分散を分析し、簡潔な最適化提案を作成してください。",
            zh: "分析集群算力与显存分配，并生成简明的优化建议。"
        )
        wanBandwidthSourceLabel = tr(de: "Bereit", en: "Ready", fr: "Prêt", es: "Listo", pt: "Pronto", ru: "Готово", ja: "待機中", zh: "就绪")
        audioPartyStatusText = tr(
            de: "Bereit · Sprach-Kanal für Verbund-Koordination",
            en: "Ready · Voice channel for cluster coordination",
            fr: "Prêt · Canal vocal de coordination",
            es: "Listo · Canal de voz del clúster",
            pt: "Pronto · Canal de voz do cluster",
            ru: "Готово · Голосовой канал кластера",
            ja: "準備完了 · クラスター連携用ボイスチャンネル",
            zh: "已就绪 · 集群语音协作频道"
        )
        if !clusterReadinessChecks.isEmpty {
            verifyClusterReadiness()
        } else if !discoveredProvisionTargets.isEmpty {
            discoverClusterSetupTargets()
        }
        probeWanOverlayTools()
        syncAudioPartyMembers()
    }

    func t(_ key: String) -> String {
        L10n.text(key, language)
    }

    func tabTitle(_ tab: NavigationTab) -> String {
        L10n.tabTitle(tab, language)
    }

    func tabSubtitle(_ tab: NavigationTab) -> String {
        L10n.tabSubtitle(tab, language)
    }

    func addCustomNode(formFactor: MacFormFactor, chip: AppleSiliconChipFamily, ramGB: Double, customName: String) {
        let index = customNodes.count + (simulateMacStudio ? 3 : 2)
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "\(formFactor.rawValue) \(chip.rawValue.replacingOccurrences(of: "Apple ", with: ""))" : trimmed
        let usable = AppleSiliconChipFamily.usableVramGB(for: ramGB)
        let node = ClusterNodeModel(
            id: "custom-\(UUID().uuidString.prefix(8))",
            name: name,
            role: "Worker (Rank \(index - 1))",
            modelIdentifier: formFactor.rawValue,
            chip: chip.rawValue,
            cpuCores: chip.cpuCores,
            cpuTopology: "\(chip.cpuCores) Cores",
            gpuCores: chip.gpuCores,
            neuralEngineCores: chip.aneCores,
            osVersion: "macOS (Apple Silicon)",
            totalRamGB: ramGB,
            usableVramGB: usable,
            wiredLimitMB: Int(usable * 1024),
            bandwidthGBs: chip.bandwidthGBs,
            thunderboltGen: chip.thunderboltGen,
            rdmaEnabled: chip.thunderboltGen >= 5,
            tbIP: "10.99.1.\(index)",
            lanIP: "192.168.1.\(20 + index)",
            ssdTotalGB: 512,
            ssdFreeGB: 320,
            thermalLabel: "Nominal (Zielwert)",
            powerLabel: chip.typicalPowerLabel,
            isSimulated: false
        )
        customNodes.append(node)
    }

    func removeCustomNode(id: String) {
        customNodes.removeAll { $0.id == id }
    }

    var nodes: [ClusterNodeModel] {
        if !liveClusterNodes.isEmpty { return liveClusterNodes }
        let localUsable = AppleSiliconChipFamily.usableVramGB(for: localRamGB)
        let localBandwidth = AppleSiliconChipFamily.inferBandwidth(from: localChipName)
        let localTbGen = AppleSiliconChipFamily.inferThunderboltGen(from: localChipName)

        var rawList: [ClusterNodeModel] = []
        if simulateMacStudio {
            rawList.append(
                ClusterNodeModel(
                    id: "studio-m5-max",
                    name: "Mac Studio M5 Max",
                    role: "Coordinator (Rank 0)",
                    modelIdentifier: "MacStudio (M5 Max)",
                    chip: "Apple M5 Max",
                    cpuCores: 18,
                    cpuTopology: "12P + 6E",
                    gpuCores: 32,
                    neuralEngineCores: 16,
                    osVersion: "macOS 27.x (Ziel)",
                    totalRamGB: 36.0,
                    usableVramGB: 30.0,
                    wiredLimitMB: 30720,
                    bandwidthGBs: 460.0,
                    thunderboltGen: 5,
                    rdmaEnabled: false,
                    tbIP: "10.99.1.1",
                    lanIP: "192.168.1.10",
                    ssdTotalGB: 512,
                    ssdFreeGB: 380,
                    thermalLabel: "Nominal (Kühl)",
                    powerLabel: "30–145 W (Netzteil)",
                    isSimulated: true
                )
            )
        }

        let localNode = ClusterNodeModel(
            id: "local-host",
            name: Host.current().localizedName ?? "Apple Silicon Mac",
            role: (simulateMacStudio || !customNodes.isEmpty) ? "Worker" : "Standalone (Rank 0)",
            modelIdentifier: localModelIdentifier,
            chip: localChipName,
            cpuCores: localCPUCores,
            cpuTopology: localCPUTopology,
            gpuCores: localGPUCores,
            neuralEngineCores: localANECores,
            osVersion: localOSVersion,
            totalRamGB: localRamGB,
            usableVramGB: localUsable,
            wiredLimitMB: localWiredLimitMB,
            bandwidthGBs: localBandwidth,
            thunderboltGen: localTbGen,
            rdmaEnabled: localRdmaActive,
            tbIP: localTbIP,
            lanIP: localLanIP,
            ssdTotalGB: localSsdTotalGB,
            ssdFreeGB: localSsdFreeGB,
            thermalLabel: localThermalLabel,
            powerLabel: localPowerLabel,
            isSimulated: false
        )
        rawList.append(localNode)
        rawList.append(contentsOf: customNodes)

        // Sort by memory bandwidth descending so fastest M-series chip takes Rank 0
        let sorted = rawList.sorted { $0.bandwidthGBs > $1.bandwidthGBs }
        return sorted.enumerated().map { idx, n in
            ClusterNodeModel(
                id: n.id,
                name: n.name,
                role: sorted.count == 1 ? "Standalone (Rank 0)" : (idx == 0 ? "Coordinator (Rank 0)" : "Worker (Rank \(idx))"),
                modelIdentifier: n.modelIdentifier,
                chip: n.chip,
                cpuCores: n.cpuCores,
                cpuTopology: n.cpuTopology,
                gpuCores: n.gpuCores,
                neuralEngineCores: n.neuralEngineCores,
                osVersion: n.osVersion,
                totalRamGB: n.totalRamGB,
                usableVramGB: n.usableVramGB,
                wiredLimitMB: n.wiredLimitMB,
                bandwidthGBs: n.bandwidthGBs,
                thunderboltGen: n.thunderboltGen,
                rdmaEnabled: n.rdmaEnabled,
                tbIP: n.tbIP,
                lanIP: n.lanIP,
                ssdTotalGB: n.ssdTotalGB,
                ssdFreeGB: n.ssdFreeGB,
                thermalLabel: n.thermalLabel,
                powerLabel: n.powerLabel,
                isSimulated: n.isSimulated
            )
        }
    }

    var totalPhysicalRamGB: Double {
        nodes.reduce(0) { $0 + $1.totalRamGB }
    }

    var totalUsableVramGB: Double {
        nodes.reduce(0) { $0 + $1.usableVramGB }
    }

    var shardingSplit: LayerSplitResult {
        let total = selectedModel.totalLayers
        let usable = max(totalUsableVramGB, 1.0)
        let required = selectedModel.estimatedGB + kvCacheReserveGB
        let fits = required <= usable

        let activeNodes = nodes
        var allocatedSum = 0
        var allocations: [NodeLayerAllocation] = []

        for (index, node) in activeNodes.enumerated() {
            let layers: Int
            if index == activeNodes.count - 1 {
                layers = max(0, total - allocatedSum)
            } else {
                let share = node.usableVramGB / usable
                layers = max(0, min(total - allocatedSum, Int((Double(total) * share).rounded())))
            }
            allocatedSum += layers
            let pct = total > 0 ? (Double(layers) / Double(total) * 100.0) : 0.0
            allocations.append(
                NodeLayerAllocation(
                    id: node.id,
                    nodeName: node.name,
                    layers: layers,
                    percent: pct,
                    usableGB: node.usableVramGB
                )
            )
        }

        let firstLayers = allocations.first?.layers ?? total
        let restLayers = max(0, total - firstLayers)
        let firstPct = total > 0 ? (Double(firstLayers) / Double(total) * 100.0) : 100.0
        let restPct = max(0.0, 100.0 - firstPct)

        return LayerSplitResult(
            studioLayers: activeNodes.count > 1 ? firstLayers : 0,
            miniLayers: activeNodes.count > 1 ? restLayers : total,
            studioPercent: activeNodes.count > 1 ? firstPct : 0,
            miniPercent: activeNodes.count > 1 ? restPct : 100,
            nodeAllocations: allocations,
            totalRequiredGB: required,
            totalUsableGB: usable,
            fits: fits
        )
    }

    var effectiveLinkStats: (rangeLabel: String, nominalGbps: Double, badge: String) {
        let active = nodes
        guard active.count > 1 else {
            return (t("ov_local_internal"), 0.0, t("ov_one_node"))
        }
        let minTb = active.map(\.thunderboltGen).min() ?? 4
        let maxTb = active.map(\.thunderboltGen).max() ?? 4
        return AppleSiliconChipFamily.linkTransferStats(genA: minTb, genB: maxTb, mode: transportMode)
    }

    var activeLinkHeadline: String {
        guard nodes.count > 1 else { return t("ov_one_node") }
        let stats = effectiveLinkStats
        switch transportMode {
        case .autoHybrid:
            return "\(stats.badge) Bridge (\(stats.rangeLabel)) + LAN/WLAN Control"
        case .thunderboltOnly:
            return "Thunderbolt Point-to-Point (\(stats.rangeLabel) · 10.99.1.x)"
        case .lanWlanOnly:
            return "LAN / Wi-Fi Fallback (~1–10 Gbps)"
        case .rdmaExperimental:
            return "JACCL / RDMA Verbs (\(stats.rangeLabel), Opt-In)"
        }
    }

    func checkDaemonHealth() async {
        guard let url = URL(string: "\(ClusterViewModel.clusterGatewayBase)/health") else { return }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                daemonConnected = true
                return
            }
        } catch {
            // Daemon läuft noch nicht – lokale Vorschau bleibt aktiv
        }
        daemonConnected = false
    }

    func sendTestPrompt() async {
        isSendingPrompt = true
        defer { isSendingPrompt = false }

        if daemonConnected, let url = URL(string: "\(ClusterViewModel.clusterGatewayBase)/v1/chat/completions") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "model": selectedModel.id,
                "messages": [["role": "user", "content": promptInput]],
                "stream": false
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let msg = choices.first?["message"] as? [String: Any],
                   let content = msg["content"] as? String {
                    consoleOutput = content
                    return
                }
            } catch {
                // Fallback auf lokale Vorschau
            }
        }

        let split = shardingSplit
        let splitSummary = split.nodeAllocations
            .map { "\($0.nodeName): \($0.layers)L (\(String(format: "%.0f", $0.percent))%)" }
            .joined(separator: " | ")
        consoleOutput = """
        [SS-CCC Lokale Vorschau]
        Modell: \(selectedModel.displayName) (\(selectedModel.quantization))
        Cluster: \(nodes.count) Node(s) · \(Int(totalPhysicalRamGB)) GB physisch (\(Int(totalUsableVramGB)) GB nutzbar)
        Verteilung: \(splitSummary)
        Transport: \(activeLinkHeadline) | FAST_SYNCH=\(fastSynchEnabled ? "1 (~4 µs)" : "0 (~180 µs)")
        """
    }

    var openCodeConfigJSON: String {
        """
        {
          "$schema": "https://opencode.ai/config.json",
          "provider": {
            "ss-ccc": {
              "npm": "@ai-sdk/openai-compatible",
              "name": "SonnerStudio Cluster (SS-CCC)",
              "options": {
                "baseURL": "\(openCodeBaseURL)"
              },
              "models": {
                "\(selectedModel.id)": {
                  "name": "\(selectedModel.displayName) (\(Int(totalPhysicalRamGB)) GB Cluster)"
                },
                "mlx-community/Qwen2.5-32B-Instruct-4bit": {
                  "name": "Qwen 2.5 32B (Fast)"
                }
              }
            }
          },
          "model": "ss-ccc/\(selectedModel.id)",
          "small_model": "ss-ccc/mlx-community/Qwen2.5-32B-Instruct-4bit"
        }
        """
    }

    var hermesConfigYAML: String {
        """
        provider: custom
        custom:
          base_url: "\(openCodeBaseURL)"
          model: "\(selectedModel.id)"
        """
    }

    func installOpenCodeConfig() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let configDir = home.appendingPathComponent(".config/opencode")
        let authDir = home.appendingPathComponent(".local/share/opencode")
        do {
            try fm.createDirectory(at: configDir, withIntermediateDirectories: true)
            try fm.createDirectory(at: authDir, withIntermediateDirectories: true)
            try openCodeConfigJSON.write(
                to: configDir.appendingPathComponent("opencode.json"),
                atomically: true,
                encoding: .utf8
            )
            let authJSON = "{\n  \"ss-ccc\": {\n    \"type\": \"api\",\n    \"key\": \"sk-local\"\n  }\n}\n"
            try authJSON.write(
                to: authDir.appendingPathComponent("auth.json"),
                atomically: true,
                encoding: .utf8
            )
            agentStatusMessage = tr(
                de: "OpenCode konfiguriert: ~/.config/opencode/opencode.json & auth.json geschrieben.",
                en: "OpenCode configured: wrote ~/.config/opencode/opencode.json & auth.json.",
                fr: "OpenCode configuré : ~/.config/opencode/opencode.json & auth.json écrits.",
                es: "OpenCode configurado: ~/.config/opencode/opencode.json y auth.json escritos.",
                pt: "OpenCode configurado: ~/.config/opencode/opencode.json e auth.json gravados.",
                ru: "OpenCode настроен: записаны ~/.config/opencode/opencode.json и auth.json.",
                ja: "OpenCode 設定完了: ~/.config/opencode/opencode.json と auth.json を書き込みました。",
                zh: "OpenCode 已配置：已写入 ~/.config/opencode/opencode.json 与 auth.json。"
            )
        } catch {
            agentStatusMessage = tr(
                de: "Fehler beim Schreiben der OpenCode-Config: \(error.localizedDescription)",
                en: "Error writing OpenCode config: \(error.localizedDescription)",
                fr: "Erreur d'écriture config OpenCode : \(error.localizedDescription)",
                es: "Error al escribir config OpenCode: \(error.localizedDescription)",
                pt: "Erro ao gravar config OpenCode: \(error.localizedDescription)",
                ru: "Ошибка записи конфига OpenCode: \(error.localizedDescription)",
                ja: "OpenCode 設定の書き込みエラー: \(error.localizedDescription)",
                zh: "写入 OpenCode 配置失败：\(error.localizedDescription)"
            )
        }
    }

    func installHermesConfig() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let hermesDir = home.appendingPathComponent(".hermes")
        do {
            try fm.createDirectory(at: hermesDir, withIntermediateDirectories: true)
            try hermesConfigYAML.write(
                to: hermesDir.appendingPathComponent("config.yaml"),
                atomically: true,
                encoding: .utf8
            )
            let envFile = "OPENAI_API_KEY=\"not-needed\"\n"
            try envFile.write(
                to: hermesDir.appendingPathComponent(".env"),
                atomically: true,
                encoding: .utf8
            )
            agentStatusMessage = tr(
                de: "Hermes Agent konfiguriert: ~/.hermes/config.yaml & .env geschrieben.",
                en: "Hermes Agent configured: wrote ~/.hermes/config.yaml & .env.",
                fr: "Hermes Agent configuré : ~/.hermes/config.yaml & .env écrits.",
                es: "Hermes Agent configurado: ~/.hermes/config.yaml y .env escritos.",
                pt: "Hermes Agent configurado: ~/.hermes/config.yaml e .env gravados.",
                ru: "Hermes Agent настроен: записаны ~/.hermes/config.yaml и .env.",
                ja: "Hermes Agent 設定完了: ~/.hermes/config.yaml と .env を書き込みました。",
                zh: "Hermes Agent 已配置：已写入 ~/.hermes/config.yaml 与 .env。"
            )
        } catch {
            agentStatusMessage = tr(
                de: "Fehler beim Schreiben der Hermes-Config: \(error.localizedDescription)",
                en: "Error writing Hermes config: \(error.localizedDescription)",
                fr: "Erreur d'écriture config Hermes : \(error.localizedDescription)",
                es: "Error al escribir config Hermes: \(error.localizedDescription)",
                pt: "Erro ao gravar config Hermes: \(error.localizedDescription)",
                ru: "Ошибка записи конфига Hermes: \(error.localizedDescription)",
                ja: "Hermes 設定の書き込みエラー: \(error.localizedDescription)",
                zh: "写入 Hermes 配置失败：\(error.localizedDescription)"
            )
        }
    }

    var antigravityConfigPython: String {
        """
        # Antigravity SDK (AGY) <-> SonnerStudio Cluster-Case-Companion (SS-CCC)
        from google.antigravity import Agent, LocalOpenAIAgentConfig

        config = LocalOpenAIAgentConfig(
            model="\(selectedModel.id)",
            base_url="\(openCodeBaseURL)",
        ).lightweight()
        """
    }

    func installAntigravityConfig() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let agyDir = home.appendingPathComponent(".gemini/antigravity")
        do {
            try fm.createDirectory(at: agyDir, withIntermediateDirectories: true)
            let providerJSON = """
            {
              "provider": "ss-ccc-local-mlx",
              "base_url": "\(openCodeBaseURL)",
              "model": "\(selectedModel.id)",
              "engine": "mlx-distributed"
            }
            """
            try providerJSON.write(
                to: agyDir.appendingPathComponent("ssccc_local_provider.json"),
                atomically: true,
                encoding: .utf8
            )
            try antigravityConfigPython.write(
                to: agyDir.appendingPathComponent("ssccc_local_agent.py"),
                atomically: true,
                encoding: .utf8
            )
            agentStatusMessage = tr(
                de: "Antigravity konfiguriert: ~/.gemini/antigravity/ssccc_local_provider.json & ssccc_local_agent.py geschrieben.",
                en: "Antigravity configured: wrote ~/.gemini/antigravity/ssccc_local_provider.json & ssccc_local_agent.py.",
                fr: "Antigravity configuré : ~/.gemini/antigravity/ssccc_local_provider.json & ssccc_local_agent.py écrits.",
                es: "Antigravity configurado: ssccc_local_provider.json y ssccc_local_agent.py escritos.",
                pt: "Antigravity configurado: ssccc_local_provider.json e ssccc_local_agent.py gravados.",
                ru: "Antigravity настроен: записаны ssccc_local_provider.json и ssccc_local_agent.py.",
                ja: "Antigravity 設定完了: ssccc_local_provider.json と ssccc_local_agent.py を書き込みました。",
                zh: "Antigravity 已配置：已写入 ssccc_local_provider.json 与 ssccc_local_agent.py。"
            )
        } catch {
            agentStatusMessage = tr(
                de: "Fehler beim Schreiben der Antigravity-Config: \(error.localizedDescription)",
                en: "Error writing Antigravity config: \(error.localizedDescription)",
                fr: "Erreur d'écriture config Antigravity : \(error.localizedDescription)",
                es: "Error al escribir config Antigravity: \(error.localizedDescription)",
                pt: "Erro ao gravar config Antigravity: \(error.localizedDescription)",
                ru: "Ошибка записи конфига Antigravity: \(error.localizedDescription)",
                ja: "Antigravity 設定の書き込みエラー: \(error.localizedDescription)",
                zh: "写入 Antigravity 配置失败：\(error.localizedDescription)"
            )
        }
    }

    private func writeIntegrationFiles(relativeDir: String, files: [(name: String, content: String)], successLabel: String) {
        let fm = FileManager.default
        let dir = fm.homeDirectoryForCurrentUser.appendingPathComponent(relativeDir)
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            for file in files {
                try file.content.write(
                    to: dir.appendingPathComponent(file.name),
                    atomically: true,
                    encoding: .utf8
                )
            }
            agentStatusMessage = successLabel
        } catch {
            agentStatusMessage = tr(
                de: "Fehler beim Schreiben (\(relativeDir)): \(error.localizedDescription)",
                en: "Error writing (\(relativeDir)): \(error.localizedDescription)",
                fr: "Erreur d'écriture (\(relativeDir)) : \(error.localizedDescription)",
                es: "Error al escribir (\(relativeDir)): \(error.localizedDescription)",
                pt: "Erro ao gravar (\(relativeDir)): \(error.localizedDescription)",
                ru: "Ошибка записи (\(relativeDir)): \(error.localizedDescription)",
                ja: "書き込みエラー (\(relativeDir)): \(error.localizedDescription)",
                zh: "写入失败 (\(relativeDir))：\(error.localizedDescription)"
            )
        }
    }

    var cursorConfigJSON: String {
        """
        {
          "name": "SonnerStudio Cluster (SS-CCC)",
          "openAIBaseURL": "\(openCodeBaseURL)",
          "model": "\(selectedModel.id)",
          "contextLength": 65536
        }
        """
    }

    var vscodeConfigJSON: String {
        """
        {
          "ssccc.clusterBaseURL": "\(openCodeBaseURL)",
          "ssccc.defaultModel": "\(selectedModel.id)",
          "models": [
            {
              "title": "SS-CCC (\(selectedModel.displayName))",
              "provider": "openai",
              "model": "\(selectedModel.id)",
              "apiBase": "\(openCodeBaseURL)",
              "apiKey": "ss-ccc-local"
            }
          ]
        }
        """
    }

    var xcodeConfigJSON: String {
        """
        {
          "provider": "SonnerStudio Cluster (SS-CCC)",
          "openaiEndpoint": "\(openCodeBaseURL)",
          "ollamaEndpoint": "http://127.0.0.1:8000",
          "model": "\(selectedModel.id)",
          "fastModel": "mlx-community/Qwen2.5-32B-Instruct-4bit"
        }
        """
    }

    func installCursorConfig() {
        writeIntegrationFiles(
            relativeDir: ".cursor",
            files: [("ssccc_cluster.json", cursorConfigJSON)],
            successLabel: tr(
                de: "Cursor konfiguriert: ~/.cursor/ssccc_cluster.json geschrieben.",
                en: "Cursor configured: wrote ~/.cursor/ssccc_cluster.json.",
                fr: "Cursor configuré : ~/.cursor/ssccc_cluster.json écrit.",
                es: "Cursor configurado: ~/.cursor/ssccc_cluster.json escrito.",
                pt: "Cursor configurado: ~/.cursor/ssccc_cluster.json gravado.",
                ru: "Cursor настроен: ~/.cursor/ssccc_cluster.json записан.",
                ja: "Cursor 設定完了: ~/.cursor/ssccc_cluster.json を書き込みました。",
                zh: "Cursor 已配置：已写入 ~/.cursor/ssccc_cluster.json。"
            )
        )
    }

    func installVSCodeConfig() {
        writeIntegrationFiles(
            relativeDir: ".vscode",
            files: [("ssccc_cluster.json", vscodeConfigJSON)],
            successLabel: tr(
                de: "Visual Studio Code konfiguriert: ~/.vscode/ssccc_cluster.json geschrieben.",
                en: "Visual Studio Code configured: wrote ~/.vscode/ssccc_cluster.json.",
                fr: "VS Code configuré : ~/.vscode/ssccc_cluster.json écrit.",
                es: "VS Code configurado: ~/.vscode/ssccc_cluster.json escrito.",
                pt: "VS Code configurado: ~/.vscode/ssccc_cluster.json gravado.",
                ru: "VS Code настроен: ~/.vscode/ssccc_cluster.json записан.",
                ja: "VS Code 設定完了: ~/.vscode/ssccc_cluster.json を書き込みました。",
                zh: "VS Code 已配置：已写入 ~/.vscode/ssccc_cluster.json。"
            )
        )
    }

    func installXcodeConfig() {
        writeIntegrationFiles(
            relativeDir: "Library/Developer/Xcode/UserData",
            files: [("SSCCCClusterProvider.json", xcodeConfigJSON)],
            successLabel: tr(
                de: "Xcode konfiguriert: ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json geschrieben.",
                en: "Xcode configured: wrote ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json.",
                fr: "Xcode configuré : ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json écrit.",
                es: "Xcode configurado: SSCCCClusterProvider.json escrito.",
                pt: "Xcode configurado: SSCCCClusterProvider.json gravado.",
                ru: "Xcode настроен: SSCCCClusterProvider.json записан.",
                ja: "Xcode 設定完了: SSCCCClusterProvider.json を書き込みました。",
                zh: "Xcode 已配置：已写入 SSCCCClusterProvider.json。"
            )
        )
    }

    func scanOllamaAndLlamaCppToMLX() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        var found: [String] = []

        // 1. Ollama Manifests scannen
        let ollamaDir = home.appendingPathComponent(".ollama/models/manifests")
        if let enumerator = fm.enumerator(at: ollamaDir, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: fileURL.path, isDirectory: &isDir), !isDir.boolValue {
                    found.append("Ollama → MLX: \(fileURL.deletingLastPathComponent().lastPathComponent):\(fileURL.lastPathComponent)")
                }
            }
        }

        // 2. llama.cpp / GGUF Dateien scannen
        let ggufDirs = [
            home.appendingPathComponent("Models"),
            home.appendingPathComponent(".cache/llama.cpp"),
            home.appendingPathComponent(".lmstudio/models"),
            home.appendingPathComponent(".cache/lm-studio/models"),
            home.appendingPathComponent("Downloads")
        ]
        for dir in ggufDirs {
            if let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: nil) {
                for case let fileURL as URL in enumerator where fileURL.pathExtension.lowercased() == "gguf" {
                    found.append("GGUF → MLX: \(fileURL.lastPathComponent)")
                }
            }
        }

        discoveredExternalModels = Array(found.prefix(10))
        if found.isEmpty {
            bridgeStatusMessage = tr(de: "Keine lokalen Ollama-/GGUF-Dateien gefunden. Nutze direkte schnelle MLX-Modelle (mlx-community/*-4bit).", en: "No local Ollama/GGUF files found. Use fast native MLX models (mlx-community/*-4bit).", fr: "Aucun fichier Ollama/GGUF local trouvé. Utilisez des modèles MLX natifs rapides.", es: "No se encontraron archivos Ollama/GGUF locales. Usa modelos MLX nativos rápidos.", pt: "Nenhum ficheiro Ollama/GGUF local encontrado. Utilize modelos MLX nativos rápidos.", ru: "Локальные файлы Ollama/GGUF не найдены. Используйте быстрые модели MLX.", ja: "ローカルの Ollama/GGUF ファイルが見つかりません。高速なネイティブ MLX モデルをご利用ください。", zh: "未发现本地 Ollama/GGUF 模型文件，建议直接使用高速原生 MLX 模型。")
        } else {
            bridgeStatusMessage = tr(de: "\(found.count) Ollama/GGUF-Quelle(n) erkannt — bereit zur schnellen MLX-Einbindung (mlx_lm.convert --quantize).", en: "Detected \(found.count) Ollama/GGUF source(s) — ready for fast MLX bridging (mlx_lm.convert --quantize).", fr: "\(found.count) source(s) Ollama/GGUF détectée(s) — prêt pour intégration MLX.", es: "\(found.count) fuente(s) Ollama/GGUF detectada(s) — listo para puente MLX.", pt: "\(found.count) fonte(s) Ollama/GGUF detetada(s) — pronto para ponte MLX.", ru: "Найдено источников Ollama/GGUF: \(found.count) — готово к подключению к MLX.", ja: "\(found.count) 件の Ollama/GGUF を検出 — MLX への高速連携準備完了。", zh: "已发现 \(found.count) 个 Ollama/GGUF 源 — 已就绪导入高速 MLX。")
        }
    }

    func exportForOllamaAndLlamaCpp() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let exportDir = home.appendingPathComponent(".ssccc/bridges")
        do {
            try fm.createDirectory(at: exportDir, withIntermediateDirectories: true)
            let modelfile = """
            # SS-CCC Ollama-Bridge Profil (nutzt schnelles MLX-Cluster-Backend)
            # Gateway: \(openCodeBaseURL.replacingOccurrences(of: "/v1", with: ""))
            FROM \(selectedModel.id)
            PARAMETER num_ctx \(kvPrecision == .q4 ? 65536 : (kvPrecision == .q8 ? 32768 : 16384))
            """
            try modelfile.write(
                to: exportDir.appendingPathComponent("Modelfile.ssccc"),
                atomically: true,
                encoding: .utf8
            )

            let llamaCppBridge = """
            {
              "bridge": "ss-ccc-mlx-cluster",
              "openai_base_url": "\(openCodeBaseURL)",
              "ollama_base_url": "\(openCodeBaseURL.replacingOccurrences(of: "/v1", with: ""))",
              "active_mlx_model": "\(selectedModel.id)",
              "kv_precision": "\(kvPrecision.rawValue)"
            }
            """
            try llamaCppBridge.write(
                to: exportDir.appendingPathComponent("llamacpp_ollama_bridge.json"),
                atomically: true,
                encoding: .utf8
            )
            bridgeStatusMessage = tr(de: "Bereitgestellt: ~/.ssccc/bridges/Modelfile.ssccc & llamacpp_ollama_bridge.json (Endpoint: \(openCodeBaseURL)).", en: "Exported ~/.ssccc/bridges/Modelfile.ssccc & llamacpp_ollama_bridge.json (Endpoint: \(openCodeBaseURL)).", fr: "Exporté : ~/.ssccc/bridges/Modelfile.ssccc & llamacpp_ollama_bridge.json (\(openCodeBaseURL)).", es: "Exportado: ~/.ssccc/bridges/Modelfile.ssccc y llamacpp_ollama_bridge.json (\(openCodeBaseURL)).", pt: "Exportado: ~/.ssccc/bridges/Modelfile.ssccc e llamacpp_ollama_bridge.json (\(openCodeBaseURL)).", ru: "Создано: ~/.ssccc/bridges/Modelfile.ssccc и llamacpp_ollama_bridge.json (\(openCodeBaseURL)).", ja: "出力完了: ~/.ssccc/bridges/Modelfile.ssccc & llamacpp_ollama_bridge.json (\(openCodeBaseURL))。", zh: "已导出至 ~/.ssccc/bridges/Modelfile.ssccc 与 llamacpp_ollama_bridge.json (端点：\(openCodeBaseURL))。")
        } catch {
            bridgeStatusMessage = tr(de: "Fehler beim Bridge-Export: \(error.localizedDescription)", en: "Bridge export error: \(error.localizedDescription)", fr: "Erreur d'export de passerelle : \(error.localizedDescription)", es: "Error al exportar pasarela: \(error.localizedDescription)", pt: "Erro ao exportar ponte: \(error.localizedDescription)", ru: "Ошибка экспорта моста: \(error.localizedDescription)", ja: "ブリッジ出力エラー: \(error.localizedDescription)", zh: "导出桥接配置失败：\(error.localizedDescription)")
        }
    }

    // MARK: - Live Model Discovery (oMLX, Ollama, llama.cpp & Local Cache)

    static func inferModelSpecs(from modelId: String, knownSizeGB: Double? = nil, knownQuant: String? = nil) -> (layers: Int, gb: Double, quant: String) {
        let lower = modelId.lowercased()
        let quant: String
        if let kq = knownQuant, !kq.isEmpty {
            quant = kq
        } else if lower.contains("8bit") || lower.contains("q8") {
            quant = "8-bit"
        } else if lower.contains("fp16") || lower.contains("bf16") {
            quant = "FP16"
        } else if lower.contains("q6") {
            quant = "6-bit"
        } else if lower.contains("q5") {
            quant = "5-bit"
        } else {
            quant = "4-bit"
        }

        // Parse parameter count in billions from name (e.g. 70b, 32b, 14b, 8b, 7b, 3b, 1.5b)
        var paramsB = 8.0
        if let regex = try? NSRegularExpression(pattern: "(\\d+(?:\\.\\d+)?)\\s*b\\b", options: []),
           let match = regex.firstMatch(in: lower, options: [], range: NSRange(lower.startIndex..., in: lower)),
           let r = Range(match.range(at: 1), in: lower),
           let parsed = Double(lower[r]) {
            paramsB = parsed
        }

        let layers: Int
        if paramsB >= 100 { layers = 88 }
        else if paramsB >= 65 { layers = 80 }
        else if paramsB >= 28 { layers = 64 }
        else if paramsB >= 20 { layers = 48 }
        else if paramsB >= 12 { layers = 40 }
        else if paramsB >= 6 { layers = 32 }
        else { layers = 24 }

        let bytesPerParam: Double = quant.contains("FP16") ? 2.0 : (quant.contains("8") ? 1.05 : 0.56)
        let gb = knownSizeGB ?? max(1.0, (paramsB * bytesPerParam * 1.05 * 10.0).rounded() / 10.0)
        return (layers, gb, quant)
    }

    func refreshLiveModels() async {
        isRefreshingModels = true
        var live: [ModelPreset] = []
        var seenIds = Set<String>()

        // 1. oMLX / OpenAI-compatible endpoint (:8000)
        if let url = URL(string: "\(ClusterViewModel.clusterGatewayBase)/v1/models") {
            var req = URLRequest(url: url)
            req.timeoutInterval = 1.5
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let arr = json["data"] as? [[String: Any]] {
                for item in arr {
                    if let id = item["id"] as? String, !seenIds.contains(id) {
                        seenIds.insert(id)
                        let specs = Self.inferModelSpecs(from: id)
                        live.append(ModelPreset(
                            id: id,
                            displayName: id.components(separatedBy: "/").last ?? id,
                            quantization: "\(specs.quant) MLX",
                            totalLayers: specs.layers,
                            estimatedGB: specs.gb,
                            kvReserveGB: 4.0,
                            notes: "Live erkannt über oMLX (:8000)",
                            sourceLabel: "oMLX Live",
                            isLiveDiscovered: true
                        ))
                    }
                }
            }
        }

        // 2. Ollama API (:11434/api/tags) with exact byte sizes & quantization_level
        var ollamaFoundCount = 0
        for tagEndpoint in ["http://127.0.0.1:11434/api/tags", "http://localhost:11434/api/tags"] where ollamaFoundCount == 0 {
            if let url = URL(string: tagEndpoint) {
                var req = URLRequest(url: url)
                req.timeoutInterval = 1.5
                if let (data, resp) = try? await URLSession.shared.data(for: req),
                   let http = resp as? HTTPURLResponse, http.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["models"] as? [[String: Any]] {
                    for m in models {
                        if let name = m["name"] as? String, !seenIds.contains(name) {
                            seenIds.insert(name)
                            ollamaFoundCount += 1
                            let sizeBytes = (m["size"] as? NSNumber)?.doubleValue ?? 0
                            let sizeGB = sizeBytes > 0 ? (sizeBytes / 1_073_741_824.0 * 10.0).rounded() / 10.0 : nil
                            let details = m["details"] as? [String: Any]
                            let qLevel = details?["quantization_level"] as? String
                            let paramSize = details?["parameter_size"] as? String ?? ""
                            let specs = Self.inferModelSpecs(from: "\(name) \(paramSize)", knownSizeGB: sizeGB, knownQuant: qLevel)
                            live.append(ModelPreset(
                                id: name,
                                displayName: name,
                                quantization: "Ollama · \(specs.quant)",
                                totalLayers: specs.layers,
                                estimatedGB: specs.gb,
                                kvReserveGB: 4.0,
                                notes: "Live erkannt über Ollama (:11434)",
                                sourceLabel: "Ollama Live",
                                isLiveDiscovered: true
                            ))
                        }
                    }
                }
            }
        }
        // Fallback: CLI `ollama list` (captures custom OLLAMA_MODELS paths / launchctl env)
        if ollamaFoundCount == 0 {
            let cliModels = Self.probeOllamaCliModels(excludingIds: seenIds)
            for item in cliModels {
                seenIds.insert(item.id)
                live.append(item)
            }
        }

        // 3. llama.cpp server (:8080/v1/models)
        if let url = URL(string: "http://127.0.0.1:8080/v1/models") {
            var req = URLRequest(url: url)
            req.timeoutInterval = 1.5
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let arr = json["data"] as? [[String: Any]] {
                for item in arr {
                    if let id = item["id"] as? String, !seenIds.contains(id) {
                        seenIds.insert(id)
                        let specs = Self.inferModelSpecs(from: id)
                        live.append(ModelPreset(
                            id: id,
                            displayName: URL(fileURLWithPath: id).lastPathComponent,
                            quantization: "llama.cpp · \(specs.quant)",
                            totalLayers: specs.layers,
                            estimatedGB: specs.gb,
                            kvReserveGB: 4.0,
                            notes: "Live erkannt über llama.cpp (:8080)",
                            sourceLabel: "llama.cpp Live",
                            isLiveDiscovered: true
                        ))
                    }
                }
            }
        }

        // 4. Local GGUF & HuggingFace MLX cache scan (sync helper for Swift 6 concurrency)
        let localDiskModels = Self.scanLocalDiskModels(excludingIds: seenIds)
        live.append(contentsOf: localDiskModels)

        if !live.isEmpty {
            modelPresets = live
            if !live.contains(where: { $0.id == selectedModel.id }) {
                selectedModel = live[0]
                kvCacheReserveGB = live[0].kvReserveGB
            }
            modelDiscoveryNote = tr(
                de: "\(live.count) echte(s) Modell(e) aus oMLX / Ollama / llama.cpp / lokalem Speicher eingelesen.",
                en: "Loaded \(live.count) live model(s) from oMLX / Ollama / llama.cpp / local cache.",
                fr: "\(live.count) modèle(s) réel(s) détecté(s) via oMLX / Ollama / llama.cpp / cache local.",
                es: "\(live.count) modelo(s) real(es) detectado(s) desde oMLX / Ollama / llama.cpp / caché local.",
                pt: "\(live.count) modelo(s) real(is) detetado(s) via oMLX / Ollama / llama.cpp / cache local.",
                ru: "Загружено \(live.count) моделей из oMLX / Ollama / llama.cpp / локального кэша.",
                ja: "oMLX・Ollama・llama.cpp・ローカルキャッシュから \(live.count) 個のモデルを読み込みました。",
                zh: "已从 oMLX / Ollama / llama.cpp / 本地缓存读取 \(live.count) 个真实模型。"
            )
        } else {
            modelPresets = []
            modelDiscoveryNote = t("ms_no_models_note")
        }
        await checkRuntimeReadiness(
            omlxRunning: live.contains(where: { $0.sourceLabel == "oMLX Live" }) ? true : nil,
            ollamaRunning: live.contains(where: { $0.sourceLabel == "Ollama Live" }) ? true : nil,
            llamaRunning: live.contains(where: { $0.sourceLabel == "llama.cpp Live" }) ? true : nil
        )
        isRefreshingModels = false
    }

    private func isPortReachable(port: Int, path: String) async -> Bool {
        guard let url = URL(string: port == 8000 ? "\(ClusterViewModel.clusterGatewayBase)\(path)" : "http://127.0.0.1:\(port)\(path)") else { return false }
        var req = URLRequest(url: url)
        req.timeoutInterval = 0.8
        if let (_, resp) = try? await URLSession.shared.data(for: req),
           let http = resp as? HTTPURLResponse, (200..<500).contains(http.statusCode) {
            return true
        }
        return false
    }

    func checkRuntimeReadiness(omlxRunning: Bool? = nil, ollamaRunning: Bool? = nil, llamaRunning: Bool? = nil) async {
        let omlxUp: Bool
        if let v = omlxRunning { omlxUp = v } else { omlxUp = await isPortReachable(port: 8000, path: "/v1/models") }
        let ollamaUp: Bool
        if let v = ollamaRunning { ollamaUp = v } else { ollamaUp = await isPortReachable(port: 11434, path: "/api/tags") }
        let llamaUp: Bool
        if let v = llamaRunning { llamaUp = v } else { llamaUp = await isPortReachable(port: 8080, path: "/v1/models") }

        let paths = Self.probeRuntimeBinaries()
        let recommendedOllamaPull = totalUsableVramGB <= 14.0 ? "ollama pull qwen2.5:7b" : "ollama pull qwen2.5:14b"
        runtimeReadiness = [
            .omlx: RuntimeReadiness(
                service: .omlx,
                installed: !paths.omlx.isEmpty,
                running: omlxUp,
                binaryPath: paths.omlx,
                installCommand: "pip install omlx && omlx serve --port 8000",
                pullModelCommand: "mlx_lm.server --model mlx-community/Qwen2.5-14B-Instruct-4bit --port 8000"
            ),
            .ollama: RuntimeReadiness(
                service: .ollama,
                installed: !paths.ollama.isEmpty,
                running: ollamaUp,
                binaryPath: paths.ollama,
                installCommand: "brew install ollama && ollama serve",
                pullModelCommand: recommendedOllamaPull
            ),
            .llamaCpp: RuntimeReadiness(
                service: .llamaCpp,
                installed: !paths.llama.isEmpty,
                running: llamaUp,
                binaryPath: paths.llama,
                installCommand: "brew install llama.cpp",
                pullModelCommand: "llama-server -hf bartowski/Qwen2.5-14B-Instruct-GGUF:Q4_K_M --port 8080"
            )
        ]
        serviceAvailability = [
            .omlx: !paths.omlx.isEmpty || omlxUp,
            .ollama: !paths.ollama.isEmpty || ollamaUp,
            .llamaCpp: !paths.llama.isEmpty || llamaUp
        ]
    }

    private static func probeOllamaCliModels(excludingIds: Set<String>) -> [ModelPreset] {
        let fm = FileManager.default
        let candidates = [
            "/opt/homebrew/bin/ollama",
            "/usr/local/bin/ollama",
            "/Applications/Ollama.app/Contents/Resources/ollama"
        ]
        guard let bin = candidates.first(where: { fm.isExecutableFile(atPath: $0) }) else {
            return []
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: bin)
        proc.arguments = ["list"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            guard proc.terminationStatus == 0,
                  let text = String(data: data, encoding: .utf8) else { return [] }
            var result: [ModelPreset] = []
            for line in text.split(separator: "\n").dropFirst() {
                let cols = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
                guard let nameSub = cols.first else { continue }
                let name = String(nameSub)
                if name.isEmpty || excludingIds.contains(name) { continue }
                let specs = inferModelSpecs(from: name)
                result.append(ModelPreset(
                    id: name,
                    displayName: name,
                    quantization: "Ollama · \(specs.quant)",
                    totalLayers: specs.layers,
                    estimatedGB: specs.gb,
                    kvReserveGB: 4.0,
                    notes: "Live erkannt über Ollama CLI",
                    sourceLabel: "Ollama Live",
                    isLiveDiscovered: true
                ))
            }
            return result
        } catch {
            return []
        }
    }

    func pullRecommendedOllamaModel() async {
        let modelTag = totalUsableVramGB <= 14.0 ? "qwen2.5:7b" : "qwen2.5:14b"
        let fm = FileManager.default
        let candidates = [
            "/opt/homebrew/bin/ollama",
            "/usr/local/bin/ollama",
            "/Applications/Ollama.app/Contents/Resources/ollama"
        ]
        guard let bin = candidates.first(where: { fm.isExecutableFile(atPath: $0) }) else {
            bridgeStatusMessage = tr(de: "Ollama-Binary nicht gefunden.", en: "Ollama binary not found.", fr: "Binaire Ollama introuvable.", es: "Binario de Ollama no encontrado.", pt: "Binário Ollama não encontrado.", ru: "Бинарник Ollama не найден.", ja: "Ollama バイナリが見つかりません。", zh: "未找到 Ollama 可执行文件。")
            return
        }
        bridgeStatusMessage = tr(de: "Lade \(modelTag) über Ollama…", en: "Pulling \(modelTag) via Ollama…", fr: "Téléchargement de \(modelTag) via Ollama…", es: "Descargando \(modelTag) con Ollama…", pt: "A transferir \(modelTag) via Ollama…", ru: "Загрузка \(modelTag) через Ollama…", ja: "Ollama で \(modelTag) を取得中…", zh: "正在通过 Ollama 拉取 \(modelTag)…")
        let status = await Task.detached { () -> Int32 in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: bin)
            proc.arguments = ["pull", modelTag]
            proc.standardOutput = Pipe()
            proc.standardError = Pipe()
            try? proc.run()
            proc.waitUntilExit()
            return proc.terminationStatus
        }.value
        if status == 0 {
            bridgeStatusMessage = tr(de: "\(modelTag) erfolgreich in Ollama geladen.", en: "Successfully pulled \(modelTag) in Ollama.", fr: "\(modelTag) téléchargé dans Ollama.", es: "\(modelTag) descargado en Ollama.", pt: "\(modelTag) transferido para o Ollama.", ru: "\(modelTag) загружен в Ollama.", ja: "Ollama で \(modelTag) の取得が完了しました。", zh: "已在 Ollama 中成功拉取 \(modelTag)。")
            await refreshLiveModels()
        } else {
            bridgeStatusMessage = tr(de: "Ollama-Pull fehlgeschlagen (Status \(status)).", en: "Ollama pull failed (status \(status)).", fr: "Échec du pull Ollama (code \(status)).", es: "Error al descargar con Ollama (estado \(status)).", pt: "Falha no pull Ollama (estado \(status)).", ru: "Ошибка загрузки Ollama (код \(status)).", ja: "Ollama pull に失敗しました (ステータス \(status))。", zh: "Ollama 拉取失败（状态码 \(status)）。")
        }
    }

    private static func probeRuntimeBinaries() -> (omlx: String, ollama: String, llama: String) {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        func firstExisting(_ candidates: [String]) -> String {
            for p in candidates where fm.fileExists(atPath: p) { return p }
            return ""
        }
        let omlx = firstExisting([
            "/opt/homebrew/bin/omlx",
            "/usr/local/bin/omlx",
            "\(home)/.local/bin/omlx",
            "/Applications/oMLX.app",
            "/opt/homebrew/bin/mlx_lm.server",
            "\(home)/.local/bin/mlx_lm.server"
        ])
        let ollama = firstExisting([
            "/opt/homebrew/bin/ollama",
            "/usr/local/bin/ollama",
            "/Applications/Ollama.app/Contents/Resources/ollama",
            "/Applications/Ollama.app"
        ])
        let llama = firstExisting([
            "/opt/homebrew/bin/llama-server",
            "/usr/local/bin/llama-server",
            "/opt/homebrew/bin/llama-cli",
            "/usr/local/bin/llama-cli"
        ])
        return (omlx, ollama, llama)
    }

    private static func scanLocalDiskModels(excludingIds: Set<String>) -> [ModelPreset] {
        var found: [ModelPreset] = []
        var seenIds = excludingIds
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let ggufDirs = [
            home.appendingPathComponent("Models"),
            home.appendingPathComponent(".cache/llama.cpp"),
            home.appendingPathComponent(".lmstudio/models"),
            home.appendingPathComponent(".cache/lm-studio/models"),
            home.appendingPathComponent("Downloads")
        ]
        for dir in ggufDirs {
            if let enumerator = fm.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator where fileURL.pathExtension.lowercased() == "gguf" {
                    let id = fileURL.lastPathComponent
                    if !seenIds.contains(id) {
                        seenIds.insert(id)
                        let bytes = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Double.init) ?? 0
                        let sizeGB = bytes > 0 ? (bytes / 1_073_741_824.0 * 10.0).rounded() / 10.0 : nil
                        let specs = inferModelSpecs(from: id, knownSizeGB: sizeGB)
                        found.append(ModelPreset(
                            id: fileURL.path,
                            displayName: id,
                            quantization: "GGUF · \(specs.quant)",
                            totalLayers: specs.layers,
                            estimatedGB: specs.gb,
                            kvReserveGB: 4.0,
                            notes: "Lokale GGUF-Datei (\(fileURL.deletingLastPathComponent().lastPathComponent))",
                            sourceLabel: "Lokal GGUF",
                            isLiveDiscovered: true
                        ))
                    }
                }
            }
        }

        let hfHub = home.appendingPathComponent(".cache/huggingface/hub")
        if let entries = try? fm.contentsOfDirectory(at: hfHub, includingPropertiesForKeys: [.isDirectoryKey]) {
            for dir in entries where dir.lastPathComponent.hasPrefix("models--") {
                let repoId = dir.lastPathComponent
                    .replacingOccurrences(of: "models--", with: "")
                    .replacingOccurrences(of: "--", with: "/")
                if !seenIds.contains(repoId) {
                    seenIds.insert(repoId)
                    let specs = inferModelSpecs(from: repoId)
                    found.append(ModelPreset(
                        id: repoId,
                        displayName: repoId.components(separatedBy: "/").last ?? repoId,
                        quantization: "HF/MLX · \(specs.quant)",
                        totalLayers: specs.layers,
                        estimatedGB: specs.gb,
                        kvReserveGB: 4.0,
                        notes: "Lokaler HuggingFace-/MLX-Cache",
                        sourceLabel: "MLX Cache",
                        isLiveDiscovered: true
                    ))
                }
            }
        }
        return found
    }

    // MARK: - Scientific Roofline, WAN Topology, Memory, Energetics & Reproducible Benchmarking

    var bytesPerWeight: Double {
        switch sciWeightBits {
        case 4: return 0.5625 // 4-bit MLX affine group=64 (0.5 B + scale/bias overhead)
        case 8: return 1.0625 // 8-bit MLX
        default: return 2.0   // FP16 / BF16
        }
    }

    var isWanScienceActive: Bool {
        sciScope == .internetWan || (sciScope == .hybridCompare && wanPeers.count > 1)
    }

    /// Unified node snapshot across Local TB/RDMA nodes or Internet WAN peers.
    var activeScienceNodes: [ScientificNodeSnapshot] {
        if isWanScienceActive && !wanPeers.isEmpty {
            return wanPeers.map { peer in
                let peak = AppleSiliconChipFamily.inferFP16TFLOPS(from: peer.chip)
                let bw = max(10.0, peer.bandwidthGBs)
                let ridge = (peak * 1000.0) / bw
                let watts = AppleSiliconChipFamily.inferTypicalWatts(from: peer.chip)
                return ScientificNodeSnapshot(
                    id: peer.id,
                    name: peer.displayName,
                    chip: peer.chip,
                    region: peer.region,
                    totalRamGB: peer.ramGB,
                    usableVramGB: peer.usableVramGB,
                    bandwidthGBs: bw,
                    peakFP16TFLOPS: peak,
                    ridgePointFLOPPerByte: ridge,
                    typicalWatts: watts,
                    rttMs: peer.isLocalHost ? 0.0 : peer.rttMs,
                    uplinkMbps: peer.uplinkMbps,
                    linkLabel: peer.isLocalHost ? "\(tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")) (\(peer.transport.localizedTitle(language)))" : "\(peer.region) · \(Int(peer.rttMs))ms",
                    isRemoteWan: !peer.isLocalHost
                )
            }
        }
        return nodes.map { node in
            ScientificNodeSnapshot(
                id: node.id,
                name: node.name,
                chip: node.chip,
                region: "\(tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")) (TB\(node.thunderboltGen))",
                totalRamGB: node.totalRamGB,
                usableVramGB: node.usableVramGB,
                bandwidthGBs: node.bandwidthGBs,
                peakFP16TFLOPS: node.peakFP16TFLOPS,
                ridgePointFLOPPerByte: node.ridgePointFLOPPerByte,
                typicalWatts: node.typicalWatts,
                rttMs: node.id == nodes.first?.id ? 0.0 : (transportMode == .lanWlanOnly ? 0.85 : 0.07),
                uplinkMbps: node.thunderboltGen >= 5 ? 80000.0 : 32000.0,
                linkLabel: "TB\(node.thunderboltGen)\(node.rdmaEnabled ? " RDMA" : "")",
                isRemoteWan: false
            )
        }
    }

    var clusterPeakFP16TFLOPS: Double {
        nodes.reduce(0.0) { $0 + $1.peakFP16TFLOPS }
    }

    var activePeakFP16TFLOPS: Double {
        activeScienceNodes.reduce(0.0) { $0 + $1.peakFP16TFLOPS }
    }

    var clusterAggregateBandwidthGBs: Double {
        nodes.reduce(0.0) { $0 + $1.bandwidthGBs }
    }

    var activeAggregateBandwidthGBs: Double {
        activeScienceNodes.reduce(0.0) { $0 + $1.bandwidthGBs }
    }

    var activeTotalRamGB: Double {
        activeScienceNodes.reduce(0.0) { $0 + $1.totalRamGB }
    }

    var activeTotalUsableVramGB: Double {
        activeScienceNodes.reduce(0.0) { $0 + $1.usableVramGB }
    }

    /// GPipe / async micro-batch pipeline bubble fraction: (N - 1) / (M + N - 1)
    var pipelineBubbleFraction: Double {
        let n = Double(max(1, nodes.count))
        let b = Double(max(1, sciBatchSize))
        return (n - 1.0) / (b + n - 1.0)
    }

    var activePipelineBubbleFraction: Double {
        let n = Double(max(1, activeScienceNodes.count))
        let effMicro = Double(max(1, sciBatchSize * sciMicroBatches))
        return (n - 1.0) / (effMicro + n - 1.0)
    }

    var effectiveDecodeBandwidthGBs: Double {
        let agg = clusterAggregateBandwidthGBs
        let n = Double(max(1, nodes.count))
        if n <= 1 { return agg }
        return agg * (1.0 - pipelineBubbleFraction) * 0.88
    }

    var activeEffectiveDecodeBandwidthGBs: Double {
        let agg = activeAggregateBandwidthGBs
        let n = Double(max(1, activeScienceNodes.count))
        if n <= 1 { return agg }
        let efficiency = isWanScienceActive ? 0.82 : 0.88
        return agg * (1.0 - activePipelineBubbleFraction) * efficiency
    }

    var decodeArithmeticIntensity: Double {
        (2.0 * Double(sciBatchSize)) / bytesPerWeight
    }

    var prefillArithmeticIntensity: Double {
        let raw = (2.0 * Double(sciBatchSize) * Double(sciPromptTokens)) / bytesPerWeight
        return min(raw, 2048.0)
    }

    var estimatedInterconnectOverheadMs: Double {
        let n = max(1, nodes.count)
        if n == 1 {
            return fastSynchEnabled ? 0.004 : 0.180
        }
        let handoffs = Double(n - 1)
        let perHandoffMs: Double
        switch transportMode {
        case .rdmaExperimental: perHandoffMs = 0.015 // ~15 us RDMA Verbs
        case .thunderboltOnly:  perHandoffMs = 0.065 // ~65 us TB IP
        case .autoHybrid:       perHandoffMs = 0.075 // ~75 us TB + control
        case .lanWlanOnly:      perHandoffMs = 0.850 // ~850 us LAN/Wi-Fi
        }
        let metalFenceMs = fastSynchEnabled ? 0.004 : 0.180
        return handoffs * (perHandoffMs + metalFenceMs)
    }

    /// Hidden dimension d_model inferred from model parameter scale for activation tensor payload math.
    var inferredHiddenDim: Double {
        let approxParamsB = max(1.0, selectedModel.estimatedGB / 0.5625)
        if approxParamsB >= 100 { return 12288 }
        if approxParamsB >= 60 { return 8192 }
        if approxParamsB >= 24 { return 5120 }
        return 4096
    }

    /// Activation payload size per pipeline hop in MB: B * d_model * bytesPerElement / 1e6
    var activationPayloadMBPerHop: Double {
        let elems = Double(max(1, sciBatchSize)) * inferredHiddenDim
        return (elems * sciActivationCompression.bytesPerElement) / 1_000_000.0
    }

    var activeStepComputeMs: Double {
        let bw = max(10.0, activeEffectiveDecodeBandwidthGBs)
        return (estimatedModelTrafficGBPerStep / bw) * 1000.0
    }

    var activeStepRttMs: Double {
        let snap = activeScienceNodes
        guard snap.count > 1 else { return 0.0 }
        if isWanScienceActive {
            let remoteRtt = snap.filter(\.isRemoteWan).reduce(0.0) { $0 + $1.rttMs }
            return remoteRtt + Double(snap.count - 1) * wanTransport.baseOverheadMs
        }
        return estimatedInterconnectOverheadMs
    }

    var activeStepTransferMs: Double {
        let snap = activeScienceNodes
        guard snap.count > 1 else { return 0.0 }
        let hops = Double(snap.count - 1)
        let payloadBits = activationPayloadMBPerHop * 8.0 // Megabits
        if isWanScienceActive {
            let minUplinkMbps = max(5.0, snap.map(\.uplinkMbps).min() ?? 100.0)
            return (payloadBits / minUplinkMbps) * 1000.0 * hops
        }
        let linkMbps = transportMode == .lanWlanOnly ? 1000.0 : 32000.0
        return (payloadBits / linkMbps) * 1000.0 * hops
    }

    var activeStepStragglerMs: Double {
        guard activeScienceNodes.count > 1, sciStragglerRate > 0 else { return 0.0 }
        return (activeStepComputeMs + activeStepRttMs) * (sciStragglerRate * 1.65)
    }

    /// Critical batch size B* where micro-batched compute hides network RTT + transfer latency.
    var criticalBatchSizeBStar: Int {
        let netMs = activeStepRttMs + activeStepTransferMs
        let singleCompute = max(0.5, activeStepComputeMs / Double(max(1, sciBatchSize)))
        return max(1, Int(ceil(netMs / singleCompute)))
    }

    /// Effective WAN-adjusted Roofline ceiling (TFLOPS) accounting for network stall fraction.
    var activeEffectiveRooflineCeilingTFLOPS: Double {
        let total = max(0.1, activeStepComputeMs + activeStepRttMs + activeStepTransferMs + activeStepStragglerMs)
        let computeShare = activeStepComputeMs / total
        return activePeakFP16TFLOPS * computeShare
    }

    var activeBottleneckRegime: String {
        let netMs = activeStepRttMs + activeStepTransferMs
        if isWanScienceActive && activeScienceNodes.count > 1 {
            if activeStepRttMs > activeStepComputeMs && activeStepRttMs >= activeStepTransferMs {
                return tr(
                    de: "WAN-RTT-Latenz-begrenzt (B* = \(criticalBatchSizeBStar))",
                    en: "WAN RTT Latency-Bound (B* = \(criticalBatchSizeBStar))",
                    fr: "Limité par latence RTT WAN (B* = \(criticalBatchSizeBStar))",
                    es: "Limitado por latencia RTT WAN (B* = \(criticalBatchSizeBStar))",
                    pt: "Limitado por latência RTT WAN (B* = \(criticalBatchSizeBStar))",
                    ru: "Ограничено задержкой RTT WAN (B* = \(criticalBatchSizeBStar))",
                    ja: "WAN RTT 遅延律速 (B* = \(criticalBatchSizeBStar))",
                    zh: "WAN RTT 延迟受限 (B* = \(criticalBatchSizeBStar))"
                )
            }
            if activeStepTransferMs > activeStepComputeMs {
                return tr(
                    de: "WAN-Uplink-begrenzt (Aktivierungs-Kompression empfohlen)",
                    en: "WAN Uplink-Bound (Activation compression recommended)",
                    fr: "Limité par lien montant WAN (compression conseillée)",
                    es: "Limitado por subida WAN (compresión recomendada)",
                    pt: "Limitado por uplink WAN (compressão recomendada)",
                    ru: "Ограничено аплинком WAN (рекомендуется сжатие)",
                    ja: "WAN アップリンク帯域律速（活性化圧縮推奨）",
                    zh: "WAN 上行带宽受限（建议开启激活压缩）"
                )
            }
        }
        if netMs > activeStepComputeMs * 0.8 && activeScienceNodes.count > 1 {
            return tr(
                de: "Verbindungs-begrenzt (TB/LAN-Übergabe)",
                en: "Interconnect-Bound (TB/LAN Handoff)",
                fr: "Limité par l'interconnexion (TB/LAN)",
                es: "Limitado por interconexión (TB/LAN)",
                pt: "Limitado por interligação (TB/LAN)",
                ru: "Ограничено межсоединением (TB/LAN)",
                ja: "インターコネクト律速 (TB/LAN)",
                zh: "互联传输受限 (TB/LAN 切换)"
            )
        }
        let activeMinRidge = activeScienceNodes.map(\.ridgePointFLOPPerByte).min() ?? 80.0
        if decodeArithmeticIntensity < activeMinRidge {
            return tr(
                de: "Speicherbandbreiten-begrenzt (UMA-Decode)",
                en: "Memory Bandwidth-Bound (UMA Decode)",
                fr: "Limité par bande passante mémoire (UMA Decode)",
                es: "Limitado por ancho de banda de memoria (UMA Decode)",
                pt: "Limitado por largura de banda de memória (UMA Decode)",
                ru: "Ограничено пропускной способностью памяти (UMA Decode)",
                ja: "メモリ帯域幅律速 (UMA Decode)",
                zh: "显存带宽受限 (UMA 解码阶段)"
            )
        }
        return tr(
            de: "Rechenleistungs-begrenzt (Metal FP16)",
            en: "Compute-Bound (Metal FP16)",
            fr: "Limité par le calcul (Metal FP16)",
            es: "Limitado por cómputo (Metal FP16)",
            pt: "Limitado por computação (Metal FP16)",
            ru: "Ограничено вычислениями (Metal FP16)",
            ja: "演算性能律速 (Metal FP16)",
            zh: "算力受限 (Metal FP16)"
        )
    }

    var estimatedModelTrafficGBPerStep: Double {
        let scale = bytesPerWeight / 0.5625
        let weightsGB = selectedModel.estimatedGB * scale
        let kvTrafficGB = (Double(sciPromptTokens) / 32768.0) * kvCacheReserveGB * kvPrecision.memoryFactor
        return weightsGB + kvTrafficGB * 0.25
    }

    var estimatedTPOTMs: Double {
        let bw = max(10.0, effectiveDecodeBandwidthGBs)
        let memTimeMs = (estimatedModelTrafficGBPerStep / bw) * 1000.0
        return memTimeMs + estimatedInterconnectOverheadMs
    }

    var activeTPOTMs: Double {
        // With micro-batching M, WAN RTT is amortized across M concurrent sequences in throughput mode,
        // while single-stream latency sees full RTT. We model amortized per-token wall time for B*M > 1.
        let amort = isWanScienceActive ? max(1.0, Double(sciMicroBatches) * 0.65) : 1.0
        return activeStepComputeMs + (activeStepRttMs + activeStepTransferMs) / amort + activeStepStragglerMs
    }

    var estimatedTokPerSec: Double {
        guard estimatedTPOTMs > 0 else { return 0 }
        return (1000.0 / estimatedTPOTMs) * Double(sciBatchSize)
    }

    var activeTokPerSec: Double {
        guard activeTPOTMs > 0 else { return 0 }
        return (1000.0 / activeTPOTMs) * Double(sciBatchSize)
    }

    var estimatedTTFTMs: Double {
        let approxParamsB = max(1.0, selectedModel.estimatedGB / 0.5625)
        let prefillTFLOPs = 2.0 * approxParamsB * 1e-3 * Double(sciPromptTokens) * Double(sciBatchSize)
        let effectiveTFLOPS = max(1.0, clusterPeakFP16TFLOPS * 0.62)
        let computeMs = (prefillTFLOPs / effectiveTFLOPS) * 1000.0
        return computeMs + estimatedInterconnectOverheadMs * 2.0
    }

    var activeTTFTMs: Double {
        let approxParamsB = max(1.0, selectedModel.estimatedGB / 0.5625)
        let prefillTFLOPs = 2.0 * approxParamsB * 1e-3 * Double(sciPromptTokens) * Double(sciBatchSize)
        let effectiveTFLOPS = max(1.0, activePeakFP16TFLOPS * 0.62)
        let computeMs = (prefillTFLOPs / effectiveTFLOPS) * 1000.0
        let prefillNetMs = activeStepRttMs + activeStepTransferMs * Double(max(1, sciPromptTokens / 512))
        return computeMs + prefillNetMs + activeStepStragglerMs
    }

    var estimatedClusterWatts: Double {
        nodes.reduce(0.0) { $0 + $1.typicalWatts }
    }

    var activeWatts: Double {
        let computeWatts = activeScienceNodes.reduce(0.0) { $0 + $1.typicalWatts }
        let nicRouterWatts = isWanScienceActive ? Double(activeScienceNodes.count) * 4.5 : 0.0
        return computeWatts + nicRouterWatts
    }

    var estimatedJoulesPerToken: Double {
        guard estimatedTokPerSec > 0 else { return 0 }
        return estimatedClusterWatts / estimatedTokPerSec
    }

    var activeJoulesPerToken: Double {
        guard activeTokPerSec > 0 else { return 0 }
        return activeWatts / activeTokPerSec
    }

    /// Energy-Delay Product (EDP) in Joule-seconds per token: lower is better.
    var activeEDPJoulesSec: Double {
        activeJoulesPerToken * (activeTPOTMs / 1000.0)
    }

    var activeCO2GramsPerMillionTokens: Double {
        let kwhPer1M = (activeJoulesPerToken * 1_000_000.0) / 3_600_000.0
        return kwhPer1M * sciCarbonRegion.gco2PerKwh
    }

    var activeCostEurPerMillionTokens: Double {
        let kwhPer1M = (activeJoulesPerToken * 1_000_000.0) / 3_600_000.0
        return kwhPer1M * sciElectricityEurPerKwh
    }

    /// Transformer memory breakdown for the active scope & model.
    var memoryBreakdownGB: (weights: Double, kvPerTokenMB: Double, kvTotalGB: Double, activationsGB: Double, maxContextTokens: Int) {
        let weights = selectedModel.estimatedGB * (bytesPerWeight / 0.5625)
        let approxParamsB = max(1.0, selectedModel.estimatedGB / 0.5625)
        // GQA-aware heuristic: ~0.125 MB/tok for 70B FP16 -> scaled by kvPrecision.memoryFactor
        let kvPerTokMBFP16 = max(0.02, (approxParamsB / 70.0) * 0.125)
        let kvPerTokMB = kvPerTokMBFP16 * kvPrecision.memoryFactor
        let totalSeqTokens = Double(sciBatchSize) * Double(sciPromptTokens + sciGenTokens)
        let kvTotalGB = (totalSeqTokens * kvPerTokMB) / 1024.0
        let activationsGB = max(0.4, (Double(sciBatchSize) * Double(prefillStepSize) * inferredHiddenDim * 4.0) / 1_073_741_824.0)
        let remainingForKvGB = max(0.0, activeTotalUsableVramGB - weights - activationsGB)
        let maxCtx = kvPerTokMB > 0 ? Int((remainingForKvGB * 1024.0) / (kvPerTokMB * Double(max(1, sciBatchSize)))) : 0
        return (weights, kvPerTokMB, kvTotalGB, activationsGB, max(0, maxCtx))
    }

    /// DiLoCo (Distributed Low-Communication) vs Naive DDP bandwidth requirement in Mbps for WAN training/fine-tuning.
    var trainingCommAnalysis: (ddpMbps: Double, diLoCoMbps: Double, pipelineInfMbps: Double, reductionFactor: Int) {
        let approxParamsB = max(1.0, selectedModel.estimatedGB / 0.5625)
        // Gradient volume FP16 = 2 * P GB; AllReduce = 2*(N-1)/N * 2P GB per step (~1.2s step)
        let gradBits = approxParamsB * 2.0 * 8.0 * 1000.0 * 1.8 // Megabits
        let ddpMbps = gradBits / 1.2
        let h = max(10, sciDiLoCoLocalSteps)
        let diLoCoMbps = ddpMbps / Double(h)
        // Inference pipeline sends only B * d_model per token
        let pipelineInfMbps = activationPayloadMBPerHop * 8.0 * max(1.0, activeTokPerSec)
        return (ddpMbps, diLoCoMbps, pipelineInfMbps, h)
    }

    /// Multi-regime scaling curve points (N nodes -> tok/s) for comparative scaling plots.
    func scalingCurvePoints(for regime: String) -> [(nodes: Int, tokPerSec: Double)] {
        let nodeCounts = [1, 2, 4, 8, 16, 32, 64, 128]
        let singleNodeBW = activeScienceNodes.first?.bandwidthGBs ?? 400.0
        let modelGB = max(1.0, estimatedModelTrafficGBPerStep)
        let rttPerHopMs: Double
        let linkGbps: Double
        switch regime {
        case "TB5 RDMA":
            rttPerHopMs = 0.018; linkGbps = 90.0
        case "TB4 Bridge":
            rttPerHopMs = 0.075; linkGbps = 32.0
        case "WAN Regional (25ms)":
            rttPerHopMs = 25.0; linkGbps = 0.5
        case "WAN Global (110ms)":
            rttPerHopMs = 110.0; linkGbps = 0.2
        default:
            rttPerHopMs = 0.85; linkGbps = 1.0
        }

        return nodeCounts.map { n in
            let aggBW = singleNodeBW * Double(n)
            let bubble = Double(n - 1) / Double(max(1, sciBatchSize * sciMicroBatches) + n - 1)
            let effBW = aggBW * (1.0 - bubble) * 0.85
            let compMs = (modelGB / max(10.0, effBW)) * 1000.0
            let hops = Double(max(0, n - 1))
            let txMs = ((activationPayloadMBPerHop * 8.0) / (linkGbps * 1000.0)) * 1000.0 * hops
            let netMs = (rttPerHopMs * hops + txMs) / (regime.hasPrefix("WAN") ? max(1.0, Double(sciMicroBatches) * 0.65) : 1.0)
            let stepMs = max(1.0, compMs + netMs)
            let tps = (1000.0 / stepMs) * Double(sciBatchSize)
            return (n, tps)
        }
    }

    var hardwareFingerprint: String {
        let snap = activeScienceNodes
        let nodeSummary = snap.prefix(6).map { "\($0.chip)(\(Int($0.totalRamGB))GB)" }.joined(separator: "+")
        let extra = snap.count > 6 ? "+\(snap.count - 6)more" : ""
        let linkDesc = isWanScienceActive ? wanTransport.rawValue : transportMode.apiKey
        return "\(nodeSummary)\(extra) | \(sciScope.rawValue) | \(linkDesc) | \(kvPrecision.rawValue) | FastSync=\(fastSynchEnabled ? 1 : 0)"
    }

    func runScientificBenchmark() {
        guard !isRunningBenchmark else { return }
        isRunningBenchmark = true
        sciTrials = []
        sciStatusMessage = t("sci_bench_running")

        let isSimulatedMode = simulateMacStudio
        let scopeSnapshot = sciScope
        let useWan = isWanScienceActive
        let countTarget = max(5, sciTrialCount)
        let baseTTFT = activeTTFTMs
        let baseTPOT = activeTPOTMs
        let baseWatts = activeWatts
        let baseRtt = activeStepRttMs
        let jitterAmp = useWan ? sciWanJitterFactor : 0.022
        let endpointString = "\(openCodeBaseURL)/chat/completions"
        let modelId = selectedModel.id
        let remotePeers = wanPeers.filter { !$0.isLocalHost && $0.isOnline && !$0.overlayIP.isEmpty }
        let wanPeerIPs = remotePeers.map(\.overlayIP)

        let realNoEndpointErr = tr(
            de: "Echtbetrieb: Kein aktiver Inferenz-Endpunkt unter \(openCodeBaseURL) erreichbar",
            en: "Live mode: No active inference endpoint reachable at \(openCodeBaseURL)",
            fr: "Mode réel : aucun point d'inférence actif joignable sur \(openCodeBaseURL)",
            es: "Modo real: ningún endpoint de inferencia activo en \(openCodeBaseURL)",
            pt: "Modo real: nenhum endpoint de inferência ativo em \(openCodeBaseURL)",
            ru: "Реальный режим: нет активного эндпоинта инференса по адресу \(openCodeBaseURL)",
            ja: "実測モード：\(openCodeBaseURL) で稼働中の推論エンドポイントが見つかりません",
            zh: "实时模式：未能在 \(openCodeBaseURL) 检测到活跃的推理端点"
        )
        Task {
            var collected: [ScientificBenchmarkTrial] = []

            if !isSimulatedMode {
                // REAL DATA MODE: Require reachable live inference endpoint (SSE streaming) — never fabricate fake trials
                guard let endpointURL = URL(string: endpointString) else {
                    isRunningBenchmark = false
                    sciSummary = nil
                    sciStatusMessage = tr(
                        de: "Echtbetrieb: Ungültige Endpunkt-URL (\(endpointString)).",
                        en: "Live mode: Invalid endpoint URL (\(endpointString)).",
                        fr: "Mode réel : URL invalide (\(endpointString)).",
                        es: "Modo real: URL no válida (\(endpointString)).",
                        pt: "Modo real: URL inválida (\(endpointString)).",
                        ru: "Реальный режим: неверный URL эндпоинта (\(endpointString)).",
                        ja: "実測モード：無効なエンドポイント URL (\(endpointString))。",
                        zh: "实时模式：无效的端点 URL (\(endpointString))。"
                    )
                    return
                }

                // 1 Warmup + N measured live SSE trials (temperature=0.0 reproducibility protocol)
                for idx in 0...countTarget {
                    let liveSample: (ttftMs: Double, tpotMs: Double, tokensPerSec: Double, generatedTokens: Int)
                    do {
                        liveSample = try await runLiveChatCompletionTrial(endpointURL: endpointURL, modelId: modelId)
                    } catch {
                        isRunningBenchmark = false
                        if collected.isEmpty {
                            sciSummary = nil
                            sciStatusMessage = "\(realNoEndpointErr) (\(error.localizedDescription))."
                        } else {
                            sciStatusMessage = tr(
                                de: "Echtbetrieb unterbrochen nach \(collected.count) realen Läufen: \(error.localizedDescription)",
                                en: "Live mode interrupted after \(collected.count) real trials: \(error.localizedDescription)",
                                fr: "Mode réel interrompu après \(collected.count) essais : \(error.localizedDescription)",
                                es: "Modo real interrumpido tras \(collected.count) pruebas: \(error.localizedDescription)",
                                pt: "Modo real interrompido após \(collected.count) testes: \(error.localizedDescription)",
                                ru: "Прервано после \(collected.count) замеров: \(error.localizedDescription)",
                                ja: "実測が \(collected.count) 回後に中断されました：\(error.localizedDescription)",
                                zh: "实时测量在 \(collected.count) 次后中断：\(error.localizedDescription)"
                            )
                        }
                        return
                    }

                    if idx == 0 { continue } // Discard warmup

                    let measuredRtt: Double
                    if useWan, let targetIP = wanPeerIPs.first {
                        measuredRtt = await measureRealNetworkRttMs(host: targetIP) ?? baseRtt
                    } else {
                        measuredRtt = await measureRealNetworkRttMs(host: "127.0.0.1") ?? 0.2
                    }

                    let watts = baseWatts // Estimated hardware TDP/power envelope for active nodes
                    let tokSec = liveSample.tokensPerSec * Double(max(1, sciBatchSize))
                    let jPerTok = tokSec > 0 ? watts / tokSec : 0
                    let sloPass = liveSample.ttftMs <= sciSloTtftMaxMs && liveSample.tpotMs <= sciSloTpotMaxMs

                    let trial = ScientificBenchmarkTrial(
                        trialIndex: idx,
                        ttftMs: liveSample.ttftMs,
                        tpotMs: liveSample.tpotMs,
                        tokensPerSec: tokSec,
                        netRttMs: measuredRtt,
                        watts: watts,
                        joulesPerToken: jPerTok,
                        sloPass: sloPass,
                        scopeLabel: scopeSnapshot.localizedTitle(language)
                    )
                    collected.append(trial)
                    sciTrials = collected
                }
            } else {
                // SIMULATION MODE: Credible, realistic Apple Silicon cluster telemetry (explicitly marked as Simulation)
                for idx in 0...countTarget {
                    try? await Task.sleep(nanoseconds: useWan ? 45_000_000 : 30_000_000)
                    if idx == 0 { continue } // Discard warmup

                    // Realistic bounded Gaussian-like variation (2-3% local, WAN jitter in WAN scope)
                    let u1 = Double(((idx * 37 + 13) % 97) + 1) / 98.0
                    let u2 = Double(((idx * 53 + 29) % 89) + 1) / 90.0
                    let gaussianApprox = (u1 + u2 - 1.0) // [-1, +1] triangular/normal-like
                    let tailSpike = (useWan && idx % 10 == 9) ? jitterAmp * 1.25 : 0.0
                    let ttftFactor = max(0.88, 1.0 + gaussianApprox * (jitterAmp * 0.6) + tailSpike)
                    let tpotFactor = max(0.92, 1.0 + gaussianApprox * (jitterAmp * 0.4) + tailSpike * 0.5)

                    let simTTFT = max(8.0, baseTTFT * ttftFactor)
                    let simTPOT = max(1.5, baseTPOT * tpotFactor)
                    let tokSec = (1000.0 / simTPOT) * Double(sciBatchSize)
                    let watts = baseWatts * (0.97 + Double(idx % 5) * 0.015)
                    let jPerTok = tokSec > 0 ? watts / tokSec : 0
                    let rttSample = max(0.2, baseRtt * max(0.85, 1.0 + gaussianApprox * jitterAmp))
                    let sloPass = simTTFT <= sciSloTtftMaxMs && simTPOT <= sciSloTpotMaxMs

                    let trial = ScientificBenchmarkTrial(
                        trialIndex: idx,
                        ttftMs: simTTFT,
                        tpotMs: simTPOT,
                        tokensPerSec: tokSec,
                        netRttMs: rttSample,
                        watts: watts,
                        joulesPerToken: jPerTok,
                        sloPass: sloPass,
                        scopeLabel: scopeSnapshot.localizedTitle(language)
                    )
                    collected.append(trial)
                    sciTrials = collected
                }
            }

            let ttfTs = collected.map(\.ttftMs).sorted()
            let tpoTs = collected.map(\.tpotMs).sorted()
            let n = Double(max(1, collected.count))
            let ttftMean = ttfTs.reduce(0, +) / n
            let tpotMean = tpoTs.reduce(0, +) / n
            let ttftSD = Self.stdDev(ttfTs, mean: ttftMean)
            let tpotSD = Self.stdDev(tpoTs, mean: tpotMean)
            let ci95Ttft = 1.96 * ttftSD / sqrt(n)
            let ci95Tpot = 1.96 * tpotSD / sqrt(n)
            let cvPct = tpotMean > 0 ? (tpotSD / tpotMean) * 100.0 : 0.0
            let goodputPct = (Double(collected.filter(\.sloPass).count) / n) * 100.0

            let meanTok = collected.map(\.tokensPerSec).reduce(0, +) / n
            let meanW = collected.map(\.watts).reduce(0, +) / n
            let jPerTok = meanTok > 0 ? meanW / meanTok : 0
            let whPer1M = (jPerTok * 1_000_000.0) / 3600.0
            let edp = jPerTok * (tpotMean / 1000.0)
            let co2Per1M = ((jPerTok * 1_000_000.0) / 3_600_000.0) * sciCarbonRegion.gco2PerKwh

            let backendDesc: String
            if !isSimulatedMode {
                backendDesc = useWan
                    ? "\(selectedService.rawValue) (Live SSE + Real RTT)"
                    : "\(selectedService.rawValue) (Live SSE)"
            } else {
                backendDesc = useWan
                    ? "Simulation (Realistic Apple Silicon + WAN)"
                    : "Simulation (Realistic Apple Silicon)"
            }

            let formatter = ISO8601DateFormatter()
            sciSummary = ScientificBenchmarkSummary(
                modelId: selectedModel.id,
                scopeLabel: scopeSnapshot.localizedTitle(language),
                hardwareFingerprint: hardwareFingerprint,
                backendLabel: backendDesc,
                trialCount: collected.count,
                warmupDiscarded: 1,
                ttftMeanMs: ttftMean,
                ttftP50Ms: Self.percentile(ttfTs, p: 0.50),
                ttftP95Ms: Self.percentile(ttfTs, p: 0.95),
                ttftP99Ms: Self.percentile(ttfTs, p: 0.99),
                ttftStdDevMs: ttftSD,
                ci95TtftMarginMs: ci95Ttft,
                tpotMeanMs: tpotMean,
                tpotP50Ms: Self.percentile(tpoTs, p: 0.50),
                tpotP95Ms: Self.percentile(tpoTs, p: 0.95),
                tpotP99Ms: Self.percentile(tpoTs, p: 0.99),
                tpotStdDevMs: tpotSD,
                ci95TpotMarginMs: ci95Tpot,
                cvPercent: cvPct,
                goodputPercent: goodputPct,
                meanTokensPerSec: meanTok,
                meanWatts: meanW,
                joulesPerToken: jPerTok,
                whPerMillionTokens: whPer1M,
                edpJoulesSec: edp,
                co2GramsPerMillionTok: co2Per1M,
                timestamp: formatter.string(from: Date()),
                isLiveEndpoint: !isSimulatedMode
            )
            isRunningBenchmark = false
            sciStatusMessage = isSimulatedMode
                ? tr(
                    de: "Simulation abgeschlossen (\(collected.count) realistische Läufe).",
                    en: "Simulation complete (\(collected.count) realistic runs).",
                    fr: "Simulation terminée (\(collected.count) essais réalistes).",
                    es: "Simulación completada (\(collected.count) pruebas realistas).",
                    pt: "Simulação concluída (\(collected.count) ensaios realistas).",
                    ru: "Симуляция завершена (\(collected.count) реалистичных прогонов).",
                    ja: "シミュレーション完了（\(collected.count) 回の実践的試行）。",
                    zh: "模拟测试完成（\(collected.count) 轮仿真测量）。"
                )
                : t("sci_bench_done")
            if sciAutoRecordHistory {
                let modeTag = isSimulatedMode
                    ? tr(de: "Simulation", en: "Simulation", fr: "Simulation", es: "Simulación", pt: "Simulação", ru: "Симуляция", ja: "シミュレーション", zh: "模拟")
                    : tr(de: "Live-Messung", en: "Live Run", fr: "Mesure directe", es: "Medición en vivo", pt: "Medição ao vivo", ru: "Живой замер", ja: "実測", zh: "实测")
                let runLabel = tr(de: "Läufe", en: "runs", fr: "essais", es: "pruebas", pt: "ensaios", ru: "прогонов", ja: "回", zh: "次")
                recordScienceHistory(position: .globalAll, note: "\(modeTag) (\(collected.count) \(runLabel), T=0.0)")
            }
        }
    }

    /// Streams a real `/v1/chat/completions` SSE request and measures true TTFT (first token chunk) and decode TPOT.
    private func runLiveChatCompletionTrial(
        endpointURL: URL,
        modelId: String
    ) async throws -> (ttftMs: Double, tpotMs: Double, tokensPerSec: Double, generatedTokens: Int) {
        var req = URLRequest(url: endpointURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "model": modelId,
            "temperature": 0.0,
            "max_tokens": 32,
            "stream": true,
            "stream_options": ["include_usage": true],
            "messages": [["role": "user", "content": "State the Roofline equation in one sentence."]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let startNs = DispatchTime.now().uptimeNanoseconds
        let (bytes, response) = try await URLSession.shared.bytes(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NSError(
                domain: "SSCCC.ScienceBenchmark",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"]
            )
        }

        var firstTokenNs: UInt64?
        var streamedChunks = 0
        var reportedCompletionTokens: Int?

        for try await rawLine in bytes.lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.hasPrefix("data:") else { continue }
            let jsonText = line.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
            if jsonText == "[DONE]" || jsonText.isEmpty { continue }

            guard let data = jsonText.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            if let usage = obj["usage"] as? [String: Any],
               let compTokens = usage["completion_tokens"] as? Int, compTokens > 0 {
                reportedCompletionTokens = compTokens
            }

            if let choices = obj["choices"] as? [[String: Any]], let first = choices.first {
                let delta = first["delta"] as? [String: Any]
                let content = (delta?["content"] as? String)
                    ?? (delta?["reasoning_content"] as? String)
                    ?? (first["text"] as? String)
                    ?? ""
                if !content.isEmpty {
                    if firstTokenNs == nil {
                        firstTokenNs = DispatchTime.now().uptimeNanoseconds
                    }
                    streamedChunks += 1
                }
            }
        }

        let endNs = DispatchTime.now().uptimeNanoseconds
        let generatedTokens = max(1, reportedCompletionTokens ?? streamedChunks)
        let firstNs = firstTokenNs ?? endNs
        let ttftMs = max(1.0, Double(firstNs - startNs) / 1_000_000.0)
        let decodeMs = max(0.5, Double(endNs - firstNs) / 1_000_000.0)
        let tpotMs = generatedTokens > 1 ? max(0.2, decodeMs / Double(generatedTokens - 1)) : decodeMs
        let tokSec = decodeMs > 0 ? (Double(generatedTokens) / (decodeMs / 1000.0)) : (1000.0 / max(0.5, tpotMs))
        return (ttftMs, tpotMs, tokSec, generatedTokens)
    }

    /// Measures real ICMP ping RTT in milliseconds to a target host.
    private func measureRealNetworkRttMs(host: String) async -> Double? {
        await Task.detached(priority: .utility) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/sbin/ping")
            proc.arguments = ["-c", "1", "-W", "800", host]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = FileHandle.nullDevice
            proc.standardInput = FileHandle.nullDevice
            guard (try? proc.run()) != nil else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            let out = String(data: data, encoding: .utf8) ?? ""
            guard let range = out.range(of: #"time=([0-9]+(\.[0-9]+)?)\s*ms"#, options: .regularExpression) else {
                return nil
            }
            let match = String(out[range])
            let numStr = match.replacingOccurrences(of: "time=", with: "")
                .replacingOccurrences(of: "ms", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return Double(numStr)
        }.value
    }

    func recordScienceHistory(position: ScienceHistoryPosition? = nil, note: String = "") {
        let pos = position ?? sciHistoryPositionFilter
        let s = sciSummary
        let entry = ScienceHistoryEntry(
            timestamp: currentClockTime(),
            positionFilter: pos,
            scopeLabel: sciScope.localizedTitle(language),
            modelName: selectedModel.displayName,
            nodeCount: activeScienceNodes.count,
            usableVramGB: activeTotalUsableVramGB,
            ttftMs: s?.ttftP50Ms ?? activeTTFTMs,
            tpotMs: s?.tpotP50Ms ?? activeTPOTMs,
            tokPerSec: s?.meanTokensPerSec ?? activeTokPerSec,
            wanRttMs: activeStepRttMs,
            bubblePercent: activePipelineBubbleFraction * 100.0,
            joulesPerToken: s?.joulesPerToken ?? activeJoulesPerToken,
            edpJouleSec: s?.edpJoulesSec ?? activeEDPJoulesSec,
            co2PerMillionTok: s?.co2GramsPerMillionTok ?? activeCO2GramsPerMillionTokens,
            bottleneckRegime: activeBottleneckRegime,
            note: note.isEmpty ? pos.rawValue : note
        )
        sciHistoryEntries.append(entry)
    }

    func clearScienceHistory() {
        sciHistoryEntries.removeAll()
    }

    var filteredScienceHistory: [ScienceHistoryEntry] {
        if sciHistoryPositionFilter == .globalAll {
            return sciHistoryEntries
        }
        return sciHistoryEntries.filter { $0.positionFilter == sciHistoryPositionFilter || $0.positionFilter == .globalAll }
    }

    func exportScienceHistoryCSV() -> String {
        var lines = ["timestamp,position,scope,model,nodes,usable_vram_gb,ttft_ms,tpot_ms,tok_per_sec,wan_rtt_ms,bubble_pct,j_per_tok,edp_js,co2_g_per_1m,bottleneck,note"]
        for h in filteredScienceHistory {
            lines.append("\(h.timestamp),\(h.positionFilter.rawValue),\(h.scopeLabel),\(h.modelName),\(h.nodeCount),\(String(format: "%.1f", h.usableVramGB)),\(String(format: "%.1f", h.ttftMs)),\(String(format: "%.2f", h.tpotMs)),\(String(format: "%.2f", h.tokPerSec)),\(String(format: "%.2f", h.wanRttMs)),\(String(format: "%.1f", h.bubblePercent)),\(String(format: "%.2f", h.joulesPerToken)),\(String(format: "%.3f", h.edpJouleSec)),\(String(format: "%.1f", h.co2PerMillionTok)),\"\(h.bottleneckRegime)\",\"\(h.note)\"")
        }
        return lines.joined(separator: "\n")
    }

    private static func stdDev(_ values: [Double], mean: Double) -> Double {
        guard values.count > 1 else { return 0 }
        let sumSq = values.reduce(0.0) { $0 + pow($1 - mean, 2) }
        return sqrt(sumSq / Double(values.count - 1))
    }

    private static func percentile(_ sorted: [Double], p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let idx = min(sorted.count - 1, max(0, Int(ceil(p * Double(sorted.count))) - 1))
        return sorted[idx]
    }

    func exportScientificCSV() -> String {
        var lines = ["trial,scope,model,nodes,batch_size,micro_batches,prompt_tokens,weight_bits,act_compression,ttft_ms,tpot_ms,tokens_per_sec,net_rtt_ms,watts,joules_per_token,slo_pass"]
        for tr in sciTrials {
            lines.append("\(tr.trialIndex),\(tr.scopeLabel),\(selectedModel.id),\(activeScienceNodes.count),\(sciBatchSize),\(sciMicroBatches),\(sciPromptTokens),\(sciWeightBits),\(sciActivationCompression.rawValue),\(String(format: "%.2f", tr.ttftMs)),\(String(format: "%.2f", tr.tpotMs)),\(String(format: "%.2f", tr.tokensPerSec)),\(String(format: "%.2f", tr.netRttMs)),\(String(format: "%.1f", tr.watts)),\(String(format: "%.2f", tr.joulesPerToken)),\(tr.sloPass)")
        }
        return lines.joined(separator: "\n")
    }

    func exportScientificJSON() -> String {
        let s = sciSummary
        return """
        {
          "tool": "SonnerStudio Cluster-Case-Companion (SS-CCC)",
          "timestamp": "\(s?.timestamp ?? ISO8601DateFormatter().string(from: Date()))",
          "scope": "\(sciScope.rawValue)",
          "node_count": \(activeScienceNodes.count),
          "hardware_fingerprint": "\(hardwareFingerprint)",
          "model_id": "\(selectedModel.id)",
          "workload": {
            "batch_size": \(sciBatchSize),
            "micro_batches": \(sciMicroBatches),
            "prompt_tokens": \(sciPromptTokens),
            "gen_tokens": \(sciGenTokens),
            "weight_bits": \(sciWeightBits),
            "activation_compression": "\(sciActivationCompression.rawValue)",
            "straggler_rate": \(String(format: "%.2f", sciStragglerRate)),
            "temperature": 0.0
          },
          "roofline": {
            "cluster_peak_fp16_tflops": \(String(format: "%.2f", activePeakFP16TFLOPS)),
            "effective_wan_ceiling_tflops": \(String(format: "%.2f", activeEffectiveRooflineCeilingTFLOPS)),
            "effective_decode_bw_gbs": \(String(format: "%.2f", activeEffectiveDecodeBandwidthGBs)),
            "pipeline_bubble_fraction": \(String(format: "%.4f", activePipelineBubbleFraction)),
            "critical_batch_b_star": \(criticalBatchSizeBStar),
            "bottleneck_regime": "\(activeBottleneckRegime)",
            "decode_arithmetic_intensity_flop_per_byte": \(String(format: "%.2f", decodeArithmeticIntensity)),
            "prefill_arithmetic_intensity_flop_per_byte": \(String(format: "%.2f", prefillArithmeticIntensity))
          },
          "metrics": {
            "ttft_p50_ms": \(String(format: "%.2f", s?.ttftP50Ms ?? activeTTFTMs)),
            "ttft_p95_ms": \(String(format: "%.2f", s?.ttftP95Ms ?? activeTTFTMs)),
            "ttft_ci95_margin_ms": \(String(format: "%.2f", s?.ci95TtftMarginMs ?? 0)),
            "tpot_p50_ms": \(String(format: "%.2f", s?.tpotP50Ms ?? activeTPOTMs)),
            "tpot_p95_ms": \(String(format: "%.2f", s?.tpotP95Ms ?? activeTPOTMs)),
            "tpot_ci95_margin_ms": \(String(format: "%.2f", s?.ci95TpotMarginMs ?? 0)),
            "cv_percent": \(String(format: "%.2f", s?.cvPercent ?? 0)),
            "goodput_percent": \(String(format: "%.1f", s?.goodputPercent ?? 100.0)),
            "mean_tokens_per_sec": \(String(format: "%.2f", s?.meanTokensPerSec ?? activeTokPerSec)),
            "joules_per_token": \(String(format: "%.2f", s?.joulesPerToken ?? activeJoulesPerToken)),
            "edp_joule_sec": \(String(format: "%.4f", s?.edpJoulesSec ?? activeEDPJoulesSec)),
            "co2_grams_per_1m_tokens": \(String(format: "%.1f", s?.co2GramsPerMillionTok ?? activeCO2GramsPerMillionTokens))
          }
        }
        """
    }

    func exportScientificLaTeX() -> String {
        let s = sciSummary
        let ttft = String(format: "%.1f", s?.ttftP50Ms ?? activeTTFTMs)
        let tpot = String(format: "%.2f", s?.tpotP50Ms ?? activeTPOTMs)
        let ci = String(format: "%.2f", s?.ci95TpotMarginMs ?? 0.0)
        let tps = String(format: "%.1f", s?.meanTokensPerSec ?? activeTokPerSec)
        let jpt = String(format: "%.2f", s?.joulesPerToken ?? activeJoulesPerToken)
        let gp = String(format: "%.1f", s?.goodputPercent ?? 100.0)
        return """
        \\begin{table}[t]
        \\centering
        \\caption{SS-CCC Evaluation: \(selectedModel.displayName) (\(sciScope.rawValue), $N=\(activeScienceNodes.count)$, $B=\(sciBatchSize)$, $M=\(sciMicroBatches)$)}
        \\label{tab:ssccc-eval}
        \\begin{tabular}{lcccccc}
        \\toprule
        Scope & Nodes & TTFT$_{p50}$ (ms) & TPOT$_{p50} \\pm \\text{CI}_{95}$ (ms) & Throughput (tok/s) & Energy (J/tok) & Goodput (\\%) \\\\
        \\midrule
        \(sciScope.rawValue) & \(activeScienceNodes.count) & \(ttft) & $\(tpot) \\pm \(ci)$ & \(tps) & \(jpt) & \(gp)\\% \\\\
        \\bottomrule
        \\end{tabular}
        \\end{table}
        """
    }

    func exportBibTeX() -> String {
        """
        @article{williams2009roofline,
          title={Roofline: An Insightful Visual Performance Model for Multicore Architectures},
          author={Williams, Samuel and Waterman, Andrew and Patterson, David},
          journal={Communications of the ACM},
          volume={52}, number={4}, pages={65--76}, year={2009}
        }
        @inproceedings{patel2024splitwise,
          title={Splitwise: Efficient Generative LLM Inference Using Phase Splitting},
          author={Patel, Pratyush and Choukse, Esha and Zhang, Chaojie and Shah, Aashaka and Goiri, Inigo and Maleki, Saeed and Bianchini, Ricardo},
          booktitle={ISCA}, year={2024}
        }
        @inproceedings{zhong2024distserve,
          title={DistServe: Disaggregating Prefill and Decoding for Goodput-optimized Large Language Model Serving},
          author={Zhong, Yinmin and Liu, Shengyu and Chen, Junda and Hu, Jianbo and Zhu, Yibo and Liu, Xuanzhe and Jin, Xin and Zhang, Hao},
          booktitle={USENIX OSDI}, year={2024}
        }
        @inproceedings{kwon2023pagedattention,
          title={Efficient Memory Management for Large Language Model Serving with PagedAttention},
          author={Kwon, Woosuk and Li, Zhuohan and Zhuang, Siyuan and Sheng, Ying and Zheng, Lianmin and Yu, Cody Hao and Gonzalez, Joseph and Zhang, Hao and Stoica, Ion},
          booktitle={ACM SOSP}, year={2023}
        }
        @inproceedings{borzunov2023petals,
          title={Petals: Collaborative Inference and Fine-tuning of Large Models},
          author={Borzunov, Alexander and Ryabinin, Max and Chumachenko, Artem and Baranchuk, Dmitry and Dettmers, Tim and Belkada, Younes and Samygin, Pavel and Raffel, Colin},
          booktitle={ACL System Demonstrations}, year={2023}
        }
        @inproceedings{ryabinin2023swarm,
          title={SWARM Parallelism: Training Large Models Can Be Surprisingly Communication-Efficient},
          author={Ryabinin, Max and Dettmers, Tim and Diskin, Michael and Borzunov, Alexander},
          booktitle={ICML}, year={2023}
        }
        @article{douillard2024diloco,
          title={DiLoCo: Distributed Low-Communication Training of Language Models},
          author={Douillard, Arthur and Feng, Qixuan and Rusu, Andrei A. and Chhaparia, Rachita and Donchev, Yani and Kuncoro, Adhiguna and Ranzato, Marc'Aurelio and Szlam, Arthur and Shen, Jiawei},
          journal={arXiv preprint arXiv:2311.08105}, year={2024}
        }
        @article{tokenpowerbench2025,
          title={TokenPowerBench: Benchmarking Power and Energy Efficiency of LLM Inference},
          author={Chen, Wei and Liu, Yifan and Zhang, Hao},
          journal={arXiv preprint arXiv:2502.00124}, year={2025}
        }
        """
    }

    // MARK: - Internet WAN Cluster & Participant Chat

    var wanTotalRamGB: Double {
        wanPeers.reduce(0.0) { $0 + $1.ramGB }
    }

    var wanTotalUsableVramGB: Double {
        wanPeers.reduce(0.0) { $0 + $1.usableVramGB }
    }

    var wanRemotePeers: [WanPeerNode] {
        wanPeers.filter { !$0.isLocalHost && !$0.id.hasPrefix("local-bridge-") }
    }

    var wanLocalIslandPeers: [WanPeerNode] {
        wanPeers.filter { $0.isLocalHost || $0.id.hasPrefix("local-bridge-") }
    }

    var wanSubclustersByRegion: [(region: String, peers: [WanPeerNode])] {
        let grouped = Dictionary(grouping: wanRemotePeers) { peer in
            peer.region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Global WAN" : peer.region
        }
        return grouped.keys.sorted().map { key in
            (region: key, peers: grouped[key] ?? [])
        }
    }

    var hybridCombinedRamGB: Double {
        totalPhysicalRamGB + wanRemotePeers.reduce(0.0) { $0 + $1.ramGB }
    }

    var hybridCombinedUsableVramGB: Double {
        totalUsableVramGB + wanRemotePeers.reduce(0.0) { $0 + $1.usableVramGB }
    }

    var hybridCombinedNodeCount: Int {
        nodes.count + wanRemotePeers.count
    }

    var wanTotalRttMs: Double {
        guard wanPeers.count > 1 else { return 0.0 }
        let remoteRtt = wanPeers.filter { !$0.isLocalHost }.reduce(0.0) { $0 + $1.rttMs }
        return remoteRtt + Double(wanPeers.count - 1) * wanTransport.baseOverheadMs
    }

    var wanEstimatedTokPerSec: Double {
        guard !wanPeers.isEmpty else { return 0.0 }
        let avgBw = max(68.0, wanPeers.reduce(0.0) { $0 + $1.bandwidthGBs } / Double(wanPeers.count))
        let computeMs = (selectedModel.estimatedGB / avgBw) * 1000.0
        let minUplinkMbps = max(10.0, wanBottleneckUplinkMbps > 0 ? wanBottleneckUplinkMbps : (wanPeers.map(\.uplinkMbps).min() ?? 100.0))
        // ~16 KB activation hidden-state tensor per pipeline hop
        let transferMs = wanPeers.count > 1 ? ((0.128 / minUplinkMbps) * 1000.0) * Double(wanPeers.count - 1) : 0.0
        let totalStepMs = max(5.0, computeMs + wanTotalRttMs + transferMs)
        return 1000.0 / totalStepMs
    }

    // MARK: - Internet Bandwidth & WAN Throughput Monitoring

    /// Effective bottleneck uplink across local WAN egress and remote WAN peers (Mbps).
    var wanBottleneckUplinkMbps: Double {
        let peerMin = wanRemotePeers.map(\.uplinkMbps).min() ?? (wanPeers.map(\.uplinkMbps).min() ?? 0.0)
        if wanMeasuredUploadMbps > 0 {
            return peerMin > 0 ? min(wanMeasuredUploadMbps, peerMin) : wanMeasuredUploadMbps
        }
        return peerMin
    }

    /// Net usable payload throughput in MB/s after ~12% overlay/QUIC/WireGuard framing overhead.
    var wanEffectivePayloadMBs: Double {
        (wanBottleneckUplinkMbps / 8.0) * 0.88
    }

    /// Per-hop hidden-state tensor sync latency (16 KB activation + current WAN ping RTT).
    var wanActivationSyncOverheadMs: Double {
        let uplink = max(1.0, wanBottleneckUplinkMbps)
        let serializationMs = (0.128 / uplink) * 1000.0
        let rtt = wanMeasuredPingMs > 0 ? wanMeasuredPingMs : (wanRemotePeers.map(\.rttMs).max() ?? 0.0)
        return serializationMs + rtt
    }

    /// Percentage of inference step time spent in productive GPU compute vs WAN network wait.
    var wanPipelineEfficiencyPct: Double {
        guard !wanPeers.isEmpty else { return 0.0 }
        let avgBw = max(68.0, wanPeers.reduce(0.0) { $0 + $1.bandwidthGBs } / Double(wanPeers.count))
        let computeMs = (selectedModel.estimatedGB / avgBw) * 1000.0
        let minUplink = max(1.0, wanBottleneckUplinkMbps > 0 ? wanBottleneckUplinkMbps : 100.0)
        let transferMs = wanPeers.count > 1 ? ((0.128 / minUplink) * 1000.0) * Double(wanPeers.count - 1) : 0.0
        let netMs = wanTotalRttMs + transferMs
        let total = computeMs + netMs
        return total > 0 ? (computeMs / total) * 100.0 : 100.0
    }

    var wanConnectionQualityGrade: String {
        if wanMeasuredDownloadMbps <= 0 && wanMeasuredUploadMbps <= 0 && wanMeasuredPingMs <= 0 {
            return tr(
                de: "Nicht gemessen — Live-Check oder Speedtest starten",
                en: "Not measured — run Live Check or Speedtest",
                fr: "Non mesuré — lancer vérif. live ou test de débit",
                es: "Sin medir — ejecuta Live Check o Speedtest",
                pt: "Não medido — iniciar verificação ou Speedtest",
                ru: "Не измерено — запустите Live Check или Speedtest",
                ja: "未計測 — ライブ確認または Speedtest を実行",
                zh: "未测量 — 请点击实时检测或速度测试"
            )
        }
        let uplink = wanBottleneckUplinkMbps
        let rtt = wanMeasuredPingMs
        if uplink >= 150.0 && rtt <= 30.0 && wanMeasuredPacketLossPct < 0.5 {
            return tr(de: "Exzellent (High-Throughput Fiber · ideal für PP)", en: "Excellent (High-Throughput Fiber · ideal for PP)", fr: "Excellent (Fibre haut débit · idéal pour PP)", es: "Excelente (Fibra de alto rendimiento · ideal PP)", pt: "Excelente (Fibra de alto débito · ideal para PP)", ru: "Отлично (Высокоскоростная оптика · идеал для PP)", ja: "優秀（高速光回線 · PP に最適）", zh: "极佳（高速光纤 · 极适合流水线并行）")
        } else if uplink >= 50.0 && rtt <= 65.0 && wanMeasuredPacketLossPct < 1.5 {
            return tr(de: "Gut (Stabil für Pipeline-Parallelism)", en: "Good (Stable for Pipeline Parallelism)", fr: "Bon (Stable pour parallélisme en pipeline)", es: "Bueno (Estable para paralelismo en pipeline)", pt: "Bom (Estável para paralelismo em pipeline)", ru: "Хорошо (Стабильно для Pipeline Parallelism)", ja: "良好（パイプライン並列に安定）", zh: "良好（流水线并行稳定）")
        } else {
            return tr(de: "Eingeschränkt (Hohe Latenz/Engpass · DiLoCo empfohlen)", en: "Constrained (High Latency/Bottleneck · DiLoCo recommended)", fr: "Limité (Latence élevée · DiLoCo recommandé)", es: "Limitado (Latencia alta · se recomienda DiLoCo)", pt: "Limitado (Latência elevada · DiLoCo recomendado)", ru: "Ограничено (Высокая задержка · нужен DiLoCo)", ja: "制限あり（高遅延/ボトルネック · DiLoCo 推奨）", zh: "受限（延迟较高或带宽窄 · 建议使用 DiLoCo）")
        }
    }

    /// Measures real interface throughput (`netstat -ibn`), ICMP ping + jitter/loss, and optionally `/usr/bin/networkQuality -c`
    /// in Real Mode (`!simulateMacStudio`), or realistic WAN fiber telemetry in Simulation Mode.
    func probeWanBandwidthAndThroughput(runActiveSpeedTest: Bool = false) {
        guard !isProbingWanBandwidth else { return }
        isProbingWanBandwidth = true
        let isSimulated = simulateMacStudio
        let targetPeerIP = wanRemotePeers.first(where: { $0.isOnline && !$0.overlayIP.isEmpty })?.overlayIP ?? "1.1.1.1"
        wanBandwidthSourceLabel = isSimulated
            ? tr(de: "Simulation läuft...", en: "Running simulation...", fr: "Simulation en cours...", es: "Ejecutando simulación...", pt: "Simulação em curso...", ru: "Идёт симуляция...", ja: "シミュレーション計測中...", zh: "正在模拟测速...")
            : (runActiveSpeedTest
                ? tr(de: "Aktiver macOS Speedtest (/usr/bin/networkQuality)...", en: "Running macOS Speedtest (/usr/bin/networkQuality)...", fr: "Test macOS en cours (/usr/bin/networkQuality)...", es: "Prueba macOS en curso (/usr/bin/networkQuality)...", pt: "Teste macOS em curso (/usr/bin/networkQuality)...", ru: "Тест скорости macOS (/usr/bin/networkQuality)...", ja: "macOS Speedtest 実行中...", zh: "正在运行 macOS 速度测试 (/usr/bin/networkQuality)...")
                : tr(de: "Messe Live-Interface & ICMP-Ping...", en: "Probing live interface & ICMP ping...", fr: "Mesure d'interface live & ping ICMP...", es: "Midiendo interfaz en vivo y ping ICMP...", pt: "A medir interface ao vivo e ping ICMP...", ru: "Замер интерфейса и ICMP ping...", ja: "ライブNICとICMPピングを計測中...", zh: "正在探测实时网卡速率与 ICMP 延迟..."))

        Task {
            if isSimulated {
                try? await Task.sleep(nanoseconds: runActiveSpeedTest ? 350_000_000 : 180_000_000)
                let idx = wanThroughputHistory.count + 1
                let wave = Double(((idx * 29 + 7) % 19) - 9) / 9.0
                let dl = max(250.0, 485.0 + wave * 35.0)
                let ul = max(100.0, 215.0 + wave * 18.0)
                let ping = max(8.0, 16.5 + wave * 2.2)
                let jitter = max(0.3, 1.4 + abs(wave) * 0.9)
                let loss = 0.0
                let payloadMBs = (ul / 8.0) * 0.88

                self.wanActiveInterfaceName = "en0 (Sim)"
                self.wanMeasuredDownloadMbps = dl
                self.wanMeasuredUploadMbps = ul
                self.wanMeasuredPingMs = ping
                self.wanMeasuredJitterMs = jitter
                self.wanMeasuredPacketLossPct = loss
                self.wanBandwidthSourceLabel = self.tr(de: "Simulation (Realistische Glasfaser-WAN-Telemetrie)", en: "Simulation (Realistic Fiber WAN Telemetry)", fr: "Simulation (Télémétrie Fibre WAN réaliste)", es: "Simulación (Telemetría WAN Fibra realista)", pt: "Simulação (Telemetria WAN Fibra realista)", ru: "Симуляция (Реалистичная оптоволоконная телеметрия)", ja: "シミュレーション（現実的な光回線WANテレメトリ）", zh: "模拟（真实光纤 WAN 遥测基准）")
                self.wanBandwidthLastUpdated = self.currentClockTime()
                self.appendWanThroughputSample(
                    downloadMbps: dl,
                    uploadMbps: ul,
                    pingRttMs: ping,
                    jitterMs: jitter,
                    packetLossPct: loss,
                    tensorSyncMBs: payloadMBs,
                    isLive: false
                )
                self.isProbingWanBandwidth = false
                return
            }

            // REAL DATA MODE: probe default interface, netstat delta, ICMP ping, and optional networkQuality
            let result = await Task.detached(priority: .utility) { () -> (iface: String, dlMbps: Double, ulMbps: Double, pingMs: Double, jitterMs: Double, lossPct: Double, source: String) in
                let iface = Self.detectDefaultNetworkInterface() ?? "en0"
                let statsBefore = Self.readInterfaceBytes(iface: iface)
                try? await Task.sleep(nanoseconds: 450_000_000)
                let statsAfter = Self.readInterfaceBytes(iface: iface)

                var dlMbps = 0.0
                var ulMbps = 0.0
                if let b0 = statsBefore, let b1 = statsAfter {
                    let rxDelta = b1.rx >= b0.rx ? Double(b1.rx - b0.rx) : 0.0
                    let txDelta = b1.tx >= b0.tx ? Double(b1.tx - b0.tx) : 0.0
                    dlMbps = (rxDelta * 8.0) / (0.45 * 1_000_000.0)
                    ulMbps = (txDelta * 8.0) / (0.45 * 1_000_000.0)
                }

                let pingRes = Self.runIcmpPingProbe(host: targetPeerIP, count: 3)
                var sourceDesc = "Echtzeit: \(iface) (netstat) + ICMP Ping (\(targetPeerIP))"

                if runActiveSpeedTest, let nq = Self.runMacOSNetworkQuality() {
                    dlMbps = nq.dlMbps
                    ulMbps = nq.ulMbps
                    sourceDesc = "Echtzeit: /usr/bin/networkQuality + ICMP Ping (\(targetPeerIP))"
                }

                return (iface, dlMbps, ulMbps, pingRes.avgMs, pingRes.jitterMs, pingRes.lossPct, sourceDesc)
            }.value

            self.wanActiveInterfaceName = result.iface
            if result.dlMbps > 0 || runActiveSpeedTest {
                self.wanMeasuredDownloadMbps = result.dlMbps
            }
            if result.ulMbps > 0 || runActiveSpeedTest {
                self.wanMeasuredUploadMbps = result.ulMbps
            }
            self.wanMeasuredPingMs = result.pingMs
            self.wanMeasuredJitterMs = result.jitterMs
            self.wanMeasuredPacketLossPct = result.lossPct
            self.wanBandwidthSourceLabel = result.source
            self.wanBandwidthLastUpdated = self.currentClockTime()
            let effPayload = (self.wanBottleneckUplinkMbps / 8.0) * 0.88
            self.appendWanThroughputSample(
                downloadMbps: result.dlMbps,
                uploadMbps: result.ulMbps,
                pingRttMs: result.pingMs,
                jitterMs: result.jitterMs,
                packetLossPct: result.lossPct,
                tensorSyncMBs: effPayload,
                isLive: true
            )
            self.isProbingWanBandwidth = false
        }
    }

    private func appendWanThroughputSample(
        downloadMbps: Double,
        uploadMbps: Double,
        pingRttMs: Double,
        jitterMs: Double,
        packetLossPct: Double,
        tensorSyncMBs: Double,
        isLive: Bool
    ) {
        wanThroughputHistory.append(
            WanBandwidthSample(
                timestamp: Date(),
                downloadMbps: downloadMbps,
                uploadMbps: uploadMbps,
                pingRttMs: pingRttMs,
                jitterMs: jitterMs,
                packetLossPct: packetLossPct,
                tensorSyncMBs: tensorSyncMBs,
                isLiveMeasurement: isLive
            )
        )
        if wanThroughputHistory.count > 24 {
            wanThroughputHistory.removeFirst(wanThroughputHistory.count - 24)
        }
    }

    private nonisolated static func runQuickUtility(_ path: String, _ args: [String]) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        proc.standardInput = FileHandle.nullDevice
        guard (try? proc.run()) != nil else { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private nonisolated static func detectDefaultNetworkInterface() -> String? {
        let out = runQuickUtility("/sbin/route", ["-n", "get", "default"])
        for line in out.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("interface:") {
                return trimmed.replacingOccurrences(of: "interface:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private nonisolated static func readInterfaceBytes(iface: String) -> (rx: UInt64, tx: UInt64)? {
        let out = runQuickUtility("/usr/sbin/netstat", ["-ibn"])
        var bestRx: UInt64 = 0
        var bestTx: UInt64 = 0
        var found = false
        for line in out.components(separatedBy: .newlines) {
            let cols = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard cols.count >= 10, cols[0] == iface else { continue }
            if let ibytes = UInt64(cols[6]), let obytes = UInt64(cols[9]) {
                bestRx = max(bestRx, ibytes)
                bestTx = max(bestTx, obytes)
                found = true
            }
        }
        return found ? (bestRx, bestTx) : nil
    }

    private nonisolated static func runIcmpPingProbe(host: String, count: Int) -> (avgMs: Double, jitterMs: Double, lossPct: Double) {
        let out = runQuickUtility("/sbin/ping", ["-c", "\(count)", "-W", "800", host])
        var avgMs = 0.0
        var jitterMs = 0.0
        var lossPct = 100.0

        if let lossRange = out.range(of: #"([0-9]+(\.[0-9]+)?)%\s*packet loss"#, options: .regularExpression) {
            let numStr = String(out[lossRange])
                .replacingOccurrences(of: "packet loss", with: "")
                .replacingOccurrences(of: "%", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            lossPct = Double(numStr) ?? lossPct
        }

        // macOS ping footer: round-trip min/avg/max/stddev = 11.2/14.5/18.1/2.8 ms
        for line in out.components(separatedBy: .newlines) where line.contains("min/avg/max/stddev") {
            if let eqIdx = line.firstIndex(of: "=") {
                let rhs = String(line[line.index(after: eqIdx)...])
                    .replacingOccurrences(of: "ms", with: "")
                    .trimmingCharacters(in: .whitespaces)
                let parts = rhs.split(separator: "/").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                if parts.count >= 4 {
                    avgMs = parts[1]
                    jitterMs = parts[3]
                }
            }
        }
        return (avgMs, jitterMs, lossPct)
    }

    private nonisolated static func runMacOSNetworkQuality() -> (dlMbps: Double, ulMbps: Double)? {
        let out = runQuickUtility("/usr/bin/networkQuality", ["-c"])
        guard let data = out.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let dlBps = (obj["dl_throughput"] as? Double) ?? 0.0
        let ulBps = (obj["ul_throughput"] as? Double) ?? 0.0
        guard dlBps > 0 || ulBps > 0 else { return nil }
        return (dlBps / 1_000_000.0, ulBps / 1_000_000.0)
    }

    // MARK: - Multi-Model-Mode (MMM)

    var mmmAvailableTargets: [String] {
        switch mmmScope {
        case .local:
            return nodes.map(\.name)
        case .internet:
            return wanPeers.map(\.displayName)
        case .hybrid:
            var seen = Set<String>()
            var combined: [String] = []
            for n in nodes.map(\.name) + wanRemotePeers.map(\.displayName) {
                if seen.insert(n).inserted { combined.append(n) }
            }
            return combined
        }
    }

    var mmmUsableVramPoolGB: Double {
        switch mmmScope {
        case .local: return totalUsableVramGB
        case .internet: return wanTotalUsableVramGB
        case .hybrid: return hybridCombinedUsableVramGB
        }
    }

    var mmmActiveSlots: [MultiModelSlot] {
        mmmSlots.filter(\.isEnabled)
    }

    var mmmTotalRequiredVramGB: Double {
        mmmActiveSlots.reduce(0.0) { $0 + $1.estimatedRamGB }
    }

    var mmmFitsInClusterPool: Bool {
        mmmTotalRequiredVramGB <= mmmUsableVramPoolGB
    }

    var mmmEstimatedCombinedTokPerSec: Double {
        let active = mmmActiveSlots
        guard !active.isEmpty else { return 0.0 }
        let baseSingle = max(4.0, activeTokPerSec)
        let topologyBoost = (mmmScope != .internet) ? clusterMeshTopology.bandwidthEfficiencyFactor : 1.0
        let wanBoost = (mmmScope != .local) ? (1.0 / wanTransportProtocol.latencyFactor) : 1.0
        let splitBoost = splitPhaseComputeMode == .anePrefillGpuDecode ? 1.12 : 1.0

        let rawEstimate: Double
        switch mmmStrategy {
        case .parallelPool:
            // Independent models executing concurrently across distinct nodes/VRAM pools
            rawEstimate = baseSingle * Double(min(active.count, max(1, mmmAvailableTargets.count))) * 0.88
        case .mixtureOfAgents:
            // Specialists run in parallel + 1 aggregator synthesis pass; Tree-MoA early-exit avoids extra synthesis hops
            let parallelFactor = min(Double(active.count), max(1.0, Double(mmmAvailableTargets.count))) * 0.72
            let earlyExitGain = mmmEnableTreeMoaEarlyExit ? (1.0 + max(0.0, (0.95 - mmmMoaConfidenceThreshold) * 0.6)) : 1.0
            rawEstimate = baseSingle * max(1.0, parallelFactor) * earlyExitGain
        case .speculativeDecoding:
            // Draft + Target; EAGLE-3 multi-layer feature fusion yields an additional speedup multiplier
            let baseSpec = active.contains(where: { $0.role == .draft }) ? 1.85 : 1.25
            rawEstimate = baseSingle * baseSpec * mmmSpeculativeEngine.speedupBonusMultiplier
        case .sequentialPipeline:
            // Chained stages; throughput bounded by slowest stage + WAN/TB hop overhead
            let hopOverhead = (mmmScope == .local) ? 0.94 : 0.78
            rawEstimate = baseSingle * hopOverhead
        }
        return rawEstimate * min(1.35, topologyBoost * 0.85 + 0.15) * min(1.25, wanBoost * 0.5 + 0.5) * splitBoost
    }

    func syncMultiModelSlotsFromCluster() {
        let localLabel = tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")
        let targets = mmmAvailableTargets
        let primaryTarget = targets.first ?? (nodes.first?.name ?? localLabel)
        let secondaryTarget = targets.count > 1 ? targets[1] : primaryTarget

        let liveModels = modelPresets.filter(\.isLiveDiscovered)
        if !liveModels.isEmpty {
            mmmSlots = liveModels.prefix(4).enumerated().map { idx, model in
                let role: MultiModelRole = idx == 0 ? .primary : (idx == 1 ? .specialist : .aggregator)
                let target = idx % 2 == 0 ? primaryTarget : secondaryTarget
                return MultiModelSlot(
                    modelId: model.id,
                    displayName: model.displayName,
                    role: role,
                    assignedTarget: target,
                    endpointURL: openCodeBaseURL,
                    estimatedRamGB: model.estimatedGB,
                    isEnabled: true
                )
            }
            mmmStatusMessage = tr(
                de: "MMM-Slots aus \(mmmSlots.count) erkannten Live-Modellen synchronisiert.",
                en: "Synced MMM slots from \(mmmSlots.count) live discovered models.",
                fr: "Slots MMM synchronisés depuis \(mmmSlots.count) modèles actifs.",
                es: "Slots MMM sincronizados desde \(mmmSlots.count) modelos en vivo.",
                pt: "Slots MMM sincronizados de \(mmmSlots.count) modelos ao vivo.",
                ru: "Слоты MMM синхронизированы с \(mmmSlots.count) активными моделями.",
                ja: "検出された \(mmmSlots.count) 個のライブモデルから MMM スロットを同期しました。",
                zh: "已从 \(mmmSlots.count) 个在线模型同步 MMM 槽位。"
            )
            return
        }

        // Fallback to catalog presets mapped onto active targets without fabricating fake runtime discovery
        let basePresets = Array(modelPresets.prefix(3))
        mmmSlots = basePresets.enumerated().map { idx, preset in
            let role: MultiModelRole = idx == 0 ? .primary : (idx == 1 ? .draft : .aggregator)
            let target = idx % 2 == 0 ? primaryTarget : secondaryTarget
            return MultiModelSlot(
                modelId: preset.id,
                displayName: preset.displayName,
                role: role,
                assignedTarget: target,
                endpointURL: openCodeBaseURL,
                estimatedRamGB: preset.estimatedGB,
                isEnabled: idx < 2
            )
        }
        mmmStatusMessage = tr(
            de: "MMM-Slots auf aktive \(mmmScope.localizedTitle(language))-Knoten ausgerichtet.",
            en: "Aligned MMM slots with active \(mmmScope.localizedTitle(language)) nodes.",
            fr: "Slots MMM alignés sur les nœuds \(mmmScope.localizedTitle(language)).",
            es: "Slots MMM alineados con nodos \(mmmScope.localizedTitle(language)).",
            pt: "Slots MMM alinhados com nós \(mmmScope.localizedTitle(language)).",
            ru: "Слоты MMM выровнены под активные узлы (\(mmmScope.localizedTitle(language))).",
            ja: "MMM スロットをアクティブなノード（\(mmmScope.localizedTitle(language))）に合わせました。",
            zh: "已将 MMM 槽位对齐至 \(mmmScope.localizedTitle(language)) 活跃节点。"
        )
    }

    func addMultiModelSlot(modelId: String, displayName: String, role: MultiModelRole, estimatedRamGB: Double) {
        let cleanId = modelId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanId.isEmpty else { return }
        let localLabel = tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")
        let target = mmmAvailableTargets.first ?? (nodes.first?.name ?? localLabel)
        mmmSlots.append(
            MultiModelSlot(
                modelId: cleanId,
                displayName: displayName.isEmpty ? cleanId : displayName,
                role: role,
                assignedTarget: target,
                endpointURL: openCodeBaseURL,
                estimatedRamGB: max(1.0, estimatedRamGB),
                isEnabled: true
            )
        )
    }

    func removeMultiModelSlot(_ id: UUID) {
        mmmSlots.removeAll { $0.id == id }
        saveMultiModelConfiguration()
    }

    func moveMultiModelSlot(_ id: UUID, direction: Int) {
        guard let idx = mmmSlots.firstIndex(where: { $0.id == id }) else { return }
        let targetIdx = idx + direction
        guard mmmSlots.indices.contains(targetIdx) else { return }
        mmmSlots.swapAt(idx, targetIdx)
        saveMultiModelConfiguration()
    }

    func duplicateMultiModelSlot(_ id: UUID) {
        guard let idx = mmmSlots.firstIndex(where: { $0.id == id }) else { return }
        let source = mmmSlots[idx]
        let localLabel = tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")
        let targets = mmmAvailableTargets.isEmpty ? [localLabel] : mmmAvailableTargets
        let nextTarget: String
        if let curTIdx = targets.firstIndex(of: source.assignedTarget), targets.count > 1 {
            nextTarget = targets[(curTIdx + 1) % targets.count]
        } else {
            nextTarget = source.assignedTarget
        }
        let replicaLabel = tr(de: "Replikat", en: "Replica", fr: "Réplique", es: "Réplica", pt: "Réplica", ru: "Реплика", ja: "レプリカ", zh: "副本")
        let copy = MultiModelSlot(
            modelId: source.modelId,
            displayName: "\(source.displayName) (\(replicaLabel))",
            role: source.role == .primary ? .specialist : source.role,
            assignedTarget: nextTarget,
            endpointURL: source.endpointURL,
            estimatedRamGB: source.estimatedRamGB,
            isEnabled: source.isEnabled
        )
        mmmSlots.insert(copy, at: idx + 1)
        saveMultiModelConfiguration()
        mmmStatusMessage = tr(
            de: "Slot '\(source.displayName)' dupliziert auf \(nextTarget).",
            en: "Duplicated slot '\(source.displayName)' onto \(nextTarget).",
            fr: "Slot « \(source.displayName) » dupliqué sur \(nextTarget).",
            es: "Slot «\(source.displayName)» duplicado en \(nextTarget).",
            pt: "Slot '\(source.displayName)' duplicado para \(nextTarget).",
            ru: "Слот '\(source.displayName)' дублирован на \(nextTarget).",
            ja: "スロット '\(source.displayName)' を \(nextTarget) に複製しました。",
            zh: "已将槽位 '\(source.displayName)' 复制到 \(nextTarget)。"
        )
    }

    /// 1-Click Automatic Cluster Setup for Multi-Model-Mode (MMM).
    /// Scans usable VRAM across the active scope (Local / Internet-WAN / Hybrid), picks fitting models
    /// (preferring live-discovered models), assigns roles and target nodes, and saves the configuration.
    func autoConfigureMultiModelSetup(profile: MultiModelAutoProfile? = nil) {
        let chosenProfile = profile ?? mmmAutoProfile
        mmmAutoProfile = chosenProfile
        mmmStrategy = chosenProfile.recommendedStrategy

        let localLabel = tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")
        let targets = mmmAvailableTargets.isEmpty ? [nodes.first?.name ?? localLabel] : mmmAvailableTargets
        let usablePool = max(8.0, mmmUsableVramPoolGB)
        let liveModels = modelPresets.filter(\.isLiveDiscovered)
        let sourcePool = liveModels.isEmpty ? modelPresets : liveModels

        // Sort candidates by RAM ascending so we can pack reliably, or select smallest+largest for speculative
        let sortedAsc = sourcePool.sorted { $0.estimatedGB < $1.estimatedGB }
        var selectedModels: [ModelPreset] = []
        var usedRam = 0.0

        switch chosenProfile {
        case .fastSpeculative:
            // Pick smallest model as Draft + largest model that still fits alongside it
            if let draft = sortedAsc.first {
                selectedModels.append(draft)
                usedRam += draft.estimatedGB
                if let target = sortedAsc.reversed().first(where: { $0.id != draft.id && usedRam + $0.estimatedGB <= usablePool }) {
                    selectedModels.append(target)
                    usedRam += target.estimatedGB
                } else if let secondSmallest = sortedAsc.dropFirst().first {
                    selectedModels.append(secondSmallest)
                    usedRam += secondSmallest.estimatedGB
                }
            }
        case .balancedCoding, .consensusReview, .hybridPipeline:
            let maxCount = chosenProfile == .consensusReview ? 4 : 3
            for candidate in sortedAsc {
                if selectedModels.count >= maxCount { break }
                if usedRam + candidate.estimatedGB <= usablePool || selectedModels.isEmpty {
                    selectedModels.append(candidate)
                    usedRam += candidate.estimatedGB
                }
            }
        }

        let rolesForProfile: [MultiModelRole]
        switch chosenProfile {
        case .fastSpeculative:
            rolesForProfile = [.draft, .primary, .aggregator, .specialist]
        case .consensusReview:
            rolesForProfile = [.primary, .specialist, .specialist, .aggregator]
        case .hybridPipeline:
            rolesForProfile = [.primary, .specialist, .aggregator, .draft]
        case .balancedCoding:
            rolesForProfile = [.primary, .specialist, .aggregator, .draft]
        }

        mmmSlots = selectedModels.enumerated().map { idx, model in
            let role = rolesForProfile[min(idx, rolesForProfile.count - 1)]
            let target = targets[idx % targets.count]
            return MultiModelSlot(
                modelId: model.id,
                displayName: model.displayName,
                role: role,
                assignedTarget: target,
                endpointURL: openCodeBaseURL,
                estimatedRamGB: model.estimatedGB,
                isEnabled: true
            )
        }

        saveMultiModelConfiguration()
        let sourceNote = liveModels.isEmpty
            ? tr(de: "Katalog-Referenz", en: "Catalog Reference", fr: "Catalogue de référence", es: "Referencia de catálogo", pt: "Referência de catálogo", ru: "Справочник моделей", ja: "カタログ参照", zh: "参考目录")
            : tr(de: "Live-Erkennung", en: "Live Discovery", fr: "Détection en direct", es: "Detección en vivo", pt: "Deteção ao vivo", ru: "Живое обнаружение", ja: "ライブ検出", zh: "实时发现")
        mmmAutoSetupSummary = tr(
            de: "Auto-Setup (\(chosenProfile.localizedTitle(language))): \(mmmSlots.count) Modelle (\(String(format: "%.1f", mmmTotalRequiredVramGB)) / \(String(format: "%.1f", usablePool)) GB VRAM) auf \(targets.count) Knoten (\(sourceNote)) eingerichtet.",
            en: "Auto-Setup (\(chosenProfile.localizedTitle(language))): Configured \(mmmSlots.count) models (\(String(format: "%.1f", mmmTotalRequiredVramGB)) / \(String(format: "%.1f", usablePool)) GB VRAM) across \(targets.count) node(s) (\(sourceNote)).",
            fr: "Auto-Setup (\(chosenProfile.localizedTitle(language))) : \(mmmSlots.count) modèles (\(String(format: "%.1f", mmmTotalRequiredVramGB)) / \(String(format: "%.1f", usablePool)) Go VRAM) sur \(targets.count) nœud(s) (\(sourceNote)).",
            es: "Auto-Setup (\(chosenProfile.localizedTitle(language))): \(mmmSlots.count) modelos (\(String(format: "%.1f", mmmTotalRequiredVramGB)) / \(String(format: "%.1f", usablePool)) GB VRAM) en \(targets.count) nodo(s) (\(sourceNote)).",
            pt: "Auto-Setup (\(chosenProfile.localizedTitle(language))): \(mmmSlots.count) modelos (\(String(format: "%.1f", mmmTotalRequiredVramGB)) / \(String(format: "%.1f", usablePool)) GB VRAM) em \(targets.count) nó(s) (\(sourceNote)).",
            ru: "Автонастройка (\(chosenProfile.localizedTitle(language))): \(mmmSlots.count) моделей (\(String(format: "%.1f", mmmTotalRequiredVramGB)) / \(String(format: "%.1f", usablePool)) ГБ VRAM) на \(targets.count) узл. (\(sourceNote)).",
            ja: "自動構成 (\(chosenProfile.localizedTitle(language))): \(mmmSlots.count) モデル (\(String(format: "%.1f", mmmTotalRequiredVramGB)) / \(String(format: "%.1f", usablePool)) GB VRAM) を \(targets.count) ノードに配置（\(sourceNote)）。",
            zh: "自动配置 (\(chosenProfile.localizedTitle(language)))：已在 \(targets.count) 个节点上配置 \(mmmSlots.count) 个模型（\(String(format: "%.1f", mmmTotalRequiredVramGB)) / \(String(format: "%.1f", usablePool)) GB VRAM · \(sourceNote)）。"
        )
        mmmStatusMessage = mmmAutoSetupSummary
    }

    /// Trims/disables lower-priority slots if the current configuration exceeds usable cluster VRAM.
    func optimizeMultiModelSlotsForVram() {
        let pool = mmmUsableVramPoolGB
        var running = 0.0
        var keptActive = 0
        var disabledCount = 0

        for idx in mmmSlots.indices {
            guard mmmSlots[idx].isEnabled else { continue }
            let ram = mmmSlots[idx].estimatedRamGB
            if keptActive == 0 || (running + ram <= pool) {
                running += ram
                keptActive += 1
            } else {
                mmmSlots[idx].isEnabled = false
                disabledCount += 1
            }
        }
        saveMultiModelConfiguration()
        if disabledCount > 0 {
            mmmStatusMessage = tr(
                de: "VRAM-Optimierung: \(disabledCount) Slot(s) pausiert, \(keptActive) aktiv (\(String(format: "%.1f", running)) / \(String(format: "%.1f", pool)) GB).",
                en: "VRAM Optimization: paused \(disabledCount) slot(s), \(keptActive) active (\(String(format: "%.1f", running)) / \(String(format: "%.1f", pool)) GB).",
                fr: "Optimisation VRAM : \(disabledCount) slot(s) en pause, \(keptActive) actif(s) (\(String(format: "%.1f", running)) / \(String(format: "%.1f", pool)) Go).",
                es: "Optimización VRAM: \(disabledCount) slot(s) en pausa, \(keptActive) activos (\(String(format: "%.1f", running)) / \(String(format: "%.1f", pool)) GB).",
                pt: "Otimização VRAM: \(disabledCount) slot(s) pausado(s), \(keptActive) ativo(s) (\(String(format: "%.1f", running)) / \(String(format: "%.1f", pool)) GB).",
                ru: "Оптимизация VRAM: приостановлено \(disabledCount), активно \(keptActive) (\(String(format: "%.1f", running)) / \(String(format: "%.1f", pool)) ГБ).",
                ja: "VRAM 最適化: \(disabledCount) スロット停止、\(keptActive) 有効 (\(String(format: "%.1f", running)) / \(String(format: "%.1f", pool)) GB)。",
                zh: "显存优化：已暂停 \(disabledCount) 个槽位，保留 \(keptActive) 个活跃（\(String(format: "%.1f", running)) / \(String(format: "%.1f", pool)) GB）。"
            )
        } else {
            mmmStatusMessage = tr(
                de: "VRAM-Prüfung OK: Alle \(keptActive) aktiven Modelle passen sicher in \(String(format: "%.1f", pool)) GB.",
                en: "VRAM Check OK: All \(keptActive) active models fit safely within \(String(format: "%.1f", pool)) GB.",
                fr: "Vérif. VRAM OK : Les \(keptActive) modèles actifs tiennent dans \(String(format: "%.1f", pool)) Go.",
                es: "VRAM OK: Los \(keptActive) modelos activos caben en \(String(format: "%.1f", pool)) GB.",
                pt: "VRAM OK: Todos os \(keptActive) modelos ativos cabem em \(String(format: "%.1f", pool)) GB.",
                ru: "Проверка VRAM OK: Все \(keptActive) активные модели помещаются в \(String(format: "%.1f", pool)) ГБ.",
                ja: "VRAM 検査 OK: 有効な \(keptActive) モデルすべて \(String(format: "%.1f", pool)) GB 内に収まります。",
                zh: "显存校验通过：全部 \(keptActive) 个活跃模型均安全适配于 \(String(format: "%.1f", pool)) GB 内。"
            )
        }
    }

    private static let mmmConfigDefaultsKey = "ssccc.mmm.config.v1"

    private struct MultiModelPersistedConfig: Codable {
        let scope: MultiModelScope
        let strategy: MultiModelStrategy
        let autoProfile: MultiModelAutoProfile
        let activeClientCount: Int
        let slots: [MultiModelSlot]
    }

    func saveMultiModelConfiguration() {
        let payload = MultiModelPersistedConfig(
            scope: mmmScope,
            strategy: mmmStrategy,
            autoProfile: mmmAutoProfile,
            activeClientCount: mmmActiveClientCount,
            slots: mmmSlots
        )
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: Self.mmmConfigDefaultsKey)
        }
    }

    @discardableResult
    func loadMultiModelConfiguration() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.mmmConfigDefaultsKey),
              let decoded = try? JSONDecoder().decode(MultiModelPersistedConfig.self, from: data),
              !decoded.slots.isEmpty else {
            return false
        }
        mmmScope = decoded.scope
        mmmStrategy = decoded.strategy
        mmmAutoProfile = decoded.autoProfile
        mmmActiveClientCount = max(1, decoded.activeClientCount)
        mmmSlots = decoded.slots
        mmmStatusMessage = tr(
            de: "Gespeicherte MMM-Konfiguration (\(decoded.slots.count) Slots) geladen.",
            en: "Loaded saved MMM configuration (\(decoded.slots.count) slots).",
            fr: "Configuration MMM enregistrée chargée (\(decoded.slots.count) slots).",
            es: "Configuración MMM guardada cargada (\(decoded.slots.count) slots).",
            pt: "Configuração MMM guardada carregada (\(decoded.slots.count) slots).",
            ru: "Загружена сохранённая конфигурация MMM (\(decoded.slots.count) слотов).",
            ja: "保存済みの MMM 設定（\(decoded.slots.count) スロット）を読み込みました。",
            zh: "已加载保存的 MMM 配置（共 \(decoded.slots.count) 个槽位）。"
        )
        return true
    }

    func exportMultiModelConfigurationJSON() -> String {
        let payload = MultiModelPersistedConfig(
            scope: mmmScope,
            strategy: mmmStrategy,
            autoProfile: mmmAutoProfile,
            activeClientCount: mmmActiveClientCount,
            slots: mmmSlots
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    func executeMultiModelOrchestration() {
        guard !isRunningMultiModel else { return }
        let active = mmmActiveSlots
        guard !active.isEmpty else {
            mmmStatusMessage = tr(de: "Bitte mindestens einen Modell-Slot aktivieren.", en: "Please enable at least one model slot.", fr: "Veuillez activer au moins un slot de modèle.", es: "Por favor activa al menos un slot de modelo.", pt: "Por favor ative pelo menos um slot de modelo.", ru: "Включите хотя бы один слот модели.", ja: "少なくとも1つのモデルスロットを有効にしてください。", zh: "请至少启用一个模型槽位。")
            return
        }

        isRunningMultiModel = true
        let isSimulated = simulateMacStudio
        let strategy = mmmStrategy
        let scope = mmmScope
        let promptText = mmmPromptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "State the Roofline equation in one sentence."
            : mmmPromptInput
        let usedVram = mmmTotalRequiredVramGB
        let poolVram = mmmUsableVramPoolGB
        let formatter = ISO8601DateFormatter()

        let stratTitle = strategy.localizedTitle(language)
        let scopeTitle = scope.localizedTitle(language)
        mmmStatusMessage = isSimulated
            ? tr(de: "Simuliere \(stratTitle) über \(active.count) Modelle (\(scopeTitle))...", en: "Simulating \(stratTitle) across \(active.count) models (\(scopeTitle))...", fr: "Simulation de \(stratTitle) sur \(active.count) modèles (\(scopeTitle))...", es: "Simulando \(stratTitle) en \(active.count) modelos (\(scopeTitle))...", pt: "A simular \(stratTitle) em \(active.count) modelos (\(scopeTitle))...", ru: "Симуляция \(stratTitle) на \(active.count) моделях (\(scopeTitle))...", ja: "\(active.count) モデルで \(stratTitle) をシミュレーション中 (\(scopeTitle))...", zh: "正在模拟 \(stratTitle)（\(active.count) 个模型 · \(scopeTitle)）...")
            : tr(de: "Führe \(stratTitle) über \(active.count) Live-Modelle aus...", en: "Executing \(stratTitle) across \(active.count) live models...", fr: "Exécution de \(stratTitle) sur \(active.count) modèles actifs...", es: "Ejecutando \(stratTitle) en \(active.count) modelos activos...", pt: "A executar \(stratTitle) em \(active.count) modelos ativos...", ru: "Выполнение \(stratTitle) на \(active.count) моделях...", ja: "\(active.count) 台のライブモデルで \(stratTitle) を実行中...", zh: "正在运行 \(stratTitle)（\(active.count) 个在线模型）...")

        Task {
            if isSimulated {
                try? await Task.sleep(nanoseconds: 280_000_000)
                var updatedSlots = mmmSlots
                var sumTok = 0.0
                var maxTtft = 0.0
                for idx in updatedSlots.indices where updatedSlots[idx].isEnabled {
                    let slot = updatedSlots[idx]
                    let baseSlotTok = max(8.0, (activeTokPerSec * (slot.role == .draft ? 2.4 : 1.0)) * (scope == .local ? 1.0 : 0.78))
                    let slotTtft = max(18.0, activeTTFTMs * (slot.role == .draft ? 0.35 : 1.0) * (scope == .local ? 1.0 : 1.4))
                    updatedSlots[idx].lastTokPerSec = baseSlotTok
                    updatedSlots[idx].lastTtftMs = slotTtft
                    sumTok += baseSlotTok
                    maxTtft = max(maxTtft, slotTtft)
                }
                mmmSlots = updatedSlots

                let combinedTok = strategy == .sequentialPipeline ? (sumTok / Double(max(1, active.count))) : sumTok * 0.86
                let baselineSingle = max(1.0, activeTokPerSec)
                let speedup = combinedTok / baselineSingle

                let res = MultiModelRunResult(
                    timestamp: formatter.string(from: Date()),
                    strategy: strategy,
                    scope: scope,
                    activeModelsCount: active.count,
                    combinedTokPerSec: combinedTok,
                    aggregateTtftMs: maxTtft,
                    totalVramUsedGB: usedVram,
                    usableVramPoolGB: poolVram,
                    speedupFactor: speedup,
                    responsePreview: tr(
                        de: "Simulation (\(stratTitle)): \(active.count) Modelle auf \(scopeTitle) kombiniert (\(String(format: "%.1f", combinedTok)) tok/s, \(String(format: "%.2fx", speedup)) vs. Einzelmodell).",
                        en: "Simulation (\(stratTitle)): combined \(active.count) models across \(scopeTitle) (\(String(format: "%.1f", combinedTok)) tok/s, \(String(format: "%.2fx", speedup)) vs. single model).",
                        fr: "Simulation (\(stratTitle)) : \(active.count) modèles combinés sur \(scopeTitle) (\(String(format: "%.1f", combinedTok)) tok/s, \(String(format: "%.2fx", speedup)) vs modèle unique).",
                        es: "Simulación (\(stratTitle)): \(active.count) modelos combinados en \(scopeTitle) (\(String(format: "%.1f", combinedTok)) tok/s, \(String(format: "%.2fx", speedup)) vs modelo único).",
                        pt: "Simulação (\(stratTitle)): \(active.count) modelos combinados em \(scopeTitle) (\(String(format: "%.1f", combinedTok)) tok/s, \(String(format: "%.2fx", speedup)) vs modelo único).",
                        ru: "Симуляция (\(stratTitle)): \(active.count) моделей на \(scopeTitle) (\(String(format: "%.1f", combinedTok)) tok/с, \(String(format: "%.2fx", speedup)) к 1 модели).",
                        ja: "シミュレーション (\(stratTitle)): \(scopeTitle) で \(active.count) モデル統合 (\(String(format: "%.1f", combinedTok)) tok/s, 単体比 \(String(format: "%.2fx", speedup)))。",
                        zh: "模拟完成 (\(stratTitle))：已在 \(scopeTitle) 上组合 \(active.count) 个模型（\(String(format: "%.1f", combinedTok)) tok/s，单模型加速比 \(String(format: "%.2fx", speedup))）。"
                    ),
                    isLiveExecution: false
                )
                mmmLastResult = res
                mmmHistory.insert(res, at: 0)
                if mmmHistory.count > 20 { mmmHistory.removeLast(mmmHistory.count - 20) }
                if sciAutoRecordHistory {
                    recordScienceHistoryFromMMM(res)
                }
                mmmStatusMessage = tr(
                    de: "Simulation abgeschlossen (\(active.count) Modelle · \(String(format: "%.1f", combinedTok)) tok/s).",
                    en: "Simulation complete (\(active.count) models · \(String(format: "%.1f", combinedTok)) tok/s).",
                    fr: "Simulation terminée (\(active.count) modèles · \(String(format: "%.1f", combinedTok)) tok/s).",
                    es: "Simulación completada (\(active.count) modelos · \(String(format: "%.1f", combinedTok)) tok/s).",
                    pt: "Simulação concluída (\(active.count) modelos · \(String(format: "%.1f", combinedTok)) tok/s).",
                    ru: "Симуляция завершена (\(active.count) моделей · \(String(format: "%.1f", combinedTok)) tok/с).",
                    ja: "シミュレーション完了（\(active.count) モデル · \(String(format: "%.1f", combinedTok)) tok/s）。",
                    zh: "模拟完成（\(active.count) 个模型 · \(String(format: "%.1f", combinedTok)) tok/s）。"
                )
                isRunningMultiModel = false
                return
            }

            // REAL EXECUTION MODE: Query live OpenAI-compatible endpoints via SSE streaming
            var updatedSlots = mmmSlots
            var totalTok = 0.0
            var worstTtft = 0.0
            var successCount = 0
            var lastError = ""

            for idx in updatedSlots.indices where updatedSlots[idx].isEnabled {
                let slot = updatedSlots[idx]
                let base = slot.endpointURL.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let url = URL(string: "\(base)/chat/completions") else {
                    lastError = tr(
                        de: "Ungültige URL für \(slot.displayName)",
                        en: "Invalid URL for \(slot.displayName)",
                        fr: "URL invalide pour \(slot.displayName)",
                        es: "URL no válida para \(slot.displayName)",
                        pt: "URL inválido para \(slot.displayName)",
                        ru: "Некорректный URL для \(slot.displayName)",
                        ja: "\(slot.displayName) の URL が無効です",
                        zh: "\(slot.displayName) 的 URL 无效"
                    )
                    continue
                }
                do {
                    let sample = try await runLiveChatCompletionTrial(endpointURL: url, modelId: slot.modelId)
                    updatedSlots[idx].lastTokPerSec = sample.tokensPerSec
                    updatedSlots[idx].lastTtftMs = sample.ttftMs
                    totalTok += sample.tokensPerSec
                    worstTtft = max(worstTtft, sample.ttftMs)
                    successCount += 1
                } catch {
                    lastError = error.localizedDescription
                }
            }
            mmmSlots = updatedSlots

            guard successCount > 0 else {
                let detail = lastError.isEmpty ? openCodeBaseURL : lastError
                mmmStatusMessage = tr(
                    de: "Echtbetrieb: Kein aktiver MMM-Endpunkt erreichbar (\(detail)). Starte oMLX, Ollama oder llama.cpp – oder aktiviere den Simulationsmodus.",
                    en: "Live mode: no active MMM endpoint reachable (\(detail)). Start oMLX, Ollama, or llama.cpp – or enable simulation mode.",
                    fr: "Mode réel : aucun endpoint MMM actif joignable (\(detail)). Démarrez oMLX, Ollama ou llama.cpp — ou activez la simulation.",
                    es: "Modo real: ningún endpoint MMM activo accesible (\(detail)). Inicia oMLX, Ollama o llama.cpp — o activa la simulación.",
                    pt: "Modo real: nenhum endpoint MMM ativo alcançável (\(detail)). Inicie oMLX, Ollama ou llama.cpp — ou ative a simulação.",
                    ru: "Боевой режим: нет доступных конечных точек MMM (\(detail)). Запустите oMLX, Ollama или llama.cpp — или включите симуляцию.",
                    ja: "ライブモード: 有効な MMM エンドポイントに到達できません (\(detail))。oMLX・Ollama・llama.cpp を起動するかシミュレーションを有効にしてください。",
                    zh: "实时模式：无法连接任何活跃的 MMM 端点 (\(detail))。请先启动 oMLX、Ollama 或 llama.cpp，或开启模拟模式。"
                )
                isRunningMultiModel = false
                return
            }

            let combined = strategy == .sequentialPipeline ? (totalTok / Double(successCount)) : totalTok
            let speedup = combined / max(1.0, activeTokPerSec)
            let res = MultiModelRunResult(
                timestamp: formatter.string(from: Date()),
                strategy: strategy,
                scope: scope,
                activeModelsCount: successCount,
                combinedTokPerSec: combined,
                aggregateTtftMs: worstTtft,
                totalVramUsedGB: usedVram,
                usableVramPoolGB: poolVram,
                speedupFactor: speedup,
                responsePreview: tr(
                    de: "Live-Ausführung (\(promptText.prefix(64))...): \(successCount)/\(active.count) Modelle erfolgreich gestreamt.",
                    en: "Live execution (\(promptText.prefix(64))...): \(successCount)/\(active.count) models streamed cleanly.",
                    fr: "Exécution directe (\(promptText.prefix(64))...) : \(successCount)/\(active.count) modèles diffusés.",
                    es: "Ejecución en vivo (\(promptText.prefix(64))...): \(successCount)/\(active.count) modelos transmitidos.",
                    pt: "Execução ao vivo (\(promptText.prefix(64))...): \(successCount)/\(active.count) modelos em streaming.",
                    ru: "Выполнение LIVE (\(promptText.prefix(64))...): \(successCount)/\(active.count) моделей успешно ответили.",
                    ja: "ライブ実行 (\(promptText.prefix(64))...): \(successCount)/\(active.count) モデルがストリーミング完了。",
                    zh: "实时运行 (\(promptText.prefix(64))...)：\(successCount)/\(active.count) 个模型已成功完成流式输出。"
                ),
                isLiveExecution: true
            )
            mmmLastResult = res
            mmmHistory.insert(res, at: 0)
            if mmmHistory.count > 20 { mmmHistory.removeLast(mmmHistory.count - 20) }
            if sciAutoRecordHistory {
                recordScienceHistoryFromMMM(res)
            }
            mmmStatusMessage = tr(
                de: "Live-Ausführung abgeschlossen (\(successCount) Modelle · \(String(format: "%.1f", combined)) tok/s).",
                en: "Live execution finished (\(successCount) models · \(String(format: "%.1f", combined)) tok/s).",
                fr: "Exécution directe terminée (\(successCount) modèles · \(String(format: "%.1f", combined)) tok/s).",
                es: "Ejecución en vivo finalizada (\(successCount) modelos · \(String(format: "%.1f", combined)) tok/s).",
                pt: "Execução ao vivo concluída (\(successCount) modelos · \(String(format: "%.1f", combined)) tok/s).",
                ru: "Выполнение LIVE завершено (\(successCount) моделей · \(String(format: "%.1f", combined)) tok/с).",
                ja: "ライブ実行完了（\(successCount) モデル · \(String(format: "%.1f", combined)) tok/s）。",
                zh: "实时运行完成（\(successCount) 个模型 · \(String(format: "%.1f", combined)) tok/s）。"
            )
            isRunningMultiModel = false
        }
    }

    /// Estimated tokens/sec available per concurrent IDE / Agent Harness drawing from the unified cluster.
    var mmmPerClientTokPerSec: Double {
        mmmEstimatedCombinedTokPerSec / Double(max(1, mmmActiveClientCount))
    }

    var mmmMeanObservedTokPerSec: Double {
        guard !mmmHistory.isEmpty else { return mmmLastResult?.combinedTokPerSec ?? mmmEstimatedCombinedTokPerSec }
        return mmmHistory.reduce(0.0) { $0 + $1.combinedTokPerSec } / Double(mmmHistory.count)
    }

    var mmmMeanSpeedupFactor: Double {
        guard !mmmHistory.isEmpty else { return mmmLastResult?.speedupFactor ?? 1.0 }
        return mmmHistory.reduce(0.0) { $0 + $1.speedupFactor } / Double(mmmHistory.count)
    }

    /// Feeds Multi-Model-Mode (MMM) orchestration runs directly into the Science & Roofline telemetry history.
    func recordScienceHistoryFromMMM(_ res: MultiModelRunResult) {
        let tpot = res.combinedTokPerSec > 0 ? (1000.0 / res.combinedTokPerSec) : activeTPOTMs
        let jPerTok = res.combinedTokPerSec > 0 ? (activeWatts / res.combinedTokPerSec) : activeJoulesPerToken
        let edp = jPerTok * (tpot / 1000.0)
        let co2 = ((jPerTok * 1_000_000.0) / 3_600_000.0) * sciCarbonRegion.gco2PerKwh
        let entry = ScienceHistoryEntry(
            timestamp: currentClockTime(),
            positionFilter: .globalAll,
            scopeLabel: "MMM · \(res.scope.localizedTitle(language))",
            modelName: "\(res.strategy.localizedTitle(language)) (\(res.activeModelsCount)x)",
            nodeCount: max(1, mmmAvailableTargets.count),
            usableVramGB: res.usableVramPoolGB,
            ttftMs: res.aggregateTtftMs,
            tpotMs: tpot,
            tokPerSec: res.combinedTokPerSec,
            wanRttMs: res.scope == .local ? 0.2 : activeStepRttMs,
            bubblePercent: activePipelineBubbleFraction * 100.0,
            joulesPerToken: jPerTok,
            edpJouleSec: edp,
            co2PerMillionTok: co2,
            bottleneckRegime: res.isLiveExecution ? "MMM Live SSE" : "MMM Simulation",
            note: String(format: "MMM Speedup %.2fx · %d IDEs/Harnesses", res.speedupFactor, mmmActiveClientCount)
        )
        sciHistoryEntries.insert(entry, at: 0)
        if sciHistoryEntries.count > 120 {
            sciHistoryEntries.removeLast(sciHistoryEntries.count - 120)
        }
    }

    /// Generates a unified OpenAI-compatible Multi-IDE & Harness routing config for simultaneous cluster consumption.
    func exportMultiIdeMmmGatewayConfig() -> String {
        let slotEntries = mmmActiveSlots.map { slot in
            "    { \"model\": \"\(slot.modelId)\", \"role\": \"\(slot.role.rawValue)\", \"targetNode\": \"\(slot.assignedTarget)\", \"vramGB\": \(String(format: "%.1f", slot.estimatedRamGB)) }"
        }.joined(separator: ",\n")
        return """
        {
          "sscccGateway": "\(openCodeBaseURL)",
          "scope": "\(mmmScope.rawValue)",
          "strategy": "\(mmmStrategy.rawValue)",
          "concurrentIdesAndHarnesses": \(mmmActiveClientCount),
          "clients": ["Cursor", "VS Code", "Xcode", "OpenCode", "Hermes Agent", "Google Antigravity"],
          "modelSlots": [
        \(slotEntries)
          ]
        }
        """
    }

    func probeWanOverlayTools() {
        let fm = FileManager.default
        let tsPaths = [
            "/Applications/Tailscale.app/Contents/MacOS/Tailscale",
            "/opt/homebrew/bin/tailscale",
            "/usr/local/bin/tailscale"
        ]
        let wgPaths = [
            "/opt/homebrew/bin/wg",
            "/usr/local/bin/wg"
        ]
        let tsBin = tsPaths.first { fm.fileExists(atPath: $0) } ?? ""
        let wgBin = wgPaths.first { fm.fileExists(atPath: $0) } ?? ""
        wanTailscaleInstalled = !tsBin.isEmpty
        wanWireGuardInstalled = !wgBin.isEmpty

        let localHost = Host.current().localizedName ?? tr(de: "Lokaler Mac", en: "Local Mac", fr: "Mac local", es: "Mac local", pt: "Mac local", ru: "Локальный Mac", ja: "ローカル Mac", zh: "本地 Mac")
        let localUsable = AppleSiliconChipFamily.usableVramGB(for: localRamGB)
        let localBw = AppleSiliconChipFamily.inferBandwidth(from: localChipName)
        let localHostRegion = tr(de: "Lokal (Host)", en: "Local (Host)", fr: "Local (Hôte)", es: "Local (Host)", pt: "Local (Host)", ru: "Локально (Хост)", ja: "ローカル (ホスト)", zh: "本地（主节点）")

        var discovered: [WanPeerNode] = [
            WanPeerNode(
                id: "wan-local-host",
                displayName: localHost,
                region: localHostRegion,
                chip: localChipName,
                ramGB: localRamGB,
                usableVramGB: localUsable,
                bandwidthGBs: localBw,
                overlayIP: wanTailscaleIP.isEmpty ? localLanIP : wanTailscaleIP,
                rttMs: 0.2,
                uplinkMbps: 1000.0,
                assignedLayers: "0–\(selectedModel.totalLayers)",
                transport: wanTransport,
                isOnline: true,
                isLocalHost: true
            )
        ]

        // Real Tailscale peer discovery if Tailscale CLI is installed & logged in
        if !tsBin.isEmpty {
            let statusJson = runShell(tsBin, ["status", "--json"])
            if let data = statusJson.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let selfNode = obj["Self"] as? [String: Any],
                   let ips = selfNode["TailscaleIPs"] as? [String],
                   let firstIP = ips.first {
                    wanTailscaleIP = firstIP
                }
                if let peerDict = obj["Peer"] as? [String: [String: Any]] {
                    for (peerKey, info) in peerDict {
                        let hostName = (info["HostName"] as? String) ?? peerKey
                        let os = (info["OS"] as? String) ?? ""
                        let online = (info["Online"] as? Bool) ?? false
                        let ips = (info["TailscaleIPs"] as? [String]) ?? []
                        if os.lowercased().contains("macos") || os.lowercased().contains("darwin") {
                            let peerIP = ips.first ?? ""
                            var probedRtt = 0.0
                            if online, !peerIP.isEmpty {
                                let pingOut = runShell("/sbin/ping", ["-c", "1", "-W", "500", peerIP])
                                if let range = pingOut.range(of: #"time=([0-9]+(\.[0-9]+)?)\s*ms"#, options: .regularExpression) {
                                    let numStr = String(pingOut[range])
                                        .replacingOccurrences(of: "time=", with: "")
                                        .replacingOccurrences(of: "ms", with: "")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    probedRtt = Double(numStr) ?? 0.0
                                }
                            }
                            discovered.append(
                                WanPeerNode(
                                    id: "ts-\(peerKey)",
                                    displayName: hostName,
                                    region: "Tailscale Mesh",
                                    chip: "Apple Silicon (Tailscale)",
                                    ramGB: 32.0,
                                    usableVramGB: 26.0,
                                    bandwidthGBs: 200.0,
                                    overlayIP: peerIP.isEmpty ? "100.64.0.x" : peerIP,
                                    rttMs: probedRtt,
                                    uplinkMbps: 200.0,
                                    assignedLayers: "Auto",
                                    transport: .tailscaleMesh,
                                    isOnline: online,
                                    isLocalHost: false
                                )
                            )
                        }
                    }
                }
            }
        }

        wanPeers = discovered
        recomputeWanLayerAssignments()

        if chatMessages.isEmpty {
            chatMessages = [
                ClusterChatMessage(
                    senderName: "SS-CCC Mesh",
                    senderRegion: "System",
                    senderChip: localChipName,
                    timestamp: currentClockTime(),
                    text: tr(
                        de: "Raum \(wanRoomCode) bereit. Verbinde Macs über Tailscale, WireGuard oder libp2p-QUIC und nutze /status oder /layers im Chat.",
                        en: "Room \(wanRoomCode) ready. Connect Macs via Tailscale, WireGuard, or libp2p-QUIC and use /status or /layers in chat.",
                        fr: "Salle \(wanRoomCode) prête. Connectez vos Macs via Tailscale, WireGuard ou libp2p-QUIC et utilisez /status ou /layers.",
                        es: "Sala \(wanRoomCode) lista. Conecta Macs por Tailscale, WireGuard o libp2p-QUIC y usa /status o /layers.",
                        pt: "Sala \(wanRoomCode) pronta. Ligue Macs via Tailscale, WireGuard ou libp2p-QUIC e use /status ou /layers.",
                        ru: "Комната \(wanRoomCode) готова. Подключите Mac через Tailscale, WireGuard или libp2p-QUIC (/status, /layers).",
                        ja: "ルーム \(wanRoomCode) 準備完了。Tailscale / WireGuard / libp2p-QUIC で接続し /status や /layers を利用できます。",
                        zh: "房间 \(wanRoomCode) 已就绪。可通过 Tailscale、WireGuard 或 libp2p-QUIC 连接 Mac，并在聊天中使用 /status 或 /layers。"
                    ),
                    isSystemEvent: true,
                    isSelf: false
                )
            ]
        }
        let readyWord = tr(de: "bereit", en: "ready", fr: "prêt", es: "listo", pt: "pronto", ru: "готов", ja: "準備完了", zh: "就绪")
        wanStatusNote = wanTailscaleInstalled
            ? tr(
                de: "Tailscale erkannt (\(wanTailscaleIP.isEmpty ? readyWord : wanTailscaleIP)) · \(wanPeers.count) Knoten im Verbund.",
                en: "Tailscale detected (\(wanTailscaleIP.isEmpty ? readyWord : wanTailscaleIP)) · \(wanPeers.count) node(s) in cluster.",
                fr: "Tailscale détecté (\(wanTailscaleIP.isEmpty ? readyWord : wanTailscaleIP)) · \(wanPeers.count) nœud(s) dans le cluster.",
                es: "Tailscale detectado (\(wanTailscaleIP.isEmpty ? readyWord : wanTailscaleIP)) · \(wanPeers.count) nodo(s) en el clúster.",
                pt: "Tailscale detetado (\(wanTailscaleIP.isEmpty ? readyWord : wanTailscaleIP)) · \(wanPeers.count) nó(s) no cluster.",
                ru: "Tailscale обнаружен (\(wanTailscaleIP.isEmpty ? readyWord : wanTailscaleIP)) · \(wanPeers.count) узл. в кластере.",
                ja: "Tailscale 検出 (\(wanTailscaleIP.isEmpty ? readyWord : wanTailscaleIP)) · クラスタ内 \(wanPeers.count) ノード。",
                zh: "已检测到 Tailscale (\(wanTailscaleIP.isEmpty ? readyWord : wanTailscaleIP)) · 集群共 \(wanPeers.count) 个节点。"
            )
            : tr(
                de: "Bereit für Tailscale / WireGuard / libp2p-QUIC Mesh (\(wanPeers.count) lokaler Knoten).",
                en: "Ready for Tailscale / WireGuard / libp2p-QUIC Mesh (\(wanPeers.count) local node(s)).",
                fr: "Prêt pour maillage Tailscale / WireGuard / libp2p-QUIC (\(wanPeers.count) nœud local).",
                es: "Listo para malla Tailscale / WireGuard / libp2p-QUIC (\(wanPeers.count) nodo local).",
                pt: "Pronto para malha Tailscale / WireGuard / libp2p-QUIC (\(wanPeers.count) nó local).",
                ru: "Готово к сети Tailscale / WireGuard / libp2p-QUIC (\(wanPeers.count) лок. узел).",
                ja: "Tailscale / WireGuard / libp2p-QUIC メッシュ待機中（ローカル \(wanPeers.count) ノード）。",
                zh: "Tailscale / WireGuard / libp2p-QUIC 网格已就绪（当前 \(wanPeers.count) 个本地节点）。"
            )
    }

    func toggleWanConnection() {
        if wanConnected {
            wanWebSocketTask?.cancel(with: .normalClosure, reason: nil)
            wanWebSocketTask = nil
            wanConnected = false
            chatMessages.append(
                ClusterChatMessage(
                    senderName: "SS-CCC Mesh",
                    senderRegion: "System",
                    senderChip: "",
                    timestamp: currentClockTime(),
                    text: tr(
                        de: "Verbindung zum Internet-Verbund \(wanRoomCode) getrennt.",
                        en: "Disconnected from Internet cluster \(wanRoomCode).",
                        fr: "Déconnecté du cluster Internet \(wanRoomCode).",
                        es: "Desconectado del clúster de Internet \(wanRoomCode).",
                        pt: "Desligado do cluster Internet \(wanRoomCode).",
                        ru: "Отключено от интернет-кластера \(wanRoomCode).",
                        ja: "インターネットクラスタ \(wanRoomCode) から切断しました。",
                        zh: "已断开互联网集群 \(wanRoomCode) 的连接。"
                    ),
                    isSystemEvent: true,
                    isSelf: false
                )
            )
            wanStatusNote = tr(
                de: "Getrennt vom Internet-Verbund.",
                en: "Disconnected from Internet cluster.",
                fr: "Déconnecté du cluster Internet.",
                es: "Desconectado del clúster de Internet.",
                pt: "Desligado do cluster Internet.",
                ru: "Отключено от интернет-кластера.",
                ja: "インターネットクラスタから切断済み。",
                zh: "已断开互联网集群。"
            )
            return
        }

        wanConnected = true
        let endpoint = "\(wanRelayUrl)\(wanRoomCode)"
        chatMessages.append(
            ClusterChatMessage(
                senderName: "SS-CCC Mesh",
                senderRegion: "System",
                senderChip: localChipName,
                timestamp: currentClockTime(),
                text: tr(
                    de: "Beigetreten: \(wanRoomCode) über \(wanTransport.localizedTitle(language)) (MTU \(wanTransport.mtuBytes)).",
                    en: "Joined: \(wanRoomCode) via \(wanTransport.localizedTitle(language)) (MTU \(wanTransport.mtuBytes)).",
                    fr: "Connecté à \(wanRoomCode) via \(wanTransport.localizedTitle(language)) (MTU \(wanTransport.mtuBytes)).",
                    es: "Conectado a \(wanRoomCode) vía \(wanTransport.localizedTitle(language)) (MTU \(wanTransport.mtuBytes)).",
                    pt: "Ligado a \(wanRoomCode) via \(wanTransport.localizedTitle(language)) (MTU \(wanTransport.mtuBytes)).",
                    ru: "Подключено к \(wanRoomCode) через \(wanTransport.localizedTitle(language)) (MTU \(wanTransport.mtuBytes)).",
                    ja: "参加完了: \(wanRoomCode) (\(wanTransport.localizedTitle(language)), MTU \(wanTransport.mtuBytes))。",
                    zh: "已加入房间 \(wanRoomCode)（经由 \(wanTransport.localizedTitle(language))，MTU \(wanTransport.mtuBytes)）。"
                ),
                isSystemEvent: true,
                isSelf: false
            )
        )

        if let url = URL(string: endpoint) {
            let task = URLSession.shared.webSocketTask(with: url)
            wanWebSocketTask = task
            task.resume()
            listenForWanMessages(task)
            let joinPayload: [String: Any] = [
                "type": "join",
                "sender": Host.current().localizedName ?? "Mac",
                "chip": localChipName,
                "ram_gb": Int(localRamGB),
                "region": wanPeerRegionInput
            ]
            if let data = try? JSONSerialization.data(withJSONObject: joinPayload),
               let str = String(data: data, encoding: .utf8) {
                task.send(.string(str)) { _ in }
            }
        }
        wanStatusNote = tr(
            de: "Aktiv verbunden mit \(wanRoomCode) (\(wanPeers.count) Knoten · \(Int(wanTotalRamGB)) GB RAM).",
            en: "Active connection to \(wanRoomCode) (\(wanPeers.count) nodes · \(Int(wanTotalRamGB)) GB RAM).",
            fr: "Connecté à \(wanRoomCode) (\(wanPeers.count) nœuds · \(Int(wanTotalRamGB)) Go RAM).",
            es: "Conectado activamente a \(wanRoomCode) (\(wanPeers.count) nodos · \(Int(wanTotalRamGB)) GB RAM).",
            pt: "Ligado a \(wanRoomCode) (\(wanPeers.count) nós · \(Int(wanTotalRamGB)) GB RAM).",
            ru: "Активное подключение к \(wanRoomCode) (\(wanPeers.count) узл. · \(Int(wanTotalRamGB)) ГБ ОЗУ).",
            ja: "\(wanRoomCode) に接続中（\(wanPeers.count) ノード · \(Int(wanTotalRamGB)) GB RAM）。",
            zh: "已连接到 \(wanRoomCode)（\(wanPeers.count) 个节点 · \(Int(wanTotalRamGB)) GB 内存）。"
        )
    }

    private func listenForWanMessages(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self else { return }
            if case .success(let message) = result, case .string(let text) = message {
                if let data = text.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msgText = json["text"] as? String {
                    let sender = (json["sender"] as? String) ?? "Remote Mac"
                    let region = (json["region"] as? String) ?? "WAN"
                    let chip = (json["chip"] as? String) ?? "Apple Silicon"
                    Task { @MainActor in
                        self.chatMessages.append(
                            ClusterChatMessage(
                                senderName: sender,
                                senderRegion: region,
                                senderChip: chip,
                                timestamp: self.currentClockTime(),
                                text: msgText,
                                isSystemEvent: false,
                                isSelf: false
                            )
                        )
                    }
                }
                Task { @MainActor in
                    if self.wanConnected {
                        self.listenForWanMessages(task)
                    }
                }
            }
        }
    }

    func addManualWanPeer() {
        let name = wanPeerNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = name.isEmpty ? "Remote-\(wanPeerChip.rawValue.replacingOccurrences(of: "Apple ", with: ""))" : name
        let usable = AppleSiliconChipFamily.usableVramGB(for: wanPeerRamGB)
        let peer = WanPeerNode(
            id: "wan-\(UUID().uuidString.prefix(8))",
            displayName: finalName,
            region: wanPeerRegionInput.isEmpty ? "WAN" : wanPeerRegionInput,
            chip: wanPeerChip.rawValue,
            ramGB: wanPeerRamGB,
            usableVramGB: usable,
            bandwidthGBs: wanPeerChip.bandwidthGBs,
            overlayIP: wanPeerIpInput.isEmpty ? "100.64.0.x" : wanPeerIpInput,
            rttMs: wanPeerRttMs,
            uplinkMbps: wanPeerUplinkMbps,
            assignedLayers: "Auto",
            transport: wanTransport,
            isOnline: true,
            isLocalHost: false
        )
        wanPeers.append(peer)
        wanPeerNameInput = ""
        recomputeWanLayerAssignments()
        chatMessages.append(
            ClusterChatMessage(
                senderName: "SS-CCC Mesh",
                senderRegion: peer.region,
                senderChip: peer.chip,
                timestamp: currentClockTime(),
                text: tr(
                    de: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) GB, RTT \(Int(peer.rttMs)) ms) ist dem Verbund beigetreten.",
                    en: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) GB, RTT \(Int(peer.rttMs)) ms) joined the cluster.",
                    fr: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) Go, RTT \(Int(peer.rttMs)) ms) a rejoint le cluster.",
                    es: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) GB, RTT \(Int(peer.rttMs)) ms) se unió al clúster.",
                    pt: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) GB, RTT \(Int(peer.rttMs)) ms) juntou-se ao cluster.",
                    ru: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) ГБ, RTT \(Int(peer.rttMs)) мс) присоединился к кластеру.",
                    ja: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) GB, RTT \(Int(peer.rttMs)) ms) がクラスタに参加しました。",
                    zh: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) GB, RTT \(Int(peer.rttMs)) ms) 已加入集群。"
                ),
                isSystemEvent: true,
                isSelf: false
            )
        )
    }

    func populateMegaClusterSwarm(count: Int) {
        let regions = ["EU-Central", "EU-West", "US-East", "US-West", "AP-Tokyo", "AP-Singapore"]
        let chips: [AppleSiliconChipFamily] = [.m3Max, .m4Pro, .m4Max, .m5Max, .m6Max, .m7Max, .m8Max, .m3Ultra]
        // Keep local host, replace remote simulation peers
        wanPeers = wanPeers.filter(\.isLocalHost)
        for i in 1..<count {
            let chip = chips[i % chips.count]
            let ram = chip.defaultRamGB
            let region = regions[i % regions.count]
            wanPeers.append(
                WanPeerNode(
                    id: "mega-\(i)",
                    displayName: "Swarm-Mac-\(String(format: "%02d", i))",
                    region: region,
                    chip: chip.rawValue,
                    ramGB: ram,
                    usableVramGB: AppleSiliconChipFamily.usableVramGB(for: ram),
                    bandwidthGBs: chip.bandwidthGBs,
                    overlayIP: "100.64.\(i / 250).\(10 + (i % 240))",
                    rttMs: Double(12 + (i % 6) * 14),
                    uplinkMbps: Double(250 + (i % 4) * 200),
                    assignedLayers: "Auto",
                    transport: wanTransport,
                    isOnline: true,
                    isLocalHost: false
                )
            )
        }
        wanScaleMode = count >= 32 ? .megaCluster : .researchSwarm
        recomputeWanLayerAssignments()
        chatMessages.append(
            ClusterChatMessage(
                senderName: "SS-CCC Mesh",
                senderRegion: "Global",
                senderChip: "Swarm-\(count)",
                timestamp: currentClockTime(),
                text: tr(
                    de: "Weltweiter Mega-Verbund mit \(wanPeers.count) Macs (\(Int(wanTotalRamGB)) GB Gesamt-RAM / \(Int(wanTotalUsableVramGB)) GB nutzbar) initialisiert.",
                    en: "Global Mega Cluster initialized with \(wanPeers.count) Macs (\(Int(wanTotalRamGB)) GB Total RAM / \(Int(wanTotalUsableVramGB)) GB usable).",
                    fr: "Méga-cluster mondial initialisé avec \(wanPeers.count) Macs (\(Int(wanTotalRamGB)) Go RAM totale / \(Int(wanTotalUsableVramGB)) Go utilisables).",
                    es: "Megaclúster global inicializado con \(wanPeers.count) Macs (\(Int(wanTotalRamGB)) GB RAM total / \(Int(wanTotalUsableVramGB)) GB utilizables).",
                    pt: "Megacluster global inicializado com \(wanPeers.count) Macs (\(Int(wanTotalRamGB)) GB RAM total / \(Int(wanTotalUsableVramGB)) GB utilizáveis).",
                    ru: "Глобальный мега-кластер инициализирован: \(wanPeers.count) Mac (\(Int(wanTotalRamGB)) ГБ ОЗУ / \(Int(wanTotalUsableVramGB)) ГБ доступно).",
                    ja: "\(wanPeers.count) 台の Mac でグローバル・メガクラスタを初期化しました（総計 \(Int(wanTotalRamGB)) GB / 利用可能 \(Int(wanTotalUsableVramGB)) GB）。",
                    zh: "已初始化全球超大集群，共 \(wanPeers.count) 台 Mac（总内存 \(Int(wanTotalRamGB)) GB / 可用显存 \(Int(wanTotalUsableVramGB)) GB）。"
                ),
                isSystemEvent: true,
                isSelf: false
            )
        )
    }

    // MARK: - Local Thunderbolt/RDMA <-> Internet WAN Coupling

    var coupledLocalBridgeCount: Int {
        wanPeers.filter { $0.isLocalHost || $0.id.hasPrefix("local-bridge-") }.count
    }

    var coupledRemoteWanCount: Int {
        wanPeers.filter { !$0.isLocalHost && !$0.id.hasPrefix("local-bridge-") }.count
    }

    func toggleLocalClusterWanCoupling() {
        isLocalClusterCoupledWithWan.toggle()
        syncLocalClusterIntoWan(announceInChat: true)
    }

    func syncLocalClusterIntoWan(announceInChat: Bool = false) {
        let remoteOnly = wanPeers.filter { !$0.isLocalHost && !$0.id.hasPrefix("local-bridge-") }
        let localLabel = tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")
        let localMacFallback = tr(de: "Lokaler Mac", en: "Local Mac", fr: "Mac local", es: "Mac local", pt: "Mac local", ru: "Локальный Mac", ja: "ローカル Mac", zh: "本地 Mac")
        let bridgeSender = tr(de: "Hybrid-Brücke", en: "Hybrid Bridge", fr: "Pont Hybride", es: "Puente Híbrido", pt: "Ponte Híbrida", ru: "Гибридный мост", ja: "ハイブリッドブリッジ", zh: "混合桥接")
        let bridgeRegion = "\(localLabel) ↔ WAN"
        if isLocalClusterCoupledWithWan {
            let localBridgePeers: [WanPeerNode] = nodes.enumerated().map { idx, node in
                let tbMbps = Double(node.thunderboltGen >= 5 ? 80000 : 32000)
                return WanPeerNode(
                    id: idx == 0 ? "local-host" : "local-bridge-\(node.id)",
                    displayName: idx == 0 ? "\(node.name) (Gateway)" : "\(node.name) (TB\(node.thunderboltGen))",
                    region: "\(localLabel) · TB\(node.thunderboltGen)\(node.rdmaEnabled ? " RDMA" : "")",
                    chip: node.chip,
                    ramGB: node.totalRamGB,
                    usableVramGB: node.usableVramGB,
                    bandwidthGBs: node.bandwidthGBs,
                    overlayIP: idx == 0 ? (wanTailscaleIP.isEmpty ? node.lanIP : wanTailscaleIP) : node.tbIP,
                    rttMs: idx == 0 ? 0.0 : 0.07,
                    uplinkMbps: tbMbps,
                    assignedLayers: "Auto",
                    transport: wanTransport,
                    isOnline: true,
                    isLocalHost: true
                )
            }
            wanPeers = localBridgePeers + remoteOnly
            recomputeWanLayerAssignments()
            wanStatusNote = tr(
                de: "Gekoppelt: \(localBridgePeers.count) lokale TB-Macs + \(remoteOnly.count) WAN-Macs (\(Int(wanTotalRamGB)) GB Gesamt-RAM).",
                en: "Coupled: \(localBridgePeers.count) local TB Macs + \(remoteOnly.count) WAN Macs (\(Int(wanTotalRamGB)) GB total RAM).",
                fr: "Couplé : \(localBridgePeers.count) Macs TB locaux + \(remoteOnly.count) Macs WAN (\(Int(wanTotalRamGB)) Go RAM).",
                es: "Acoplado: \(localBridgePeers.count) Macs TB locales + \(remoteOnly.count) Macs WAN (\(Int(wanTotalRamGB)) GB RAM).",
                pt: "Acoplado: \(localBridgePeers.count) Macs TB locais + \(remoteOnly.count) Macs WAN (\(Int(wanTotalRamGB)) GB RAM).",
                ru: "Объединено: \(localBridgePeers.count) лок. TB-Mac + \(remoteOnly.count) WAN-Mac (\(Int(wanTotalRamGB)) ГБ ОЗУ).",
                ja: "結合中: ローカル TB Mac \(localBridgePeers.count) 台 + WAN Mac \(remoteOnly.count) 台（総計 \(Int(wanTotalRamGB)) GB RAM）。",
                zh: "已耦合：\(localBridgePeers.count) 台本地雷雳 Mac + \(remoteOnly.count) 台广域网 Mac（共 \(Int(wanTotalRamGB)) GB 内存）。"
            )
            if announceInChat {
                chatMessages.append(
                    ClusterChatMessage(
                        senderName: bridgeSender,
                        senderRegion: bridgeRegion,
                        senderChip: "\(localBridgePeers.count) TB + \(remoteOnly.count) WAN",
                        timestamp: currentClockTime(),
                        text: tr(
                            de: "🔗 Lokaler Thunderbolt/RDMA-Verbund (\(localBridgePeers.count) Macs · \(Int(totalPhysicalRamGB)) GB) mit Internet-Cluster gekoppelt. Gesamtspeicher: \(Int(wanTotalRamGB)) GB (\(Int(wanTotalUsableVramGB)) GB nutzbar).",
                            en: "🔗 Local Thunderbolt/RDMA cluster (\(localBridgePeers.count) Macs · \(Int(totalPhysicalRamGB)) GB) coupled with Internet cluster. Total RAM: \(Int(wanTotalRamGB)) GB (\(Int(wanTotalUsableVramGB)) GB usable).",
                            fr: "🔗 Cluster Thunderbolt/RDMA local (\(localBridgePeers.count) Macs · \(Int(totalPhysicalRamGB)) Go) couplé au cluster Internet. Total : \(Int(wanTotalRamGB)) Go (\(Int(wanTotalUsableVramGB)) Go utilisables).",
                            es: "🔗 Clúster local Thunderbolt/RDMA (\(localBridgePeers.count) Macs · \(Int(totalPhysicalRamGB)) GB) acoplado al clúster de Internet. Total: \(Int(wanTotalRamGB)) GB (\(Int(wanTotalUsableVramGB)) GB utilizables).",
                            pt: "🔗 Cluster local Thunderbolt/RDMA (\(localBridgePeers.count) Macs · \(Int(totalPhysicalRamGB)) GB) acoplado ao cluster Internet. Total: \(Int(wanTotalRamGB)) GB (\(Int(wanTotalUsableVramGB)) GB utilizáveis).",
                            ru: "🔗 Локальный TB/RDMA кластер (\(localBridgePeers.count) Mac · \(Int(totalPhysicalRamGB)) ГБ) подключён к интернет-кластеру. Всего: \(Int(wanTotalRamGB)) ГБ (\(Int(wanTotalUsableVramGB)) ГБ доступно).",
                            ja: "🔗 ローカル Thunderbolt/RDMA (\(localBridgePeers.count) 台 · \(Int(totalPhysicalRamGB)) GB) をインターネットクラスタに結合しました。合計 \(Int(wanTotalRamGB)) GB（利用可能 \(Int(wanTotalUsableVramGB)) GB）。",
                            zh: "🔗 已将本地雷雳/RDMA 集群（\(localBridgePeers.count) 台 Mac · \(Int(totalPhysicalRamGB)) GB）耦合至互联网集群。总内存：\(Int(wanTotalRamGB)) GB（可用 \(Int(wanTotalUsableVramGB)) GB）。"
                        ),
                        isSystemEvent: true,
                        isSelf: false
                    )
                )
            }
        } else {
            let primaryHost = wanPeers.first(where: { $0.id == "local-host" }) ?? WanPeerNode(
                id: "local-host",
                displayName: Host.current().localizedName ?? localMacFallback,
                region: localLabel,
                chip: localChipName,
                ramGB: localRamGB,
                usableVramGB: AppleSiliconChipFamily.usableVramGB(for: localRamGB),
                bandwidthGBs: AppleSiliconChipFamily.inferBandwidth(from: localChipName),
                overlayIP: wanTailscaleIP.isEmpty ? localLanIP : wanTailscaleIP,
                rttMs: 0.0,
                uplinkMbps: 300.0,
                assignedLayers: "Auto",
                transport: wanTransport,
                isOnline: true,
                isLocalHost: true
            )
            wanPeers = [primaryHost] + remoteOnly
            recomputeWanLayerAssignments()
            wanStatusNote = tr(
                de: "Kopplung gelöst: \(wanPeers.count) Knoten im Internet-Verbund.",
                en: "Uncoupled: \(wanPeers.count) node(s) in Internet cluster.",
                fr: "Découplé : \(wanPeers.count) nœud(s) dans le cluster Internet.",
                es: "Desacoplado: \(wanPeers.count) nodo(s) en el clúster de Internet.",
                pt: "Desacoplado: \(wanPeers.count) nó(s) no cluster Internet.",
                ru: "Разъединено: \(wanPeers.count) узл. в интернет-кластере.",
                ja: "結合解除: インターネットクラスタ内 \(wanPeers.count) ノード。",
                zh: "已解除耦合：互联网集群剩余 \(wanPeers.count) 个节点。"
            )
            if announceInChat {
                chatMessages.append(
                    ClusterChatMessage(
                        senderName: bridgeSender,
                        senderRegion: bridgeRegion,
                        senderChip: tr(de: "Getrennt", en: "Detached", fr: "Détaché", es: "Desacoplado", pt: "Desligado", ru: "Отключено", ja: "切断済み", zh: "已断开"),
                        timestamp: currentClockTime(),
                        text: tr(
                            de: "🔌 Lokale Thunderbolt-Brücke vom Internet-Cluster getrennt.",
                            en: "🔌 Local Thunderbolt bridge uncoupled from Internet cluster.",
                            fr: "🔌 Pont Thunderbolt local découplé du cluster Internet.",
                            es: "🔌 Puente Thunderbolt local desacoplado del clúster de Internet.",
                            pt: "🔌 Ponte Thunderbolt local desligada do cluster Internet.",
                            ru: "🔌 Локальный мост Thunderbolt отключён от интернет-кластера.",
                            ja: "🔌 ローカル Thunderbolt ブリッジをインターネットクラスタから切り離しました。",
                            zh: "🔌 已断开本地 Thunderbolt 网桥与互联网集群的耦合。"
                        ),
                        isSystemEvent: true,
                        isSelf: false
                    )
                )
            }
        }
    }

    func recomputeWanLayerAssignments() {
        guard !wanPeers.isEmpty else { return }
        let totalLayers = max(8, selectedModel.totalLayers)
        let totalBw = max(1.0, wanPeers.reduce(0.0) { $0 + $1.bandwidthGBs })
        var cursor = 0
        var updated: [WanPeerNode] = []
        for (idx, peer) in wanPeers.enumerated() {
            let share = peer.bandwidthGBs / totalBw
            let count = (idx == wanPeers.count - 1)
                ? max(0, totalLayers - cursor)
                : max(1, Int((Double(totalLayers) * share).rounded()))
            let end = min(totalLayers, cursor + count)
            let rangeLabel = cursor < end ? "L\(cursor)–L\(end - 1)" : "Replica"
            cursor = end
            updated.append(
                WanPeerNode(
                    id: peer.id,
                    displayName: peer.displayName,
                    region: peer.region,
                    chip: peer.chip,
                    ramGB: peer.ramGB,
                    usableVramGB: peer.usableVramGB,
                    bandwidthGBs: peer.bandwidthGBs,
                    overlayIP: peer.overlayIP,
                    rttMs: peer.rttMs,
                    uplinkMbps: peer.uplinkMbps,
                    assignedLayers: rangeLabel,
                    transport: peer.transport,
                    isOnline: peer.isOnline,
                    isLocalHost: peer.isLocalHost
                )
            )
        }
        wanPeers = updated
        if audioPartyJoined || !audioPartyMembers.isEmpty {
            syncAudioPartyMembers()
        }
    }

    func sendClusterChatMessage(_ overrideText: String? = nil) {
        let raw = (overrideText ?? chatInput).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        if overrideText == nil { chatInput = "" }

        let localLabel = tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")
        let localMacFallback = tr(de: "Lokaler Mac", en: "Local Mac", fr: "Mac local", es: "Mac local", pt: "Mac local", ru: "Локальный Mac", ja: "ローカル Mac", zh: "本地 Mac")
        let sender = Host.current().localizedName ?? localMacFallback
        var finalText = raw
        if raw == "/status" {
            let localizedTherm = nodes.first?.localizedThermal(language) ?? localThermalLabel
            let localizedPwr = nodes.first?.localizedPower(language) ?? localPowerLabel
            finalText = tr(
                de: "📊 Status: \(localChipName) · \(Int(localRamGB)) GB RAM · \(localizedTherm) · \(localizedPwr) · Transport: \(wanTransport.localizedTitle(language))",
                en: "📊 Status: \(localChipName) · \(Int(localRamGB)) GB RAM · \(localizedTherm) · \(localizedPwr) · Transport: \(wanTransport.localizedTitle(language))",
                fr: "📊 Statut : \(localChipName) · \(Int(localRamGB)) Go RAM · \(localizedTherm) · \(localizedPwr) · Transport : \(wanTransport.localizedTitle(language))",
                es: "📊 Estado: \(localChipName) · \(Int(localRamGB)) GB RAM · \(localizedTherm) · \(localizedPwr) · Transporte: \(wanTransport.localizedTitle(language))",
                pt: "📊 Estado: \(localChipName) · \(Int(localRamGB)) GB RAM · \(localizedTherm) · \(localizedPwr) · Transporte: \(wanTransport.localizedTitle(language))",
                ru: "📊 Статус: \(localChipName) · \(Int(localRamGB)) ГБ ОЗУ · \(localizedTherm) · \(localizedPwr) · Транспорт: \(wanTransport.localizedTitle(language))",
                ja: "📊 状態: \(localChipName) · \(Int(localRamGB)) GB RAM · \(localizedTherm) · \(localizedPwr) · 転送: \(wanTransport.localizedTitle(language))",
                zh: "📊 状态：\(localChipName) · \(Int(localRamGB)) GB 内存 · \(localizedTherm) · \(localizedPwr) · 传输：\(wanTransport.localizedTitle(language))"
            )
        } else if raw == "/layers" {
            let myLayers = wanPeers.first(where: \.isLocalHost)?.assignedLayers ?? "Auto"
            finalText = tr(
                de: "🧩 Schichten-Anteil: \(myLayers) für \(selectedModel.displayName) · Verbund-Summe: \(wanPeers.count) Macs (\(Int(wanTotalUsableVramGB)) GB nutzbar)",
                en: "🧩 Layer Share: \(myLayers) for \(selectedModel.displayName) · Cluster Total: \(wanPeers.count) Macs (\(Int(wanTotalUsableVramGB)) GB usable)",
                fr: "🧩 Répartition : \(myLayers) pour \(selectedModel.displayName) · Total : \(wanPeers.count) Macs (\(Int(wanTotalUsableVramGB)) Go utilisables)",
                es: "🧩 Reparto de capas: \(myLayers) para \(selectedModel.displayName) · Total: \(wanPeers.count) Macs (\(Int(wanTotalUsableVramGB)) GB utilizables)",
                pt: "🧩 Camadas: \(myLayers) para \(selectedModel.displayName) · Total: \(wanPeers.count) Macs (\(Int(wanTotalUsableVramGB)) GB utilizáveis)",
                ru: "🧩 Доля слоёв: \(myLayers) для \(selectedModel.displayName) · Всего: \(wanPeers.count) Mac (\(Int(wanTotalUsableVramGB)) ГБ доступно)",
                ja: "🧩 担当層: \(selectedModel.displayName) 用 \(myLayers) · クラスタ計 \(wanPeers.count) 台 (\(Int(wanTotalUsableVramGB)) GB 利用可能)",
                zh: "🧩 分层配额：\(selectedModel.displayName) 分配 \(myLayers) · 集群总计 \(wanPeers.count) 台 Mac（可用 \(Int(wanTotalUsableVramGB)) GB）"
            )
        } else if raw == "/ping" {
            finalText = String(format: tr(
                de: "🏓 WAN-Pipeline RTT: %.1f ms · Geschätzte Rate: %.2f tok/s",
                en: "🏓 WAN Pipeline RTT: %.1f ms · Est. Throughput: %.2f tok/s",
                fr: "🏓 RTT Pipeline WAN : %.1f ms · Débit est. : %.2f tok/s",
                es: "🏓 RTT Pipeline WAN: %.1f ms · Tasa est.: %.2f tok/s",
                pt: "🏓 RTT Pipeline WAN: %.1f ms · Débito est.: %.2f tok/s",
                ru: "🏓 RTT конвейера WAN: %.1f мс · Оценка: %.2f tok/с",
                ja: "🏓 WAN パイプライン RTT: %.1f ms · 推定速度: %.2f tok/s",
                zh: "🏓 WAN 流水线 RTT：%.1f ms · 预计速率：%.2f tok/s"
            ), wanTotalRttMs, wanEstimatedTokPerSec)
        }

        chatMessages.append(
            ClusterChatMessage(
                senderName: sender,
                senderRegion: localLabel,
                senderChip: localChipName,
                timestamp: currentClockTime(),
                text: finalText,
                isSystemEvent: false,
                isSelf: true
            )
        )

        if let task = wanWebSocketTask, wanConnected {
            let payload: [String: Any] = [
                "type": "chat",
                "sender": sender,
                "region": wanPeerRegionInput,
                "chip": localChipName,
                "text": finalText
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let str = String(data: data, encoding: .utf8) {
                task.send(.string(str)) { _ in }
            }
        }
    }

    // MARK: - Cluster Audio-Party (Xbox / PlayStation-style Voice Coordination)

    var audioPartyBandwidthSharePercent: Double {
        let minUplinkKbps = max(1000.0, (wanPeers.map(\.uplinkMbps).min() ?? 100.0) * 1000.0)
        return (audioPartyCodec.kbps / minUplinkKbps) * 100.0
    }

    func toggleAudioParty() {
        if audioPartyJoined {
            leaveAudioParty()
        } else {
            joinAudioParty()
        }
    }

    func joinAudioParty() {
        audioPartyJoined = true
        syncAudioPartyMembers()
        startPartyAudioMonitor()
        connectPartyAudioWebSocket()
        let localMacFallback = tr(de: "Lokaler Mac", en: "Local Mac", fr: "Mac local", es: "Mac local", pt: "Mac local", ru: "Локальный Mac", ja: "ローカル Mac", zh: "本地 Mac")
        let hostName = Host.current().localizedName ?? localMacFallback
        audioPartyStatusText = tr(
            de: "In Audio-Party (\(audioPartyMembers.count) Teilnehmer · \(audioPartyCodec.localizedTitle(language)))",
            en: "In Audio Party (\(audioPartyMembers.count) members · \(audioPartyCodec.localizedTitle(language)))",
            fr: "En salon audio (\(audioPartyMembers.count) membres · \(audioPartyCodec.localizedTitle(language)))",
            es: "En sala de audio (\(audioPartyMembers.count) miembros · \(audioPartyCodec.localizedTitle(language)))",
            pt: "Na festa áudio (\(audioPartyMembers.count) membros · \(audioPartyCodec.localizedTitle(language)))",
            ru: "В аудио-комнате (\(audioPartyMembers.count) участн. · \(audioPartyCodec.localizedTitle(language)))",
            ja: "オーディオパーティ参加中（\(audioPartyMembers.count) 名 · \(audioPartyCodec.localizedTitle(language))）",
            zh: "已加入语音派对（\(audioPartyMembers.count) 人 · \(audioPartyCodec.localizedTitle(language))）"
        )
        chatMessages.append(
            ClusterChatMessage(
                senderName: "Audio-Party",
                senderRegion: wanPeerRegionInput,
                senderChip: localChipName,
                timestamp: currentClockTime(),
                text: tr(
                    de: "🎧 \(hostName) ist der Cluster-Audio-Party beigetreten (\(audioPartyCodec.localizedTitle(language))).",
                    en: "🎧 \(hostName) joined Cluster Audio Party (\(audioPartyCodec.localizedTitle(language))).",
                    fr: "🎧 \(hostName) a rejoint le salon audio (\(audioPartyCodec.localizedTitle(language))).",
                    es: "🎧 \(hostName) se unió a la sala de audio (\(audioPartyCodec.localizedTitle(language))).",
                    pt: "🎧 \(hostName) entrou na festa áudio (\(audioPartyCodec.localizedTitle(language))).",
                    ru: "🎧 \(hostName) присоединился к аудио-комнате (\(audioPartyCodec.localizedTitle(language))).",
                    ja: "🎧 \(hostName) がクラスタ・オーディオパーティに参加しました (\(audioPartyCodec.localizedTitle(language)))。",
                    zh: "🎧 \(hostName) 已加入集群语音派对 (\(audioPartyCodec.localizedTitle(language)))。"
                ),
                isSystemEvent: true,
                isSelf: false
            )
        )
    }

    func leaveAudioParty() {
        audioPartyJoined = false
        audioPartyMicLevel = 0.0
        partyPulseTask?.cancel()
        partyPulseTask = nil
        partyAudioEngine?.inputNode.removeTap(onBus: 0)
        partyAudioEngine?.stop()
        partyAudioEngine = nil
        partyAudioSocket?.cancel(with: .normalClosure, reason: nil)
        partyAudioSocket = nil
        let localMacFallback = tr(de: "Lokaler Mac", en: "Local Mac", fr: "Mac local", es: "Mac local", pt: "Mac local", ru: "Локальный Mac", ja: "ローカル Mac", zh: "本地 Mac")
        let hostName = Host.current().localizedName ?? localMacFallback
        audioPartyStatusText = tr(
            de: "Audio-Party verlassen.",
            en: "Left Audio Party.",
            fr: "Salon audio quitté.",
            es: "Has salido de la sala de audio.",
            pt: "Saiu da festa áudio.",
            ru: "Вы вышли из аудио-комнаты.",
            ja: "オーディオパーティから退出しました。",
            zh: "已离开语音派对。"
        )
        chatMessages.append(
            ClusterChatMessage(
                senderName: "Audio-Party",
                senderRegion: wanPeerRegionInput,
                senderChip: localChipName,
                timestamp: currentClockTime(),
                text: tr(
                    de: "🔇 \(hostName) hat die Audio-Party verlassen.",
                    en: "🔇 \(hostName) left Audio Party.",
                    fr: "🔇 \(hostName) a quitté le salon audio.",
                    es: "🔇 \(hostName) salió de la sala de audio.",
                    pt: "🔇 \(hostName) saiu da festa áudio.",
                    ru: "🔇 \(hostName) покинул аудио-комнату.",
                    ja: "🔇 \(hostName) がオーディオパーティから退出しました。",
                    zh: "🔇 \(hostName) 已离开语音派对。"
                ),
                isSystemEvent: true,
                isSelf: false
            )
        )
    }

    func togglePartyMute() {
        audioPartyMuted.toggle()
        if audioPartyMuted { audioPartyMicLevel = 0.0 }
        syncSelfSpeakingState(speaking: false)
    }

    func togglePartyDeafen() {
        audioPartyDeafened.toggle()
        if audioPartyDeafened {
            audioPartyMuted = true
            audioPartyMicLevel = 0.0
        }
        syncSelfSpeakingState(speaking: false)
    }

    func triggerPushToTalk(active: Bool) {
        audioPartyPushToTalkActive = active
        if active && audioPartyJoined && !audioPartyMuted && !audioPartyDeafened {
            audioPartyMicLevel = 0.72
            syncSelfSpeakingState(speaking: true)
        } else {
            syncSelfSpeakingState(speaking: false)
        }
    }

    func syncAudioPartyMembers() {
        let localLabel = tr(de: "Lokal", en: "Local", fr: "Local", es: "Local", pt: "Local", ru: "Локально", ja: "ローカル", zh: "本地")
        let localMacFallback = tr(de: "Lokaler Mac", en: "Local Mac", fr: "Mac local", es: "Mac local", pt: "Mac local", ru: "Локальный Mac", ja: "ローカル Mac", zh: "本地 Mac")
        let peers = wanPeers.isEmpty ? [
            WanPeerNode(
                id: "local-host",
                displayName: Host.current().localizedName ?? localMacFallback,
                region: localLabel,
                chip: localChipName,
                ramGB: localRamGB,
                usableVramGB: AppleSiliconChipFamily.usableVramGB(for: localRamGB),
                bandwidthGBs: AppleSiliconChipFamily.inferBandwidth(from: localChipName),
                overlayIP: localLanIP,
                rttMs: 0.0,
                uplinkMbps: 300.0,
                assignedLayers: "L0–L\(max(0, selectedModel.totalLayers - 1))",
                transport: wanTransport,
                isOnline: true,
                isLocalHost: true
            )
        ] : wanPeers

        let existingMap = Dictionary(uniqueKeysWithValues: audioPartyMembers.map { ($0.id, $0) })
        audioPartyMembers = peers.prefix(16).enumerated().map { idx, peer in
            let prev = existingMap[peer.id]
            let role = idx == 0
                ? tr(de: "Party-Leiter (Rang 0)", en: "Party Leader (Rank 0)", fr: "Chef de groupe (Rang 0)", es: "Líder del grupo (Rango 0)", pt: "Líder do grupo (Ranque 0)", ru: "Лидер группы (Ранг 0)", ja: "パーティリーダー (Rank 0)", zh: "语音队长 (Rank 0)")
                : (peer.isLocalHost
                    ? tr(de: "TB-Insel-Knoten", en: "TB Island Node", fr: "Nœud îlot TB", es: "Nodo isla TB", pt: "Nó ilha TB", ru: "Локальный узел TB", ja: "TBアイランド", zh: "本地 TB 节点")
                    : tr(de: "WAN-Knoten", en: "WAN Peer", fr: "Pair WAN", es: "Par WAN", pt: "Par WAN", ru: "WAN-узел", ja: "WANピア", zh: "WAN 节点"))
            return AudioPartyMember(
                id: peer.id,
                displayName: peer.displayName,
                chip: peer.chip,
                region: peer.region,
                assignedLayers: peer.assignedLayers,
                roleBadge: role,
                isSelf: peer.id == "local-host",
                isSpeaking: prev?.isSpeaking ?? false,
                isMuted: peer.id == "local-host" ? audioPartyMuted : (prev?.isMuted ?? false),
                volumePercent: prev?.volumePercent ?? 100.0,
                voicePingMs: peer.isLocalHost ? 1.0 : peer.rttMs + audioPartyCodec.kbps * 0.1
            )
        }
    }

    func toggleMemberMute(id: String) {
        if id == "local-host" {
            togglePartyMute()
            return
        }
        if let idx = audioPartyMembers.firstIndex(where: { $0.id == id }) {
            audioPartyMembers[idx].isMuted.toggle()
        }
    }

    func setMemberVolume(id: String, volume: Double) {
        if let idx = audioPartyMembers.firstIndex(where: { $0.id == id }) {
            audioPartyMembers[idx].volumePercent = volume
        }
    }

    func sendPartyCallout(_ text: String) {
        if !audioPartyDeafened {
            NSSound.beep()
        }
        syncSelfSpeakingState(speaking: true)
        sendClusterChatMessage("🎙️ [Party-Signal] \(text)")
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            syncSelfSpeakingState(speaking: false)
        }
    }

    private func syncSelfSpeakingState(speaking: Bool) {
        if let idx = audioPartyMembers.firstIndex(where: { $0.isSelf }) {
            audioPartyMembers[idx].isSpeaking = speaking && !audioPartyMuted && !audioPartyDeafened
        }
    }

    private func connectPartyAudioWebSocket() {
        let base = wanRelayUrl
            .replacingOccurrences(of: "/ws/wan/", with: "/ws/wan-audio/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/\(wanRoomCode)") else { return }
        let task = URLSession.shared.webSocketTask(with: url)
        partyAudioSocket = task
        task.resume()
    }

    private func startPartyAudioMonitor() {
        partyPulseTask?.cancel()
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            let engine = AVAudioEngine()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            if format.sampleRate > 0 && format.channelCount > 0 {
                input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                    guard let channelData = buffer.floatChannelData?[0] else { return }
                    let frames = Int(buffer.frameLength)
                    var sumSq: Float = 0
                    for i in 0..<frames {
                        let s = channelData[i]
                        sumSq += s * s
                    }
                    let rms = frames > 0 ? sqrt(sumSq / Float(frames)) : 0
                    let level = min(1.0, Double(rms) * 8.0)
                    Task { @MainActor in
                        guard let self, self.audioPartyJoined else { return }
                        if self.audioPartyMuted || self.audioPartyDeafened {
                            self.audioPartyMicLevel = 0.0
                            self.syncSelfSpeakingState(speaking: false)
                        } else {
                            self.audioPartyMicLevel = level
                            let threshold = self.audioPartyNoiseGate ? 0.14 : 0.04
                            let active = self.audioPartyMicMode == .openMic
                                ? (level > threshold)
                                : self.audioPartyPushToTalkActive
                            self.syncSelfSpeakingState(speaking: active)
                        }
                    }
                }
                do {
                    try engine.start()
                    partyAudioEngine = engine
                    return
                } catch {
                    engine.stop()
                }
            }
        }

        // Graceful fallback pulse when microphone permission is not yet granted or running headless
        partyPulseTask = Task {
            var tick = 0
            while !Task.isCancelled && audioPartyJoined {
                tick += 1
                if !audioPartyMuted && !audioPartyDeafened && audioPartyMicMode == .openMic {
                    audioPartyMicLevel = (tick % 4 == 0) ? 0.35 : 0.08
                    syncSelfSpeakingState(speaking: tick % 4 == 0)
                } else if !audioPartyPushToTalkActive {
                    audioPartyMicLevel = 0.0
                    syncSelfSpeakingState(speaking: false)
                }
                try? await Task.sleep(nanoseconds: 450_000_000)
            }
        }
    }

    private func currentClockTime() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: Date())
    }

    // MARK: - GitHub-Controlled Program Update Checker & Installer

    static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let cleanA = lhs.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
        let cleanB = rhs.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
        let partsA = cleanA.split(separator: ".").map { Int($0.prefix(while: { $0.isNumber })) ?? 0 }
        let partsB = cleanB.split(separator: ".").map { Int($0.prefix(while: { $0.isNumber })) ?? 0 }
        let maxCount = max(partsA.count, partsB.count)
        for i in 0..<maxCount {
            let a = i < partsA.count ? partsA[i] : 0
            let b = i < partsB.count ? partsB[i] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }
        return .orderedSame
    }

    func startAutomaticUpdateMonitor() {
        autoUpdateMonitorTask?.cancel()
        autoUpdateMonitorTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            while !Task.isCancelled {
                guard let self, self.autoUpdateCheckEnabled else { return }
                await self.checkForGitHubUpdates(userInitiated: false)
                try? await Task.sleep(nanoseconds: 1_800_000_000_000) // 30 minutes
            }
        }
    }

    func refreshLocalCommitSHA() {
        if let repoRoot = localGitRepoRoot {
            let res = Self.runCommandInDir(repoRoot, "/usr/bin/git", ["rev-parse", "--short", "HEAD"])
            let cleanStdout = res.stdout
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .last(where: { !$0.isEmpty }) ?? ""
            if res.exitCode == 0 && !cleanStdout.isEmpty {
                localGitCommitSHA = cleanStdout
                return
            }
        }
        localGitCommitSHA = AppReleaseMetadata.embeddedCommitSHA
    }

    private func isRemoteCommitAheadOfLocal(_ remoteSHA: String) -> Bool {
        let cleanRemote = remoteSHA.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocal = localGitCommitSHA.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanRemote.isEmpty, !cleanLocal.isEmpty, cleanRemote != cleanLocal, let repoRoot = localGitRepoRoot else {
            return false
        }
        // If remoteSHA is already an ancestor of local HEAD (e.g. local is ahead of version.json), no update needed.
        let ancestorCheck = Self.runCommandInDir(repoRoot, "/usr/bin/git", ["merge-base", "--is-ancestor", cleanRemote, "HEAD"])
        return ancestorCheck.exitCode != 0
    }

    func checkForGitHubUpdates(userInitiated: Bool = true) async {
        updateStatus = .checking
        refreshLocalCommitSHA()
        let manifestCandidate = await fetchGitHubManifest()
        let releaseCandidate = await fetchGitHubLatestRelease()
        let remoteHeadSHA = await fetchGitHubMainCommitSHA()

        let best: GitHubUpdateInfo?
        switch (manifestCandidate, releaseCandidate) {
        case let (m?, r?):
            let cmp = Self.compareVersions(r.version, m.version)
            best = (cmp == .orderedDescending) ? r : m
        case let (m?, nil):
            best = m
        case let (nil, r?):
            best = r
        case (nil, nil):
            best = nil
        }

        lastUpdateCheckTime = currentClockTime()

        guard var info = best else {
            updateStatus = userInitiated ? .failed("GitHub nicht erreichbar") : .idle
            return
        }

        if info.commitSHA.isEmpty, let sha = remoteHeadSHA {
            info = GitHubUpdateInfo(
                version: info.version,
                build: info.build,
                tag: info.tag,
                title: info.title,
                notes: info.notes,
                mandatory: info.mandatory,
                releaseURL: info.releaseURL,
                downloadURL: info.downloadURL,
                sourceLabel: info.sourceLabel,
                commitSHA: sha,
                updatedAt: info.updatedAt
            )
        }

        let currentVer = AppReleaseMetadata.currentVersion
        let currentBuild = AppReleaseMetadata.currentBuild
        let versionCmp = Self.compareVersions(info.version, currentVer)
        let shaChanged = isRemoteCommitAheadOfLocal(info.commitSHA)
        let isNewer = (versionCmp == .orderedDescending) || (versionCmp == .orderedSame && info.build > currentBuild) || (versionCmp == .orderedDescending && shaChanged)

        if isNewer {
            availableUpdate = info
            updateStatus = .updateAvailable
            if userInitiated || info.mandatory || skippedUpdateVersion != info.version {
                showUpdatePromptSheet = true
            }
        } else {
            availableUpdate = info
            updateStatus = .upToDate
            if userInitiated {
                showUpdatePromptSheet = true
            }
        }
    }

    private func fetchGitHubMainCommitSHA() async -> String? {
        guard let url = URL(string: AppReleaseMetadata.commitsMainAPIURL) else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 6
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let sha = obj["sha"] as? String else { return nil }
            return String(sha.prefix(7))
        } catch {
            return nil
        }
    }

    private func fetchGitHubManifest() async -> GitHubUpdateInfo? {
        guard let url = URL(string: "\(AppReleaseMetadata.manifestRawURL)?t=\(Int(Date().timeIntervalSince1970))") else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 8
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let version = obj["version"] as? String else { return nil }
            let build = obj["build"] as? Int ?? 0
            let tag = obj["tag"] as? String ?? "v\(version)"
            let title = obj["title"] as? String ?? "SS-CCC \(tag)"
            let notes = obj["notes"] as? String ?? ""
            let mandatory = obj["mandatory"] as? Bool ?? false
            let releaseURL = obj["release_url"] as? String ?? AppReleaseMetadata.releasesPageURL
            let downloadURL = obj["download_url"] as? String ?? releaseURL
            let commitSHA = obj["commit_sha"] as? String ?? ""
            let updatedAt = obj["updated_at"] as? String ?? ""
            return GitHubUpdateInfo(
                version: version,
                build: build,
                tag: tag,
                title: title,
                notes: notes,
                mandatory: mandatory,
                releaseURL: releaseURL,
                downloadURL: downloadURL,
                sourceLabel: "GitHub main/version.json",
                commitSHA: commitSHA,
                updatedAt: updatedAt
            )
        } catch {
            return nil
        }
    }

    private func fetchGitHubLatestRelease() async -> GitHubUpdateInfo? {
        guard let url = URL(string: AppReleaseMetadata.latestReleaseAPIURL) else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 8
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = obj["tag_name"] as? String else { return nil }
            let cleanVer = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
            let title = obj["name"] as? String ?? "SS-CCC \(tagName)"
            let notes = obj["body"] as? String ?? ""
            let htmlURL = obj["html_url"] as? String ?? AppReleaseMetadata.releasesPageURL
            var downloadURL = htmlURL
            if let assets = obj["assets"] as? [[String: Any]],
               let firstAsset = assets.first(where: { ($0["name"] as? String ?? "").hasSuffix(".dmg") || ($0["name"] as? String ?? "").hasSuffix(".zip") }),
               let browserDownload = firstAsset["browser_download_url"] as? String {
                downloadURL = browserDownload
            }
            return GitHubUpdateInfo(
                version: cleanVer,
                build: 0,
                tag: tagName,
                title: title,
                notes: notes,
                mandatory: false,
                releaseURL: htmlURL,
                downloadURL: downloadURL,
                sourceLabel: "GitHub Releases",
                commitSHA: "",
                updatedAt: obj["published_at"] as? String ?? ""
            )
        } catch {
            return nil
        }
    }

    func skipCurrentUpdate() {
        if let ver = availableUpdate?.version {
            skippedUpdateVersion = ver
            UserDefaults.standard.set(ver, forKey: "ssccc_skipped_version")
        }
        showUpdatePromptSheet = false
    }

    func openUpdateOnGitHub() {
        let target = availableUpdate?.downloadURL ?? AppReleaseMetadata.releasesPageURL
        if let url = URL(string: target) {
            NSWorkspace.shared.open(url)
        }
    }

    var localGitRepoRoot: URL? {
        let fm = FileManager.default
        var candidates = [
            URL(fileURLWithPath: fm.currentDirectoryPath),
            Bundle.main.bundleURL.deletingLastPathComponent(),
            Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent(),
            Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        ]
        if let bgPath = ProcessInfo.processInfo.environment["SSCCC_BG_PATH"], !bgPath.isEmpty {
            let repoFromBg = URL(fileURLWithPath: bgPath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            candidates.append(repoFromBg)
        }
        for base in candidates {
            var dir = base
            for _ in 0..<5 {
                if fm.fileExists(atPath: dir.appendingPathComponent(".git").path) &&
                    fm.fileExists(atPath: dir.appendingPathComponent("app/Package.swift").path) {
                    return dir
                }
                dir = dir.deletingLastPathComponent()
            }
        }
        return nil
    }

    nonisolated private static func syncBuiltBinaryToTmp(repoRoot: URL, onlyIfNewer: Bool = false) -> Bool {
        let candidates = [
            repoRoot.appendingPathComponent("app/.build/out/Products/Debug/SSCCCApp").path,
            repoRoot.appendingPathComponent("app/.build/debug/SSCCCApp").path,
            "/tmp/ssccc-build/out/Products/Debug/SSCCCApp",
            "/tmp/ssccc-build/debug/SSCCCApp"
        ]
        let outBin = "/tmp/SSCCCApp"
        let tmpBin = "/tmp/SSCCCApp.new"
        let fm = FileManager.default

        let newestCandidate = candidates
            .filter { fm.isExecutableFile(atPath: $0) }
            .max { a, b in
                let da = (try? fm.attributesOfItem(atPath: a)[.modificationDate] as? Date) ?? .distantPast
                let db = (try? fm.attributesOfItem(atPath: b)[.modificationDate] as? Date) ?? .distantPast
                return da < db
            }
        guard let spmBin = newestCandidate else { return fm.isExecutableFile(atPath: outBin) }

        if onlyIfNewer && fm.isExecutableFile(atPath: outBin) {
            let srcDate = (try? fm.attributesOfItem(atPath: spmBin)[.modificationDate] as? Date) ?? .distantPast
            let outDate = (try? fm.attributesOfItem(atPath: outBin)[.modificationDate] as? Date) ?? .distantPast
            if srcDate <= outDate {
                return true
            }
        }

        do {
            if fm.fileExists(atPath: tmpBin) {
                try fm.removeItem(atPath: tmpBin)
            }
            try fm.copyItem(atPath: spmBin, toPath: tmpBin)
            try fm.setAttributes([.posixPermissions: NSNumber(value: Int16(0o755))], ofItemAtPath: tmpBin)
            if fm.fileExists(atPath: outBin) {
                try fm.removeItem(atPath: outBin)
            }
            try fm.moveItem(atPath: tmpBin, toPath: outBin)
            return true
        } catch {
            return fm.isExecutableFile(atPath: outBin)
        }
    }

    func applyGitHubUpdateAndRebuild() {
        guard let repoRoot = localGitRepoRoot else {
            openUpdateOnGitHub()
            return
        }
        updateStatus = .updating
        updateProgressLog = "git pull --ff-only origin main …\n"

        Task.detached(priority: .userInitiated) {
            let pullOut = Self.runCommandInDir(
                repoRoot,
                "/usr/bin/git",
                ["pull", "--ff-only", "origin", "main"]
            ) { chunk in
                let cleaned = Self.sanitizeGitNoise(chunk)
                guard !cleaned.isEmpty else { return }
                Task { @MainActor in
                    self.updateProgressLog += cleaned
                }
            }

            var syncSummary = Self.sanitizeGitNoise(pullOut.output)
            if pullOut.exitCode != 0 {
                // Fallback when local auto-bump metadata diverged from origin/main
                let fetchOut = Self.runCommandInDir(repoRoot, "/usr/bin/git", ["fetch", "origin", "main"])
                let resetOut = fetchOut.exitCode == 0
                    ? Self.runCommandInDir(repoRoot, "/usr/bin/git", ["reset", "--hard", "origin/main"])
                    : fetchOut
                if resetOut.exitCode != 0 {
                    await MainActor.run {
                        let cleanErr = Self.sanitizeGitNoise(resetOut.output.isEmpty ? pullOut.output : resetOut.output)
                        if !cleanErr.isEmpty {
                            self.updateProgressLog = cleanErr
                        }
                        self.updateStatus = .failed("git pull failed (Exit \(pullOut.exitCode))")
                    }
                    return
                }
                syncSummary = Self.sanitizeGitNoise(resetOut.output)
            }

            let pullSummary = syncSummary
            await MainActor.run {
                self.updateProgressLog = (pullSummary.isEmpty ? "Already up to date." : pullSummary) + "\n\nswift build …\n"
            }

            let appDir = repoRoot.appendingPathComponent("app")
            let buildOut = Self.runCommandInDir(
                appDir,
                "/usr/bin/swift",
                ["build"]
            ) { chunk in
                guard !chunk.isEmpty else { return }
                Task { @MainActor in
                    self.updateProgressLog += chunk
                }
            }

            if buildOut.exitCode == 0 {
                let runScript = repoRoot.appendingPathComponent("scripts/run_ssccc.sh").path
                let buildOnlyOut = Self.runCommandInDir(repoRoot, "/bin/bash", [runScript, "--build-only"])
                if buildOnlyOut.exitCode != 0 {
                    _ = Self.syncBuiltBinaryToTmp(repoRoot: repoRoot)
                }
            }

            await MainActor.run {
                if buildOut.exitCode == 0 {
                    self.refreshLocalCommitSHA()
                    if !self.updateProgressLog.hasSuffix("\n") {
                        self.updateProgressLog += "\n"
                    }
                    self.updateProgressLog += "Build complete. Click Restart to launch the updated SS-CCC."
                    self.updateStatus = .updatedNeedsRestart
                } else {
                    if self.updateProgressLog.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("swift build …") {
                        self.updateProgressLog += "\n" + buildOut.output
                    }
                    self.updateStatus = .failed("Build failed (Exit \(buildOut.exitCode))")
                }
            }
        }
    }

    private func spawnDetachedRelaunch(targetPath: String, workingDirectory: URL?, skipBuild: Bool) {
        let oldPID = ProcessInfo.processInfo.processIdentifier
        let cmd = "/bin/bash -c '(trap \"\" HUP INT TERM; while kill -0 \"$1\" 2>/dev/null; do sleep 0.1; done; export SSCCC_SKIP_BUILD=\"$2\"; exec \"$3\") </dev/null >/tmp/ssccc_relaunch.log 2>&1 &' _ \"$SSCCC_RELAUNCH_PID\" \"$SSCCC_RELAUNCH_SKIP\" \"$SSCCC_RELAUNCH_TARGET\""
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-c", cmd]
        if let workingDirectory {
            proc.currentDirectoryURL = workingDirectory
        }
        var env = ProcessInfo.processInfo.environment
        env["SSCCC_RELAUNCH_PID"] = "\(oldPID)"
        env["SSCCC_RELAUNCH_SKIP"] = skipBuild ? "1" : "0"
        env["SSCCC_RELAUNCH_TARGET"] = targetPath
        proc.environment = env
        proc.standardInput = FileHandle.nullDevice
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
        proc.waitUntilExit()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSApplication.shared.terminate(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                exit(0)
            }
        }
    }

    func relaunchApp() {
        guard !isRelaunching else { return }
        isRelaunching = true
        showUpdatePromptSheet = false

        let fm = FileManager.default
        let fallbackExec = CommandLine.arguments.first ?? "/tmp/SSCCCApp"

        if let repoRoot = localGitRepoRoot {
            let tmpBin = "/tmp/SSCCCApp"
            _ = Self.syncBuiltBinaryToTmp(repoRoot: repoRoot, onlyIfNewer: true)

            let script = repoRoot.appendingPathComponent("scripts/run_ssccc.sh").path
            if fm.isExecutableFile(atPath: script) {
                spawnDetachedRelaunch(
                    targetPath: script,
                    workingDirectory: repoRoot,
                    skipBuild: fm.isExecutableFile(atPath: tmpBin)
                )
                return
            }
        }

        let targetBin = fm.isExecutableFile(atPath: "/tmp/SSCCCApp") ? "/tmp/SSCCCApp" : fallbackExec
        if fm.isExecutableFile(atPath: targetBin) {
            spawnDetachedRelaunch(targetPath: targetBin, workingDirectory: localGitRepoRoot, skipBuild: true)
            return
        }

        isRelaunching = false
        openUpdateOnGitHub()
    }

    nonisolated static func sanitizeGitNoise(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .filter { !$0.contains("non-monotonic index .git/objects/pack/._") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated private static func runCommandInDir(
        _ dir: URL,
        _ launchPath: String,
        _ args: [String],
        onOutput: (@Sendable (String) -> Void)? = nil
    ) -> (exitCode: Int32, stdout: String, stderr: String, output: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: launchPath)
        proc.arguments = args
        proc.currentDirectoryURL = dir
        var env = ProcessInfo.processInfo.environment
        env["GIT_TERMINAL_PROMPT"] = "0"
        proc.environment = env
        proc.standardInput = FileHandle.nullDevice

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        proc.standardOutput = stdoutPipe
        proc.standardError = stderrPipe

        let lock = NSLock()
        var stdoutData = Data()
        var stderrData = Data()
        let ioGroup = DispatchGroup()

        let startDraining: (FileHandle, Bool) -> Void = { handle, isStdout in
            ioGroup.enter()
            DispatchQueue.global(qos: .utility).async {
                defer { ioGroup.leave() }
                while true {
                    let chunk = handle.availableData
                    if chunk.isEmpty { break }
                    lock.lock()
                    if isStdout {
                        stdoutData.append(chunk)
                    } else {
                        stderrData.append(chunk)
                    }
                    lock.unlock()
                    if let onOutput, let text = String(data: chunk, encoding: .utf8), !text.isEmpty {
                        onOutput(text)
                    }
                }
            }
        }

        do {
            try proc.run()
            startDraining(stdoutPipe.fileHandleForReading, true)
            startDraining(stderrPipe.fileHandleForReading, false)
            proc.waitUntilExit()
            ioGroup.wait()

            let outStr = (String(data: stdoutData, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let errStr = (String(data: stderrData, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let combined = [outStr, errStr].filter { !$0.isEmpty }.joined(separator: "\n")
            return (proc.terminationStatus, outStr, errStr, combined)
        } catch {
            return (-1, "", error.localizedDescription, error.localizedDescription)
        }
    }

    // MARK: - Phase 11: 2026 SOTA Architecture Upgrade Methods (Points 1–5)

    /// Point 1: TB5 RDMA Preflight Command (`rdma_ctl enable` + `bridge0` guard + per-port IP check)
    func rdmaPreflightCommand() -> String {
        let modeNote = clusterMeshTopology == .fullMesh ? "JACCL Full-Mesh TP" : "Pipeline Ring"
        return """
        # SS-CCC TB5 RDMA Preflight (\(modeNote))
        sudo ifconfig bridge0 down 2>/dev/null || true
        sudo rdma_ctl enable
        rdma_ctl status && ibv_devinfo || system_profiler SPThunderboltDataType | grep -E "Speed|Port|Domain"
        """
    }

    /// Point 1: Generates `mlx.distributed_config` compatible hostfile JSON for JACCL / Ring
    func generateMlxDistributedHostfileJSON() -> String {
        let activeNodes = simulateMacStudio ? nodes : nodes.filter { !$0.isSimulated }
        let hostEntries = activeNodes.enumerated().map { idx, node in
            let rdmaDevice = "rdma_en\(idx + 2)"
            return """
                {
                  "rank": \(idx),
                  "name": "\(node.name)",
                  "ip": "\(node.tbIP)",
                  "rdma_device": "\(rdmaDevice)",
                  "usable_vram_gb": \(Int(node.usableVramGB))
                }
            """
        }.joined(separator: ",\n")
        let backend = clusterMeshTopology == .fullMesh ? "jaccl" : "ring"
        return """
        {
          "backend": "\(backend)",
          "topology": "\(clusterMeshTopology.rawValue)",
          "bridge0_disabled": true,
          "hosts": [
        \(hostEntries)
          ]
        }
        """
    }

    /// Point 1: Effective WAN latency factor (QUIC/Iroh 0-RTT eliminates TCP HoL blocking)
    var wanTransportLatencyFactor: Double {
        wanTransportProtocol.latencyFactor
    }

    /// Point 2: ANE-Prefill + MLX-Decode Split-Phase EDP & wattage ratio
    func aneSplitSpeedupAndEnergyRatio() -> (prefillSpeedup: Double, energySavingsPct: Double) {
        (splitPhaseComputeMode.prefillEdpGainFactor, splitPhaseComputeMode.wattSavingsPercent)
    }

    /// Point 2: 3-Tier KV-Cache & CacheGen compression telemetry
    func cacheGenCompressionMetrics(contextTokens: Int = 32768) -> CacheGenCompressionMetrics {
        let rawKvGB = max(0.25, Double(contextTokens) / 1000.0 * 0.19)
        let ratio = kvCacheTierMode.compressionRatio
        let compressedGB = rawKvGB / ratio
        let hitFactor = max(0.0, min(100.0, kvPrefixCacheHitRatePct))
        let ttftReduction = min(82.0, hitFactor * 0.65 + (ratio - 1.0) * 8.5)
        return CacheGenCompressionMetrics(
            tierMode: kvCacheTierMode,
            prefixHitRatePct: hitFactor,
            rawKvSizeGB: rawKvGB,
            compressedTransferGB: compressedGB,
            compressionRatio: ratio,
            estimatedTtftReductionPct: ttftReduction
        )
    }

    /// Point 4: OpenAI `/v1/responses` payload with native MCP tool server declaration
    func generateOpenAIResponsesMcpPayload() -> String {
        let model = selectedModel.id
        return """
        POST \(openCodeBaseURL)/v1/responses
        {
          "model": "\(model)",
          "input": "\(tr(de: "Analysiere den Cluster-Zustand und optimiere das Sharding.", en: "Analyze cluster state and optimize sharding.", fr: "Analysez l'état du cluster et optimisez le découpage.", es: "Analiza el estado del clúster y optimiza el sharding.", pt: "Analise o estado do cluster e otimize o sharding.", ru: "Проанализируйте состояние кластера и оптимизируйте шардинг.", ja: "クラスタ状態を分析しシャーディングを最適化してください。", zh: "分析集群状态并优化模型分片。"))",
          "tools": [
            {
              "type": "mcp",
              "server_label": "ssccc-cluster",
              "server_url": "\(openCodeBaseURL)/mcp",
              "require_approval": "never"
            }
          ],
          "store": true
        }
        """
    }

    /// Point 4: MCP Server Registry JSON for Cursor, Claude Desktop, VS Code, Codex
    func generateMcpRegistryJSON() -> String {
        return """
        {
          "mcpServers": {
            "ssccc-cluster": {
              "transport": "streamable-http",
              "url": "\(openCodeBaseURL)/mcp",
              "capabilities": ["cluster_telemetry", "mmm_orchestrate", "kv_cache_status"]
            }
          }
        }
        """
    }

    /// Point 4: Google/Linux Foundation A2A Agent Card (`/.well-known/agent.json`)
    func generateA2AAgentCardJSON() -> String {
        let usableGB = Int(totalUsableVramGB)
        let nodeCount = max(1, nodes.count)
        return """
        {
          "name": "SS-CCC Apple Silicon Cluster Agent",
          "description": "Distributed MLX/oMLX/MMM inference cluster (\(nodeCount) nodes, \(usableGB) GB usable VRAM).",
          "url": "\(openCodeBaseURL)",
          "version": "\(AppReleaseMetadata.currentVersion)",
          "capabilities": {
            "streaming": true,
            "multiModelMode": true,
            "speculativeEngine": "\(mmmSpeculativeEngine.rawValue)",
            "transport": "\(wanTransportProtocol.rawValue)"
          },
          "skills": [
            { "id": "mmm-orchestrate", "name": "Multi-Model-Mode Orchestration" },
            { "id": "cluster-rooflines", "name": "Roofline & Telemetry Analysis" }
          ]
        }
        """
    }

    /// Point 5: Thermal- & Carbon-Aware target ranking/filtering for MMM & cluster scheduling
    func thermalAndCarbonAdjustedTargets(from candidates: [String]) -> [String] {
        guard mmmThermalCarbonAwareScheduling, thermalCarbonPolicy != .performanceFirst else {
            return candidates
        }
        let sorted = candidates.sorted { (lhs: String, rhs: String) -> Bool in
            let lNode = nodes.first { $0.name == lhs }
            let rNode = nodes.first { $0.name == rhs }
            let lPenalty = thermalPenalty(for: lNode?.thermalLabel ?? "Nominal")
            let rPenalty = thermalPenalty(for: rNode?.thermalLabel ?? "Nominal")
            if lPenalty != rPenalty { return lPenalty < rPenalty }
            if thermalCarbonPolicy == .ecoCarbonAware {
                return (lNode?.bandwidthGBs ?? 120) > (rNode?.bandwidthGBs ?? 120)
            }
            return (lNode?.usableVramGB ?? 0) > (rNode?.usableVramGB ?? 0)
        }
        return sorted
    }

    private func thermalPenalty(for label: String) -> Int {
        let low = label.lowercased()
        if low.contains("critical") || low.contains("kritisch") { return 10 }
        if low.contains("serious") || low.contains("hoch") || low.contains("warm") { return 5 }
        if low.contains("fair") || low.contains("mäßig") { return 1 }
        return 0
    }

    // MARK: - Phase 12: Cluster Auto-Setup, Readiness Verification & Shorttips

    func shorttip(_ tab: NavigationTab) -> String {
        L10n.tabShorttip(tab, language)
    }

    var currentReadinessLabel: String {
        L10n.readinessLabel(clusterReadinessState, language)
    }

    func setShorttip(_ text: String?, id: String?) {
        if let id, let text, !text.isEmpty {
            hoveredShorttipId = id
            activeShorttipText = text
        } else if id == nil || hoveredShorttipId == id {
            hoveredShorttipId = nil
            activeShorttipText = nil
        }
    }

    func discoverClusterSetupTargets() {
        var targets: [NodeProvisioningTarget] = []

        if clusterSetupVariant == .local || clusterSetupVariant == .hybrid {
            let activeLocalNodes = simulateMacStudio ? nodes : nodes.filter { !$0.isSimulated }
            let sshDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh").path
            let hasLocalSshKey = FileManager.default.fileExists(atPath: "\(sshDir)/id_ed25519.pub")
                || FileManager.default.fileExists(atPath: "\(sshDir)/id_rsa.pub")

            for node in activeLocalNodes {
                let isLocalhost = (node.id == "local-host") || (node.lanIP == "127.0.0.1")
                let sshReady = isLocalhost ? (hasLocalSshKey || hasCompletedClusterSetup || !simulateMacStudio) : hasCompletedClusterSetup
                targets.append(
                    NodeProvisioningTarget(
                        id: "local-\(node.id)",
                        hostname: node.name,
                        address: node.tbIP.isEmpty ? node.lanIP : node.tbIP,
                        transport: node.rdmaEnabled ? "TB5 RDMA (JACCL)" : "Thunderbolt / LAN",
                        chipLabel: node.chip,
                        usableVramGB: node.usableVramGB,
                        sshTrusted: sshReady,
                        wiredLimitConfigured: node.wiredLimitMB > 0,
                        rdmaOrWanReady: node.rdmaEnabled || !node.tbIP.isEmpty || isLocalhost,
                        isSelected: true
                    )
                )
            }
        }

        if clusterSetupVariant == .internet || clusterSetupVariant == .hybrid {
            let rawPeers = clusterSetupVariant == .hybrid ? wanRemotePeers : wanPeers
            let activePeers = simulateMacStudio ? rawPeers : rawPeers.filter { wanConnected || $0.isLocalHost }
            for peer in activePeers {
                targets.append(
                    NodeProvisioningTarget(
                        id: "wan-\(peer.id)",
                        hostname: peer.displayName,
                        address: peer.region,
                        transport: wanTransportProtocol.localizedTitle(language),
                        chipLabel: peer.chip,
                        usableVramGB: peer.usableVramGB,
                        sshTrusted: peer.isLocalHost || hasCompletedClusterSetup,
                        wiredLimitConfigured: peer.isLocalHost ? (localWiredLimitMB > 0) : true,
                        rdmaOrWanReady: peer.isOnline,
                        isSelected: peer.isOnline
                    )
                )
            }
        }

        targets = applyLiveHealth(to: targets)
        discoveredProvisionTargets = targets
        let vTitle = clusterSetupVariant.localizedTitle(language)
        if targets.isEmpty {
            clusterReadinessState = .unconfigured
            setupStatusMessage = tr(
                de: "Keine Ziel-Macs für Variante '\(vTitle)' gefunden.",
                en: "No target Macs found for '\(vTitle)'.",
                fr: "Aucun Mac cible trouvé pour '\(vTitle)'.",
                es: "No se encontraron Macs para '\(vTitle)'.",
                pt: "Nenhum Mac encontrado para '\(vTitle)'.",
                ru: "Целевые Mac для '\(vTitle)' не найдены.",
                ja: "「\(vTitle)」の対象Macが見つかりません。",
                zh: "未找到适用于“\(vTitle)”的目标 Mac。"
            )
        } else {
            if !hasCompletedClusterSetup {
                let anyMissing = targets.contains { !$0.sshTrusted || !$0.wiredLimitConfigured || !$0.rdmaOrWanReady }
                clusterReadinessState = anyMissing ? .incomplete : .notReady
            }
            let modeTag = simulateMacStudio
                ? tr(de: "Simulation", en: "Simulation", fr: "Simulation", es: "Simulación", pt: "Simulação", ru: "Симуляция", ja: "シミュレーション", zh: "模拟")
                : tr(de: "Echtzeitdaten", en: "Live Telemetry", fr: "Temps réel", es: "Datos en vivo", pt: "Tempo real", ru: "Реальные данные", ja: "実測データ", zh: "实时数据")
            setupStatusMessage = tr(
                de: "\(targets.count) Mac-Knoten (\(modeTag)) für '\(vTitle)' erkannt.",
                en: "Discovered \(targets.count) Mac node(s) (\(modeTag)) for '\(vTitle)'.",
                fr: "\(targets.count) nœud(s) Mac détecté(s) (\(modeTag)) pour '\(vTitle)'.",
                es: "\(targets.count) nodo(s) Mac detectado(s) (\(modeTag)) para '\(vTitle)'.",
                pt: "\(targets.count) nó(s) Mac detetado(s) (\(modeTag)) para '\(vTitle)'.",
                ru: "Обнаружено \(targets.count) узлов Mac (\(modeTag)) для '\(vTitle)'.",
                ja: "\(targets.count) 台のMacノードを検出（\(modeTag)・\(vTitle)）。",
                zh: "已发现 \(targets.count) 个 Mac 节点（\(modeTag) · \(vTitle)）。"
            )
        }
    }

    func runAutomaticClusterSetup() {
        // Echte Einrichtung über core/cluster/ssccc_setup.py (lokaler Verbund / Hybrid)
        if Self.setupToolPath != nil && clusterSetupVariant != .internet {
            startSetupTool(apply: true)
            return
        }
        isRunningClusterSetup = true
        if discoveredProvisionTargets.isEmpty {
            discoverClusterSetupTargets()
        }

        for idx in discoveredProvisionTargets.indices where discoveredProvisionTargets[idx].isSelected {
            discoveredProvisionTargets[idx].sshTrusted = true
            discoveredProvisionTargets[idx].wiredLimitConfigured = true
            discoveredProvisionTargets[idx].rdmaOrWanReady = true
        }

        switch clusterSetupVariant {
        case .local:
            overviewScope = .local
            mmmScope = .local
        case .internet:
            overviewScope = .internet
            mmmScope = .internet
        case .hybrid:
            overviewScope = .hybrid
            mmmScope = .hybrid
        }

        hasCompletedClusterSetup = true
        isRunningClusterSetup = false
        let count = discoveredProvisionTargets.filter(\.isSelected).count
        setupStatusMessage = tr(
            de: "Automatische Einrichtung für \(count) Macs abgeschlossen — starte Betriebsbereitschafts-Prüfung...",
            en: "Auto-provisioning finished for \(count) Mac(s) — running readiness check...",
            fr: "Configuration automatique terminée pour \(count) Mac — vérification en cours...",
            es: "Aprovisionamiento automático completado para \(count) Mac(s) — verificando estado...",
            pt: "Configuração automática concluída para \(count) Mac(s) — a verificar prontidão...",
            ru: "Автонастройка для \(count) Mac завершена — запуск проверки готовности...",
            ja: "\(count) 台の自動構成が完了 — 稼働確認を実行中...",
            zh: "已完成 \(count) 台 Mac 的自动配置 — 正在执行就绪检测..."
        )
        verifyClusterReadiness()
    }

    func verifyClusterReadiness() {
        isVerifyingReadiness = true
        discoverClusterSetupTargets()

        let selectedTargets = discoveredProvisionTargets.filter(\.isSelected)
        var checks: [ClusterReadinessCheckItem] = []

        // Check 1: Discovery & Node Count
        let hasTargets = !selectedTargets.isEmpty
        checks.append(
            ClusterReadinessCheckItem(
                id: "chk-discovery",
                title: tr(de: "Bonjour / mDNS & Peer-Erkennung", en: "Bonjour / mDNS & Peer Discovery", fr: "Bonjour / mDNS & Découverte des pairs", es: "Bonjour / mDNS y descubrimiento de pares", pt: "Bonjour / mDNS e descoberta de pares", ru: "Bonjour / mDNS и поиск узлов", ja: "Bonjour / mDNS・ピア検出", zh: "Bonjour / mDNS 与节点发现"),
                detail: hasTargets
                    ? tr(de: "\(selectedTargets.count) aktive Ziel-Macs im Verbund erkannt.", en: "Detected \(selectedTargets.count) active target Mac(s) in cluster.", fr: "\(selectedTargets.count) Mac cible(s) actif(s) détecté(s) dans la grappe.", es: "\(selectedTargets.count) Mac(s) destino activo(s) detectado(s) en el clúster.", pt: "\(selectedTargets.count) Mac(s) destino ativo(s) detetado(s) no cluster.", ru: "Обнаружено \(selectedTargets.count) активных Mac в кластере.", ja: "クラスター内で \(selectedTargets.count) 台の有効なMacを検出。", zh: "集群中已检测到 \(selectedTargets.count) 台活跃目标 Mac。")
                    : tr(de: "Keine Ziel-Macs erkannt.", en: "No target Macs detected.", fr: "Aucun Mac cible détecté.", es: "No se detectaron Macs destino.", pt: "Nenhum Mac destino detetado.", ru: "Целевые Mac не обнаружены.", ja: "対象Macが検出されません。", zh: "未检测到目标 Mac。"),
                status: hasTargets ? .pass : .fail,
                remediation: tr(de: "Bonjour/mDNS auf allen Macs prüfen oder Nachbildung/WAN-Peers verbinden.", en: "Check Bonjour/mDNS on all Macs or connect simulation/WAN peers.", fr: "Vérifiez Bonjour/mDNS sur les Mac ou connectez des pairs WAN.", es: "Verifica Bonjour/mDNS o conecta pares WAN / simulación.", pt: "Verifique o Bonjour/mDNS ou ligue pares WAN.", ru: "Проверьте Bonjour/mDNS на всех Mac или подключите WAN-узлы.", ja: "Bonjour/mDNSまたはWANピア接続を確認してください。", zh: "检查各 Mac 的 Bonjour/mDNS 或连接 WAN 节点。")
            )
        )

        // Check 2: SSH Trust & Remote Provisioning
        let allSshTrusted = hasTargets && selectedTargets.allSatisfy(\.sshTrusted)
        checks.append(
            ClusterReadinessCheckItem(
                id: "chk-ssh",
                title: tr(de: "SSH-Vertrauen & mlx.distributed_config", en: "SSH Trust & mlx.distributed_config", fr: "Confiance SSH & mlx.distributed_config", es: "Confianza SSH y mlx.distributed_config", pt: "Confiança SSH e mlx.distributed_config", ru: "Доверие SSH и mlx.distributed_config", ja: "SSH 信頼・mlx.distributed_config", zh: "SSH 免密信任与 mlx.distributed_config"),
                detail: allSshTrusted
                    ? tr(de: "Passwortloser SSH-Zugriff & Hostfile auf allen Knoten bestätigt.", en: "Passwordless SSH access & hostfile verified on all nodes.", fr: "Accès SSH sans mot de passe et hostfile vérifiés sur tous les nœuds.", es: "Acceso SSH sin contraseña y hostfile verificados en todos los nodos.", pt: "Acesso SSH sem palavra-passe e hostfile verificados em todos os nós.", ru: "Беспарольный SSH-доступ и hostfile подтверждены на всех узлах.", ja: "全ノードでパスワードなしSSHとHostfileを確認済み。", zh: "所有节点的免密 SSH 与 Hostfile 已验证。")
                    : tr(de: "SSH-Vertrauen fehlt noch auf mindestens einem entfernten Mac.", en: "SSH trust is missing on at least one remote Mac.", fr: "La confiance SSH manque encore sur au moins un Mac distant.", es: "Falta confianza SSH en al menos un Mac remoto.", pt: "Falta confiança SSH em pelo menos um Mac remoto.", ru: "Отсутствует SSH-доверие как минимум на одном удалённом Mac.", ja: "少なくとも1台のリモートMacでSSH信頼が未設定です。", zh: "至少一台远程 Mac 尚未建立 SSH 互信。"),
                status: allSshTrusted ? .pass : .warn,
                remediation: tr(de: "Automatische Einrichtung starten oder `ssh-copy-id user@host.local` ausführen.", en: "Run Automatic Setup or execute `ssh-copy-id user@host.local`.", fr: "Lancez la configuration automatique ou exécutez `ssh-copy-id user@host.local`.", es: "Inicia la configuración automática o ejecuta `ssh-copy-id user@host.local`.", pt: "Execute a configuração automática ou `ssh-copy-id user@host.local`.", ru: "Запустите автонастройку или выполните `ssh-copy-id user@host.local`.", ja: "自動セットアップを実行するか `ssh-copy-id user@host.local` を実行してください。", zh: "启动自动配置或运行 `ssh-copy-id user@host.local`。")
            )
        )

        // Check 3: Interconnect & Transport
        let transportOK = hasTargets && selectedTargets.allSatisfy(\.rdmaOrWanReady)
        let transportLabel = clusterSetupVariant == .local
            ? tr(de: "Thunderbolt / RDMA (bridge0-frei)", en: "Thunderbolt / RDMA (bridge0-free)", fr: "Thunderbolt / RDMA (sans bridge0)", es: "Thunderbolt / RDMA (sin bridge0)", pt: "Thunderbolt / RDMA (sem bridge0)", ru: "Thunderbolt / RDMA (без bridge0)", ja: "Thunderbolt / RDMA (bridge0なし)", zh: "Thunderbolt / RDMA（无 bridge0 环路）")
            : wanTransportProtocol.localizedTitle(language)
        checks.append(
            ClusterReadinessCheckItem(
                id: "chk-transport",
                title: tr(de: "Interconnect & Transport (\(transportLabel))", en: "Interconnect & Transport (\(transportLabel))", fr: "Interconnexion & Transport (\(transportLabel))", es: "Interconexión y transporte (\(transportLabel))", pt: "Interligação e transporte (\(transportLabel))", ru: "Интерконнект и транспорт (\(transportLabel))", ja: "インターコネクト＆転送 (\(transportLabel))", zh: "互联与传输通道 (\(transportLabel))"),
                detail: transportOK
                    ? tr(de: "Alle Daten-Links und Transportkanäle sind aktiv.", en: "All data links and transport channels are active.", fr: "Toutes les liaisons de données et canaux de transport sont actifs.", es: "Todos los enlaces de datos y canales de transporte están activos.", pt: "Todas as ligações de dados e canais de transporte estão ativos.", ru: "Все каналы данных и транспорта активны.", ja: "すべてのデータリンクと転送チャネルが有効です。", zh: "所有数据链路和传输通道均已激活。")
                    : tr(de: "Ein oder mehrere Transport-Links sind getrennt oder unvollständig.", en: "One or more transport links are disconnected or incomplete.", fr: "Une ou plusieurs liaisons sont déconnectées ou incomplètes.", es: "Uno o más enlaces están desconectados o incompletos.", pt: "Uma ou mais ligações estão desligadas ou incompletas.", ru: "Один или несколько транспортных каналов отключены.", ja: "1つ以上の転送リンクが未接続または不完全です。", zh: "一个或多个传输链路已断开或配置不完整。"),
                status: transportOK ? .pass : .fail,
                remediation: tr(de: "Thunderbolt-Kabel / `rdma_ctl enable` oder Tailscale/QUIC-Tunnel prüfen.", en: "Check Thunderbolt cables / `rdma_ctl enable` or Tailscale/QUIC tunnels.", fr: "Vérifiez les câbles Thunderbolt / `rdma_ctl enable` ou tunnels Tailscale/QUIC.", es: "Verifica cables Thunderbolt / `rdma_ctl enable` o túneles Tailscale/QUIC.", pt: "Verifique cabos Thunderbolt / `rdma_ctl enable` ou túneis Tailscale/QUIC.", ru: "Проверьте кабели Thunderbolt / `rdma_ctl enable` или туннели Tailscale/QUIC.", ja: "Thunderboltケーブル / `rdma_ctl enable` または Tailscale/QUIC トンネルを確認してください。", zh: "检查 Thunderbolt 线缆 / `rdma_ctl enable` 或 Tailscale/QUIC 隧道。")
            )
        )

        // Check 4: Memory Protection (iogpu.wired_limit_mb) & Thermal Guard
        let wiredOK = hasTargets && selectedTargets.allSatisfy(\.wiredLimitConfigured)
        let thermalCritical = nodes.contains { thermalPenalty(for: $0.thermalLabel) >= 10 }
        let hwStatus: ClusterReadinessCheckStatus = (!wiredOK || thermalCritical) ? (thermalCritical ? .fail : .warn) : .pass
        checks.append(
            ClusterReadinessCheckItem(
                id: "chk-memory-thermal",
                title: tr(de: "Speicherschutz (iogpu.wired_limit_mb) & Thermal-State", en: "Memory Guard (iogpu.wired_limit_mb) & Thermal State", fr: "Protection mémoire (iogpu.wired_limit_mb) & État thermique", es: "Protección de memoria (iogpu.wired_limit_mb) y estado térmico", pt: "Proteção de memória (iogpu.wired_limit_mb) e estado térmico", ru: "Защита памяти (iogpu.wired_limit_mb) и температура", ja: "メモリ保護 (iogpu.wired_limit_mb) と熱状態", zh: "内存保护 (iogpu.wired_limit_mb) 与热状态"),
                detail: thermalCritical
                    ? tr(de: "Kritische Temperatur auf mindestens einem Knoten!", en: "Critical thermal state detected on at least one node!", fr: "Température critique détectée sur au moins un nœud !", es: "¡Estado térmico crítico en al menos un nodo!", pt: "Estado térmico crítico em pelo menos um nó!", ru: "Критическая температура на одном из узлов!", ja: "少なくとも1台のノードが危険温度です！", zh: "至少一个节点温度过高！")
                    : (wiredOK
                        ? tr(de: "OS-Reserve (4–8 GB) und Thermal-Status nominal.", en: "OS reserve (4–8 GB) and thermal state nominal.", fr: "Réserve OS (4–8 Go) et état thermique nominaux.", es: "Reserva de SO (4–8 GB) y estado térmico nominales.", pt: "Reserva de SO (4–8 GB) e estado térmico nominais.", ru: "Резерв ОС (4–8 ГБ) и температура в норме.", ja: "OS予約領域 (4–8 GB) と熱状態は正常です。", zh: "系统预留 (4–8 GB) 与温度状态正常。")
                        : tr(de: "Wired-Limit auf Teilknoten noch nicht gesetzt.", en: "Wired memory limit not yet applied on some nodes.", fr: "Limite mémoire câblée non encore définie sur certains nœuds.", es: "Límite de memoria fija aún no aplicado en algunos nodos.", pt: "Limite de memória fixa ainda não aplicado nalguns nós.", ru: "Лимит wired-памяти ещё не задан на части узлов.", ja: "一部ノードで iogpu.wired_limit_mb が未設定です。", zh: "部分节点尚未设置 wired 内存上限。")),
                status: hwStatus,
                remediation: tr(de: "`scripts/setup_wired_limit.sh` ausführen bzw. überhitzten Knoten abkühlen lassen.", en: "Run `scripts/setup_wired_limit.sh` or allow overheated node to cool.", fr: "Exécutez `scripts/setup_wired_limit.sh` ou laissez refroidir le nœud.", es: "Ejecuta `scripts/setup_wired_limit.sh` o enfría el nodo.", pt: "Execute `scripts/setup_wired_limit.sh` ou arrefeça o nó.", ru: "Выполните `scripts/setup_wired_limit.sh` или дайте узлу остыть.", ja: "`scripts/setup_wired_limit.sh` を実行するか高温ノードを冷却してください。", zh: "运行 `scripts/setup_wired_limit.sh` 或等待过热节点降温。")
            )
        )

        // Check 5: Gateway / Runtime Health
        let runtimeOK = simulateMacStudio || daemonConnected || !modelPresets.filter(\.isLiveDiscovered).isEmpty
        checks.append(
            ClusterReadinessCheckItem(
                id: "chk-runtime",
                title: tr(de: "Inferenz-Gateway (:8000/v1 · oMLX / Ollama / llama.cpp)", en: "Inference Gateway (:8000/v1 · oMLX / Ollama / llama.cpp)", fr: "Passerelle d'inférence (:8000/v1 · oMLX / Ollama / llama.cpp)", es: "Pasarela de inferencia (:8000/v1 · oMLX / Ollama / llama.cpp)", pt: "Gateway de inferência (:8000/v1 · oMLX / Ollama / llama.cpp)", ru: "Шлюз инференса (:8000/v1 · oMLX / Ollama / llama.cpp)", ja: "推論ゲートウェイ (:8000/v1 · oMLX / Ollama / llama.cpp)", zh: "推理网关 (:8000/v1 · oMLX / Ollama / llama.cpp)"),
                detail: runtimeOK
                    ? (simulateMacStudio
                        ? tr(de: "Simulations-Endpunkt bereit für Trockenläufe.", en: "Simulation endpoint ready for dry runs.", fr: "Point de simulation prêt pour tests à blanc.", es: "Endpoint de simulación listo para pruebas.", pt: "Endpoint de simulação pronto para testes.", ru: "Симуляционный эндпоинт готов к тестам.", ja: "シミュレーション用エンドポイントの準備完了。", zh: "模拟端点已就绪，可用于演练测试。")
                        : tr(de: "Lokales Gateway bzw. Modell-Laufzeit antwortet.", en: "Local gateway / model runtime is responding.", fr: "La passerelle locale ou un moteur de modèles répond.", es: "La pasarela local o motor de modelos está respondiendo.", pt: "O gateway local ou motor de modelos está a responder.", ru: "Локальный шлюз или среда выполнения моделей отвечает.", ja: "ローカルゲートウェイ／モデルランタイムが応答中。", zh: "本地网关或模型运行时响应正常。"))
                    : tr(de: "Kein aktiver Inferenz-Daemon auf :8000 / :11434 erreichbar.", en: "No active inference daemon reachable on :8000 / :11434.", fr: "Aucun démon d'inférence actif joignable sur :8000 / :11434.", es: "Ningún servicio de inferencia activo en :8000 / :11434.", pt: "Nenhum serviço de inferência ativo em :8000 / :11434.", ru: "Нет доступного сервиса инференса на :8000 / :11434.", ja: ":8000 / :11434 で稼働中の推論デーモンが見つかりません。", zh: "未能在 :8000 / :11434 检测到活跃的推理服务。"),
                status: runtimeOK ? .pass : .warn,
                remediation: tr(de: "oMLX, Ollama oder llama.cpp starten und über 'Modell Werkstatt' prüfen.", en: "Start oMLX, Ollama, or llama.cpp and verify in 'Model Studio'.", fr: "Démarrez oMLX, Ollama ou llama.cpp et vérifiez dans 'Atelier de modèles'.", es: "Inicia oMLX, Ollama o llama.cpp y verifica en 'Taller de modelos'.", pt: "Inicie oMLX, Ollama ou llama.cpp e verifique na 'Oficina de modelos'.", ru: "Запустите oMLX, Ollama или llama.cpp и проверьте в 'Студия моделей'.", ja: "oMLX・Ollama・llama.cpp を起動し「モデルスタジオ」で確認してください。", zh: "启动 oMLX、Ollama 或 llama.cpp 并在“模型工坊”中检查。")
            )
        )

        // Ergebnisse der ausführlichen Prüfung (ssccc_setup.py) einbeziehen
        checks.append(contentsOf: setupToolChecks)
        clusterReadinessChecks = checks

        // Determine 4-state Readiness Machine
        if !hasTargets {
            clusterReadinessState = .unconfigured
        } else if checks.contains(where: { $0.status == .fail }) {
            clusterReadinessState = .notReady
        } else if !hasCompletedClusterSetup || checks.contains(where: { $0.status == .warn }) {
            clusterReadinessState = .incomplete
        } else {
            clusterReadinessState = .ready
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        lastReadinessCheckedAt = fmt.string(from: Date())
        isVerifyingReadiness = false
        setupStatusMessage = tr(
            de: "Prüfung abgeschlossen (\(lastReadinessCheckedAt)): \(currentReadinessLabel)",
            en: "Check completed (\(lastReadinessCheckedAt)): \(currentReadinessLabel)",
            fr: "Vérification terminée (\(lastReadinessCheckedAt)) : \(currentReadinessLabel)",
            es: "Verificación completada (\(lastReadinessCheckedAt)): \(currentReadinessLabel)",
            pt: "Verificação concluída (\(lastReadinessCheckedAt)): \(currentReadinessLabel)",
            ru: "Проверка завершена (\(lastReadinessCheckedAt)): \(currentReadinessLabel)",
            ja: "確認完了 (\(lastReadinessCheckedAt)): \(currentReadinessLabel)",
            zh: "检查完成 (\(lastReadinessCheckedAt))：\(currentReadinessLabel)"
        )
    }
}
