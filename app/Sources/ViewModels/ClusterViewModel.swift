import Foundation
import SwiftUI

@MainActor
final class ClusterViewModel: ObservableObject {
    @Published var selectedTab: NavigationTab = .overview
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
    }

    var nodes: [ClusterNodeModel] {
        let localUsable = localRamGB >= 32 ? (localRamGB - 6.0) : max(8.0, localRamGB - 4.0)
        let mini = ClusterNodeModel(
            id: "mini-m4",
            name: Host.current().localizedName ?? "Mac mini M4",
            role: simulateMacStudio ? "Worker (Rank 1)" : "Standalone (Rank 0)",
            chip: "\(localChipName) · \(localCPUCores) CPU-Kerne",
            cpuCores: localCPUCores,
            osVersion: localOSVersion,
            totalRamGB: localRamGB,
            usableVramGB: localUsable,
            wiredLimitMB: localWiredLimitMB,
            bandwidthGBs: localChipName.lowercased().contains("max") ? 460.0 : 120.0,
            thunderboltGen: localChipName.lowercased().contains("max") ? 5 : 4,
            rdmaEnabled: localRdmaActive,
            tbIP: localTbIP,
            lanIP: localLanIP,
            ssdTotalGB: 256,
            isSimulated: false
        )
        if simulateMacStudio {
            let studio = ClusterNodeModel(
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
            return [studio, mini]
        }
        return [mini]
    }

    var totalPhysicalRamGB: Double {
        nodes.reduce(0) { $0 + $1.totalRamGB }
    }

    var totalUsableVramGB: Double {
        nodes.reduce(0) { $0 + $1.usableVramGB }
    }

    var shardingSplit: LayerSplitResult {
        let total = selectedModel.totalLayers
        let usable = totalUsableVramGB
        let required = selectedModel.estimatedGB + kvCacheReserveGB
        let fits = required <= usable

        if simulateMacStudio {
            let studioShare = 30.0 / 42.0
            let studioLayers = Int((Double(total) * studioShare).rounded())
            let miniLayers = max(0, total - studioLayers)
            return LayerSplitResult(
                studioLayers: studioLayers,
                miniLayers: miniLayers,
                studioPercent: Double(studioLayers) / Double(total) * 100.0,
                miniPercent: Double(miniLayers) / Double(total) * 100.0,
                totalRequiredGB: required,
                totalUsableGB: usable,
                fits: fits
            )
        } else {
            return LayerSplitResult(
                studioLayers: 0,
                miniLayers: total,
                studioPercent: 0,
                miniPercent: 100,
                totalRequiredGB: required,
                totalUsableGB: usable,
                fits: fits
            )
        }
    }

    var activeLinkHeadline: String {
        switch transportMode {
        case .autoHybrid:
            return simulateMacStudio ? "TB4/5 Bridge (30–37 Gbps) + LAN/WLAN Control" : "Lokal (1 Node)"
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
}
