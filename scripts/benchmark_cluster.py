#!/usr/bin/env python3
"""Phase 0: MLX Distributed Latenz- und Bandbreiten-Benchmark.

Kann direkt lokal (Single-Node Sanity Check) oder verteilt via `mlx.launch`
ueber Thunderbolt Bridge (`ring`) bzw. RDMA (`jaccl`) ausgefuehrt werden:

  mlx.launch --verbose --backend ring \
    --hostfile configs/ring_2node_example.json \
    --env MLX_METAL_FAST_SYNCH=1 -- \
    uv run python scripts/benchmark_cluster.py
"""

from __future__ import annotations

import os
import time
import mlx.core as mx


def main() -> None:
    group = mx.distributed.init()
    rank = group.rank()
    world_size = group.size()

    if rank == 0:
        print(f"MLX Distributed aktiv: world_size={world_size}, fast_synch={os.environ.get('MLX_METAL_FAST_SYNCH', '0')}")

    # 1. Latenz-Test (kleine Aktivierungen ~16 KB, typisch fuer Token-Decode bs=1)
    small_tensor = mx.ones((4096,), dtype=mx.float32)  # 16 KB
    mx.eval(small_tensor)

    # Warmup
    for _ in range(10):
        res = mx.distributed.all_sum(small_tensor, group=group)
        mx.eval(res)

    iters_lat = 200
    t0 = time.perf_counter()
    for _ in range(iters_lat):
        res = mx.distributed.all_sum(small_tensor, group=group)
        mx.eval(res)
    t1 = time.perf_counter()

    avg_lat_us = ((t1 - t0) / iters_lat) * 1_000_000

    # 2. Bandbreiten-Test (groessere Aktivierungen ~32 MB, typisch fuer Prefill)
    large_tensor = mx.ones((8 * 1024 * 1024,), dtype=mx.float32)  # 32 MB
    mx.eval(large_tensor)

    for _ in range(3):
        res = mx.distributed.all_sum(large_tensor, group=group)
        mx.eval(res)

    iters_bw = 20
    t2 = time.perf_counter()
    for _ in range(iters_bw):
        res = mx.distributed.all_sum(large_tensor, group=group)
        mx.eval(res)
    t3 = time.perf_counter()

    gb_per_iter = (large_tensor.nbytes / 1e9)
    total_sec = t3 - t2
    bw_gbps = (gb_per_iter * iters_bw * 8) / total_sec

    if rank == 0:
        print(f"[Decode-Regime  16 KB] Durchschnittliche all_sum-Latenz: {avg_lat_us:.1f} us")
        print(f"[Prefill-Regime 32 MB] Effektiver Durchsatz:            {bw_gbps:.2f} Gbps")


if __name__ == "__main__":
    main()
