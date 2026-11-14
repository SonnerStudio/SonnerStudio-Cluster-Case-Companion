import Foundation

enum NavigationTab: String, CaseIterable, Identifiable {
    case overview = "Cluster-Übersicht"
    case devices = "Geräte & Vergleich"
    case models = "Modell-Studio"
    case network = "Netzwerk & RDMA"
    case agents = "Agenten & IDEs"
    case science = "Forschung & Roofline"
    case console = "API & Konsole"
    case help = "Hilfe & Handbuch"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "cpu.fill"
        case .devices: return "macstudio.fill"
        case .models: return "square.stack.3d.up.fill"
        case .network: return "bolt.horizontal.circle.fill"
        case .agents: return "sparkles.rectangle.stack.fill"
        case .science: return "chart.xyaxis.line"
        case .console: return "terminal.fill"
        case .help: return "questionmark.circle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: return "Verbund-Speicher & Topologie"
        case .devices: return "Alle M-Macs & Vergleich"
        case .models: return "MLX, oMLX, Ollama & llama.cpp"
        case .network: return "TB4/5, RDMA & Hybrid"
        case .agents: return "Lokale Agenten, IDEs & SDKs"
        case .science: return "arXiv, Splitwise & Tuning"
        case .console: return "OpenAI / Ollama / oMLX API"
        case .help: return "Handbuch & Einrichtung"
        }
    }
}

enum RuntimeService: String, CaseIterable, Identifiable {
    case omlx = "oMLX (SSD KV-Cache)"
    case ollama = "Ollama"
    case llamaCpp = "llama.cpp"

    var id: String { rawValue }

    var defaultPort: Int {
        switch self {
        case .omlx: return 8000
        case .ollama: return 11434
        case .llamaCpp: return 8080
        }
    }

    var description: String {
        switch self {
        case .omlx:
            return "Nativer macOS-MLX-Server mit Paged SSD KV-Cache, OpenAI (/v1) & Anthropic (/v1/messages) API."
        case .ollama:
            return "Lokaler Modell-Dienst auf Port 11434 — ideal für Zero-Config & breite Client-Unterstützung."
        case .llamaCpp:
            return "Direkter GGUF-/llama-server-Dienst (Port 8080) oder Import nach schnellem MLX."
        }
    }
}

enum KVCachePrecision: String, CaseIterable, Identifiable {
    case fp16 = "FP16 (Standard)"
    case q8 = "8-Bit (--kv-bits 8)"
    case q4 = "4-Bit (--kv-bits 4)"

    var id: String { rawValue }

    var memoryFactor: Double {
        switch self {
        case .fp16: return 1.0
        case .q8: return 0.52
        case .q4: return 0.28
        }
    }

    var maxContextEstimate: String {
        switch self {
        case .fp16: return "~16k Tokens"
        case .q8: return "~32k Tokens"
        case .q4: return "~64k+ Tokens"
        }
    }
}

enum TransportMode: String, CaseIterable, Identifiable {
    case autoHybrid = "Auto-Hybrid (Empfohlen)"
    case thunderboltOnly = "Thunderbolt-Only"
    case lanWlanOnly = "LAN / WLAN-Only"
    case rdmaExperimental = "RDMA / JACCL (Opt-In)"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .autoHybrid:
            return "Control Plane über LAN/WLAN · Tensor-Daten exklusiv über Thunderbolt (30–37 Gbps) mit automatischem Fallback."
        case .thunderboltOnly:
            return "Erzwingt punkt-zu-punkt Thunderbolt-IPs (10.99.1.x) für maximale Isolation ohne WLAN-Jitter."
        case .lanWlanOnly:
            return "Nutzt Ethernet/WLAN für alle Transfers — ideal zum Testen ohne TB-Kabel."
        case .rdmaExperimental:
            return "Nutzt MLX JACCL über RDMA Verbs (ab TB5 nativ; für TB4 ist ein Community-Enabler nötig)."
        }
    }

    var apiKey: String {
        switch self {
        case .autoHybrid: return "auto_hybrid"
        case .thunderboltOnly: return "tb_only"
        case .lanWlanOnly: return "lan_wlan_only"
        case .rdmaExperimental: return "rdma_jaccl"
        }
    }
}

struct ClusterNodeModel: Identifiable, Hashable {
    let id: String
    let name: String
    let role: String
    let chip: String
    let cpuCores: Int
    let osVersion: String
    let totalRamGB: Double
    let usableVramGB: Double
    let wiredLimitMB: Int
    let bandwidthGBs: Double
    let thunderboltGen: Int
    let rdmaEnabled: Bool
    let tbIP: String
    let lanIP: String
    let ssdTotalGB: Int
    let isSimulated: Bool
}

struct ModelPreset: Identifiable, Hashable {
    let id: String
    let displayName: String
    let quantization: String
    let totalLayers: Int
    let estimatedGB: Double
    let kvReserveGB: Double
    let notes: String
}

struct NodeLayerAllocation: Identifiable {
    let id: String
    let nodeName: String
    let layers: Int
    let percent: Double
    let usableGB: Double
}

struct LayerSplitResult {
    let studioLayers: Int
    let miniLayers: Int
    let studioPercent: Double
    let miniPercent: Double
    let nodeAllocations: [NodeLayerAllocation]
    let totalRequiredGB: Double
    let totalUsableGB: Double
    let fits: Bool
}

enum MacFormFactor: String, CaseIterable, Identifiable {
    case macStudio = "Mac Studio"
    case macMini = "Mac mini"
    case macBookPro = "MacBook Pro"
    case macBookAir = "MacBook Air"
    case iMac = "iMac"
    case macPro = "Mac Pro"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .macStudio: return "macstudio.fill"
        case .macMini: return "macmini.fill"
        case .macBookPro, .macBookAir: return "laptopcomputer"
        case .iMac: return "desktopcomputer"
        case .macPro: return "macpro.gen3.fill"
        }
    }
}

enum AppleSiliconChipFamily: String, CaseIterable, Identifiable {
    case m1 = "Apple M1"
    case m1Pro = "Apple M1 Pro"
    case m1Max = "Apple M1 Max"
    case m1Ultra = "Apple M1 Ultra"
    case m2 = "Apple M2"
    case m2Pro = "Apple M2 Pro"
    case m2Max = "Apple M2 Max"
    case m2Ultra = "Apple M2 Ultra"
    case m3 = "Apple M3"
    case m3Pro = "Apple M3 Pro"
    case m3Max = "Apple M3 Max"
    case m3Ultra = "Apple M3 Ultra"
    case m4 = "Apple M4"
    case m4Pro = "Apple M4 Pro"
    case m4Max = "Apple M4 Max"
    case m5 = "Apple M5"
    case m5Pro = "Apple M5 Pro"
    case m5Max = "Apple M5 Max"
    case m6 = "Apple M6"
    case m6Pro = "Apple M6 Pro"
    case m6Max = "Apple M6 Max"

    var id: String { rawValue }

    var cpuCores: Int {
        switch self {
        case .m1, .m2, .m3: return 8
        case .m1Pro, .m2Pro, .m1Max, .m2Max, .m4, .m5, .m6: return 10
        case .m3Pro, .m4Pro: return 12
        case .m3Max, .m4Max, .m5Pro, .m6Pro: return 16
        case .m5Max, .m6Max: return 18
        case .m1Ultra: return 20
        case .m2Ultra: return 24
        case .m3Ultra: return 32
        }
    }

    var gpuCores: Int {
        switch self {
        case .m1, .m2, .m3, .m4, .m5, .m6: return 10
        case .m1Pro, .m2Pro, .m3Pro, .m4Pro: return 18
        case .m5Pro, .m6Pro: return 20
        case .m1Max, .m2Max, .m5Max, .m6Max: return 32
        case .m3Max, .m4Max: return 40
        case .m1Ultra: return 64
        case .m2Ultra: return 76
        case .m3Ultra: return 80
        }
    }

    var bandwidthGBs: Double {
        switch self {
        case .m1: return 68.0
        case .m2, .m3: return 100.0
        case .m4: return 120.0
        case .m5: return 153.0
        case .m6: return 180.0
        case .m3Pro: return 150.0
        case .m1Pro, .m2Pro: return 200.0
        case .m4Pro, .m5Pro: return 273.0
        case .m6Pro: return 310.0
        case .m1Max, .m2Max, .m3Max: return 400.0
        case .m5Max: return 460.0
        case .m4Max: return 546.0
        case .m6Max: return 580.0
        case .m1Ultra, .m2Ultra, .m3Ultra: return 800.0
        }
    }

    var thunderboltGen: Int {
        switch self {
        case .m4Pro, .m4Max, .m5, .m5Pro, .m5Max, .m6, .m6Pro, .m6Max: return 5
        default: return 4
        }
    }

    var defaultRamGB: Double {
        switch self {
        case .m1, .m2, .m3, .m4, .m5, .m6: return 16.0
        case .m1Pro, .m2Pro, .m3Pro, .m4Pro, .m5Pro, .m6Pro: return 24.0
        case .m1Max, .m2Max, .m3Max, .m4Max, .m5Max, .m6Max: return 36.0
        case .m1Ultra, .m2Ultra, .m3Ultra: return 128.0
        }
    }

    static func usableVramGB(for totalRamGB: Double) -> Double {
        if totalRamGB >= 96.0 { return totalRamGB - 8.0 }
        if totalRamGB >= 32.0 { return totalRamGB - 6.0 }
        return max(4.0, totalRamGB - 4.0)
    }

    static func inferBandwidth(from chipName: String) -> Double {
        let lower = chipName.lowercased()
        if lower.contains("ultra") { return 800.0 }
        if lower.contains("m6 max") { return 580.0 }
        if lower.contains("m4 max") { return 546.0 }
        if lower.contains("m5 max") { return 460.0 }
        if lower.contains("max") { return 400.0 }
        if lower.contains("m6 pro") { return 310.0 }
        if lower.contains("m4 pro") || lower.contains("m5 pro") { return 273.0 }
        if lower.contains("m3 pro") { return 150.0 }
        if lower.contains("pro") { return 200.0 }
        if lower.contains("m6") { return 180.0 }
        if lower.contains("m5") { return 153.0 }
        if lower.contains("m4") { return 120.0 }
        if lower.contains("m2") || lower.contains("m3") { return 100.0 }
        return 68.0
    }
}
