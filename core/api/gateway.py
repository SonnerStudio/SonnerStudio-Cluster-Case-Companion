"""FastAPI Control-Plane & OpenAI/Ollama-compatible Gateway for SS-CCC."""

from __future__ import annotations

import time
import uuid
from fastapi import FastAPI
from pydantic import BaseModel, Field

from core.adapters.system.macos_probe import MacOSSystemProbe
from core.adapters.transport.network_profiler import NetworkProfiler
from core.application.planner import MemoryWeightedPlanner
from core.domain.models import (
    LinkSelection,
    LinkType,
    NetworkInterfaceInfo,
    NodeSpec,
    ShardingPlan,
)

app = FastAPI(
    title="SonnerStudio Cluster-Case-Companion (SS-CCC)",
    version="0.1.0",
)

_probe = MacOSSystemProbe()
_profiler = NetworkProfiler()
_planner = MemoryWeightedPlanner()

# Solange der Mac Studio noch per UPS unterwegs ist, kann die Simulation aktiviert bleiben
_simulate_mac_studio: bool = True
_transport_mode: str = "auto_hybrid"  # auto_hybrid | tb_only | lan_wlan_only


def _simulated_studio_node() -> NodeSpec:
    return NodeSpec(
        node_id="studio-m5-max (sim)",
        hostname="mac-studio.local",
        chip="Apple M5 Max (18-Core CPU / 32-Core GPU)",
        total_ram_gb=36.0,
        usable_wired_gb=30.0,
        memory_bandwidth_gbps=460.0,
        thunderbolt_gen=5,
        rdma_enabled=False,
        interfaces=[
            NetworkInterfaceInfo(
                name="en0", ip="192.168.1.10", link_type=LinkType.WLAN, bandwidth_gbps=2.4, latency_us=1200.0
            ),
            NetworkInterfaceInfo(
                name="en1", ip="192.168.1.11", link_type=LinkType.LAN_10G, bandwidth_gbps=10.0, latency_us=180.0
            ),
            NetworkInterfaceInfo(
                name="bridge0", ip="10.99.1.1", link_type=LinkType.TB_BRIDGE, bandwidth_gbps=35.0, latency_us=80.0
            ),
        ],
    )


def _current_nodes() -> list[NodeSpec]:
    local_node = _probe.probe_local_node()
    if _simulate_mac_studio:
        return [_simulated_studio_node(), local_node]
    return [local_node]


class ClusterStatusResponse(BaseModel):
    app_name: str = "SonnerStudio Cluster-Case-Companion"
    simulation_active: bool
    transport_mode: str
    total_physical_ram_gb: float
    total_usable_vram_gb: float
    nodes: list[NodeSpec]
    selected_link: LinkSelection
    hostfile: list[dict] | dict


class PlanRequest(BaseModel):
    model_id: str = "mlx-community/Llama-3.3-70B-Instruct-4bit"
    total_layers: int = 80
    estimated_model_gb: float = 37.5
    kv_cache_reserve_gb: float = 4.0


class SimulationToggleRequest(BaseModel):
    enabled: bool
    transport_mode: str = Field(default="auto_hybrid")


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatCompletionRequest(BaseModel):
    model: str = "mlx-community/Llama-3.3-70B-Instruct-4bit"
    messages: list[ChatMessage]
    stream: bool = False


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "ss-ccc"}


@app.get("/v1/cluster/status", response_model=ClusterStatusResponse)
def cluster_status() -> ClusterStatusResponse:
    nodes = _current_nodes()
    link = _profiler.select_best_link(nodes, prefer_rdma=(_transport_mode != "lan_wlan_only"))
    hostfile = _profiler.build_hostfile(nodes, link)
    return ClusterStatusResponse(
        simulation_active=_simulate_mac_studio,
        transport_mode=_transport_mode,
        total_physical_ram_gb=round(sum(n.total_ram_gb for n in nodes), 2),
        total_usable_vram_gb=round(sum(n.usable_wired_gb for n in nodes), 2),
        nodes=nodes,
        selected_link=link,
        hostfile=hostfile,
    )


@app.post("/v1/cluster/simulation")
def set_simulation(req: SimulationToggleRequest) -> dict[str, object]:
    global _simulate_mac_studio, _transport_mode
    _simulate_mac_studio = req.enabled
    _transport_mode = req.transport_mode
    return {"simulation_active": _simulate_mac_studio, "transport_mode": _transport_mode}


@app.post("/v1/cluster/plan", response_model=ShardingPlan)
def compute_plan(req: PlanRequest) -> ShardingPlan:
    nodes = _current_nodes()
    link = _profiler.select_best_link(nodes, prefer_rdma=(_transport_mode != "lan_wlan_only"))
    return _planner.create_plan(
        nodes=nodes,
        model_id=req.model_id,
        total_layers=req.total_layers,
        estimated_model_gb=req.estimated_model_gb,
        kv_cache_reserve_gb=req.kv_cache_reserve_gb,
        backend=link.backend,
    )


@app.get("/v1/models")
def list_openai_models() -> dict[str, object]:
    return {
        "object": "list",
        "data": [
            {"id": "mlx-community/Llama-3.3-70B-Instruct-4bit", "object": "model", "owned_by": "ss-ccc"},
            {"id": "mlx-community/Qwen2.5-32B-Instruct-4bit", "object": "model", "owned_by": "ss-ccc"},
            {"id": "mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit", "object": "model", "owned_by": "ss-ccc"},
        ],
    }


@app.get("/api/tags")
def list_ollama_models() -> dict[str, object]:
    return {
        "models": [
            {"name": "llama3.3:70b-mlx-q4", "size": 37_500_000_000},
            {"name": "qwen2.5:32b-mlx-q4", "size": 19_200_000_000},
        ]
    }


@app.post("/v1/chat/completions")
def chat_completions(req: ChatCompletionRequest) -> dict[str, object]:
    nodes = _current_nodes()
    total_gb = sum(n.total_ram_gb for n in nodes)
    prompt_preview = req.messages[-1].content if req.messages else ""
    reply = (
        f"[SS-CCC Cluster Vorschau | {len(nodes)} Node(s) | {total_gb:.0f} GB RAM] "
        f"Anfrage empfangen fuer '{req.model}': \"{prompt_preview[:80]}\". "
        "Sobald der Mac Studio M5 Max physisch verbunden ist, uebernimmt hier mlx_lm.distributed."
    )
    return {
        "id": f"chatcmpl-{uuid.uuid4().hex[:12]}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": req.model,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": reply},
                "finish_reason": "stop",
            }
        ],
    }
