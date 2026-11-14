"""Unit tests for SS-CCC planner, network profiler, and local macOS probe."""

from __future__ import annotations

from core.adapters.system.macos_probe import MacOSSystemProbe
from core.adapters.transport.network_profiler import NetworkProfiler
from core.application.planner import MemoryWeightedPlanner
from core.domain.models import LinkType, NetworkInterfaceInfo, NodeSpec


def _studio_m5_max() -> NodeSpec:
    return NodeSpec(
        node_id="studio-m5-max",
        hostname="mac-studio.local",
        chip="Apple M5 Max",
        total_ram_gb=36.0,
        usable_wired_gb=30.0,
        memory_bandwidth_gbps=460.0,
        thunderbolt_gen=5,
        rdma_enabled=False,
        interfaces=[
            NetworkInterfaceInfo(name="en0", ip="192.168.1.10", link_type=LinkType.WLAN, bandwidth_gbps=1.5),
            NetworkInterfaceInfo(name="en1", ip="192.168.1.11", link_type=LinkType.LAN_10G, bandwidth_gbps=10.0),
            NetworkInterfaceInfo(name="bridge0", ip="10.99.1.1", link_type=LinkType.TB_BRIDGE, bandwidth_gbps=35.0),
        ],
    )


def _mini_m4() -> NodeSpec:
    return NodeSpec(
        node_id="mini-m4",
        hostname="mac-mini.local",
        chip="Apple M4",
        total_ram_gb=16.0,
        usable_wired_gb=12.0,
        memory_bandwidth_gbps=120.0,
        thunderbolt_gen=4,
        rdma_enabled=False,
        interfaces=[
            NetworkInterfaceInfo(name="en0", ip="192.168.1.20", link_type=LinkType.WLAN, bandwidth_gbps=1.2),
            NetworkInterfaceInfo(name="bridge0", ip="10.99.1.2", link_type=LinkType.TB_BRIDGE, bandwidth_gbps=35.0),
        ],
    )


def test_weighted_pipeline_plan_36gb_plus_16gb() -> None:
    planner = MemoryWeightedPlanner()
    plan = planner.create_plan(
        nodes=[_mini_m4(), _studio_m5_max()],  # intentionally reversed order
        model_id="mlx-community/Llama-3.3-70B-Instruct-4bit",
        total_layers=80,
        estimated_model_gb=37.5,
        kv_cache_reserve_gb=4.0,
    )

    assert plan.total_usable_cluster_gb == 42.0
    assert plan.fits_in_cluster is True
    assert len(plan.assignments) == 2

    rank0, rank1 = plan.assignments
    assert rank0.node_id == "studio-m5-max"
    assert rank0.has_embeddings is True
    assert rank0.has_lm_head is True
    assert rank0.layer_count == 57  # 30/42 * 80 = 57.14

    assert rank1.node_id == "mini-m4"
    assert rank1.layer_count == 23  # 12/42 * 80 = 22.86
    assert rank0.layer_count + rank1.layer_count == 80


def test_network_profiler_prefers_thunderbolt_bridge_over_wlan() -> None:
    profiler = NetworkProfiler()
    nodes = [_studio_m5_max(), _mini_m4()]
    link = profiler.select_best_link(nodes, prefer_rdma=True)

    assert link.backend == "ring"
    assert link.link_type == LinkType.TB_BRIDGE
    assert link.node_ips["studio-m5-max"] == "10.99.1.1"
    assert link.node_ips["mini-m4"] == "10.99.1.2"

    hostfile = profiler.build_hostfile(nodes, link)
    assert hostfile == [
        {"ssh": "10.99.1.1", "ips": ["10.99.1.1"]},
        {"ssh": "10.99.1.2", "ips": ["10.99.1.2"]},
    ]


def test_network_profiler_uses_jaccl_when_rdma_enabled_on_all_nodes() -> None:
    studio = _studio_m5_max()
    mini = _mini_m4()
    studio.rdma_enabled = True
    mini.rdma_enabled = True
    studio.interfaces.append(
        NetworkInterfaceInfo(name="rdma_en5", ip="10.99.1.1", link_type=LinkType.RDMA, rdma_device="rdma_en5")
    )
    mini.interfaces.append(
        NetworkInterfaceInfo(name="rdma_en5", ip="10.99.1.2", link_type=LinkType.RDMA, rdma_device="rdma_en5")
    )

    profiler = NetworkProfiler()
    link = profiler.select_best_link([studio, mini], prefer_rdma=True)
    assert link.backend == "jaccl"
    assert link.link_type == LinkType.RDMA

    hostfile = profiler.build_hostfile([studio, mini], link)
    assert isinstance(hostfile, dict)
    assert hostfile["backend"] == "jaccl"
    assert hostfile["hosts"][0]["rdma"] == [None, "rdma_en5"]
    assert hostfile["hosts"][1]["rdma"] == ["rdma_en5", None]


def test_local_macos_probe_runs_cleanly() -> None:
    probe = MacOSSystemProbe()
    node = probe.probe_local_node()
    assert node.total_ram_gb >= 8.0
    assert node.usable_wired_gb > 0
