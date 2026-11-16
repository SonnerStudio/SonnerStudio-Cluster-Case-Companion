import Foundation

enum ClusterOverviewScope: String, CaseIterable, Identifiable {
    case local = "local"
    case internet = "internet"
    case hybrid = "hybrid"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .local: return "macstudio.fill"
        case .internet: return "globe.americas.fill"
        case .hybrid: return "point.3.connected.trianglepath.dotted"
        }
    }
}

enum NavigationTab: String, CaseIterable, Identifiable {
    case overview = "Cluster-Übersicht"
    case devices = "Geräte & Vergleich"
    case models = "Modell-Studio"
    case network = "Netzwerk & RDMA"
    case internetCluster = "Internet-Verbund & Chat"
    case multiModelMode = "Multi-Model-Mode"
    case agents = "Agenten & IDEs"
    case science = "Forschung & Roofline"
    case console = "API & Konsole"
    case setup = "Setup & Einrichten"
    case help = "Hilfe & Handbuch"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "cpu.fill"
        case .devices: return "macstudio.fill"
        case .models: return "square.stack.3d.up.fill"
        case .network: return "bolt.horizontal.circle.fill"
        case .internetCluster: return "globe.americas.fill"
        case .multiModelMode: return "rectangle.3.group.fill"
        case .agents: return "sparkles.rectangle.stack.fill"
        case .science: return "chart.xyaxis.line"
        case .console: return "terminal.fill"
        case .setup: return "wand.and.stars"
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
        case .multiModelMode: return "Ensemble, MoA & Speculative"
        case .agents: return "Lokale Agenten, IDEs & SDKs"
        case .science: return "arXiv, Splitwise & Tuning"
        case .console: return "OpenAI / Ollama / oMLX API"
        case .setup: return "Auto-Setup & Bereitschaft"
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
        localizedDescription(.de)
    }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .omlx:
            return L10n.tr(lang, de: "oMLX (SSD KV-Cache)", en: "oMLX (SSD KV Cache)", fr: "oMLX (Cache KV SSD)", es: "oMLX (Caché KV SSD)", pt: "oMLX (Cache KV SSD)", ru: "oMLX (SSD KV-кэш)", ja: "oMLX (SSD KVキャッシュ)", zh: "oMLX (SSD KV 缓存)")
        case .ollama, .llamaCpp:
            return rawValue
        }
    }

    func localizedDescription(_ lang: AppLanguage) -> String {
        switch self {
        case .omlx:
            return L10n.tr(
                lang,
                de: "Nativer macOS-MLX-Server mit Paged SSD KV-Cache, OpenAI (/v1) & Anthropic (/v1/messages) API.",
                en: "Native macOS MLX server with paged SSD KV cache, OpenAI (/v1) & Anthropic (/v1/messages) API.",
                fr: "Serveur MLX natif macOS avec cache KV SSD paginé, API OpenAI (/v1) et Anthropic (/v1/messages).",
                es: "Servidor MLX nativo para macOS con caché KV SSD paginado y API OpenAI (/v1) / Anthropic (/v1/messages).",
                pt: "Servidor MLX nativo para macOS com cache KV SSD paginada e API OpenAI (/v1) / Anthropic (/v1/messages).",
                ru: "Нативный сервер macOS MLX с подкачкой KV-кэша на SSD, OpenAI (/v1) и Anthropic (/v1/messages) API.",
                ja: "ページングSSD KVキャッシュ・OpenAI (/v1)・Anthropic (/v1/messages) API対応のネイティブmacOS MLXサーバー。",
                zh: "原生 macOS MLX 服务器，支持分页 SSD KV 缓存、OpenAI (/v1) 与 Anthropic (/v1/messages) 接口。"
            )
        case .ollama:
            return L10n.tr(
                lang,
                de: "Lokaler Modell-Dienst auf Port 11434 — ideal für Zero-Config & breite Client-Unterstützung.",
                en: "Local model service on port 11434 — ideal for zero-config setup and broad client compatibility.",
                fr: "Service de modèles local sur le port 11434 — idéal pour une configuration zéro et une compatibilité étendue.",
                es: "Servicio local de modelos en el puerto 11434 — ideal para configuración cero y amplia compatibilidad.",
                pt: "Serviço local de modelos na porta 11434 — ideal para configuração zero e ampla compatibilidade.",
                ru: "Локальный сервис моделей на порту 11434 — удобен для быстрого запуска и широкой совместимости.",
                ja: "ポート11434のローカルモデルサービス — ゼロ設定と幅広いクライアント互換性に最適。",
                zh: "端口 11434 本地模型服务 — 零配置即用，兼容各类客户端。"
            )
        case .llamaCpp:
            return L10n.tr(
                lang,
                de: "Direkter GGUF-/llama-server-Dienst (Port 8080) oder Import nach schnellem MLX.",
                en: "Direct GGUF/llama-server service (port 8080) or fast conversion/import to MLX.",
                fr: "Service GGUF/llama-server direct (port 8080) ou import vers MLX rapide.",
                es: "Servicio directo GGUF/llama-server (puerto 8080) o importación a MLX rápido.",
                pt: "Serviço direto GGUF/llama-server (porta 8080) ou importação rápida para MLX.",
                ru: "Прямой сервис GGUF/llama-server (порт 8080) или импорт в быстрый MLX.",
                ja: "直接のGGUF/llama-serverサービス (ポート8080) または高速MLXへのインポート。",
                zh: "直接运行 GGUF/llama-server 服务（端口 8080）或导入为高速 MLX。"
            )
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

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .fp16:
            return L10n.tr(lang, de: "FP16 (Standard)", en: "FP16 (Default)", fr: "FP16 (Standard)", es: "FP16 (Estándar)", pt: "FP16 (Padrão)", ru: "FP16 (Стандарт)", ja: "FP16 (標準)", zh: "FP16（标准）")
        case .q8, .q4:
            return rawValue
        }
    }

    var memoryFactor: Double {
        switch self {
        case .fp16: return 1.0
        case .q8: return 0.52
        case .q4: return 0.28
        }
    }

    var maxContextEstimate: String {
        localizedMaxContextEstimate(.de)
    }

    func localizedMaxContextEstimate(_ lang: AppLanguage) -> String {
        let unit = L10n.tr(lang, de: "Tokens", en: "Tokens", fr: "Jetons", es: "Tokens", pt: "Tokens", ru: "токенов", ja: "トークン", zh: "Tokens")
        switch self {
        case .fp16: return "~16k \(unit)"
        case .q8: return "~32k \(unit)"
        case .q4: return "~64k+ \(unit)"
        }
    }
}

enum TransportMode: String, CaseIterable, Identifiable {
    case autoHybrid = "Auto-Hybrid (Empfohlen)"
    case thunderboltOnly = "Thunderbolt-Only"
    case lanWlanOnly = "LAN / WLAN-Only"
    case rdmaExperimental = "RDMA / JACCL (Opt-In)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .autoHybrid:
            return L10n.tr(lang, de: "Auto-Hybrid (Empfohlen)", en: "Auto-Hybrid (Recommended)", fr: "Auto-Hybride (Recommandé)", es: "Auto-Híbrido (Recomendado)", pt: "Auto-Híbrido (Recomendado)", ru: "Авто-гибрид (рекоменд.)", ja: "自動ハイブリッド（推奨）", zh: "自动混合模式（推荐）")
        case .thunderboltOnly:
            return L10n.tr(lang, de: "Thunderbolt-Only", en: "Thunderbolt Only", fr: "Thunderbolt uniquement", es: "Solo Thunderbolt", pt: "Apenas Thunderbolt", ru: "Только Thunderbolt", ja: "Thunderbolt 専用", zh: "仅 Thunderbolt")
        case .lanWlanOnly:
            return L10n.tr(lang, de: "LAN / WLAN-Only", en: "LAN / Wi-Fi Only", fr: "LAN / Wi-Fi uniquement", es: "Solo LAN / Wi-Fi", pt: "Apenas LAN / Wi-Fi", ru: "Только LAN / Wi-Fi", ja: "LAN / Wi-Fi 専用", zh: "仅 LAN / Wi-Fi")
        case .rdmaExperimental:
            return L10n.tr(lang, de: "RDMA / JACCL (Opt-In)", en: "RDMA / JACCL (Opt-In)", fr: "RDMA / JACCL (Opt-In)", es: "RDMA / JACCL (Opcional)", pt: "RDMA / JACCL (Opcional)", ru: "RDMA / JACCL (вручную)", ja: "RDMA / JACCL（オプトイン）", zh: "RDMA / JACCL（主动启用）")
        }
    }

    var description: String {
        localizedDescription(.de)
    }

    func localizedDescription(_ lang: AppLanguage) -> String {
        switch self {
        case .autoHybrid:
            return L10n.tr(
                lang,
                de: "Control Plane über LAN/WLAN · Tensor-Daten exklusiv über Thunderbolt (30–37 Gbps) mit automatischem Fallback.",
                en: "Control plane over LAN/Wi-Fi · Tensor traffic exclusively over Thunderbolt (30–37 Gbps) with automatic fallback.",
                fr: "Plan de contrôle via LAN/Wi-Fi · Tenseurs exclusivement sur Thunderbolt (30–37 Gbps) avec repli automatique.",
                es: "Plano de control por LAN/Wi-Fi · Tensores exclusivamente por Thunderbolt (30–37 Gbps) con respaldo automático.",
                pt: "Plano de controlo por LAN/Wi-Fi · Tensores exclusivamente por Thunderbolt (30–37 Gbps) com contingência automática.",
                ru: "Управление по LAN/Wi-Fi · Тензоры исключительно через Thunderbolt (30–37 Гбит/с) с автопереключением.",
                ja: "制御プレーンはLAN/Wi-Fi・テンソル転送はThunderbolt (30–37 Gbps) 専用で自動フォールバック対応。",
                zh: "控制面走 LAN/Wi-Fi · 张量数据独占 Thunderbolt (30–37 Gbps)，支持自动回退。"
            )
        case .thunderboltOnly:
            return L10n.tr(
                lang,
                de: "Erzwingt punkt-zu-punkt Thunderbolt-IPs (10.99.1.x) für maximale Isolation ohne WLAN-Jitter.",
                en: "Enforces point-to-point Thunderbolt IPs (10.99.1.x) for maximum isolation without Wi-Fi jitter.",
                fr: "Impose des IP Thunderbolt point à point (10.99.1.x) pour une isolation maximale sans gigue Wi-Fi.",
                es: "Fuerza IPs Thunderbolt punto a punto (10.99.1.x) para máximo aislamiento sin jitter Wi-Fi.",
                pt: "Força IPs Thunderbolt ponto-a-ponto (10.99.1.x) para isolamento máximo sem jitter Wi-Fi.",
                ru: "Принудительные P2P Thunderbolt IP (10.99.1.x) для максимальной изоляции без джиттера Wi-Fi.",
                ja: "P2P Thunderbolt IP (10.99.1.x) を強制し、Wi-Fiジッターのない完全分離を実現します。",
                zh: "强制点对点 Thunderbolt 专用 IP (10.99.1.x)，消除 Wi-Fi 抖动实现完全隔离。"
            )
        case .lanWlanOnly:
            return L10n.tr(
                lang,
                de: "Nutzt Ethernet/WLAN für alle Transfers — ideal zum Testen ohne TB-Kabel.",
                en: "Uses Ethernet/Wi-Fi for all transfers — ideal for testing without a Thunderbolt cable.",
                fr: "Utilise Ethernet/Wi-Fi pour tous les transferts — idéal pour tester sans câble Thunderbolt.",
                es: "Usa Ethernet/Wi-Fi para todas las transferencias — ideal para probar sin cable Thunderbolt.",
                pt: "Usa Ethernet/Wi-Fi para todas as transferências — ideal para testar sem cabo Thunderbolt.",
                ru: "Использует Ethernet/Wi-Fi для всех передач — удобно для тестов без кабеля Thunderbolt.",
                ja: "すべての転送にEthernet/Wi-Fiを使用 — TBケーブルなしでのテストに最適です。",
                zh: "所有传输均使用以太网 / Wi-Fi — 适合无 Thunderbolt 线缆时测试。"
            )
        case .rdmaExperimental:
            return L10n.tr(
                lang,
                de: "Nutzt MLX JACCL über RDMA Verbs (ab TB5 nativ; für TB4 ist ein Community-Enabler nötig).",
                en: "Uses MLX JACCL over RDMA Verbs (native on TB5+; TB4 requires a community enabler).",
                fr: "Utilise MLX JACCL sur RDMA Verbs (natif dès TB5 ; un module tiers est requis sur TB4).",
                es: "Usa MLX JACCL sobre RDMA Verbs (nativo en TB5+; TB4 requiere un habilitador comunitario).",
                pt: "Usa MLX JACCL sobre RDMA Verbs (nativo no TB5+; TB4 requer ativador da comunidade).",
                ru: "Использует MLX JACCL через RDMA Verbs (нативно с TB5; для TB4 нужен модификатор).",
                ja: "RDMA Verbs経由でMLX JACCLを使用（TB5以降はネイティブ対応、TB4ではコミュニティ有効化が必要）。",
                zh: "通过 RDMA Verbs 运行 MLX JACCL（TB5 原生支持；TB4 需社区启用补丁）。"
            )
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

    func localizedRole(_ lang: AppLanguage) -> String {
        if role.hasPrefix("Standalone") {
            return L10n.tr(lang, de: "Einzelbetrieb (Rang 0)", en: "Standalone (Rank 0)", fr: "Autonome (Rang 0)", es: "Individual (Rango 0)", pt: "Autónomo (Ranque 0)", ru: "Одиночный (Ранг 0)", ja: "スタンドアロン (Rank 0)", zh: "单机模式 (Rank 0)")
        }
        if role.hasPrefix("Coordinator") {
            return L10n.tr(lang, de: "Koordinator (Rang 0)", en: "Coordinator (Rank 0)", fr: "Coordinateur (Rang 0)", es: "Coordinador (Rango 0)", pt: "Coordenador (Ranque 0)", ru: "Координатор (Ранг 0)", ja: "コーディネーター (Rank 0)", zh: "协调器 (Rank 0)")
        }
        if role.hasPrefix("Worker (Rank "), let idxStr = role.components(separatedBy: "Rank ").last?.replacingOccurrences(of: ")", with: "") {
            return L10n.tr(lang, de: "Worker (Rang \(idxStr))", en: "Worker (Rank \(idxStr))", fr: "Nœud (Rang \(idxStr))", es: "Trabajador (Rango \(idxStr))", pt: "Operário (Ranque \(idxStr))", ru: "Воркер (Ранг \(idxStr))", ja: "ワーカー (Rank \(idxStr))", zh: "工作节点 (Rank \(idxStr))")
        }
        return L10n.tr(lang, de: "Worker", en: "Worker", fr: "Nœud", es: "Trabajador", pt: "Operário", ru: "Воркер", ja: "ワーカー", zh: "工作节点")
    }

    func localizedThermal(_ lang: AppLanguage) -> String {
        let base = thermalLabel
            .replacingOccurrences(of: "Nominal (Kühl)", with: L10n.tr(lang, de: "Nominal (Kühl)", en: "Nominal (Cool)", fr: "Nominal (Frais)", es: "Nominal (Fresco)", pt: "Nominal (Fresco)", ru: "Номинал (холодн.)", ja: "正常（低温）", zh: "正常（凉爽）"))
            .replacingOccurrences(of: "Erhöht (Fair)", with: L10n.tr(lang, de: "Erhöht (Fair)", en: "Elevated (Fair)", fr: "Élevée (Modérée)", es: "Elevada (Moderada)", pt: "Elevada (Moderada)", ru: "Повышена", ja: "やや高め", zh: "偏高（尚可）"))
            .replacingOccurrences(of: "Hoch (Drosselung möglich)", with: L10n.tr(lang, de: "Hoch (Drosselung möglich)", en: "High (Throttling possible)", fr: "Élevée (bridage possible)", es: "Alta (posible limitación)", pt: "Alta (possível limitação)", ru: "Высокая (возможен троттлинг)", ja: "高温（スロットリング可能）", zh: "高温（可能降频）"))
            .replacingOccurrences(of: "Kritisch (Heiß)", with: L10n.tr(lang, de: "Kritisch (Heiß)", en: "Critical (Hot)", fr: "Critique (Chaud)", es: "Crítica (Caliente)", pt: "Crítica (Quente)", ru: "Критическая (перегрев)", ja: "危険（高温）", zh: "严重（过热）"))
            .replacingOccurrences(of: "Unbekannt", with: L10n.tr(lang, de: "Unbekannt", en: "Unknown", fr: "Inconnu", es: "Desconocido", pt: "Desconhecido", ru: "Неизвестно", ja: "不明", zh: "未知"))
        return base
    }

    func localizedPower(_ lang: AppLanguage) -> String {
        let ac = L10n.tr(lang, de: "Netzteil", en: "AC Power", fr: "Secteur", es: "Alimentación CA", pt: "Alimentação CA", ru: "сеть питания", ja: "AC電源", zh: "外接电源")
        let live = L10n.tr(lang, de: "live", en: "live", fr: "en direct", es: "en vivo", pt: "ao vivo", ru: "живые", ja: "実測", zh: "实时")
        return powerLabel
            .replacingOccurrences(of: "Netzteil", with: ac)
            .replacingOccurrences(of: "(live)", with: "(\(live))")
    }
}

enum ScienceScope: String, CaseIterable, Identifiable {
    case localCluster = "Lokal (TB/RDMA)"
    case internetWan = "Internet-WAN"
    case hybridCompare = "Vergleich (Lokal vs. WAN)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .localCluster:
            return L10n.tr(lang, de: "Lokal (TB/RDMA)", en: "Local (TB/RDMA)", fr: "Local (TB/RDMA)", es: "Local (TB/RDMA)", pt: "Local (TB/RDMA)", ru: "Локальный (TB/RDMA)", ja: "ローカル (TB/RDMA)", zh: "本地 (TB/RDMA)")
        case .internetWan:
            return L10n.tr(lang, de: "Internet-WAN", en: "Internet WAN", fr: "WAN Internet", es: "WAN Internet", pt: "WAN Internet", ru: "Интернет-WAN", ja: "インターネット WAN", zh: "互联网 WAN")
        case .hybridCompare:
            return L10n.tr(lang, de: "Vergleich (Lokal vs. WAN)", en: "Compare (Local vs. WAN)", fr: "Comparatif (Local vs WAN)", es: "Comparar (Local vs. WAN)", pt: "Comparar (Local vs. WAN)", ru: "Сравнение (Лок. и WAN)", ja: "比較 (ローカル vs WAN)", zh: "对比（本地 vs WAN）")
        }
    }
}

enum ScienceLabTab: String, CaseIterable, Identifiable {
    case roofline = "Roofline & Engpass"
    case wanTopology = "WAN-Topologie & Skalierung"
    case memoryKv = "Speicher & KV-Analyse"
    case energetics = "Energie, CO₂ & Kosten"
    case trialsExport = "Messreihen & Export"
    case historyLog = "Verlaufsaufzeichnung"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .roofline: return L10n.text("sci_tab_roofline", lang)
        case .wanTopology: return L10n.text("sci_tab_wan", lang)
        case .memoryKv: return L10n.text("sci_tab_memory", lang)
        case .energetics: return L10n.text("sci_tab_energy", lang)
        case .trialsExport: return L10n.text("sci_tab_trials", lang)
        case .historyLog: return L10n.text("sci_tab_history", lang)
        }
    }

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

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .globalAll: return L10n.tr(lang, de: "Global (Alle Messwerte)", en: "Global (All Metrics)", fr: "Global (Toutes mesures)", es: "Global (Todas las métricas)", pt: "Global (Todas as métricas)", ru: "Глобально (все метрики)", ja: "全体（全指標）", zh: "全局（全部指标）")
        case .throughput: return L10n.tr(lang, de: "Durchsatz (tok/s)", en: "Throughput (tok/s)", fr: "Débit (tok/s)", es: "Rendimiento (tok/s)", pt: "Débito (tok/s)", ru: "Скорость (tok/s)", ja: "スループット (tok/s)", zh: "吞吐率 (tok/s)")
        case .latency: return L10n.tr(lang, de: "Latenz (TTFT / TPOT)", en: "Latency (TTFT / TPOT)", fr: "Latence (TTFT / TPOT)", es: "Latencia (TTFT / TPOT)", pt: "Latência (TTFT / TPOT)", ru: "Задержка (TTFT / TPOT)", ja: "遅延 (TTFT / TPOT)", zh: "延迟 (TTFT / TPOT)")
        case .energetics: return L10n.tr(lang, de: "Energie & CO₂ (J/tok)", en: "Energy & CO₂ (J/tok)", fr: "Énergie & CO₂ (J/tok)", es: "Energía y CO₂ (J/tok)", pt: "Energia e CO₂ (J/tok)", ru: "Энергия и CO₂ (Дж/ток)", ja: "電力と CO₂ (J/tok)", zh: "能耗与 CO₂ (J/tok)")
        case .wanNetwork: return L10n.tr(lang, de: "WAN-RTT & Blase", en: "WAN RTT & Bubble", fr: "RTT WAN & Bulle", es: "WAN RTT y burbuja", pt: "WAN RTT e bolha", ru: "WAN RTT и пузырь", ja: "WAN RTT・バブル", zh: "WAN RTT 与气泡")
        case .memoryPool: return L10n.tr(lang, de: "Speicher & Kontext", en: "Memory & Context", fr: "Mémoire & Contexte", es: "Memoria y contexto", pt: "Memória e contexto", ru: "Память и контекст", ja: "メモリとコンテキスト", zh: "内存与上下文")
        }
    }
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
        localizedQualityNote(.de)
    }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .fp16Raw: return L10n.tr(lang, de: "FP16 (16-Bit Roh)", en: "FP16 (16-Bit Raw)", fr: "FP16 (Brut 16 bits)", es: "FP16 (16 bits sin compresión)", pt: "FP16 (16 bits bruto)", ru: "FP16 (16 бит без сжатия)", ja: "FP16 (16ビット非圧縮)", zh: "FP16（16 位原始）")
        case .fp8Quantized: return L10n.tr(lang, de: "FP8 / INT8 (2× Kompakt)", en: "FP8 / INT8 (2× Compact)", fr: "FP8 / INT8 (2× Compact)", es: "FP8 / INT8 (2× Compacto)", pt: "FP8 / INT8 (2× Compacto)", ru: "FP8 / INT8 (2× сжатие)", ja: "FP8 / INT8 (2× 圧縮)", zh: "FP8 / INT8（2× 压缩）")
        case .int4Block: return L10n.tr(lang, de: "INT4 Block (4× Kompakt)", en: "INT4 Block (4× Compact)", fr: "Bloc INT4 (4× Compact)", es: "Bloque INT4 (4× Compacto)", pt: "Bloco INT4 (4× Compacto)", ru: "INT4 Блок (4× сжатие)", ja: "INT4 ブロック (4× 圧縮)", zh: "INT4 分块（4× 压缩）")
        case .topKSparse: return L10n.tr(lang, de: "Top-K Dünnbesetzt (~6×)", en: "Top-K Sparse (~6×)", fr: "Top-K Creux (~6×)", es: "Top-K Disperso (~6×)", pt: "Top-K Esparso (~6×)", ru: "Top-K Разреженное (~6×)", ja: "Top-K スパース (~6×)", zh: "Top-K 稀疏（~6×）")
        }
    }

    func localizedQualityNote(_ lang: AppLanguage) -> String {
        switch self {
        case .fp16Raw: return L10n.tr(lang, de: "Verlustfrei (0,00 PPL-Abweichung)", en: "Lossless (0.00 PPL delta)", fr: "Sans perte (0,00 écart PPL)", es: "Sin pérdida (0,00 variación PPL)", pt: "Sem perdas (0,00 desvio PPL)", ru: "Без потерь (отклонение 0.00 PPL)", ja: "可逆・劣化なし (0.00 PPL)", zh: "无损传输 (0.00 PPL 偏差)")
        case .fp8Quantized: return L10n.tr(lang, de: "Vernachlässigbar (<0,02 PPL, Standard für Petals/SWARM)", en: "Negligible (<0.02 PPL, default for Petals/SWARM)", fr: "Négligeable (<0,02 PPL, standard Petals/SWARM)", es: "Insignificante (<0,02 PPL, estándar Petals/SWARM)", pt: "Desprezível (<0,02 PPL, padrão Petals/SWARM)", ru: "Ничтожно (<0.02 PPL, стандарт Petals/SWARM)", ja: "微小 (<0.02 PPL、Petals/SWARM標準)", zh: "极小 (<0.02 PPL，Petals/SWARM 默认)")
        case .int4Block: return L10n.tr(lang, de: "Gering (+0,08–0,15 PPL, ideal für schmale Uplink-Leitungen)", en: "Low (+0.08–0.15 PPL, ideal for narrow uplinks)", fr: "Faible (+0,08–0,15 PPL, idéal pour liens montants étroits)", es: "Bajo (+0,08–0,15 PPL, ideal para subidas estrechas)", pt: "Baixo (+0,08–0,15 PPL, ideal para uplinks curtos)", ru: "Малое (+0.08–0.15 PPL, для узких каналов)", ja: "低劣化 (+0.08–0.15 PPL、狭帯域アップリンク向け)", zh: "较低 (+0.08–0.15 PPL，适合窄带上传)")
        case .topKSparse: return L10n.tr(lang, de: "Messbar (+0,25–0,45 PPL, maximaler Durchsatz bei CGNAT/DERP)", en: "Measurable (+0.25–0.45 PPL, max throughput on CGNAT/DERP)", fr: "Mesurable (+0,25–0,45 PPL, débit maximal sur CGNAT/DERP)", es: "Medible (+0,25–0,45 PPL, máximo rendimiento en CGNAT/DERP)", pt: "Mensurável (+0,25–0,45 PPL, máximo débito em CGNAT/DERP)", ru: "Заметное (+0.25–0.45 PPL, макс. скорость CGNAT/DERP)", ja: "計測可能 (+0.25–0.45 PPL、CGNAT/DERP最大効率)", zh: "可测 (+0.25–0.45 PPL，CGNAT/DERP 下最高吞吐)")
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

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .norway: return L10n.tr(lang, de: "Norwegen / Wasserkraft (20 g/kWh)", en: "Norway / Hydro (20 g/kWh)", fr: "Norvège / Hydroélectricité (20 g/kWh)", es: "Noruega / Hidroeléctrica (20 g/kWh)", pt: "Noruega / Hídrica (20 g/kWh)", ru: "Норвегия / ГЭС (20 г/кВт·ч)", ja: "ノルウェー / 水力 (20 g/kWh)", zh: "挪威 / 水电 (20 g/kWh)")
        case .france: return L10n.tr(lang, de: "Frankreich / Kernkraft (55 g/kWh)", en: "France / Nuclear (55 g/kWh)", fr: "France / Nucléaire (55 g/kWh)", es: "Francia / Nuclear (55 g/kWh)", pt: "França / Nuclear (55 g/kWh)", ru: "Франция / АЭС (55 г/кВт·ч)", ja: "フランス / 原子力 (55 g/kWh)", zh: "法国 / 核电 (55 g/kWh)")
        case .euAverage: return L10n.tr(lang, de: "EU-Mittelwert (250 g/kWh)", en: "EU Average (250 g/kWh)", fr: "Moyenne UE (250 g/kWh)", es: "Promedio UE (250 g/kWh)", pt: "Média UE (250 g/kWh)", ru: "Средний по ЕС (250 г/кВт·ч)", ja: "EU平均 (250 g/kWh)", zh: "欧盟平均 (250 g/kWh)")
        case .germany: return L10n.tr(lang, de: "Deutschland (320 g/kWh)", en: "Germany (320 g/kWh)", fr: "Allemagne (320 g/kWh)", es: "Alemania (320 g/kWh)", pt: "Alemanha (320 g/kWh)", ru: "Германия (320 г/кВт·ч)", ja: "ドイツ (320 g/kWh)", zh: "德国 (320 g/kWh)")
        case .globalWan: return L10n.tr(lang, de: "Weltweiter WAN-Mix (360 g/kWh)", en: "Global WAN Mix (360 g/kWh)", fr: "Mix mondial WAN (360 g/kWh)", es: "Mix global WAN (360 g/kWh)", pt: "Mix global WAN (360 g/kWh)", ru: "Мировой микс WAN (360 г/кВт·ч)", ja: "世界WANミックス (360 g/kWh)", zh: "全球 WAN 混合电网 (360 g/kWh)")
        case .usAverage: return L10n.tr(lang, de: "USA-Mittelwert (380 g/kWh)", en: "US Average (380 g/kWh)", fr: "Moyenne USA (380 g/kWh)", es: "Promedio EE. UU. (380 g/kWh)", pt: "Média EUA (380 g/kWh)", ru: "Средний по США (380 г/кВт·ч)", ja: "米国平均 (380 g/kWh)", zh: "美国平均 (380 g/kWh)")
        }
    }

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

struct WanBandwidthSample: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let downloadMbps: Double
    let uploadMbps: Double
    let pingRttMs: Double
    let jitterMs: Double
    let packetLossPct: Double
    let tensorSyncMBs: Double
    let isLiveMeasurement: Bool
}

enum MultiModelScope: String, CaseIterable, Identifiable, Codable {
    case local = "Lokaler Cluster"
    case internet = "Internet-Cluster"
    case hybrid = "Lokal + Internet (Hybrid)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .local: return L10n.tr(lang, de: "Lokaler Cluster", en: "Local Cluster", fr: "Grappe locale", es: "Clúster local", pt: "Cluster local", ru: "Локальный кластер", ja: "ローカルクラスター", zh: "本地集群")
        case .internet: return L10n.tr(lang, de: "Internet-Cluster", en: "Internet Cluster", fr: "Grappe Internet", es: "Clúster Internet", pt: "Cluster Internet", ru: "Интернет-кластер", ja: "インターネットクラスター", zh: "互联网集群")
        case .hybrid: return L10n.tr(lang, de: "Lokal + Internet (Hybrid)", en: "Local + Internet (Hybrid)", fr: "Local + Internet (Hybride)", es: "Local + Internet (Híbrido)", pt: "Local + Internet (Híbrido)", ru: "Локальный + Интернет (Гибрид)", ja: "ローカル + インターネット (ハイブリッド)", zh: "本地 + 互联网（混合）")
        }
    }
}

enum MultiModelStrategy: String, CaseIterable, Identifiable, Codable {
    case parallelPool = "Paralleler Multi-Modell-Pool"
    case mixtureOfAgents = "Mixture-of-Agents (MoA)"
    case speculativeDecoding = "Speculative Decoding (Draft + Target)"
    case sequentialPipeline = "Sequenzielle Modell-Pipeline"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .parallelPool: return L10n.tr(lang, de: "Paralleler Multi-Modell-Pool", en: "Parallel Multi-Model Pool", fr: "Pool multi-modèles parallèle", es: "Pool paralelo multimodelo", pt: "Pool paralelo multimodelo", ru: "Параллельный пул моделей", ja: "並列マルチモデルプール", zh: "并行多模型池")
        case .mixtureOfAgents: return "Mixture-of-Agents (MoA)"
        case .speculativeDecoding: return L10n.tr(lang, de: "Speculative Decoding (Draft + Target)", en: "Speculative Decoding (Draft + Target)", fr: "Décodage spéculatif (Draft + Target)", es: "Decodificación especulativa (Draft + Target)", pt: "Descodificação especulativa (Draft + Target)", ru: "Speculative Decoding (Draft + Target)", ja: "投機的デコーディング (Draft + Target)", zh: "投机解码 (Draft + Target)")
        case .sequentialPipeline: return L10n.tr(lang, de: "Sequenzielle Modell-Pipeline", en: "Sequential Model Pipeline", fr: "Pipeline séquentiel de modèles", es: "Pipeline secuencial de modelos", pt: "Pipeline sequencial de modelos", ru: "Последовательный конвейер", ja: "逐次モデルパイプライン", zh: "顺序模型流水线")
        }
    }

    var summary: String {
        localizedSummary(.de)
    }

    func localizedSummary(_ lang: AppLanguage) -> String {
        switch self {
        case .parallelPool:
            return L10n.tr(lang, de: "Hält mehrere Modelle gleichzeitig in getrennten VRAM-Budgets (lokal & WAN) für parallele Anfragen.", en: "Keeps multiple models resident in separate VRAM budgets (local & WAN) for concurrent requests.", fr: "Maintient plusieurs modèles en parallèle dans des budgets VRAM séparés (local & WAN).", es: "Mantiene varios modelos activos en presupuestos VRAM separados (local y WAN) para peticiones paralelas.", pt: "Mantém vários modelos residentes em orçamentos VRAM separados (local e WAN) para pedidos paralelos.", ru: "Удерживает несколько моделей в раздельных бюджетах VRAM (локально и WAN) для параллельных запросов.", ja: "複数のモデルを別々のVRAM予算（ローカルおよびWAN）に常駐させ、並列リクエストを処理します。", zh: "在独立显存预算（本地与 WAN）中同时常驻多个模型以并发处理请求。")
        case .mixtureOfAgents:
            return L10n.tr(lang, de: "Sendet den Prompt parallel an mehrere Spezialisten-Modelle und führt die Antworten über einen Aggregator zusammen.", en: "Dispatches the prompt to multiple specialist models in parallel and synthesizes responses via an aggregator.", fr: "Envoie la requête en parallèle à plusieurs modèles spécialistes puis fusionne les réponses.", es: "Envía el prompt en paralelo a varios modelos especialistas y combina las respuestas mediante un agregador.", pt: "Envia o prompt em paralelo a vários modelos especialistas e sintetiza as respostas num agregador.", ru: "Отправляет запрос нескольким моделям-специалистам параллельно и объединяет ответы агрегатором.", ja: "プロンプトを複数の専門モデルへ並列送信し、アグリゲーターで統合します。", zh: "将提示并发发送至多个专家模型，并通过聚合器融合结果。")
        case .speculativeDecoding:
            return L10n.tr(lang, de: "Kombiniert ein schnelles lokales Draft-Modell mit einem großen Target-Modell im Verbund zur Beschleunigung.", en: "Pairs a fast local draft model with a large target model across the cluster to accelerate generation.", fr: "Combine un modèle draft local rapide avec un grand modèle cible sur la grappe pour accélérer l'inférence.", es: "Combina un modelo borrador local rápido con un modelo objetivo grande en el clúster para acelerar.", pt: "Combina um modelo draft local rápido com um modelo alvo grande no cluster para acelerar a geração.", ru: "Сочетает быструю локальную draft-модель с крупной target-моделью в кластере для ускорения.", ja: "高速なローカルDraftモデルと大規模Targetモデルを組み合わせて生成を高速化します。", zh: "将本地快速草案模型与集群大型目标模型结合以实现加速生成。")
        case .sequentialPipeline:
            return L10n.tr(lang, de: "Verkettet Modelle als Stufen (z. B. Planer → Coder → Reviewer) über lokale TB- und WAN-Knoten.", en: "Chains models sequentially (e.g. Planner → Coder → Reviewer) across local Thunderbolt and WAN nodes.", fr: "Chaîne les modèles en étapes (ex. Planificateur → Codeur → Relecteur) sur TB local et WAN.", es: "Encadena modelos por etapas (p. ej., Planificador → Programador → Revisor) en nodos TB locales y WAN.", pt: "Encadeia modelos em etapas (ex. Planeador → Programador → Revisor) entre nós TB locais e WAN.", ru: "Выстраивает модели цепочкой (Планировщик → Кодер → Ревьюер) по локальным и WAN-узлам.", ja: "ローカルTBノードとWANノード間でモデルを段階連鎖（設計→実装→レビュー）させます。", zh: "在本地 Thunderbolt 与 WAN 节点上将模型串联（规划→编码→审查）。")
        }
    }
}

enum MultiModelRole: String, CaseIterable, Identifiable, Codable {
    case primary = "Primary"
    case draft = "Draft"
    case specialist = "Specialist"
    case aggregator = "Aggregator"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .primary: return L10n.tr(lang, de: "Hauptmodell", en: "Primary", fr: "Principal", es: "Principal", pt: "Principal", ru: "Основная", ja: "メイン", zh: "主模型")
        case .draft: return L10n.tr(lang, de: "Entwurf (Draft)", en: "Draft", fr: "Brouillon (Draft)", es: "Borrador (Draft)", pt: "Rascunho (Draft)", ru: "Черновик (Draft)", ja: "ドラフト", zh: "草案 (Draft)")
        case .specialist: return L10n.tr(lang, de: "Spezialist", en: "Specialist", fr: "Spécialiste", es: "Especialista", pt: "Especialista", ru: "Специалист", ja: "スペシャリスト", zh: "专家模型")
        case .aggregator: return L10n.tr(lang, de: "Aggregator", en: "Aggregator", fr: "Agrégateur", es: "Agregador", pt: "Agregador", ru: "Агрегатор", ja: "アグリゲーター", zh: "聚合器")
        }
    }
}

enum MultiModelAutoProfile: String, CaseIterable, Identifiable, Codable {
    case balancedCoding = "Coding & IDE-Schwarm"
    case consensusReview = "Konsens & Audit"
    case fastSpeculative = "Turbo (Draft + Target)"
    case hybridPipeline = "Stufen-Pipeline"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .balancedCoding: return L10n.tr(lang, de: "Coding & IDE-Schwarm", en: "Coding & IDE Swarm", fr: "Code & Essaim d'EDI", es: "Código y enjambre IDE", pt: "Código e enxame IDE", ru: "Кодинг и рой IDE", ja: "コーディング & IDEスウォーム", zh: "编程与 IDE 蜂群")
        case .consensusReview: return L10n.tr(lang, de: "Konsens & Audit", en: "Consensus & Audit", fr: "Consensus & Audit", es: "Consenso y auditoría", pt: "Consenso e auditoria", ru: "Консенсус и аудит", ja: "合意と監査", zh: "共识与审计")
        case .fastSpeculative: return L10n.tr(lang, de: "Turbo (Draft + Target)", en: "Turbo (Draft + Target)", fr: "Turbo (Draft + Target)", es: "Turbo (Draft + Target)", pt: "Turbo (Draft + Target)", ru: "Турбо (Draft + Target)", ja: "ターボ (Draft + Target)", zh: "极速 (Draft + Target)")
        case .hybridPipeline: return L10n.tr(lang, de: "Stufen-Pipeline", en: "Staged Pipeline", fr: "Pipeline par étapes", es: "Pipeline por etapas", pt: "Pipeline por etapas", ru: "Поэтапный конвейер", ja: "段階パイプライン", zh: "阶段流水线")
        }
    }

    var recommendedStrategy: MultiModelStrategy {
        switch self {
        case .balancedCoding: return .parallelPool
        case .consensusReview: return .mixtureOfAgents
        case .fastSpeculative: return .speculativeDecoding
        case .hybridPipeline: return .sequentialPipeline
        }
    }

    var summary: String {
        localizedSummary(.de)
    }

    func localizedSummary(_ lang: AppLanguage) -> String {
        switch self {
        case .balancedCoding:
            return L10n.tr(lang, de: "Verteilt Haupt-Coder, Spezialist und Prüfer gleichmäßig über lokale & WAN-Knoten für mehrere IDEs.", en: "Balances Primary Coder, Specialist, and Reviewer across local & WAN nodes for multiple IDEs.", fr: "Répartit codeur principal, spécialiste et réviseur entre nœuds locaux et WAN.", es: "Equilibra programador principal, especialista y revisor entre nodos locales y WAN para varios IDEs.", pt: "Distribui programador principal, especialista e revisor por nós locais e WAN para vários IDEs.", ru: "Распределяет кодера, специалиста и ревьюера по локальным и WAN-узлам для нескольких IDE.", ja: "メインコーダー・専門モデル・レビュー担当をローカル/WANノードへ均等に割り当てます。", zh: "在本地和 WAN 节点上均衡部署主编码、专家和审查模型供多 IDE 并发使用。")
        case .consensusReview:
            return L10n.tr(lang, de: "Wählt bis zu 4 diverse Modelle im sicheren VRAM-Budget für parallele Abstimmung & Synthese.", en: "Selects up to 4 diverse models within safe VRAM limits for parallel consensus voting & synthesis.", fr: "Sélectionne jusqu'à 4 modèles diversifiés dans le budget VRAM pour vote et synthèse.", es: "Elige hasta 4 modelos diversos dentro del presupuesto VRAM seguro para votación paralela.", pt: "Seleciona até 4 modelos distintos dentro do limite VRAM seguro para votação paralela.", ru: "Выбирает до 4 разных моделей в пределах безопасной VRAM для консенсуса.", ja: "安全なVRAM予算内で最大4つの異なるモデルを選び並列合意・統合を行います。", zh: "在安全显存范围内挑选最多 4 个不同模型进行并行共识投票与综合。")
        case .fastSpeculative:
            return L10n.tr(lang, de: "Koppelt das kleinste schnelle Draft-Modell mit dem leistungsstärksten passenden Target-Modell.", en: "Pairs the fastest compact Draft model with the strongest fitting Target model.", fr: "Associe le plus rapide des modèles Draft au modèle Target le plus performant compatible.", es: "Empareja el modelo Draft más rápido con el modelo Target más potente que quepa en memoria.", pt: "Associa o modelo Draft mais rápido ao modelo Target mais capaz dentro da memória.", ru: "Соединяет самую быструю компактную Draft-модель с самой мощной Target-моделью.", ja: "最小・高速なDraftモデルと適合する最強Targetモデルを組み合わせます。", zh: "将最快的小型草案模型与可容纳的最强目标模型配对。")
        case .hybridPipeline:
            return L10n.tr(lang, de: "Baut eine geordnete Kette (Planer → Coder → Reviewer) über TB5- und Internet-Knoten auf.", en: "Builds an ordered chain (Planner → Coder → Reviewer) across TB5 and Internet WAN nodes.", fr: "Construit une chaîne ordonnée (Planificateur → Codeur → Réviseur) sur TB5 et WAN.", es: "Construye una cadena ordenada (Planificador → Programador → Revisor) sobre nodos TB5 y WAN.", pt: "Constrói uma cadeia ordenada (Planeador → Programador → Revisor) em nós TB5 e WAN.", ru: "Строит упорядоченную цепочку (Планировщик → Кодер → Ревьюер) через TB5 и WAN.", ja: "TB5およびインターネットノード上に順序付きチェーン（設計→実装→レビュー）を構築します。", zh: "跨 TB5 与广域网节点构建有序链条（规划→编码→审查）。")
        }
    }
}

struct MultiModelSlot: Identifiable, Hashable, Codable {
    let id: UUID
    var modelId: String
    var displayName: String
    var role: MultiModelRole
    var assignedTarget: String
    var endpointURL: String
    var estimatedRamGB: Double
    var isEnabled: Bool
    var lastTokPerSec: Double
    var lastTtftMs: Double

    init(
        id: UUID = UUID(),
        modelId: String,
        displayName: String,
        role: MultiModelRole,
        assignedTarget: String,
        endpointURL: String,
        estimatedRamGB: Double,
        isEnabled: Bool = true,
        lastTokPerSec: Double = 0.0,
        lastTtftMs: Double = 0.0
    ) {
        self.id = id
        self.modelId = modelId
        self.displayName = displayName
        self.role = role
        self.assignedTarget = assignedTarget
        self.endpointURL = endpointURL
        self.estimatedRamGB = estimatedRamGB
        self.isEnabled = isEnabled
        self.lastTokPerSec = lastTokPerSec
        self.lastTtftMs = lastTtftMs
    }
}

struct MultiModelRunResult: Identifiable, Hashable {
    let id = UUID()
    let timestamp: String
    let strategy: MultiModelStrategy
    let scope: MultiModelScope
    let activeModelsCount: Int
    let combinedTokPerSec: Double
    let aggregateTtftMs: Double
    let totalVramUsedGB: Double
    let usableVramPoolGB: Double
    let speedupFactor: Double
    let responsePreview: String
    let isLiveExecution: Bool
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

    func localizedSourceLabel(_ lang: AppLanguage) -> String {
        switch sourceLabel {
        case "Referenz":
            return L10n.tr(lang, de: "Referenz", en: "Reference", fr: "Référence", es: "Referencia", pt: "Referência", ru: "Эталон", ja: "リファレンス", zh: "参考")
        case "Lokal GGUF":
            return L10n.tr(lang, de: "Lokal GGUF", en: "Local GGUF", fr: "GGUF local", es: "GGUF local", pt: "GGUF local", ru: "Локальный GGUF", ja: "ローカル GGUF", zh: "本地 GGUF")
        default:
            return sourceLabel
        }
    }

    func localizedNotes(_ lang: AppLanguage) -> String {
        if notes.hasPrefix("Lokale GGUF-Datei (") {
            let folder = notes.replacingOccurrences(of: "Lokale GGUF-Datei (", with: "").replacingOccurrences(of: ")", with: "")
            return L10n.tr(lang,
                de: "Lokale GGUF-Datei (\(folder))",
                en: "Local GGUF file (\(folder))",
                fr: "Fichier GGUF local (\(folder))",
                es: "Archivo GGUF local (\(folder))",
                pt: "Arquivo GGUF local (\(folder))",
                ru: "Локальный файл GGUF (\(folder))",
                ja: "ローカル GGUF ファイル (\(folder))",
                zh: "本地 GGUF 文件 (\(folder))")
        }
        switch notes {
        case "Referenzprofil · kompakter Verbund oder Einzel-Mac ab 24 GB":
            return L10n.tr(lang,
                de: notes,
                en: "Reference profile · compact cluster or single Mac (24 GB+)",
                fr: "Profil de référence · cluster compact ou Mac unique dès 24 Go",
                es: "Perfil de referencia · clúster compacto o Mac único desde 24 GB",
                pt: "Perfil de referência · cluster compacto ou Mac único (24 GB+)",
                ru: "Эталонный профиль · компактный кластер или один Mac от 24 ГБ",
                ja: "参照プロファイル · 24 GB以上の単体Macまたは小規模クラスタ",
                zh: "参考配置 · 紧凑型集群或 24 GB+ 单台 Mac")
        case "Referenzprofil · Schlussfolgerungs-Modell im Verbund":
            return L10n.tr(lang,
                de: notes,
                en: "Reference profile · distributed reasoning model",
                fr: "Profil de référence · modèle de raisonnement distribué",
                es: "Perfil de referencia · modelo de razonamiento distribuido",
                pt: "Perfil de referência · modelo de raciocínio distribuído",
                ru: "Эталонный профиль · распределённая модель рассуждений",
                ja: "参照プロファイル · クラスタ向け推論モデル",
                zh: "参考配置 · 集群分布式推理模型")
        case "Referenzprofil · großer Verbund ab ~48 GB nutzbarem Speicher":
            return L10n.tr(lang,
                de: notes,
                en: "Reference profile · large cluster (~48 GB+ usable RAM)",
                fr: "Profil de référence · grand cluster (~48 Go+ utilisables)",
                es: "Perfil de referencia · clúster grande (~48 GB+ utilizables)",
                pt: "Perfil de referência · grande cluster (~48 GB+ utilizáveis)",
                ru: "Эталонный профиль · крупный кластер (от ~48 ГБ доступной памяти)",
                ja: "参照プロファイル · 約48 GB以上の大規模クラスタ",
                zh: "参考配置 · ~48 GB+ 可用显存的大型集群")
        case "Referenzprofil · Hochkapazitäts-Verbund (z. B. Ultra / Multi-Max)":
            return L10n.tr(lang,
                de: notes,
                en: "Reference profile · high-capacity cluster (e.g., Ultra / Multi-Max)",
                fr: "Profil de référence · cluster haute capacité (ex. Ultra / Multi-Max)",
                es: "Perfil de referencia · clúster de alta capacidad (p. ej., Ultra / Multi-Max)",
                pt: "Perfil de referência · cluster de alta capacidade (ex.: Ultra / Multi-Max)",
                ru: "Эталонный профиль · высокоёмкий кластер (напр., Ultra / Multi-Max)",
                ja: "参照プロファイル · 大容量クラスタ（Ultra / Multi-Max 等）",
                zh: "参考配置 · 超大容量集群（如 Ultra / Multi-Max）")
        case "Live erkannt über oMLX (:8000)":
            return L10n.tr(lang,
                de: notes,
                en: "Live detected via oMLX (:8000)",
                fr: "Détecté en direct via oMLX (:8000)",
                es: "Detectado en vivo vía oMLX (:8000)",
                pt: "Detetado em direto via oMLX (:8000)",
                ru: "Обнаружено в реальном времени через oMLX (:8000)",
                ja: "oMLX (:8000) 経由でライブ検出",
                zh: "通过 oMLX (:8000) 实时检测到")
        case "Live erkannt über Ollama (:11434)":
            return L10n.tr(lang,
                de: notes,
                en: "Live detected via Ollama (:11434)",
                fr: "Détecté en direct via Ollama (:11434)",
                es: "Detectado en vivo vía Ollama (:11434)",
                pt: "Detetado em direto via Ollama (:11434)",
                ru: "Обнаружено в реальном времени через Ollama (:11434)",
                ja: "Ollama (:11434) 経由でライブ検出",
                zh: "通过 Ollama (:11434) 实时检测到")
        case "Live erkannt über llama.cpp (:8080)":
            return L10n.tr(lang,
                de: notes,
                en: "Live detected via llama.cpp (:8080)",
                fr: "Détecté en direct via llama.cpp (:8080)",
                es: "Detectado en vivo vía llama.cpp (:8080)",
                pt: "Detetado em direto via llama.cpp (:8080)",
                ru: "Обнаружено в реальном времени через llama.cpp (:8080)",
                ja: "llama.cpp (:8080) 経由でライブ検出",
                zh: "通过 llama.cpp (:8080) 实时检测到")
        case "Live erkannt über Ollama CLI":
            return L10n.tr(lang,
                de: notes,
                en: "Live detected via Ollama CLI",
                fr: "Détecté en direct via Ollama CLI",
                es: "Detectado en vivo vía Ollama CLI",
                pt: "Detetado em direto via Ollama CLI",
                ru: "Обнаружено через Ollama CLI",
                ja: "Ollama CLI 経由でライブ検出",
                zh: "通过 Ollama CLI 实时检测到")
        case "Lokaler HuggingFace-/MLX-Cache":
            return L10n.tr(lang,
                de: notes,
                en: "Local HuggingFace / MLX cache",
                fr: "Cache local HuggingFace / MLX",
                es: "Caché local de HuggingFace / MLX",
                pt: "Cache local HuggingFace / MLX",
                ru: "Локальный кэш HuggingFace / MLX",
                ja: "ローカル HuggingFace / MLX キャッシュ",
                zh: "本地 HuggingFace / MLX 缓存")
        default:
            return notes
        }
    }
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

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .tailscaleMesh: return "Tailscale / WireGuard Mesh (100.64.x.x)"
        case .wireGuardDirect: return L10n.tr(lang, de: "WireGuard P2P Tunnel (ChaCha20)", en: "WireGuard P2P Tunnel (ChaCha20)", fr: "Tunnel WireGuard P2P (ChaCha20)", es: "Túnel P2P WireGuard (ChaCha20)", pt: "Túnel P2P WireGuard (ChaCha20)", ru: "Туннель WireGuard P2P (ChaCha20)", ja: "WireGuard P2P トンネル (ChaCha20)", zh: "WireGuard P2P 隧道 (ChaCha20)")
        case .libp2pQuic: return L10n.tr(lang, de: "libp2p / QUIC + DCUtR (Petals-Stil)", en: "libp2p / QUIC + DCUtR (Petals-style)", fr: "libp2p / QUIC + DCUtR (style Petals)", es: "libp2p / QUIC + DCUtR (estilo Petals)", pt: "libp2p / QUIC + DCUtR (estilo Petals)", ru: "libp2p / QUIC + DCUtR (стиль Petals)", ja: "libp2p / QUIC + DCUtR (Petals方式)", zh: "libp2p / QUIC + DCUtR（Petals 风格）")
        case .derpRelay: return L10n.tr(lang, de: "Verschlüsselter DERP / WebSocket-Relay", en: "Encrypted DERP / WebSocket Relay", fr: "Relais chiffré DERP / WebSocket", es: "Relé cifrado DERP / WebSocket", pt: "Retransmissor cifrado DERP / WebSocket", ru: "Шифрованный DERP / WebSocket-релей", ja: "暗号化 DERP / WebSocket リレー", zh: "加密 DERP / WebSocket 中继")
        }
    }

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
        localizedNatNote(.de)
    }

    func localizedNatNote(_ lang: AppLanguage) -> String {
        switch self {
        case .tailscaleMesh:
            return L10n.tr(lang, de: "Automatisches UDP-Hole-Punching über CGNAT (100.64.0.0/10) mit DERP-Rückfall.", en: "Automatic UDP hole punching across CGNAT (100.64.0.0/10) with DERP fallback.", fr: "Perforation UDP automatique via CGNAT (100.64.0.0/10) avec repli DERP.", es: "Perforación UDP automática tras CGNAT (100.64.0.0/10) con respaldo DERP.", pt: "Perfuração UDP automática em CGNAT (100.64.0.0/10) com contingência DERP.", ru: "Автоматический UDP hole-punching через CGNAT (100.64.0.0/10) с резервом DERP.", ja: "CGNAT (100.64.0.0/10) 越えの自動UDPホールパンチングとDERPフォールバック。", zh: "支持 CGNAT (100.64.0.0/10) 自动 UDP 打洞与 DERP 回退。")
        case .wireGuardDirect:
            return L10n.tr(lang, de: "Direkter Layer-3-Tunnel (ChaCha20-Poly1305) mit minimalem Protokoll-Overhead.", en: "Direct Layer-3 tunnel (ChaCha20-Poly1305) with minimal protocol overhead.", fr: "Tunnel Layer-3 direct (ChaCha20-Poly1305) à surcoût minimal.", es: "Túnel directo de capa 3 (ChaCha20-Poly1305) con sobrecarga mínima.", pt: "Túnel direto de camada 3 (ChaCha20-Poly1305) com sobrecarga mínima.", ru: "Прямой туннель Layer-3 (ChaCha20-Poly1305) с минимальными накладными расходами.", ja: "最小オーバーヘッドの直接Layer-3トンネル (ChaCha20-Poly1305)。", zh: "直接三层隧道（ChaCha20-Poly1305），协议开销极低。")
        case .libp2pQuic:
            return L10n.tr(lang, de: "Dezentrales Kademlia-DHT & DCUtR-Hole-Punching ohne zentralen VPN-Server.", en: "Decentralized Kademlia DHT & DCUtR hole punching with no central VPN server.", fr: "DHT Kademlia décentralisé & perforation DCUtR sans serveur VPN central.", es: "DHT Kademlia descentralizada y DCUtR sin servidor VPN central.", pt: "DHT Kademlia descentralizada e DCUtR sem servidor VPN central.", ru: "Децентрализованный Kademlia DHT и DCUtR без центрального VPN-сервера.", ja: "中央VPN不要の分散Kademlia DHTとDCUtRホールパンチング。", zh: "去中心化 Kademlia DHT 与 DCUtR 打洞，无需中心 VPN 服务器。")
        case .derpRelay:
            return L10n.tr(lang, de: "Ende-zu-Ende-verschlüsselter TCP/WSS-Relay für strenge Firmen-Firewalls.", en: "End-to-end encrypted TCP/WSS relay for strict corporate firewalls.", fr: "Relais TCP/WSS chiffré de bout en bout pour pare-feux stricts.", es: "Relé TCP/WSS cifrado de extremo a extremo para cortafuegos corporativos estrictos.", pt: "Retransmissor TCP/WSS cifrado ponto-a-ponto para firewalls restritivas.", ru: "Сквозной шифрованный TCP/WSS-релей для строгих корпоративных брандмауэров.", ja: "厳格な企業ファイアウォール向けのE2E暗号化TCP/WSSリレー。", zh: "端到端加密 TCP/WSS 中继，穿透严格企业防火墙。")
        }
    }
}

enum InternetClusterScale: String, CaseIterable, Identifiable {
    case privateTeam = "Privates Team (2–8 Macs)"
    case researchSwarm = "Forschungs-Schwarm (8–32 Macs)"
    case megaCluster = "Riesiger Welt-Verbund (32–256+ Macs)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .privateTeam: return L10n.tr(lang, de: "Privates Team (2–8 Macs)", en: "Private Team (2–8 Macs)", fr: "Équipe privée (2–8 Mac)", es: "Equipo privado (2–8 Macs)", pt: "Equipa privada (2–8 Macs)", ru: "Частная команда (2–8 Mac)", ja: "プライベートチーム (2–8台)", zh: "私人团队（2–8 台 Mac）")
        case .researchSwarm: return L10n.tr(lang, de: "Forschungs-Schwarm (8–32 Macs)", en: "Research Swarm (8–32 Macs)", fr: "Essaim de recherche (8–32 Mac)", es: "Enjambre de investigación (8–32 Macs)", pt: "Enxame de investigação (8–32 Macs)", ru: "Исследовательский рой (8–32 Mac)", ja: "研究スウォーム (8–32台)", zh: "科研集群（8–32 台 Mac）")
        case .megaCluster: return L10n.tr(lang, de: "Riesiger Welt-Verbund (32–256+ Macs)", en: "Global Mega Cluster (32–256+ Macs)", fr: "Méga-grappe mondiale (32–256+ Mac)", es: "Megaclúster global (32–256+ Macs)", pt: "Megacluster global (32–256+ Macs)", ru: "Глобальный мегакластер (32–256+ Mac)", ja: "グローバルメガクラスター (32–256+台)", zh: "全球超级集群（32–256+ 台 Mac）")
        }
    }
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

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .opus16: return L10n.tr(lang, de: "Opus 16 kbps (WAN-Sparmodus)", en: "Opus 16 kbps (WAN Low-BW)", fr: "Opus 16 kbps (Éco WAN)", es: "Opus 16 kbps (Ahorro WAN)", pt: "Opus 16 kbps (Poupança WAN)", ru: "Opus 16 кбит/с (Эконом WAN)", ja: "Opus 16 kbps (WAN省帯域)", zh: "Opus 16 kbps（WAN 省流）")
        case .opus32: return L10n.tr(lang, de: "Opus 32 kbps (Klar · Standard)", en: "Opus 32 kbps (Clear · Default)", fr: "Opus 32 kbps (Clair · Défaut)", es: "Opus 32 kbps (Claro · Estándar)", pt: "Opus 32 kbps (Nítido · Padrão)", ru: "Opus 32 кбит/с (Чётко · Стандарт)", ja: "Opus 32 kbps (クリア · 標準)", zh: "Opus 32 kbps（清晰·默认）")
        case .opus64: return L10n.tr(lang, de: "Opus 64 kbps (Studio-Sprache)", en: "Opus 64 kbps (Studio Voice)", fr: "Opus 64 kbps (Voix Studio)", es: "Opus 64 kbps (Voz de estudio)", pt: "Opus 64 kbps (Voz de estúdio)", ru: "Opus 64 кбит/с (Студийный)", ja: "Opus 64 kbps (スタジオ音声)", zh: "Opus 64 kbps（演播室音质）")
        }
    }

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

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .openMic: return L10n.tr(lang, de: "Offenes Mikrofon", en: "Open Mic", fr: "Micro ouvert", es: "Micrófono abierto", pt: "Microfone aberto", ru: "Открытый микрофон", ja: "常時マイク", zh: "自由麦")
        case .pushToTalk: return L10n.tr(lang, de: "Sprech-Taste (PTT)", en: "Push-to-Talk (PTT)", fr: "Appuyer pour parler (PTT)", es: "Pulsar para hablar (PTT)", pt: "Premir para falar (PTT)", ru: "Нажать для речи (PTT)", ja: "プッシュトゥトーク (PTT)", zh: "按键通话 (PTT)")
        case .alertsOnly: return L10n.tr(lang, de: "Nur Verbund-Warnungen", en: "Cluster Alerts Only", fr: "Alertes de grappe seules", es: "Solo alertas del clúster", pt: "Apenas alertas do cluster", ru: "Только оповещения кластера", ja: "クラスター警報のみ", zh: "仅集群告警")
        }
    }
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

    static let fallbackVersion = "1.6.42"
    static let fallbackBuild = 164
    static let embeddedCommitSHA = "b2ef2cc"

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

// MARK: - Phase 11: 2026 SOTA Architecture Upgrade Models (Points 1-5)

/// Punkt 1: TB5 RDMA Tensor Parallelism Topologie (Ring vs. Full-Mesh JACCL)
enum ClusterMeshTopology: String, CaseIterable, Identifiable, Codable {
    case ring = "Ring (Pipeline)"
    case fullMesh = "Full-Mesh (TB5 RDMA Tensor Parallelism)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .ring: return L10n.tr(lang, de: "Ring (Pipeline)", en: "Ring (Pipeline)", fr: "Anneau (Pipeline)", es: "Anillo (Pipeline)", pt: "Anel (Pipeline)", ru: "Кольцо (Pipeline)", ja: "リング (Pipeline)", zh: "环形（流水线）")
        case .fullMesh: return L10n.tr(lang, de: "Full-Mesh (TB5 RDMA Tensor Parallelism)", en: "Full-Mesh (TB5 RDMA Tensor Parallelism)", fr: "Maillage complet (TB5 RDMA Tensor)", es: "Malla completa (TB5 RDMA Tensor)", pt: "Malha completa (TB5 RDMA Tensor)", ru: "Full-Mesh (TB5 RDMA Tensor)", ja: "フルメッシュ (TB5 RDMA Tensor)", zh: "全互联（TB5 RDMA 张量并行）")
        }
    }

    var shortLabel: String {
        switch self {
        case .ring: return "Ring (PP)"
        case .fullMesh: return "Full-Mesh (TP/JACCL)"
        }
    }

    var bandwidthEfficiencyFactor: Double {
        switch self {
        case .ring: return 0.88
        case .fullMesh: return 1.18
        }
    }
}

/// Punkt 1: WAN-Transport-Protokoll (QUIC/Iroh P2P ohne TCP HoL-Blocking vs. Tailscale/WireGuard)
enum WanTransportProtocol: String, CaseIterable, Identifiable, Codable {
    case tailscaleWireGuard = "Tailscale / WireGuard (UDP/TCP)"
    case quicIrohP2P = "QUIC / Iroh P2P (0-RTT Multiplex)"
    case libp2pDerp = "libp2p + DERP Relay"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .tailscaleWireGuard: return "Tailscale / WireGuard (UDP/TCP)"
        case .quicIrohP2P: return L10n.tr(lang, de: "QUIC / Iroh P2P (0-RTT Multiplex)", en: "QUIC / Iroh P2P (0-RTT Multiplex)", fr: "QUIC / Iroh P2P (Multiplex 0-RTT)", es: "QUIC / Iroh P2P (Multiplex 0-RTT)", pt: "QUIC / Iroh P2P (Multiplex 0-RTT)", ru: "QUIC / Iroh P2P (0-RTT Мультиплекс)", ja: "QUIC / Iroh P2P (0-RTT多重)", zh: "QUIC / Iroh P2P（0-RTT 多路复用）")
        case .libp2pDerp: return L10n.tr(lang, de: "libp2p + DERP Relay", en: "libp2p + DERP Relay", fr: "Relais libp2p + DERP", es: "Relé libp2p + DERP", pt: "Relé libp2p + DERP", ru: "libp2p + DERP-релей", ja: "libp2p + DERP リレー", zh: "libp2p + DERP 中继")
        }
    }

    var latencyFactor: Double {
        switch self {
        case .tailscaleWireGuard: return 1.00
        case .quicIrohP2P: return 0.72
        case .libp2pDerp: return 1.12
        }
    }

    var zeroRttEnabled: Bool {
        self == .quicIrohP2P
    }
}

/// Punkt 2: Disaggregiertes Prefill / Decode (ANE-Prefill + MLX-Decode Split-Phase)
enum SplitPhaseComputeMode: String, CaseIterable, Identifiable, Codable {
    case unifiedGpu = "Unified GPU (Standard)"
    case anePrefillGpuDecode = "ANE Prefill + MLX GPU Decode (Split-Phase)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .unifiedGpu: return L10n.tr(lang, de: "Unified GPU (Standard)", en: "Unified GPU (Default)", fr: "GPU unifié (Standard)", es: "GPU unificada (Estándar)", pt: "GPU unificada (Padrão)", ru: "Общий GPU (Стандарт)", ja: "統合GPU (標準)", zh: "统一 GPU（标准）")
        case .anePrefillGpuDecode: return L10n.tr(lang, de: "ANE Prefill + MLX GPU Decode (Split-Phase)", en: "ANE Prefill + MLX GPU Decode (Split-Phase)", fr: "Préfill ANE + Décodage GPU MLX (Split-Phase)", es: "Prefill ANE + Decode GPU MLX (Fases separadas)", pt: "Prefill ANE + Decode GPU MLX (Fases separadas)", ru: "ANE Prefill + MLX GPU Decode (Раздельно)", ja: "ANE Prefill + MLX GPU Decode (フェーズ分離)", zh: "ANE 预填充 + MLX GPU 解码（分阶段）")
        }
    }

    var prefillEdpGainFactor: Double {
        switch self {
        case .unifiedGpu: return 1.00
        case .anePrefillGpuDecode: return 1.42
        }
    }

    var wattSavingsPercent: Double {
        switch self {
        case .unifiedGpu: return 0.0
        case .anePrefillGpuDecode: return 31.5
        }
    }
}

/// Punkt 2: 3-Tier KV-Cache & CacheGen Kompression
enum KVCacheTierMode: String, CaseIterable, Identifiable, Codable {
    case ramOnly = "Tier 1: Unified RAM Only"
    case ramNvmeTiered = "Tier 1+2: RAM + NVMe SSD Offload"
    case distributedCacheGen = "Tier 1–3: RAM + NVMe + Peer CacheGen"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .ramOnly: return L10n.tr(lang, de: "Stufe 1: Nur Unified RAM", en: "Tier 1: Unified RAM Only", fr: "Niveau 1 : RAM unifiée seule", es: "Nivel 1: Solo RAM unificada", pt: "Nível 1: Apenas RAM unificada", ru: "Уровень 1: Только Unified RAM", ja: "第1層: 統合RAMのみ", zh: "第 1 层：仅统一内存")
        case .ramNvmeTiered: return L10n.tr(lang, de: "Stufe 1+2: RAM + NVMe SSD Offload", en: "Tier 1+2: RAM + NVMe SSD Offload", fr: "Niveaux 1+2 : RAM + Déchargement NVMe SSD", es: "Nivel 1+2: RAM + Descarga SSD NVMe", pt: "Nível 1+2: RAM + Descarga SSD NVMe", ru: "Уровень 1+2: RAM + NVMe SSD", ja: "第1+2層: RAM + NVMe SSD退避", zh: "第 1+2 层：RAM + NVMe SSD 卸载")
        case .distributedCacheGen: return L10n.tr(lang, de: "Stufe 1–3: RAM + NVMe + Peer CacheGen", en: "Tier 1–3: RAM + NVMe + Peer CacheGen", fr: "Niveaux 1–3 : RAM + NVMe + CacheGen pairs", es: "Nivel 1–3: RAM + NVMe + CacheGen entre nodos", pt: "Nível 1–3: RAM + NVMe + CacheGen entre nós", ru: "Уровень 1–3: RAM + NVMe + Peer CacheGen", ja: "第1–3層: RAM + NVMe + Peer CacheGen", zh: "第 1–3 层：RAM + NVMe + 节点 CacheGen")
        }
    }

    var compressionRatio: Double {
        switch self {
        case .ramOnly: return 1.0
        case .ramNvmeTiered: return 1.8
        case .distributedCacheGen: return 3.6
        }
    }
}

struct CacheGenCompressionMetrics: Equatable {
    let tierMode: KVCacheTierMode
    let prefixHitRatePct: Double
    let rawKvSizeGB: Double
    let compressedTransferGB: Double
    let compressionRatio: Double
    let estimatedTtftReductionPct: Double
}

/// Punkt 3: MMM Next-Gen Speculative Decoding Engine
enum SpeculativeEngineMode: String, CaseIterable, Identifiable, Codable {
    case standardDraftTarget = "Standard Draft + Target"
    case eagle3Fusion = "EAGLE-3 Multi-Layer Feature Fusion"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .standardDraftTarget: return L10n.tr(lang, de: "Standard Draft + Target", en: "Standard Draft + Target", fr: "Draft + Target standard", es: "Draft + Target estándar", pt: "Draft + Target padrão", ru: "Стандартная Draft + Target", ja: "標準 Draft + Target", zh: "标准 Draft + Target")
        case .eagle3Fusion: return L10n.tr(lang, de: "EAGLE-3 Mehrschicht-Fusion", en: "EAGLE-3 Multi-Layer Feature Fusion", fr: "Fusion multicouche EAGLE-3", es: "Fusión multicapa EAGLE-3", pt: "Fusão multicamada EAGLE-3", ru: "EAGLE-3 Многослойный фьюжн", ja: "EAGLE-3 多層特徴融合", zh: "EAGLE-3 多层特征融合")
        }
    }

    var speedupBonusMultiplier: Double {
        switch self {
        case .standardDraftTarget: return 1.00
        case .eagle3Fusion: return 1.38
        }
    }
}

/// Punkt 4: Moderne Agenten- & Gateway-Protokolle
enum AgentGatewayProtocol: String, CaseIterable, Identifiable, Codable {
    case chatCompletions = "OpenAI /v1/chat/completions"
    case responsesWithMcp = "OpenAI /v1/responses + MCP"
    case a2aAgentCard = "A2A Agent Card (/.well-known/agent.json)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .chatCompletions, .responsesWithMcp: return rawValue
        case .a2aAgentCard: return L10n.tr(lang, de: "A2A Agenten-Visitenkarte (/.well-known/agent.json)", en: "A2A Agent Card (/.well-known/agent.json)", fr: "Carte d'agent A2A (/.well-known/agent.json)", es: "Tarjeta de agente A2A (/.well-known/agent.json)", pt: "Cartão de agente A2A (/.well-known/agent.json)", ru: "Визитка агента A2A (/.well-known/agent.json)", ja: "A2A エージェントカード (/.well-known/agent.json)", zh: "A2A 智能体名片 (/.well-known/agent.json)")
        }
    }
}

/// Punkt 5: Thermal- & Carbon-Aware Workload Placement
enum ThermalCarbonSchedulingPolicy: String, CaseIterable, Identifiable, Codable {
    case performanceFirst = "Max Performance (Ignore Thermal/Carbon)"
    case balancedThermal = "Thermal-Balanced (Throttle .serious/.critical)"
    case ecoCarbonAware = "Eco Carbon-Aware (Min Watt/Token)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .performanceFirst: return L10n.tr(lang, de: "Max. Leistung (Thermik/CO₂ ignorieren)", en: "Max Performance (Ignore Thermal/Carbon)", fr: "Performances max (Ignorer thermique/CO₂)", es: "Máximo rendimiento (Ignorar térmico/CO₂)", pt: "Desempenho máx. (Ignorar térmico/CO₂)", ru: "Макс. производительность (без лимитов)", ja: "最高性能（熱・CO₂無視）", zh: "最高性能（忽略温控与碳排）")
        case .balancedThermal: return L10n.tr(lang, de: "Thermisch balanciert (Schutz ab .serious)", en: "Thermal-Balanced (Throttle .serious/.critical)", fr: "Équilibré thermique (Limite dès .serious)", es: "Equilibrado térmico (Limitar en .serious)", pt: "Equilibrado térmico (Abrandar .serious)", ru: "Термобаланс (снижение при нагреве)", ja: "熱バランス（高温時は自動抑制）", zh: "温控均衡（高热自动降载）")
        case .ecoCarbonAware: return L10n.tr(lang, de: "Öko & CO₂-bewusst (Min. Watt/Token)", en: "Eco Carbon-Aware (Min Watt/Token)", fr: "Éco & Bas Carbone (Min Watt/Jeton)", es: "Eco consciente de carbono (Min Watt/Token)", pt: "Eco consciente de carbono (Min Watt/Token)", ru: "Эко / Низкий CO₂ (Мин. Вт/токен)", ja: "エコ・低炭素（最小ワット/トークン）", zh: "低碳节能（最低瓦特/Token）")
        }
    }
}

// MARK: - Phase 12: Cluster Auto-Setup & Readiness Verification Models

enum ClusterSetupVariant: String, CaseIterable, Identifiable, Codable {
    case local = "Lokaler Verbund (TB / RDMA / LAN)"
    case internet = "Internet-Verbund (QUIC Iroh / Tailscale)"
    case hybrid = "Kombinationsverbund (Lokal + Internet)"

    var id: String { rawValue }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .local: return L10n.tr(lang, de: "Lokaler Verbund (TB / RDMA / LAN)", en: "Local Cluster (TB / RDMA / LAN)", fr: "Grappe locale (TB / RDMA / LAN)", es: "Clúster local (TB / RDMA / LAN)", pt: "Cluster local (TB / RDMA / LAN)", ru: "Локальный кластер (TB / RDMA / LAN)", ja: "ローカルクラスター (TB / RDMA / LAN)", zh: "本地集群 (TB / RDMA / LAN)")
        case .internet: return L10n.tr(lang, de: "Internet-Verbund (QUIC Iroh / Tailscale)", en: "Internet Cluster (QUIC Iroh / Tailscale)", fr: "Grappe Internet (QUIC Iroh / Tailscale)", es: "Clúster Internet (QUIC Iroh / Tailscale)", pt: "Cluster Internet (QUIC Iroh / Tailscale)", ru: "Интернет-кластер (QUIC Iroh / Tailscale)", ja: "インターネットクラスター (QUIC Iroh / Tailscale)", zh: "互联网集群 (QUIC Iroh / Tailscale)")
        case .hybrid: return L10n.tr(lang, de: "Kombinationsverbund (Lokal + Internet)", en: "Hybrid Cluster (Local + Internet)", fr: "Grappe hybride (Local + Internet)", es: "Clúster híbrido (Local + Internet)", pt: "Cluster híbrido (Local + Internet)", ru: "Гибридный кластер (Локально + Интернет)", ja: "ハイブリッドクラスター (ローカル + インターネット)", zh: "混合集群（本地 + 互联网）")
        }
    }

    var icon: String {
        switch self {
        case .local: return "macstudio.fill"
        case .internet: return "globe.americas.fill"
        case .hybrid: return "point.3.connected.trianglepath.dotted"
        }
    }
}

enum ClusterReadinessState: String, CaseIterable, Identifiable, Codable {
    case unconfigured = "unconfigured"
    case incomplete = "incomplete"
    case notReady = "notReady"
    case ready = "ready"

    var id: String { rawValue }

    var isOperational: Bool {
        self == .ready
    }
}

enum ClusterReadinessCheckStatus: String, Codable {
    case pass
    case warn
    case fail
}

struct ClusterReadinessCheckItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let detail: String
    let status: ClusterReadinessCheckStatus
    let remediation: String
}

struct NodeProvisioningTarget: Identifiable, Hashable, Codable {
    let id: String
    let hostname: String
    let address: String
    let transport: String
    let chipLabel: String
    let usableVramGB: Double
    var sshTrusted: Bool
    var wiredLimitConfigured: Bool
    var rdmaOrWanReady: Bool
    var isSelected: Bool
}
