# Implementation Plan: Mac-Cluster-App (MLX + Thunderbolt/RDMA + Hybrid-Netzwerk)

Dieses Dokument beschreibt die konkrete technische Architektur, den Tech-Stack, die Schnittstellen und die schrittweise Implementierung für den Verbund aus **Mac Studio M5 Max (36 GB, TB5, 10GbE, Wi-Fi 7)** und **Mac mini M4 (16 GB, TB4, 1GbE, Wi-Fi 6E)**.

---

## 1. Systemarchitektur (Control Plane vs. Data Plane)

Um **LAN/WLAN** und **Thunderbolt** (bzw. **RDMA**) gleichzeitig optimal zu nutzen, trennt die Architektur strikt zwischen **Control Plane** und **Data Plane**. Das verhindert, dass Management-Traffic oder langsame WLAN-Pakete die latenzkritische Tensor-Pipeline ausbremsen:

```text
+-------------------------------------------------------------------+
|                   macOS Native App (SwiftUI)                      |
|  [Topologie-UI]  [52GB Memory-Pool]  [Model-Hub]  [Settings]      |
+---------------------------------+---------------------------------+
                                  | Local IPC / HTTP
+---------------------------------v---------------------------------+
|                Cluster Coordinator (Python / FastAPI)             |
|  - OpenAI / Ollama API Gateway (:11434 / :8000)                   |
|  - Bonjour / mDNS Discovery (_maccluster._tcp)                    |
|  - Topology-Aware Layer Scheduler (Weighted PP / TP)              |
+----------------+---------------------------------+----------------+
                 | Control Plane (LAN/WLAN)        | Data Plane
                 | Heartbeat, Metrics, API, HF-DL  | (TB-Bridge / RDMA / Fallback)
+----------------v----------------+ +--------------v----------------+
|   Node A: Mac Studio M5 Max     | |   Node B: Mac mini M4         |
|   - 36 GB RAM (~30 GB Wired)    | |   - 16 GB RAM (~12 GB Wired)  |
|   - 460 GB/s Bandbreite         | |   - 120 GB/s Bandbreite       |
|   - ~71% Modell-Layer           | |   - ~29% Modell-Layer         |
|   - MLX Worker (Rank 0)         | |   - MLX Worker (Rank 1)       |
+---------------------------------+ +-------------------------------+
```

---

## 2. Tech-Stack

| Komponente | Technologie | Begründung |
| :--- | :--- | :--- |
| **Inference & Distributed** | Python 3.12+, `mlx`, `mlx-lm`, `mlx.distributed` | Native Apple-Silicon-GPU/UMA-Nutzung, eingebaute Backends `ring` (TCP/IP / RDMA-Ring) und `jaccl` (RDMA-Mesh), `--pipeline`-Support. |
| **Node-Daemon & API** | `FastAPI` + `uvicorn` + `zeroconf` + `psutil` | Schnelle asynchrone Steuerung, mDNS-Discovery, OpenAI-kompatibles SSE-Streaming. |
| **Netzwerk & Transport** | Punkt-zu-Punkt TB-Interfaces (`enX` / `bridge0`), RDMA (`ibv_devices` / `rdma_ctl`), LAN/WLAN | Isoliertes Routing: Thunderbolt exklusiv für Aktivierungen, LAN/WLAN für Control Plane & Fallback. |
| **Desktop-UI** | **Swift / SwiftUI** (macOS 15/26+ Native App) | Native Menüleisten-Integration, `NWBrowser` (Bonjour), `Process`-Management für den Python-Daemon, System-Telemetrie. |
| **Paketmanagement** | `uv` (Python) + Xcode / SwiftPM | Identische, reproduzierbare Python-Umgebung auf beiden Macs ohne globale Konflikte. |

---

## 3. Repository- & Modulstruktur

```text
Harbor-Substitut/
├── docs/
│   ├── ROADMAP.md
│   └── IMPLEMENTATION_PLAN.md
├── core/                          # Python Cluster & Inference Engine
│   ├── pyproject.toml             # uv / Dependencies (mlx, mlx-lm, fastapi, zeroconf)
│   ├── daemon/
│   │   ├── node_agent.py          # Hardware-Probing, Memory-Guard, Heartbeat
│   │   ├── discovery.py           # mDNS/Bonjour (_maccluster._tcp) + IP-Mapping
│   │   ├── network_profiler.py    # Interface-Ranking (RDMA > Multi-TB > TB > LAN > WLAN)
│   │   └── wired_memory.py        # sysctl iogpu.wired_limit_mb Manager
│   ├── scheduler/
│   │   ├── planner.py             # Weighted Pipeline Partitioning (36GB vs 16GB)
│   │   └── model_sync.py          # HuggingFace Download & Multi-Path Shard-Sync
│   ├── engine/
│   │   ├── mlx_runner.py          # Wrapper für mlx.launch (ring / jaccl + FAST_SYNCH)
│   │   └── pipeline_model.py      # Asymmetrisches Layer-Sharding für MLX-LM
│   └── api/
│       └── gateway.py             # OpenAI (/v1/chat/completions) & Ollama API
├── app/                           # Native macOS SwiftUI App
│   ├── MacClusterApp.xcodeproj
│   └── Sources/
│       ├── ClusterManager.swift   # Daemon Lifecycle & IPC
│       ├── NetworkMonitor.swift   # Live TB/LAN/WLAN/RDMA Status
│       └── Views/                 # Dashboard, TopologyView, ModelLibraryView
└── scripts/
    ├── setup_tb_network.sh        # Dedizierte TB-IPs & Service-Order-Check
    ├── check_rdma.sh              # Prüft rdma_ctl & ibv_devices / ibv_devinfo
    └── benchmark_cluster.py       # Prefill/Decode TPS & Latenz-Benchmarks
```

---

## 4. Detail-Implementierung der Kernmodule

### 4.1 Netzwerk- & Transport-Layer (`network_profiler.py` & `setup_tb_network.sh`)
Um die volle Thunderbolt-Geschwindigkeit (**30–37 Gbps real auf TB4**) zuverlässig abzurufen und Routing-Fallen auf macOS zu vermeiden:

1. **Dedizierte Thunderbolt-IPs & Service Order (Standard für M5 Max ↔ M4):**
   * **Problem auf macOS:** Nutzt man Hostnamen (`.local`), löst mDNS diese oft auf die **WLAN-IP** statt auf Thunderbolt auf — der Durchsatz bricht dann auf ~30–40 MB/s ein. Außerdem fasst macOS alle TB-Ports in eine einzige `bridge0` zusammen, was bei mehreren Kabeln zu Routing-Loops führt und bei RDMA (`jaccl`) den Fehler **`EINVAL` / `errno 22`** beim Queue-Pair-Aufbau auslöst (bekannt aus `exo-explore/exo` / TN3205).
   * **Lösung (analog Exos `set_rdma_network_config.sh`):**
     * Für RDMA (`jaccl`) oder Multi-Cable-Setups wird `bridge0` deaktiviert; einzelne Thunderbolt-Ports (`Thunderbolt 1`, `Thunderbolt 2`, … bzw. `enX`) werden als getrennte Punkt-zu-Punkt-Interfaces mit eigenen Subnets konfiguriert (z. B. Kabel 1: `10.99.1.1/24` ↔ `10.99.1.2/24`; Kabel 2: `10.99.2.1/24` ↔ `10.99.2.2/24`).
     * Für den einfachen Single-Cable-TCP-Betrieb (`ring` zwischen M5 Max & M4) reicht auch die klassische Thunderbolt-Bridge mit festen IPs, sofern `.local`-Hostnamen gemieden werden.
     * `mlx.launch` und die Hostfiles referenzieren **ausschließlich diese numerischen TB-IPs**, niemals `.local`-Hostnamen.
     * In den macOS-Netzwerkeinstellungen wird Thunderbolt in der *Service Order* über WLAN/LAN priorisiert.
2. **RDMA-Erkennung (`check_rdma.sh`) & `jaccl`-Hostfile:**
   * Prüft via `ibv_devices` / `ibv_devinfo`, ob aktive `rdma_en*`-Interfaces vorliegen (`rdma_ctl enable` in RecoveryOS).
   * Sind auf **allen** Nodes RDMA-Devices aktiv (z. B. mit einem zweiten TB5-Mac oder via `tb4-rdma-enabler`), generiert der Profiler automatisch eine 2D-JACCL-Matrix (`hosts.json`):
     ```json
     {
       "backend": "jaccl",
       "hosts": [
         {"ssh": "10.99.1.1", "ips": ["10.99.1.1"], "rdma": [null, "rdma_en5"]},
         {"ssh": "10.99.1.2", "ips": ["10.99.1.2"], "rdma": ["rdma_en5", null]}
       ]
     }
     ```
   * Bei **2 Thunderbolt-Kabeln** zwischen beiden Macs nutzt `jaccl` Multi-Trunk-Striping über beide `rdma_en*`-Devices parallel.
3. **Warum kein Packet-Bonding über TB + LAN/WLAN für Inferenz?**
   * **Decode-Phase (`bs=1`):** Aktivierungen sind nur ~8–16 KB groß (latenzlimitiert). Gleichzeitiges Senden über 1GbE/WLAN würde durch *Straggler-Pakete* die Latenz massiv verschlechtern.
   * **Stattdessen:** Strikte Trennung — **LAN/WLAN** trägt Control Plane + API + HuggingFace-Downloads, **Thunderbolt** trägt exklusiv den Tensor-Traffic. Nur beim *Kopieren großer Modell-Dateien* (Shard-Sync) darf `model_sync.py` optional parallele Streams über TB + 10GbE LAN nutzen.
   * **Auto-Fallback:** Ist kein TB-Link erreichbar, fällt `network_profiler.py` automatisch in der Reihenfolge `RDMA > TB-Bridge > 10GbE LAN > 1GbE LAN > WLAN` auf die nächste aktive Data-Plane-IP zurück.

### 4.2 Speicher-Management & Heterogenes Sharding (`wired_memory.py` & `planner.py`)
Um aus **36 GB + 16 GB = 52 GB** das Maximum stabil herauszuholen:

1. **Sicherheits-Budget pro Node:**
   * **Mac Studio (36 GB):** OS-Reserve = `6 GB` → max. nutzbar für MLX = **`30 GB`** (`sudo sysctl -w iogpu.wired_limit_mb=30720`).
   * **Mac mini (16 GB):** OS-Reserve = `4 GB` → max. nutzbar für MLX = **`12 GB`** (`sudo sysctl -w iogpu.wired_limit_mb=12288`).
   * **Gesamter nutzbarer Cluster-VRAM:** **`42 GB`**.
2. **Proportionale Layer-Zuweisung (`planner.py`, analog EXOs `RingMemoryWeightedPartitioningStrategy`):**
   * Eingabe: Anzahl Transformer-Layer $L$ des Modells (z. B. $L = 80$ bei Llama-3-70B), Gewicht pro Layer + KV-Cache-Reserve.
   * Berechnung des Gewichts-Anteils:
     $$\text{Anteil}_{\text{Studio}} = \frac{30}{30 + 12} \approx 71{,}4\% \quad (\approx 57 \text{ Layer})$$
     $$\text{Anteil}_{\text{Mini}} = \frac{12}{30 + 12} \approx 28{,}6\% \quad (\approx 23 \text{ Layer})$$
   * **Embeddings & LM-Head:** Werden auf **Node A (Mac Studio)** platziert (460 GB/s Bandbreite + direkter API-Output).

### 4.3 MLX Distributed Runner & Latenz-Optimierung (`mlx_runner.py`)
* **Backend-Auswahl:**
  * Standard für M5 Max + M4: `ring` (TCP/IP über Thunderbolt-IPs `10.99.1.1`, `10.99.1.2`) mit `--pipeline`.
  * Optional (bei aktivem RDMA auf beiden Nodes): `jaccl` (mit `--pipeline` für heterogene 36/16-GB-Aufteilung oder Tensor-Parallelism bei homogenen Nodes).
* **Synchronisations-Beschleunigung (`MLX_METAL_FAST_SYNCH=1`):**
  * Wird standardmäßig als Umgebungsvariable übergeben (`mlx.launch --env MLX_METAL_FAST_SYNCH=1`), um GPU-zu-CPU-Fence-Overhead von **~180 µs auf ~4 µs** zu senken.
  * *Watchdog-Schutz:* Da `MLX_METAL_FAST_SYNCH=1` aktives GPU-Spin-Polling nutzt, überwacht `node_agent.py` den Worker-Heartbeat; bei einem Hang erfolgt ein automatischer Restart ohne das Flag als Fallback.

### 4.4 API-Gateway & Agenten-Integration (`gateway.py`, OpenCode & Hermes Agent)
* Stellt auf dem Mac Studio einen lokalen HTTP-Server bereit:
  * `GET /v1/models` — listet geladene & verfügbare Cluster-Modelle.
  * `POST /v1/chat/completions` — OpenAI-kompatibel mit `stream: true` (SSE) inkl. Tool-Calling-Durchreichung für Coding-Agenten.
  * `POST /api/chat` & `GET /api/tags` — Ollama-kompatibel für bestehende Desktop-Clients.
* **KV-Cache-Optimierung für lange Agenten-Kontexte:** Unterstützt `--kv-bits 4|8`, `--kv-group-size 64`, `--quantized-kv-start 5000` und `--prefill-step-size 512` (basierend auf Erkenntnissen aus *Splitwise/DistServe* zu Prefill-Speicherspitzen).
* **1-Klick-Export in der SwiftUI-App (`AgentIntegrationsView`):**
  * **OpenCode:** Generiert `~/.config/opencode/opencode.json` (inkl. `model` auf 52-GB-Cluster und optionalem `small_model`) sowie `~/.local/share/opencode/auth.json`.
  * **Hermes Agent (Nous Research):** Generiert `~/.hermes/config.yaml` (`provider: custom`, `base_url: http://127.0.0.1:8000/v1`) und `~/.hermes/.env`.
* Bindet an `0.0.0.0` (über LAN/WLAN im Heimnetz erreichbar) oder `127.0.0.1`, sodass Clients im WLAN den Cluster ansprechen können, während die Inferenz-Kommunikation intern über Thunderbolt läuft.

---

## 5. Konkrete Erste Schritte (Umsetzungs-Checkliste)

1. **System-Setup auf beiden Macs:**
   * `uv` installieren, identische Python-3.12-Umgebung mit `mlx` und `mlx-lm` auf Mac Studio M5 Max und Mac mini M4 anlegen.
   * Passwortloses SSH zwischen beiden Macs einrichten (Voraussetzung für `mlx.launch`).
2. **Thunderbolt-Netzwerk konfigurieren & vermessen:**
   * Zertifiziertes Thunderbolt-4/5-Kabel verbinden, feste Punkt-zu-Punkt-IPs (`10.99.1.1` / `10.99.1.2`) setzen.
   * Durchsatz & Latenz mit `iperf3 -c 10.99.1.1` (Ziel: 30–37 Gbps) und `ping` verifizieren.
3. **Minimaler Proof-of-Concept (Phase 0/1):**
   * `mlx_lm.benchmark` mit Pipeline-Parallelität (`--pipeline`) und `MLX_METAL_FAST_SYNCH=1` über Thunderbolt vs. LAN/WLAN vergleichen (Prefill- vs. Decode-TPS).
4. **Daemon, API & SwiftUI-App schrittweise aufbauen:**
   * Nach erfolgreichem PoC folgen `node_agent.py` (mDNS + `iogpu.wired_limit_mb` Guard), `planner.py` (71/29-Sharding), `gateway.py` (OpenAI/Ollama API) und die SwiftUI-Oberfläche.

---

## 6. Sicherheits- & Stabilitäts-Hinweise
* **`iogpu.wired_limit_mb`:** Niemals auf 100 % des physischen RAM setzen; mindestens 4 GB (Mini) bzw. 6 GB (Studio) für macOS reservieren.
* **RDMA auf Thunderbolt 4:** Falls das experimentelle `tb4-rdma-enabler`-Verfahren getestet wird, ist zu beachten, dass das Deaktivieren von SIP (`csrutil`) und das Setzen auf *Permissive Security* (`bputil`) die DMA-Angriffsfläche des Mac mini erhöht. Für den produktiven Alltag bleibt **IP-over-Thunderbolt (30–37 Gbps)** der sichere Standard.

---

## 7. Multi-Model-Mode (MMM) — Architektur & Implementierungsplan

### 7.1 Zielsetzung & Einordnung im Gesamtkonzept
Der **Multi-Model-Mode (MMM)** ergänzt SS-CCC als **10. Kategorie im linken Seitenmenü** (`NavigationTab.multiModelMode`) und verknüpft bestehende Bausteine (Modell-Werkstatt, Netzwerk & RDMA, Internet-Verbund) zu einer gemeinsamen Multi-Modell-Orchestrierung über drei Cluster-Bereiche (`MultiModelScope`):
1. **Lokaler Cluster:** Verteilt spezialisierte Modelle auf lokale Thunderbolt-/RDMA-Macs mit minimaler Latenz.
2. **Internet-Cluster:** Nutzt weltweite Tailscale-, WireGuard- oder libp2p-QUIC-Peers für große VRAM-Pools.
3. **Lokal + Internet (Hybrid):** Koppelt lokale Schnell-Modelle (z. B. Draft/Router auf Mac mini/Studio) mit großen Remote-Target- oder Spezialisten-Modellen im Internet-Verbund.

### 7.2 Unterstützte Orchestrierungs-Strategien (`MultiModelStrategy`)
* **Paralleler Multi-Modell-Pool:** Hält mehrere Modelle gleichzeitig in getrennten VRAM-Budgets (`usableVramGB` mit `iogpu.wired_limit_mb`-Schutz) für parallele Anfragen ohne Reload.
* **Mixture-of-Agents (MoA):** Sendet denselben Prompt parallel an mehrere Spezialisten-Slots und konsolidiert die Antworten über einen `Aggregator`-Slot.
* **Speculative Decoding (Draft + Target):** Kombiniert ein schnelles lokales `Draft`-Modell mit einem großen `Target`-Modell im Verbund zur Beschleunigung der effektiven Token-Rate.
* **Sequenzielle Modell-Pipeline:** Verkettet Modelle als spezialisierte Stufen (z. B. *Planer → Coder → Reviewer*) über lokale und WAN-Knoten hinweg.

### 7.3 Datenmodell, Echtzeit-Ausführung & Sicherheit
* **Domain-Modelle (`ClusterModels.swift`):** `MultiModelScope`, `MultiModelStrategy`, `MultiModelRole`, `MultiModelSlot` (inkl. Zielknoten, RAM-Bedarf, Endpunkt-URL und gemessener `lastTokPerSec` / `lastTtftMs`) sowie `MultiModelRunResult`.
* **ViewModel-Logik (`ClusterViewModel.swift`):**
  * `syncMultiModelSlotsFromCluster()` übernimmt automatisch erkannte Modelle (oMLX, Ollama, llama.cpp, GGUF) und mappt sie auf verfügbare Knoten im gewählten Scope.
  * `mmmFitsInClusterPool` prüft vorab gegen `mmmUsableVramPoolGB`, sodass der Speicherschutz-Puffer nie verletzt wird.
  * `executeMultiModelOrchestration()` nutzt im **Echtbetrieb** (`!simulateMacStudio`) reales SSE-Streaming (`runLiveChatCompletionTrial`) ohne Fake-Werte; im **Simulationsmodus** liefert er realistische, klar als `SIMULATION` markierte Referenzwerte.
* **UI (`MultiModelModeView.swift` & `SSCCCApp.swift`):** Scrollbare 10-Tab-Sidebar im Solaris-Design mit Scope-/Strategie-Auswahl, VRAM-Füllbalken, Slot-Editor und Live-Ausführungsprotokoll.

---

## 8. Phase 11 — 2026 SOTA Architecture Upgrade (Punkte 1–5)

Dieser Implementierungsplan fasst die fünf auf aktuellen Forschungsergebnissen basierenden Modernisierungen zusammen und definiert die konkrete Umsetzung in `ClusterModels.swift`, `ClusterViewModel.swift`, den zugehörigen SwiftUI-Views sowie der Test-Suite:

### 8.1 Punkt 1: TB5 RDMA Tensor Parallelism & QUIC / Iroh WAN-Transport
* **Domain-Modelle (`ClusterModels.swift`):**
  * `ClusterMeshTopology` (`ring`, `fullMesh`) für JACCL/MLX Tensor Parallelism vs. Pipeline-Ring.
  * `WanTransportProtocol` (`tailscaleWireGuard`, `quicIrohP2P`, `libp2pDerp`) für WAN-Peers ohne TCP Head-of-Line-Blocking.
* **ViewModel-Logik (`ClusterViewModel.swift`):**
  * `@Published var clusterMeshTopology: ClusterMeshTopology = .fullMesh`
  * `@Published var wanTransportProtocol: WanTransportProtocol = .quicIrohP2P`
  * `rdmaPreflightCommand()` (`rdma_ctl enable`, `bridge0`-Check, Per-Port-IP) und `generateMlxDistributedHostfileJSON()` (`mlx.distributed_config`-kompatibles Hostfile).
  * `wanTransportLatencyFactor` (QUIC 0-RTT & Stream-Multiplexing reduzieren effektive WAN-Latenz um ~28 % gegenüber TCP/Relay).
* **Views:** `NetworkRdmaView.swift` (Full-Mesh vs. Ring, `rdma_ctl`-Preflight & `bridge0`-Guard, `mlx.distributed_config`-Export) und `InternetClusterView.swift` (QUIC / Iroh P2P Selektor & Telemetrie).

### 8.2 Punkt 2: Disaggregiertes Prefill/Decode, ANE-Split & 3-Tier KV-Cache / CacheGen
* **Domain-Modelle (`ClusterModels.swift`):**
  * `SplitPhaseComputeMode` (`unifiedGpu`, `anePrefillGpuDecode`) für Energy-Delay-Product-(EDP)-Optimierung auf Apple Silicon.
  * `KVCacheTierMode` (`ramOnly`, `ramNvmeTiered`, `distributedCacheGen`) inkl. `CacheGenCompressionMetrics`.
* **ViewModel-Logik (`ClusterViewModel.swift`):**
  * `@Published var splitPhaseComputeMode: SplitPhaseComputeMode = .anePrefillGpuDecode`
  * `@Published var kvCacheTierMode: KVCacheTierMode = .distributedCacheGen`
  * `@Published var kvPrefixCacheHitRatePct: Double = 78.0`
  * `aneSplitSpeedupAndEnergyRatio()` & `cacheGenCompressionMetrics()` (Kompressionsfaktor ~3.6× für KV-Tensoren über TB/WAN).
* **Views:** `ModelStudioView.swift` & `ScienceBenchmarksView.swift` (Split-Phase ANE/MLX Steuerung + 3-Tier KV-Cache / CacheGen-Rechner).

### 8.3 Punkt 3: MMM Next-Gen (EAGLE-3, Tree-MoA Early-Exit & Adaptive Confidence Router)
* **Domain-Modelle (`ClusterModels.swift`):**
  * `SpeculativeEngineMode` (`standardDraftTarget`, `eagle3Fusion`) für Hidden-State-Fusion (`arXiv:2503.01840`).
* **ViewModel-Logik (`ClusterViewModel.swift`):**
  * `@Published var mmmSpeculativeEngine: SpeculativeEngineMode = .eagle3Fusion`
  * `@Published var mmmEnableTreeMoaEarlyExit: Bool = true`
  * `@Published var mmmMoaConfidenceThreshold: Double = 0.82`
  * `@Published var mmmConfidenceEscalationEnabled: Bool = true`
  * Integration in `mmmEstimatedCombinedTokPerSec` und `executeMultiModelOrchestration()`.
* **Views:** `MultiModelModeView.swift` (EAGLE-3 Toggle, Tree-MoA Early-Exit & Confidence-Schwellenwert-Slider, Adaptive Confidence Escalation).

### 8.4 Punkt 4: Moderne Agenten- & Gateway-Standards (`/v1/responses`, MCP Registry & A2A Agent Card)
* **Domain-Modelle (`ClusterModels.swift`):**
  * `AgentGatewayProtocol` (`chatCompletions`, `responsesWithMcp`, `a2aAgentCard`).
* **ViewModel-Logik (`ClusterViewModel.swift`):**
  * `@Published var selectedGatewayProtocol: AgentGatewayProtocol = .responsesWithMcp`
  * `generateOpenAIResponsesMcpPayload()`, `generateMcpRegistryJSON()`, `generateA2AAgentCardJSON()` (`/.well-known/agent.json`).
* **Views:** `AgentIntegrationsView.swift` & `ApiConsoleView.swift` (Live-Generator & Vorschau für `/v1/responses`, MCP-Server-Registry & `/.well-known/agent.json`).

### 8.5 Punkt 5: Thermal- & Carbon-Aware Workload Placement
* **Domain-Modelle (`ClusterModels.swift`):**
  * `ThermalCarbonSchedulingPolicy` (`performanceFirst`, `balancedThermal`, `ecoCarbonAware`).
* **ViewModel-Logik (`ClusterViewModel.swift`):**
  * `@Published var thermalCarbonPolicy: ThermalCarbonSchedulingPolicy = .balancedThermal`
  * `@Published var mmmThermalCarbonAwareScheduling: Bool = true`
  * `thermalAndCarbonAdjustedTargets(from:)` bewertet `ThermalState` und Effizienz pro Node und priorisiert kühle/effiziente Knoten in MMM & Routing.
* **Views:** `MultiModelModeView.swift` (Thermal-/Carbon-Aware Scheduler Toggle & Policy-Auswahl).

---

## 9. Phase 12 — Automatisches Verbund-Setup (`Setup / Einrichten`), Betriebsbereitschafts-Prüfung & Programmweite Hover-Shorttips

Auf Basis aktueller Forschungsergebnisse zu Zero-Config-Cluster-Orchestrierung (`Bonjour/mDNS`, `mlx.distributed_config`, `JACCL/RDMA`, `Tailscale/Iroh QUIC P2P`), verteilten Readiness-State-Machines (wie in *Ray*, *Exo* und *Petals*) sowie macOS SwiftUI Pointer-/Accessibility-Best-Practices wird SS-CCC um eine **11. Seitenmenü-Kategorie `Setup / Einrichten`** sowie ein **programmweites Shorttip-/Tooltip-System** erweitert.

### 9.1 Recherche-Grundlagen & Architektur-Entscheidungen
1. **Zero-Config-Erkennung & Provisionierung auf allen Macs:**
   * **Lokaler Verbund (TB3/4/5, RDMA/JACCL & 10GbE):** Automatische Erkennung aller über Bonjour/mDNS (`_ssccc._tcp` / `.local`) und Thunderbolt/LAN erreichbaren Macs (`system_profiler`, `ifconfig`, `rdma_ctl status`, `ibv_devices`), Erkennung der `bridge0`-Konfliktfreiheit, Abgleich von `iogpu.wired_limit_mb`, passwortlosem SSH-Trust (`ssh-copy-id`) sowie automatischer Erzeugung von `mlx.distributed_config` (`cluster.json`).
   * **Internet-Verbund (WAN P2P):** Automatische Erkennung von `Tailscale` / `WireGuard` / `QUIC Iroh P2P` (`0-RTT Multiplex`, NAT Hole-Punching mit DERP-Fallback) und Gossip/Raum-Synchronisation.
   * **Kombinationsverbund (Hybrid: Lokal + Internet):** Zwei-Ebenen-Setup, das lokale TB/RDMA-Inseln mit WAN-Peers über den jeweiligen Rank-0-Leitrechner koppelt.
2. **4-stufige Betriebsbereitschafts-State-Machine (`ClusterReadinessState`):**
   * Inspiriert durch relationale Readiness-Probes in *Exo / Ray / Petals* trennt SS-CCC strikt zwischen Liveness (lokaler Prozess) und verteilter Readiness (Cluster-Verbund):
     1. **`unconfigured` (*Uneingerichtet*):** Keine Verbund-Topologie oder Provisionierung gespeichert.
     2. **`incomplete` (*Unvollständig eingerichtet*):** Einzelne Voraussetzungen fehlen (z. B. `iogpu.wired_limit_mb` nicht gesetzt, SSH-Trust fehlt auf Teilknoten, `bridge0` aktiv oder WAN-Tunnel getrennt).
     3. **`notReady` (*Nicht bereit*):** Einrichtung vorhanden, aber aktive Prüf-Probe fehlgeschlagen (Knoten nicht erreichbar, RDMA/TCP-Handshake oder API-Loop `/v1/models` antwortet nicht, thermische Drosselung `.critical`).
     4. **`ready` (*Bereit — Betriebsbereit*):** Alle Knoten, Links, Speicherschutz-Grenzen, Transport-Protokolle und Endpunkte sind verifiziert und sofort einsatzfähig.
3. **Mehrstufige Prüf-Funktion (`verifyClusterReadiness()`):**
   * Führt deterministische Einzel-Checks (`ClusterReadinessCheckItem`) für die gewählte Variante (`Lokal`, `Internet-WAN`, `Hybrid`) aus:
     * *Discovery & Host-Erreichbarkeit* (Bonjour/mDNS, `.local`-Auflösung, Peer-Ping/RTT)
     * *Interconnect & Transport* (TB3/4/5 Link, `bridge0`-Check, `rdma_ctl` bzw. QUIC/Iroh/Tailscale Tunnel)
     * *Speicherschutz & Hardware* (`iogpu.wired_limit_mb`-Guard pro Mac, freier RAM, Thermal-State)
     * *Runtime & Gateway-Loop* (SSH/mlx.launch-Konsistenz, `:8000/v1` bzw. `:11434` Health-Antwort)
   * Zeigt das Gesamturteil (**Bereit** vs. **Nicht bereit** / **Unvollständig** / **Uneingerichtet**) inklusive Schritt-für-Schritt-Behebung direkt im Setup-Bereich und als Live-Status-Badge in der Seitenleiste/Kopfzeile an.

### 9.2 Programmweite Shorttips / Tooltips (Mouse-Hover in allen Bereichen)
* **SwiftUI-Architektur ohne `@State`-Makros (CLT-kompatibel):**
  * Zentrales Lokalisierungs-Wörterbuch in `Localization.swift` (alle 8 Sprachen: `DE/EN/FR/ES/PT/RU/JA/ZH`) für jeden Bereich, jeden Tab, jede Karte und alle zentralen Steuer-Elemente.
  * Einheitlicher ViewModifier (`solarisShorttip(_ text: String, id: String)`) in `Theme.swift`, gesteuert über `@Published var activeShorttipText: String?` / `hoveredShorttipId: String?` in `ClusterViewModel` (kein `@State`, vollständige Accessibility-Spiegelung via `.help(text)` und `.accessibilityHint(text)` sowie Respekt vor `accessibilityReduceMotion`).
  * **Sichtbarkeit in allen Bereichen:** Sowohl native macOS Hover-Tooltips (`.help(...)`) als auch eine schwebende, hochkontrastige Solaris-Shorttip-Leiste / Hover-Blase, die beim Überfahren eines Bereichs mit dem Mauszeiger sofort eine verständliche Kurz-Erklärung einblendet.

### 9.3 Geplante Dateien & Tests
* **`ClusterModels.swift`:** `NavigationTab.setup`, `ClusterSetupVariant` (`local`, `internet`, `hybrid`), `ClusterReadinessState` (`unconfigured`, `incomplete`, `notReady`, `ready`), `ClusterReadinessCheckItem`, `NodeProvisioningTarget`.
* **`Localization.swift`:** Vollständige 8-Sprachen-Übersetzung für den Setup-Tab, alle 4 Readiness-Zustände und alle programmweiten Shorttip-Keys.
* **`ClusterViewModel.swift`:** Automatische Verbund-Erkennung (`discoverClusterSetupTargets()`), Multi-Mac-Provisionierung (`runAutomaticClusterSetup()`), Prüf-Engine (`verifyClusterReadiness()`) und `@Published` Hover-Shorttip-State.
* **`ClusterSetupView.swift` & `Theme.swift`:** Neue 11. Sidebar-Kategorie `Setup / Einrichten` mit Varianten-Wahl, Auto-Provisioning, Live-Prüfprotokoll und Bereitschafts-Anzeige; `solarisShorttip` auf allen 11 Views und Sidebar-Einträgen.
* **`scripts/run_ssccc.sh` & `tests/test_global_suite.py`:** Aufnahme von `ClusterSetupView.swift` und neue automatisierte Tests für Auto-Setup, 4-Stufen-Readiness-Prüfung und 8-Sprachen-Shorttips.

---

## 10. Phase 13 — Vollständige 8-Sprachen-Übersetzung, Mac-GPU-/ANE-Auslesung & 25/25-Testabdeckung

### 10.1 Vollständige 8-Sprachen-Abdeckung (Deutsch als Übersetzungsvorlage)
* **`Localization.swift` & `ClusterModels.swift`:** Einführung von `L10n.tr(_ lang:de:en:fr:es:pt:ru:ja:zh:)`, Korrektur des deutschen Seitenmenü-Namens auf **Modell Werkstatt**, ausgeschriebene Schichteneinheit (`ms_layers_unit`: `Schichten` / `Layers` statt `24L`) sowie 8-sprachige Lokalisierung aller Transport-, Katalog-, Readiness- und KV-Cache-Methoden (`localizedTitle`, `localizedDescription`, `localizedMaxContextEstimate`, `localizedSourceLabel`, `localizedNotes`).
* **Alle 11 Views + `HelpDocDeepDiveContent.swift` + `ClusterViewModel.swift`:** Entfernung verbliebener deutscher UI-Literale und alter zweisprachiger `isGerman`-Verzweigungen; alle Übersichten, Buttons (`Prüfen`, `Setup öffnen`), Tabellen (`Thunderbolt-Klassen & Übertragungsraten`), Untermenüs (inkl. `Disaggregiertes Prefill/Decode (ANE-Split) & 3-Tier KV-Cache`) und dynamische Statusmeldungen übersetzen in alle 8 App-Sprachen.

### 10.2 Lokale Mac-GPU- & Neural-Engine-(ANE-)Kern-Auslesung
* **`ClusterViewModel.swift` & `ClusterOverviewView.swift`:** Erweiterte Hardware-Probe über `IOAccelerator` (`gpu-core-count`) und `system_profiler SPDisplaysDataType` sowie Anzeige von **CPU-, GPU- und ANE-Kernen** direkt in den Knotenkarten.

### 10.3 Verifikation (`tests/test_global_suite.py`)
* Erweiterung um `test_25_eight_language_views_and_gpu_ane_display` sowie Abschnitt 11 in `tests/run_swift_checks.swift` — **alle `25/25` automatisierten Tests bestanden**.
