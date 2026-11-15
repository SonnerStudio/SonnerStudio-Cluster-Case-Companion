<div align="center">

# ☀️ SonnerStudio Cluster-Case-Companion (SS-CCC)

<img src="docs/images/flags/us.png" width="20" height="16" alt="US"/> <img src="docs/images/flags/gb.png" width="20" height="16" alt="GB"/> <img src="docs/images/flags/ca.png" width="20" height="16" alt="CA"/> **[English](README.md)** · <img src="docs/images/flags/de.png" width="20" height="16" alt="DE"/> <img src="docs/images/flags/at.png" width="20" height="16" alt="AT"/> <img src="docs/images/flags/ch.png" width="20" height="16" alt="CH"/> **[Deutsch](README.de.md)** · <img src="docs/images/flags/fr.png" width="20" height="16" alt="FR"/> <img src="docs/images/flags/be.png" width="20" height="16" alt="BE"/> <img src="docs/images/flags/ch.png" width="20" height="16" alt="CH"/> **[Français](README.fr.md)** · <img src="docs/images/flags/es.png" width="20" height="16" alt="ES"/> <img src="docs/images/flags/mx.png" width="20" height="16" alt="MX"/> <img src="docs/images/flags/ar.png" width="20" height="16" alt="AR"/> **[Español](README.es.md)** · <img src="docs/images/flags/pt.png" width="20" height="16" alt="PT"/> <img src="docs/images/flags/br.png" width="20" height="16" alt="BR"/> **[Português](README.pt.md)** · <img src="docs/images/flags/ru.png" width="20" height="16" alt="RU"/> **[Русский](README.ru.md)** · <img src="docs/images/flags/jp.png" width="20" height="16" alt="JP"/> **[日本語](README.ja.md)** · <img src="docs/images/flags/cn.png" width="20" height="16" alt="CN"/> **[中文](README.zh.md)**

*原生 macOS Apple Silicon 集群管理器与分布式 MLX 推理工作室*

<table>
  <tr>
    <td align="center">
      <img src="docs/images/ssccc_cluster_52gb.png" alt="SS-CCC 52 GB 集群模式" width="100%"/><br/>
      <sub><b>集群模式 (52 GB 统一内存池 · 2 节点)</b></sub>
    </td>
    <td align="center">
      <img src="docs/images/ssccc_single_16gb.png" alt="SS-CCC 16 GB 单机模式" width="100%"/><br/>
      <sub><b>单机模式 (16 GB 本地 · 1 节点)</b></sub>
    </td>
  </tr>
</table>

</div>

---

## 🧭 概览

**SonnerStudio Cluster-Case-Companion (SS-CCC)** 是一款原生 macOS (SwiftUI) 桌面应用与 Python/FastAPI 控制网关，可通过 **Thunderbolt 3/4/5 (RDMA / JACCL)**、**10GbE 局域网** 与 **全球互联网 (WAN)** 将多台 **Apple Silicon Mac (M1–M12+)** 聚合为统一的显存池与分布式 MLX 推理集群。

无需将源码或敏感文档上传至云端，本地 AI 智能体与 IDE（**OpenCode**、**Hermes Agent**、**Google Antigravity**、**Cursor**、**Continue**、**Xcode**）均可直接连接 `http://127.0.0.1:8000/v1`。

---

## 🌐 全球互联网集群、实时聊天与科学 Roofline 分析

<table>
  <tr>
    <td align="center" width="50%">
      <img src="docs/images/ssccc_internet_wan_mesh.jpg" alt="全球互联网 Mac 集群与实时聊天" width="100%"/><br/>
      <sub><b>全球互联网 Mac 集群 (WAN)、混合耦合与参与者聊天</b></sub>
    </td>
    <td align="center" width="50%">
      <img src="docs/images/ssccc_science_roofline_hero.jpg" alt="科学 Roofline 与 Splitwise 遥测" width="100%"/><br/>
      <sub><b>Roofline 分析 (Williams)、Splitwise 阶段解耦、能耗 (J/tok) 与 p50/p95/p99</b></sub>
    </td>
  </tr>
</table>

SS-CCC 通过 **Tailscale / WireGuard、ZeroTier、libp2p QUIC 与 DERP 中继**（`/ws/wan/{room_id}`、`/ws/wan-chat`、`/ws/wan-audio`）将本地 Thunderbolt 集群与远程节点无缝连接。

---

## 🏗️ 混合架构（控制平面、Thunderbolt 与 WAN）

<div align="center">
  <img src="docs/images/ssccc_ecosystem_banner.jpg" alt="SS-CCC 混合架构图" width="100%"/>
</div>

- **控制平面 (LAN / Wi-Fi):** 节点发现、OpenAI/Anthropic/Ollama 兼容接口 (`:8000`) 与健康监测。
- **数据平面 (Thunderbolt 3/4/5 + RDMA):** 基于 `10.99.1.x` 的隔离张量传输（TB4 为 `30–37 Gbps`，TB5 RDMA JACCL 双向最高 `160 Gbps` / `~3 µs` 延迟）。
- **互联网 WAN 层:** 通过微批次 (`M ≥ 4`) 隐藏跨网延迟，支持 `405B–671B+` 超大模型。

---

## ✨ 核心功能

![本地 AI 智能体与 IDE 生态](docs/images/ssccc_agents_ide_ecosystem.jpg)

- **全系列 Apple Silicon 支持 (M1–M12+):** 涵盖 Mac mini、MacBook Air/Pro、iMac、Mac Studio 与 Mac Pro。
- **加权流水线分片 (`MemoryWeightedPlanner`):** 内存带宽最高的 Mac 自动担任 **Rank 0（协调器）** 并持有 Embeddings + LM-Head；各工作节点按可用内存比例分担层数。
- **内存安全保护 (`iogpu.wired_limit_mb`):** 每台 Mac 自动预留 4–8 GB 给 macOS 与 WindowServer，防止 OOM 崩溃。
- **运行时支持:** `MLX` (`mlx.distributed` / `JACCL`)、`oMLX`（端口 `8000`，SSD 分页 KV 缓存）、`Ollama` (`11434`)、`llama.cpp` (`8080`)。
- **一键集成:** OpenCode、Hermes Agent、Google Antigravity、Cursor、VS Code、Xcode。
- **8 种语言界面:** English、Deutsch、Français、Español、Português、Русский、日本語、中文。

---

## 🧩 核心新特性（10 大侧边栏模块与多模型协同模式）

- **多模型协同模式 (Multi-Model-Mode / MMM，第 10 项菜单)：** 在**本地集群**、**互联网 WAN 集群**或**混合集群（本地 + 互联网）**中聚合多个模型的算力（支持 *Parallel Pool*、*Mixture-of-Agents*、*Speculative Draft+Target*、*Sequential Pipeline*），内置 `iogpu.wired_limit_mb` 显存保护，并支持 **多个 IDE 与智能体框架（Cursor, VS Code, Xcode, OpenCode, Hermes, Antigravity）同时通过 `:8000/v1` 共享调用集群算力**。
- **互联网带宽与 WAN 吞吐量监控：** 通过 `netstat`、ICMP Ping/抖动与 `/usr/bin/networkQuality -c` 实时测量上下行带宽并计算对集群推理效率的影响。
- **Science & Roofline 真实数据与 MMM 科学评估联动：** 实测模式采用真实 SSE 流式首字延迟与 ICMP RTT 测量，模拟模式提供清晰标注的逼真 Apple Silicon 参考值；**多模型协同模式 (MMM) 的加速比、聚合 `tok/s`、VRAM 效率与多 IDE 负载数据**会自动汇入科学评估面板与历史记录。

---

## 🛠️ 从源码编译（首次运行前必读）

> **说明：** 本仓库仅包含源代码、脚本与文档，不包含预编译二进制文件。

```bash
git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
cd SonnerStudio-Cluster-Case-Companion
chmod +x scripts/*.sh
"./scripts/run_ssccc.sh"
```

---

## 🚀 快速开始

```bash
# 1. 启动原生 SwiftUI 应用
"./scripts/run_ssccc.sh"

# 2. (可选) 启动 Python/FastAPI 网关
cd core && uv sync --extra dev
PYTHONPATH=".." uv run uvicorn core.api.gateway:app --host 0.0.0.0 --port 8000

# 3. 配置 Thunderbolt 点对点 IP
./scripts/setup_tb_network.sh studio   # 10.99.1.1
./scripts/setup_tb_network.sh mini     # 10.99.1.2
```

---

## 📖 使用指南：本地与混合（本地 + 互联网）集群配置、模型加载机制与理论性能数据

### 1. 本地集群搭建 (Thunderbolt 3/4/5 与 LAN)
1. **物理连接：** 使用 **Thunderbolt 3/4/5 线缆**（点对点、环形或网状）和/或 **10GbE 以太网** 直连多台 Mac。
2. **分配点对点 IP：** 在主节点运行 `./scripts/setup_tb_network.sh studio` (`10.99.1.1`)，在工作节点运行 `./scripts/setup_tb_network.sh mini` (`10.99.1.2` 等)。
3. **可选 RDMA（macOS 26.2+ TB5）：** 启用 `rdma_ctl enable`，让 `JACCL` (`mlx.distributed`) 节点间延迟从 `~300 µs` (TCP/IP) 降至 **`~3 µs`**。
4. **自动分配 Rank：** 在 **设备与对比** 中添加所有 Mac。内存带宽最高的 Mac 自动成为 **Rank 0（协调器）**，其余成为 **Rank 1..N（工作节点）**。

### 2. 混合集群网络搭建（本地 + 互联网 WAN 同时在线）
1. **本地高速核心 (Tier 1)：** 保持本地 Thunderbolt/LAN 环网 (`10.99.1.x` / `192.168.x.x`) 运行，承载高敏感度层。
2. **WAN 协调器房间 (Tier 2)：** 在 **互联网集群与聊天** 创建 WAN 房间（`/ws/wan/{room_id}`，端口 `8000`，可通过 Tailscale、WireGuard、Cloudflare Tunnel 或反向代理暴露）。
3. **远程节点加入：** 全球任意 Mac 凭 **房间号 + 加入令牌** 作为 WAN 工作节点接入。
4. **两级混合路由：** 高频层留在本地环网 (`3–180 µs`)，溢出层通过微批次 (`M ≥ 4`) 调度至 WAN 节点 (`15–120 ms` RTT)。

### 3. 由谁加载模型？能同时加载多少个模型？请求如何流转？
- **由谁加载什么？**
  - **协调器 (Rank 0)：** 提供 API 网关 (`:8000`) 与分词，**始终持有 Embeddings 与 LM-Head (`has_embeddings=True`, `has_lm_head=True`)** 及按比例分配的 Transformer 层 (`Layers_i = TotalLayers × Usable_i / TotalUsable`)。
  - **工作节点 (Rank 1..N)：** 每个节点仅从本地 HuggingFace/oMLX/Ollama 缓存（`~/.cache/huggingface`, `~/.ollama/models`, `~/Models`）加载 **分配给自己的 Safetensors/层切片 `[start_layer .. end_layer)`**，绝不浪费内存。
- **最多可同时加载多少个模型？**
  - **分布式集群模式 (`mlx.distributed` / `JACCL`)：** 整个聚合内存池每次运行 **1 个大型分片模型**（支持快速热切换）。
  - **多模型并行模式 (`oMLX` / `Ollama` / 异构节点)：** 只要满足 `Σ (模型权重_i + KV_Cache_i) ≤ 总可用_VRAM_GB`（扣除 `iogpu.wired_limit_mb` 预留的 4–8 GB），即可 **同时常驻多个模型**（例如：**32B 编程模型 + 8B 快速路由 + 1.5B 向量模型**）。
- **端到端请求流程：**
  1. **硬件探测与链路选择** (`TB5 RDMA > TB Bridge > 10GbE > WLAN > WAN`)
  2. **分片规划** (`hostfile.json` 与 `iogpu.wired_limit_mb` 保护)
  3. **API 接入** (`http://127.0.0.1:8000/v1/chat/completions`, `/v1/messages`, `/api/chat`)
  4. **Prefill 阶段 (`TTFT`)：** Rank 0 编码提示词并沿流水线传递激活值 (`Rank 0 → 1 → ... → N → Rank 0`)
  5. **Decode 阶段 (`TPOT` 与 `tok/s`)：** 配合 `--kv-bits 4` 与 `MLX_METAL_FAST_SYNCH=1` 逐 token 生成
  6. **SSE 流式输出与遥测记录**

### 4. 不同应用场景的理论容量与性能参考

> **解析估算公式：**
> - **显存需求：** `VRAM_GB ≈ 参数量_B × (Bits / 8) × 1.15 + KV_Cache_GB`
> - **Decode 理论上限：** `tok/s ≈ (有效带宽_GB/s / 活跃权重_GB) × (1 − 通信开销)`

| 应用场景 | 拓扑与可用内存池 | 典型模型与量化 | 理论 `TTFT` (2k prompt) | 理论 Decode (`tok/s` / `TPOT`) | 能耗与主要瓶颈 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. 单机工作站 (Edge Dev)** | 1× Mac mini M4 (16 GB, `12 GB` 可用, `120 GB/s`) | `Qwen2.5-14B` (`4-bit`, ~8.8 GB) | `~1.8 – 2.6 s` | **`11 – 14 tok/s`** (`~75 ms/tok`) | `~1.7 J/tok` · 内存带宽 |
| **2. 单台 Pro Studio (高速编程)** | 1× Mac Studio M4 Max (64 GB, `58 GB` 可用, `546 GB/s`) | `Llama-3.3-70B` (`4-bit`, ~40 GB) | `~1.1 – 1.7 s` | **`12 – 14 tok/s`** (`~74 ms/tok`) | `~3.8 J/tok` · 内存带宽 |
| **3. 本地双节点 TB5 RDMA 环** | 2× M4 Max 64 GB (`116 GB` 可用, `~1,092 GB/s` 聚合, `~3 µs` JACCL) | `Qwen2.5-Coder-72B` (`8-bit`, ~78 GB) | `~1.4 – 2.0 s` | **`12 – 14 tok/s`** (`~76 ms/tok`) | `~7.5 J/tok` · RDMA 同步开销极低 |
| **4. 实验室 4 节点 Ultra TB5 RDMA** | 4× M3 Ultra 256 GB (`992 GB` 可用, `~3.27 TB/s` 聚合) | `DeepSeek-V3 671B MoE` (`4-bit`, ~385 GB, ~37B 活跃) | `~2.2 – 3.5 s` | **`38 – 55 tok/s`** (`~20 ms/tok`) | `~5.2 J/tok` · MoE 活跃专家带宽 |
| **5. 混合 办公室 LAN + 家庭 WAN** | 2× TB4/10GbE + 2× WAN (`192 GB` 可用, `35 ms` WAN RTT) | `Llama-3.1-405B` (`3/4-bit`, ~170 GB) | `~6 – 11 s` | **`2.2 – 4.5 tok/s`** (`~280 ms/tok`) | `~28 J/tok` · WAN 延迟 (`M=8` 缓解) |
| **6. 全球社区 WAN 集群** | 16+ Mac 全球互联 (`1.5+ TB` 可用, `60–120 ms` WAN RTT) | `671B–1T+` Frontier (`4/8-bit`) | `~12 – 25 s` | **`1.2 – 3.0 tok/s`** (`~500 ms/tok`) | WAN 延迟（批处理可扩展吞吐） |

---

## 📚 文档中心与 Thunderbolt 5 RDMA (`JACCL`)

![Thunderbolt 5 RDMA JACCL 与内存安全](docs/images/ssccc_tb5_rdma_jaccl.jpg)

完整 9 章用户手册已内置于应用的 **帮助与手册** 标签页中。

---

## 🔄 GitHub 托管更新与自动版本控制

![GitHub 自动更新与版本控制](docs/images/ssccc_github_auto_updater.jpg)

- **每 30 分钟自动检测：** 比对 `version.json`、GitHub Releases 与 `main` 分支提交 SHA。
- **一键更新：** 应用内直接执行 `git pull` + `swift build` + 一键重启。
- **CI Auto-Bump：** 推送至 `main` 时由 GitHub Actions 自动递增构建号。

---

## 🎙️ 集群 Audio-Party 语音派对与实时 WAN 协作

![集群 Audio-Party 与实时聊天](docs/images/ssccc_audio_party_collab.jpg)

内置基于 `AVAudioEngine 16 kHz PCM16 · /ws/wan-audio` 的主机风格语音派对。

---

## 📊 科学实验室 (6 个标签页) 与历史记录

![科学实验室与历史记录](docs/images/ssccc_history_telemetry_lab.jpg)

支持按单指标或全局自动/手动录制，并导出 `CSV / JSON / LaTeX / BibTeX`。

---

## 🏆 世界纪录挑战：本地 + 全球混合超级集群

![SS-CCC 世界纪录挑战](docs/images/ssccc_world_record_challenge.jpg)

**由分散在全球各地的 Apple Silicon Mac 组成的去中心化联盟，能否媲美数据中心超级计算机？**  
我们诚挚邀请全球高校、AI 研究实验室、开发者社区与 Apple Silicon 爱好者共同组织官方 **SS-CCC 混合超级集群世界纪录挑战** —— 利用 SS-CCC 的 **混合桥接（本地 + 互联网耦合）**、**Cluster Audio-Party** 与 **6 标签页科学实验室**，同时联合尽可能多的 **本地 Thunderbolt 3/4/5/RDMA 集群** 与 **互联网 WAN Mac**。

### 🔬 科学原理与数学扩展模型

1. **两级分层拓扑（Tier-0 本地 TB/RDMA 集群岛 + Tier-1 WAN 骨干网）：**
   - 扁平化的互联网集群会在每一层边界都跨越广域网高延迟链路 ($H_{\text{WAN}} = N - 1$)，导致吞吐急剧下降。
   - 通过 **SS-CCC 混合桥接**，连续的 Transformer 层保留在高速本地 Thunderbolt 集群岛内（`~0.07 ms` 延迟，`30–110 Gbps`），将跨网通信严格限制在少数 **岛间 Rank 0 网关交接** ($H_{\text{WAN}} \ll N_{\text{total}}$)。
2. **通过临界微批次 ($B^*$) 与激活压缩隐藏 WAN RTT：**
   - 流水线效率遵循 GPipe 气泡公式：
     $$\Phi_{\text{bubble}} = \frac{N - 1}{M + N - 1}, \qquad B^* = \left\lceil \frac{T_{\text{RTT,WAN}} + T_{\text{tx}}}{T_{\text{comp}}(B=1)} \right\rceil$$
   - 将微批次深度 $M$ 提升至 $B^*$ 可在并发流水线执行中掩盖跨洲际往返延迟，同时 **FP8 / INT4 / Top-K 激活压缩** (*Petals / SWARM*) 将每跳通信负载压低至常规 WAN 上行带宽的 $1\%$ 以下。
3. **标准化可复现纪录协议 ($T = 0.0$)：**
   1. **组建 Tier-0 本地岛：** 通过 Thunderbolt 3/4/5 连接本地 M1–M9+ Mac（启用 `MLX_METAL_FAST_SYNCH=1`）。
   2. **桥接与协同：** 启用 **混合桥接**，分享 `SSCCC-WAN-…` 房间号，并加入 **Cluster Audio-Party**（`Opus 16 kbps`，WAN 占用 $<0.02\%$）同步层划分。
   3. **执行测试：** 在 **科学与 Roofline** 中切换至 **Internet-WAN**，运行 `N = 20` 次试验（丢弃 `1` 次预热，`T = 0.0`），验证目标 SLO（`TTFT ≤ 2500 ms`，`TPOT ≤ 100 ms/tok`）。
   4. **归档验证：** 导出并公开包含 `hardware_fingerprint`、`TTFT/TPOT (p50/p95/p99 ± CI₉₅)`、`CV%`、`Goodput%`、`J/tok`、`EDP` 与 `gCO₂eq/1M tok` 的 **JSON 可复现清单**、**CSV 日志** 与 **LaTeX (`booktabs`) 表格**。

![科学实验室与历史记录](docs/images/ssccc_history_telemetry_lab.jpg)

### 🥇 官方纪录类别
- **最大统一内存池：** 本地与 WAN 耦合后可支配的最大总可用 VRAM (`GB` / `TB`)。
- **最多同时耦合 Mac 数量 ($N$)：** 成功完成有效 `N = 20` 试验的最大活跃网格（`32–256+` 节点）。
- **最高跨洲混合 Goodput：** 横跨 $\ge 2$ 个大洲且满足交互式 SLO 的最高 `tokens/s`。
- **最佳集群能效：** `70B+` 参数规模模型下的最低 `Joules/token` 与 `EDP (J·s)`。

---

## 🎯 应用场景与目标用户

![SS-CCC 应用场景展示](docs/images/ssccc_use_cases_showcase.jpg)

| 用户群体 | SS-CCC 实际应用场景 |
| :--- | :--- |
| **AI 系统与 ML 研究人员** | 对比本地与 WAN 的 Roofline 极限 ($P = \min(\beta \cdot I, \pi_{\text{eff}})$)、*Petals/SWARM* 压缩、*DiLoCo* 与 DDP 通信开销，并将 `CI₉₅` + `LaTeX`/`BibTeX` 直接导出至论文。 |
| **高校与教学科研实验室** | 跨校园局域网与家庭宽带聚合学生 MacBook 与实验室 Mac mini，通过 **Audio-Party** 协作组建共享 `70B–405B+` 教学集群。 |
| **软件工作室与智能体团队** | 在现有办公 Mac 上零云端费用运行私有编程大模型，直接驱动 **OpenCode**、**Hermes Agent**、**Antigravity**、**Cursor**、**VS Code** 与 **Xcode**。 |
| **隐私优先的医疗、法律与研发** | 敏感文档严格留在本地内网或加密 **WireGuard / Tailscale** 隧道中，杜绝任何第三方 API 遥测或数据外泄。 |
| **全球开源计算群与黑客松** | 数分钟内跨国组建临时超级集群，通过主机风格语音派对协调分工并冲击社区规模纪录。 |
| **绿色 AI 与可持续能效审计** | 对比不同电网碳强度（挪威水电 vs 欧美电网）下的 `J/token`、`EDP` 与 `gCO₂eq/1M tokens`，全面对标数据中心 GPU API。 |

---

## 📁 仓库结构

```text
├── app/Sources/
│   ├── SSCCCApp.swift              # 主窗口、顶部更新胶囊与 UpdatePromptSheet
│   ├── Models/
│   │   ├── ClusterModels.swift     # M1–M12+ 芯片推断、WAN/科学/历史与版本模型
│   │   └── Localization.swift      # 完整 8 种语言界面与帮助词典 (EN/DE/FR/ES/PT/RU/JA/ZH)
│   ├── ViewModels/
│   │   └── ClusterViewModel.swift  # 硬件探测、模型发现、WAN/Audio-Party 与 GitHub 更新器
│   └── Views/                      # 9 个模块化 SwiftUI 视图 + Theme.swift（3 标签页集群概览、黄黑工业警示条纹、6 标签页科学实验室与帮助）
├── core/                           # Python FastAPI 网关、WebSocket WAN/音频中继与 MLX 分片
├── scripts/
│   ├── run_ssccc.sh                # 编译并启动 macOS 应用
│   ├── bump_version.py             # 将 version.json 与 ClusterModels.swift 同步至 Git
│   ├── setup_tb_network.sh         # 配置 10.99.1.x Thunderbolt 桥接网络
│   └── setup_wired_limit.sh        # 应用安全的 iogpu.wired_limit_mb 内存上限
├── tests/                          # 14 项全局自动化测试套件 (Swift + Python)
├── .github/workflows/              # 自动 CI 版本控制与打标
└── version.json                    # 托管于 GitHub 的更新控制清单
```

---

## 🚧 开发状态与诚邀参与

> [!IMPORTANT]
> **SS-CCC (v1.6+) 已可完整编译运行并通过全部 `14/14` 项自动化测试；异构多节点长时间稳定性压测仍在持续推进。**
> **已实现并验证：** 英文默认启动与 8 语言即时切换 (`EN/DE/FR/ES/PT/RU/JA/ZH`)、**3 标签页集群概览**（**本地集群**、包含区域与本地子集群的 **互联网集群** 以及 **本地 + 互联网** 混合视图）、覆盖 6 大核心界面的 **黄黑斜纹工业警示条 (`HazardStripesBar` / `IndustrialHazardBanner`)**、开放式 M1–M12+ 硬件探测、实时模型发现 (oMLX / Ollama / llama.cpp / GGUF)、带单指标与全局历史记录的 6 标签页科学实验室、本地 ↔ 互联网 WAN 混合耦合、`AVAudioEngine` 集群 Audio-Party、9 章内置帮助中心以及由 GitHub + CI 驱动的自动更新机制。

我们热忱邀请开发者、研究人员与 Apple Silicon 爱好者 **共同参与并推动 SS-CCC 不断完善**：
- **在您的硬件上实测：** 在 M1–M12+ Mac 上运行 SS-CCC，并分享吞吐量、显存占用及 RDMA/JACCL 稳定性数据。
- **加入混合世界纪录挑战：** 将本地 Thunderbolt 集群与 WAN 节点联合，发布导出的 JSON / CSV / LaTeX 验证清单。
- **提交 Pull Request：** 无论是 SwiftUI 界面优化、Python/MLX 分片策略、Thunderbolt 脚本还是多语言翻译改进，我们都非常欢迎！

---

## 📄 许可证

基于 [MIT 许可证](LICENSE.md) 发布。
