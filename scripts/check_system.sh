#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "  Mac-Cluster Phase 0: System-, Thunderbolt- & RDMA-Check"
echo "============================================================"

echo ""
echo "[1/6] macOS & Hardware"
sw_vers
sysctl -n machdep.cpu.brand_string 2>/dev/null || true
TOTAL_MEM_BYTES=$(sysctl -n hw.memsize)
TOTAL_MEM_GB=$((TOTAL_MEM_BYTES / 1024 / 1024 / 1024))
echo "Physischer RAM: ${TOTAL_MEM_GB} GB"

echo ""
echo "[2/6] GPU Wired Memory Limit (iogpu.wired_limit_mb)"
WIRED_LIMIT=$(sysctl -n iogpu.wired_limit_mb 2>/dev/null || echo "unbekannt")
echo "Aktuelles iogpu.wired_limit_mb: ${WIRED_LIMIT} (0 = dynamisches macOS-Standardlimit ~65-75%)"
if [[ "${TOTAL_MEM_GB}" -ge 32 ]]; then
  echo "Empfehlung fuer 36 GB Mac Studio: sudo sysctl -w iogpu.wired_limit_mb=30720  (30 GB)"
elif [[ "${TOTAL_MEM_GB}" -ge 16 ]]; then
  echo "Empfehlung fuer 16 GB Mac mini:   sudo sysctl -w iogpu.wired_limit_mb=12288  (12 GB)"
fi

echo ""
echo "[3/6] Thunderbolt-Hardware & Links"
system_profiler SPThunderboltDataType 2>/dev/null | grep -E "Bus|Port|Link Speed|Device Name|Switch|Domain" || echo "Keine Thunderbolt-Infos gefunden."

echo ""
echo "[4/6] RDMA-Status (TN3205 / ibv_devices)"
if command -v ibv_devices >/dev/null 2>&1; then
  ibv_devices || true
else
  echo "ibv_devices nicht gefunden (ab macOS 26.2 verfuegbar)."
fi

if command -v rdma_ctl >/dev/null 2>&1; then
  rdma_ctl status 2>&1 || true
else
  echo "rdma_ctl im normalen OS-Pfad nicht verfuegbar (Aktivierung erfolgt in RecoveryOS)."
fi

echo ""
echo "[5/6] Netzwerk-Services & Reihenfolge (Service Order)"
networksetup -listnetworkserviceorder 2>/dev/null | head -n 30 || true

echo ""
echo "[6/6] Python / uv / iperf3 Tooling"
for cmd in uv python3 iperf3 ssh; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    echo "  [OK] ${cmd}: $(command -v "${cmd}")"
  else
    echo "  [FEHLT] ${cmd} (optional: brew install ${cmd})"
  fi
done

echo ""
echo "Check abgeschlossen."
