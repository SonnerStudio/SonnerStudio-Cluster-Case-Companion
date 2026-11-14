"""Abstract ports (Hexagonal Architecture) for SS-CCC."""

from __future__ import annotations

from typing import Protocol
from core.domain.models import LinkSelection, NodeSpec, ShardingPlan


class SystemControlPort(Protocol):
    def probe_local_node(self) -> NodeSpec: ...
    def get_wired_limit_mb(self) -> int: ...


class TransportPort(Protocol):
    def select_best_link(self, nodes: list[NodeSpec], prefer_rdma: bool = True) -> LinkSelection: ...
    def build_hostfile(self, nodes: list[NodeSpec], link: LinkSelection) -> list[dict] | dict: ...


class PlannerPort(Protocol):
    def create_plan(
        self,
        nodes: list[NodeSpec],
        model_id: str,
        total_layers: int,
        estimated_model_gb: float,
        kv_cache_reserve_gb: float = 4.0,
        backend: str = "ring",
    ) -> ShardingPlan: ...
