"""Memory-weighted pipeline partitioning planner for heterogeneous Mac clusters."""

from __future__ import annotations

from core.domain.models import LayerAssignment, NodeSpec, ShardingPlan


class MemoryWeightedPlanner:
    """Splits transformer layers proportionally to each node's usable wired GPU memory.

    Places Rank 0 (embeddings + LM head) on the node with the highest memory bandwidth
    (e.g., Mac Studio M5 Max at 460 GB/s).
    """

    def create_plan(
        self,
        nodes: list[NodeSpec],
        model_id: str,
        total_layers: int,
        estimated_model_gb: float,
        kv_cache_reserve_gb: float = 4.0,
        backend: str = "ring",
    ) -> ShardingPlan:
        if not nodes:
            raise ValueError("Cannot create a sharding plan with zero nodes.")
        if total_layers <= 0:
            raise ValueError("total_layers must be positive.")

        # Order nodes so Rank 0 is the highest-bandwidth / highest-RAM node (Coordinator)
        ordered = sorted(
            nodes,
            key=lambda n: (n.memory_bandwidth_gbps, n.usable_wired_gb),
            reverse=True,
        )

        total_usable = sum(n.usable_wired_gb for n in ordered)
        fits = (estimated_model_gb + kv_cache_reserve_gb) <= total_usable

        # Allocate integer layers proportional to usable_wired_gb
        raw_counts = [
            (n.usable_wired_gb / total_usable) * total_layers for n in ordered
        ]
        layer_counts = [int(c) for c in raw_counts]
        remainder = total_layers - sum(layer_counts)

        # Distribute remaining layers by largest fractional part
        fractions = sorted(
            range(len(ordered)),
            key=lambda i: raw_counts[i] - layer_counts[i],
            reverse=True,
        )
        for idx in fractions[:remainder]:
            layer_counts[idx] += 1

        assignments: list[LayerAssignment] = []
        cursor = 0
        for rank, (node, count) in enumerate(zip(ordered, layer_counts)):
            start = cursor
            end = cursor + count
            cursor = end
            assignments.append(
                LayerAssignment(
                    node_id=node.node_id,
                    rank=rank,
                    start_layer=start,
                    end_layer=end,
                    layer_count=count,
                    memory_budget_gb=node.usable_wired_gb,
                    has_embeddings=(rank == 0),
                    has_lm_head=(rank == 0),
                )
            )

        return ShardingPlan(
            model_id=model_id,
            total_layers=total_layers,
            estimated_model_gb=estimated_model_gb,
            kv_cache_reserve_gb=kv_cache_reserve_gb,
            total_usable_cluster_gb=round(total_usable, 2),
            fits_in_cluster=fits,
            backend=backend,
            assignments=assignments,
        )
