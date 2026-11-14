import Foundation

enum NavigationTab: String, CaseIterable, Identifiable {
    case overview = "Cluster-Übersicht"
    case devices = "Geräte & Vergleich"
    case models = "Modell-Studio"
    case network = "Netzwerk & RDMA"
    case agents = "Agenten & IDEs"
    case science = "Forschung & Roofline"
    case console = "API & Konsole"

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
        }
    }

    var subtitle: String {
        switch self {
        case .overview: return "52 GB Pool & Topologie"
        case .devices: return "Einzeldaten & Vergleich"
        case .models: return "MLX, oMLX, Ollama & llama.cpp"
        case .network: return "TB4/5, RDMA & Hybrid"
        case .agents: return "Lokale Agenten, IDEs & SDKs"
        case .science: return "arXiv, Splitwise & Tuning"
        case .console: return "OpenAI / Ollama / oMLX API"
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

struct LayerSplitResult {
    let studioLayers: Int
    let miniLayers: Int
    let studioPercent: Double
    let miniPercent: Double
    let totalRequiredGB: Double
    let totalUsableGB: Double
    let fits: Bool
}
