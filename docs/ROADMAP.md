# Roadmap: Mac-Cluster-App (Harbor/EXO-Substitut mit RDMA & Hybrid-Netzwerk)

> **Ziel:** Entwicklung einer nativen macOS-Cluster-Anwendung (inspiriert von **EXO** und **Apple/Claris Harbor / Fabric**), die mehrere Apple-Silicon-Macs zu einem gemeinsamen KI-Inferenz-Cluster koppelt — optimiert für heterogene Hardware wie **Mac Studio M5 Max (36 GB, 512 GB SSD, Thunderbolt 5)** + **Mac mini M4 (16 GB, 256 GB SSD, Thunderbolt 4)** mit **52 GB Gesamtspeicher** und flexibler Konnektivität (**Thunderbolt RDMA / TB-Bridge**, **LAN/WLAN** oder **Hybrid-Betrieb**).

---

## 1. Ausgangslage & Technische Realität (Hardware-, Netzwerk- & OS-Analyse)

### 1.1 Ziel-Hardware-Profil
| Eigenschaft | Node A: Mac Studio (Primary) | Node B: Mac mini (Worker) | Gesamt / Verbund |
| :--- | :--- | :--- | :--- |
| **Chip** | Apple M5 Max (18-Core CPU, bis 40-Core GPU) | Apple M4 Base (10-Core CPU, 10-Core GPU) | Heterogen (Max + Base) |
| **Unified Memory** | 36 GB | 16 GB | **52 GB physisch** |
| **Nutzbares MLX/GPU-Limit (Standard ~70–75 %)** | ~25–27 GB | ~11–12 GB | ~36–39 GB |
| **Nutzbares Limit (mit `iogpu.wired_limit_mb` Tuning)** | ~30 GB (6 GB OS-Reserve) | ~12 GB (4 GB OS-Reserve) | **~42 GB effektiv** |
| **Speicherbandbreite** | 460 GB/s | 120 GB/s | Asymmetrisch (3,8:1) |
| **SSD** | 512 GB | 256 GB | 768 GB (Model-Cache) |
| **Thunderbolt-Standard** | **Thunderbolt 5** (bis 120 Gb/s) | **Thunderbolt 4** (bis 40 Gb/s) | Link-Speed max. **40 Gb/s** |
| **Ethernet & WLAN** | **10GbE** RJ-45, **Wi-Fi 7** (N1) | **1GbE** (opt. 10GbE), **Wi-Fi 6E** | Hybrid-Netzwerkfähig |

### 1.2 Kritische Erkenntnis: RDMA über Thunderbolt 5 vs. Thunderbolt 4 (TN3205)
* **Offizieller Apple-Support (macOS 26.2+ / Tahoe, Technical Note TN3205):** Apple unterstützt natives **RDMA over Thunderbolt** (`rdma_ctl enable` in RecoveryOS, `AppleThunderboltRDMA.kext`, MLX `jaccl`-Backend, RDMA Verbs / `ibv_devices`) offiziell **nur zwischen Thunderbolt-5-Ports** (z. B. M4 Pro/Max, M5 Max/Ultra). Die Latenz sinkt dadurch von mehreren hundert Mikrosekunden (TCP/IP) auf **unter 50 µs**.
* **Mac mini M4 (Base):** Besitzt **Thunderbolt 4**. Out-of-the-box blockiert macOS `AppleThunderboltRDMA.kext` auf TB4-Controllern.
* **Drei Transport-Modi für unsere App:**
  1. **Modus A — IP-over-Thunderbolt / TB-Bridge (40 Gb/s, offiziell & sicher):** Kein Recovery/SIP-Eingriff nötig. Realer `iperf3`-Durchsatz auf Apple Silicon liegt bei **30–37 Gbps (~3,7–4,6 GB/s)**. Nutzt TCP/IP über dedizierte Thunderbolt-Interfaces mit MLX `ring`-Backend. Ideal für **Weighted Pipeline Parallelism**.
  2. **Modus B — Experimentelles RDMA auf TB4 (`tb4-rdma-enabler`):** Community-Kext-Workaround (`zhaofengli/tb4-rdma-enabler`), der `AppleThunderboltRDMA` auch auf TB4 freischaltet (40 Gb/s RDMA via `jaccl`). *Erfordert:* `csrutil` / Permissive Security (`bputil`) + `rdma_ctl enable` in RecoveryOS. Wird in der App nur als **optionaler Experten-/Opt-In-Modus** mit klarem DMA-Sicherheitshinweis angeboten.
  3. **Modus C — Hybrid-Netzwerk (LAN/WLAN + Thunderbolt gleichzeitig):**
     * **Control Plane (LAN/WLAN):** mDNS/Bonjour-Discovery, Cluster-Heartbeat, API-Gateway (OpenAI/Ollama), HuggingFace-Downloads & Web-Dashboard.
     * **Data Plane (Thunderbolt bevorzugt, LAN/WLAN als Fallback):** Tensor-/Aktivierungs-Transfers laufen isoliert über Thunderbolt; fällt das TB-Kabel aus oder wird ein WLAN-only-Node ergänzt, schaltet die App automatisch auf LAN/WLAN um.

### 1.3 Kann gleichzeitige LAN/WLAN-Übertragung die 40-Gbps-Thunderbolt-Grenze erhöhen?
Eine zentrale Architekturfrage ist, ob sich Thunderbolt (40 Gbps) + LAN (1GbE / 10GbE) + WLAN bündeln lassen, um die Inferenz-Geschwindigkeit über 40 Gbps hinaus zu steigern:

* **Für LLM-Inferenz (Token-Generierung / Decode): Nein — Bündelung über LAN/WLAN wäre kontraproduktiv.**
  1. **Latenz- vs. Bandbreiten-Regime:** Beim **Decode** (`batch_size=1`) werden pro Token nur winzige Aktivierungs-Tensoren übertragen (~8–16 KB). Dieser Pfad ist **streng latenzlimitiert**, nicht bandbreitenlimitiert. Würde man Pakete via Multipath (MPTCP) oder LACP über Thunderbolt *und* 1GbE/Wi-Fi verteilen, müsste die Pipeline auf das langsamere Paket über LAN/WLAN warten (*Straggler-Effekt*), was die Tokens/s **senkt** statt erhöht.
  2. **macOS-Protokollgrenzen:** macOS Link Aggregation (LACP) erfordert einen Managed Switch und beschleunigt *keine* einzelne TCP-Verbindung (Single-Stream). Systemweites MPTCP existiert auf macOS nur über explizite App-APIs (`connectx()` / `.aggregate`), nicht als transparentes Bandbreiten-Bonding.
  3. **Hardware-Verhältnis:** Selbst mit Standard-1GbE auf dem Mac mini M4 entspräche LAN nur ~2,7 % der realen Thunderbolt-4-Bandbreite (1 Gbps vs. 30–37 Gbps).
* **Was tatsächlich hilft (und in die Roadmap einfließt):**
  1. **Strikte Traffic-Isolation:** LAN/WLAN übernimmt die Control Plane & HuggingFace-Downloads, damit **100 % der Thunderbolt-Leitung** exklusiv und jitterfrei für MLX-Aktivierungen frei bleiben.
  2. **Multi-Cable Thunderbolt (2× TB-Kabel parallel):** Mac mini M4 hat 3× TB4-Ports, Mac Studio M5 Max hat 4× TB5-Ports. Über zwei dedizierte Thunderbolt-Kabel unterstützt **MLX `jaccl`** echtes **Multi-Trunk-Striping** (bis zu 2× 40 Gbps auf TB4-RDMA).
  3. **Paralleler Bulk-Transfer für Modell-Gewichte:** Beim *Kopieren/Synchronisieren* großer Modell-Shards (SSD-zu-SSD) kann ein Multi-Stream-Downloader Chunks parallel über Thunderbolt + 10GbE LAN übertragen (nur sinnvoll, falls der Mini ebenfalls 10GbE hat).

### 1.4 Warum Weighted Pipeline Parallelism (PP) + `MLX_METAL_FAST_SYNCH=1` entscheidend sind
* **Tensor Parallelism (TP / `jaccl`):** Erzwingt symmetrische Shards. Bei 36 GB + 16 GB würde der 16-GB-Mini das Limit vorgeben (~12 GB pro Node = max. **24 GB** nutzbar, 18 GB auf dem Mac Studio blieben brach!).
* **Weighted Pipeline Parallelism (PP / `ring` bzw. `RingMemoryWeightedPartitioning` wie in EXO):** Teilt das Modell **sequenziell nach Layern proportional zum verfügbaren VRAM**:
  * **Mac Studio (36 GB):** ~70–72 % der Layer (nutzt 460 GB/s Speicherbandbreite).
  * **Mac mini (16 GB):** ~28–30 % der Layer.
  * Ergebnis: **~42 GB effektiver Pool** aus 52 GB physischem RAM.
* **Synchronisations-Turbo (`MLX_METAL_FAST_SYNCH=1`):** Reduziert die GPU-zu-CPU/Comm-Synchronisationslatenz in MLX von **~180 µs auf ~4 µs** pro Crossing — ein massiver Hebel für Pipeline- und Tensor-Parallelität bei vielen aufeinanderfolgenden Transformer-Layern.

### 1.5 Learnings aus `github.com/exo-explore/exo` (Referenz-Architektur)
Die Analyse des `exo-explore/exo`-Repositories liefert entscheidende Best Practices für unsere App:
* **P2P-Discovery + Dynamic Master Election:** Exo nutzt einen Rust-basierten Discovery-Layer für das lokale Mesh sowie eine dynamische Master-Wahl (Coordinator) mit State-Reducer und Placement-Engine (`src/exo/master/placement.py`, `placement_utils.py` → `get_shard_assignments_for_pipeline_parallel`).
* **`bridge0`-Falle bei RDMA (`EINVAL / errno 22`):** Laut Exo-Dokumentation & TN3205 stört die standardmäßige macOS-`Thunderbolt Bridge` (`bridge0`) das Aufsetzen von RDMA Queue Pairs (`EINVAL` / `errno 22`). Exo löst dies über ein eigenes Setup-Skript (`set_rdma_network_config.sh`), das `bridge0` deaktiviert und einzelne Thunderbolt-Ports als dedizierte Punkt-zu-Punkt-Services ausgliedert.
* **Dual-Backend-Strategie (`jaccl` vs. `ring`):** Exo nutzt `jaccl` (RDMA) für reine TB5-Meshes und fällt bei gemischten/TB4-Setups (wie **M5 Max + M4**) sauber auf `ring` (TCP/IP über IP-over-Thunderbolt, Ethernet oder WLAN) zurück.
* **UX-Vorbild:** Menüleisten-App + lokales Dashboard (Port `52415`) mit `uv`-gestütztem Python/MLX-Backend (`uv sync --extra mlx`).

### 1.6 Wissenschaftliche Grundlagen (IT-/Systemforschung) & Agenten-Integration
* **Prefill-Decode-Disaggregation (*Splitwise* / *DistServe*, OSDI '24):** Wissenschaftliche Arbeiten zeigen, dass Prefill (compute-bound, bestimmt *TTFT*) und Decode (speicherbandbreiten-bound, bestimmt *TPOT*) gegensätzliche Hardware-Anforderungen haben. Chunked Prefill (`--prefill-step-size 512`) verhindert Speicher-Spikes bei langen Agenten-Prompts.
* **KV-Cache-Quantisierung (`--kv-bits 4/8`, `--quantized-kv-start 5000`):** Reduziert den VRAM-Bedarf langer Kontextfenster (16k–64k+ Tokens für Coding-Agenten) drastisch innerhalb unseres 42-GB-Pools, während die ersten Prefix-Tokens unquantisiert bleiben können.
* **Heterogene Pipeline-Parallelität & *SpecPipe* (arXiv):** Auf Apple Silicon können naiv portierte Speculative-Decoding-Ansätze bei Batch-Size 1 durch Metal-Sync-Overhead bremsen; deshalb sind `MLX_METAL_FAST_SYNCH=1` (~4 µs) und speichergewichtetes Pipeline-Sharding der effektivere Hebel.
* **Agenten-Ökosystem (OpenCode & Hermes Agent):**
  * **OpenCode:** Anbindung über `~/.config/opencode/opencode.json` (`@ai-sdk/openai-compatible`, `baseURL: http://127.0.0.1:8000/v1`) + `~/.local/share/opencode/auth.json`, inklusive `small_model`-Routing.
  * **Hermes Agent (Nous Research):** Anbindung über `~/.hermes/config.yaml` (`provider: custom`, `base_url: http://127.0.0.1:8000/v1`) + `~/.hermes/.env` bzw. `/model custom`.

---

## 2. Produkt-Roadmap (Phasenplan)

### Phase 0: Fundament & Hardware-Validierung (Woche 1)
* **Ziel:** Beide Macs vernetzen, reale Latenzen/Bandbreiten messen und Basis-Benchmarks mit `mlx.distributed` fahren.
* **Meilensteine:**
  * macOS-Version (26.2+) und `iogpu.wired_limit_mb` auf beiden Geräten prüfen.
  * Dedizierte Punkt-zu-Punkt-Thunderbolt-IPs (`10.99.0.1` / `10.99.0.2`) konfigurieren (Service Order priorisieren, um WLAN-Routing zu verhindern!) und mit `iperf3` (Ziel: 30–37 Gbps) sowie `ping` messen.
  * Optionaler Machbarkeitstest von `rdma_ctl` / `ibv_devices` (TB5) und Entscheidung über TB4-RDMA-Opt-In.
  * Erster manueller `mlx_lm.benchmark --pipeline`-Test mit und ohne `MLX_METAL_FAST_SYNCH=1`.

### Phase 1: Core Daemon & Hybrid-Transport-Layer (Woche 2–3)
* **Ziel:** Ein schlanker Hintergrund-Daemon auf jedem Mac, der Hardware-Ressourcen erkennt, Netzwerkpfade misst und Control/Data Plane sauber trennt.
* **Meilensteine:**
  * **Node-Agent (Daemon):** Erfasst RAM, verfügbares Wired-GPU-Limit, Chip-Typ, Thunderbolt-Ports (`system_profiler SPThunderboltDataType`), RDMA-Devices (`ibv_devices` / `ibv_devinfo`) und LAN/WLAN-Interfaces.
  * **Auto-Discovery (Bonjour/mDNS):** Automatische Erkennung aller Cluster-Nodes im LAN/WLAN (`_maccluster._tcp.local.`).
  * **Link-Profiler & Transport-Router:** Rankt Interfaces nach Latenz & Bandbreite (`RDMA > Multi-TB > TB-Bridge > 10GbE > 1GbE > WLAN`), verhindert Routing-Loops bei Multi-Cable-Setups und schaltet bei TB-Ausfall automatisch auf LAN/WLAN um.

### Phase 2: Heterogene Inference-Engine & Memory-Scheduler (Woche 4–5)
* **Ziel:** Modelle automatisch proportional aufteilen (36 GB vs. 16 GB), sodass der 16-GB-Node nie in Swap/OOM läuft.
* **Meilensteine:**
  * **Topology-Aware Memory Planner:** Berechnet aus Modellgröße, Quantisierung (4-bit/8-bit), KV-Cache-Bedarf und `wired_limit_mb` die exakte Layer-Verteilung (~71 % Studio / ~29 % Mini).
  * **MLX-Distributed Runner:** Orchestriert `mlx.launch` mit `ring` (TB-Bridge / LAN / WLAN) oder `jaccl` (RDMA, inkl. 2D-Hostfile-Matrix) und steuert `MLX_METAL_FAST_SYNCH=1` mit Watchdog.
  * **Dynamic `iogpu.wired_limit_mb` Guard:** Sicheres Anheben/Zurücksetzen des GPU-Speicherlimits (`30720` MB / `12288` MB).
  * **Multi-Path Model Sync:** Lädt HuggingFace-Modelle zentral über LAN/WLAN und verteilt benötigte Shards schnellstmöglich über Thunderbolt (oder parallel über TB + 10GbE).

### Phase 3: API-Gateway & Kompatibilität (Woche 6)
* **Ziel:** Der Cluster verhält sich nach außen wie ein lokaler Standard-LLM-Server (wie Ollama / EXO / Harbor).
* **Meilensteine:**
  * **OpenAI-kompatible API** (`/v1/chat/completions`, `/v1/models`, Streaming via SSE).
  * **Ollama-kompatibler Endpunkt** (`/api/chat`, `/api/tags`) für Cursor, Continue, Open WebUI, Xcode/Coding-Tools.
  * **Request-Queue & Concurrency-Control:** Verhindert Parallel-OOMs bei mehreren gleichzeitigen Anfragen.

### Phase 4: Native macOS App (SwiftUI) — "Harbor/EXO"-UI (Woche 7–8)
* **Ziel:** Eine native macOS-Menüleisten- und Dashboard-App zur Steuerung des gesamten Clusters ohne Terminal.
* **Meilensteine:**
  * **Cluster-Topologie-Ansicht:** Live-Visualisierung von Mac Studio & Mac mini, aktiven Links (TB4/TB5, RDMA-Status, LAN, WLAN), Durchsatz & Latenz.
  * **Speicher- & Telemetrie-Monitor:** Live-Auslastung des gekoppelten 52-GB-Pools (pro Node), Memory-Pressure, Prefill- & Decode-Tokens/s.
  * **1-Klick-Modell-Manager:** HuggingFace-MLX-Modelle suchen, Sharding-Plan vorab prüfen ("Passt in 42 GB effektiv") und starten.
  * **Verbindungs-Modi-Schalter:** *Auto (Hybrid: LAN Control + TB Data)*, *Thunderbolt-Only*, *LAN/WLAN-Only* und *RDMA-Setup-Assistent*.

### Phase 5: Stabilität, Benchmarks & Erweiterbarkeit (Woche 9+)
* **Ziel:** Produktionsreife für den Dauerbetrieb und Vorbereitung auf weitere Nodes.
* **Meilensteine:**
  * Automatisierte Benchmark-Suite (Prefill vs. Decode TPS bei 7B, 32B, 70B über TB-Bridge vs. Multi-Cable vs. LAN vs. WLAN vs. RDMA).
  * Graceful Node-Join / Node-Leave (Hot-Reconnect bei Kabelwechsel).
  * LaunchAgent/Daemon-Autostart für Headless-Betrieb des Mac mini M4.
  * Optional: `llama.cpp` RPC-Backend als Alternative für GGUF-Modelle.

---

### Phase 6: Multi-Model-Mode (MMM) & Cross-Cluster-Orchestrierung (10. Seitenmenü-Kategorie)
* **Ziel:** Mehrere Modelle innerhalb des lokalen Clusters, des Internet-Clusters oder eines gekoppelten Hybrid-Verbunds (Lokal + Internet) parallel, als Ensemble (MoA), per Speculative Decoding oder als Pipeline zu einer gemeinsamen Gesamtleistung zusammenführen.
* **Meilensteine:**
  * **10. Menüpunkt `Multi-Model-Mode` in der Studio-Sidebar:** Scrollbare Navigation in allen 8 App-Sprachen (`NavigationTab.multiModelMode`).
  * **Scope- & Strategie-Steuerung:** Umschaltung zwischen *Lokaler Cluster*, *Internet-Cluster* und *Lokal + Internet (Hybrid)* sowie 4 Modi (*Paralleler Multi-Modell-Pool*, *Mixture-of-Agents*, *Speculative Decoding*, *Sequenzielle Modell-Pipeline*).
  * **VRAM-Pool-Schutz & Slot-Zuweisung:** Pro-Modell-Zuweisung auf lokale TB/RDMA-Knoten oder WAN-Peers inkl. `iogpu.wired_limit_mb`-Budgetprüfung.
  * **Echtzeit-SSE-Ausführung & Simulation:** Reale Token/s- und TTFT-Messung über aktive Endpunkte sowie klar gekennzeichnete Simulationsläufe.

---

### Phase 11: 2026 SOTA Architecture Upgrade (Punkte 1–5)
* **Ziel:** Integration moderner 2025/2026er Forschungs- und Industriestandards in alle Cluster-, Modell-, Forschungs- und Agentenbereiche.
* **Meilensteine:**
  * **TB5 RDMA Full-Mesh & QUIC/Iroh WAN:** `ClusterMeshTopology` (Ring vs. Full-Mesh), `rdma_ctl enable` Preflight-Check, `bridge0`-Schutz, `mlx.distributed_config`-Export sowie QUIC/Iroh 0-RTT WAN-Transport.
  * **Disaggregated Prefill/Decode & KV-Cache Tiering:** ANE-Prefill + MLX-Decode Split-Phase, 3-Tier KV-Cache (`RAM -> NVMe -> Peer`) & CacheGen-Kompression.
  * **MMM Next-Gen:** EAGLE-3 Speculative Fusion, Tree-MoA Early-Exit mit Konfidenz-Schwellenwert & Adaptive Confidence Escalation Routing.
  * **Moderne Gateway-Standards:** OpenAI `/v1/responses` + MCP Registry + A2A Agent Card (`/.well-known/agent.json`).
  * **Thermal- & Carbon-Aware Scheduling:** Automatische Drosselung bzw. Umverteilung bei `.serious`/`.critical` Thermal-State und Energieeffizienz-Gewichtung.

---

### Phase 12: Automatisches Verbund-Setup (`Setup / Einrichten`), Betriebsbereitschafts-Prüfung & Programmweite Shorttips
* **Ziel:** 11. Seitenmenü-Kategorie zum automatischen Erkennen, Einrichten und Verifizieren lokaler, Internet-WAN- und hybrider Mac-Verbünde inkl. programmweiter Maus-Hover-Shorttips.
* **Meilensteine:**
  * **Auto-Discovery & Multi-Mac-Einrichtung:** Automatische Erkennung aller beteiligten Macs (Bonjour/mDNS, Thunderbolt/RDMA, Tailscale/QUIC Iroh) und geführte Einrichtung für Lokal-, Internet- und Hybrid-Verbünde.
  * **Betriebsbereitschafts-Prüfung (`ClusterReadinessState`):** Mehrstufige Verifikation mit klarer Zustandsmeldung (*Uneingerichtet*, *Unvollständig eingerichtet*, *Nicht bereit*, *Bereit*).
  * **Programmweite Shorttips / Tooltips (8 Sprachen):** Einheitliche Hover-Kurzerklärungen (`solarisShorttip` + `.help()`) über alle Seitenmenü-Kategorien, Karten und Steuer-Elemente hinweg.

---

### Phase 13: Vollständige 8-Sprachen-Lokalisierung, GPU-/ANE-Kern-Anzeige & 25/25 Test-Suite
* **Ziel:** Lückenlose 8-Sprachen-Übersetzung aller 11 Menüs, Untermenüs, Tabellen, Buttons und Detail-Hilfen auf Basis der deutschen Vorlage sowie vollständige Auslesung/Anzeige lokaler Mac-CPU/GPU/ANE-Kerne.
* **Meilensteine:**
  * **8-Sprachen-Parität (`L10n.tr`):** Entfernung aller verbliebenen `isGerman`-Zweige und festen deutschen Strings; `"Modell Werkstatt"` im deutschen Seitenmenü und ausgeschriebene Layer-Angaben (`ms_layers_unit`).
  * **GPU- & Neural-Engine-(ANE-)Auslesung:** Robuste Erkennung der lokalen GPU- und ANE-Kerne auf Apple-Silicon-Macs und Darstellung auf allen Knotenkarten.
  * **25/25 Globale Test-Suite:** Absicherung über `test_25_eight_language_views_and_gpu_ane_display` in `tests/test_global_suite.py` und Abschnitt 11 in `tests/run_swift_checks.swift`.
