import Foundation

enum NavigationTab: String, CaseIterable, Identifiable {
    case overview = "Cluster-Übersicht"
    case devices = "Geräte & Vergleich"
    case models = "Modell-Studio"
    case network = "Netzwerk & RDMA"
    case internetCluster = "Internet-Verbund & Chat"
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
        case .internetCluster: return "globe.americas.fill"
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
        case .network: return "TB3/4/5, RDMA & Hybrid"
        case .internetCluster: return "WAN-Verbund & Teilnehmer-Chat"
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

struct RuntimeReadiness: Hashable {
    let service: RuntimeService
    let installed: Bool
    let running: Bool
    let binaryPath: String
    let installCommand: String
    let pullModelCommand: String
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
    let modelIdentifier: String
    let chip: String
    let cpuCores: Int
    let cpuTopology: String
    let gpuCores: Int
    let neuralEngineCores: Int
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
    let ssdFreeGB: Int
    let thermalLabel: String
    let powerLabel: String
    let isSimulated: Bool

    var peakFP16TFLOPS: Double {
        AppleSiliconChipFamily.inferFP16TFLOPS(from: chip)
    }

    var ridgePointFLOPPerByte: Double {
        guard bandwidthGBs > 0 else { return 0 }
        return (peakFP16TFLOPS * 1000.0) / bandwidthGBs
    }

    var typicalWatts: Double {
        AppleSiliconChipFamily.inferTypicalWatts(from: chip)
    }
}

enum ScienceScope: String, CaseIterable, Identifiable {
    case localCluster = "Lokal (TB/RDMA)"
    case internetWan = "Internet-WAN"
    case hybridCompare = "Vergleich (Lokal vs. WAN)"

    var id: String { rawValue }
}

enum ScienceLabTab: String, CaseIterable, Identifiable {
    case roofline = "Roofline & Engpass"
    case wanTopology = "WAN-Topologie & Skalierung"
    case memoryKv = "Speicher & KV-Analyse"
    case energetics = "Energie, CO₂ & Kosten"
    case trialsExport = "Messreihen & Export"
    case historyLog = "Verlaufsaufzeichnung"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .roofline: return "chart.xyaxis.line"
        case .wanTopology: return "globe.europe.africa.fill"
        case .memoryKv: return "memorychip.fill"
        case .energetics: return "bolt.fill"
        case .trialsExport: return "tablecells.fill"
        case .historyLog: return "clock.arrow.circlepath"
        }
    }
}

enum ScienceHistoryPosition: String, CaseIterable, Identifiable {
    case globalAll = "Global (Alle Messwerte)"
    case throughput = "Durchsatz (tok/s)"
    case latency = "Latenz (TTFT / TPOT)"
    case energetics = "Energie & CO₂ (J/tok)"
    case wanNetwork = "WAN-RTT & Blase"
    case memoryPool = "Speicher & Kontext"

    var id: String { rawValue }
}

struct ScienceHistoryEntry: Identifiable {
    let id = UUID()
    let timestamp: String
    let positionFilter: ScienceHistoryPosition
    let scopeLabel: String
    let modelName: String
    let nodeCount: Int
    let usableVramGB: Double
    let ttftMs: Double
    let tpotMs: Double
    let tokPerSec: Double
    let wanRttMs: Double
    let bubblePercent: Double
    let joulesPerToken: Double
    let edpJouleSec: Double
    let co2PerMillionTok: Double
    let bottleneckRegime: String
    let note: String
}

enum ActivationCompressionMode: String, CaseIterable, Identifiable {
    case fp16Raw = "FP16 (16-Bit Roh)"
    case fp8Quantized = "FP8 / INT8 (2× Kompakt)"
    case int4Block = "INT4 Block (4× Kompakt)"
    case topKSparse = "Top-K Dünnbesetzt (~6×)"

    var id: String { rawValue }

    var bytesPerElement: Double {
        switch self {
        case .fp16Raw: return 2.0
        case .fp8Quantized: return 1.0
        case .int4Block: return 0.5625
        case .topKSparse: return 0.32
        }
    }

    var qualityNote: String {
        switch self {
        case .fp16Raw: return "Verlustfrei (0,00 PPL-Abweichung)"
        case .fp8Quantized: return "Vernachlässigbar (<0,02 PPL, Standard für Petals/SWARM)"
        case .int4Block: return "Gering (+0,08–0,15 PPL, ideal für schmale Uplink-Leitungen)"
        case .topKSparse: return "Messbar (+0,25–0,45 PPL, maximaler Durchsatz bei CGNAT/DERP)"
        }
    }
}

enum CarbonRegionProfile: String, CaseIterable, Identifiable {
    case norway = "Norwegen / Wasserkraft (20 g/kWh)"
    case france = "Frankreich / Kernkraft (55 g/kWh)"
    case euAverage = "EU-Mittelwert (250 g/kWh)"
    case germany = "Deutschland (320 g/kWh)"
    case globalWan = "Weltweiter WAN-Mix (360 g/kWh)"
    case usAverage = "USA-Mittelwert (380 g/kWh)"

    var id: String { rawValue }

    var gco2PerKwh: Double {
        switch self {
        case .norway: return 20.0
        case .france: return 55.0
        case .euAverage: return 250.0
        case .germany: return 320.0
        case .globalWan: return 360.0
        case .usAverage: return 380.0
        }
    }
}

struct ScientificNodeSnapshot: Identifiable {
    let id: String
    let name: String
    let chip: String
    let region: String
    let totalRamGB: Double
    let usableVramGB: Double
    let bandwidthGBs: Double
    let peakFP16TFLOPS: Double
    let ridgePointFLOPPerByte: Double
    let typicalWatts: Double
    let rttMs: Double
    let uplinkMbps: Double
    let linkLabel: String
    let isRemoteWan: Bool
}

struct ScientificBenchmarkTrial: Identifiable {
    let id = UUID()
    let trialIndex: Int
    let ttftMs: Double
    let tpotMs: Double
    let tokensPerSec: Double
    let netRttMs: Double
    let watts: Double
    let joulesPerToken: Double
    let sloPass: Bool
    let scopeLabel: String
}

struct ScientificBenchmarkSummary {
    let modelId: String
    let scopeLabel: String
    let hardwareFingerprint: String
    let backendLabel: String
    let trialCount: Int
    let warmupDiscarded: Int
    let ttftMeanMs: Double
    let ttftP50Ms: Double
    let ttftP95Ms: Double
    let ttftP99Ms: Double
    let ttftStdDevMs: Double
    let ci95TtftMarginMs: Double
    let tpotMeanMs: Double
    let tpotP50Ms: Double
    let tpotP95Ms: Double
    let tpotP99Ms: Double
    let tpotStdDevMs: Double
    let ci95TpotMarginMs: Double
    let cvPercent: Double
    let goodputPercent: Double
    let meanTokensPerSec: Double
    let meanWatts: Double
    let joulesPerToken: Double
    let whPerMillionTokens: Double
    let edpJoulesSec: Double
    let co2GramsPerMillionTok: Double
    let timestamp: String
    let isLiveEndpoint: Bool
}

struct ModelPreset: Identifiable, Hashable {
    let id: String
    let displayName: String
    let quantization: String
    let totalLayers: Int
    let estimatedGB: Double
    let kvReserveGB: Double
    let notes: String
    var sourceLabel: String = "Referenz"
    var isLiveDiscovered: Bool = false
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
    case m7 = "Apple M7"
    case m7Pro = "Apple M7 Pro"
    case m7Max = "Apple M7 Max"
    case m8 = "Apple M8"
    case m8Pro = "Apple M8 Pro"
    case m8Max = "Apple M8 Max"
    case m9 = "Apple M9"
    case m9Pro = "Apple M9 Pro"
    case m9Max = "Apple M9 Max"

    var id: String { rawValue }

    var cpuCores: Int {
        switch self {
        case .m1, .m2, .m3: return 8
        case .m1Pro, .m2Pro, .m1Max, .m2Max, .m4, .m5, .m6, .m7, .m8, .m9: return 10
        case .m3Pro, .m4Pro: return 12
        case .m3Max, .m4Max, .m5Pro, .m6Pro, .m7Pro, .m8Pro, .m9Pro: return 16
        case .m5Max, .m6Max, .m7Max, .m8Max, .m9Max: return 18
        case .m1Ultra: return 20
        case .m2Ultra: return 24
        case .m3Ultra: return 32
        }
    }

    var gpuCores: Int {
        switch self {
        case .m1, .m2, .m3, .m4, .m5, .m6, .m7, .m8, .m9: return 10
        case .m1Pro, .m2Pro, .m3Pro, .m4Pro: return 18
        case .m5Pro, .m6Pro, .m7Pro, .m8Pro, .m9Pro: return 20
        case .m1Max, .m2Max, .m5Max, .m6Max, .m7Max, .m8Max, .m9Max: return 32
        case .m3Max, .m4Max: return 40
        case .m1Ultra: return 64
        case .m2Ultra: return 76
        case .m3Ultra: return 80
        }
    }

    var aneCores: Int {
        switch self {
        case .m1Ultra, .m2Ultra, .m3Ultra: return 32
        default: return 16
        }
    }

    var typicalPowerLabel: String {
        switch self {
        case .m1, .m2, .m3, .m4, .m5, .m6, .m7, .m8, .m9: return "10–45 W (Netzteil)"
        case .m1Pro, .m2Pro, .m3Pro, .m4Pro, .m5Pro, .m6Pro, .m7Pro, .m8Pro, .m9Pro: return "20–95 W (Netzteil)"
        case .m1Max, .m2Max, .m3Max, .m4Max, .m5Max, .m6Max, .m7Max, .m8Max, .m9Max: return "30–145 W (Netzteil)"
        case .m1Ultra, .m2Ultra, .m3Ultra: return "45–215 W (Netzteil)"
        }
    }

    var bandwidthGBs: Double {
        Self.inferBandwidth(from: rawValue)
    }

    var thunderboltGen: Int {
        Self.inferThunderboltGen(from: rawValue)
    }

    var defaultRamGB: Double {
        switch self {
        case .m1, .m2, .m3, .m4, .m5, .m6, .m7, .m8, .m9: return 16.0
        case .m1Pro, .m2Pro, .m3Pro, .m4Pro, .m5Pro, .m6Pro, .m7Pro, .m8Pro, .m9Pro: return 24.0
        case .m1Max, .m2Max, .m3Max, .m4Max, .m5Max, .m6Max, .m7Max, .m8Max, .m9Max: return 36.0
        case .m1Ultra, .m2Ultra, .m3Ultra: return 128.0
        }
    }

    static func usableVramGB(for totalRamGB: Double) -> Double {
        if totalRamGB >= 96.0 { return totalRamGB - 8.0 }
        if totalRamGB >= 32.0 { return totalRamGB - 6.0 }
        return max(4.0, totalRamGB - 4.0)
    }

    /// Parses any Apple Silicon generation (M1..M99) and tier (base/pro/max/ultra) for open-ended future support.
    static func parseGenerationAndTier(from chipName: String) -> (gen: Int, tier: String) {
        let lower = chipName.lowercased()
        let tier: String
        if lower.contains("ultra") { tier = "ultra" }
        else if lower.contains("max") { tier = "max" }
        else if lower.contains("pro") { tier = "pro" }
        else { tier = "base" }

        if let regex = try? NSRegularExpression(pattern: "\\bm(\\d+)", options: []),
           let match = regex.firstMatch(in: lower, options: [], range: NSRange(lower.startIndex..., in: lower)),
           let range = Range(match.range(at: 1), in: lower),
           let gen = Int(lower[range]) {
            return (gen, tier)
        }
        return (1, tier)
    }

    static func inferBandwidth(from chipName: String) -> Double {
        let (gen, tier) = parseGenerationAndTier(from: chipName)
        switch (gen, tier) {
        case (1, "base"): return 68.0
        case (2, "base"), (3, "base"): return 100.0
        case (4, "base"): return 120.0
        case (5, "base"): return 153.0
        case (6, "base"): return 180.0
        case (_, "base"): return 180.0 + Double(max(0, gen - 6)) * 28.0

        case (3, "pro"): return 150.0
        case (1, "pro"), (2, "pro"): return 200.0
        case (4, "pro"), (5, "pro"): return 273.0
        case (6, "pro"): return 310.0
        case (_, "pro"): return 310.0 + Double(max(0, gen - 6)) * 45.0

        case (1, "max"), (2, "max"), (3, "max"): return 400.0
        case (4, "max"): return 546.0
        case (5, "max"): return 460.0
        case (6, "max"): return 580.0
        case (_, "max"): return 580.0 + Double(max(0, gen - 6)) * 80.0

        case (1, "ultra"), (2, "ultra"), (3, "ultra"): return 800.0
        default: return 800.0 + Double(max(0, gen - 3)) * 160.0
        }
    }

    static func inferThunderboltGen(from chipName: String) -> Int {
        let (gen, tier) = parseGenerationAndTier(from: chipName)
        if gen >= 5 || (gen == 3 && tier == "ultra") || (gen == 4 && (tier == "pro" || tier == "max" || tier == "ultra")) {
            return 5
        }
        if (gen == 1 || gen == 2) && tier == "base" {
            return 3
        }
        return 4
    }

    static func inferGPUCores(from chipName: String) -> Int {
        let (gen, tier) = parseGenerationAndTier(from: chipName)
        switch tier {
        case "ultra":
            if gen == 1 { return 64 }
            if gen == 2 { return 76 }
            return 80 + max(0, gen - 3) * 8
        case "max":
            if gen == 3 || gen == 4 { return 40 }
            return gen >= 7 ? 32 + (gen - 6) * 4 : 32
        case "pro":
            return gen >= 5 ? 20 + max(0, gen - 6) * 2 : 18
        default:
            return gen >= 7 ? 10 + (gen - 6) * 2 : 10
        }
    }

    static func inferANECores(from chipName: String) -> Int {
        let (gen, tier) = parseGenerationAndTier(from: chipName)
        if tier == "ultra" { return 32 }
        return gen >= 8 ? 32 : 16
    }

    static func inferFP16TFLOPS(from chipName: String) -> Double {
        let (gen, tier) = parseGenerationAndTier(from: chipName)
        switch (gen, tier) {
        case (1, "ultra"): return 42.0
        case (2, "ultra"): return 54.4
        case (3, "ultra"): return 114.6
        case (_, "ultra"): return 114.6 + Double(max(0, gen - 3)) * 18.0
        case (1, "max"): return 20.8
        case (2, "max"): return 27.2
        case (3, "max"): return 32.8
        case (4, "max"): return 36.8
        case (5, "max"): return 41.0
        case (6, "max"): return 46.0
        case (_, "max"): return 46.0 + Double(max(0, gen - 6)) * 6.5
        case (1, "pro"): return 10.6
        case (2, "pro"): return 13.6
        case (3, "pro"): return 14.8
        case (4, "pro"): return 18.4
        case (5, "pro"): return 20.8
        case (6, "pro"): return 23.0
        case (_, "pro"): return 23.0 + Double(max(0, gen - 6)) * 3.5
        case (1, "base"): return 5.2
        case (2, "base"): return 7.2
        case (3, "base"): return 8.2
        case (4, "base"): return 8.6
        case (5, "base"): return 10.4
        case (6, "base"): return 11.6
        default: return 11.6 + Double(max(0, gen - 6)) * 1.8
        }
    }

    static func inferTypicalWatts(from chipName: String) -> Double {
        let lower = chipName.lowercased()
        if lower.contains("ultra") { return 155.0 }
        if lower.contains("max") { return 95.0 }
        if lower.contains("pro") { return 42.0 }
        return 22.0
    }

    static func linkTransferStats(genA: Int, genB: Int, mode: TransportMode) -> (rangeLabel: String, nominalGbps: Double, badge: String) {
        if mode == .lanWlanOnly {
            return ("1–10 Gbps", 2.5, "LAN/Wi-Fi")
        }
        let minGen = min(genA, genB)
        if minGen >= 5 {
            return mode == .rdmaExperimental
                ? ("75–110 Gbps", 85.0, "TB5 RDMA")
                : ("65–80 Gbps", 72.0, "TB5")
        }
        if minGen <= 3 {
            let badge = (genA != genB) ? "TB3/4/5" : "TB3"
            return mode == .rdmaExperimental
                ? ("28–33 Gbps", 30.0, "\(badge) RDMA")
                : ("26–32 Gbps", 29.0, badge)
        }
        let badge = (genA != genB) ? "TB4/5" : "TB4"
        return mode == .rdmaExperimental
            ? ("34–38 Gbps", 36.0, "\(badge) RDMA")
            : ("30–37 Gbps", 34.0, badge)
    }
}

// MARK: - Internet WAN Cluster & Participant Chat Models

enum WanOverlayTransport: String, CaseIterable, Identifiable {
    case tailscaleMesh = "Tailscale / WireGuard Mesh (100.64.x.x)"
    case wireGuardDirect = "WireGuard P2P Tunnel (ChaCha20)"
    case libp2pQuic = "libp2p / QUIC + DCUtR (Petals-Stil)"
    case derpRelay = "Verschlüsselter DERP / WebSocket-Relay"

    var id: String { rawValue }

    var mtuBytes: Int {
        switch self {
        case .tailscaleMesh, .wireGuardDirect: return 1280
        case .libp2pQuic: return 1350
        case .derpRelay: return 1420
        }
    }

    var baseOverheadMs: Double {
        switch self {
        case .wireGuardDirect: return 4.0
        case .tailscaleMesh: return 6.0
        case .libp2pQuic: return 9.0
        case .derpRelay: return 28.0
        }
    }

    var natNote: String {
        switch self {
        case .tailscaleMesh:
            return "Automatisches UDP-Hole-Punching über CGNAT (100.64.0.0/10) mit DERP-Rückfall."
        case .wireGuardDirect:
            return "Direkter Layer-3-Tunnel (ChaCha20-Poly1305) mit minimalem Protokoll-Overhead."
        case .libp2pQuic:
            return "Dezentrales Kademlia-DHT & DCUtR-Hole-Punching ohne zentralen VPN-Server."
        case .derpRelay:
            return "Ende-zu-Ende-verschlüsselter TCP/WSS-Relay für strenge Firmen-Firewalls."
        }
    }
}

enum InternetClusterScale: String, CaseIterable, Identifiable {
    case privateTeam = "Privates Team (2–8 Macs)"
    case researchSwarm = "Forschungs-Schwarm (8–32 Macs)"
    case megaCluster = "Riesiger Welt-Verbund (32–256+ Macs)"

    var id: String { rawValue }
}

struct WanPeerNode: Identifiable, Hashable {
    let id: String
    let displayName: String
    let region: String
    let chip: String
    let ramGB: Double
    let usableVramGB: Double
    let bandwidthGBs: Double
    let overlayIP: String
    let rttMs: Double
    let uplinkMbps: Double
    let assignedLayers: String
    let transport: WanOverlayTransport
    let isOnline: Bool
    let isLocalHost: Bool
}

struct ClusterChatMessage: Identifiable, Hashable {
    let id = UUID()
    let senderName: String
    let senderRegion: String
    let senderChip: String
    let timestamp: String
    let text: String
    let isSystemEvent: Bool
    let isSelf: Bool
}

enum AudioPartyCodec: String, CaseIterable, Identifiable {
    case opus16 = "Opus 16 kbps (WAN-Sparmodus)"
    case opus32 = "Opus 32 kbps (Klar · Standard)"
    case opus64 = "Opus 64 kbps (Studio-Sprache)"

    var id: String { rawValue }

    var kbps: Double {
        switch self {
        case .opus16: return 16.0
        case .opus32: return 32.0
        case .opus64: return 64.0
        }
    }
}

enum AudioPartyMicMode: String, CaseIterable, Identifiable {
    case openMic = "Offenes Mikrofon"
    case pushToTalk = "Sprech-Taste (PTT)"
    case alertsOnly = "Nur Verbund-Warnungen"

    var id: String { rawValue }
}

struct AudioPartyMember: Identifiable, Hashable {
    let id: String
    let displayName: String
    let chip: String
    let region: String
    let assignedLayers: String
    let roleBadge: String
    let isSelf: Bool
    var isSpeaking: Bool
    var isMuted: Bool
    var volumePercent: Double
    let voicePingMs: Double
}

// MARK: - GitHub Program Update Models

enum AppReleaseMetadata {
    static let githubOwner = "SonnerStudio"
    static let githubRepo = "SonnerStudio-Cluster-Case-Companion"
    static let manifestRawURL = "https://raw.githubusercontent.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion/main/version.json"
    static let latestReleaseAPIURL = "https://api.github.com/repos/SonnerStudio/SonnerStudio-Cluster-Case-Companion/releases/latest"
    static let commitsMainAPIURL = "https://api.github.com/repos/SonnerStudio/SonnerStudio-Cluster-Case-Companion/commits/main"
    static let releasesPageURL = "https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion/releases"

    static let fallbackVersion = "1.6.6"
    static let fallbackBuild = 160
    static let embeddedCommitSHA = "55e815a"

    static var currentVersion: String {
        if let bundleVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           !bundleVer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return bundleVer
        }
        return fallbackVersion
    }

    static var currentBuild: Int {
        if let buildStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
           let num = Int(buildStr) {
            return num
        }
        return fallbackBuild
    }
}

struct GitHubUpdateInfo: Equatable {
    let version: String
    let build: Int
    let tag: String
    let title: String
    let notes: String
    let mandatory: Bool
    let releaseURL: String
    let downloadURL: String
    let sourceLabel: String
    let commitSHA: String
    let updatedAt: String
}

enum AppUpdateStatus: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable
    case updating
    case updatedNeedsRestart
    case failed(String)
}
