<div align="center">

# ☀️ SonnerStudio Cluster-Case-Companion (SS-CCC)

<img src="docs/images/flags/us.png" width="20" height="16" alt="US"/> <img src="docs/images/flags/gb.png" width="20" height="16" alt="GB"/> <img src="docs/images/flags/ca.png" width="20" height="16" alt="CA"/> **[English](README.md)** · <img src="docs/images/flags/de.png" width="20" height="16" alt="DE"/> <img src="docs/images/flags/at.png" width="20" height="16" alt="AT"/> <img src="docs/images/flags/ch.png" width="20" height="16" alt="CH"/> **[Deutsch](README.de.md)** · <img src="docs/images/flags/fr.png" width="20" height="16" alt="FR"/> <img src="docs/images/flags/be.png" width="20" height="16" alt="BE"/> <img src="docs/images/flags/ch.png" width="20" height="16" alt="CH"/> **[Français](README.fr.md)** · <img src="docs/images/flags/es.png" width="20" height="16" alt="ES"/> <img src="docs/images/flags/mx.png" width="20" height="16" alt="MX"/> <img src="docs/images/flags/ar.png" width="20" height="16" alt="AR"/> **[Español](README.es.md)** · <img src="docs/images/flags/pt.png" width="20" height="16" alt="PT"/> <img src="docs/images/flags/br.png" width="20" height="16" alt="BR"/> **[Português](README.pt.md)** · <img src="docs/images/flags/ru.png" width="20" height="16" alt="RU"/> **[Русский](README.ru.md)** · <img src="docs/images/flags/jp.png" width="20" height="16" alt="JP"/> **[日本語](README.ja.md)** · <img src="docs/images/flags/cn.png" width="20" height="16" alt="CN"/> **[中文](README.zh.md)**

*macOS ネイティブ Apple Silicon クラスターマネージャー & 分散 MLX 推論スタジオ*

<table>
  <tr>
    <td align="center">
      <img src="docs/images/ssccc_cluster_52gb.png" alt="SS-CCC 52 GB Cluster Mode" width="100%"/><br/>
      <sub><b>クラスターモード (52 GB 統合プール · 2 ノード)</b></sub>
    </td>
    <td align="center">
      <img src="docs/images/ssccc_single_16gb.png" alt="SS-CCC 16 GB Standalone Mode" width="100%"/><br/>
      <sub><b>スタンドアロンモード (16 GB ローカル · 1 ノード)</b></sub>
    </td>
  </tr>
</table>

</div>

---

## 🧭 概要

**SonnerStudio Cluster-Case-Companion (SS-CCC)** は、複数の **Apple Silicon Mac (M1–M12+)** を **Thunderbolt 3/4/5 (RDMA / JACCL)**、**10GbE LAN**、および **インターネット WAN** 経由で結合し、統合メモリプールと分散 MLX 推論を実現するネイティブ macOS アプリ (SwiftUI) ＋ コントロールゲートウェイ (Python/FastAPI) です。

ソースコードや機密文書をクラウドへ送信することなく、ローカルの AI エージェントや IDE（**OpenCode**、**Hermes Agent**、**Google Antigravity**、**Cursor**、**Continue**、**Xcode**）を `http://127.0.0.1:8000/v1` に接続できます。

---

## 🌐 世界規模インターネットクラスター、ライブチャット & 科学 Roofline 分析

<table>
  <tr>
    <td align="center" width="50%">
      <img src="docs/images/ssccc_internet_wan_mesh.jpg" alt="世界規模インターネット Mac クラスター" width="100%"/><br/>
      <sub><b>世界規模インターネット Mac クラスター (WAN)、ハイブリッド連携 & 参加者チャット</b></sub>
    </td>
    <td align="center" width="50%">
      <img src="docs/images/ssccc_science_roofline_hero.jpg" alt="科学 Roofline & Splitwise テレメトリ" width="100%"/><br/>
      <sub><b>Roofline 分析 (Williams)、Splitwise フェーズ分離、エネルギー効率 (J/tok) & p50/p95/p99</b></sub>
    </td>
  </tr>
</table>

SS-CCC は **Tailscale / WireGuard、ZeroTier、libp2p QUIC、DERP リレー** 経由でローカル Thunderbolt クラスターと遠隔 Mac をシームレスに接続します（`/ws/wan/{room_id}`、`/ws/wan-chat`、`/ws/wan-audio`）。

---

## 🏗️ ハイブリッド構成（制御プレーン・Thunderbolt・WAN）

<div align="center">
  <img src="docs/images/ssccc_ecosystem_banner.jpg" alt="SS-CCC ハイブリッド構成図" width="100%"/>
</div>

- **制御プレーン (LAN / Wi-Fi):** ノード探索、OpenAI/Anthropic/Ollama 互換 API (`:8000`)、ヘルス監視。
- **データプレーン (Thunderbolt 3/4/5 + RDMA):** `10.99.1.x` 上の専用テンソル転送（TB4 で `30–37 Gbps`、TB5 RDMA JACCL で双方向最大 `160 Gbps` / 遅延 `~3 µs`）。
- **インターネット WAN 層:** マイクロバッチ (`M ≥ 4`) により WAN 遅延を隠蔽し `405B–671B+` モデルを実行。

---

## ✨ 主な機能

![ローカル AI エージェントと IDE エコシステム](docs/images/ssccc_agents_ide_ecosystem.jpg)

- **全 Apple Silicon 対応 (M1–M12+):** Mac mini, MacBook Air/Pro, iMac, Mac Studio, Mac Pro。
- **重み付きレイヤー分割 (`MemoryWeightedPlanner`):** 最大メモリ帯域の Mac が自動的に **ランク 0 (コーディネーター)** となり Embeddings + LM-Head を保持。各ワーカーは利用可能メモリに比例した層のみを担当します。
- **メモリ保護 (`iogpu.wired_limit_mb`):** ノードごとに 4–8 GB を macOS 用に予約し OOM を防止。
- **ランタイム:** `MLX` (`mlx.distributed` / `JACCL`)、`oMLX` (ポート `8000`、SSD ページング KV キャッシュ)、`Ollama` (`11434`)、`llama.cpp` (`8080`)。
- **ワンクリック連携:** OpenCode, Hermes Agent, Google Antigravity, Cursor, VS Code, Xcode。
- **8 言語対応 UI:** English, Deutsch, Français, Español, Português, Русский, 日本語, 中文。

---

## 🧩 新機能ハイライト（10タブ構成 & Multi-Model-Mode）

- **Multi-Model-Mode (MMM / 10番目のメニュー):** ローカルクラスター、インターネットWAN、またはハイブリッド（ローカル＋WAN）上で複数モデルを統合（*Parallel Pool*・*Mixture-of-Agents*・*Speculative Draft+Target*・*Sequential Pipeline*）。VRAM予算保護（`iogpu.wired_limit_mb`）および **複数の IDE / エージェント・ハーネス（Cursor, VS Code, Xcode, OpenCode, Hermes, Antigravity）による `:8000/v1` 同時利用**に対応。
- **インターネット帯域幅・WANスループット監視:** `netstat`・ICMP Ping/ジッター・`/usr/bin/networkQuality -c` を用いた実測とクラスター性能影響の可視化。
- **Science & Roofline 実測データ対応:** 実運用ではライブ SSE ストリーミング & ICMP RTT を実測し、シミュレーションモードでは明確にラベル付けされた現実的な Apple Silicon 参照値を表示。

---

## 🛠️ ソースからのビルド（初回起動前に重要）

> **注意:** このリポジトリにはソースコード・スクリプト・ドキュメントのみが含まれ、ビルド済みバイナリは同梱されていません。

```bash
git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
cd SonnerStudio-Cluster-Case-Companion
chmod +x scripts/*.sh
"./scripts/run_ssccc.sh"
```

---

## 🚀 クイックスタート

```bash
# 1. ネイティブ SwiftUI アプリを起動
"./scripts/run_ssccc.sh"

# 2. (任意) Python/FastAPI ゲートウェイを起動
cd core && uv sync --extra dev
PYTHONPATH=".." uv run uvicorn core.api.gateway:app --host 0.0.0.0 --port 8000

# 3. Thunderbolt ポイントツーポイント IP を設定
./scripts/setup_tb_network.sh studio   # 10.99.1.1
./scripts/setup_tb_network.sh mini     # 10.99.1.2
```

---

## 📖 運用ガイド：ローカル & ハイブリッド（ローカル + インターネット）クラスター構築・モデル読み込み・理論性能データ

### 1. ローカルクラスターの構築 (Thunderbolt 3/4/5 & LAN)
1. **物理配線:** Mac 同士を **Thunderbolt 3/4/5 ケーブル**（直結・リング・メッシュ）および/または **10GbE Ethernet** で接続します。
2. **固定 IP の割り当て:** 主機で `./scripts/setup_tb_network.sh studio` (`10.99.1.1`)、ワーカー側で `./scripts/setup_tb_network.sh mini` (`10.99.1.2` 等) を実行します。
3. **RDMA 有効化（任意・macOS 26.2+ TB5）:** `rdma_ctl enable` により `JACCL` (`mlx.distributed`) のノード間遅延が `~300 µs` (TCP/IP) から **`~3 µs`** へ短縮されます。
4. **自動ランク割り当て:** **デバイスと比較** で Mac を追加すると、メモリ帯域幅が最大の Mac が自動的に **ランク 0 (コーディネーター)**、他が **ランク 1..N (ワーカー)** になります。

### 2. ハイブリッドクラスターネットワークの構築（ローカル + インターネット WAN 同時接続）
1. **ローカル高速コア (Tier 1):** ローカルの TB/LAN リング (`10.99.1.x` / `192.168.x.x`) を維持します。
2. **WAN コーディネータールーム (Tier 2):** **インターネットクラスターとチャット** で WAN ルーム (`/ws/wan/{room_id}`, ポート `8000`) を開設（Tailscale / WireGuard / Cloudflare Tunnel 等で公開）。
3. **遠隔 Mac の参加:** 世界中の Mac が **ルームコード + 参加トークン** でワーカーとして合流します。
4. **2 階層ハイブリッドルーティング:** 高頻度レイヤーはローカルリング (`3–180 µs`) に残し、余剰レイヤーを WAN ワーカー (`15–120 ms` RTT) へマイクロバッチ (`M ≥ 4`) 付きで分散します。

### 3. 誰がモデルを読み込むか、いくつ同時読み込みできるか、処理の流れは？
- **誰が何を読み込むか？**
  - **コーディネーター (ランク 0):** API ゲートウェイ (`:8000`) とトークナイズを担当し、**常に Embeddings と LM-Head (`has_embeddings=True`, `has_lm_head=True`)** および自身の担当レイヤー (`Layers_i = TotalLayers × Usable_i / TotalUsable`) を読み込みます。
  - **ワーカー (ランク 1..N):** 各ワーカーはローカルキャッシュ（`~/.cache/huggingface`, `~/.ollama/models`, `~/Models`）から **自身に割り当てられた Safetensors / レイヤー範囲 `[start_layer .. end_layer)` のみ** を読み込みます。
- **同時にいくつのモデルを読み込めるか？**
  - **分散クラスターモード (`mlx.distributed` / `JACCL`):** 統合メモリプール全体で **1 つの大型分割モデルを同時稼働**（モデル切替は高速ホットスワップ）。
  - **マルチモデルモード (`oMLX` / `Ollama` / 異種ノード):** `Σ (ModelWeights_i + KV_Cache_i) ≤ Total_Usable_VRAM_GB`（`iogpu.wired_limit_mb` 予約後）の範囲内で **複数モデルを同時常駐** 可能（例：**32B コーダー + 8B 高速ルーター + 1.5B 埋め込みモデル**）。
- **リクエストの処理フロー:**
  1. **ハードウェア探索 & リンク選択** (`TB5 RDMA > TB Bridge > 10GbE > WLAN > WAN`)
  2. **シャーディング計画** (`hostfile.json` と `iogpu.wired_limit_mb` 保護)
  3. **API 受信** (`http://127.0.0.1:8000/v1/chat/completions`, `/v1/messages`, `/api/chat`)
  4. **Prefill フェーズ (`TTFT`):** ランク 0 からパイプライン (`Rank 0 → 1 → ... → N → Rank 0`) へアクティベーションを伝達
  5. **Decode フェーズ (`TPOT` & `tok/s`):** `--kv-bits 4` と `MLX_METAL_FAST_SYNCH=1` で高速生成
  6. **SSE ストリーミング & テレメトリ記録**

### 4. 用途別・理論サイジング＆性能データ

> **解析推定式:**
> - **必要メモリ:** `VRAM_GB ≈ パラメータ数_B × (Bits / 8) × 1.15 + KV_Cache_GB`
> - **理論 Decode 上限:** `tok/s ≈ (実効帯域幅_GB/s / アクティブ重み_GB) × (1 − 通信オーバーヘッド)`

| ユースケース | トポロジ & 利用可能プール | 代表モデル & 量子化 | 理論 `TTFT` (2k prompt) | 理論 Decode (`tok/s` / `TPOT`) | エネルギー & 主なボトルネック |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. ソロ作業環境 (Edge Dev)** | 1× Mac mini M4 (16 GB, `12 GB` 有効, `120 GB/s`) | `Qwen2.5-14B` (`4-bit`, ~8.8 GB) | `~1.8 – 2.6 s` | **`11 – 14 tok/s`** (`~75 ms/tok`) | `~1.7 J/tok` · メモリ帯域幅 |
| **2. 単体 Pro Studio (高速コーディング)** | 1× Mac Studio M4 Max (64 GB, `58 GB` 有効, `546 GB/s`) | `Llama-3.3-70B` (`4-bit`, ~40 GB) | `~1.1 – 1.7 s` | **`12 – 14 tok/s`** (`~74 ms/tok`) | `~3.8 J/tok` · メモリ帯域幅 |
| **3. ローカル 2 台 TB5 RDMA リング** | 2× M4 Max 64 GB (`116 GB` 有効, `~1,092 GB/s` 合計, `~3 µs` JACCL) | `Qwen2.5-Coder-72B` (`8-bit`, ~78 GB) | `~1.4 – 2.0 s` | **`12 – 14 tok/s`** (`~76 ms/tok`) | `~7.5 J/tok` · RDMA 同期負荷極小 |
| **4. 研究室 4 台 Ultra TB5 RDMA** | 4× M3 Ultra 256 GB (`992 GB` 有効, `~3.27 TB/s` 合計) | `DeepSeek-V3 671B MoE` (`4-bit`, ~385 GB, ~37B 稼働) | `~2.2 – 3.5 s` | **`38 – 55 tok/s`** (`~20 ms/tok`) | `~5.2 J/tok` · MoE 稼働エキスパート帯域 |
| **5. ハイブリッド Office LAN + 自宅 WAN** | 2× TB4/10GbE + 2× WAN (`192 GB` 有効, `35 ms` WAN RTT) | `Llama-3.1-405B` (`3/4-bit`, ~170 GB) | `~6 – 11 s` | **`2.2 – 4.5 tok/s`** (`~280 ms/tok`) | `~28 J/tok` · WAN 遅延 (`M=8` で緩和) |
| **6. 世界規模コミュニティ WAN 群** | 16+ Mac 世界各地 (`1.5+ TB` 有効, `60–120 ms` WAN RTT) | `671B–1T+` Frontier (`4/8-bit`) | `~12 – 25 s` | **`1.2 – 3.0 tok/s`** (`~500 ms/tok`) | WAN 遅延（バッチングで拡張） |

---

## 📚 ドキュメント & Thunderbolt 5 RDMA (`JACCL`)

![Thunderbolt 5 RDMA JACCL とメモリ保護](docs/images/ssccc_tb5_rdma_jaccl.jpg)

アプリ内の **ヘルプとマニュアル** タブに 9 セクションの完全ガイドを内蔵しています。

---

## 🔄 GitHub 連携アップデート & 自動バージョン管理

![GitHub 連携アップデートと自動バージョン管理](docs/images/ssccc_github_auto_updater.jpg)

- **30 分ごとの自動監視:** `version.json`、GitHub Releases、`commits/main` SHA を確認。
- **ワンクリック更新:** アプリ内から `git pull` + `swift build` + 再起動を実行。
- **CI Auto-Bump:** `main` へのプッシュ時に GitHub Actions が自動でビルド番号を更新します。

---

## 🎙️ クラスター Audio-Party & リアルタイム WAN 協業

![クラスター Audio-Party とライブチャット](docs/images/ssccc_audio_party_collab.jpg)

`AVAudioEngine 16 kHz PCM16 · /ws/wan-audio` によるコンソール風音声パーティーを内蔵。

---

## 📊 科学ラボ (6 タブ) & 履歴記録

![科学ラボと履歴記録](docs/images/ssccc_history_telemetry_lab.jpg)

個別指標または全体の履歴を記録し、`CSV / JSON / LaTeX / BibTeX` で出力可能。

---

## 🏆 世界記録チャレンジ：ローカル + 世界規模ハイブリッドスーパーコンピューター

![SS-CCC 世界記録チャレンジ](docs/images/ssccc_world_record_challenge.jpg)

**分散型 Apple Silicon Mac 連合はデータセンターのスーパーコンピューターに匹敵できるか？**  
世界中の大学、AI 研究室、開発者コミュニティ、Apple Silicon 愛好家の皆様に、公式 **SS-CCC ハイブリッド世界記録チャレンジ** への参加を呼びかけます。**ハイブリッドブリッジ（ローカル＋インターネット結合）**、**Cluster Audio-Party**、**6 タブ科学ラボ** を活用し、可能な限り多くの **ローカル Thunderbolt 3/4/5/RDMA クラスター** と **インターネット上の WAN Mac** を同時に結合しましょう。

### 🔬 科学的根拠とスケーリング数理モデル

1. **2 階層トポロジ（Tier-0 TB/RDMA アイランド + Tier-1 WAN バックボーン）：**
   - 単純なフラット WAN 構成では、すべての層境界が高遅延なインターネットを経由するため速度が低下します ($H_{\text{WAN}} = N - 1$)。
   - **SS-CCC ハイブリッドブリッジ** により連続する層を高速なローカル Thunderbolt 島（`~0.07 ms`、`30–110 Gbps`）に留め、WAN 通信を各島の **Rank 0 ゲートウェイ間** のみに限定します ($H_{\text{WAN}} \ll N_{\text{total}}$)。
2. **臨界マイクロバッチ ($B^*$) とアクティベーション圧縮による WAN RTT 隠蔽：**
   - パイプライン効率は GPipe バブル式に従います：
     $$\Phi_{\text{bubble}} = \frac{N - 1}{M + N - 1}, \qquad B^* = \left\lceil \frac{T_{\text{RTT,WAN}} + T_{\text{tx}}}{T_{\text{comp}}(B=1)} \right\rceil$$
   - マイクロバッチ深度 $M \to B^*$ により大陸間 RTT を並列計算の背後に隠し、**FP8 / INT4 / Top-K 圧縮** (*Petals / SWARM*) で通信量を一般的な WAN 上り帯域の $1\%$ 未満に抑えます。
3. **標準化された再現性プロトコル ($T = 0.0$)：**
   1. **Tier-0 アイランド構築：** ローカルの M1–M9+ Mac を Thunderbolt 3/4/5 で接続（`MLX_METAL_FAST_SYNCH=1`）。
   2. **ブリッジ結合と調整：** **Hybrid Bridge** を有効化し、`SSCCC-WAN-…` ルームコードを共有して **Audio-Party**（`Opus 16 kbps`、WAN 負荷 $<0.02\%$）で層分割を同期。
   3. **計測実行：** **科学と Roofline** を **Internet-WAN** に切り替え、`N = 20` 試行（ウォームアップ `1` 回除外、`T = 0.0`）を実行し SLO（`TTFT ≤ 2500 ms`、`TPOT ≤ 100 ms/tok`）を検証。
   4. **検証データ公開：** `hardware_fingerprint`、`TTFT/TPOT (p50/p95/p99 ± CI₉₅)`、`CV%`、`Goodput%`、`J/tok`、`EDP`、`gCO₂eq/1M tok` を含む **JSON 再現性マニフェスト**・**CSV**・**LaTeX (`booktabs`)** を公開。

![科学ラボと履歴記録](docs/images/ssccc_history_telemetry_lab.jpg)

### 🥇 公式記録カテゴリー
- **最大統合メモリプール：** ローカル＋WAN 結合で確保された最大合計利用可能 VRAM (`GB` / `TB`)。
- **最多同時結合 Mac 台数 ($N$)：** 有効な `N = 20` 計測を完了した最大アクティブメッシュ (`32–256+` ノード)。
- **最高大陸間ハイブリッド Goodput：** 2 大陸以上でインタラクティブ SLO を満たす最大 `tokens/s`。
- **最高クラスターエネルギー効率：** `70B+` モデルにおける最小 `Joules/token` および `EDP (J·s)`。

---

## 🎯 主なユースケースと対象ユーザー

![SS-CCC ユースケース一覧](docs/images/ssccc_use_cases_showcase.jpg)

| ユーザー層 | SS-CCC による具体的ユースケース |
| :--- | :--- |
| **AI システム・ML 研究者** | ローカル vs WAN の Roofline 限界 ($P = \min(\beta \cdot I, \pi_{\text{eff}})$)、*Petals/SWARM* 圧縮、*DiLoCo* vs DDP を解析し、`CI₉₅`＋`LaTeX`/`BibTeX` を論文へ直接出力。 |
| **大学・教育機関・研究室** | キャンパス LAN と自宅 WAN を跨いで学生の MacBook と研究室の Mac mini を統合し、**Audio-Party** で調整しながら `70B–405B+` 教育クラスターを構築。 |
| **ソフトウェアスタジオ・エージェント開発** | **OpenCode**、**Hermes Agent**、**Antigravity**、**Cursor**、**VS Code**、**Xcode** 向けのプライベートかつクラウド費用ゼロのコーディング環境を社内の Mac で構築。 |
| **機密重視の法務・医療・R&D** | 機密データを完全にオンプレミス、または暗号化 **WireGuard / Tailscale** トンネル内に留め、外部 API への送信や情報漏洩をゼロに。 |
| **グローバルハッカソン・OSS 群** | 数分で国境を越えたアドホック・スーパーコンピューターを起動し、コンソール風音声チャットで連携して記録に挑戦。 |
| **グリーン AI・持続可能性監査** | データセンター GPU API に対し、`J/token`、`EDP`、地域別 `gCO₂eq/1M tokens`（ノルウェー水力 vs 欧米電力網）を定量比較。 |

---

## 📁 リポジトリ構成

```text
├── app/Sources/
│   ├── SSCCCApp.swift              # メインウィンドウ、ヘッダー更新ピル & UpdatePromptSheet
│   ├── Models/
│   │   ├── ClusterModels.swift     # M1–M12+ チップ推定、WAN/科学/履歴 & リリースモデル
│   │   └── Localization.swift      # 8 言語完全対応 UI & ヘルプ辞書 (EN/DE/FR/ES/PT/RU/JA/ZH)
│   ├── ViewModels/
│   │   └── ClusterViewModel.swift  # ハードウェア探索、モデル検出、WAN/Audio-Party & GitHub 更新
│   └── Views/                      # 9 つの SwiftUI ビュー + Theme.swift（3 タブ概要、黄黒の警告ストライプ、6 タブ科学ラボ & ヘルプ）
├── core/                           # Python FastAPI ゲートウェイ、WebSocket WAN/音声リレー & MLX 分割
├── scripts/
│   ├── run_ssccc.sh                # macOS アプリをコンパイルして起動
│   ├── bump_version.py             # version.json & ClusterModels.swift を Git と同期
│   ├── setup_tb_network.sh         # 10.99.1.x Thunderbolt ブリッジを設定
│   └── setup_wired_limit.sh        # 安全な iogpu.wired_limit_mb 上限を適用
├── tests/                          # 14 項目の総合テストスイート (Swift + Python)
├── .github/workflows/              # 自動 CI バージョン管理とタグ付け
└── version.json                    # GitHub ホスト型アップデート制御マニフェスト
```

---

## 🚧 開発状況とコントリビューションのお誘い

> [!IMPORTANT]
> **SS-CCC (v1.6+) は完全に動作可能で `14/14` の自動テストを通過しており、異種マルチノード環境での連続耐久ベンチマークを継続中です。**
> **実装・検証済み機能：** 英語デフォルト起動＋8 言語切替 (`EN/DE/FR/ES/PT/RU/JA/ZH`)、**3 タブ構成のクラスター概要**（**ローカルクラスター**、地域・ローカルサブクラスター付きの **インターネットクラスター**、および **ローカル + インターネット** ハイブリッド表示）、6 つの主要画面に配置された **黄黒の産業用警告ストライプ (`HazardStripesBar` / `IndustrialHazardBanner`)**、将来対応 M1–M12+ ハードウェア検出、リアルタイムモデル検出 (oMLX / Ollama / llama.cpp / GGUF)、単一項目・全体履歴記録付き 6 タブ科学ラボ、ローカル ↔ インターネット WAN ハイブリッド結合、`AVAudioEngine` Audio-Party、9 章ヘルプセンター、および CI 連動 GitHub 自動アップデート。

開発者、研究者、Apple Silicon 愛好家の皆様からの **貢献・参加を心より歓迎します**：
- **実機でのテスト：** お持ちの M1–M12+ Mac で SS-CCC を試し、スループット・メモリ・RDMA/JACCL の安定性レポートを共有してください。
- **ハイブリッド世界記録への参加：** ローカル TB 島と WAN ノードを結合し、出力した JSON/CSV/LaTeX マニフェストを公開してください。
- **Pull Request の送信：** SwiftUI 画面、Python/MLX 分割、Thunderbolt スクリプト、翻訳の改善など、あらゆる貢献を歓迎します！

---

## 📄 ライセンス

[MIT License](LICENSE.md) の下で公開されています。
