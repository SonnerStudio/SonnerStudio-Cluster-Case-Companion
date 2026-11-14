"""macOS system & hardware prober adapter for SS-CCC."""

from __future__ import annotations

import platform
import re
import subprocess
from core.domain.models import LinkType, NetworkInterfaceInfo, NodeSpec


def _run(cmd: list[str]) -> str:
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=5)
        return out.strip()
    except Exception:
        return ""


def compute_safe_wired_gb(total_ram_gb: float) -> float:
    """Reserve safe OS headroom so macOS WindowServer does not freeze."""
    if total_ram_gb >= 32:
        return round(total_ram_gb - 6.0, 2)  # e.g. 36 GB -> 30 GB
    if total_ram_gb >= 16:
        return round(total_ram_gb - 4.0, 2)  # e.g. 16 GB -> 12 GB
    return round(total_ram_gb * 0.65, 2)


def estimate_memory_bandwidth_gbps(chip: str) -> float:
    c = chip.lower()
    if "ultra" in c:
        return 800.0
    if "m5 max" in c:
        return 460.0
    if "max" in c:
        return 400.0
    if "pro" in c:
        return 273.0
    return 120.0


def detect_rdma_devices() -> list[str]:
    out = _run(["ibv_devices"])
    devices: list[str] = []
    for line in out.splitlines():
        line = line.strip()
        if not line or line.startswith("device") or line.startswith("---"):
            continue
        parts = line.split()
        if parts:
            devices.append(parts[0])
    return devices


def parse_ifconfig_ipv4() -> list[NetworkInterfaceInfo]:
    out = _run(["ifconfig"])
    interfaces: list[NetworkInterfaceInfo] = []
    current_iface: str | None = None
    for line in out.splitlines():
        if not line.startswith("\t") and ":" in line:
            current_iface = line.split(":", 1)[0].strip()
            continue
        if current_iface and "inet " in line:
            match = re.search(r"inet\s+(\d+\.\d+\.\d+\.\d+)", line)
            if not match:
                continue
            ip = match.group(1)
            if ip.startswith("127.") or ip.startswith("169.254."):
                continue
            if ip.startswith("10.99.") or current_iface.startswith("bridge"):
                link_type = LinkType.TB_BRIDGE
                bw = 35.0
                lat = 80.0
            elif current_iface == "en0":
                link_type = LinkType.WLAN
                bw = 1.2
                lat = 1500.0
            else:
                link_type = LinkType.LAN_1G
                bw = 1.0
                lat = 350.0
            interfaces.append(
                NetworkInterfaceInfo(
                    name=current_iface,
                    ip=ip,
                    link_type=link_type,
                    bandwidth_gbps=bw,
                    latency_us=lat,
                )
            )
    return interfaces


class MacOSSystemProbe:
    def get_wired_limit_mb(self) -> int:
        raw = _run(["sysctl", "-n", "iogpu.wired_limit_mb"])
        try:
            return int(raw)
        except ValueError:
            return 0

    def probe_local_node(self, node_id: str | None = None) -> NodeSpec:
        hostname = platform.node() or "mac-node"
        chip = _run(["sysctl", "-n", "machdep.cpu.brand_string"]) or "Apple Silicon"
        mem_bytes_raw = _run(["sysctl", "-n", "hw.memsize"])
        total_ram_gb = round(int(mem_bytes_raw) / (1024**3), 2) if mem_bytes_raw.isdigit() else 16.0
        rdma_devs = detect_rdma_devices()
        tb_gen = 5 if ("max" in chip.lower() or "ultra" in chip.lower()) else 4

        return NodeSpec(
            node_id=node_id or hostname.split(".")[0].lower(),
            hostname=hostname,
            chip=chip,
            total_ram_gb=total_ram_gb,
            usable_wired_gb=compute_safe_wired_gb(total_ram_gb),
            memory_bandwidth_gbps=estimate_memory_bandwidth_gbps(chip),
            thunderbolt_gen=tb_gen,
            rdma_enabled=len(rdma_devs) > 0,
            interfaces=parse_ifconfig_ipv4(),
        )
