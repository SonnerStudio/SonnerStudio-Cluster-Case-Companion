"""mDNS / Bonjour peer discovery adapter for SS-CCC."""

from __future__ import annotations

import socket
from zeroconf import ServiceInfo, Zeroconf

SERVICE_TYPE = "_ssccc._tcp.local."


class BonjourDiscoveryAdapter:
    """Publishes this Mac as an SS-CCC cluster node over LAN/WLAN Control Plane."""

    def __init__(self, node_id: str, port: int = 8000, chip: str = "Apple Silicon", ram_gb: float = 16.0) -> None:
        self.node_id = node_id
        self.port = port
        self.chip = chip
        self.ram_gb = ram_gb
        self._zeroconf: Zeroconf | None = None
        self._info: ServiceInfo | None = None

    def start(self) -> None:
        hostname = socket.gethostname()
        try:
            local_ip = socket.gethostbyname(hostname)
        except OSError:
            local_ip = "127.0.0.1"

        self._zeroconf = Zeroconf()
        self._info = ServiceInfo(
            SERVICE_TYPE,
            f"{self.node_id}.{SERVICE_TYPE}",
            addresses=[socket.inet_aton(local_ip)],
            port=self.port,
            properties={
                "node_id": self.node_id.encode(),
                "chip": self.chip.encode(),
                "ram_gb": str(self.ram_gb).encode(),
            },
            server=f"{hostname}.local.",
        )
        self._zeroconf.register_service(self._info)

    def stop(self) -> None:
        if self._zeroconf and self._info:
            self._zeroconf.unregister_service(self._info)
            self._zeroconf.close()
            self._zeroconf = None
            self._info = None
