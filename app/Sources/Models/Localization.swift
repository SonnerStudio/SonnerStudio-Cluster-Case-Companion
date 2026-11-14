import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case de = "de"
    case en = "en"
    case fr = "fr"
    case es = "es"
    case pt = "pt"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .de: return "🇩🇪 🇦🇹 🇨🇭 Deutsch"
        case .en: return "🇺🇸 🇬🇧 🇨🇦 English"
        case .fr: return "🇫🇷 🇧🇪 🇨🇭 Français"
        case .es: return "🇪🇸 🇲🇽 🇦🇷 Español"
        case .pt: return "🇵🇹 🇧🇷 Português"
        }
    }

    var badgeCode: String {
        switch self {
        case .de: return "DE"
        case .en: return "EN"
        case .fr: return "FR"
        case .es: return "ES"
        case .pt: return "PT"
        }
    }
}

enum L10n {
    static func tabTitle(_ tab: NavigationTab, _ lang: AppLanguage) -> String {
        switch (tab, lang) {
        case (.overview, .de): return "Verbund-Übersicht"
        case (.overview, .en): return "Cluster Overview"
        case (.overview, .fr): return "Vue de la grappe"
        case (.overview, .es): return "Resumen del conjunto"
        case (.overview, .pt): return "Visão do conjunto"

        case (.devices, .de): return "Geräte & Vergleich"
        case (.devices, .en): return "Devices & Compare"
        case (.devices, .fr): return "Appareils & Comparaison"
        case (.devices, .es): return "Equipos y comparación"
        case (.devices, .pt): return "Dispositivos e comparação"

        case (.models, .de): return "Modell-Werkstatt"
        case (.models, .en): return "Model Studio"
        case (.models, .fr): return "Atelier de modèles"
        case (.models, .es): return "Taller de modelos"
        case (.models, .pt): return "Oficina de modelos"

        case (.network, .de): return "Netzwerk & Direktspeicher"
        case (.network, .en): return "Network & RDMA"
        case (.network, .fr): return "Réseau & Accès direct"
        case (.network, .es): return "Red y acceso directo"
        case (.network, .pt): return "Rede e acesso direto"

        case (.agents, .de): return "Agenten & Umgebungen"
        case (.agents, .en): return "Agents & IDEs"
        case (.agents, .fr): return "Agents & Environnements"
        case (.agents, .es): return "Agentes y entornos"
        case (.agents, .pt): return "Agentes e ambientes"

        case (.science, .de): return "Forschung & Leistung"
        case (.science, .en): return "Science & Roofline"
        case (.science, .fr): return "Recherche & Limites"
        case (.science, .es): return "Ciencia y rendimiento"
        case (.science, .pt): return "Ciência e desempenho"

        case (.console, .de): return "Schnittstelle & Konsole"
        case (.console, .en): return "API & Console"
        case (.console, .fr): return "Interface & Console"
        case (.console, .es): return "Interfaz y consola"
        case (.console, .pt): return "Interface e consola"

        case (.help, .de): return "Hilfe & Handbuch"
        case (.help, .en): return "Help & Documentation"
        case (.help, .fr): return "Aide et guide"
        case (.help, .es): return "Ayuda y manual"
        case (.help, .pt): return "Ajuda e manual"
        }
    }

    static func tabSubtitle(_ tab: NavigationTab, _ lang: AppLanguage) -> String {
        switch (tab, lang) {
        case (.overview, .de): return "Verbund-Speicher & Topologie"
        case (.overview, .en): return "Cluster Pool & Topology"
        case (.overview, .fr): return "Mémoire de grappe & Topologie"
        case (.overview, .es): return "Memoria y topología"
        case (.overview, .pt): return "Memória e topologia"

        case (.devices, .de): return "Einzeldaten & Vergleich"
        case (.devices, .en): return "Hardware & Comparison"
        case (.devices, .fr): return "Données & Comparatif"
        case (.devices, .es): return "Datos y comparativa"
        case (.devices, .pt): return "Dados e comparativa"

        case (.models, .de): return "MLX, oMLX, Ollama & llama.cpp"
        case (.models, .en): return "MLX, oMLX, Ollama & llama.cpp"
        case (.models, .fr): return "MLX, oMLX, Ollama & llama.cpp"
        case (.models, .es): return "MLX, oMLX, Ollama y llama.cpp"
        case (.models, .pt): return "MLX, oMLX, Ollama e llama.cpp"

        case (.network, .de): return "TB3/4/5, Direktspeicher & Hybrid"
        case (.network, .en): return "TB3/4/5, RDMA & Hybrid"
        case (.network, .fr): return "TB3/4/5, Accès direct & Hybride"
        case (.network, .es): return "TB3/4/5, Acceso directo e híbrido"
        case (.network, .pt): return "TB3/4/5, Acesso direto e híbrido"

        case (.agents, .de): return "Lokale Agenten & Werkzeuge"
        case (.agents, .en): return "Local Agents, IDEs & SDKs"
        case (.agents, .fr): return "Agents locaux & Outils"
        case (.agents, .es): return "Agentes locales y entornos"
        case (.agents, .pt): return "Agentes locais e ferramentas"

        case (.science, .de): return "Studien, Aufteilung & Feinabgleich"
        case (.science, .en): return "Papers, Splitwise & Tuning"
        case (.science, .fr): return "Études, Répartition & Réglages"
        case (.science, .es): return "Estudios, reparto y ajuste"
        case (.science, .pt): return "Estudos, partilha e ajuste"

        case (.console, .de): return "OpenAI / Ollama / oMLX Dienst"
        case (.console, .en): return "OpenAI / Ollama / oMLX API"
        case (.console, .fr): return "Service OpenAI / Ollama / oMLX"
        case (.console, .es): return "Servicio OpenAI / Ollama / oMLX"
        case (.console, .pt): return "Serviço OpenAI / Ollama / oMLX"

        case (.help, .de): return "Anleitung & Einrichtung"
        case (.help, .en): return "Manual & Setup Guide"
        case (.help, .fr): return "Manuel et prise en main"
        case (.help, .es): return "Manual y puesta en marcha"
        case (.help, .pt): return "Manual e configuração"
        }
    }

    static func text(_ key: String, _ lang: AppLanguage) -> String {
        switch (key, lang) {
        // Sidebar & Header
        case ("app_subtitle", .de): return "SonnerStudio Verbund-Begleiter"
        case ("app_subtitle", .en): return "SonnerStudio Companion"
        case ("app_subtitle", .fr): return "Compagnon SonnerStudio"
        case ("app_subtitle", .es): return "Asistente SonnerStudio"
        case ("app_subtitle", .pt): return "Assistente SonnerStudio"

        case ("language_label", .de): return "Sprache"
        case ("language_label", .en): return "Language"
        case ("language_label", .fr): return "Langue"
        case ("language_label", .es): return "Idioma"
        case ("language_label", .pt): return "Idioma"

        case ("sim_toggle", .de): return "Mac Studio (Nachbildung)"
        case ("sim_toggle", .en): return "Mac Studio (Sim)"
        case ("sim_toggle", .fr): return "Mac Studio (Simulation)"
        case ("sim_toggle", .es): return "Mac Studio (Simulación)"
        case ("sim_toggle", .pt): return "Mac Studio (Simulação)"

        case ("sim_active_desc", .de): return "36 GB + 16 GB = 52 GB aktiv"
        case ("sim_active_desc", .en): return "36 GB + 16 GB = 52 GB active"
        case ("sim_active_desc", .fr): return "36 Go + 16 Go = 52 Go actifs"
        case ("sim_active_desc", .es): return "36 GB + 16 GB = 52 GB activos"
        case ("sim_active_desc", .pt): return "36 GB + 16 GB = 52 GB ativos"

        case ("sim_single_desc", .de): return "Nur lokaler Mac mini (16 GB)"
        case ("sim_single_desc", .en): return "Local Mac mini only (16 GB)"
        case ("sim_single_desc", .fr): return "Mac mini local uniquement (16 Go)"
        case ("sim_single_desc", .es): return "Solo Mac mini local (16 GB)"
        case ("sim_single_desc", .pt): return "Apenas Mac mini local (16 GB)"

        case ("header_preview", .de): return "Oberflächen-Vorschau · %d GB Speicher"
        case ("header_preview", .en): return "UI Preview · %d GB Pool"
        case ("header_preview", .fr): return "Aperçu · %d Go partagés"
        case ("header_preview", .es): return "Vista previa · %d GB compartidos"
        case ("header_preview", .pt): return "Pré-visualização · %d GB partilhados"

        case ("header_online", .de): return "Dienst aktiv (:8000)"
        case ("header_online", .en): return "Service Online (:8000)"
        case ("header_online", .fr): return "Service actif (:8000)"
        case ("header_online", .es): return "Servicio activo (:8000)"
        case ("header_online", .pt): return "Serviço ativo (:8000)"

        // Overview KPIs
        case ("kpi_memory", .de): return "Gekoppelter Speicher"
        case ("kpi_memory", .en): return "Pooled Memory"
        case ("kpi_memory", .fr): return "Mémoire mutualisée"
        case ("kpi_memory", .es): return "Memoria unificada"
        case ("kpi_memory", .pt): return "Memória acoplada"

        case ("kpi_memory_sub", .de): return "%d GB nutzbare MLX-Grenze"
        case ("kpi_memory_sub", .en): return "%d GB usable MLX limit"
        case ("kpi_memory_sub", .fr): return "%d Go utilisables pour MLX"
        case ("kpi_memory_sub", .es): return "%d GB útiles para MLX"
        case ("kpi_memory_sub", .pt): return "%d GB úteis para MLX"

        case ("kpi_nodes", .de): return "Verbundene Geräte"
        case ("kpi_nodes", .en): return "Active Nodes"
        case ("kpi_nodes", .fr): return "Appareils actifs"
        case ("kpi_nodes", .es): return "Equipos activos"
        case ("kpi_nodes", .pt): return "Dispositivos ativos"

        case ("kpi_link", .de): return "Datenleitung"
        case ("kpi_link", .en): return "Data-Plane Link"
        case ("kpi_link", .fr): return "Liaison de données"
        case ("kpi_link", .es): return "Enlace de datos"
        case ("kpi_link", .pt): return "Ligação de dados"

        case ("topo_title", .de): return "Verbund-Aufbau & Speicherverteilung"
        case ("topo_title", .en): return "Cluster Topology & Memory Pool"
        case ("topo_title", .fr): return "Topologie et répartition mémoire"
        case ("topo_title", .es): return "Topología y reparto de memoria"
        case ("topo_title", .pt): return "Topologia e repartição de memória"

        case ("topo_sub", .de): return "Steuerung über LAN/WLAN · Rechendaten getrennt über Thunderbolt"
        case ("topo_sub", .en): return "Control Plane over LAN/Wi-Fi · Tensors isolated over Thunderbolt"
        case ("topo_sub", .fr): return "Contrôle par LAN/Wi-Fi · Tenseurs isolés par Thunderbolt"
        case ("topo_sub", .es): return "Control por LAN/Wi-Fi · Tensores aislados por Thunderbolt"
        case ("topo_sub", .pt): return "Controlo por LAN/Wi-Fi · Tensores isolados por Thunderbolt"

        case ("pool_bar_title", .de): return "Verbund-Speicheraufteilung (iogpu.wired_limit_mb)"
        case ("pool_bar_title", .en): return "Cluster Memory Allocation (iogpu.wired_limit_mb)"
        case ("pool_bar_title", .fr): return "Répartition mémoire de grappe (iogpu.wired_limit_mb)"
        case ("pool_bar_title", .es): return "Reparto de memoria (iogpu.wired_limit_mb)"
        case ("pool_bar_title", .pt): return "Repartição de memória (iogpu.wired_limit_mb)"

        case ("pool_bar_note", .de): return "Hinweis: Niemals 100 % des Arbeitsspeichers zuweisen — je nach Knoten bleiben 4–8 GB fest für macOS reserviert."
        case ("pool_bar_note", .en): return "Note: Never allocate 100% of RAM — keep 4–8 GB per node reserved for macOS."
        case ("pool_bar_note", .fr): return "Remarque : ne jamais allouer 100 % de la RAM — réserver 4 à 8 Go par nœud pour macOS."
        case ("pool_bar_note", .es): return "Nota: nunca asignar el 100 % de la RAM — reservar 4–8 GB por nodo para macOS."
        case ("pool_bar_note", .pt): return "Nota: nunca alocar 100 % da RAM — reservar 4–8 GB por nó para o macOS."

        // Devices
        case ("dev_title", .de): return "Verbundene Geräte & Gerätedaten"
        case ("dev_title", .en): return "Connected Devices & Hardware Telemetry"
        case ("dev_title", .fr): return "Appareils connectés et télémétrie"
        case ("dev_title", .es): return "Equipos conectados y telemetría"
        case ("dev_title", .pt): return "Dispositivos ligados e telemetria"

        case ("dev_refresh", .de): return "Geräte neu auslesen"
        case ("dev_refresh", .en): return "Refresh Hardware"
        case ("dev_refresh", .fr): return "Actualiser le matériel"
        case ("dev_refresh", .es): return "Actualizar equipos"
        case ("dev_refresh", .pt): return "Atualizar equipamento"

        case ("dev_compare", .de): return "Direktvergleich"
        case ("dev_compare", .en): return "Direct Comparison"
        case ("dev_compare", .fr): return "Comparaison directe"
        case ("dev_compare", .es): return "Comparación directa"
        case ("dev_compare", .pt): return "Comparação direta"

        case ("dev_add_title", .de): return "Weiteren Apple Mac mit M-Prozessor (M1–M9+) hinzufügen"
        case ("dev_add_title", .en): return "Add Any Apple Silicon Mac (M1–M9+) to Cluster"
        case ("dev_add_title", .fr): return "Ajouter un autre Mac à puce M (M1–M9+)"
        case ("dev_add_title", .es): return "Añadir otro Mac con procesador M (M1–M9+)"
        case ("dev_add_title", .pt): return "Adicionar outro Mac com processador M (M1–M9+)"

        case ("dev_add_sub", .de): return "Alle Mac mini, MacBook Air/Pro, iMac, Mac Studio und Mac Pro mit M-Chip lassen sich zu einem Verbund zusammenschalten."
        case ("dev_add_sub", .en): return "Any Mac mini, MacBook Air/Pro, iMac, Mac Studio, or Mac Pro with an M-series chip can join the cluster."
        case ("dev_add_sub", .fr): return "Tout Mac mini, MacBook Air/Pro, iMac, Mac Studio ou Mac Pro à puce M peut rejoindre la grappe."
        case ("dev_add_sub", .es): return "Cualquier Mac mini, MacBook Air/Pro, iMac, Mac Studio o Mac Pro con chip M puede unirse al conjunto."
        case ("dev_add_sub", .pt): return "Qualquer Mac mini, MacBook Air/Pro, iMac, Mac Studio ou Mac Pro com chip M pode integrar o conjunto."

        case ("dev_add_name_ph", .de): return "Eigener Gerätename (freiwillig)"
        case ("dev_add_name_ph", .en): return "Custom device name (optional)"
        case ("dev_add_name_ph", .fr): return "Nom personnalisé (facultatif)"
        case ("dev_add_name_ph", .es): return "Nombre propio (opcional)"
        case ("dev_add_name_ph", .pt): return "Nome personalizado (opcional)"

        case ("dev_add_btn", .de): return "Mac hinzufügen"
        case ("dev_add_btn", .en): return "Add Mac"
        case ("dev_add_btn", .fr): return "Ajouter ce Mac"
        case ("dev_add_btn", .es): return "Añadir Mac"
        case ("dev_add_btn", .pt): return "Adicionar Mac"

        // Help & Documentation
        case ("help_title", .de): return "Ausführliches Handbuch & Dokumentation"
        case ("help_title", .en): return "Comprehensive Help & Documentation"
        case ("help_title", .fr): return "Manuel détaillé et documentation"
        case ("help_title", .es): return "Manual detallado y documentación"
        case ("help_title", .pt): return "Manual detalhado e documentação"

        case ("help_sub", .de): return "Alle Grundlagen zu M1–M9+-Verbünden, Speicherschutz, Thunderbolt, Laufzeiten und KI-Agenten in der gewählten Sprache."
        case ("help_sub", .en): return "Complete guide to M1–M9+ clustering, memory safety, Thunderbolt bridging, runtimes, and AI agents in your selected language."
        case ("help_sub", .fr): return "Guide complet sur les grappes M1–M9+, la sécurité mémoire, Thunderbolt, les moteurs locaux et les agents."
        case ("help_sub", .es): return "Guía completa sobre conjuntos M1–M9+, seguridad de memoria, Thunderbolt, motores locales y agentes."
        case ("help_sub", .pt): return "Guia completo sobre conjuntos M1–M9+, segurança de memória, Thunderbolt, motores locais e agentes."

        case ("help_search_ph", .de): return "Handbuch durchsuchen (z. B. Thunderbolt, oMLX, M1, Reserve)..."
        case ("help_search_ph", .en): return "Search documentation (e.g., Thunderbolt, oMLX, M1, reserve)..."
        case ("help_search_ph", .fr): return "Rechercher dans le manuel (ex. Thunderbolt, oMLX, M1)..."
        case ("help_search_ph", .es): return "Buscar en el manual (ej. Thunderbolt, oMLX, M1)..."
        case ("help_search_ph", .pt): return "Pesquisar no manual (ex. Thunderbolt, oMLX, M1)..."

        // Agents
        case ("agents_title", .de): return "Lokale KI-Agenten & Entwicklungsumgebungen anbinden"
        case ("agents_title", .en): return "Connect Local AI Agents, IDEs & SDKs"
        case ("agents_title", .fr): return "Connecter les agents et environnements locaux"
        case ("agents_title", .es): return "Conectar agentes locales y entornos"
        case ("agents_title", .pt): return "Ligar agentes locais e ambientes"

        case ("agents_sub", .de): return "Verbinde OpenCode, Hermes Agent, Google Antigravity sowie weitere Werkzeuge mit einem Klick mit dem aktiven Mac-Verbund."
        case ("agents_sub", .en): return "Connect OpenCode, Hermes Agent, Google Antigravity, and other local tools to your active Mac cluster in one click."
        case ("agents_sub", .fr): return "Reliez OpenCode, Hermes Agent, Google Antigravity et d'autres outils locaux à votre grappe Mac active en un clic."
        case ("agents_sub", .es): return "Conecta OpenCode, Hermes Agent, Google Antigravity y otras herramientas locales a tu agrupación Mac activa en un clic."
        case ("agents_sub", .pt): return "Ligue o OpenCode, o Hermes Agent, o Google Antigravity e outras ferramentas ao seu agrupamento Mac ativo com um clique."

        // Model Studio
        case ("ms_title", .de): return "Modell-Auswahl & Speicher-Prüfung"
        case ("ms_title", .en): return "Model Selection & Memory Check"
        case ("ms_title", .fr): return "Choix du modèle et contrôle mémoire"
        case ("ms_title", .es): return "Selección de modelo y memoria"
        case ("ms_title", .pt): return "Seleção de modelo e memória"

        case ("ms_sub", .de): return "Wähle ein Modell aus oMLX, Ollama oder llama.cpp — SS-CCC berechnet selbsttätig die anteilige Schichten-Verteilung auf alle aktiven Knoten."
        case ("ms_sub", .en): return "Choose a model from oMLX, Ollama, or llama.cpp — SS-CCC calculates the proportional layer split across all active nodes."
        case ("ms_sub", .fr): return "Choisissez un modèle depuis oMLX, Ollama ou llama.cpp — SS-CCC calcule la répartition des couches sur tous les nœuds actifs."
        case ("ms_sub", .es): return "Elige un modelo de oMLX, Ollama o llama.cpp — SS-CCC calcula el reparto proporcional de capas entre todos los nodos activos."
        case ("ms_sub", .pt): return "Escolha um modelo do oMLX, Ollama ou llama.cpp — o SS-CCC calcula a repartição proporcional de camadas entre todos os nós ativos."

        case ("ms_plan_title", .de): return "Gewichteter Schichten-Aufteilungsplan"
        case ("ms_plan_title", .en): return "Weighted Pipeline Sharding Plan"
        case ("ms_plan_title", .fr): return "Plan de répartition pondérée des couches"
        case ("ms_plan_title", .es): return "Plan de reparto ponderado de capas"
        case ("ms_plan_title", .pt): return "Plano de repartição ponderada de camadas"

        case ("ms_fits", .de): return "Passt in den Verbund"
        case ("ms_fits", .en): return "Fits in Cluster"
        case ("ms_fits", .fr): return "Compatible avec la grappe"
        case ("ms_fits", .es): return "Cabe en el conjunto"
        case ("ms_fits", .pt): return "Cabe no conjunto"

        case ("ms_oom", .de): return "Zu groß (Speicherschutz)"
        case ("ms_oom", .en): return "Too Large (OOM Guard)"
        case ("ms_oom", .fr): return "Trop grand (protection mémoire)"
        case ("ms_oom", .es): return "Demasiado grande (protección)"
        case ("ms_oom", .pt): return "Demasiado grande (proteção)"

        case ("ms_kv_reserve", .de): return "KV-Zwischenspeicher:"
        case ("ms_kv_reserve", .en): return "KV Cache Reserve:"
        case ("ms_kv_reserve", .fr): return "Réserve de cache KV :"
        case ("ms_kv_reserve", .es): return "Reserva de caché KV:"
        case ("ms_kv_reserve", .pt): return "Reserva de cache KV:"

        case ("ms_kv_quant", .de): return "KV-Verdichtung (für lange Agenten-Kontexte)"
        case ("ms_kv_quant", .en): return "KV Cache Quantization (for long agent contexts)"
        case ("ms_kv_quant", .fr): return "Compression du cache KV (longs contextes)"
        case ("ms_kv_quant", .es): return "Compresión de caché KV (contextos largos)"
        case ("ms_kv_quant", .pt): return "Compressão de cache KV (contextos longos)"

        case ("ms_services_title", .de): return "Laufzeit-Dienste: oMLX, Ollama & llama.cpp"
        case ("ms_services_title", .en): return "Runtime Services: oMLX, Ollama & llama.cpp"
        case ("ms_services_title", .fr): return "Moteurs locaux : oMLX, Ollama et llama.cpp"
        case ("ms_services_title", .es): return "Motores locales: oMLX, Ollama y llama.cpp"
        case ("ms_services_title", .pt): return "Motores locais: oMLX, Ollama e llama.cpp"

        case ("ms_services_sub", .de): return "Lade das gewählte Modell unmittelbar in oMLX, Ollama oder llama.cpp — oder binde örtliche Modelle als schnelles MLX in SS-CCC ein."
        case ("ms_services_sub", .en): return "Load the selected model directly into oMLX, Ollama, or llama.cpp — or import local models as fast MLX into SS-CCC."
        case ("ms_services_sub", .fr): return "Chargez le modèle dans oMLX, Ollama ou llama.cpp — ou intégrez des modèles locaux en MLX rapide."
        case ("ms_services_sub", .es): return "Carga el modelo en oMLX, Ollama o llama.cpp — o integra modelos locales como MLX rápido."
        case ("ms_services_sub", .pt): return "Carregue o modelo no oMLX, Ollama ou llama.cpp — ou integre modelos locais como MLX rápido."

        case ("ms_installed", .de): return "EINGERICHTET"
        case ("ms_installed", .en): return "INSTALLED"
        case ("ms_installed", .fr): return "INSTALLÉ"
        case ("ms_installed", .es): return "INSTALADO"
        case ("ms_installed", .pt): return "INSTALADO"

        case ("ms_scan_btn", .de): return "Ollama / GGUF → MLX einlesen"
        case ("ms_scan_btn", .en): return "Scan Ollama / GGUF → MLX"
        case ("ms_scan_btn", .fr): return "Analyser Ollama / GGUF → MLX"
        case ("ms_scan_btn", .es): return "Explorar Ollama / GGUF → MLX"
        case ("ms_scan_btn", .pt): return "Analisar Ollama / GGUF → MLX"

        case ("ms_export_btn", .de): return "Brücke ausgeben"
        case ("ms_export_btn", .en): return "Export Bridge"
        case ("ms_export_btn", .fr): return "Exporter la passerelle"
        case ("ms_export_btn", .es): return "Exportar pasarela"
        case ("ms_export_btn", .pt): return "Exportar ponte"

        // Network & RDMA
        case ("net_title", .de): return "Übertragungs-Verfahren (LAN/WLAN + Thunderbolt)"
        case ("net_title", .en): return "Transport Mode (Hybrid LAN/Wi-Fi + Thunderbolt)"
        case ("net_title", .fr): return "Mode de transport (LAN/Wi-Fi + Thunderbolt)"
        case ("net_title", .es): return "Modo de transporte (LAN/Wi-Fi + Thunderbolt)"
        case ("net_title", .pt): return "Modo de transporte (LAN/Wi-Fi + Thunderbolt)"

        case ("net_sub", .de): return "Wähle, wie Aktivierungs-Felder zwischen M1–M9+-Macs (Thunderbolt 3, 4 und 5) übertragen werden."
        case ("net_sub", .en): return "Choose how activation tensors are transferred across M1–M9+ Macs (Thunderbolt 3, 4, and 5)."
        case ("net_sub", .fr): return "Choisissez le mode de transfert entre Mac M1–M9+ (Thunderbolt 3, 4 et 5)."
        case ("net_sub", .es): return "Elige cómo se transfieren los tensores entre Mac M1–M9+ (Thunderbolt 3, 4 y 5)."
        case ("net_sub", .pt): return "Escolha como os tensores circulam entre Mac M1–M9+ (Thunderbolt 3, 4 e 5)."

        case ("net_fast_synch", .de): return "MLX_METAL_FAST_SYNCH=1 einschalten"
        case ("net_fast_synch", .en): return "Enable MLX_METAL_FAST_SYNCH=1"
        case ("net_fast_synch", .fr): return "Activer MLX_METAL_FAST_SYNCH=1"
        case ("net_fast_synch", .es): return "Activar MLX_METAL_FAST_SYNCH=1"
        case ("net_fast_synch", .pt): return "Ativar MLX_METAL_FAST_SYNCH=1"

        case ("net_fast_synch_sub", .de): return "Senkt die GPU/CPU-Abstimmungszeit von ~180 µs auf ~4 µs (45× schneller bei Schichten-Übergängen)."
        case ("net_fast_synch_sub", .en): return "Reduces GPU/CPU synchronization overhead from ~180 µs to ~4 µs (45× faster across pipeline stages)."
        case ("net_fast_synch_sub", .fr): return "Réduit le temps de synchronisation GPU/CPU de ~180 µs à ~4 µs (45× plus rapide)."
        case ("net_fast_synch_sub", .es): return "Reduce la espera GPU/CPU de ~180 µs a ~4 µs (45× más rápido entre etapas)."
        case ("net_fast_synch_sub", .pt): return "Reduz a sincronização GPU/CPU de ~180 µs para ~4 µs (45× mais rápida)."

        case ("net_checklist", .de): return "Prüfliste für den Aufbau eines Thunderbolt-Verbunds:"
        case ("net_checklist", .en): return "Checklist for setting up a Thunderbolt cluster:"
        case ("net_checklist", .fr): return "Liste de contrôle pour monter une grappe Thunderbolt :"
        case ("net_checklist", .es): return "Lista de verificación para configurar una agrupación Thunderbolt:"
        case ("net_checklist", .pt): return "Lista de verificação para configurar um agrupamento Thunderbolt:"

        // Science & Benchmarks
        case ("sci_title", .de): return "Wissenschaftliche Grundlagen & Leistungs-Grenzkurve"
        case ("sci_title", .en): return "Scientific Foundations & Roofline Analysis"
        case ("sci_title", .fr): return "Bases scientifiques et courbe de rendement"
        case ("sci_title", .es): return "Bases científicas y análisis Roofline"
        case ("sci_title", .pt): return "Bases científicas e análise Roofline"

        case ("sci_sub", .de): return "Analytische Leistungs-Grenzkurven (Williams et al.), Phasen-Zerlegung (Splitwise / DistServe), Energiebilanz (J/Token) und reproduzierbare Messreihen (p50/p95/p99) für den aktiven Apple-Silicon-Verbund."
        case ("sci_sub", .en): return "Analytical Roofline modeling (Williams et al.), phase disaggregation (Splitwise / DistServe), energetics (J/token), and reproducible trials (p50/p95/p99) for your active Apple Silicon cluster."
        case ("sci_sub", .fr): return "Modélisation analytique des limites (Williams et al.), séparation des phases (Splitwise / DistServe), bilan énergétique (J/jeton) et essais reproductibles (p50/p95/p99) pour la grappe Apple Silicon active."
        case ("sci_sub", .es): return "Modelado analítico de límites (Williams et al.), separación de fases (Splitwise / DistServe), balance energético (J/token) y ensayos reproducibles (p50/p95/p99) para la agrupación Apple Silicon activa."
        case ("sci_sub", .pt): return "Modelagem analítica de limites (Williams et al.), separação de fases (Splitwise / DistServe), balanço energético (J/token) e ensaios reprodutíveis (p50/p95/p99) para o agrupamento Apple Silicon ativo."

        case ("sci_roofline", .de): return "Knoten-Vergleich: Rechenleistung, Speicherbandbreite & Knickpunkt (Ridge Point)"
        case ("sci_roofline", .en): return "Node Comparison: Compute, Memory Bandwidth & Ridge Point"
        case ("sci_roofline", .fr): return "Comparaison des nœuds : calcul, débit mémoire et point d'inflexion"
        case ("sci_roofline", .es): return "Comparación de nodos: cómputo, ancho de banda y punto de inflexión"
        case ("sci_roofline", .pt): return "Comparação de nós: cálculo, largura de banda e ponto de inflexão"

        case ("sci_workload_title", .de): return "Interaktives Lastprofil & Leistungs-Grenzkurve (Log-Log Roofline)"
        case ("sci_workload_title", .en): return "Interactive Workload & Log-Log Roofline Model"
        case ("sci_workload_title", .fr): return "Profil de charge interactif et courbe de rendement (log-log)"
        case ("sci_workload_title", .es): return "Perfil de carga interactivo y curva de rendimiento (log-log)"
        case ("sci_workload_title", .pt): return "Perfil de carga interativo e curva de rendimento (log-log)"

        case ("sci_metrics_title", .de): return "Phasen-Latenz (TTFT / TPOT), Verbund-Wirkungsgrad & Energiebilanz"
        case ("sci_metrics_title", .en): return "Phase Latency (TTFT / TPOT), Pipeline Efficiency & Energetics"
        case ("sci_metrics_title", .fr): return "Latence par phase (TTFT / TPOT), rendement et bilan énergétique"
        case ("sci_metrics_title", .es): return "Latencia por fase (TTFT / TPOT), eficiencia y balance energético"
        case ("sci_metrics_title", .pt): return "Latência por fase (TTFT / TPOT), eficiência e balanço energético"

        case ("sci_bench_title", .de): return "Reproduzierbare Messreihe & Statistische Auswertung (Aufwärmlauf + 5 Messläufe)"
        case ("sci_bench_title", .en): return "Reproducible Benchmark & Statistical Evaluation (1 Warmup + 5 Trials)"
        case ("sci_bench_title", .fr): return "Série de mesures reproductible et statistique (1 chauffe + 5 essais)"
        case ("sci_bench_title", .es): return "Serie de medición reproducible y estadística (1 calentamiento + 5 ensayos)"
        case ("sci_bench_title", .pt): return "Série de medição reprodutível e estatística (1 aquecimento + 5 ensaios)"

        case ("sci_bench_run", .de): return "Messreihe starten (T=0,0)"
        case ("sci_bench_run", .en): return "Run Trials (T=0.0)"
        case ("sci_bench_run", .fr): return "Lancer les essais (T=0,0)"
        case ("sci_bench_run", .es): return "Iniciar ensayos (T=0,0)"
        case ("sci_bench_run", .pt): return "Iniciar ensaios (T=0,0)"

        case ("sci_bench_running", .de): return "Aufwärmlauf verworfen · Messläufe laufen..."
        case ("sci_bench_running", .en): return "Warmup discarded · Running measured trials..."
        case ("sci_bench_running", .fr): return "Chauffe écartée · Mesures en cours..."
        case ("sci_bench_running", .es): return "Calentamiento descartado · Ejecutando ensayos..."
        case ("sci_bench_running", .pt): return "Aquecimento descartado · A executar ensaios..."

        case ("sci_bench_done", .de): return "Messreihe abgeschlossen · bereit für CSV-, JSON- oder BibTeX-Ausgabe."
        case ("sci_bench_done", .en): return "Trials complete · ready for CSV, JSON, or BibTeX export."
        case ("sci_bench_done", .fr): return "Essais terminés · prêt pour exportation CSV, JSON ou BibTeX."
        case ("sci_bench_done", .es): return "Ensayos completados · listo para exportar CSV, JSON o BibTeX."
        case ("sci_bench_done", .pt): return "Ensaios concluídos · pronto para exportar CSV, JSON ou BibTeX."

        case ("sci_papers_title", .de): return "Begutachtete Fachliteratur & Methodische Grundlagen"
        case ("sci_papers_title", .en): return "Peer-Reviewed Literature & Methodological Foundations"
        case ("sci_papers_title", .fr): return "Littérature scientifique évaluée et bases méthodologiques"
        case ("sci_papers_title", .es): return "Literatura científica revisada por pares y bases metodológicas"
        case ("sci_papers_title", .pt): return "Literatura científica revista por pares e bases metodológicas"

        case ("sci_prop", .de): return "Eigenschaft"
        case ("sci_prop", .en): return "Property"
        case ("sci_prop", .fr): return "Caractéristique"
        case ("sci_prop", .es): return "Propiedad"
        case ("sci_prop", .pt): return "Propriedade"

        case ("sci_bw", .de): return "Speicherdurchsatz (Ausgabe-Grenze)"
        case ("sci_bw", .en): return "Memory Bandwidth (Decode Limit)"
        case ("sci_bw", .fr): return "Débit mémoire (limite de génération)"
        case ("sci_bw", .es): return "Ancho de banda de memoria"
        case ("sci_bw", .pt): return "Largura de banda de memória"

        case ("sci_layers", .de): return "Bester Schichten-Anteil"
        case ("sci_layers", .en): return "Optimal Layer Share"
        case ("sci_layers", .fr): return "Part optimale des couches"
        case ("sci_layers", .es): return "Reparto óptimo de capas"
        case ("sci_layers", .pt): return "Repartição ótima de camadas"

        case ("sci_link", .de): return "Datenweg-Durchsatz (TB4/5-Brücke)"
        case ("sci_link", .en): return "Data-Plane Throughput (TB4/5 Bridge)"
        case ("sci_link", .fr): return "Débit de données (pont TB4/5)"
        case ("sci_link", .es): return "Rendimiento de datos (puente TB4/5)"
        case ("sci_link", .pt): return "Débito de dados (ponte TB4/5)"

        // API & Console
        case ("api_openai", .de): return "OpenAI-verträglicher Endpunkt"
        case ("api_openai", .en): return "OpenAI-Compatible Endpoint"
        case ("api_openai", .fr): return "Point d'accès compatible OpenAI"
        case ("api_openai", .es): return "Punto de acceso compatible OpenAI"
        case ("api_openai", .pt): return "Ponto de acesso compatível OpenAI"

        case ("api_ollama", .de): return "Ollama-verträglicher Endpunkt"
        case ("api_ollama", .en): return "Ollama-Compatible Endpoint"
        case ("api_ollama", .fr): return "Point d'accès compatible Ollama"
        case ("api_ollama", .es): return "Punto de acceso compatible Ollama"
        case ("api_ollama", .pt): return "Ponto de acesso compatível Ollama"

        case ("api_console", .de): return "Verbund-Prüfkonsole"
        case ("api_console", .en): return "Cluster Test Console"
        case ("api_console", .fr): return "Console de test de la grappe"
        case ("api_console", .es): return "Consola de pruebas del conjunto"
        case ("api_console", .pt): return "Consola de testes do conjunto"

        case ("api_send", .de): return "Prüf-Anfrage ausführen"
        case ("api_send", .en): return "Run Test Request"
        case ("api_send", .fr): return "Lancer la requête de test"
        case ("api_send", .es): return "Ejecutar prueba"
        case ("api_send", .pt): return "Executar teste"

        case ("api_sending", .de): return "Sende..."
        case ("api_sending", .en): return "Sending..."
        case ("api_sending", .fr): return "Envoi..."
        case ("api_sending", .es): return "Enviando..."
        case ("api_sending", .pt): return "A enviar..."

        case ("api_health", .de): return "Dienst prüfen"
        case ("api_health", .en): return "Check Daemon"
        case ("api_health", .fr): return "Vérifier le service"
        case ("api_health", .es): return "Comprobar servicio"
        case ("api_health", .pt): return "Verificar serviço"

        case ("api_output", .de): return "Antwort / Messwerte:"
        case ("api_output", .en): return "Response / Telemetry:"
        case ("api_output", .fr): return "Réponse / mesures :"
        case ("api_output", .es): return "Respuesta / telemetría:"
        case ("api_output", .pt): return "Resposta / telemetria:"

        default: return key
        }
    }
}
