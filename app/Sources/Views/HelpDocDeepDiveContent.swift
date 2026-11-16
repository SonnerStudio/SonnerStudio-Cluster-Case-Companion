import SwiftUI
import AppKit

struct HelpDocVisual {
    let imageFile: String
    let caption: String
}

struct HelpDocMetric {
    let label: String
    let value: String
}

struct HelpDocDeepDive {
    let id: String
    let subtitle: String
    let visuals: [HelpDocVisual]
    let detailedParagraphs: [String]
    let stepByStep: [String]
    let keyMetrics: [HelpDocMetric]
    let bestPractices: [String]
}

enum HelpDocDeepDiveCatalog {
    private static func trList(
        _ lang: AppLanguage,
        de: [String],
        en: [String],
        fr: [String],
        es: [String],
        pt: [String],
        ru: [String],
        ja: [String],
        zh: [String]
    ) -> [String] {
        switch lang {
        case .de: return de
        case .en: return en
        case .fr: return fr
        case .es: return es
        case .pt: return pt
        case .ru: return ru
        case .ja: return ja
        case .zh: return zh
        }
    }

    static func deepDive(for id: String, section: HelpDocSection, lang: AppLanguage) -> HelpDocDeepDive {
        switch id {
        case "universal-m":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "Heterogener Apple-Silicon-Verbund von M1 bis M12+ mit automatischer Rang-0-Zuweisung",
                    en: "Heterogeneous Apple Silicon Clustering (M1–M12+) with Automatic Rank 0 Assignment",
                    fr: "Clustering Apple Silicon hétérogène (M1–M12+) avec attribution automatique du rang 0",
                    es: "Clúster heterogéneo Apple Silicon (M1–M12+) con asignación automática de Rango 0",
                    pt: "Clusterização heterogénea Apple Silicon (M1–M12+) com atribuição automática de Rank 0",
                    ru: "Гетерогенный кластер Apple Silicon (M1–M12+) с автоназначением Rank 0",
                    ja: "M1〜M12+ 異種混在 Apple Silicon クラスタリング＆自動 Rank 0 割り当て",
                    zh: "异构 Apple Silicon（M1–M12+）集群与自动 Rank 0 主节点分配"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_cluster_52gb.png",
                        caption: L10n.tr(lang,
                            de: "Verbund-Übersicht: Koordinator (Rang 0) + Worker-Knoten über Thunderbolt & LAN",
                            en: "Cluster Overview: Coordinator (Rank 0) + Worker nodes over Thunderbolt & LAN",
                            fr: "Vue d'ensemble : Coordinateur (Rang 0) + nœuds Workers via Thunderbolt & LAN",
                            es: "Resumen del clúster: Coordinador (Rango 0) + nodos Worker vía Thunderbolt y LAN",
                            pt: "Visão geral do cluster: Coordenador (Rank 0) + nós Worker via Thunderbolt e LAN",
                            ru: "Обзор кластера: Координатор (Rank 0) + рабочие узлы по Thunderbolt и LAN",
                            ja: "クラスタ概要: コーディネータ (Rank 0) + Thunderbolt / LAN 接続ワーカー",
                            zh: "集群概览：协调主节点 (Rank 0) 与 Thunderbolt / 局域网工作节点")
                    ),
                    HelpDocVisual(
                        imageFile: "cluster_topology_graphic.png",
                        caption: L10n.tr(lang,
                            de: "Hardware-Topologie: Getrennte Steuer- (LAN/WLAN) und Rechendaten-Ebene (TB3/4/5)",
                            en: "Hardware Topology: Separated Control Plane (LAN/WLAN) and Data Plane (TB3/4/5)",
                            fr: "Topologie matérielle : Plan de contrôle (LAN/WLAN) et plan de données (TB3/4/5) séparés",
                            es: "Topología de hardware: Plano de control (LAN/WLAN) y plano de datos (TB3/4/5) separados",
                            pt: "Topologia de hardware: Plano de controlo (LAN/WLAN) e plano de dados (TB3/4/5) separados",
                            ru: "Топология оборудования: раздельные плоскости управления (LAN/Wi-Fi) и данных (TB3/4/5)",
                            ja: "ハードウェアトポロジ: 制御プレーン (LAN/WLAN) とデータプレーン (TB3/4/5) の分離",
                            zh: "硬件拓扑：控制面（LAN/WLAN）与计算数据面（TB3/4/5）完全隔离")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "Jeder Apple-Silicon-Mac (Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, Mac Pro) kann unabhängig von seiner Generation als gleichberechtigter Rechenknoten in den Verbund aufgenommen werden. SS-CCC liest per sysctl und system_profiler automatisch CPU-P/E-Kerne, GPU-Kerne, Neural Engine (ANE), RAM-Größe und die reale Speicherbandbreite (GB/s) aus.",
                        "Für künftige Chip-Generationen (M7 bis M12+) leitet AppleSiliconChipFamily Speicherbandbreite, FP16-TFLOPS und Thunderbolt-Generation konsistent ab, sodass auch kommende Hardware ohne manuelle Tabellen sofort korrekt als Koordinator oder Worker eingestuft wird.",
                        "Der Knoten mit dem höchsten Speicherdurchsatz (z. B. Ultra oder Max) übernimmt automatisch Rang 0 (Leitrechner & OpenAI/Ollama-API-Eingang). Alle weiteren Macs arbeiten als nachgeschaltete Worker (Rang 1..N) mit speichergewichteter Layer-Aufteilung."
                    ],
                    en: [
                        "Every Apple Silicon Mac (Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, Mac Pro) can join the cluster on equal terms regardless of generation. SS-CCC inspects CPU P/E cores, GPU cores, Neural Engine (ANE), RAM capacity, and memory bandwidth (GB/s) via sysctl and system_profiler.",
                        "For future Apple Silicon generations (M7–M12+), AppleSiliconChipFamily extrapolates memory bandwidth, FP16 TFLOPS, and Thunderbolt class automatically so upcoming hardware is ranked accurately out of the box.",
                        "The Mac with the highest memory bandwidth automatically becomes Rank 0 (Coordinator & OpenAI/Ollama API gateway), while all remaining Macs serve as Rank 1..N Workers receiving proportional model layers."
                    ],
                    fr: [
                        "Chaque Mac Apple Silicon (Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, Mac Pro) rejoint le cluster quelle que soit sa génération. SS-CCC détecte automatiquement les cœurs CPU P/E, GPU, Neural Engine (ANE), la RAM et la bande passante (Go/s) via sysctl et system_profiler.",
                        "Pour les futures générations (M7–M12+), AppleSiliconChipFamily déduit automatiquement la bande passante, les TFLOPS FP16 et la classe Thunderbolt sans table manuelle.",
                        "Le Mac ayant le débit mémoire le plus élevé devient automatiquement Rang 0 (Coordinateur & passerelle OpenAI/Ollama), les autres Macs servant de Workers (Rang 1..N)."
                    ],
                    es: [
                        "Cualquier Mac Apple Silicon (Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, Mac Pro) puede integrarse en el clúster sin importar su generación. SS-CCC lee núcleos CPU P/E, GPU, Neural Engine (ANE), RAM y ancho de banda (GB/s) vía sysctl y system_profiler.",
                        "Para futuras generaciones (M7–M12+), AppleSiliconChipFamily extrapola automáticamente el ancho de banda, TFLOPS FP16 y generación Thunderbolt.",
                        "El Mac con mayor ancho de banda asume el Rango 0 (Coordinador y pasarela OpenAI/Ollama), mientras los demás operan como Workers (Rango 1..N) con capas proporcionales."
                    ],
                    pt: [
                        "Qualquer Mac Apple Silicon (Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio, Mac Pro) integra o cluster independentemente da geração. O SS-CCC lê núcleos CPU P/E, GPU, Neural Engine (ANE), RAM e largura de banda (GB/s) via sysctl e system_profiler.",
                        "Para futuras gerações (M7–M12+), o AppleSiliconChipFamily deduz automaticamente a largura de banda, FP16 TFLOPS e geração Thunderbolt.",
                        "O Mac com maior largura de banda torna-se Rank 0 (Coordenador e gateway OpenAI/Ollama), enquanto os restantes atuam como Workers (Rank 1..N)."
                    ],
                    ru: [
                        "Любой Mac на Apple Silicon (Mac mini, MacBook Air/Pro, iMac, Mac Studio, Mac Pro) подключается к кластеру независимо от поколения. SS-CCC считывает ядра CPU P/E, GPU, Neural Engine (ANE), ОЗУ и пропускную способность (ГБ/с) через sysctl и system_profiler.",
                        "Для будущих чипов (M7–M12+) класс AppleSiliconChipFamily автоматически вычисляет ПСП, FP16 TFLOPS и версию Thunderbolt.",
                        "Mac с наибольшей пропускной способностью памяти становится Rank 0 (Координатор и шлюз OpenAI/Ollama API), а остальные работают как Worker (Rank 1..N)."
                    ],
                    ja: [
                        "世代を問わずすべての Apple Silicon Mac（Mac mini、MacBook Air/Pro、iMac、Mac Studio、Mac Pro）が対等な計算ノードとして参加できます。SS-CCC は sysctl と system_profiler 経由で CPU P/E コア、GPU コア、Neural Engine (ANE)、RAM、メモリ帯域 (GB/s) を自動検出します。",
                        "将来の世代 (M7〜M12+) についても、AppleSiliconChipFamily がメモリ帯域・FP16 TFLOPS・Thunderbolt 世代を自動推論します。",
                        "最も帯域幅の広い Mac が自動的に Rank 0（コーディネータ＆API ゲートウェイ）となり、残りの Mac は Rank 1..N ワーカーとして比例分割された層を担当します。"
                    ],
                    zh: [
                        "所有搭载 Apple Silicon 的 Mac（Mac mini、MacBook Air/Pro、iMac、Mac Studio、Mac Pro）均可跨代际平等加入集群。SS-CCC 通过 sysctl 与 system_profiler 自动读取 CPU 大小核、GPU 核心、神经网络引擎 (ANE)、内存容量及真实带宽 (GB/s)。",
                        "面向未来芯片世代（M7–M12+），AppleSiliconChipFamily 可自动推导内存带宽、FP16 算力与 Thunderbolt 代际。",
                        "内存带宽最高的 Mac 自动担任 Rank 0（主调度节点兼 OpenAI/Ollama API 网关），其余节点作为 Rank 1..N 工作节点按显存比例分担模型层。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Verbinde alle Macs per Thunderbolt-Kabel (TB3/4/5) oder über das lokale LAN/WLAN bzw. WAN.",
                        "2. Öffne 'Verbund-Übersicht' oder 'Geräte & Vergleich', um die automatisch erkannte Hardware und Rang-Vergabe zu prüfen.",
                        "3. Starte auf dem Rang-0-Leitrechner die gewünschte Laufzeit (oMLX, Ollama oder llama.cpp) — SS-CCC verteilt die Schichten entsprechend des verfügbaren RAMs."
                    ],
                    en: [
                        "1. Connect your Macs via Thunderbolt cables (TB3/4/5) or local LAN/WLAN/WAN.",
                        "2. Open 'Cluster Overview' or 'Devices & Compare' to verify detected hardware and Rank 0 assignment.",
                        "3. Launch your runtime (oMLX, Ollama, or llama.cpp) on Rank 0 — SS-CCC shards model layers proportionally across available memory."
                    ],
                    fr: [
                        "1. Reliez vos Macs par câble Thunderbolt (TB3/4/5) ou via LAN/WLAN/WAN.",
                        "2. Ouvrez « Vue d'ensemble » ou « Appareils & Comparaison » pour vérifier le matériel et le Rang 0.",
                        "3. Lancez oMLX, Ollama ou llama.cpp sur le Rang 0 — SS-CCC répartit les couches proportionnellement."
                    ],
                    es: [
                        "1. Conecta tus Macs mediante cables Thunderbolt (TB3/4/5) o por LAN/WLAN/WAN.",
                        "2. Abre «Resumen del clúster» o «Dispositivos y Comparación» para revisar el hardware y el Rango 0.",
                        "3. Inicia oMLX, Ollama o llama.cpp en Rango 0: SS-CCC reparte las capas proporcionalmente."
                    ],
                    pt: [
                        "1. Ligue os Macs via cabos Thunderbolt (TB3/4/5) ou pela rede LAN/WLAN/WAN.",
                        "2. Abra 'Visão do Cluster' ou 'Dispositivos e Comparação' para confirmar o hardware e o Rank 0.",
                        "3. Inicie oMLX, Ollama ou llama.cpp no Rank 0 — o SS-CCC distribui as camadas proporcionalmente."
                    ],
                    ru: [
                        "1. Соедините Mac кабелями Thunderbolt (TB3/4/5) или по локальной сети LAN/Wi-Fi/WAN.",
                        "2. Откройте «Обзор кластера» или «Устройства и сравнение» для проверки оборудования и Rank 0.",
                        "3. Запустите oMLX, Ollama или llama.cpp на Rank 0 — SS-CCC пропорционально распределит слои."
                    ],
                    ja: [
                        "1. 各 Mac を Thunderbolt ケーブル (TB3/4/5) または LAN/WLAN/WAN で接続します。",
                        "2. 「クラスタ概要」または「デバイスと比較」で検出されたハードウェアと Rank 0 を確認します。",
                        "3. Rank 0 で oMLX / Ollama / llama.cpp を起動すると、利用可能メモリに応じて層が自動配分されます。"
                    ],
                    zh: [
                        "1. 使用 Thunderbolt 线缆 (TB3/4/5) 或本地 LAN/WLAN/WAN 连接所有 Mac。",
                        "2. 打开“集群概览”或“设备与硬件对比”，确认自动识别的硬件及 Rank 0 分配。",
                        "3. 在 Rank 0 主节点启动 oMLX、Ollama 或 llama.cpp，SS-CCC 将按可用显存自动分片模型层。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: L10n.tr(lang, de: "Chip-Support", en: "Chip Support", fr: "Support puces", es: "Soporte chips", pt: "Suporte chips", ru: "Поддержка чипов", ja: "対応チップ", zh: "芯片支持"), value: "M1 – M12+ (Base/Pro/Max/Ultra)"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Koordinator", en: "Coordinator", fr: "Coordinateur", es: "Coordinador", pt: "Coordenador", ru: "Координатор", ja: "コーディネータ", zh: "主协调器"), value: L10n.tr(lang, de: "Max. Speicherbandbreite → Rang 0", en: "Max Bandwidth → Rank 0", fr: "BP max → Rang 0", es: "Ancho máx. → Rango 0", pt: "Largura máx. → Rank 0", ru: "Макс. ПСП → Rank 0", ja: "最大帯域 → Rank 0", zh: "最高内存带宽 → Rank 0")),
                    HelpDocMetric(label: L10n.tr(lang, de: "Layer-Verteilung", en: "Layer Sharding", fr: "Découpage couches", es: "Reparto de capas", pt: "Divisão camadas", ru: "Шардинг слоёв", ja: "層シャーディング", zh: "模型分层"), value: L10n.tr(lang, de: "Speichergewichtet (proportional)", en: "Memory-Weighted Sharding", fr: "Proportionnel à la VRAM", es: "Ponderado por memoria", pt: "Ponderado por memória", ru: "Пропорционально ОЗУ", ja: "メモリ比率による重み付け", zh: "按显存加权分片"))
                ],
                bestPractices: trList(lang,
                    de: [
                        "Den Mac mit der höchsten Speicherbandbreite (z. B. Mac Studio Max/Ultra) immer als Rang-0-Leitrechner vorsehen.",
                        "Unterschiedliche RAM-Größen (z. B. 36 GB + 16 GB) sind ausdrücklich vorgesehen — SS-CCC verteilt die Gewichte automatisch proportional."
                    ],
                    en: [
                        "Always designate the Mac with highest memory bandwidth (e.g., Mac Studio Max/Ultra) as Rank 0 Coordinator.",
                        "Asymmetric RAM sizes (e.g., 36 GB + 16 GB) work seamlessly via proportional layer sharding."
                    ],
                    fr: [
                        "Désignez toujours le Mac à plus forte bande passante (ex. Mac Studio Max/Ultra) comme Rang 0.",
                        "Les capacités asymétriques (ex. 36 Go + 16 Go) sont prises en charge nativement."
                    ],
                    es: [
                        "Designa siempre el Mac con mayor ancho de banda (p. ej., Mac Studio Max/Ultra) como Rango 0.",
                        "Los tamaños de RAM asimétricos (p. ej., 36 GB + 16 GB) funcionan mediante reparto proporcional."
                    ],
                    pt: [
                        "Designe sempre o Mac com maior largura de banda (ex.: Mac Studio Max/Ultra) como Rank 0.",
                        "Tamanhos de RAM assimétricos (ex.: 36 GB + 16 GB) funcionam perfeitamente via sharding proporcional."
                    ],
                    ru: [
                        "Всегда назначайте Mac с наибольшей ПСП (напр., Mac Studio Max/Ultra) в качестве Rank 0.",
                        "Разные объёмы ОЗУ (напр., 36 ГБ + 16 ГБ) балансируются автоматически."
                    ],
                    ja: [
                        "最もメモリ帯域の広い Mac（Mac Studio Max/Ultra 等）を Rank 0 に割り当ててください。",
                        "異なる RAM 容量（例: 36 GB + 16 GB）でも比例シャーディングにより柔軟に協調できます。"
                    ],
                    zh: [
                        "始终将内存带宽最高的 Mac（例如 Mac Studio Max/Ultra）作为 Rank 0 主节点。",
                        "天然支持非对称内存容量组合（例如 36 GB + 16 GB），系统自动按比例切分层。"
                    ])
            )

        case "overview-hazard":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "Strukturierte Trennung nach Lokal, Internet & Hybrid mit industriellen Warnmarkierungen",
                    en: "Structured Local, Internet & Hybrid Topology Scopes with Industrial Hazard Striping",
                    fr: "Séparation Locale, Internet & Hybride avec marquage de sécurité industriel",
                    es: "Separación estructurada Local, Internet e Híbrido con bandas de advertencia",
                    pt: "Separação estruturada Local, Internet e Híbrido com faixas de segurança",
                    ru: "Чёткое разделение на Локальный, Интернет и Гибридный контуры с защитной разметкой",
                    ja: "ローカル・インターネット・ハイブリッドの3領域構成と警告ストライプ表示",
                    zh: "本地、互联网与混合三域拓扑清晰隔离与工业警戒标识"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_single_16gb.png",
                        caption: L10n.tr(lang,
                            de: "Einzelbetrieb & 3-Reiter-Umschaltung mit Speicherschutz-Zone",
                            en: "Standalone & 3-Tab Scope Switcher with Memory Protection Zone",
                            fr: "Mode autonome & sélecteur 3 onglets avec zone de protection mémoire",
                            es: "Modo individual y selector de 3 pestañas con zona de protección de memoria",
                            pt: "Modo individual e seletor de 3 separadores com zona de proteção de memória",
                            ru: "Одиночный режим и 3 вкладки областей с зоной защиты памяти",
                            ja: "単独モード・3タブ範囲切替およびメモリ保護ゾーン",
                            zh: "单机模式与三选项卡拓扑切换及显存保护区")
                    ),
                    HelpDocVisual(
                        imageFile: "ssccc_cluster_52gb.png",
                        caption: L10n.tr(lang,
                            de: "Aktiver Verbund mit gelb-schwarzen Industrie-Warnstreifen an kritischen Zonen",
                            en: "Active Cluster with Yellow-Black Industrial Hazard Stripes on Critical Zones",
                            fr: "Cluster actif avec bandes de sécurité jaune/noir sur les zones critiques",
                            es: "Clúster activo con franjas industriales amarillo/negro en zonas críticas",
                            pt: "Cluster ativo com faixas industriais amarelo/preto nas zonas críticas",
                            ru: "Активный кластер с жёлто-чёрной маркировкой критических зон",
                            ja: "アクティブクラスタの重要ゾーン（黄黒インダストリアル警告ライン）",
                            zh: "运行中集群的关键保护区（黄黑斜纹警戒标识）")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "Die Verbund-Übersicht gliedert die gesamte Cluster-Topologie in drei klar getrennte Auswahl-Reiter: 'Lokaler Cluster' (Thunderbolt-3/4/5-, RDMA/JACCL- und 10GbE-Rechner vor Ort), 'Internet-Cluster' (entfernte WAN-Partner und regionale Subcluster) sowie 'Lokal + Internet' (gekoppelter Gesamtverbund).",
                        "Sicherheitskritische Zonen — insbesondere der aktive Verbund-Speicher, das iogpu.wired_limit_mb-Limit, RDMA-Direktspeicherpfade und aktive Ausführungsbereiche — werden mit diagonalen gelb-schwarzen 45°-Industrie-Warnstreifen (HazardStripesBar) hervorgehoben.",
                        "Durch diese visuelle Trennung erkennst du auf einen Blick, ob ein Modell rein lokal, rein über WAN oder im gekoppelten Hybrid-Verbund läuft und wie viel Betriebssystem-Reserve geschützt bleibt."
                    ],
                    en: [
                        "Cluster Overview divides your topology into three clear scopes: 'Local Cluster' (TB3/4/5, RDMA/JACCL & 10GbE), 'Internet Cluster' (remote WAN peers & regional subclusters), and 'Local + Internet' (coupled hybrid mesh).",
                        "Safety-critical zones — including wired VRAM pools, iogpu.wired_limit_mb guards, RDMA zero-copy paths, and active execution blocks — are highlighted with 45-degree yellow-black industrial hazard stripes (HazardStripesBar).",
                        "This visual grammar makes it immediately clear whether workloads run locally, over WAN, or in coupled hybrid mode, while keeping macOS memory reserves visible."
                    ],
                    fr: [
                        "La vue d'ensemble divise la topologie en trois portées : « Cluster local », « Cluster Internet » et « Local + Internet ».",
                        "Les zones critiques (pools VRAM, limites iogpu.wired_limit_mb, chemins RDMA) sont signalées par des bandes obliques jaune et noir à 45°.",
                        "Cette séparation visuelle indique instantanément le périmètre d'exécution et la réserve macOS protégée."
                    ],
                    es: [
                        "El resumen divide la topología en tres ámbitos: «Clúster local», «Clúster Internet» y «Local + Internet».",
                        "Las zonas críticas de seguridad —incluidos los límites iogpu.wired_limit_mb y enlaces RDMA— llevan franjas amarillas y negras a 45°.",
                        "Esta separación visual muestra al instante dónde se ejecuta cada modelo y cuánta memoria queda protegida para macOS."
                    ],
                    pt: [
                        "A visão geral organiza a topologia em três âmbitos: 'Cluster Local', 'Cluster Internet' e 'Local + Internet'.",
                        "Zonas críticas — incluindo reservas iogpu.wired_limit_mb e caminhos RDMA — destacam-se com faixas de alerta industriais a 45°.",
                        "Esta separação visual indica de imediato onde o modelo executa e qual a margem segura do macOS."
                    ],
                    ru: [
                        "Обзор кластера разделяет топологию на три контура: «Локальный кластер», «Интернет-кластер» и «Локально + Интернет».",
                        "Критические зоны — лимит iogpu.wired_limit_mb, каналы RDMA и пулы VRAM — отмечены жёлто-чёрной полосой безопасности (45°).",
                        "Визуальное разделение сразу показывает режим выполнения и защищённый резерв macOS."
                    ],
                    ja: [
                        "クラスタ概要は「ローカルクラスタ」「インターネットクラスタ」「ローカル＋インターネット」の3タブで構成されています。",
                        "iogpu.wired_limit_mb メモリ保護帯、RDMA パス、実行ブロックなどの重要領域には 45 度の黄黒警告ストライプが表示されます。",
                        "ワークロードがローカル・WAN・ハイブリッドのどこで動作中かと macOS 保護メモリ残量を一目で把握できます。"
                    ],
                    zh: [
                        "集群概览采用清晰的三域划分：「本地集群」(TB3/4/5、RDMA/JACCL 与万兆网)、「互联网集群」（远程 WAN 与区域子集群）以及「本地 + 互联网」（耦合混合网格）。",
                        "高风险安全关键区域（含显存池、iogpu.wired_limit_mb 守护边界、RDMA 零拷贝链路等）均标注 45° 黄黑工业警戒斜纹 (HazardStripesBar)。",
                        "您可一目了然地确认当前运行边界及为 macOS 系统保留的安全内存。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Wähle in der Verbund-Übersicht den gewünschten Reiter (Lokaler Cluster, Internet-Cluster oder Lokal + Internet).",
                        "2. Prüfe im Balken 'Verbund-Speicheraufteilung' den genauen Anteil für KI-Modelle vs. macOS-Reserve.",
                        "3. Nutze bei Bedarf die Nachbildungs-Umschaltung links unten in der Seitenleiste, um größere Mehrknoten-Topologien risikofrei zu testen."
                    ],
                    en: [
                        "1. Select your target scope in Cluster Overview (Local, Internet, or Local + Internet).",
                        "2. Inspect the 'Unified Memory Allocation' bar showing AI VRAM vs. protected macOS OS reserve.",
                        "3. Toggle the sidebar simulation switch whenever you want to preview multi-node topologies safely."
                    ],
                    fr: [
                        "1. Choisissez la portée dans Vue d'ensemble (Local, Internet ou Local + Internet).",
                        "2. Vérifiez la barre d'allocation mémoire entre la VRAM IA et la réserve macOS.",
                        "3. Activez l'interrupteur de simulation dans la barre latérale pour tester sans risque."
                    ],
                    es: [
                        "1. Elige el ámbito en Resumen del clúster (Local, Internet o Local + Internet).",
                        "2. Comprueba en la barra de memoria el reparto exacto entre IA y la reserva de macOS.",
                        "3. Usa el interruptor de simulación en la barra lateral para probar topologías multi-nodo."
                    ],
                    pt: [
                        "1. Selecione o âmbito pretendido na Visão do Cluster (Local, Internet ou Local + Internet).",
                        "2. Verifique na barra de alocação a divisão exata entre IA e reserva macOS.",
                        "3. Utilize o comutador de simulação na barra lateral para ensaiar topologias maiores."
                    ],
                    ru: [
                        "1. Выберите нужный контур в Обзоре кластера (Локальный, Интернет или Гибрид).",
                        "2. Проверьте распределение памяти между ИИ-пулом и резервом macOS.",
                        "3. Используйте переключатель симуляции внизу боковой панели для безопасных тестов."
                    ],
                    ja: [
                        "1. クラスタ概要から対象スコープ（ローカル・インターネット・ハイブリッド）を選択します。",
                        "2. メモリ配分バーで AI 用 VRAM と macOS 保護領域の割合を確認します。",
                        "3. 左下のシミュレーション切替スイッチで複数ノード構成を安全にテストできます。"
                    ],
                    zh: [
                        "1. 在集群概览顶部切换目标作用域（本地、互联网或本地 + 互联网）。",
                        "2. 在“集群显存分配”条中核对 AI 可用显存与 macOS 系统保留内存比例。",
                        "3. 需要测试多节点规模时，可点击侧边栏底部的模拟节点开关。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: L10n.tr(lang, de: "Scope-Modi", en: "Scope Modes", fr: "Portées", es: "Ámbitos", pt: "Âmbitos", ru: "Режимы", ja: "範囲モード", zh: "作用域"), value: "Local · Internet · Hybrid"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Warn-Elemente", en: "Hazard UI", fr: "Bandeaux d'alerte", es: "Indicadores", pt: "Indicadores", ru: "Предупреждения", ja: "警戒UI", zh: "警戒组件"), value: "HazardStripesBar & IndustrialBanner"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Ansichts-Abdeckung", en: "View Coverage", fr: "Couverture", es: "Cobertura", pt: "Cobertura", ru: "Охват", ja: "カバー範囲", zh: "界面覆盖"), value: L10n.tr(lang, de: "Alle 11 Hauptansichten", en: "All 11 Primary Views", fr: "Les 11 vues principales", es: "Las 11 vistas principales", pt: "Todas as 11 vistas", ru: "Все 11 разделов", ja: "全11メイン画面", zh: "全部 11 个主视图"))
                ],
                bestPractices: trList(lang,
                    de: [
                        "Vor großen Modell-Starts stets prüfen, ob der gewählte Reiter (Lokal vs. Hybrid) zur gewünschten Latenzklasse passt.",
                        "Gelb-schwarze Warnbereiche signalisieren direkte Kernel-/Speicher- oder Netzwerk-Eingriffe — Werte dort mit Bedacht anpassen."
                    ],
                    en: [
                        "Verify the active scope tab (Local vs. Hybrid) before loading large multi-node models.",
                        "Yellow-black hazard zones indicate direct kernel memory or high-speed link boundaries."
                    ],
                    fr: [
                        "Vérifiez l'onglet de portée actif avant de charger de grands modèles.",
                        "Les bandes jaune/noir signalent les limites directes de mémoire noyau ou réseau."
                    ],
                    es: [
                        "Verifica la pestaña de ámbito antes de cargar modelos grandes.",
                        "Las zonas amarillas y negras indican límites críticos de memoria kernel o red."
                    ],
                    pt: [
                        "Verifique o separador de âmbito ativo antes de carregar modelos grandes.",
                        "Zonas amarelo-preto sinalizam limites diretos de memória kernel ou ligação rápida."
                    ],
                    ru: [
                        "Перед загрузкой крупных моделей проверяйте выбранный контур (Локальный или Гибрид).",
                        "Жёлто-чёрная разметка обозначает системные ограничения памяти ядра и сети."
                    ],
                    ja: [
                        "大規模モデル起動前に、遅延要件に合ったタブ（ローカル / ハイブリッド）か確認してください。",
                        "黄黒ストライプ領域はカーネルメモリ保護や高速リンク境界を示すため慎重に設定してください。"
                    ],
                    zh: [
                        "加载大模型前请确认当前作用域选项卡（本地 vs 混合）符合目标延迟要求。",
                        "黄黑警戒区域涉及系统内核显存上限或高速网络边界，调整时请保持谨慎。"
                    ])
            )

        case "memory-safety":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "macOS Kernel-Schutzgrenze (iogpu.wired_limit_mb) gegen OOM-Abstürze und WindowServer-Freezes",
                    en: "macOS Kernel Memory Guard (iogpu.wired_limit_mb) Preventing OOM Crashes & WindowServer Freezes",
                    fr: "Protection mémoire noyau macOS (iogpu.wired_limit_mb) contre OOM et blocages",
                    es: "Protección de memoria kernel macOS (iogpu.wired_limit_mb) contra fallos OOM",
                    pt: "Proteção de memória kernel macOS (iogpu.wired_limit_mb) contra falhas OOM",
                    ru: "Защита памяти ядра macOS (iogpu.wired_limit_mb) от сбоев OOM и зависаний",
                    ja: "OOM・フリーズを防ぐ macOS カーネルメモリ保護境界 (iogpu.wired_limit_mb)",
                    zh: "macOS 内核显存守护界限 (iogpu.wired_limit_mb)，防止 OOM 崩溃与系统卡死"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_tb5_rdma_jaccl.jpg",
                        caption: L10n.tr(lang,
                            de: "Unified Memory Pool & iogpu.wired_limit_mb Schutzarchitektur",
                            en: "Unified Memory Pool & iogpu.wired_limit_mb Protection Architecture",
                            fr: "Pool Mémoire Unifiée & architecture de protection iogpu.wired_limit_mb",
                            es: "Pool de memoria unificada y arquitectura de protección iogpu.wired_limit_mb",
                            pt: "Pool de Memória Unificada e arquitetura de proteção iogpu.wired_limit_mb",
                            ru: "Объединённая память и архитектура защиты iogpu.wired_limit_mb",
                            ja: "ユニファイドメモリプール＆ iogpu.wired_limit_mb 保護アーキテクチャ",
                            zh: "统一内存池与 iogpu.wired_limit_mb 内核保护架构")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "Auf Apple Silicon teilen sich CPU, GPU und Neural Engine denselben physikalischen Unified-Memory-Pool. Wird versucht, 100 % des Arbeitsspeichers als GPU-Wired-Memory für ein LLM zu sperren, drohen dem macOS WindowServer und Kernel sofortige System-Freezes oder Out-of-Memory-Panics.",
                        "SS-CCC berechnet deshalb auf jedem Knoten automatisch die geschützte Betriebssystem-Reserve: 4 GB bei Macs bis 24 GB RAM (z. B. 16 GB → 12 GB nutzbar), 6 GB bei 32–64 GB RAM (z. B. 36 GB → 30 GB nutzbar) und 8 GB ab 96 GB RAM (z. B. 128 GB → 120 GB nutzbar).",
                        "Vor jedem Modellstart prüft die Modell-Werkstatt sowie der Multi-Model-Mode (MMM), ob Modellgewichte + KV-Zwischenspeicher sicher in die nutzbare Gesamtsumme passen."
                    ],
                    en: [
                        "On Apple Silicon, CPU, GPU, and Neural Engine share a single Unified Memory pool. Allocating 100% of system RAM as wired GPU memory starves macOS WindowServer and causes freezes or kernel panics.",
                        "SS-CCC enforces an automatic per-node OS safety reserve: 4 GB for Macs up to 24 GB RAM (16 GB → 12 GB usable), 6 GB for 32–64 GB RAM (36 GB → 30 GB usable), and 8 GB for 96 GB+ RAM (128 GB → 120 GB usable).",
                        "Before loading any model or MMM multi-model pool, Model Studio and MMM validate weights + KV-cache against this safe limit."
                    ],
                    fr: [
                        "Sur Apple Silicon, CPU, GPU et Neural Engine partagent la même mémoire unifiée. Allouer 100 % de la RAM au GPU bloque le WindowServer macOS.",
                        "SS-CCC réserve automatiquement 4 Go (≤ 24 Go RAM), 6 Go (32–64 Go) ou 8 Go (≥ 96 Go) pour le système.",
                        "Avant tout chargement, l'atelier modèles et le MMM vérifient que poids + cache KV tiennent dans la limite sûre."
                    ],
                    es: [
                        "En Apple Silicon, CPU, GPU y Neural Engine comparten memoria unificada. Asignar el 100 % de RAM a GPU bloquea WindowServer y provoca kernel panics.",
                        "SS-CCC reserva automáticamente 4 GB (≤ 24 GB RAM), 6 GB (32–64 GB) u 8 GB (≥ 96 GB) para macOS.",
                        "Antes de cargar un modelo, el estudio y MMM validan pesos + caché KV frente a ese límite seguro."
                    ],
                    pt: [
                        "No Apple Silicon, CPU, GPU e Neural Engine partilham a mesma memória unificada. Reservar 100% da RAM para a GPU bloqueia o WindowServer.",
                        "O SS-CCC garante automaticamente uma reserva segura: 4 GB (≤ 24 GB RAM), 6 GB (32–64 GB) ou 8 GB (≥ 96 GB).",
                        "Antes de iniciar qualquer modelo, a oficina e o MMM validam os pesos + cache KV contra esse limite."
                    ],
                    ru: [
                        "На Apple Silicon CPU, GPU и Neural Engine используют общую память. Блокировка 100 % ОЗУ под GPU приводит к зависанию WindowServer или kernel panic.",
                        "SS-CCC автоматически оставляет безопасный резерв ОС: 4 ГБ (до 24 ГБ ОЗУ), 6 ГБ (32–64 ГБ) и 8 ГБ (от 96 ГБ).",
                        "Перед запуском моделей Мастерская и MMM проверяют сумму весов и KV-кэша относительно безопасного лимита."
                    ],
                    ja: [
                        "Apple Silicon では CPU・GPU・Neural Engine が同じユニファイドメモリを共有します。100% を GPU 用にロックすると macOS WindowServer が飢餓状態になりフリーズします。",
                        "SS-CCC は各ノードで OS 安全領域（≤24GB: 4GB、32–64GB: 6GB、≥96GB: 8GB）を自動確保します。",
                        "モデル起動前にはモデルスタジオおよび MMM が重み＋KVキャッシュ合計を安全上限と照合します。"
                    ],
                    zh: [
                        "Apple Silicon 上的 CPU、GPU 与神经引擎共享同一块物理统一内存。若将 100% 内存锁定给大模型 GPU 使用，会触发 WindowServer 卡顿甚至内核崩溃。",
                        "SS-CCC 自动按节点规模保留系统安全余量：24 GB 以下保留 4 GB，32–64 GB 保留 6 GB，96 GB 以上保留 8 GB。",
                        "加载单模型或 MMM 多模型池前，模型工坊均会提前校验权重与 KV 缓存是否在安全可用总额之内。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Ermittle das sichere Wired-Limit deines Macs (z. B. 30720 MB bei 36 GB RAM oder 12288 MB bei 16 GB RAM).",
                        "2. Setze das Limit über 'scripts/setup_wired_limit.sh <MB>' (oder in 'Netzwerk & Direktspeicher').",
                        "3. Aktiviere in MMM bei Bedarf 'VRAM-Fit optimieren', um überschüssige Slots automatisch zu pausieren."
                    ],
                    en: [
                        "1. Determine your Mac's safe wired limit (e.g., 30720 MB on 36 GB or 12288 MB on 16 GB).",
                        "2. Apply the limit using 'scripts/setup_wired_limit.sh <MB>' or from Network & RDMA.",
                        "3. Use 'Optimize VRAM-Fit' in MMM if switching to a smaller cluster scope."
                    ],
                    fr: [
                        "1. Identifiez la limite sûre de votre Mac (ex. 30720 Mo sur 36 Go ou 12288 Mo sur 16 Go).",
                        "2. Appliquez-la via 'scripts/setup_wired_limit.sh <MB>'.",
                        "3. Utilisez « Optimiser la VRAM » dans MMM si vous réduisez le cluster."
                    ],
                    es: [
                        "1. Calcula el límite seguro de tu Mac (ej. 30720 MB en 36 GB o 12288 MB en 16 GB).",
                        "2. Aplícalo con 'scripts/setup_wired_limit.sh <MB>'.",
                        "3. Pulsa «Optimizar ajuste VRAM» en MMM si cambias a un clúster menor."
                    ],
                    pt: [
                        "1. Determine o limite seguro do seu Mac (ex.: 30720 MB em 36 GB ou 12288 MB em 16 GB).",
                        "2. Aplique o limite com 'scripts/setup_wired_limit.sh <MB>'.",
                        "3. Use 'Otimizar ajuste VRAM' no MMM se mudar para um cluster menor."
                    ],
                    ru: [
                        "1. Определите безопасный лимит Mac (напр., 30720 МБ для 36 ГБ или 12288 МБ для 16 ГБ).",
                        "2. Примените его через 'scripts/setup_wired_limit.sh <MB>'.",
                        "3. Нажмите «Оптимизировать VRAM» в MMM при переходе на меньший кластер."
                    ],
                    ja: [
                        "1. 各 Mac の安全 Wired 上限（36 GB なら 30720 MB、16 GB なら 12288 MB）を確認します。",
                        "2. 'scripts/setup_wired_limit.sh <MB>' を実行して適用します。",
                        "3. 必要に応じて MMM の「VRAM適合を最適化」で超過スロットを停止します。"
                    ],
                    zh: [
                        "1. 核对单台 Mac 的安全锁定上限（例如 36 GB 设 30720 MB，16 GB 设 12288 MB）。",
                        "2. 运行 'scripts/setup_wired_limit.sh <MB>' 或通过自动配置脚本写入 sysctl。",
                        "3. 若切换至较小集群，请在 MMM 中点击“优化显存适配”。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: "≤ 24 GB RAM", value: L10n.tr(lang, de: "4 GB OS-Reserve", en: "4 GB OS Reserve", fr: "4 Go réserve OS", es: "4 GB reserva OS", pt: "4 GB reserva SO", ru: "4 ГБ резерв ОС", ja: "4 GB OS保護", zh: "4 GB 系统保留")),
                    HelpDocMetric(label: "32 – 64 GB RAM", value: L10n.tr(lang, de: "6 GB OS-Reserve", en: "6 GB OS Reserve", fr: "6 Go réserve OS", es: "6 GB reserva OS", pt: "6 GB reserva SO", ru: "6 ГБ резерв ОС", ja: "6 GB OS保護", zh: "6 GB 系统保留")),
                    HelpDocMetric(label: "≥ 96 GB RAM", value: L10n.tr(lang, de: "8 GB OS-Reserve", en: "8 GB OS Reserve", fr: "8 Go réserve OS", es: "8 GB reserva OS", pt: "8 GB reserva SO", ru: "8 ГБ резерв ОС", ja: "8 GB OS保護", zh: "8 GB 系统保留"))
                ],
                bestPractices: trList(lang,
                    de: [
                        "Niemals 100 % des RAMs per sysctl iogpu.wired_limit_mb freigeben.",
                        "Bei großen Kontextfenstern (32k–128k Tokens) 8-bit oder 4-bit KV-Cache-Quantisierung aktivieren."
                    ],
                    en: [
                        "Never assign 100% of physical RAM to iogpu.wired_limit_mb.",
                        "Enable 8-bit or 4-bit KV-cache quantization for long 32k–128k context windows."
                    ],
                    fr: [
                        "N'allouez jamais 100 % de la RAM physique à iogpu.wired_limit_mb.",
                        "Activez la quantification KV 8 ou 4 bits pour les grands contextes (32k–128k)."
                    ],
                    es: [
                        "Nunca asignes el 100 % de la RAM física a iogpu.wired_limit_mb.",
                        "Activa cuantización KV de 8 o 4 bits para contextos largos (32k–128k)."
                    ],
                    pt: [
                        "Nunca atribua 100 % da RAM física a iogpu.wired_limit_mb.",
                        "Ative a quantização KV de 8 ou 4 bits para contextos de 32k–128k."
                    ],
                    ru: [
                        "Никогда не выделяйте 100 % физической памяти под iogpu.wired_limit_mb.",
                        "Для длинного контекста (32k–128k) включайте 8- или 4-битный KV-кэш."
                    ],
                    ja: [
                        "物理 RAM の 100% を iogpu.wired_limit_mb に割り当てないでください。",
                        "32k〜128k の長文コンテキストには 8-bit または 4-bit KV 量子化を有効にしてください。"
                    ],
                    zh: [
                        "严禁将 100% 物理内存分配给 iogpu.wired_limit_mb。",
                        "面对 32k–128k 长上下文任务，请开启 8-bit 或 4-bit KV 缓存量化。"
                    ])
            )

        case "network-tb":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "Getrennte Control- und Data-Plane, Thunderbolt-3/4/5-Bridge & RDMA (JACCL) Zero-Copy",
                    en: "Dual-Plane Networking, Thunderbolt 3/4/5 Bridge & RDMA (JACCL) Zero-Copy",
                    fr: "Réseau double plan, pont Thunderbolt 3/4/5 & RDMA (JACCL) Zero-Copy",
                    es: "Red de doble plano, puente Thunderbolt 3/4/5 y RDMA (JACCL) Zero-Copy",
                    pt: "Rede de plano duplo, ponte Thunderbolt 3/4/5 e RDMA (JACCL) Zero-Copy",
                    ru: "Двухуровневая сеть, мост Thunderbolt 3/4/5 и RDMA (JACCL) Zero-Copy",
                    ja: "デュアルプレーン通信・Thunderbolt 3/4/5 ブリッジ・RDMA (JACCL) ゼロコピー",
                    zh: "双平面网络、Thunderbolt 3/4/5 网桥与 RDMA (JACCL) 零拷贝"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_tb5_rdma_jaccl.jpg",
                        caption: L10n.tr(lang,
                            de: "Thunderbolt 5 RDMA (JACCL) & MLX_METAL_FAST_SYNCH=1 (~4 µs Latenz)",
                            en: "Thunderbolt 5 RDMA (JACCL) & MLX_METAL_FAST_SYNCH=1 (~4 µs latency)",
                            fr: "Thunderbolt 5 RDMA (JACCL) & MLX_METAL_FAST_SYNCH=1 (latence ~4 µs)",
                            es: "Thunderbolt 5 RDMA (JACCL) y MLX_METAL_FAST_SYNCH=1 (latencia ~4 µs)",
                            pt: "Thunderbolt 5 RDMA (JACCL) e MLX_METAL_FAST_SYNCH=1 (latência ~4 µs)",
                            ru: "Thunderbolt 5 RDMA (JACCL) и MLX_METAL_FAST_SYNCH=1 (~4 мкс)",
                            ja: "Thunderbolt 5 RDMA (JACCL) & MLX_METAL_FAST_SYNCH=1（遅延約 4 µs）",
                            zh: "Thunderbolt 5 RDMA (JACCL) 与 MLX_METAL_FAST_SYNCH=1（约 4 µs 超低延迟）")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "SS-CCC trennt Netzwerkverkehr sauber auf zwei Ebenen: Steuerdaten, mDNS/Bonjour-Erkennung und WebSocket-Chat laufen über LAN/WLAN bzw. Tailscale-WAN, während hochfrequente Tensor-Aktivierungen dediziert über eine Punkt-zu-Punkt-Thunderbolt-Bridge (10.99.1.x) fließen.",
                        "Bei gemischten Generationen (z. B. TB5 Mac Studio + TB4 Mac mini) skaliert die Verbindung dynamisch auf die gemeinsam unterstützte Bandbreite (TB3/USB4: 26–32 Gbps, TB4: 30–37 Gbps, TB5: 65–80 Gbps, TB5 RDMA: 75–110 Gbps).",
                        "Mit MLX_METAL_FAST_SYNCH=1 und JACCL RDMA auf macOS 26.2+ werden GPU-Synchronisationswartezeiten von ~180 µs auf ~4 µs reduziert (45× schnellere Synchronisation)."
                    ],
                    en: [
                        "SS-CCC cleanly separates Control Plane (LAN/WLAN/Tailscale discovery & chat) from Data Plane (dedicated 10.99.1.x point-to-point Thunderbolt bridge for tensor activations).",
                        "Mixed generations negotiate link throughput dynamically (TB3/USB4: 26–32 Gbps, TB4: 30–37 Gbps, TB5: 65–80 Gbps, TB5 RDMA: 75–110 Gbps).",
                        "Enabling MLX_METAL_FAST_SYNCH=1 with JACCL RDMA on macOS 26.2+ cuts GPU synchronization latency from ~180 µs down to ~4 µs (45× speedup)."
                    ],
                    fr: [
                        "SS-CCC sépare le plan de contrôle (LAN/WLAN/Tailscale) du plan de données (pont Thunderbolt point à point 10.99.1.x pour les tenseurs).",
                        "Les générations mixtes négocient automatiquement le débit (TB3/USB4 : 26–32 Gbps, TB4 : 30–37 Gbps, TB5 : 65–80 Gbps, RDMA : 75–110 Gbps).",
                        "MLX_METAL_FAST_SYNCH=1 avec JACCL RDMA (macOS 26.2+) réduit la synchronisation GPU de ~180 µs à ~4 µs (45× plus rapide)."
                    ],
                    es: [
                        "SS-CCC separa el plano de control (LAN/WLAN/Tailscale) del plano de datos (puente Thunderbolt punto a punto 10.99.1.x para activaciones).",
                        "Generaciones mixtas negocian el caudal automáticamente (TB3/USB4: 26–32 Gbps, TB4: 30–37 Gbps, TB5: 65–80 Gbps, RDMA: 75–110 Gbps).",
                        "MLX_METAL_FAST_SYNCH=1 junto con JACCL RDMA (macOS 26.2+) reduce la sincronización GPU de ~180 µs a ~4 µs (45× más rápido)."
                    ],
                    pt: [
                        "O SS-CCC separa o plano de controlo (LAN/WLAN/Tailscale) do plano de dados (ponte Thunderbolt 10.99.1.x exclusiva para tensores).",
                        "Gerações mistas negociam o débito dinamicamente (TB3/USB4: 26–32 Gbps, TB4: 30–37 Gbps, TB5: 65–80 Gbps, RDMA: 75–110 Gbps).",
                        "MLX_METAL_FAST_SYNCH=1 com JACCL RDMA (macOS 26.2+) reduz a latência de sincronização GPU de ~180 µs para ~4 µs (45×)."
                    ],
                    ru: [
                        "SS-CCC разделяет плоскость управления (LAN/Wi-Fi/Tailscale) и плоскость данных (выделенный мост Thunderbolt 10.99.1.x для тензоров).",
                        "Смешанные поколения автоматически согласуют скорость (TB3/USB4: 26–32, TB4: 30–37, TB5: 65–80, TB5 RDMA: 75–110 Гбит/с).",
                        "MLX_METAL_FAST_SYNCH=1 и JACCL RDMA в macOS 26.2+ снижают задержку синхронизации GPU с ~180 мкс до ~4 мкс (в 45× быстрее)."
                    ],
                    ja: [
                        "SS-CCC は制御プレーン（LAN/WLAN/Tailscale 検出とチャット）とデータプレーン（10.99.1.x 専用 Thunderbolt ブリッジ）を厳密に分離します。",
                        "異世代混在でも実効帯域を自動交渉します（TB3/USB4: 26–32 Gbps、TB4: 30–37 Gbps、TB5: 65–80 Gbps、TB5 RDMA: 75–110 Gbps）。",
                        "macOS 26.2+ で MLX_METAL_FAST_SYNCH=1 と JACCL RDMA を有効にすると、GPU 同期待ちが約 180 µs から約 4 µs へ 45 倍高速化されます。"
                    ],
                    zh: [
                        "SS-CCC 将控制平面（LAN/WLAN/Tailscale 发现与聊天）与计算数据平面（10.99.1.x 点对点 Thunderbolt 专网）完全解耦。",
                        "混搭不同代际 Mac 时可自动协商速率（TB3/USB4：26–32 Gbps，TB4：30–37 Gbps，TB5：65–80 Gbps，TB5 RDMA：75–110 Gbps）。",
                        "在 macOS 26.2+ 上启用 MLX_METAL_FAST_SYNCH=1 与 JACCL RDMA 可将 GPU 同步开销由 ~180 µs 降至 ~4 µs（提速 45 倍）。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Verbinde beide Macs direkt mit einem zertifizierten Thunderbolt-4/5-Kabel (max. 1–2 m).",
                        "2. Richte im Bereich 'Netzwerk & Direktspeicher' die TB-Bridge-IPs (10.99.1.1 / 10.99.1.2) ein.",
                        "3. Prüfe mit 'ibv_devices' im RDMA-Panel, ob RDMA-Verbs aktiv sind (ab macOS 26.2 + TB5)."
                    ],
                    en: [
                        "1. Connect Macs directly with a certified Thunderbolt 4/5 cable.",
                        "2. Configure the 10.99.1.x Thunderbolt Bridge in 'Network & RDMA'.",
                        "3. Verify RDMA verbs via 'ibv_devices' on macOS 26.2+ TB5 hardware."
                    ],
                    fr: [
                        "1. Reliez directement les Macs avec un câble Thunderbolt 4/5 certifié.",
                        "2. Configurez les IP 10.99.1.x du pont TB dans « Réseau & RDMA ».",
                        "3. Vérifiez les verbs RDMA avec 'ibv_devices' sur macOS 26.2+."
                    ],
                    es: [
                        "1. Conecta ambos Macs directamente con un cable Thunderbolt 4/5 certificado.",
                        "2. Configura las IPs 10.99.1.x en «Red y RDMA».",
                        "3. Comprueba los verbs RDMA con 'ibv_devices' en macOS 26.2+ y TB5."
                    ],
                    pt: [
                        "1. Ligue os Macs diretamente com um cabo Thunderbolt 4/5 certificado.",
                        "2. Configure os IPs 10.99.1.x em 'Rede e RDMA'.",
                        "3. Verifique os verbs RDMA com 'ibv_devices' no macOS 26.2+ TB5."
                    ],
                    ru: [
                        "1. Соедините Mac напрямую сертифицированным кабелем Thunderbolt 4/5.",
                        "2. Настройте IP-мост 10.99.1.x в разделе «Сеть и RDMA».",
                        "3. Проверьте RDMA-устройства командой 'ibv_devices' (macOS 26.2+ и TB5)."
                    ],
                    ja: [
                        "1. 認証済み Thunderbolt 4/5 ケーブル (1–2m) で Mac 同士を直結します。",
                        "2. 「ネットワーク＆RDMA」で 10.99.1.x ブリッジ IP を設定します。",
                        "3. macOS 26.2+ TB5 環境では 'ibv_devices' で RDMA verbs の有効化を確認します。"
                    ],
                    zh: [
                        "1. 使用认证的 Thunderbolt 4/5 线缆直连两台 Mac。",
                        "2. 在“网络与 RDMA”中配置 10.99.1.x 点对点网桥。",
                        "3. 在 macOS 26.2+ 与 TB5 设备上运行 'ibv_devices' 验证 RDMA 启用状态。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: "TB4 Bridge", value: "30–37 Gbps"),
                    HelpDocMetric(label: "TB5 RDMA (JACCL)", value: "75–110 Gbps · ~4 µs"),
                    HelpDocMetric(label: "FAST_SYNCH", value: L10n.tr(lang, de: "45× schnelleres GPU-Sync", en: "45× Faster GPU Sync", fr: "Sync GPU 45× plus rapide", es: "Sync GPU 45× más rápido", pt: "Sync GPU 45× mais rápido", ru: "В 45× быстрее GPU-синхр.", ja: "GPU 同期 45 倍高速", zh: "GPU 同步提速 45×"))
                ],
                bestPractices: trList(lang,
                    de: [
                        "Thunderbolt-Bridge in der macOS-Netzwerkreihenfolge unterhalb von WLAN/Ethernet belassen, damit normaler Internetverkehr ungestört bleibt.",
                        "Für RDMA über JACCL kurze passive oder aktive TB5-Kabel direkt ohne Hub anschließen."
                    ],
                    en: [
                        "Keep Thunderbolt Bridge below Wi-Fi/Ethernet in macOS Network service order so internet routing stays intact.",
                        "Connect TB5 cables directly host-to-host without intermediate docks for RDMA."
                    ],
                    fr: [
                        "Placez le pont Thunderbolt sous Wi-Fi/Ethernet dans l'ordre des services macOS.",
                        "Branchez les câbles TB5 directement entre Macs sans hub intermédiaire pour le RDMA."
                    ],
                    es: [
                        "Mantén el puente Thunderbolt debajo de Wi-Fi/Ethernet en el orden de red de macOS.",
                        "Conecta los cables TB5 directamente sin docks intermedios para RDMA."
                    ],
                    pt: [
                        "Mantenha a Thunderbolt Bridge abaixo de Wi-Fi/Ethernet na ordem de rede do macOS.",
                        "Ligue cabos TB5 diretamente sem hubs intermédios para RDMA."
                    ],
                    ru: [
                        "Держите Thunderbolt Bridge ниже Wi-Fi/Ethernet в списке служб сети macOS.",
                        "Подключайте кабели TB5 напрямую без хабов и док-станций для RDMA."
                    ],
                    ja: [
                        "通常のネット通信を妨げないよう、macOS ネットワーク優先順位では Thunderbolt ブリッジを Wi-Fi/Ethernet より下に配置してください。",
                        "RDMA 通信にはドックやハブを挟まず TB5 ケーブルで Mac 同士を直結してください。"
                    ],
                    zh: [
                        "在 macOS 网络服务顺序中将 Thunderbolt 网桥置于 Wi-Fi/以太网之下，确保常规外网流量不受影响。",
                        "启用 RDMA 时请用 TB5 线直连主机，不要经过扩展坞。"
                    ])
            )

        case "sharding-loading":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "Multi-Model-Mode (MMM), Auto-Setup & Speichergewichtete Schichtenverteilung",
                    en: "Multi-Model-Mode (MMM), 1-Click Auto-Setup & Memory-Weighted Sharding",
                    fr: "Mode Multi-Modèle (MMM), config auto 1 clic & découpage pondéré",
                    es: "Modo Multimodelo (MMM), autoconfiguración 1 clic y reparto ponderado",
                    pt: "Modo Multimodelo (MMM), autoconfiguração 1 clique e sharding ponderado",
                    ru: "Multi-Model-Mode (MMM), автонастройка в 1 клик и взвешенный шардинг",
                    ja: "マルチモデルモード (MMM)・ワンクリック構成＆重み付けシャーディング",
                    zh: "多模型模式 (MMM)、一键自动配置与显存加权分片"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_multi_model_mode.jpg",
                        caption: L10n.tr(lang,
                            de: "Multi-Model-Mode (MMM): 4 Orchestrierungsstrategien & Multi-IDE-Verbrauch (:8000/v1)",
                            en: "Multi-Model-Mode (MMM): 4 Orchestration Strategies & Multi-IDE Consumption (:8000/v1)",
                            fr: "MMM : 4 stratégies d'orchestration & consommation multi-IDE (:8000/v1)",
                            es: "MMM: 4 estrategias de orquestación y consumo multi-IDE (:8000/v1)",
                            pt: "MMM: 4 estratégias de orquestração e consumo multi-IDE (:8000/v1)",
                            ru: "MMM: 4 стратегии оркестровки и подключение Multi-IDE (:8000/v1)",
                            ja: "MMM: 4種のオーケストレーション戦略＆マルチ IDE 共有 (:8000/v1)",
                            zh: "MMM：四种编排策略与多 IDE 并发输出 (:8000/v1)")
                    ),
                    HelpDocVisual(
                        imageFile: "ssccc_mmm_autosetup_editor.jpg",
                        caption: L10n.tr(lang,
                            de: "MMM 1-Klick-Auto-Einrichtung & Nachträglicher Live-Slot-Editor",
                            en: "MMM 1-Click Auto-Setup Wizard & Post-Configuration Live Slot Editor",
                            fr: "Assistant Auto-Setup 1 clic MMM & éditeur de slots en direct",
                            es: "Asistente Auto-Setup MMM de 1 clic y editor de slots en vivo",
                            pt: "Assistente Auto-Setup MMM de 1 clique e editor de slots ao vivo",
                            ru: "Мастер автонастройки MMM в 1 клик и редактор слотов",
                            ja: "MMM ワンクリック自動設定ウィザード＆ライブスロット編集",
                            zh: "MMM 一键自动向导与实时槽位编辑器")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "Beim klassischen Sharding teilt SS-CCC große Einzelmodelle speichergewichtet über alle verfügbaren Knoten auf (z. B. 70 % der Transformer-Layer auf einen 36-GB-Studio, 30 % auf einen 16-GB-mini).",
                        "Der Multi-Model-Mode (MMM, 10. Menüpunkt) geht noch weiter: Er bündelt mehrere spezialisierte Modelle gleichzeitig im lokalen Cluster, Internet-Cluster oder gekoppelten Hybrid-Verbund (Parallel Pool, Mixture-of-Agents, Speculative Decoding, Sequenzielle Pipeline).",
                        "Mit dem neuen Auto-Setup-Assistenten richtest du komplette Multi-Modell-Topologien mit 1 Klick ein und kannst jeden Slot anschließend im Live-Editor umsortieren, duplizieren, umbenennen, auf andere Endpunkte legen oder im VRAM-Limit anpassen."
                    ],
                    en: [
                        "In classic sharding, SS-CCC splits large single models proportionally across all nodes' usable VRAM.",
                        "Multi-Model-Mode (MMM, 10th sidebar item) goes further by orchestrating multiple specialized models simultaneously across Local, Internet-WAN, or Hybrid clusters (Parallel Pool, Mixture-of-Agents, Speculative Decoding, Sequential Pipeline).",
                        "Using the 1-Click Auto-Setup Wizard, you can configure optimal multi-model pools instantly and customize every slot afterwards in the inline Live Editor."
                    ],
                    fr: [
                        "En découpage classique, SS-CCC répartit les grands modèles proportionnellement à la VRAM disponible.",
                        "Le Mode Multi-Modèle (MMM) orchestre plusieurs modèles spécialisés simultanément sur les clusters locaux, WAN ou hybrides (Pool parallèle, MoA, Speculative, Pipeline).",
                        "Avec l'assistant en 1 clic, vous configurez la topologie instantanément tout en gardant chaque slot modifiable en direct."
                    ],
                    es: [
                        "En el reparto clásico, SS-CCC divide modelos grandes proporcionalmente a la VRAM usable de cada Mac.",
                        "El Modo Multimodelo (MMM) orquesta varios modelos especializados a la vez en clústeres locales, WAN o híbridos (Pool paralelo, MoA, Especulativo, Pipeline).",
                        "Con el asistente de 1 clic configuras la topología al instante y luego editas o duplicas cada slot en vivo."
                    ],
                    pt: [
                        "No sharding clássico, o SS-CCC divide grandes modelos proporcionalmente pela VRAM disponível.",
                        "O Modo Multimodelo (MMM) orquestra vários modelos especializados em simultâneo (Pool paralelo, MoA, Especulativo, Pipeline) em clusters locais, WAN ou híbridos.",
                        "Com o assistente 1-clique configura a topologia de imediato e ajusta qualquer slot no editor ao vivo."
                    ],
                    ru: [
                        "При классическом шардинге SS-CCC делит крупную модель пропорционально доступной памяти узлов.",
                        "Multi-Model-Mode (MMM) объединяет сразу несколько специализированных моделей в локальном, WAN или гибридном кластере (Пул, MoA, Speculative, Конвейер).",
                        "Мастер автонастройки разворачивает конфигурацию в 1 клик с возможностью тонкой правки любого слота."
                    ],
                    ja: [
                        "従来のシャーディングでは、利用可能な VRAM に応じて単一の大規模モデルを各 Mac へ比例分割します。",
                        "マルチモデルモード (MMM) はさらに一歩進み、ローカル / WAN / ハイブリッド上で複数モデル（並列プール・MoA・投機的デコード・直列パイプライン）を同時協調させます。",
                        "ワンクリック自動セットアップ後でも、インラインエディタから並び替え・複製・VRAM 上限調整が自由に行えます。"
                    ],
                    zh: [
                        "在传统分片模式下，SS-CCC 按各节点可用显存比例切分单个大模型层。",
                        "多模型模式 (MMM) 更进一步，可在本地、广域网或混合集群中同时调度多个专长模型（并行池、MoA、投机解码、顺序流水线）。",
                        "借助一键自动配置向导即可快速构建多模型拓扑，随后还能在实时编辑器中随时调整顺序、复制槽位或更改端点。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Öffne 'Multi-Model-Mode' (10. Menüpunkt) und wähle deinen Bereich (Lokal, Internet oder Hybrid).",
                        "2. Wähle ein Auto-Setup-Profil (z. B. Coding & IDE-Schwarm oder Stufen-Pipeline) und klicke auf 'Automatisch einrichten'.",
                        "3. Passe bei Bedarf einzelne Slots nachträglich über das Regler-Symbol an (Reihenfolge, URL, Modell-ID, VRAM) und speichere."
                    ],
                    en: [
                        "1. Open 'Multi-Model-Mode' (10th sidebar item) and pick your scope (Local, Internet, or Hybrid).",
                        "2. Select an Auto-Setup profile and click 'Auto-Configure'.",
                        "3. Fine-tune any slot afterwards (reorder, duplicate, edit model ID, URL, or VRAM) and save."
                    ],
                    fr: [
                        "1. Ouvrez « Mode Multi-Modèle » et choisissez la portée (Local, Internet ou Hybride).",
                        "2. Sélectionnez un profil Auto-Setup puis cliquez sur « Configurer auto ».",
                        "3. Ajustez ensuite chaque slot (ordre, URL, ID modèle, VRAM) et enregistrez."
                    ],
                    es: [
                        "1. Abre «Modo Multimodelo» y elige el ámbito (Local, Internet o Híbrido).",
                        "2. Elige un perfil de configuración automática y pulsa «Configurar auto».",
                        "3. Ajusta cualquier slot luego (orden, URL, ID o VRAM) y guarda."
                    ],
                    pt: [
                        "1. Abra 'Modo Multimodelo' e selecione o âmbito (Local, Internet ou Híbrido).",
                        "2. Escolha um perfil automático e clique em 'Configurar auto'.",
                        "3. Ajuste depois qualquer slot (ordem, URL, ID ou VRAM) e guarde."
                    ],
                    ru: [
                        "1. Откройте «Multi-Model-Mode» и выберите область (Локально, Интернет или Гибрид).",
                        "2. Выберите профиль и нажмите «Автонастройка».",
                        "3. При необходимости отредактируйте любой слот (порядок, URL, модель, VRAM) и сохраните."
                    ],
                    ja: [
                        "1. サイドバーの「マルチモデルモード」を開き範囲（ローカル / インターネット / ハイブリッド）を選択します。",
                        "2. 自動プロファイルを選び「自動構成」をクリックします。",
                        "3. 必要に応じて個別スロット（順番・URL・モデルID・VRAM）を調整して保存します。"
                    ],
                    zh: [
                        "1. 打开侧边栏“多模型模式 (MMM)”，选择目标作用域（本地、互联网或混合）。",
                        "2. 选择自动配置方案并点击“自动配置”。",
                        "3. 如需微调，可随时展开具体槽位修改排序、端点 URL、模型 ID 或显存上限并保存。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: L10n.tr(lang, de: "Strategien", en: "Strategies", fr: "Stratégies", es: "Estrategias", pt: "Estratégias", ru: "Стратегии", ja: "戦略", zh: "编排策略"), value: "4 (Pool · MoA · Spec · Pipe)"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Auto-Profile", en: "Auto Profiles", fr: "Profils auto", es: "Perfiles auto", pt: "Perfis auto", ru: "Автопрофили", ja: "自動構成", zh: "自动方案"), value: L10n.tr(lang, de: "4 1-Klick-Presets", en: "4 1-Click Presets", fr: "4 préréglages 1 clic", es: "4 preajustes 1 clic", pt: "4 perfis 1 clique", ru: "4 шаблона в 1 клик", ja: "4種のワンクリック構成", zh: "4 种一键预设")),
                    HelpDocMetric(label: L10n.tr(lang, de: "Gemeinsamer Gateway", en: "Shared Gateway", fr: "Passerelle partagée", es: "Pasarela compartida", pt: "Gateway partilhado", ru: "Общий шлюз", ja: "共有ゲートウェイ", zh: "共享网关"), value: "OpenAI :8000/v1")
                ],
                bestPractices: trList(lang,
                    de: [
                        "Bei knapper VRAM-Grenze 'VRAM-Fit optimieren' nutzen, um niedrig priorisierte Slots sauber zu pausieren.",
                        "Für Multi-IDE-Betrieb (Xcode + Cursor + Claude Code gleichzeitig) das Profil 'Coding & IDE-Schwarm' wählen."
                    ],
                    en: [
                        "Use 'Optimize VRAM-Fit' after switching to a smaller cluster scope to prevent OOM.",
                        "Choose 'Coding & IDE Swarm' when serving Xcode, Cursor, and CLI agents concurrently."
                    ],
                    fr: [
                        "Utilisez « Optimiser la VRAM » après être passé sur un cluster plus petit.",
                        "Choisissez « Essaim Code & IDE » pour servir Xcode, Cursor et agents CLI en parallèle."
                    ],
                    es: [
                        "Usa «Optimizar ajuste VRAM» al cambiar a un clúster menor para evitar OOM.",
                        "Elige «Enjambre de Código e IDE» para alimentar Xcode, Cursor y agentes en paralelo."
                    ],
                    pt: [
                        "Use 'Otimizar ajuste VRAM' ao mudar para um cluster mais pequeno.",
                        "Escolha 'Enxame Código & IDE' para servir Xcode, Cursor e agentes em paralelo."
                    ],
                    ru: [
                        "Нажмите «Оптимизировать VRAM» при переходе на меньший пул, чтобы избежать переполнения.",
                        "Выберите профиль «Рой кода и IDE» для одновременной работы Xcode, Cursor и CLI-агентов."
                    ],
                    ja: [
                        "小規模スコープへ切替時は「VRAM適合を最適化」で空きスロットを自動調整してください。",
                        "Xcode や Cursor などを同時利用する場合は「コーディング & IDE スウォーム」が最適です。"
                    ],
                    zh: [
                        "切换至更小显存池时请点击“优化显存适配”，自动暂停低优先级槽位以防 OOM。",
                        "同时使用 Xcode、Cursor 与命令行智能体时，建议选择“编程与 IDE 并发蜂群”预设。"
                    ])
            )

        case "setup-hybrid":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "Weltweiter Internet-Cluster, Tailscale/DERP-Mesh & Live WAN-Bandbreiten-Monitor",
                    en: "Global Internet-Cluster, Tailscale/DERP Mesh & Live WAN Bandwidth Monitor",
                    fr: "Cluster Internet mondial, maillage Tailscale/DERP & moniteur WAN en direct",
                    es: "Clúster Internet global, malla Tailscale/DERP y monitor WAN en vivo",
                    pt: "Cluster Internet global, malha Tailscale/DERP e monitor WAN ao vivo",
                    ru: "Глобальный интернет-кластер, Tailscale/DERP и монитор пропускной способности WAN",
                    ja: "グローバル・インターネットクラスタ＆ライブ WAN 帯域モニター",
                    zh: "全球互联网集群、Tailscale/DERP 网状互联与实时 WAN 带宽监控"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_internet_wan_mesh.jpg",
                        caption: L10n.tr(lang,
                            de: "Weltweiter Internet-Mac-Verbund & Gekoppeltes Hybrid-Mesh",
                            en: "Global Internet Mac Cluster & Coupled Hybrid Mesh",
                            fr: "Cluster Mac Internet mondial & maillage hybride couplé",
                            es: "Clúster Mac de Internet global y malla híbrida acoplada",
                            pt: "Cluster Mac Internet global e malha híbrida acoplada",
                            ru: "Глобальный интернет-кластер Mac и гибридная сеть",
                            ja: "グローバル・インターネット Mac クラスタ＆結合ハイブリッドメッシュ",
                            zh: "全球互联网 Mac 集群与耦合混合网格")
                    ),
                    HelpDocVisual(
                        imageFile: "ssccc_wan_bandwidth_monitor.jpg",
                        caption: L10n.tr(lang,
                            de: "Live WAN Bandbreiten- & Datendurchsatz-Monitor (Downlink/Uplink, RTT, Jitter, tok/s)",
                            en: "Live WAN Bandwidth & Throughput Monitor (Downlink/Uplink, RTT, Jitter, tok/s)",
                            fr: "Moniteur bande passante WAN en direct (Débit, RTT, gigue, tok/s)",
                            es: "Monitor de ancho de banda y rendimiento WAN en vivo (RTT, Jitter, tok/s)",
                            pt: "Monitor de banda e débito WAN ao vivo (Download/Upload, RTT, Jitter, tok/s)",
                            ru: "Монитор пропускной способности WAN (Загрузка/Отдача, RTT, джиттер, tok/с)",
                            ja: "ライブ WAN 帯域＆スループットモニター（下り/上り・RTT・ジッター・tok/s）",
                            zh: "实时 WAN 带宽与吞吐监控（下行/上行、RTT、抖动与 tok/s）")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "Mit dem Internet-Verbund lassen sich beliebige Apple-Silicon-Macs weltweit über verschlüsselte Tunnel (Tailscale/WireGuard, libp2p/DERP oder direkte Endpunkte) zu regionalen Subclustern oder einem gekoppelten Hybrid-Verbund zusammenschließen.",
                        "Der integrierte WAN-Bandbreiten- & Datendurchsatz-Monitor misst in Echtzeit über netstat, ping und macOS networkQuality die tatsächliche Download-/Upload-Bandbreite, WAN-RTT-Latenz (ms), Jitter und Paketverlust.",
                        "So siehst du direkt, wie stark die Internetleitung die verteilte Token-Rate (tok/s) beeinflusst und ob DiLoCo/Pipeline-Stufen optimal getaktet sind."
                    ],
                    en: [
                        "Internet-Cluster links Macs globally over encrypted tunnels (Tailscale/WireGuard, libp2p/DERP, or direct endpoints) into regional subclusters or coupled Local+WAN hybrid meshes.",
                        "The integrated WAN Bandwidth & Throughput Monitor measures real Downlink/Uplink Mbps, WAN RTT latency (ms), jitter, and packet loss via netstat, ping, and networkQuality.",
                        "You can immediately observe how WAN throughput correlates with distributed tok/s and tune pipeline/DiLoCo intervals accordingly."
                    ],
                    fr: [
                        "Le cluster Internet relie des Macs dans le monde entier via des tunnels chiffrés (Tailscale/WireGuard, libp2p/DERP) en sous-clusters ou maillage hybride Local+WAN.",
                        "Le moniteur mesure en direct les débits descendants/montants, la latence RTT, la gigue et la perte de paquets via netstat, ping et networkQuality.",
                        "Vous observez immédiatement l'impact de la ligne Internet sur les tok/s distribués."
                    ],
                    es: [
                        "El Clúster de Internet enlaza Macs en todo el mundo por túneles cifrados (Tailscale/WireGuard, libp2p/DERP) creando mallas regionales o híbridas Local+WAN.",
                        "El monitor integrado mide descarga/subida Mbps, latencia RTT, jitter y pérdida con netstat, ping y networkQuality.",
                        "Observa al instante cómo el ancho de banda afecta a la tasa tok/s distribuida."
                    ],
                    pt: [
                        "O Cluster Internet interliga Macs globalmente por túneis encriptados (Tailscale/WireGuard, libp2p/DERP) em subclusters ou malha híbrida.",
                        "O monitor mede em tempo real débitos de download/upload, RTT (ms), jitter e perdas via netstat, ping e networkQuality.",
                        "Veja diretamente o impacto da ligação Internet no débito em tok/s."
                    ],
                    ru: [
                        "Интернет-кластер объединяет Mac по всему миру через шифрованные туннели (Tailscale/WireGuard, libp2p/DERP) в региональные или гибридные сети.",
                        "Встроенный монитор измеряет скорость загрузки/отдачи, пинг RTT (мс), джиттер и потери пакетов через netstat, ping и networkQuality.",
                        "Вы сразу видите, как пропускная способность интернета влияет на скорость генерации tok/с."
                    ],
                    ja: [
                        "インターネットクラスタは暗号化トンネル（Tailscale/WireGuard、libp2p/DERP）越しに世界中の Mac を地域サブクラスタやハイブリッドメッシュへ接続します。",
                        "内蔵の WAN 帯域モニターが netstat・ping・networkQuality を使い、実効上下速度・RTT 遅延・ジッター・パケット損失をリアルタイム計測します。",
                        "回線品質が分散推論の tok/s に与える影響を即座に確認できます。"
                    ],
                    zh: [
                        "互联网集群可通过加密隧道（Tailscale/WireGuard、libp2p/DERP）将全球各地的 Apple Silicon Mac 组成区域子集群或混合大集群。",
                        "内置 WAN 带宽监视器通过 netstat、ping 与 macOS networkQuality 实时测定上下行带宽、RTT 延迟、抖动和丢包率。",
                        "您可直接洞察广域网速率对分布式 tok/s 性能与流水线 / DiLoCo 步长的实际影响。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Öffne 'Internet-Verbund & Chat' und verbinde dich mit deinem Raum oder füge Partner-Endpunkte hinzu.",
                        "2. Starte die Live-WAN-Messung im Bandbreiten-Monitor, um Downlink, Uplink und RTT-Latenz zu erfassen.",
                        "3. Kopple in der 'Verbund-Übersicht' (Reiter 'Lokal + Internet') deinen lokalen TB-Kern mit dem WAN-Pool."
                    ],
                    en: [
                        "1. Open 'Internet Cluster & Chat' and join your room or add remote peer endpoints.",
                        "2. Run the WAN Bandwidth Monitor to capture live downlink, uplink, and RTT latency.",
                        "3. Couple your local Thunderbolt core with the WAN pool via 'Local + Internet' scope."
                    ],
                    fr: [
                        "1. Ouvrez « Cluster Internet & Chat », rejoignez votre salle ou ajoutez des pairs.",
                        "2. Lancez le moniteur WAN pour mesurer les débits et la latence RTT.",
                        "3. Couplez votre noyau Thunderbolt local avec le pool WAN via « Local + Internet »."
                    ],
                    es: [
                        "1. Abre «Clúster Internet y Chat», únete a tu sala o añade nodos remotos.",
                        "2. Ejecuta el monitor de banda WAN para capturar descarga, subida y latencia RTT.",
                        "3. Acopla tu núcleo Thunderbolt local con el pool WAN en «Local + Internet»."
                    ],
                    pt: [
                        "1. Abra 'Cluster Internet e Chat', entre na sala ou adicione nós remotos.",
                        "2. Execute o monitor WAN para medir download, upload e latência RTT.",
                        "3. Acople o seu núcleo Thunderbolt local ao pool WAN no âmbito 'Local + Internet'."
                    ],
                    ru: [
                        "1. Откройте «Интернет-кластер и Чат», подключитесь к комнате или добавьте пиры.",
                        "2. Запустите замер в мониторе WAN для измерения скорости и RTT-задержки.",
                        "3. Свяжите локальное ядро Thunderbolt с пулом WAN во вкладке «Локально + Интернет»."
                    ],
                    ja: [
                        "1. 「インターネットクラスタ＆チャット」を開き、ルームに参加するかピアを追加します。",
                        "2. WAN 帯域モニターでライブ計測を実行し、上下帯域と RTT を取得します。",
                        "3. 「ローカル＋インターネット」範囲でローカル TB コアと WAN プールを結合します。"
                    ],
                    zh: [
                        "1. 打开“互联网集群与聊天”，加入房间或手动添加远程伙伴 IP。",
                        "2. 运行 WAN 带宽监视器，测定实时上下行速度与网络延迟 RTT。",
                        "3. 在“本地 + 互联网”中将本地 Thunderbolt 核心与远程广域网集群耦合。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: L10n.tr(lang, de: "Transport", en: "Transport", fr: "Transport", es: "Transporte", pt: "Transporte", ru: "Транспорт", ja: "転送方式", zh: "传输协议"), value: "Tailscale · WireGuard · DERP"),
                    HelpDocMetric(label: L10n.tr(lang, de: "WAN-Telemetrie", en: "WAN Telemetry", fr: "Télémétrie WAN", es: "Telemetría WAN", pt: "Telemetria WAN", ru: "WAN-телеметрия", ja: "WAN 計測", zh: "WAN 遥测"), value: "netstat · ping · networkQuality"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Chat-Relay", en: "Chat Relay", fr: "Relais Chat", es: "Relé Chat", pt: "Relé Chat", ru: "Чат-релей", ja: "チャット連携", zh: "聊天中继"), value: "WebSocket /ws/wan/{room}")
                ],
                bestPractices: trList(lang,
                    de: [
                        "Für niedrige WAN-Latenz möglichst direkte WireGuard/Tailscale-Peers ohne DERP-Relay verwenden.",
                        "Bei hohen RTT-Werten (> 60 ms) größere Pipeline-Microbatches oder FP8-Aktivierungskompression nutzen."
                    ],
                    en: [
                        "Prefer direct WireGuard/Tailscale connections over relayed paths for lowest WAN RTT.",
                        "Enable FP8 activation compression when WAN RTT exceeds 60 ms."
                    ],
                    fr: [
                        "Préférez des liaisons directes WireGuard/Tailscale sans relais DERP pour réduire le RTT.",
                        "Activez la compression d'activations FP8 lorsque le RTT dépasse 60 ms."
                    ],
                    es: [
                        "Prioriza conexiones directas WireGuard/Tailscale sin relé DERP para minimizar el RTT.",
                        "Activa la compresión de activaciones FP8 cuando el RTT supere 60 ms."
                    ],
                    pt: [
                        "Prefira ligações diretas WireGuard/Tailscale em vez de DERP para menor RTT.",
                        "Ative a compressão de ativações FP8 quando o RTT exceder 60 ms."
                    ],
                    ru: [
                        "Для минимального RTT используйте прямое подключение WireGuard/Tailscale без релея DERP.",
                        "При RTT > 60 мс включайте сжатие активаций FP8."
                    ],
                    ja: [
                        "RTT を最小限に抑えるため、DERP リレーではなく直接 WireGuard/Tailscale 接続を優先してください。",
                        "WAN RTT が 60 ms を超える場合は FP8 アクティベーション圧縮を有効にしてください。"
                    ],
                    zh: [
                        "尽量使用 WireGuard/Tailscale 直连节点以获得最低广域网延迟，避免经由 DERP 中继。",
                        "当 WAN 延迟 RTT 高于 60 ms 时，请启用 FP8 激活张量压缩并增大微批次大小。"
                    ])
            )

        case "audio-party":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "Echtzeit-Sprachkoordination für verteilte Cluster-Teams im Konsolen-Party-Stil",
                    en: "Real-Time Console-Style Voice Coordination for Distributed Cluster Teams",
                    fr: "Coordination vocale en temps réel style console pour équipes distribuées",
                    es: "Coordinación de voz en tiempo real estilo consola para equipos distribuidos",
                    pt: "Coordenação de voz em tempo real estilo consola para equipas distribuídas",
                    ru: "Голосовая координация в стиле консольной вечеринки для распределённых команд",
                    ja: "分散クラスタチーム向けリアルタイム・コンソール風ボイスパーティ連携",
                    zh: "分布式集群团队的主机派对式实时语音协作系统"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_audio_party_collab.jpg",
                        caption: L10n.tr(lang,
                            de: "Cluster Audio-Party: AVAudioEngine Opus-16kHz-Sprachkanal neben dem Live-Chat",
                            en: "Cluster Audio-Party: AVAudioEngine Opus-16kHz Voice Channel alongside Live Chat",
                            fr: "Salon Audio Cluster : Canal vocal AVAudioEngine Opus-16kHz avec chat en direct",
                            es: "Sala de Audio del Clúster: Canal de voz AVAudioEngine Opus-16kHz con chat en vivo",
                            pt: "Festa Áudio do Cluster: Canal de voz AVAudioEngine Opus-16kHz com chat ao vivo",
                            ru: "Аудио-комната кластера: голосовой канал AVAudioEngine Opus-16kHz рядом с чатом",
                            ja: "クラスタ・オーディオパーティ: チャット横の AVAudioEngine Opus-16kHz ボイスチャンネル",
                            zh: "集群语音派对：实时聊天旁的 AVAudioEngine Opus-16kHz 低带宽语音频道")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "Direkt neben dem WAN-Teilnehmer-Chat bietet SS-CCC eine integrierte Cluster Audio-Party (inspiriert von Xbox/PlayStation-Party-Räumen). So können verteilte Entwickler- und Forscher-Teams während laufender Benchmarks oder Multi-Node-Setups direkt per Sprache zusammenarbeiten.",
                        "Technisch nutzt das System macOS AVAudioEngine für Low-Latency-Mikrofonaufnahme mit optionalem Push-to-Talk, Noise-Gate, Stummschaltung und automatischem Audio-Ducking (80 % Sprachmix / 20 % Cluster-Alarme) über den WebSocket-Endpunkt /ws/wan-audio.",
                        "Im Offline-/Vorschau-Modus bleiben alle UI-Kontrollen sicher simuliert, ohne unautorisiert auf Mikrofonhardware zuzugreifen."
                    ],
                    en: [
                        "Alongside the WAN participant chat, SS-CCC provides a built-in Cluster Audio-Party (inspired by console party rooms) so distributed teams can coordinate live during multi-node benchmarks.",
                        "Built on macOS AVAudioEngine with Push-to-Talk, Noise Gate, Mute/Deafen, and 80/20 voice-vs-alert mixing over /ws/wan-audio using Opus-16kHz framing.",
                        "In preview/offline mode, controls remain safe without capturing microphone audio unintentionally."
                    ],
                    fr: [
                        "À côté du chat WAN, SS-CCC propose un Salon Audio Cluster (inspiré des salons console) pour coordonner vos équipes pendant les benchmarks multi-nœuds.",
                        "Basé sur macOS AVAudioEngine avec Push-to-Talk, Noise Gate, Muet et mixage 80/20 via /ws/wan-audio (Opus 16 kHz).",
                        "En mode aperçu, toutes les commandes restent sûres sans capturer le microphone."
                    ],
                    es: [
                        "Junto al chat WAN, SS-CCC incluye una Sala de Audio del Clúster (estilo consola) para coordinarse en directo durante pruebas multi-nodo.",
                        "Construida con AVAudioEngine (Push-to-Talk, puerta de ruido, silencio) mediante /ws/wan-audio en Opus 16 kHz.",
                        "En modo vista previa, los controles permanecen simulados de forma segura sin activar el micrófono."
                    ],
                    pt: [
                        "Junto ao chat WAN, o SS-CCC oferece uma Festa Áudio do Cluster (estilo consola) para coordenação por voz em tempo real.",
                        "Baseada em AVAudioEngine com Push-to-Talk, Noise Gate e mistura 80/20 por /ws/wan-audio em Opus 16 kHz.",
                        "No modo de pré-visualização, os controlos mantêm-se simulados em segurança."
                    ],
                    ru: [
                        "Рядом с чатом WAN встроена Аудио-комната кластера (в стиле консольных голосовых чатов) для координации команды во время тестов.",
                        "Использует macOS AVAudioEngine (Push-to-Talk, шумоподавление, 80/20 микс) через /ws/wan-audio (Opus 16 кГц).",
                        "В режиме предпросмотра элементы управления безопасны и не обращаются к микрофону."
                    ],
                    ja: [
                        "WAN チャットの横にコンソール風の「クラスタ・オーディオパーティ」を内蔵し、分散チームの音声連携を可能にします。",
                        "AVAudioEngine をベースに Push-to-Talk、ノイズゲート、80/20 ミキシングを /ws/wan-audio (Opus 16kHz) 上で動作させます。",
                        "プレビューモード時はマイク入力を行わず安全にシミュレートされます。"
                    ],
                    zh: [
                        "在广域网聊天窗口旁，SS-CCC 内置了主机派对风格的「集群语音派对」，方便跨地域科研与开发团队实时通话协同。",
                        "底层采用 macOS AVAudioEngine 结合按键通话 (Push-to-Talk)、噪声门限与 80/20 混音，经由 /ws/wan-audio 进行 16kHz Opus 低带宽传输。",
                        "在离线/预览模式下所有语音控件保持安全模拟，不会擅自调用麦克风硬件。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Öffne 'Internet-Verbund & Chat' und scrolle zur Audio-Party-Leiste.",
                        "2. Wähle zwischen Open-Mic und Push-to-Talk und trete dem Sprachraum bei.",
                        "3. Nutze den Mix-Regler, um Cluster-Statusmeldungen dezent im Hintergrund zu halten."
                    ],
                    en: [
                        "1. Open 'Internet Cluster & Chat' and locate the Audio-Party bar.",
                        "2. Choose Open-Mic or Push-to-Talk and join the voice room.",
                        "3. Adjust the Voice/Alert mix ratio for clear team communication."
                    ],
                    fr: [
                        "1. Ouvrez « Cluster Internet & Chat » et allez à la section Salon Audio.",
                        "2. Choisissez micro libre ou Appuyer pour parler et rejoignez le salon.",
                        "3. Réglez la balance Voix/Alertes pour une écoute claire."
                    ],
                    es: [
                        "1. Abre «Clúster Internet y Chat» y ve a la tarjeta de Sala de Audio.",
                        "2. Elige micrófono abierto o Pulsar para hablar y únete a la sala.",
                        "3. Ajusta los controles y llamadas rápidas para coordinar al equipo."
                    ],
                    pt: [
                        "1. Abra 'Cluster Internet e Chat' e vá à secção Festa Áudio.",
                        "2. Escolha microfone aberto ou Premir para falar e entre na sala.",
                        "3. Ajuste o volume por participante e os atalhos rápidos."
                    ],
                    ru: [
                        "1. Откройте «Интернет-кластер и Чат» и перейдите в карточку Аудио-комнаты.",
                        "2. Выберите открытый микрофон или рацию (Push-to-Talk) и войдите в комнату.",
                        "3. Отрегулируйте громкость участников и используйте быстрые сигналы."
                    ],
                    ja: [
                        "1. 「インターネットクラスタ＆チャット」を開きオーディオパーティ欄を表示します。",
                        "2. オープンマイクまたはプッシュトゥトークを選んでパーティに参加します。",
                        "3. メンバー別音量やクイックコールアウトでチーム連携を行います。"
                    ],
                    zh: [
                        "1. 打开“互联网集群与聊天”，找到集群语音派对面板。",
                        "2. 选择自由麦或按键通话 (PTT) 并点击加入派对。",
                        "3. 按需调节各节点音量，或点击底部快捷状态广播指令。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: L10n.tr(lang, de: "Audio-Engine", en: "Audio Engine", fr: "Moteur audio", es: "Motor de audio", pt: "Motor áudio", ru: "Аудиодвижок", ja: "オーディオエンジン", zh: "音频引擎"), value: "macOS AVAudioEngine"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Codec / Mixing", en: "Codec / Mixing", fr: "Codec / Mixage", es: "Códec / Mezcla", pt: "Codec / Mistura", ru: "Кодек / Микс", ja: "コーデック", zh: "编码 / 混音"), value: "Opus 16 kHz · 80/20 Ducking"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Signalisierung", en: "Signaling", fr: "Signalisation", es: "Señalización", pt: "Sinalização", ru: "Сигнализация", ja: "シグナリング", zh: "信令通道"), value: "WebSocket /ws/wan-audio")
                ],
                bestPractices: trList(lang,
                    de: [
                        "Bei offenen Lautsprechern Push-to-Talk und Noise-Gate aktivieren, um Echos zu vermeiden.",
                        "Audio-Party gemeinsam mit der Weltrekord-Challenge oder Hybrid-MMM-Sessions nutzen."
                    ],
                    en: [
                        "Enable Push-to-Talk and Noise Gate when using external speakers.",
                        "Ideal for coordinating live Hybrid MMM runs and distributed benchmarks."
                    ],
                    fr: [
                        "Activez Appuyer pour parler et Réduction bruit avec des haut-parleurs.",
                        "Idéal lors de benchmarks distribués et de sessions MMM hybrides."
                    ],
                    es: [
                        "Activa Pulsar para hablar y supresor de ruido si usas altavoces externos.",
                        "Ideal para coordinar benchmarks distribuidos y sesiones MMM híbridas."
                    ],
                    pt: [
                        "Ative Premir para falar e porta de ruído ao usar colunas externas.",
                        "Ideal para coordenar benchmarks distribuídos e sessões MMM híbridas."
                    ],
                    ru: [
                        "При использовании внешних динамиков включайте рацию (PTT) и шумоподавление.",
                        "Удобно для синхронизации гибридных MMM-запусков и научных замеров."
                    ],
                    ja: [
                        "外部スピーカー使用時はハウリング防止のため Push-to-Talk とノイズゲートを有効にしてください。",
                        "ハイブリッド MMM 実行や大規模ベンチマーク計測の共同作業に最適です。"
                    ],
                    zh: [
                        "使用外放扬声器时建议开启按键通话 (PTT) 与噪声门限以消除回声。",
                        "非常适合在混合 MMM 编排或大规模分布式基准测试时实时沟通。"
                    ])
            )

        case "science-history":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "6-Tab-Forschungslabor: Roofline, WAN-DiLoCo, Splitwise KV, CO₂/EDP & Echtzeit-Historie",
                    en: "6-Tab Science Lab: Roofline, WAN/DiLoCo, Splitwise KV, Energy/CO₂ & History Telemetry",
                    fr: "Laboratoire 6 onglets : Roofline, WAN/DiLoCo, KV Splitwise, Énergie/CO₂ & Historique",
                    es: "Laboratorio 6 pestañas: Roofline, WAN/DiLoCo, KV Splitwise, Energía/CO₂ e Historial",
                    pt: "Laboratório 6 separadores: Roofline, WAN/DiLoCo, KV Splitwise, Energia/CO₂ e Histórico",
                    ru: "6-вкладочная лаборатория: Roofline, WAN/DiLoCo, KV Splitwise, Энергия/CO₂ и История",
                    ja: "6タブ研究ラボ: Roofline・WAN/DiLoCo・Splitwise KV・CO₂/EDP・履歴テレメトリ",
                    zh: "六选项卡科研实验室：Roofline、WAN/DiLoCo、Splitwise KV、碳排/EDP 与历史遥测"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_science_roofline_hero.jpg",
                        caption: L10n.tr(lang,
                            de: "Roofline-Grenzkurve, Ridge-Point-Analyse & Splitwise Prefill/Decode",
                            en: "Roofline Ceiling Analysis, Ridge-Point & Splitwise Prefill/Decode",
                            fr: "Analyse Roofline, point de coude & Prefill/Decode Splitwise",
                            es: "Curva Roofline, punto de inflexión y Prefill/Decode Splitwise",
                            pt: "Análise Roofline, ponto de crista e Prefill/Decode Splitwise",
                            ru: "Анализ Roofline, точка излома и Prefill/Decode Splitwise",
                            ja: "Roofline 上限曲線・リッジ点分析＆ Splitwise Prefill/Decode",
                            zh: "Roofline 天花板曲线、算力拐点分析与 Splitwise Prefill/Decode")
                    ),
                    HelpDocVisual(
                        imageFile: "ssccc_history_telemetry_lab.jpg",
                        caption: L10n.tr(lang,
                            de: "6-Tab Forschungslabor & Positionsbezogene Verlaufsaufzeichnung (CSV/Markdown/LaTeX)",
                            en: "6-Tab Science Lab & Per-Position History Recording (CSV/Markdown/LaTeX)",
                            fr: "Labo 6 onglets & enregistrement par position (CSV/Markdown/LaTeX)",
                            es: "Laboratorio de 6 pestañas e historial por posición (CSV/Markdown/LaTeX)",
                            pt: "Laboratório de 6 separadores e registo histórico (CSV/Markdown/LaTeX)",
                            ru: "6-вкладочная лаборатория и запись трендов (CSV/Markdown/LaTeX)",
                            ja: "6タブ研究ラボ＆項目別履歴記録 (CSV/Markdown/LaTeX)",
                            zh: "六选项卡科研实验室与分指标历史记录（支持 CSV/Markdown/LaTeX 导出）")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "Der Bereich 'Forschung & Leistung' arbeitet im Echtbetrieb konsequent mit realen SSE-Token-Streams, echten RTT-Pings und gemessener Hardware-Bandbreite — vollständig ohne Mock-Daten. Im Simulationsmodus liefert er klar gekennzeichnete, physikalisch konsistente Referenzwerte.",
                        "Auf 6 spezialisierten Reitern (Roofline & Leistung, WAN & DiLoCo, Speicher & KV-Budget, Energie & CO₂, Live-Messreihen & Statistik, Verlauf & Telemetrie) wertet das Labor Prefill vs. Decode, CI95-Konfidenzintervalle, Energy-Delay-Product (EDP) und regionale CO₂-Bilanzen aus.",
                        "Alle Messläufe — einschließlich der Läufe aus dem neuen Multi-Model-Mode (MMM) — fließen automatisch in die Verlaufsaufzeichnung und können als CSV, Markdown-Report oder IEEE/ACM-LaTeX-Tabelle exportiert werden."
                    ],
                    en: [
                        "Science & Performance runs exclusively on real SSE token streams, real RTT pings, and measured hardware bandwidth in live mode — with zero mock data. Simulation mode provides clearly badged, physically consistent reference values.",
                        "Across 6 specialized tabs (Roofline, WAN & DiLoCo, Memory & KV, Energy & CO₂, Live Trials & CI95, History & Export), the lab evaluates Prefill vs. Decode, Energy-Delay Product (EDP), and carbon footprint.",
                        "Every run — including Multi-Model-Mode (MMM) orchestrations — feeds directly into the Science History table for CSV, Markdown, or LaTeX export."
                    ],
                    fr: [
                        "Recherche & Roofline exploite exclusivement des flux SSE réels, des pings RTT réels et la bande passante mesurée en mode réel.",
                        "Sur 6 onglets (Roofline, WAN & DiLoCo, Mémoire & KV, Énergie & CO₂, Essais CI95, Historique), le labo évalue Prefill/Decode, EDP et bilan carbone.",
                        "Chaque exécution (y compris MMM) alimente l'historique pour export CSV, Markdown ou LaTeX."
                    ],
                    es: [
                        "Ciencia y Roofline funciona con flujos SSE reales, pings RTT medidos y ancho de banda real en modo en vivo.",
                        "En 6 pestañas (Roofline, WAN y DiLoCo, Memoria y KV, Energía y CO₂, Pruebas CI95, Historial) analiza Prefill/Decode, EDP y huella de carbono.",
                        "Cada ejecución (incluida MMM) se registra en el historial para exportar en CSV, Markdown o LaTeX."
                    ],
                    pt: [
                        "Ciência e Roofline utiliza fluxos SSE reais, pings RTT medidos e largura de banda real em modo ativo.",
                        "Em 6 separadores (Roofline, WAN e DiLoCo, Memória e KV, Energia e CO₂, Ensaios CI95, Histórico) avalia Prefill/Decode, EDP e emissões de CO₂.",
                        "Cada execução (incluindo MMM) entra no histórico para exportação CSV, Markdown ou LaTeX."
                    ],
                    ru: [
                        "Лаборатория «Наука и Roofline» работает с реальными SSE-потоками, реальными RTT-пингами и измеренной ПСП.",
                        "В 6 вкладках (Roofline, WAN и DiLoCo, Память и KV, Энергия и CO₂, Серии с CI95, История) оцениваются Prefill/Decode, EDP и углеродный след.",
                        "Все замеры, включая MMM, попадают в историю с экспортом в CSV, Markdown и LaTeX."
                    ],
                    ja: [
                        "「研究＆Roofline」は実運用時に実 SSE トークンストリーム・実 RTT・実測帯域のみを使用して計測を行います。",
                        "6つの専門タブ（Roofline、WAN・DiLoCo、メモリ＆KV、電力＆CO₂、再現計測＆CI95、履歴）で性能と消費電力を詳細に評価します。",
                        "MMM を含むすべての計測結果は自動的に履歴へ記録され、CSV / Markdown / LaTeX 形式で出力できます。"
                    ],
                    zh: [
                        "「科研与性能评估」在实时模式下严格采用真实 SSE Token 流、真实网络 RTT 与硬件实测带宽，绝不掺杂模拟假数据。",
                        "通过 6 个专业选项卡（Roofline、WAN 与 DiLoCo、显存与 KV、能耗与碳排、统计测试系列、历史追踪），深度分析 Prefill/Decode、EDP 与碳足迹。",
                        "所有测量结果（包括 MMM 多模型编排）均自动汇总至历史表，并支持一键导出 CSV、Markdown 与 IEEE/ACM LaTeX 表格。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Wähle oben im Forschungslabor den Analyse-Scope (Lokal, WAN oder gekoppelt).",
                        "2. Starte eine Live-Messreihe (N Trials) im Reiter 'Live-Messreihen & Statistik' oder führe einen MMM-Lauf aus.",
                        "3. Exportiere die Ergebnisse unter 'Verlauf & Telemetrie' direkt als CSV, Markdown oder LaTeX-Tabelle."
                    ],
                    en: [
                        "1. Select the analysis scope at the top of Science & Performance.",
                        "2. Run N live benchmark trials or execute a Multi-Model-Mode (MMM) orchestration.",
                        "3. Export results as CSV, Markdown, or IEEE/ACM LaTeX from the History tab."
                    ],
                    fr: [
                        "1. Sélectionnez la portée d'analyse en haut du laboratoire.",
                        "2. Lancez N essais en direct ou une orchestration MMM.",
                        "3. Exportez les résultats en CSV, Markdown ou LaTeX depuis l'onglet Historique."
                    ],
                    es: [
                        "1. Elige el ámbito de análisis en la parte superior del laboratorio.",
                        "2. Ejecuta N pruebas en vivo o una orquestación MMM.",
                        "3. Exporta los resultados en CSV, Markdown o LaTeX desde la pestaña Historial."
                    ],
                    pt: [
                        "1. Selecione o âmbito de análise no topo do laboratório.",
                        "2. Execute N ensaios ao vivo ou uma orquestração MMM.",
                        "3. Exporte os resultados em CSV, Markdown ou LaTeX no separador Histórico."
                    ],
                    ru: [
                        "1. Выберите область анализа вверху лаборатории.",
                        "2. Запустите серию из N замеров или оркестровку MMM.",
                        "3. Экспортируйте данные в CSV, Markdown или LaTeX во вкладке «История»."
                    ],
                    ja: [
                        "1. 上部で解析範囲（ローカル / WAN / 比較）を選択します。",
                        "2. N 回のライブ計測シリーズ、または MMM オーケストレーションを実行します。",
                        "3. 履歴・統計タブから CSV、Markdown、または LaTeX としてエクスポートします。"
                    ],
                    zh: [
                        "1. 在科研实验室顶部选择分析范围（本地、WAN 或对比）。",
                        "2. 启动 N 次实时基准测量系列，或执行一次 MMM 多模型运行。",
                        "3. 在统计或历史选项卡直接导出 CSV、JSON、LaTeX 与 BibTeX。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: L10n.tr(lang, de: "Analyse-Tabs", en: "Lab Tabs", fr: "Onglets d'analyse", es: "Pestañas", pt: "Separadores", ru: "Вкладки", ja: "解析タブ", zh: "分析选项卡"), value: "6 (Roofline · WAN · KV · CO₂ · Trials · History)"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Statistik", en: "Statistics", fr: "Statistiques", es: "Estadísticas", pt: "Estatística", ru: "Статистика", ja: "統計指標", zh: "统计精度"), value: "p50 · p95 · p99 · CI95"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Exporte", en: "Exports", fr: "Exports", es: "Exportación", pt: "Exportação", ru: "Экспорт", ja: "出力形式", zh: "导出格式"), value: "CSV · JSON · LaTeX · BibTeX")
                ],
                bestPractices: trList(lang,
                    de: [
                        "Für belastbare Paper-Werte mindestens 5–10 Live-Trials pro Modellkonfiguration ausführen.",
                        "MMM-Orchestrierungsläufe über die eingebaute MMM-Auswertungskarte direkt mit Einzelmodell-Baselines vergleichen."
                    ],
                    en: [
                        "Run at least 5–10 live trials per configuration for tight CI95 confidence intervals.",
                        "Compare MMM multi-model speedups directly against single-model baselines in the MMM evaluation card."
                    ],
                    fr: [
                        "Exécutez au moins 5 à 10 essais par configuration pour obtenir des intervalles CI95 fiables.",
                        "Comparez les gains MMM directement aux références mono-modèle."
                    ],
                    es: [
                        "Ejecuta al menos 5–10 pruebas por configuración para obtener intervalos CI95 sólidos.",
                        "Compara la aceleración MMM frente a la línea base de un solo modelo."
                    ],
                    pt: [
                        "Execute pelo menos 5–10 ensaios por configuração para intervalos CI95 robustos.",
                        "Compare os ganhos MMM diretamente com a linha de base de modelo único."
                    ],
                    ru: [
                        "Запускайте минимум 5–10 замеров для точного доверительного интервала CI95.",
                        "Сравнивайте ускорение MMM с одиночной моделью прямо в карточке оценки MMM."
                    ],
                    ja: [
                        "信頼性の高い CI95 信頼区間を得るため、各構成で最低 5〜10 回実行してください。",
                        "MMM 評価カードから単体モデルベースラインとの高速化倍率を直接比較できます。"
                    ],
                    zh: [
                        "建议每组配置至少运行 5–10 次实测，以获得严谨的 CI95 置信区间。",
                        "可在内置 MMM 科研评估卡中直接对比多模型与单模型基线的加速比。"
                    ])
            )

        case "runtimes":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "Live-Erkennung für oMLX, Ollama, llama.cpp, GGUF & HuggingFace-Hub",
                    en: "Live Runtime Discovery for oMLX, Ollama, llama.cpp, GGUF & HuggingFace Hub",
                    fr: "Détection en direct pour oMLX, Ollama, llama.cpp, GGUF & HuggingFace Hub",
                    es: "Detección en vivo para oMLX, Ollama, llama.cpp, GGUF y HuggingFace Hub",
                    pt: "Deteção ao vivo para oMLX, Ollama, llama.cpp, GGUF e HuggingFace Hub",
                    ru: "Живое обнаружение oMLX, Ollama, llama.cpp, GGUF и HuggingFace Hub",
                    ja: "oMLX・Ollama・llama.cpp・GGUF・HuggingFace Hub ライブ検出",
                    zh: "实时自动发现 oMLX、Ollama、llama.cpp、GGUF 与 HuggingFace 模型缓存"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_ecosystem_banner.jpg",
                        caption: L10n.tr(lang,
                            de: "Unterstützte MLX-, oMLX-, Ollama- und llama.cpp-Backends auf macOS",
                            en: "Supported MLX, oMLX, Ollama & llama.cpp Backends on macOS",
                            fr: "Moteurs MLX, oMLX, Ollama & llama.cpp pris en charge sur macOS",
                            es: "Backends MLX, oMLX, Ollama y llama.cpp soportados en macOS",
                            pt: "Backends MLX, oMLX, Ollama e llama.cpp suportados no macOS",
                            ru: "Поддерживаемые движки MLX, oMLX, Ollama и llama.cpp на macOS",
                            ja: "macOS でサポートされる MLX・oMLX・Ollama・llama.cpp バックエンド",
                            zh: "macOS 支持的 MLX、oMLX、Ollama 与 llama.cpp 推理后端")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "SS-CCC erkennt automatisch lokal laufende Inferenz-Server auf ihren Standard-Ports (:8000 für oMLX/MLX, :11434 für Ollama, :8080 für llama.cpp) sowie lokale .gguf-Dateien und Modelle im ~/.cache/huggingface/hub-Verzeichnis.",
                        "Sind keine Laufzeiten aktiv, zeigt die Modell-Werkstatt keine gefälschten Modelle an, sondern liefert eine präzise Runtime-Bereitschaftsprüfung inklusive passender Startbefehle.",
                        "Gefundene Live-Modelle stehen sofort auch im Multi-Model-Mode (MMM) für die automatische 1-Klick-Einrichtung bereit."
                    ],
                    en: [
                        "SS-CCC probes active local inference servers (:8000 oMLX/MLX, :11434 Ollama, :8080 llama.cpp) and scans local .gguf files plus ~/.cache/huggingface/hub.",
                        "When no runtimes are active, Model Studio never fabricates fake models — it displays live readiness status and exact startup commands instead.",
                        "Discovered live models are immediately available in Multi-Model-Mode (MMM) for 1-click Auto-Setup."
                    ],
                    fr: [
                        "SS-CCC détecte automatiquement les serveurs actifs (:8000 oMLX/MLX, :11434 Ollama, :8080 llama.cpp), vos fichiers .gguf et le cache ~/.cache/huggingface/hub.",
                        "Si aucun moteur ne tourne, l'atelier affiche l'état réel de disponibilité et les commandes de démarrage sans jamais inventer de faux modèles.",
                        "Les modèles détectés sont aussitôt utilisables dans l'assistant MMM en 1 clic."
                    ],
                    es: [
                        "SS-CCC detecta automáticamente servidores locales activos (:8000 oMLX/MLX, :11434 Ollama, :8080 llama.cpp), archivos .gguf y ~/.cache/huggingface/hub.",
                        "Si no hay motores activos, el taller nunca simula modelos falsos: muestra el estado real y el comando exacto de inicio.",
                        "Los modelos detectados quedan disponibles al instante en el Modo Multimodelo (MMM)."
                    ],
                    pt: [
                        "O SS-CCC deteta servidores locais ativos (:8000 oMLX/MLX, :11434 Ollama, :8080 llama.cpp), ficheiros .gguf e ~/.cache/huggingface/hub.",
                        "Sem serviços ativos, o estúdio mostra o estado real e os comandos exatos de arranque sem inventar modelos.",
                        "Os modelos descobertos ficam logo disponíveis para autoconfiguração em MMM."
                    ],
                    ru: [
                        "SS-CCC опрашивает локальные серверы (:8000 oMLX/MLX, :11434 Ollama, :8080 llama.cpp), файлы .gguf и кэш ~/.cache/huggingface/hub.",
                        "Если движки не запущены, мастерская показывает их реальный статус и команды запуска без вымышленных моделей.",
                        "Найденные модели сразу доступны в Multi-Model-Mode (MMM)."
                    ],
                    ja: [
                        "SS-CCC はローカル推論サーバー（:8000 oMLX/MLX、:11434 Ollama、:8080 llama.cpp）、.gguf ファイル、および ~/.cache/huggingface/hub を自動検出します。",
                        "実行中のサーバーがない場合も架空のモデルは表示せず、正確な準備状態と起動コマンドを提示します。",
                        "検出されたライブモデルは MMM でも即座にワンクリック構成へ利用できます。"
                    ],
                    zh: [
                        "SS-CCC 自动探测本地活跃推理服务端口（:8000 oMLX/MLX、:11434 Ollama、:8080 llama.cpp），并扫描本地 .gguf 文件与 ~/.cache/huggingface/hub 缓存。",
                        "当后台未启动任何服务时，模型工坊绝不伪造列表，而是清晰显示各引擎就绪状态与启动命令。",
                        "扫描到的实时模型可直接被 MMM 多模型模式一键调用。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Starte oMLX, Ollama oder llama-server auf deinem Rang-0-Mac.",
                        "2. Klicke in 'Modell Werkstatt' auf 'Modelle neu einlesen'.",
                        "3. Wähle ein Modell oder übernimm alle erkannten Live-Modelle direkt in MMM."
                    ],
                    en: [
                        "1. Launch oMLX, Ollama, or llama-server on your Rank 0 Mac.",
                        "2. Click 'Reload Models' in Model Studio.",
                        "3. Load a single model or auto-import all discovered models into MMM."
                    ],
                    fr: [
                        "1. Démarrez oMLX, Ollama ou llama-server sur le Rang 0.",
                        "2. Cliquez sur « Recharger les modèles » dans l'Atelier Modèles.",
                        "3. Chargez un modèle ou importez-les directement dans MMM."
                    ],
                    es: [
                        "1. Inicia oMLX, Ollama o llama-server en tu Mac Rango 0.",
                        "2. Pulsa «Recargar modelos» en Estudio de Modelos.",
                        "3. Carga un modelo o impórtalos todos automáticamente en MMM."
                    ],
                    pt: [
                        "1. Inicie oMLX, Ollama ou llama-server no Mac Rank 0.",
                        "2. Clique em 'Recarregar modelos' no Estúdio de Modelos.",
                        "3. Carregue um modelo ou importe todos diretamente para MMM."
                    ],
                    ru: [
                        "1. Запустите oMLX, Ollama или llama-server на Mac с Rank 0.",
                        "2. Нажмите «Обновить модели» в Мастерской моделей.",
                        "3. Выберите модель или перенесите их в MMM."
                    ],
                    ja: [
                        "1. Rank 0 の Mac で oMLX・Ollama・llama-server のいずれかを起動します。",
                        "2. モデルスタジオで「モデルを再読込」をクリックします。",
                        "3. 単一モデルを起動するか、検出された全モデルを MMM へ取り込みます。"
                    ],
                    zh: [
                        "1. 在 Rank 0 主节点上启动 oMLX、Ollama 或 llama-server。",
                        "2. 在“模型工坊”右上角点击“重新加载模型”。",
                        "3. 选中目标模型，或在 MMM 中一键自动装载全部已发现模型。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: "oMLX / MLX", value: "Port :8000 (/v1/models)"),
                    HelpDocMetric(label: "Ollama", value: "Port :11434 (/api/tags)"),
                    HelpDocMetric(label: "llama.cpp", value: "Port :8080 (/v1/models)")
                ],
                bestPractices: trList(lang,
                    de: [
                        "Für Apple Silicon bevorzugt MLX-4bit/8bit-Quantisierungen (oMLX) für maximalen Speicherdurchsatz verwenden.",
                        "Ollama eignet sich ideal als schneller Fallback oder für heterogene GGUF-Modelle."
                    ],
                    en: [
                        "Prefer MLX 4-bit/8-bit models via oMLX on Apple Silicon for peak memory bandwidth utilization.",
                        "Use Ollama alongside oMLX for hybrid multi-runtime MMM pools."
                    ],
                    fr: [
                        "Privilégiez MLX 4/8 bits via oMLX sur Apple Silicon pour un débit mémoire maximal.",
                        "Combinez Ollama et oMLX dans MMM pour des pools mixtes."
                    ],
                    es: [
                        "Prefiere modelos MLX de 4/8 bits con oMLX en Apple Silicon para máximo rendimiento.",
                        "Combina Ollama con oMLX para pools híbridos en MMM."
                    ],
                    pt: [
                        "Prefira modelos MLX 4/8-bit com oMLX em Apple Silicon para máximo débito de memória.",
                        "Use Ollama em conjunto com oMLX para pools híbridos no MMM."
                    ],
                    ru: [
                        "На Apple Silicon используйте 4/8-битные MLX модели через oMLX для максимальной скорости ПСП.",
                        "Совмещайте Ollama и oMLX в гибридных пулах MMM."
                    ],
                    ja: [
                        "Apple Silicon では最高帯域効率のため oMLX の MLX 4bit/8bit モデルを推奨します。",
                        "ハイブリッド MMM 構成では Ollama と oMLX の併用が効果的です。"
                    ],
                    zh: [
                        "在 Apple Silicon 上优先选用 oMLX 运行 MLX 4-bit/8-bit 模型，以充分榨干统一内存带宽。",
                        "可将 Ollama 与 oMLX 组合接入 MMM，用于跨格式混合模型调度。"
                    ])
            )

        case "agents-api":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "1-Klick-Anbindung für OpenCode, Hermes, Antigravity, Cursor, VS Code & Xcode",
                    en: "1-Click Integration for OpenCode, Hermes, Antigravity, Cursor, VS Code & Xcode",
                    fr: "Intégration en 1 clic pour OpenCode, Hermes, Antigravity, Cursor, VS Code & Xcode",
                    es: "Integración en 1 clic para OpenCode, Hermes, Antigravity, Cursor, VS Code y Xcode",
                    pt: "Integração em 1 clique para OpenCode, Hermes, Antigravity, Cursor, VS Code e Xcode",
                    ru: "Интеграция в 1 клик для OpenCode, Hermes, Antigravity, Cursor, VS Code и Xcode",
                    ja: "OpenCode・Hermes・Antigravity・Cursor・VS Code・Xcode ワンクリック統合",
                    zh: "一键接入 OpenCode、Hermes、Antigravity、Cursor、VS Code 与 Xcode"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_agents_ide_ecosystem.jpg",
                        caption: L10n.tr(lang,
                            de: "Lokales KI-Ökosystem: 6 IDEs & Agent-Harnesses an einem gemeinsamen Cluster-Endpunkt",
                            en: "Local AI Ecosystem: 6 IDEs & Agent Harnesses Sharing One Unified Cluster Endpoint",
                            fr: "Écosystème IA local : 6 IDE & harnais d'agents connectés au même cluster",
                            es: "Ecosistema de IA local: 6 IDE y agentes compartiendo un mismo endpoint",
                            pt: "Ecossistema IA local: 6 IDEs e agentes partilhando um único endpoint",
                            ru: "Локальная ИИ-экосистема: 6 IDE и агентов на общем шлюзе кластера",
                            ja: "ローカル AI エコシステム: 6種の IDE・エージェントが共通クラスタへ接続",
                            zh: "本地 AI 开发生态：6 款 IDE 与智能体共享统一集群端点")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "SS-CCC stellt über :8000/v1 (OpenAI-kompatibel) und :11434 (Ollama-kompatibel) einen zentralen API-Eingang bereit. Im Bereich 'Agenten & Umgebungen' generierst du mit einem Klick fertige JSON-/YAML-/Shell-Konfigurationen für OpenCode, Hermes Agent, Google Antigravity, Cursor, VS Code und Apple Xcode.",
                        "In Kombination mit Multi-Model-Mode (MMM) können mehrere IDEs und CLI-Agenten (z. B. Xcode + Cursor + Claude Code) gleichzeitig auf denselben Cluster zugreifen — SS-CCC berechnet in Echtzeit den verfügbaren tok/s-Durchsatz pro Client."
                    ],
                    en: [
                        "SS-CCC exposes :8000/v1 (OpenAI-compatible) and :11434 (Ollama-compatible) as unified gateways. In 'Agents & Environments', 1-click exports configure OpenCode, Hermes Agent, Google Antigravity, Cursor, VS Code, and Apple Xcode.",
                        "Combined with Multi-Model-Mode (MMM), multiple IDEs and CLI harnesses can consume the cluster simultaneously with real-time per-client tok/s estimation."
                    ],
                    fr: [
                        "SS-CCC expose :8000/v1 (OpenAI) et :11434 (Ollama) comme passerelles locales. Dans « Agents & IDEs », générez en 1 clic les configs pour OpenCode, Hermes, Antigravity, Cursor, VS Code et Xcode.",
                        "Avec le MMM, plusieurs IDE consomment le cluster simultanément avec estimation en direct du débit par client."
                    ],
                    es: [
                        "SS-CCC expone :8000/v1 (compatible OpenAI) y :11434 (Ollama). En «Agentes e IDEs» generas en 1 clic configuraciones para OpenCode, Hermes, Antigravity, Cursor, VS Code y Xcode.",
                        "Con MMM, múltiples IDE consumen el clúster en paralelo con estimación de tok/s por cliente."
                    ],
                    pt: [
                        "O SS-CCC expõe :8000/v1 (OpenAI) e :11434 (Ollama). Em 'Agentes e IDEs', exporta num clique configurações para OpenCode, Hermes, Antigravity, Cursor, VS Code e Xcode.",
                        "Juntamente com MMM, vários IDEs consomem o cluster em paralelo com débito estimado por cliente."
                    ],
                    ru: [
                        "SS-CCC предоставляет единые шлюзы :8000/v1 (OpenAI) и :11434 (Ollama). В разделе «Агенты и IDE» в 1 клик создаются конфиги для OpenCode, Hermes, Antigravity, Cursor, VS Code и Xcode.",
                        "Вместе с MMM несколько IDE одновременно работают с кластером с расчётом tok/с на каждого клиента."
                    ],
                    ja: [
                        "SS-CCC は :8000/v1 (OpenAI互換) と :11434 (Ollama互換) を統合ゲートウェイとして提供します。「エージェント＆IDE」から各ツールの設定をワンクリック生成できます。",
                        "MMM と組み合わせることで複数の IDE が同時に推論を実行でき、クライアント毎の tok/s も算出されます。"
                    ],
                    zh: [
                        "SS-CCC 提供 :8000/v1（兼容 OpenAI）与 :11434（兼容 Ollama）统一网关，支持在「智能体与 IDE」中一键生成 OpenCode、Hermes、Antigravity、Cursor、VS Code 与 Xcode 配置。",
                        "结合 MMM 多模型模式，多款 IDE 可并发从同一集群获取推理算力，并实时估算单个客户端吞吐。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Öffne 'Agenten & IDEs' und wähle deine Ziel-IDE oder deinen Agent-Harness.",
                        "2. Kopiere die generierte Konfiguration (Base-URL http://127.0.0.1:8000/v1) oder schreibe sie direkt in die Config-Datei.",
                        "3. Prüfe im Tab 'API & Konsole' oder 'Multi-Model-Mode' den Live-API-Status."
                    ],
                    en: [
                        "1. Open 'Agents & IDEs' and pick your IDE or Agent Harness.",
                        "2. Copy or apply the generated config pointing to http://127.0.0.1:8000/v1.",
                        "3. Monitor live client throughput in 'API & Console' or 'Multi-Model-Mode'."
                    ],
                    fr: [
                        "1. Ouvrez « Agents & IDEs » et choisissez votre IDE ou agent.",
                        "2. Copiez ou appliquez la configuration pointant vers http://127.0.0.1:8000/v1.",
                        "3. Surveillez l'état API dans « API & Console » ou « Mode Multi-Modèle »."
                    ],
                    es: [
                        "1. Abre «Agentes e IDEs» y elige tu IDE o agente.",
                        "2. Copia o aplica la configuración apuntando a http://127.0.0.1:8000/v1.",
                        "3. Verifica la respuesta en «API y Consola» o «Modo Multimodelo»."
                    ],
                    pt: [
                        "1. Abra 'Agentes e IDEs' e escolha o seu IDE ou agente.",
                        "2. Copie ou grave a configuração para http://127.0.0.1:8000/v1.",
                        "3. Verifique o estado da API em 'API e Consola' ou 'Modo Multimodelo'."
                    ],
                    ru: [
                        "1. Откройте «Агенты и IDE» и выберите свою IDE или агента.",
                        "2. Запишите конфигурацию для http://127.0.0.1:8000/v1 в 1 клик.",
                        "3. Проверьте живой статус в «API и Консоль» или «MMM»."
                    ],
                    ja: [
                        "1. 「エージェント＆IDE」を開き、対象の IDE またはエージェントを選択します。",
                        "2. http://127.0.0.1:8000/v1 向けの設定ファイルをコピーまたはワンクリック適用します。",
                        "3. 「API＆コンソール」または「MMM」で稼働状態を確認します。"
                    ],
                    zh: [
                        "1. 打开“智能体与 IDE”，选择目标 IDE 或编码智能体框架。",
                        "2. 一键写入配置文件（指向 http://127.0.0.1:8000/v1）或复制到剪贴板。",
                        "3. 前往“API 与控制台”或“MMM 多模型模式”测试实时接口。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: "OpenAI API", value: "http://127.0.0.1:8000/v1"),
                    HelpDocMetric(label: "Ollama API", value: "http://127.0.0.1:11434"),
                    HelpDocMetric(label: L10n.tr(lang, de: "1-Klick-IDEs", en: "1-Click IDEs", fr: "IDE 1-clic", es: "IDEs 1-clic", pt: "IDEs 1-clique", ru: "IDE в 1 клик", ja: "対応 IDE 数", zh: "一键支持"), value: "6+ (Xcode, Cursor, VS Code...)")
                ],
                bestPractices: trList(lang,
                    de: [
                        "Im Multi-IDE-Betrieb die erwartete Anzahl gleichzeitiger Clients in MMM einstellen, um realistische tok/s pro IDE zu sehen.",
                        "API-Key-Feld in IDEs bei lokalem Betrieb beliebig auf 'ss-ccc-local' setzen."
                    ],
                    en: [
                        "Set the concurrent client count in MMM to see realistic per-IDE tok/s headroom.",
                        "Use 'ss-ccc-local' as placeholder API key for local OpenAI-compatible clients."
                    ],
                    fr: [
                        "Ajustez le nombre de clients simultanés dans MMM pour estimer les tok/s réels par IDE.",
                        "Utilisez 'ss-ccc-local' comme clé API locale."
                    ],
                    es: [
                        "Ajusta el número de clientes simultáneos en MMM para estimar los tok/s reales.",
                        "Usa 'ss-ccc-local' como clave API de relleno en local."
                    ],
                    pt: [
                        "Defina o número de clientes em paralelo no MMM para estimar o débito por IDE.",
                        "Use 'ss-ccc-local' como API key local."
                    ],
                    ru: [
                        "Задайте число клиентов в MMM для оценки скорости tok/с на каждую IDE.",
                        "Используйте любой ключ вроде 'ss-ccc-local' для локальных клиентов OpenAI."
                    ],
                    ja: [
                        "実効速度を把握するため、MMM で同時利用する IDE クライアント数を設定してください。",
                        "ローカル接続の API キー欄には 'ss-ccc-local' 等の任意文字列を指定できます。"
                    ],
                    zh: [
                        "可在 MMM 中调节并发 IDE 数量，实时评估每个客户端分配到的 tok/s。",
                        "本地连接时 API Key 字段可填写任意占位符（如 'ss-ccc-local'）。"
                    ])
            )

        case "updater-ci":
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "GitHub-gesteuerte Programm-Updates, Release-Tracking & sichere SHA-Prüfung",
                    en: "GitHub-Controlled Program Updates, Release Tracking & Safe SHA Verification",
                    fr: "Mises à jour GitHub automatiques, suivi des versions & vérification SHA",
                    es: "Actualizaciones controladas por GitHub, seguimiento de versiones y verificación SHA",
                    pt: "Atualizações controladas por GitHub, seguimento de versões e verificação SHA",
                    ru: "Обновления через GitHub, контроль версий и проверка SHA",
                    ja: "GitHub 連携アップデート・リリース追跡＆安全な SHA 検証",
                    zh: "GitHub 驱动的程序更新、版本跟踪与安全 SHA 校验"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_github_auto_updater.jpg",
                        caption: L10n.tr(lang,
                            de: "Automatische GitHub-Update-Pipeline mit Version-Check & Deadlock-freier Ausführung",
                            en: "Automatic GitHub Update Pipeline with Version Tracking & Deadlock-Free Execution",
                            fr: "Pipeline de mise à jour GitHub avec contrôle de version sans blocage",
                            es: "Pipeline de actualización GitHub con verificación sin bloqueos",
                            pt: "Pipeline de atualização GitHub com verificação segura",
                            ru: "Конвейер автообновления GitHub без блокировок",
                            ja: "デッドロック防止設計の自動 GitHub アップデートパイプライン",
                            zh: "防死锁 GitHub 自动版本监控与一键更新流水线")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "SS-CCC prüft automatisch gegen das GitHub-Repository (version.json & GitHub Releases), ob eine neuere Version vorliegt. Sobald ein neues Release erkannt wird, informiert dich das Update-Banner mit Changelog und einem 1-Klick-Aktualisierungsbefehl.",
                        "Technisch nutzt der Updater getrennte stdout/stderr-Pipes ohne Prozess-Deadlocks, validiert Commit-SHAs sauber und meldet Fehlerzustände transparent im UI."
                    ],
                    en: [
                        "SS-CCC checks GitHub (version.json & Releases) automatically for newer builds. When an update is available, a clean banner displays the changelog and 1-click update action.",
                        "Under the hood, the updater separates stdout/stderr pipes to prevent process deadlocks, validates commit SHAs cleanly, and surfaces clear status diagnostics."
                    ],
                    fr: [
                        "SS-CCC vérifie automatiquement GitHub (version.json & Releases). En cas de nouvelle version, une bannière affiche le changelog et l'action en 1 clic.",
                        "Sous le capot, le module sépare les flux stdout/stderr pour éviter tout blocage et vérifie les SHA."
                    ],
                    es: [
                        "SS-CCC comprueba automáticamente GitHub (version.json y Releases) y muestra un aviso con notas y actualización en 1 clic.",
                        "Separa tuberías stdout/stderr sin bloqueos de subprocesos y valida los hashes SHA."
                    ],
                    pt: [
                        "O SS-CCC consulta o GitHub (version.json e Releases) e apresenta notas e atualização num clique.",
                        "Separa fluxos stdout/stderr para evitar bloqueios de processo e valida os SHA."
                    ],
                    ru: [
                        "SS-CCC автоматически проверяет GitHub (version.json и Releases) и отображает список изменений с кнопкой обновления в 1 клик.",
                        "Раздельные каналы stdout/stderr исключают зависание процессов при сборке, а SHA надёжно сверяется."
                    ],
                    ja: [
                        "SS-CCC は GitHub（version.json および Releases）を自動監視し、更新検出時は変更履歴とワンクリック更新を提示します。",
                        "内部では stdout/stderr パイプを分離しデッドロックを防止したうえで SHA 検証を行います。"
                    ],
                    zh: [
                        "SS-CCC 自动轮询 GitHub 仓库的 version.json 与 Releases。发现新版本时展示更新日志并提供一键更新。",
                        "底层采用独立 stdout/stderr 管道读写避免子进程死锁，并严格校验提交 SHA。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Klicke oben rechts auf das Versions-Badge oder öffne den Update-Dialog.",
                        "2. Prüfe die angezeigte Zielversion gegenüber deiner installierten Version.",
                        "3. Starte das Update per 1-Klick oder führe 'git pull && swift build' im Projektordner aus."
                    ],
                    en: [
                        "1. Click the version badge in the top bar or open the Update prompt.",
                        "2. Compare the available remote version against your local build.",
                        "3. Apply the update in 1 click or pull and rebuild via SwiftPM."
                    ],
                    fr: [
                        "1. Cliquez sur le badge de version en haut à droite.",
                        "2. Comparez la version distante avec votre version locale.",
                        "3. Lancez la mise à jour en 1 clic ou via 'git pull && swift build'."
                    ],
                    es: [
                        "1. Haz clic en la insignia de versión arriba a la derecha.",
                        "2. Compara la versión remota disponible con tu compilación local.",
                        "3. Aplica la actualización en 1 clic o ejecuta 'git pull && swift build'."
                    ],
                    pt: [
                        "1. Clique no selo de versão no canto superior direito.",
                        "2. Compare a versão remota com a instalação local.",
                        "3. Atualize num clique ou execute 'git pull && swift build'."
                    ],
                    ru: [
                        "1. Нажмите на значок версии в правом верхнем углу.",
                        "2. Сравните удалённую и локальную версии.",
                        "3. Обновитесь в 1 клик или через 'git pull && swift build'."
                    ],
                    ja: [
                        "1. 右上のバージョンバッジをクリックして更新ダイアログを開きます。",
                        "2. 現在のバージョンと最新の GitHub バージョンを比較します。",
                        "3. ワンクリックで更新・再ビルドするか、'git pull && swift build' を実行します。"
                    ],
                    zh: [
                        "1. 点击窗口右上角的版本胶囊标识打开更新提示窗口。",
                        "2. 对比当前本地版本与远程 GitHub 最新版本号及提交 SHA。",
                        "3. 点击一键更新自动拉取并重编译，或手动运行 'git pull && swift build'。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: L10n.tr(lang, de: "Quelle", en: "Source", fr: "Source", es: "Origen", pt: "Origem", ru: "Источник", ja: "ソース", zh: "更新源"), value: "GitHub Releases + version.json"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Sync-Modus", en: "Sync Mode", fr: "Mode sync", es: "Modo sync", pt: "Modo sync", ru: "Режим", ja: "同期方式", zh: "同步方式"), value: "Async · Non-blocking"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Aktuelle Version", en: "Current Version", fr: "Version actuelle", es: "Versión actual", pt: "Versão atual", ru: "Текущая версия", ja: "現在バージョン", zh: "当前版本"), value: AppReleaseMetadata.currentVersion)
                ],
                bestPractices: trList(lang,
                    de: [
                        "Vor eigenen Code-Änderungen lokale Änderungen committen, damit Auto-Updates sauber mergen können.",
                        "Nach jedem Update einmal './scripts/run_ssccc.sh' neu starten, um die aktuelle Binary zu laden."
                    ],
                    en: [
                        "Commit local tweaks before running auto-update so merges stay clean.",
                        "Restart via './scripts/run_ssccc.sh' after pulling updates."
                    ],
                    fr: [
                        "Validez vos modifications locales avant de lancer une mise à jour automatique.",
                        "Redémarrez avec './scripts/run_ssccc.sh' après mise à jour."
                    ],
                    es: [
                        "Haz commit de tus cambios locales antes de ejecutar la actualización automática.",
                        "Reinicia con './scripts/run_ssccc.sh' tras actualizar."
                    ],
                    pt: [
                        "Faça commit de alterações locais antes de atualizar automaticamente.",
                        "Reinicie com './scripts/run_ssccc.sh' após a atualização."
                    ],
                    ru: [
                        "Сохраните локальные изменения (commit) перед автообновлением.",
                        "Перезапустите приложение через './scripts/run_ssccc.sh'."
                    ],
                    ja: [
                        "自動更新の前にローカル変更をコミットしておくとマージが安全です。",
                        "更新後は './scripts/run_ssccc.sh' で最新バイナリを再起動してください。"
                    ],
                    zh: [
                        "运行自动更新前请先提交本地修改，避免 Git 合并冲突。",
                        "更新完成后使用 './scripts/run_ssccc.sh' 重启即可加载最新二进制版本。"
                    ])
            )

        default: // "launch-tests"
            return HelpDocDeepDive(
                id: id,
                subtitle: L10n.tr(lang,
                    de: "Starten über scripts/run_ssccc.sh, Swift-Kompilierung & globale Test-Suite",
                    en: "Launching via scripts/run_ssccc.sh, Swift Compilation & Global Test Suite",
                    fr: "Lancement via scripts/run_ssccc.sh, compilation Swift & suite de tests globale",
                    es: "Inicio mediante scripts/run_ssccc.sh, compilación Swift y suite de pruebas global",
                    pt: "Arranque via scripts/run_ssccc.sh, compilação Swift e suite global de testes",
                    ru: "Запуск через scripts/run_ssccc.sh, сборка Swift и глобальные автотесты",
                    ja: "scripts/run_ssccc.sh での起動・Swift ビルド＆グローバルテストスイート",
                    zh: "通过 scripts/run_ssccc.sh 启动、Swift 编译与全局测试套件"),
                visuals: [
                    HelpDocVisual(
                        imageFile: "ssccc_use_cases_showcase.jpg",
                        caption: L10n.tr(lang,
                            de: "Praxiseinsatz & Verifizierte Architektur-Suite über alle Global-Tests",
                            en: "Production Use Cases & Verified Architecture across all Global Suite Tests",
                            fr: "Cas d'usage & architecture vérifiée par l'ensemble des tests globaux",
                            es: "Casos de uso reales y arquitectura verificada en todas las pruebas",
                            pt: "Casos de uso reais e arquitetura verificada na suite global",
                            ru: "Боевые сценарии и архитектура, проверенная глобальными тестами",
                            ja: "実践ユースケースとグローバルテストスイート検証構成",
                            zh: "核心应用全景与全套全局测试验证架构")
                    )
                ],
                detailedParagraphs: trList(lang,
                    de: [
                        "SS-CCC wird als natives macOS-SwiftUI-Programm über SwiftPM (swift build) oder direkt über das Startskript ./scripts/run_ssccc.sh gestartet. Das Startskript stellt sicher, dass alle Swift-Quelldateien inklusive Theme, ViewModel, allen 11 Ansichten und Ressourcen gebündelt werden.",
                        "Die integrierte Qualitätssicherung besteht aus kompilierten Swift-Laufzeittests (tests/run_swift_checks.swift) und der Python-Verifikationssuite (tests/test_global_suite.py), die sowohl Hardware-Logik, Lokalisierung in 8 Sprachen als auch UI-Symbole absichert."
                    ],
                    en: [
                        "SS-CCC launches as a native macOS SwiftUI application via SwiftPM (swift build) or ./scripts/run_ssccc.sh, ensuring all models, view models, and 11 views compile together.",
                        "Quality assurance combines compiled Swift runtime checks (tests/run_swift_checks.swift) with a global Python verification suite (tests/test_global_suite.py) covering M1–M12+ scaling, 8-language parity, WAN monitors, and MMM."
                    ],
                    fr: [
                        "SS-CCC se lance en application macOS native via SwiftPM ou ./scripts/run_ssccc.sh en compilant l'ensemble des 11 vues et modèles.",
                        "La qualité est vérifiée par des tests Swift compilés (tests/run_swift_checks.swift) et la suite Python (tests/test_global_suite.py) couvrant 8 langues."
                    ],
                    es: [
                        "SS-CCC se inicia como app nativa macOS SwiftUI vía SwiftPM o ./scripts/run_ssccc.sh reuniendo todas las 11 vistas.",
                        "El aseguramiento de calidad combina tests Swift compilados con la suite Python global y paridad de 8 idiomas."
                    ],
                    pt: [
                        "O SS-CCC arranca como aplicação nativa SwiftUI via SwiftPM ou ./scripts/run_ssccc.sh compilando as 11 vistas.",
                        "A qualidade combina testes Swift compilados com a suite global Python para os 8 idiomas."
                    ],
                    ru: [
                        "SS-CCC запускается как нативное приложение macOS SwiftUI через SwiftPM или ./scripts/run_ssccc.sh, собирая все 11 представлений.",
                        "Автопроверка включает скомпилированные тесты Swift и глобальный набор тестов Python для всех 8 языков."
                    ],
                    ja: [
                        "SS-CCC は SwiftPM または ./scripts/run_ssccc.sh を通じて全11画面をバンドルしたネイティブ SwiftUI アプリとして起動します。",
                        "品質保証は Swift ランタイムテストと 8 言語パリティを網羅するグローバル検証スイートで自動化されています。"
                    ],
                    zh: [
                        "SS-CCC 作为原生 macOS SwiftUI 应用可通过 SwiftPM 或 ./scripts/run_ssccc.sh 启动，完整打包 11 个功能视图与全部资源。",
                        "内建质量保障结合 Swift 编译期运行时检查与 Python 全局测试套件，覆盖 M1–M12+ 推导、8 语言一致性与 MMM 功能。"
                    ]),
                stepByStep: trList(lang,
                    de: [
                        "1. Öffne ein Terminal im Repository-Wurzelverzeichnis.",
                        "2. Starte die App mit './scripts/run_ssccc.sh'.",
                        "3. Führe bei Änderungen 'python3 tests/test_global_suite.py' aus, um alle globalen Prüfungen zu verifizieren."
                    ],
                    en: [
                        "1. Open Terminal in the repository root directory.",
                        "2. Launch the app using './scripts/run_ssccc.sh'.",
                        "3. Run 'python3 tests/test_global_suite.py' after edits to verify all global checks pass."
                    ],
                    fr: [
                        "1. Ouvrez le Terminal à la racine du dépôt.",
                        "2. Lancez l'application avec './scripts/run_ssccc.sh'.",
                        "3. Exécutez 'python3 tests/test_global_suite.py' après modification."
                    ],
                    es: [
                        "1. Abre Terminal en la raíz del repositorio.",
                        "2. Inicia la aplicación con './scripts/run_ssccc.sh'.",
                        "3. Ejecuta 'python3 tests/test_global_suite.py' tras cada cambio."
                    ],
                    pt: [
                        "1. Abra o Terminal na raiz do repositório.",
                        "2. Inicie a aplicação com './scripts/run_ssccc.sh'.",
                        "3. Execute 'python3 tests/test_global_suite.py' após alterações."
                    ],
                    ru: [
                        "1. Откройте Терминал в корне репозитория.",
                        "2. Запустите приложение командой './scripts/run_ssccc.sh'.",
                        "3. После правок запустите 'python3 tests/test_global_suite.py'."
                    ],
                    ja: [
                        "1. リポジトリのルートディレクトリでターミナルを開きます。",
                        "2. './scripts/run_ssccc.sh' でアプリを起動します。",
                        "3. 変更後は 'python3 tests/test_global_suite.py' で全テストの成功を確認してください。"
                    ],
                    zh: [
                        "1. 在仓库根目录打开终端。",
                        "2. 运行 './scripts/run_ssccc.sh' 编译并启动桌面端。",
                        "3. 修改代码后运行 'python3 tests/test_global_suite.py' 验证全部检查通过。"
                    ]),
                keyMetrics: [
                    HelpDocMetric(label: L10n.tr(lang, de: "App-Start", en: "App Launch", fr: "Lancement", es: "Inicio", pt: "Arranque", ru: "Запуск", ja: "アプリ起動", zh: "启动脚本"), value: "./scripts/run_ssccc.sh"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Swift-Build", en: "Swift Build", fr: "Build Swift", es: "Compilación", pt: "Build Swift", ru: "Сборка Swift", ja: "Swift ビルド", zh: "Swift 构建"), value: "swift build --package-path app"),
                    HelpDocMetric(label: L10n.tr(lang, de: "Test-Suite", en: "Test Suite", fr: "Suite de tests", es: "Suite de pruebas", pt: "Suite de testes", ru: "Тесты", ja: "テスト", zh: "测试套件"), value: "tests/test_global_suite.py")
                ],
                bestPractices: trList(lang,
                    de: [
                        "Nach jedem Hinzufügen neuer Swift-Dateien prüfen, ob scripts/run_ssccc.sh alle Quellen auflistet (Test 12 prüft dies automatisch).",
                        "Für schnelle Entwicklungsschleifen 'swift build --package-path app' nutzen."
                    ],
                    en: [
                        "Ensure any newly added .swift files are listed in scripts/run_ssccc.sh (enforced by Test 12).",
                        "Use 'swift build --package-path app' for fast incremental compilation."
                    ],
                    fr: [
                        "Ajoutez tout nouveau fichier .swift dans scripts/run_ssccc.sh (vérifié par le Test 12).",
                        "Utilisez 'swift build --package-path app' pour une compilation incrémentale rapide."
                    ],
                    es: [
                        "Asegúrate de listar nuevos archivos .swift en scripts/run_ssccc.sh (verificado por el Test 12).",
                        "Usa 'swift build --package-path app' para compilación incremental rápida."
                    ],
                    pt: [
                        "Inclua novos ficheiros .swift em scripts/run_ssccc.sh (validado pelo Teste 12).",
                        "Use 'swift build --package-path app' para compilação incremental rápida."
                    ],
                    ru: [
                        "Убедитесь, что новые .swift файлы перечислены в scripts/run_ssccc.sh (проверяется Тестом 12).",
                        "Для быстрой сборки используйте 'swift build --package-path app'."
                    ],
                    ja: [
                        "新しい .swift ファイルを追加したら scripts/run_ssccc.sh にも記載してください（Test 12 で自動検証）。",
                        "開発中の高速ビルドには 'swift build --package-path app' が便利です。"
                    ],
                    zh: [
                        "新增 .swift 文件后务必检查 scripts/run_ssccc.sh 是否已纳入列表（Test 12 自动校验）。",
                        "日常开发增量编译可直接运行 'swift build --package-path app'。"
                    ])
            )
        }
    }
}

struct HelpDocImageLoader {
    static func loadImage(named filename: String) -> NSImage? {
        var candidates: [URL] = []
        if let res = Bundle.main.resourceURL {
            candidates.append(res.appendingPathComponent("images").appendingPathComponent(filename))
            candidates.append(res.appendingPathComponent("docs/images").appendingPathComponent(filename))
        }
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        candidates.append(cwd.appendingPathComponent("docs/images").appendingPathComponent(filename))

        // Walk up from app/Sources/Views/HelpDocDeepDiveContent.swift -> repo root -> docs/images
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        candidates.append(repoRoot.appendingPathComponent("docs/images").appendingPathComponent(filename))

        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path),
               let img = NSImage(contentsOf: url) {
                return img
            }
        }
        return nil
    }
}
