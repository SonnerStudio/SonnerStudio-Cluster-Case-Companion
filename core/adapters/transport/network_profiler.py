"""Network profiler & MLX hostfile generator for SS-CCC."""

from __future__ import annotations

from core.domain.models import LINK_PRIORITY, LinkSelection, LinkType, NodeSpec


class NetworkProfiler:
    """Selects the highest-priority common Data-Plane transport across all nodes."""

    def select_best_link(self, nodes: list[NodeSpec], prefer_rdma: bool = True) -> LinkSelection:
        if not nodes:
            raise ValueError("At least one node is required.")

        # 1. Check if ALL nodes have RDMA enabled and RDMA devices
        if prefer_rdma and len(nodes) > 1 and all(n.rdma_enabled for n in nodes):
            node_ips = self._pick_ips(nodes, fallback_only=True)
            rdma_matrix = self._build_rdma_matrix(nodes)
            if rdma_matrix is not None:
                return LinkSelection(
                    backend="jaccl",
                    link_type=LinkType.RDMA,
                    node_ips=node_ips,
                    rdma_matrix=rdma_matrix,
                )

        # 2. Otherwise pick the highest common LinkType (TB_BRIDGE > LAN_10G > LAN_1G > WLAN)
        common_types: set[LinkType] | None = None
        for n in nodes:
            types = {iface.link_type for iface in n.interfaces}
            common_types = types if common_types is None else (common_types & types)

        if common_types:
            best_type = max(common_types, key=lambda t: LINK_PRIORITY[t])
            node_ips = {}
            for n in nodes:
                matching = [i.ip for i in n.interfaces if i.link_type == best_type]
                node_ips[n.node_id] = matching[0]
            return LinkSelection(backend="ring", link_type=best_type, node_ips=node_ips)

        # 3. Fallback: pick each node's highest-priority available IP
        node_ips = self._pick_ips(nodes, fallback_only=True)
        return LinkSelection(backend="ring", link_type=LinkType.WLAN, node_ips=node_ips)

    def _pick_ips(self, nodes: list[NodeSpec], fallback_only: bool = False) -> dict[str, str]:
        result: dict[str, str] = {}
        for n in nodes:
            if not n.interfaces:
                result[n.node_id] = "127.0.0.1"
                continue
            best_iface = max(n.interfaces, key=lambda i: LINK_PRIORITY[i.link_type])
            result[n.node_id] = best_iface.ip
        return result

    def _build_rdma_matrix(self, nodes: list[NodeSpec]) -> list[list[str | None]] | None:
        count = len(nodes)
        matrix: list[list[str | None]] = [[None for _ in range(count)] for _ in range(count)]
        for i, node in enumerate(nodes):
            rdma_devs = [iface.rdma_device for iface in node.interfaces if iface.rdma_device]
            if len(rdma_devs) < count - 1:
                return None
            dev_idx = 0
            for j in range(count):
                if i == j:
                    continue
                matrix[i][j] = rdma_devs[dev_idx]
                dev_idx += 1
        return matrix

    def build_hostfile(self, nodes: list[NodeSpec], link: LinkSelection) -> list[dict] | dict:
        if link.backend == "jaccl" and link.rdma_matrix is not None:
            hosts = []
            for idx, node in enumerate(nodes):
                ip = link.node_ips[node.node_id]
                hosts.append({
                    "ssh": ip,
                    "ips": [ip],
                    "rdma": link.rdma_matrix[idx],
                })
            return {"backend": "jaccl", "hosts": hosts}

        # Standard MLX ring hostfile uses numeric IPs (never .local hostnames)
        return [
            {"ssh": link.node_ips[node.node_id], "ips": [link.node_ips[node.node_id]]}
            for node in nodes
        ]
