# Multi-Model Mode (MMM) & AI Agent / IDE Integration

[← Back to Wiki Home](Home.md)

## 🧠 Orchestrating Multiple Models Simultaneously

**Multi-Model Mode (MMM)** unites multiple local and remote LLMs across **Local TB/RDMA**, **Internet WAN**, or **Hybrid** topologies while strictly honoring per-node `iogpu.wired_limit_mb` limits and thermal/carbon policies.

### 4 Core Orchestration Strategies
1. **Parallel Multi-Model Pool:** Keeps multiple specialized models loaded concurrently (e.g., `32B Coder + 8B Fast Router + 1.5B Embeddings`).
2. **Mixture-of-Agents (MoA):** Sends one prompt to multiple specialist slots in parallel and synthesizes the final response through an `Aggregator` model.
3. **Speculative Decoding (`EAGLE-3` / Draft + Target):** Pairs a small fast `Draft` model (e.g., on Mac mini M4) with a 70B+ `Target` model for **$1.6\times$–$2.3\times$** decode speedups.
4. **Sequential Pipeline / Tree-MoA / Ares:** Chains specialist stages (*Planner → Coder → Security Reviewer*) with adaptive confidence escalation (`50–95%`).

---

## ⚙️ 1-Click Auto-Setup & Post-Setup Slot Editor

- **1-Click Profiles:** **Coding & IDE Swarm**, **Consensus & Audit**, **Turbo (Draft + Target)**, and **Stage Pipeline** inspect live usable VRAM and discovered models automatically.
- **Live Post-Configuration Editing:** Reorder pipeline stages (`Up`/`Down`), duplicate replicas onto other nodes, toggle slots on/off, or edit model IDs and endpoints (`:8000/v1`, `:11434/v1`) anytime.

---

## 🤖 6× 1-Click Agent & IDE Consumption (`:8000/v1`)

Under **Agents & IDEs** and **API & Console**, generate or copy ready-to-use configurations (including **OpenAI `/v1/responses` + MCP**, **MCP Server Registry JSON**, and **A2A Agent Cards** `/.well-known/agent.json`) for:

- **Cursor**
- **Visual Studio Code**
- **Apple Xcode**
- **OpenCode**
- **Hermes Agent**
- **Google Antigravity**

All connected tools share the same unified API gateway (`http://127.0.0.1:8000/v1`) with real-time per-client `tok/s` estimation.
