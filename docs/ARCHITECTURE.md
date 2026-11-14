# Architekturverfahren: Mac-Cluster-App

Dieses Dokument legt das verbindliche **Architekturverfahren** für das Projekt fest — basierend auf den Anforderungen (Mac Studio M5 Max 36 GB + Mac mini M4 16 GB, Hybrid LAN/WLAN + Thunderbolt/RDMA, OpenAI/Ollama-API + native macOS-App).

---

## 1. Gewähltes Architekturverfahren (3-Ebenen-Kombination)

### 1.1 Verteilte System-Topologie: **Control/Data-Plane-Separation + Coordinator-Worker**
* **Control Plane (LAN / WLAN):**
  * mDNS/Bonjour-Discovery (`_maccluster._tcp.local.`), Heartbeats, Node-Telemetrie, HuggingFace-Modell-Downloads und externes OpenAI/Ollama-API-Gateway.
  * **Coordinator (Primary):** Standardmäßig der **Mac Studio M5 Max** (36 GB, 460 GB/s, 10GbE) — hält Rank 0, Embeddings, LM-Head und ~71 % der Transformer-Layer.
  * **Worker:** Der **Mac mini M4** (16 GB, 120 GB/s) — hält Rank 1 und ~29 % der Layer.
* **Data Plane (Thunderbolt bevorzugt, LAN/WLAN Fallback):**
  * Strikt isolierte, numerische Punkt-zu-Punkt-Interfaces (`10.99.x.x` oder `rdma_en*`) ausschließlich für Aktivierungs- und Tensor-Transfers (`ring` oder `jaccl`).
  * Kein Packet-Bonding mit langsamem LAN/WLAN während der Inferenz (verhindert Straggler-Latenz beim Token-Decode).

### 1.2 Backend-Architektur (`core/`): **Hexagonale Architektur (Ports & Adapters)**
Damit Transportwege (`ring` TCP/IP vs. `jaccl` RDMA vs. LAN/WLAN-Fallback) und Inferenz-Engines (`mlx-lm` heute, optional `llama.cpp` RPC später) ohne Umbau der Geschäftslogik austauschbar bleiben:

* **`core/domain/`** — Reine Datenmodelle & Regeln ohne Framework-Abhängigkeiten:
  * `NodeSpec` (RAM, `wired_limit_mb`, Chip, Thunderbolt-Generation, RDMA-Status)
  * `LinkMetrics` (Latenz, Bandbreite, Interface-Typ, Priorität)
  * `ShardingPlan` (proportionale Layer-Zuweisung, z. B. 71/29-Split)
* **`core/ports/`** — Abstrakte Schnittstellen (Protocols/ABCs):
  * `TransportPort` (Link-Probing, Hostfile-Generierung, Failover)
  * `InferencePort` (Modell laden, Pipeline/Tensor-Inferenz, Token-Stream)
  * `DiscoveryPort` (Peer-Erkennung im LAN/WLAN)
  * `SystemControlPort` (`iogpu.wired_limit_mb`, Hardware-Telemetrie)
* **`core/adapters/`** — Konkrete Implementierungen:
  * `transport/`: `ThunderboltBridgeAdapter`, `RdmaJacclAdapter`, `LanWlanFallbackAdapter`
  * `inference/`: `MlxPipelineAdapter` (mit `MLX_METAL_FAST_SYNCH=1` + Watchdog), `MlxJacclAdapter`
  * `discovery/`: `BonjourZeroconfAdapter`
  * `system/`: `MacOSSysctlAdapter`, `ProfilerAdapter`
* **`core/application/`** — Orchestrierung (Use Cases):
  * `ClusterCoordinator`, `MemoryWeightedPlanner`, `ModelSyncService`, `BenchmarkRunner`
* **`core/api/`** — FastAPI-Gateway (OpenAI `/v1/chat/completions`, Ollama `/api/chat`, interne UI-IPC-Endpunkte).

### 1.3 Frontend-Architektur (`app/`): **MVVM (SwiftUI Native macOS App)**
* **`Models/`** — Codable-Structs passend zur Daemon-API (`ClusterNode`, `ModelInfo`, `TopologyLink`).
* **`Services/`** — `ClusterDaemonService` (steuert Python/`uv`-Prozess & REST/WebSocket-IPC), `BonjourBrowserService` (`NWBrowser`).
* **`ViewModels/`** — `DashboardViewModel`, `TopologyViewModel`, `ModelsViewModel`.
* **`Views/`** — Menüleisten-Popover, Topologie-Graph, 52-GB-Memory-Monitor, Modell-Manager.

---

## 2. Verzeichnisstruktur

```text
Harbor Substitut Thunderbold 4/
├── docs/                       # Roadmap, Implementation Plan, Architektur
├── core/                       # Python Cluster & Inference Engine (Hexagonal)
│   ├── domain/                 # Reine Domänenmodelle (Node, Link, ShardingPlan)
│   ├── ports/                  # Abstrakte Interfaces (Transport, Inference, Discovery)
│   ├── adapters/
│   │   ├── transport/          # TB-Bridge, RDMA/JACCL, LAN/WLAN-Fallback
│   │   ├── inference/          # MLX Ring/Pipeline & MLX JACCL Runner
│   │   ├── discovery/          # mDNS / Bonjour (zeroconf)
│   │   └── system/             # sysctl (iogpu.wired_limit_mb), ibv_devices, Profiler
│   ├── application/            # Planner (71/29-Split), Coordinator, Model-Sync
│   ├── api/                    # OpenAI & Ollama API Gateway + UI-IPC
│   └── tests/                  # Unit- & Integrationstests
├── app/                        # Native macOS SwiftUI App (MVVM)
│   ├── Sources/
│   │   ├── Models/
│   │   ├── Services/
│   │   ├── ViewModels/
│   │   └── Views/
│   └── Resources/
├── scripts/                    # TB-Netzwerk-Setup, RDMA-Check, Benchmarks
└── configs/                    # Generierte Hostfiles (ring/jaccl) & Cluster-Profile
```
