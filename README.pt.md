<div align="center">

# ☀️ Assistente de conjunto SonnerStudio (SS-CCC)

<img src="docs/images/flags/us.png" width="20" height="16" alt="US"/> <img src="docs/images/flags/gb.png" width="20" height="16" alt="GB"/> <img src="docs/images/flags/ca.png" width="20" height="16" alt="CA"/> **[English](README.md)** · <img src="docs/images/flags/de.png" width="20" height="16" alt="DE"/> <img src="docs/images/flags/at.png" width="20" height="16" alt="AT"/> <img src="docs/images/flags/ch.png" width="20" height="16" alt="CH"/> **[Deutsch](README.de.md)** · <img src="docs/images/flags/fr.png" width="20" height="16" alt="FR"/> <img src="docs/images/flags/be.png" width="20" height="16" alt="BE"/> <img src="docs/images/flags/ch.png" width="20" height="16" alt="CH"/> **[Français](README.fr.md)** · <img src="docs/images/flags/es.png" width="20" height="16" alt="ES"/> <img src="docs/images/flags/mx.png" width="20" height="16" alt="MX"/> <img src="docs/images/flags/ar.png" width="20" height="16" alt="AR"/> **[Español](README.es.md)** · <img src="docs/images/flags/pt.png" width="20" height="16" alt="PT"/> <img src="docs/images/flags/br.png" width="20" height="16" alt="BR"/> **[Português](README.pt.md)** · <img src="docs/images/flags/ru.png" width="20" height="16" alt="RU"/> **[Русский](README.ru.md)** · <img src="docs/images/flags/jp.png" width="20" height="16" alt="JP"/> **[日本語](README.ja.md)** · <img src="docs/images/flags/cn.png" width="20" height="16" alt="CN"/> **[中文](README.zh.md)**

*Gestor nativo macOS de conjuntos Apple Silicon e oficina de inferência distribuída MLX*

<table>
  <tr>
    <td align="center">
      <img src="docs/images/ssccc_cluster_52gb.png" alt="SS-CCC Modo Conjunto 52 GB" width="100%"/><br/>
      <sub><b>Modo Conjunto (52 GB unificados · 2 equipamentos)</b></sub>
    </td>
    <td align="center">
      <img src="docs/images/ssccc_single_16gb.png" alt="SS-CCC Modo Individual 16 GB" width="100%"/><br/>
      <sub><b>Modo Individual (16 GB local · 1 equipamento)</b></sub>
    </td>
  </tr>
</table>

</div>

---

## 🧭 Visão geral

O **Assistente de conjunto SonnerStudio (SS-CCC)** acopla a memória unificada de qualquer **Mac Apple Silicon (M1–M9+)** — desde um Mac mini ou MacBook Pro até agrupamentos locais **Thunderbolt 3/4/5 e RDMA** ou **redes mundiais pela Internet (2–256+ Macs)** — com ligação direta ao **MLX**, **oMLX**, **Ollama** e **llama.cpp**.

<div align="center">
  <img src="docs/images/i18n/ssccc_ecosystem_pt.jpg" alt="SS-CCC Ecossistema universal Apple Silicon M1–M12+ (11 módulos)" width="94%"/>
</div>

---

## 🌐 Rede Internet mundial, conversa e análise científica

<table>
  <tr>
    <td align="center" width="50%">
      <img src="docs/images/ssccc_internet_wan_mesh.jpg" alt="SS-CCC Rede Internet mundial e Conversa" width="100%"/><br/>
      <sub><b>Rede Internet e conversa dos participantes</b><br/>Tailscale · WireGuard · libp2p QUIC · DERP · <code>/status</code> · <code>/layers</code> · <code>/ping</code></sub>
    </td>
    <td align="center" width="50%">
      <img src="docs/images/ssccc_science_roofline_hero.jpg" alt="SS-CCC Ciência e Roofline" width="100%"/><br/>
      <sub><b>Análise Roofline e balanço energético</b><br/>Curva log-log · Bolha GPipe · <code>J/token</code> · <code>p50/p95/p99</code> · CSV/JSON/BibTeX</sub>
    </td>
  </tr>
</table>

---

## 🏗️ Arquitetura híbrida (controlo, Thunderbolt e Internet)

```mermaid
flowchart LR
  Clients["Cursor · VS Code · Xcode · OpenCode · Hermes · Antigravity"] -->|"Interface (:8000 / :11434)"| Rank0
  subgraph Control["Plano de controlo (rede local / sem fios / Tailscale)"]
    Discovery["Descoberta Bonjour e conversa WebSocket (/ws/wan/{room})"]
  end
  subgraph Data["Plano de dados (TB3/4/5 · RDMA · Cadeia WAN)"]
    Rank0["Nível 0 Coordenador (maior débito M1–M9+)"] <-->|"MLX ring / jaccl + FAST_SYNCH=1 (~4 µs)"| Workers["Nós trabalhadores (Nível 1..N · camadas ponderadas)"]
  end
```

---

## 🌐 Monitor de Largura de Banda e Débito WAN (Agrupamento Internet)

![Monitor de Largura de Banda e Débito WAN SS-CCC](docs/images/ssccc_wan_bandwidth_monitor.jpg)

Em **Agrupamento Internet & Chat**, o SS-CCC monitoriza continuamente o desempenho real da ligação WAN (`netstat`, `ping`, `networkQuality`) — **downlink/uplink (Mbps)**, **latência RTT WAN (ms)**, **jitter**, **perda de pacotes** e **eficiência de sincronização de tokens** — correlacionando diretamente o débito WAN com os `tok/s` distribuídos.

---

## ✨ Funcionalidades principais

- **Acoplamento universal Apple Silicon (M1 – M9+):** Liga livremente vários Mac (Mac mini, MacBook Air/Pro, iMac, Mac Studio, Mac Pro) das gerações M1 a M6 e futuras **M7, M8, M9+** num agrupamento comum com cálculo automático da largura de banda de memória.
- **Telemetria completa de equipamento e sensores:** Leitura direta através de `sysctl`, `sw_vers`, `system_profiler`, `ioreg`, `pmset` e `ibv_devices`: núcleos CPU (P/E), núcleos GPU, núcleos do motor neuronal (16 / 32 núcleos ANE), espaço SSD total/livre, estado térmico, temperatura da bateria (`°C`) e consumo elétrico (`W`).
- **Classes Thunderbolt 3 / 4 / 5 e RDMA:** Deteção e classificação automáticas para processadores M1–M9+ (TB3 `40 Gbps`, TB4 `40 Gbps`, TB5 `80/120 Gbps`, bem como RDMA por Thunderbolt 5), com plano de controlo LAN/Wi-Fi separado e plano de dados Thunderbolt isolado.
- **Divisão ponderada de camadas e proteção `iogpu.wired_limit_mb`:** Distribuição proporcional consoante a largura de banda de memória de cada nó ativo, mantendo uma reserva segura do sistema para o macOS.
- **Deteção real de modelos (oMLX, Ollama e llama.cpp):** Leitura direta dos modelos disponíveis no **oMLX**, **Ollama**, **llama.cpp**, ficheiros `.gguf` locais e cache MLX (sem perfis fictícios quando vazio, com verificação de estado e comandos copiáveis).
- **Agrupamento global pela Internet (WAN) e conversação entre participantes (`/ws/wan/{room_id}`):** Ligue computadores Mac com Apple Silicon em todo o mundo por túnel cifrado (Tailscale/WireGuard, retransmissão P2P libp2p/DERP ou ponto manual) em grandes agrupamentos distribuídos com sala de conversa em tempo real.
- **Laboratório científico de 6 separadores (Local e WAN) e histórico:** Alterne entre **Local (TB/RDMA)**, **Internet WAN** e **Comparação direta** em seis áreas: **Limite e gargalo** (teto de rede efetivo, lote crítico $B^*$), **Topologia WAN e escala** ($N=1\dots128$, compressão *Petals/SWARM*, retardatários, *DiLoCo* vs. DDP), **Memória e cache KV**, **Energia, CO₂ e custo** (`J/token`, `EDP`, `gCO₂eq/kWh`), **Ensaios, estatística e exportação** (`IC₉₅`, `CV%`, `Goodput%`, `CSV / JSON / LaTeX / BibTeX`) e **Histórico** (gravação por posição individual ou global, gráfico de tendência e CSV).
- **Atualizações via GitHub e controlo automático de versões:** Verifica `version.json`, *GitHub Releases* e o SHA de `commits/main` no arranque e a cada 30 minutos (`⌘U`). Apresenta um aviso de atualização integrado com `git pull` + `swift build` + reinício num clique ou transferência via GitHub, suportado por `scripts/bump_version.py` e `.github/workflows/auto-version-control.yml`.
- **Agentes e ambientes num clique:** Configuração imediata para **OpenCode**, **Hermes Agent**, **Google Antigravity**, **Cursor**, **Visual Studio Code** e **Xcode**.
- **Modo de simulação comutável, tema amarelo SonnerStudio (`#FFD400`) e testes globais (`tests/`):** A simulação de demonstração mantém-se na barra lateral; todo o projeto é verificado por `tests/test_global_suite.py` (`python3 -m unittest discover -s tests -v`).
- **Interface multilingue, dicas rápidas e centro de ajuda interativo:** Alternância imediata entre **8 idiomas** (inglês, alemão, francês, espanhol, português, russo, japonês e chinês), **Shorttips ao passar o cursor** em toda a aplicação, **ajuda interativa de 12 capítulos** com gráficos detalhados e realce luminoso, e telemetria em tempo real (sem dados fictícios fora da simulação).

### 🖥️ As 11 áreas do programa num relance

![Ecossistema local de agentes de IA e IDEs num clique](docs/images/ssccc_agents_ide_ecosystem.jpg)

| Área | Conteúdo e função |
| :--- | :--- |
| **1. Visão do agrupamento** | Memória conjunta, nós ativos, velocidade da ligação de dados, topologia visual, barra `iogpu.wired_limit_mb` e **cartão de estado operacional de 4 níveis** |
| **2. Dispositivos e comparação** | Telemetria em tempo real de cada Mac (CPU, GPU, ANE, RAM, largura de banda, SSD, temperatura, potência) e adição de Mac M1–M12+ |
| **3. Oficina de modelos** | Leitura real de modelos (oMLX, Ollama, llama.cpp, GGUF), estado dos serviços, divisão de camadas, ANE-Split e memória KV de 3 níveis / CacheGen |
| **4. Rede e RDMA** | Matriz de classes Thunderbolt 3/4/5 para M1–M12+, estado RDMA, Pipeline Ring vs. JACCL Full-Mesh TP e encaminhamento LAN/Thunderbolt |
| **5. Agrupamento Internet, Audio-Party e conversa** | Ligar Mac TB/RDMA locais a nós WAN globais (QUIC/Iroh 0-RTT, Tailscale/WireGuard, libp2p/DERP), monitorizar em tempo real a **largura de banda e débito WAN** (`netstat`, ping/jitter, `networkQuality -c`) e coordenar via Audio-Party e conversa (`/ws/wan-audio`, `/ws/wan`) |
| **6. Modo Multimodelo (MMM)** | Orquestrar vários modelos em conjunto **Local**, **Internet-WAN** ou **Híbrido** (*Pool paralelo*, *Mixture-of-Agents*, *EAGLE-3 / Speculative*, *Tree-MoA Early-Exit*, *Ares*) com proteção VRAM/térmica/carbono e consumo simultâneo **Multi-IDE / Harnesses** (`:8000/v1`) |
| **7. Agentes e ambientes** | Configuração num clique (incl. **MCP Registry JSON** e **A2A Agent Card**) para **OpenCode**, **Hermes Agent**, **Antigravity**, **Cursor**, **Visual Studio Code** e **Xcode** |
| **8. Ciência e Roofline** | Laboratório de 6 separadores com **streaming SSE real e ping ICMP** em modo real (simulação realista identificada), **avaliação direta do Modo Multimodelo (MMM)**, curva Roofline, `N=1..128`, *Petals/SWARM* e *DiLoCo*, equação KV, `J/token` / `EDP` / `CO₂`, `IC₉₅`, exportação `CSV / JSON / LaTeX / BibTeX` e **Histórico** |
| **9. API e consola** | Pontos de extremidade compatíveis com OpenAI (`/v1/chat/completions`, `/v1/responses` + MCP), Ollama (`/api/tags`) e **A2A Agent Card** (`/.well-known/agent.json`), registo de atividade e testes ao vivo |
| **10. Configurar e provisionar** | Deteção automática de Mac locais (Bonjour/mDNS), pares WAN (`QUIC Iroh` / `Tailscale`) ou clusters híbridos; provisionamento de confiança SSH, `iogpu.wired_limit_mb` e `mlx.distributed_config`, e **verificação de prontidão operacional** (**Pronto / Não pronto / Parcialmente configurado / Não configurado**) |
| **11. Ajuda e documentação** | Manual interativo de **12 capítulos em 8 idiomas** (`⌘?`) com cartões clicáveis, gráficos detalhados, realce luminoso e guia passo a passo |

---

## 🛠️ Compilar a partir do código-fonte (antes da primeira execução)

> [!NOTE]
> Este repositório contém apenas o **código-fonte em Swift** do SS-CCC (não inclui um executável pré-compilado). Para obter uma versão pronta a iniciar, o código tem de ser **compilado localmente no seu Mac Apple Silicon**.

### Pré-requisitos
- Um Mac com Apple Silicon (**M1–M6**) e **macOS 14.0 ou mais recente**
- **Ferramentas de linha de comandos do Xcode** (`swiftc` e o SDK do macOS):
  ```bash
  xcode-select --install
  ```

### Passo a passo até à aplicação executável
```bash
# 1. Clonar o repositório e entrar na pasta
git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
cd SonnerStudio-Cluster-Case-Companion

# 2. Tornar o guião de compilação e arranque executável
chmod +x scripts/run_ssccc.sh

# 3. Compilar o código Swift para /tmp/SSCCCApp e iniciar a aplicação
./scripts/run_ssccc.sh
```
*(Opcional: também é possível compilar com o Swift Package Manager usando `cd app && swift build -c release`.)*

---

## 🚀 Arranque rápido

```bash
"./scripts/run_ssccc.sh"
```

---

## 📖 Guia operacional: Configuração local e híbrida (Local + Internet), carregamento de modelos e dados teóricos

### 1. Configuração do agrupamento local (Thunderbolt 3/4/5 e LAN)
1. **Ligação física:** Ligue os seus Mac diretamente através de cabos **Thunderbolt 3/4/5** (ponto-a-ponto, anel ou malha) e/ou **Ethernet 10GbE**.
2. **Atribuir IPs ponto-a-ponto:** Execute `./scripts/setup_tb_network.sh studio` (`10.99.1.1`) no Mac principal e `./scripts/setup_tb_network.sh mini` (`10.99.1.2`, etc.) nos nós trabalhadores, ou configure em **Rede e memória direta**.
3. **RDMA opcional (macOS 26.2+ em TB5):** Ative `rdma_ctl enable` para o motor `JACCL` (`mlx.distributed`) atingir **`~3 µs`** de latência entre nós em vez de `~300 µs` via TCP/IP.
4. **Atribuição automática de níveis:** Adicione todos os Mac em **Dispositivos e Comparação**. O `MemoryWeightedPlanner` atribui automaticamente o **nível 0 (coordenador)** ao Mac com maior largura de banda de memória, e os **níveis 1..N (trabalhadores)** aos restantes.

### 2. Configuração da rede híbrida (Local + Internet WAN em simultâneo)
1. **Núcleo local rápido (Nível 1):** O anel local Thunderbolt/LAN (`10.99.1.x` / `192.168.x.x`) mantém-se ativo para as camadas sensíveis à latência.
2. **Sala coordenadora WAN (Nível 2):** Em **Rede Internet e Conversa**, crie uma sala WAN (`/ws/wan/{room_id}` na porta `8000`, exposta via Tailscale, WireGuard, Cloudflare Tunnel ou proxy inverso).
3. **Ligar nós remotos:** Macs em qualquer parte do mundo ligam-se com o **Código da sala + Token de acesso**.
4. **Encaminhamento híbrido em dois níveis:** O SS-CCC mantém as camadas de alta frequência no anel local (`3–180 µs`) e encaminha as etapas excedentes para trabalhadores WAN (`15–120 ms` RTT) com micro-lotes (`M ≥ 4`).

### 3. Quem carrega o modelo, quantos modelos cabem e qual é o fluxo de execução?
- **Quem carrega o quê?**
  - **Coordenador (Nível 0):** Aloja o gateway API (`:8000`), executa a tokenização, **mantém sempre os Embeddings e a cabeça LM (`has_embeddings=True`, `has_lm_head=True`)** além da sua quota proporcional de camadas (`Camadas_i = Total × Utilizável_i / TotalUtilizável`).
  - **Trabalhadores (Níveis 1..N):** Cada nó carrega **apenas a sua fatia Safetensors/camadas `[start_layer .. end_layer)`** a partir da cache local HuggingFace/oMLX/Ollama (`~/.cache/huggingface`, `~/.ollama/models`, `~/Models`).
- **Quantos modelos podem ser carregados em simultâneo?**
  - **Modo distribuído (`mlx.distributed` / `JACCL`):** **1 grande modelo fragmentado de cada vez** em todo o pool de memória (troca rápida por hot-swap).
  - **Modo multimodelo (`oMLX` / `Ollama` / nós heterogéneos):** Enquanto `Σ (Pesos_i + Cache_KV_i) ≤ VRAM_Utilizável_Total_GB` (após reservar 4–8 GB por Mac via `iogpu.wired_limit_mb`), **vários modelos** podem permanecer residentes em paralelo (ex.: **programador 32B + encaminhador rápido 8B + embeddings 1,5B**).
- **Fluxo e estrutura de um pedido:**
  1. **Sondagem e seleção de ligação** (`TB5 RDMA > TB Bridge > 10GbE > WLAN > WAN`).
  2. **Plano de repartição** (`hostfile.json` e limites `iogpu.wired_limit_mb`).
  3. **Entrada API** (`http://127.0.0.1:8000/v1/chat/completions`, `/v1/messages`, `/api/chat`).
  4. **Fase Prefill (`TTFT`):** O nível 0 processa o prompt e envia ativações pelo pipeline (`Nível 0 → 1 → ... → N → Nível 0`).
  5. **Fase Decode (`TPOT` e `tok/s`):** Geração token a token com `--kv-bits 4` e `MLX_METAL_FAST_SYNCH=1`.
  6. **Streaming SSE e telemetria** em **Ciência e Desempenho** (`tok/s`, `J/tok`, `p50/p95/p99`).

### 4. Dados teóricos de dimensionamento e desempenho por caso de uso

> **Fórmulas de estimativa analítica:**
> - **Memória necessária:** `VRAM_GB ≈ Parâmetros_B × (Bits / 8) × 1,15 + Cache_KV_GB`
> - **Limite teórico Decode:** `tok/s ≈ (Largura_Banda_Efetiva_GB/s / Pesos_Ativos_GB) × (1 − Sobrecarga_Comm)`

| Caso de uso | Topologia e Pool utilizável | Modelo típico e quantização | `TTFT` teórico (2k prompt) | Débito teórico (`tok/s` / `TPOT`) | Energia e gargalo principal |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Estação individual (Edge Dev)** | 1× Mac mini M4 (16 GB, `12 GB` úteis, `120 GB/s`) | `Qwen2.5-14B` (`4 bits`, ~8,8 GB) | `~1,8 – 2,6 s` | **`11 – 14 tok/s`** (`~75 ms/tok`) | `~1,7 J/tok` · Largura de banda |
| **2. Studio Pro individual (Código rápido)** | 1× Mac Studio M4 Max (64 GB, `58 GB` úteis, `546 GB/s`) | `Llama-3.3-70B` (`4 bits`, ~40 GB) | `~1,1 – 1,7 s` | **`12 – 14 tok/s`** (`~74 ms/tok`) | `~3,8 J/tok` · Largura de banda |
| **3. Anel local 2 nós TB5 RDMA** | 2× M4 Max 64 GB (`116 GB` úteis, `~1.092 GB/s` agg., `~3 µs` JACCL) | `Qwen2.5-Coder-72B` (`8 bits`, ~78 GB) | `~1,4 – 2,0 s` | **`12 – 14 tok/s`** (`~76 ms/tok`) | `~7,5 J/tok` · Sobrecarga RDMA mínima |
| **4. Lab 4 nós Ultra TB5 RDMA** | 4× M3 Ultra 256 GB (`992 GB` úteis, `~3,27 TB/s` agg.) | `DeepSeek-V3 671B MoE` (`4 bits`, ~385 GB, ~37B ativos) | `~2,2 – 3,5 s` | **`38 – 55 tok/s`** (`~20 ms/tok`) | `~5,2 J/tok` · BW especialistas ativos MoE |
| **5. Híbrido Escritório LAN + Casa WAN** | 2× TB4/10GbE + 2× WAN (`192 GB` úteis, `35 ms` RTT WAN) | `Llama-3.1-405B` (`3/4 bits`, ~170 GB) | `~6 – 11 s` | **`2,2 – 4,5 tok/s`** (`~280 ms/tok`) | `~28 J/tok` · Latência WAN (`M=8` ajuda) |
| **6. Enxame comunitário global WAN** | 16+ Mac globais (`1,5+ TB` úteis, `60–120 ms` RTT WAN) | `671B–1T+` Frontier (`4/8 bits`) | `~12 – 25 s` | **`1,2 – 3,0 tok/s`** (`~500 ms/tok`) | Latência WAN (batching escala) |

---

## 📚 Documentação selecionada (incluída na ajuda do programa)

### 1. Todos os Mac com processador M em conjunto (M1–M6)
O SS-CCC suporta **qualquer Mac com processador Apple Silicon** (**M1, M2, M3, M4, M5, M6** — Base, Pro, Max e Ultra): **Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio e Mac Pro**. Em **Dispositivos e Comparação**, adicione quantos Mac desejar; o equipamento com maior largura de banda assume automaticamente o **nível 0 (coordenador)**.

| Família de chip | Largura de banda | Thunderbolt e RDMA | Reserva recomendada para macOS |
| :--- | :--- | :--- | :--- |
| **M1 / M2** (Base) | 68 – 100 GB/s | TB 3 / USB4 (26–32 Gbps) | **4 GB** (≤ 24 GB RAM) |
| **M3 / M4** (Base) | 100 – 120 GB/s | TB 4 (30–37 Gbps) | **4 GB** (≤ 24 GB RAM) |
| **M5 / M6** (Base, M6 2nm) | **153 – 170 GB/s** (`M6`: 153 GB/s @ 16 GB, 170 GB/s @ 24–32 GB) | TB 4 / TB 5 (`80/120 Gbps`) | **4 GB** (≤ 32 GB RAM) |
| **M1–M3 Pro** | 150 – 200 GB/s | TB 4 (30–37 Gbps) | **4 – 6 GB** |
| **M4 / M5 Pro** | 273 – 307+ GB/s | TB 5 (`80/120 Gbps` boost) | **4 – 6 GB** |
| **M1–M3 Max** | 400 GB/s | TB 4 (30–37 Gbps) | **6 GB** (32–64 GB RAM) |
| **M4 Max** | **410 – 546 GB/s** (LPDDR5X-8533) | TB 5 + RDMA (`~3 µs` latência) | **6 GB** (32–128 GB RAM) |
| **M5 Max** | **460 – 614 GB/s** (GPU 32 / 40 núcleos) | TB 5 + RDMA (`~3 µs` JACCL) | **6 GB** (36–128 GB RAM) |
| **M1–M2 Ultra / M3 Ultra** | **800 – 819 GB/s** (UltraFusion) | TB 4 / TB 5 RDMA (JACCL) | **8 GB** (≥ 96 GB RAM) |
| **M5 Ultra** | **1,2 TB/s** (~1.228 GB/s, até 512 GB RAM, GPU 80 núcleos) | TB 5 RDMA (`JACCL`) | **8 GB** (96–512 GB RAM) |

> [!NOTE]
> **Disponibilidade do M6:** A Apple lançou o chip base **M6** de 2 nm (N2) (`153–170 GB/s`) em set./out. de 2026; **M6 Pro, M6 Max e M6 Ultra** **ainda não foram lançados** até novembro de 2026 (os MacBook Pro e Mac Studio topo de gama continuam com M5 Pro, M5 Max e M5 Ultra). A deteção aberta `M1–M12+` do SS-CCC reconhecerá automaticamente os futuros M6 Pro/Max/Ultra assim que chegarem ao mercado.

### 2. Thunderbolt 5 RDMA (`JACCL`), proteção de memória e repartição ponderada

![Thunderbolt 5 RDMA JACCL e proteção de memória](docs/images/ssccc_tb5_rdma_jaccl.jpg)

- **RDMA no macOS sobre Thunderbolt 5:** Com `rdma_ctl enable` (macOS 26.2+) e o motor `JACCL` (`mlx.distributed`), a latência entre nós desce de `~300 µs` (TCP/IP) para **`~3 µs`** com **`3,5–3,8 GB/s`** de débito sustentado.
- **Nunca alocar 100 % da RAM:** `iogpu.wired_limit_mb` protege a fluidez do macOS e do WindowServer.
- **Repartição proporcional de camadas:** cada Mac recebe camadas consoante a sua memória utilizável (`Camadas_i = Total × Utilizável_i / TotalUtilizável`).
- **Cache KV de 4 bits e sincronização rápida:** `--kv-bits 4` e `MLX_METAL_FAST_SYNCH=1` (45× mais rápido, ~180 µs → ~4 µs).

---

## 🔄 Atualizações controladas pelo GitHub e controlo automático de versões

![Atualizações via GitHub e controlo automático de versões](docs/images/ssccc_github_auto_updater.jpg)

1. **Verificação multifonte no GitHub:** No arranque (após `1,2 s`) e a cada **30 minutos** (`startAutomaticUpdateMonitor()`), `ClusterViewModel` consulta `main/version.json`, `releases/latest` e `commits/main` (SHA curto).
2. **Aviso na aplicação (`UpdatePromptSheet`, `⌘U`):** Quando deteta uma versão, compilação ou SHA mais recente, disponibiliza para instalações a partir do código `git pull --ff-only origin main` + `swift build` + reinício num clique (`scripts/run_ssccc.sh`), ou transferência direta via GitHub Releases.
3. **Automatização CI (`.github/workflows/auto-version-control.yml`):** Cada *push* para `main` executa `scripts/bump_version.py --part patch --sync-git`, sincroniza `version.json` e `ClusterModels.swift`, corre os 14 testes e cria a tag `vX.Y.Z`.

---

---

## 🧠 Multi-Model-Mode (MMM) — Orquestração de Múltiplos Modelos, Fusão de Desempenho e Uso Partilhado de IDE

![Arquitetura Multi-Model-Mode (MMM) SS-CCC e Consumo Multi-IDE](docs/images/ssccc_multi_model_mode.jpg)

O **Multi-Model-Mode (MMM)** — acessível como o **10.º item do menu lateral esquerdo** — agrega o poder de cálculo e a memória unificada de **agrupamentos locais Thunderbolt/RDMA**, **agrupamentos da Internet WAN** ou **agrupamentos híbridos (Local + Internet)** numa superfície de orquestração única e coerente. Em vez de executar um único modelo monolítico por nó, vários modelos e réplicas especializadas trabalham **em paralelo, em cascata ou em consenso** e podem ser consumidos simultaneamente por **múltiplos IDEs e Agent Harnesses** através do endpoint partilhado `:8000/v1`.

### 🎛️ As 4 Estratégias de Orquestração

1. **Ensemble / Consensus (Votação Multi-Modelo)**
   - Envia o mesmo prompt simultaneamente a vários modelos distribuídos (por ex., `Qwen3-Coder-30B` no nó local TB5 + `DeepSeek-R1-Distill` num nó parceiro WAN + `Llama-3.3-70B` em shard híbrido) e sintetiza uma resposta verificada por consenso.
   - Ideal para auditorias críticas, decisões de arquitetura e deteção de alucinações.

2. **Pipeline / Cascade (Especialista por Fase)**
   - Encadeia modelos com diferentes tamanhos e pontos fortes numa linha de produção ordenada: um modelo rápido de triagem/planeamento local encaminha sub-tarefas para modelos grandes de raciocínio ou programação na malha híbrida e entrega a um modelo compacto de validação/formatação.
   - Reduz drasticamente o tempo até ao primeiro token (**TTFT**) mantendo máxima profundidade de raciocínio.

3. **Specialist Router (Encaminhamento Inteligente por Tipo de Tarefa)**
   - Classifica pedidos recebidos do IDE/Harness (`code_edit`, `refactor`, `test_gen`, `reasoning`, `vision`, `docs`) e encaminha cada pedido para o modelo mais rápido e adequado do agrupamento.
   - Os ganhos de latência e débito são medidos em tempo real e enviados diretamente para **🔬 Ciência & Desempenho (Modelo Roofline)**.

4. **Parallel Fan-Out (Execução Simultânea Multi-Fluxo & Multi-Réplica)**
   - Divide grandes conjuntos de ficheiros, suítes de testes ou fluxos de trabalho de agentes paralelos por vários nós locais e WAN ao mesmo tempo, combinando o débito agregado (`tok/s` total do agrupamento).

### ⚙️ Configuração Automática em 1 Clique & Editor Pós-Configuração

![Configuração Automática e Editor ao Vivo Multi-Model-Mode (MMM) SS-CCC](docs/images/ssccc_mmm_autosetup_editor.jpg)

Configurar vários modelos no agrupamento é automático e totalmente editável posteriormente:
- **Perfis Auto-Setup em 1 Clique**: Escolha entre **Coding & IDE Swarm**, **Consenso & Auditoria**, **Turbo (Draft + Target)** ou **Pipeline por Etapas**. O MMM deteta automaticamente nós disponíveis, VRAM utilizável (`iogpu.wired_limit_mb`) e modelos ativos.
- **Personalização Pós-Configuração Completa**: Reordene etapas (`Subir`/`Descer`), duplique réplicas noutros nós, ative/desative slots ou edite em linha o nome, ID do modelo, URL do endpoint (`:8000/v1`, `:11434/v1`) e limite de VRAM.
- **Otimizador VRAM-Fit & Persistência JSON**: Ajuste os slots ativos ao orçamento de VRAM com 1 clique e guarde ou exporte a configuração completa em JSON.

### 🔌 Consumo Partilhado por Múltiplos IDEs & Agent Harnesses (`:8000/v1`)

- **Um agrupamento, múltiplos consumidores**: O **MMM** expõe um proxy compatível com OpenAI em `:8000/v1`, permitindo que **Xcode, VS Code, Cursor, Antigravity, Claude Code, Codex CLI, Goose** e scripts personalizados acedam ao mesmo pool de modelos ao mesmo tempo.
- **Proteção VRAM & Limites de Segurança (`iogpu.wired_limit_mb`)**: Antes de carregar vários modelos em simultâneo, o MMM verifica os limites rígidos de memória do sistema macOS (reservando 4–8 GB por nó para o SO) e impede sobrecargas OOM em topologias locais, WAN e híbridas.
- **Telemetria científica direta**: Cada execução MMM exporta métricas por modelo e agregadas (TTFT, `tok/s`, utilização do barramento RDMA/WAN, eficiência de paralelismo e sobrecarga de orquestração) diretamente para **🔬 Ciência & Desempenho** para análise Roofline e exportação CSV/Markdown.

### 💡 Casos de Utilização Práticos do Multi-Model-Mode (MMM)

1. **Enxame de Programação Multi-IDE em Simultâneo**
   - Enquanto um programador gera código Swift no **Xcode** (modelo local de baixa latência no Mac Studio), uma segunda janela do **Cursor/VS Code** executa revisões de segurança e o **Claude Code** no terminal corre testes unitários — tudo alimentado pelo mesmo agrupamento MMM híbrido sem bloqueios mútuos.
2. **Revisão de Arquitetura e Código por Consenso (Ensemble)**
   - Alterações críticas de infraestrutura ou criptografia são avaliadas em paralelo por 3 modelos distintos (`Qwen3-Coder`, `DeepSeek-R1`, `Mistral-Large`); o MMM compara divergências e destaca riscos antes de aprovar o commit.
3. **Pipeline Híbrido Local + Internet para Projetos de Grande Escala**
   - O agrupamento local **Thunderbolt 5** trata instantaneamente do autocompletar e da indexação de ficheiros (latência < 50 ms), enquanto um agrupamento parceiro **WAN** assume o planeamento profundo e a refatoração de centenas de ficheiros sem saturar os nós locais.
4. **Avaliação Comparativa Científica (Benchmark A/B em Tempo Real)**
   - Um investigador executa o mesmo conjunto de prompts simultaneamente contra 4 modelos quantizados (`4-bit MLX`, `8-bit MLX`, `Q4_K_M`, `FP16`) em modo Fan-Out; o painel **🔬 Ciência & Desempenho** compara automaticamente curvas Roofline, `tok/s` por watt e qualidade de saída.
5. **Orquestração Multimodal (Visão + Código + Documentação)**
   - Um agente de UI envia capturas de ecrã para um modelo VLM dedicado num nó trabalhador, o plano de correção para um modelo de raciocínio e a geração do patch SwiftUI/HTML para um especialista de código — tudo num único fluxo contínuo do MMM.
6. **Balanceamento de Carga em Equipas Distribuídas (Dev-Mesh)**
   - Vários membros de uma equipa ligam os seus Macs locais através do **Agrupamento Internet WAN**; o **Specialist Router** do MMM distribui automaticamente os pedidos dos seus IDEs pelos Macs com maior VRAM livre e menor carga térmica.

---

## 🎙️ Audio-Party de agrupamento e colaboração WAN em direto

![Audio-Party de agrupamento e colaboração WAN em direto](docs/images/ssccc_audio_party_collab.jpg)

- **Voz em tempo real (`AVAudioEngine`, 16 kHz PCM16):** Ligada a `/ws/wan-audio` junto ao chat (`/ws/wan/{room_id}`), com modos **Premir para falar / Microfone aberto**, **Silenciar / Ensurdecer**, medidor de nível e papéis (`Porta de nível 0`, `Nó WAN`).

---

## 🏆 Desafio de recorde mundial: supercomputador híbrido local + Internet

![Desafio de recorde mundial SS-CCC supercomputador híbrido](docs/images/ssccc_world_record_challenge.jpg)

**Conseguirá uma coligação distribuída de computadores Mac Apple Silicon rivalizar com um centro de dados?**  
Convidamos universidades, equipas de investigação e entusiastas de Apple Silicon a organizar uma **tentativa oficial de recorde com o SS-CCC**: reúnam em simultâneo o maior número possível de **agrupamentos locais Thunderbolt 3/4/5/RDMA** e **Mac ligados pela Internet** através da **ponte híbrida («Ligar local + Internet»)**, da **Audio-Party** e do **laboratório científico de 5 separadores**.

### 🔬 Protocolo científico e modelação

1. **Topologia hierárquica em dois níveis (ilhas locais TB/RDMA + rede WAN):**
   - A ponte híbrida mantém camadas consecutivas nas ilhas Thunderbolt locais (`~0,07 ms`, `30–110 Gbps`), restringindo os saltos WAN às transições entre portas de nível 0 ($H_{\text{WAN}} \ll N_{\text{total}}$).
2. **Ocultação da latência WAN ($B^*$) e compressão de ativações:**
   - Com $\Phi_{\text{bolha}} = \frac{N - 1}{M + N - 1}$ e o lote crítico $B^* = \lceil \frac{T_{\text{RTT,WAN}} + T_{\text{tx}}}{T_{\text{comp}}(B=1)} \rceil$, os micro-lotes $M \to B^*$ e a compressão **FP8 / INT4 / Top-K** (*Petals / SWARM*) mantêm a sobrecarga abaixo de $1\%$ da ligação de envio.
3. **Protocolo reprodutível ($T = 0,0$):** Ative a ponte híbrida, entre na **Audio-Party** (`Opus 16 kbps`, $<0,02\%$ da ligação), execute `N = 20` ensaios (`T = 0,0`) em modo **Internet-WAN** e exporte o **manifesto JSON**, **CSV** e a **tabela LaTeX (`booktabs`)** com `IC₉₅`, `Goodput%`, `J/token`, `EDP` e `gCO₂eq/1M tokens`.

![Laboratório científico de 6 separadores e histórico](docs/images/ssccc_history_telemetry_lab.jpg)

### 🥇 Categorias de recorde e casos de utilização

![Casos de utilização e públicos do SS-CCC](docs/images/ssccc_use_cases_showcase.jpg)
- **Categorias:** maior memória unificada total (`TB`), maior número de Mac ligados em simultâneo ($N \ge 32\text{–}256+$), maior débito útil transcontinental e melhor eficiência energética (`J/token`).
- **Casos de utilização:** investigação em sistemas de IA (curvas Roofline, *DiLoCo* vs. DDP, artigos LaTeX/BibTeX), laboratórios universitários com portáteis e Mac mini, estúdios de software para **OpenCode / Cursor / Xcode** sem custos na nuvem, setores jurídicos e médicos sob túnel **WireGuard**, maratonas globais coordenadas via **Audio-Party** e auditorias **Green-AI**.

---

## 🚀 Atualização de Arquitetura SOTA 2026 (Fase 11)

- **TB5 RDMA Tensor Parallelism & QUIC / Iroh WAN:** Alterne entre **Pipeline Ring** e **JACCL Full-Mesh TP** (`ClusterMeshTopology`), execute verificações `rdma_ctl enable` + `bridge0`, exporte `mlx.distributed_config` em JSON e ative **QUIC / Iroh P2P (0-RTT Multiplex)** sem bloqueio TCP HoL.
- **Prefill/Decode Desagregado (ANE-Split) & KV-Cache de 3 Camadas / CacheGen:** Transfira o *prefill* para o Apple Neural Engine (ANE) mantendo o *decode* na GPU MLX (`EDP ×1,42`, `-31,5 %` energia), com compressão **CacheGen (`3,6×`)** e telemetria de acerto de prefixo.
- **MMM Next-Gen (EAGLE-3, Tree-MoA Early-Exit & Roteador Adaptativo):** Fusão **EAGLE-3**, limiar de confiança **Tree-MoA Early-Exit** (`50–95 %`) e **Adaptive Confidence Escalation (Ares)** integrados no Modo Multimodelo.
- **Padrões Modernos de Agentes e Gateway:** Pré-visualização e exportação de **OpenAI `/v1/responses` + MCP**, **MCP Server Registry JSON** e **A2A Agent Card** (`/.well-known/agent.json`).
- **Agendamento Térmico e Consciente de Carbono:** Desprioriza automaticamente nós em estado térmico `.serious`/`.critical` e prioriza eficiência energética.
- **Fase 12 — Auto-Setup de Cluster (`Configuração e Setup`), Prontidão & Shorttips:** 11.ª categoria lateral para detetar e configurar automaticamente Local/WAN/Híbrido, reportar **Pronto / Não pronto / Incompleto / Não configurado** (também na Visão Geral), exibir *Shorttips* ao passar o rato nos 8 idiomas, abrir ajuda interativa ao clicar e operar com telemetria real em direto ao desativar a simulação.

![Configuração Auto e Prontidão Operacional](docs/images/i18n/ssccc_setup_readiness_pt.jpg)

---

## 📁 Estrutura do repositório

```text
├── app/Sources/
│   ├── SSCCCApp.swift              # Janela principal, aviso de atualização e UpdatePromptSheet
│   ├── Models/
│   │   ├── ClusterModels.swift     # Inferência M1–M12+, modelos WAN/Ciência/Histórico e versões
│   │   └── Localization.swift      # Dicionário completo em 8 idiomas (EN/DE/FR/ES/PT/RU/JA/ZH)
│   ├── ViewModels/
│   │   └── ClusterViewModel.swift  # Sondagem de hardware, modelos, Audio-Party WAN e atualizador GitHub
│   └── Views/                      # 12 vistas SwiftUI modulares + Theme.swift (11 separadores laterais, Setup, ajuda interativa, faixas e brilho)
├── core/                           # Gateway Python FastAPI, retransmissores WebSocket WAN/Áudio e MLX
├── scripts/
│   ├── run_ssccc.sh                # Compila e inicia a aplicação macOS
│   ├── bump_version.py             # Sincroniza version.json e ClusterModels.swift com Git
│   ├── setup_tb_network.sh         # Configura a ponte Thunderbolt 10.99.1.x
│   └── setup_wired_limit.sh        # Aplica limites seguros de iogpu.wired_limit_mb
├── tests/                          # Conjunto de verificação global de 24 testes (Swift + Python)
├── .github/workflows/              # Controlo automático de versões CI e etiquetagem
└── version.json                    # Manifesto de controlo de atualizações alojado no GitHub
```

---

## 🚧 Estado de desenvolvimento e colaboração

> [!IMPORTANT]
> **O SS-CCC (v1.6+) é totalmente executável e validado por `24/24` testes automatizados; os ensaios de resistência multinó continuam.**
> **Já implementado e verificado:** idioma inicial em inglês com 8 idiomas (`EN/DE/FR/ES/PT/RU/JA/ZH`), **barra lateral de 11 separadores** incl. **Configurar e Provisionar**, **visão geral em 3 separadores**, **faixas industriais de aviso amarelo-preto** e **realce luminoso Solaris**, deteção aberta M1–M12+ (incl. M5 Max/Ultra e M6), telemetria real em direto (sem dados fictícios ao desativar a simulação), descoberta em tempo real de modelos (oMLX / Ollama / llama.cpp / GGUF), laboratório científico de 6 separadores, ponte híbrida Local ↔ Internet-WAN, Audio-Party com `AVAudioEngine`, **manual interativo de 12 capítulos**, **Shorttips em 8 idiomas** e atualização automática controlada via GitHub + CI.

Convidamos programadores, investigadores e entusiastas de Apple Silicon a **participar no desenvolvimento e a fazer evoluir o SS-CCC**:
- **Testar no seu equipamento:** Experimente o SS-CCC nos seus Mac M1–M12+ e partilhe medições de débito, memória e RDMA/JACCL.
- **Participar no desafio de recorde:** Ligue ilhas TB locais a nós WAN e publique os seus manifestos JSON/CSV/LaTeX.
- **Enviar melhorias:** Contributos para a interface SwiftUI, para a repartição MLX, para os guiões Thunderbolt ou para as traduções são sempre bem-vindos!

---

## 📄 Licença

Publicado sob a [Licença MIT](LICENSE.md).
