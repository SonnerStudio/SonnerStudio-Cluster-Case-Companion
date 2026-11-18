"""Lokale Weiterleitung 127.0.0.1:<forward_port> -> SS-CCC-Gateway auf dem Leitrechner.

Manche Clients akzeptieren unverschlüsseltes http:// nur auf dem eigenen Rechner.
Diese Weiterleitung macht das Gateway des Leitrechners auf dem
Worker als http://127.0.0.1:<forward_port> erreichbar. Die Adresse wird bei jeder Verbindung per
IPv4 aufgelöst (über .local würden sonst zuerst tote IPv6-Adressen probiert).
"""

import asyncio
import os
import socket
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ssccc_config  # noqa: E402

_CFG = ssccc_config.load()

LISTEN = ("127.0.0.1", int(os.environ.get("SSCCC_FWD_PORT", _CFG["forward_port"])))
TARGET_HOST = os.environ.get("SSCCC_FWD_HOST", _CFG["coordinator"]["host"])
TARGET_PORT = int(os.environ.get("SSCCC_FWD_TARGET_PORT", _CFG["gateway_port"]))


def _ipv4(host: str) -> str:
    infos = socket.getaddrinfo(host, TARGET_PORT, socket.AF_INET, socket.SOCK_STREAM)
    ips = [i[4][0] for i in infos]
    lan = [ip for ip in ips if not ip.startswith("169.254.")]
    return (lan or ips)[0]


async def _pipe(r: asyncio.StreamReader, w: asyncio.StreamWriter):
    try:
        while data := await r.read(65536):
            w.write(data)
            await w.drain()
    except (ConnectionError, asyncio.CancelledError):
        pass
    finally:
        w.close()


async def handle(cr: asyncio.StreamReader, cw: asyncio.StreamWriter):
    try:
        ip = await asyncio.to_thread(_ipv4, TARGET_HOST)
        sr, sw = await asyncio.wait_for(asyncio.open_connection(ip, TARGET_PORT), 10)
    except Exception:
        cw.close()
        return
    await asyncio.gather(_pipe(cr, sw), _pipe(sr, cw))


async def main():
    srv = await asyncio.start_server(handle, *LISTEN)
    print(f"[SS-CCC] Weiterleitung {LISTEN[0]}:{LISTEN[1]} -> {TARGET_HOST}:{TARGET_PORT}", flush=True)
    async with srv:
        await srv.serve_forever()


if __name__ == "__main__":
    asyncio.run(main())
