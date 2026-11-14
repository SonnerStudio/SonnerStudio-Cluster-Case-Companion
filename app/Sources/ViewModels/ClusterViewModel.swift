import Foundation
import SwiftUI

@MainActor
final class ClusterViewModel: ObservableObject {
    @Published var selectedTab: NavigationTab = .overview
    @Published var language: AppLanguage = .de
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
    @Published var localOSVersion: String = "macOS 27.0.1"
    @Published var localCPUCores: Int = ProcessInfo.processInfo.processorCount
    @Published var localRamGB: Double = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0
    @Published var localWiredLimitMB: Int = 0
    @Published var localLanIP: String = "192.168.1.20"
    @Published var localTbIP: String = "10.99.1.2"
    @Published var localRdmaActive: Bool = false
    @Published var lastProbeTimestamp: String = "Gerade ausgelesen"

    @Published var promptInput: String = "Erkläre kurz, wie 36 GB + 16 GB per Pipeline Parallelism gekoppelt werden."
    @Published var consoleOutput: String = "Bereit. Starte den Python-Daemon (uvicorn core.api.gateway:app --port 8000) oder teste direkt im Vorschau-Modus."
    @Published var isSendingPrompt: Bool = false
    @Published var customNodes: [ClusterNodeModel] = []
    @Published var newFormFactor: MacFormFactor = .macBookPro
    @Published var newChip: AppleSiliconChipFamily = .m3Max
    @Published var newRamGB: Double = 36.0
    @Published var newCustomName: String = ""
    @Published var helpSearchText: String = ""

    let modelPresets: [ModelPreset] = [
        ModelPreset(
            id: "mlx-community/Llama-3.3-70B-Instruct-4bit",
            displayName: "Llama 3.3 70B Instruct",
            quantization: "4-bit MLX",
            totalLayers: 80,
            estimatedGB: 37.5,
            kvReserveGB: 4.0,
            notes: "Flaggschiff für 52-GB-Verbund · benötigt Studio + Mini"
        ),
        ModelPreset(
            id: "mlx-community/Qwen2.5-32B-Instruct-4bit",
            displayName: "Qwen 2.5 32B Instruct",
            quantization: "4-bit MLX",
            totalLayers: 64,
            estimatedGB: 19.2,
            kvReserveGB: 6.0,
            notes: "Sehr schnell · viel Platz für langen Kontext"
        ),
        ModelPreset(
            id: "mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit",
            displayName: "DeepSeek-R1 Distill 32B",
            quantization: "4-bit MLX",
            totalLayers: 64,
            estimatedGB: 19.5,
            kvReserveGB: 6.0,
            notes: "Starkes Reasoning-Modell im Hybrid-Cluster"
        ),
        ModelPreset(
            id: "mlx-community/Mistral-Large-Instruct-2411-4bit",
            displayName: "Mistral Large 123B (zu groß)",
            quantization: "4-bit MLX",
            totalLayers: 88,
            estimatedGB: 68.0,
            kvReserveGB: 4.0,
            notes: "Demonstriert OOM-Schutz: überschreitet 42 GB effektiv"
        )
    ]

    init() {
        self.selectedModel = modelPresets[0]
        refreshLocalHardwareProbe()
        Task { await checkDaemonHealth() }
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

        let os = runShell("/usr/bin/sw_vers", ["-productVersion"])
        if !os.isEmpty { localOSVersion = "macOS \(os)" }

        let wiredRaw = runShell("/usr/sbin/sysctl", ["-n", "iogpu.wired_limit_mb"])
        localWiredLimitMB = Int(wiredRaw) ?? 0

        localCPUCores = ProcessInfo.processInfo.processorCount
        localRamGB = (Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0).rounded()

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
            chip: "\(chip.rawValue) · \(chip.cpuCores)-Core CPU / \(chip.gpuCores)-Core GPU",
            cpuCores: chip.cpuCores,
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
        let localTbGen = localChipName.lowercased().contains("m6") || localChipName.lowercased().contains("m5") || localChipName.lowercased().contains("m4 max") || localChipName.lowercased().contains("m4 pro") ? 5 : 4

        var rawList: [ClusterNodeModel] = []
        if simulateMacStudio {
            rawList.append(
                ClusterNodeModel(
                    id: "studio-m5-max",
                    name: "Mac Studio M5 Max",
                    role: "Coordinator (Rank 0)",
                    chip: "Apple M5 Max · 18-Core CPU / 32-Core GPU",
                    cpuCores: 18,
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
                    isSimulated: true
                )
            )
        }

        let localNode = ClusterNodeModel(
            id: "local-host",
            name: Host.current().localizedName ?? "Lokaler Apple Silicon Mac",
            role: (simulateMacStudio || !customNodes.isEmpty) ? "Worker" : "Standalone (Rank 0)",
            chip: "\(localChipName) · \(localCPUCores) CPU-Kerne",
            cpuCores: localCPUCores,
            osVersion: localOSVersion,
            totalRamGB: localRamGB,
            usableVramGB: localUsable,
            wiredLimitMB: localWiredLimitMB,
            bandwidthGBs: localBandwidth,
            thunderboltGen: localTbGen,
            rdmaEnabled: localRdmaActive,
            tbIP: localTbIP,
            lanIP: localLanIP,
            ssdTotalGB: 256,
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
                chip: n.chip,
                cpuCores: n.cpuCores,
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

    var activeLinkHeadline: String {
        switch transportMode {
        case .autoHybrid:
            return nodes.count > 1 ? "TB4/5 Bridge (30–37 Gbps) + LAN/WLAN Control" : "Lokal (1 Node)"
        case .thunderboltOnly:
            return "Thunderbolt Point-to-Point (10.99.1.x)"
        case .lanWlanOnly:
            return "LAN / Wi-Fi Fallback (~1–10 Gbps)"
        case .rdmaExperimental:
            return "JACCL / RDMA Verbs (<50 µs, Opt-In)"
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
        consoleOutput = """
        [SS-CCC Lokale Vorschau]
        Modell: \(selectedModel.displayName) (\(selectedModel.quantization))
        Cluster: \(nodes.count) Node(s) · \(Int(totalPhysicalRamGB)) GB physisch (\(Int(totalUsableVramGB)) GB nutzbar)
        Verteilung: Studio \(split.studioLayers) Layer (\(String(format: "%.0f", split.studioPercent))%) | Mini \(split.miniLayers) Layer (\(String(format: "%.0f", split.miniPercent))%)
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
                  "name": "\(selectedModel.displayName) (52 GB Cluster)"
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
}
