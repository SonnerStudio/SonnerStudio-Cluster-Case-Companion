"""Domain models for SonnerStudio Cluster-Case-Companion (SS-CCC)."""

from __future__ import annotations

from enum import Enum
from pydantic import BaseModel, Field


class LinkType(str, Enum):
    RDMA = "rdma"
    TB_BRIDGE = "tb_bridge"
    LAN_10G = "lan_10g"
    LAN_1G = "lan_1g"
    WLAN = "wlan"


LINK_PRIORITY: dict[LinkType, int] = {
    LinkType.RDMA: 100,
    LinkType.TB_BRIDGE: 80,
    LinkType.LAN_10G: 60,
    LinkType.LAN_1G: 40,
    LinkType.WLAN: 20,
}


class NetworkInterfaceInfo(BaseModel):
    name: str
    ip: str
    link_type: LinkType
    bandwidth_gbps: float = 0.0
    latency_us: float = 0.0
    rdma_device: str | None = None


class NodeSpec(BaseModel):
    node_id: str
    hostname: str
    chip: str
    total_ram_gb: float
    usable_wired_gb: float
    memory_bandwidth_gbps: float = 120.0
    thunderbolt_gen: int = 4
    rdma_enabled: bool = False
    interfaces: list[NetworkInterfaceInfo] = Field(default_factory=list)


class LinkSelection(BaseModel):
    backend: str  # "ring" or "jaccl"
    link_type: LinkType
    node_ips: dict[str, str]
    rdma_matrix: list[list[str | None]] | None = None


class LayerAssignment(BaseModel):
    node_id: str
    rank: int
    start_layer: int
    end_layer: int  # exclusive
    layer_count: int
    memory_budget_gb: float
    has_embeddings: bool = False
    has_lm_head: bool = False


class ShardingPlan(BaseModel):
    model_id: str
    total_layers: int
    estimated_model_gb: float
    kv_cache_reserve_gb: float
    total_usable_cluster_gb: float
    fits_in_cluster: bool
    backend: str
    assignments: list[LayerAssignment]
