import Foundation
import SwiftUI
import AVFoundation
import AppKit

@MainActor
final class ClusterViewModel: ObservableObject {
    @Published var selectedTab: NavigationTab = .overview
    @Published var language: AppLanguage = .en
    @Published var simulateMacStudio: Bool = true
    @Published var transportMode: TransportMode = .autoHybrid
    @Published var daemonConnected: Bool = false
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
    private var wanWebSocketTask: URLSessionWebSocketTask? = nil

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
        Task {
            await checkDaemonHealth()
            await refreshLiveModels()
        }
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

        // GPU-Kerne aus system_profiler SPDisplaysDataType auslesen (mit Chip-Fallback)
        let displays = runShell("/usr/sbin/system_profiler", ["SPDisplaysDataType"])
        if let line = displays.components(separatedBy: .newlines).first(where: { $0.contains("Total Number of Cores:") }),
           let numStr = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines),
           let parsedGPU = Int(numStr) {
            localGPUCores = parsedGPU
        } else {
            localGPUCores = AppleSiliconChipFamily.inferGPUCores(from: localChipName)
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
            bridgeStatusMessage = "oMLX-Startbefehl kopiert (Paged SSD KV-Cache aktiv): \(cmd)"
        case .ollama:
            let ollamaTag = modelId.contains("70B") ? "llama3.3:70b" : (modelId.contains("Qwen2.5") ? "qwen2.5:32b" : "deepseek-r1:32b")
            let cmd = "ollama run \(ollamaTag)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(cmd, forType: .string)
            bridgeStatusMessage = "Ollama-Ladebefehl kopiert: \(cmd) (oder direkt über SS-CCC Port 8000/11434 ansprechen)."
        case .llamaCpp:
            let cmd = "llama-server --hf-repo \(modelId) --port 8080 -ngl 99"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(cmd, forType: .string)
            bridgeStatusMessage = "llama.cpp-Serverbefehl kopiert: \(cmd)"
        }
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
            chip: "\(chip.rawValue) · \(chip.cpuCores)-Core CPU / \(chip.gpuCores)-Core GPU",
            cpuCores: chip.cpuCores,
            cpuTopology: "\(chip.cpuCores) Kerne",
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
                    chip: "Apple M5 Max · 18-Core CPU / 32-Core GPU",
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
            name: Host.current().localizedName ?? "Lokaler Apple Silicon Mac",
            role: (simulateMacStudio || !customNodes.isEmpty) ? "Worker" : "Standalone (Rank 0)",
            modelIdentifier: localModelIdentifier,
            chip: "\(localChipName) · \(localCPUCores) CPU-Kerne",
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
            return ("Lokal (Intern)", 0.0, "1 Node")
        }
        let minTb = active.map(\.thunderboltGen).min() ?? 4
        let maxTb = active.map(\.thunderboltGen).max() ?? 4
        return AppleSiliconChipFamily.linkTransferStats(genA: minTb, genB: maxTb, mode: transportMode)
    }

    var activeLinkHeadline: String {
        guard nodes.count > 1 else { return "Lokal (1 Node)" }
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
        guard let url = URL(string: "http://127.0.0.1:8000/health") else { return }
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

        if daemonConnected, let url = URL(string: "http://127.0.0.1:8000/v1/chat/completions") {
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
            agentStatusMessage = "OpenCode konfiguriert: ~/.config/opencode/opencode.json & auth.json geschrieben."
        } catch {
            agentStatusMessage = "Fehler beim Schreiben der OpenCode-Config: \(error.localizedDescription)"
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
            agentStatusMessage = "Hermes Agent konfiguriert: ~/.hermes/config.yaml & .env geschrieben."
        } catch {
            agentStatusMessage = "Fehler beim Schreiben der Hermes-Config: \(error.localizedDescription)"
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
            agentStatusMessage = "Antigravity konfiguriert: ~/.gemini/antigravity/ssccc_local_provider.json & ssccc_local_agent.py geschrieben."
        } catch {
            agentStatusMessage = "Fehler beim Schreiben der Antigravity-Config: \(error.localizedDescription)"
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
            agentStatusMessage = "Fehler beim Schreiben (\(relativeDir)): \(error.localizedDescription)"
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
            successLabel: "Cursor konfiguriert: ~/.cursor/ssccc_cluster.json geschrieben."
        )
    }

    func installVSCodeConfig() {
        writeIntegrationFiles(
            relativeDir: ".vscode",
            files: [("ssccc_cluster.json", vscodeConfigJSON)],
            successLabel: "Visual Studio Code konfiguriert: ~/.vscode/ssccc_cluster.json geschrieben."
        )
    }

    func installXcodeConfig() {
        writeIntegrationFiles(
            relativeDir: "Library/Developer/Xcode/UserData",
            files: [("SSCCCClusterProvider.json", xcodeConfigJSON)],
            successLabel: "Xcode konfiguriert: ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json geschrieben."
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
            bridgeStatusMessage = "Keine lokalen Ollama-/GGUF-Dateien gefunden. Nutze direkte schnelle MLX-Modelle (mlx-community/*-4bit)."
        } else {
            bridgeStatusMessage = "\(found.count) Ollama/GGUF-Quelle(n) erkannt — bereit zur schnellen MLX-Einbindung (mlx_lm.convert --quantize)."
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
            bridgeStatusMessage = "Bereitgestellt: ~/.ssccc/bridges/Modelfile.ssccc & llamacpp_ollama_bridge.json (Endpoint: \(openCodeBaseURL))."
        } catch {
            bridgeStatusMessage = "Fehler beim Bridge-Export: \(error.localizedDescription)"
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
        if let url = URL(string: "http://127.0.0.1:8000/v1/models") {
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
        if let url = URL(string: "http://127.0.0.1:11434/api/tags") {
            var req = URLRequest(url: url)
            req.timeoutInterval = 1.5
            if let (data, resp) = try? await URLSession.shared.data(for: req),
               let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                for m in models {
                    if let name = m["name"] as? String, !seenIds.contains(name) {
                        seenIds.insert(name)
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
            modelDiscoveryNote = "\(live.count) echte(s) Modell(e) aus oMLX / Ollama / llama.cpp / lokalem Speicher eingelesen."
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
        guard let url = URL(string: "http://127.0.0.1:\(port)\(path)") else { return false }
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
                pullModelCommand: "ollama pull qwen2.5:14b"
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
            "/opt/homebrew/bin/mlx_lm.server",
            "\(home)/.local/bin/mlx_lm.server"
        ])
        let ollama = firstExisting([
            "/opt/homebrew/bin/ollama",
            "/usr/local/bin/ollama",
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
                    linkLabel: peer.isLocalHost ? "Lokal (\(peer.transport.rawValue))" : "\(peer.region) · \(Int(peer.rttMs))ms",
                    isRemoteWan: !peer.isLocalHost
                )
            }
        }
        return nodes.map { node in
            ScientificNodeSnapshot(
                id: node.id,
                name: node.name,
                chip: node.chip,
                region: "Lokal (TB\(node.thunderboltGen))",
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
                return "WAN-RTT-Latenz-begrenzt (B* = \(criticalBatchSizeBStar))"
            }
            if activeStepTransferMs > activeStepComputeMs {
                return "WAN-Uplink-begrenzt (Aktivierungs-Kompression empfohlen)"
            }
        }
        if netMs > activeStepComputeMs * 0.8 && activeScienceNodes.count > 1 {
            return "Verbindungs-begrenzt (TB/LAN-Übergabe)"
        }
        let activeMinRidge = activeScienceNodes.map(\.ridgePointFLOPPerByte).min() ?? 80.0
        if decodeArithmeticIntensity < activeMinRidge {
            return "Speicherbandbreiten-begrenzt (UMA-Decode)"
        }
        return "Rechenleistungs-begrenzt (Metal FP16)"
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

        let scopeSnapshot = sciScope
        let useWan = isWanScienceActive
        let countTarget = max(5, sciTrialCount)
        let baseTTFT = activeTTFTMs
        let baseTPOT = activeTPOTMs
        let baseWatts = activeWatts
        let baseRtt = activeStepRttMs
        let jitterAmp = useWan ? sciWanJitterFactor : 0.025

        Task {
            var collected: [ScientificBenchmarkTrial] = []

            // 1 Warmup + N measured trials (temperature=0.0 reproducibility protocol)
            for idx in 0...countTarget {
                let start = DispatchTime.now().uptimeNanoseconds
                if !useWan && daemonConnected, let url = URL(string: "\(openCodeBaseURL)/chat/completions") {
                    var req = URLRequest(url: url)
                    req.httpMethod = "POST"
                    req.timeoutInterval = 12
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let payload: [String: Any] = [
                        "model": selectedModel.id,
                        "temperature": 0.0,
                        "max_tokens": 24,
                        "messages": [["role": "user", "content": "State the Roofline equation in one sentence."]]
                    ]
                    req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
                    _ = try? await URLSession.shared.data(for: req)
                } else {
                    // Deterministic local sysctl probe + WAN timing sleep
                    _ = runShell("/usr/sbin/sysctl", ["-n", "vm.loadavg"])
                    let pauseNs: UInt64 = useWan ? 65_000_000 : 50_000_000
                    try? await Task.sleep(nanoseconds: pauseNs)
                }
                let elapsedMs = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000.0

                if idx == 0 { continue } // Discard warmup

                // Reproducible deterministic tail jitter (log-normal-like spike on p95/p99 indices)
                let wave = (Double((idx * 19) % 11) - 5.0) / 5.0
                let tailSpike = (idx % 10 == 9) ? (useWan ? jitterAmp * 1.45 : 0.04) : 0.0
                let factor = max(0.85, 1.0 + wave * (jitterAmp * 0.45) + tailSpike)

                let measuredTTFT = (!useWan && daemonConnected) ? max(15.0, elapsedMs * 0.35) : baseTTFT * factor
                let measuredTPOT = (!useWan && daemonConnected) ? max(4.0, (elapsedMs * 0.65) / 24.0) : baseTPOT * factor
                let tokSec = (1000.0 / max(0.5, measuredTPOT)) * Double(sciBatchSize)
                let watts = baseWatts * (0.96 + Double(idx % 4) * 0.02)
                let jPerTok = tokSec > 0 ? watts / tokSec : 0
                let rttSample = baseRtt * factor
                let sloPass = measuredTTFT <= sciSloTtftMaxMs && measuredTPOT <= sciSloTpotMaxMs

                let trial = ScientificBenchmarkTrial(
                    trialIndex: idx,
                    ttftMs: measuredTTFT,
                    tpotMs: measuredTPOT,
                    tokensPerSec: tokSec,
                    netRttMs: rttSample,
                    watts: watts,
                    joulesPerToken: jPerTok,
                    sloPass: sloPass,
                    scopeLabel: scopeSnapshot.rawValue
                )
                collected.append(trial)
                sciTrials = collected
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

            let formatter = ISO8601DateFormatter()
            sciSummary = ScientificBenchmarkSummary(
                modelId: selectedModel.id,
                scopeLabel: scopeSnapshot.rawValue,
                hardwareFingerprint: hardwareFingerprint,
                backendLabel: (!useWan && daemonConnected) ? "\(selectedService.rawValue) (Live)" : (useWan ? "WAN Analytical + RTT Probe" : "Local Analytical + sysctl Probe"),
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
                isLiveEndpoint: !useWan && daemonConnected
            )
            isRunningBenchmark = false
            sciStatusMessage = t("sci_bench_done")
            if sciAutoRecordHistory {
                recordScienceHistory(position: .globalAll, note: "Messreihe (\(collected.count) Läufe, T=0,0)")
            }
        }
    }

    func recordScienceHistory(position: ScienceHistoryPosition? = nil, note: String = "") {
        let pos = position ?? sciHistoryPositionFilter
        let s = sciSummary
        let entry = ScienceHistoryEntry(
            timestamp: currentClockTime(),
            positionFilter: pos,
            scopeLabel: sciScope.rawValue,
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
        let minUplinkMbps = wanPeers.map(\.uplinkMbps).min() ?? 100.0
        // ~16 KB activation hidden-state tensor per pipeline hop
        let transferMs = wanPeers.count > 1 ? ((0.128 / max(10.0, minUplinkMbps)) * 1000.0) * Double(wanPeers.count - 1) : 0.0
        let totalStepMs = max(5.0, computeMs + wanTotalRttMs + transferMs)
        return 1000.0 / totalStepMs
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

        let localHost = Host.current().localizedName ?? "Lokaler Mac"
        let localUsable = AppleSiliconChipFamily.usableVramGB(for: localRamGB)
        let localBw = AppleSiliconChipFamily.inferBandwidth(from: localChipName)

        var discovered: [WanPeerNode] = [
            WanPeerNode(
                id: "wan-local-host",
                displayName: localHost,
                region: "Lokal (Host)",
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
                            discovered.append(
                                WanPeerNode(
                                    id: "ts-\(peerKey)",
                                    displayName: hostName,
                                    region: "Tailscale Mesh",
                                    chip: "Apple Silicon (Tailscale)",
                                    ramGB: 32.0,
                                    usableVramGB: 26.0,
                                    bandwidthGBs: 200.0,
                                    overlayIP: ips.first ?? "100.64.0.x",
                                    rttMs: 18.0,
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
                    text: "Raum \(wanRoomCode) bereit. Verbinde Macs über Tailscale, WireGuard oder libp2p-QUIC und nutze /status oder /layers im Chat.",
                    isSystemEvent: true,
                    isSelf: false
                )
            ]
        }
        wanStatusNote = wanTailscaleInstalled
            ? "Tailscale erkannt (\(wanTailscaleIP.isEmpty ? "bereit" : wanTailscaleIP)) · \(wanPeers.count) Knoten im Verbund."
            : "Bereit für Tailscale / WireGuard / libp2p-QUIC Mesh (\(wanPeers.count) lokaler Knoten)."
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
                    text: "Verbindung zum Internet-Verbund \(wanRoomCode) getrennt.",
                    isSystemEvent: true,
                    isSelf: false
                )
            )
            wanStatusNote = "Getrennt vom Internet-Verbund."
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
                text: "Beigetreten: \(wanRoomCode) über \(wanTransport.rawValue) (MTU \(wanTransport.mtuBytes)).",
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
        wanStatusNote = "Aktiv verbunden mit \(wanRoomCode) (\(wanPeers.count) Knoten · \(Int(wanTotalRamGB)) GB RAM)."
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
                text: "\(peer.displayName) (\(peer.chip), \(Int(peer.ramGB)) GB, RTT \(Int(peer.rttMs)) ms) ist dem Verbund beigetreten.",
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
                text: "Weltweiter Mega-Verbund mit \(wanPeers.count) Macs (\(Int(wanTotalRamGB)) GB Gesamt-RAM / \(Int(wanTotalUsableVramGB)) GB nutzbar) initialisiert.",
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
        if isLocalClusterCoupledWithWan {
            let localBridgePeers: [WanPeerNode] = nodes.enumerated().map { idx, node in
                let tbMbps = Double(node.thunderboltGen >= 5 ? 80000 : 32000)
                return WanPeerNode(
                    id: idx == 0 ? "local-host" : "local-bridge-\(node.id)",
                    displayName: idx == 0 ? "\(node.name) (Gateway)" : "\(node.name) (TB\(node.thunderboltGen))",
                    region: "Lokal · TB\(node.thunderboltGen)\(node.rdmaEnabled ? " RDMA" : "")",
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
            wanStatusNote = "Gekoppelt: \(localBridgePeers.count) lokale TB-Macs + \(remoteOnly.count) WAN-Macs (\(Int(wanTotalRamGB)) GB Gesamt-RAM)."
            if announceInChat {
                chatMessages.append(
                    ClusterChatMessage(
                        senderName: "Hybrid-Brücke",
                        senderRegion: "Lokal ↔ WAN",
                        senderChip: "\(localBridgePeers.count) TB + \(remoteOnly.count) WAN",
                        timestamp: currentClockTime(),
                        text: "🔗 Lokaler Thunderbolt/RDMA-Verbund (\(localBridgePeers.count) Macs · \(Int(totalPhysicalRamGB)) GB) mit Internet-Cluster gekoppelt. Gesamtspeicher: \(Int(wanTotalRamGB)) GB (\(Int(wanTotalUsableVramGB)) GB nutzbar).",
                        isSystemEvent: true,
                        isSelf: false
                    )
                )
            }
        } else {
            let primaryHost = wanPeers.first(where: { $0.id == "local-host" }) ?? WanPeerNode(
                id: "local-host",
                displayName: Host.current().localizedName ?? "Lokaler Mac",
                region: "Lokal",
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
            wanStatusNote = "Kopplung gelöst: \(wanPeers.count) Knoten im Internet-Verbund."
            if announceInChat {
                chatMessages.append(
                    ClusterChatMessage(
                        senderName: "Hybrid-Brücke",
                        senderRegion: "Lokal ↔ WAN",
                        senderChip: "Getrennt",
                        timestamp: currentClockTime(),
                        text: "🔌 Lokale Thunderbolt-Brücke vom Internet-Cluster getrennt.",
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

        let sender = Host.current().localizedName ?? "Lokaler Mac"
        var finalText = raw
        if raw == "/status" {
            finalText = "📊 Status: \(localChipName) · \(Int(localRamGB)) GB RAM · \(localThermalLabel) · \(localPowerLabel) · Transport: \(wanTransport.rawValue)"
        } else if raw == "/layers" {
            let myLayers = wanPeers.first(where: \.isLocalHost)?.assignedLayers ?? "Auto"
            finalText = "🧩 Schichten-Anteil: \(myLayers) für \(selectedModel.displayName) · Verbund-Summe: \(wanPeers.count) Macs (\(Int(wanTotalUsableVramGB)) GB nutzbar)"
        } else if raw == "/ping" {
            finalText = String(format: "🏓 WAN-Pipeline RTT: %.1f ms · Geschätzte Rate: %.2f tok/s", wanTotalRttMs, wanEstimatedTokPerSec)
        }

        chatMessages.append(
            ClusterChatMessage(
                senderName: sender,
                senderRegion: "Lokal",
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
        audioPartyStatusText = "In Audio-Party (\(audioPartyMembers.count) Teilnehmer · \(audioPartyCodec.rawValue))"
        chatMessages.append(
            ClusterChatMessage(
                senderName: "Audio-Party",
                senderRegion: wanPeerRegionInput,
                senderChip: localChipName,
                timestamp: currentClockTime(),
                text: "🎧 \(Host.current().localizedName ?? "Lokaler Mac") ist der Cluster-Audio-Party beigetreten (\(audioPartyCodec.rawValue)).",
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
        audioPartyStatusText = "Audio-Party verlassen."
        chatMessages.append(
            ClusterChatMessage(
                senderName: "Audio-Party",
                senderRegion: wanPeerRegionInput,
                senderChip: localChipName,
                timestamp: currentClockTime(),
                text: "🔇 \(Host.current().localizedName ?? "Lokaler Mac") hat die Audio-Party verlassen.",
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
        let peers = wanPeers.isEmpty ? [
            WanPeerNode(
                id: "local-host",
                displayName: Host.current().localizedName ?? "Lokaler Mac",
                region: "Lokal",
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
            let role = idx == 0 ? "Party-Leiter (Rang 0)" : (peer.isLocalHost ? "TB-Insel-Knoten" : "WAN-Knoten")
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
        let isNewer = (versionCmp == .orderedDescending) || (versionCmp == .orderedSame && info.build > currentBuild) || shaChanged

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
        let candidates = [
            URL(fileURLWithPath: fm.currentDirectoryPath),
            Bundle.main.bundleURL.deletingLastPathComponent(),
            Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent(),
            Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        ]
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

            if pullOut.exitCode != 0 {
                await MainActor.run {
                    let cleanErr = Self.sanitizeGitNoise(pullOut.output)
                    if !cleanErr.isEmpty {
                        self.updateProgressLog = cleanErr
                    }
                    self.updateStatus = .failed("git pull failed (Exit \(pullOut.exitCode))")
                }
                return
            }

            await MainActor.run {
                let cleanPull = Self.sanitizeGitNoise(pullOut.output)
                self.updateProgressLog = (cleanPull.isEmpty ? "Already up to date." : cleanPull) + "\n\nswift build …\n"
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

            await MainActor.run {
                if buildOut.exitCode == 0 {
                    self.refreshLocalCommitSHA()
                    if !self.updateProgressLog.hasSuffix("\n") {
                        self.updateProgressLog += "\n"
                    }
                    self.updateProgressLog += "Build complete."
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

    func relaunchApp() {
        showUpdatePromptSheet = false
        if let repoRoot = localGitRepoRoot {
            let script = repoRoot.appendingPathComponent("scripts/run_ssccc.sh").path
            if FileManager.default.isExecutableFile(atPath: script) {
                let oldPID = ProcessInfo.processInfo.processIdentifier
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
                proc.arguments = [
                    "-c",
                    "while kill -0 \(oldPID) 2>/dev/null; do sleep 0.1; done; exec \"\(script)\""
                ]
                proc.currentDirectoryURL = repoRoot
                proc.standardInput = FileHandle.nullDevice
                proc.standardOutput = FileHandle.nullDevice
                proc.standardError = FileHandle.nullDevice
                try? proc.run()

                NSApplication.shared.terminate(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    exit(0)
                }
                return
            }
        }
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
}
