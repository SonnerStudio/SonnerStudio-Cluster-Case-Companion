# Architecture & Thunderbolt / RDMA Interconnects

[← Back to Wiki Home](Home.md)

## 🏗️ Hybrid Two-Plane Design

SS-CCC separates cluster orchestration cleanly into two planes:

- **Control Plane (LAN / WLAN / Tailscale WAN):** Bonjour/mDNS discovery, health probes, SSH provisioning, and real-time WebSocket coordination (`/ws/wan/{room_id}`, `/ws/wan-audio`).
- **Data Plane (Thunderbolt 3/4/5 · RDMA `JACCL` · WAN Pipeline):** Rank 0 Coordinator holds tokenizer, embeddings, and LM head (`has_embeddings=True`, `has_lm_head=True`), while Rank `1..N` Workers load only their proportional layer slice `[start_layer .. end_layer)`.

---

## 💻 Universal Apple Silicon Support (`M1–M12+`)

| Chip Family | Unified Memory Bandwidth | Thunderbolt & RDMA | Recommended OS Reserve |
| :--- | :--- | :--- | :--- |
| **M1 / M2** (Base) | 68 – 100 GB/s | TB 3 / USB4 (`26–32 Gbps`) | **4 GB** (`≤ 24 GB RAM`) |
| **M3 / M4** (Base) | 100 – 120 GB/s | TB 4 (`30–37 Gbps`) | **4 GB** (`≤ 24 GB RAM`) |
| **M5 / M6** (Base, 2nm) | **153 – 170 GB/s** | TB 4 / TB 5 (`80/120 Gbps`) | **4 GB** (`≤ 32 GB RAM`) |
| **M1–M3 Pro** | 150 – 200 GB/s | TB 4 (`30–37 Gbps`) | **4 – 6 GB** |
| **M4 / M5 Pro** | 273 – 307+ GB/s | TB 5 (`80/120 Gbps` Boost) | **4 – 6 GB** |
| **M1–M3 Max** | 400 GB/s | TB 4 (`30–37 Gbps`) | **6 GB** (`32–64 GB RAM`) |
| **M4 Max** | **410 – 546 GB/s** | TB 5 + RDMA (`~3 µs`) | **6 GB** (`32–128 GB RAM`) |
| **M5 Max** | **460 – 614 GB/s** | TB 5 + RDMA (`~3 µs` JACCL) | **6 GB** (`36–128 GB RAM`) |
| **M1–M3 Ultra** | **800 – 819 GB/s** | TB 4 / TB 5 RDMA (`JACCL`) | **8 GB** (`≥ 96 GB RAM`) |
| **M5 Ultra** | **1.2 TB/s** (`~1,228 GB/s`) | TB 5 RDMA (`JACCL`) | **8 GB** (`96–512 GB RAM`) |

SS-CCC inspects real hardware via `sysctl`, `system_profiler`, `IOAccelerator`, `ibv_devices`, `ipconfig`, `ioreg`, and `ProcessInfo.thermalState`.

---

## ⚡ Thunderbolt 5 RDMA (`JACCL`) & Memory Protection

```bash
# Configure deterministic point-to-point Thunderbolt IPs
./scripts/setup_tb_network.sh studio   # 10.99.1.1
./scripts/setup_tb_network.sh mini     # 10.99.1.2

# Enable Apple RDMA (macOS 26.2+ on TB5) & guard bridge0 against kernel panics
sudo ifconfig bridge0 down 2>/dev/null || true
sudo rdma_ctl enable

# Apply safe wired memory limit (reserves 4–8 GB for macOS)
./scripts/setup_wired_limit.sh
```

- Setting `MLX_METAL_FAST_SYNCH=1` cuts GPU/CPU pipeline sync overhead by **45×** (`~180 µs → ~4 µs`).
- `JACCL` Full-Mesh Tensor Parallelism reduces node-to-node latency to **`~3 µs`** at **`3.5–3.8 GB/s`** sustained tensor throughput.
