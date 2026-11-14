#!/usr/bin/env bash
set -euo pipefail

# Konfiguriert eine dedizierte Punkt-zu-Punkt-IP fuer die Thunderbolt-Bridge
# (Standard-Modus A: sicher, ohne SIP-/Recovery-Aenderung).
#
# Verwendung:
#   ./setup_tb_network.sh studio   -> setzt 10.99.1.1/24 auf "Thunderbolt Bridge"
#   ./setup_tb_network.sh mini     -> setzt 10.99.1.2/24 auf "Thunderbolt Bridge"
#   ./setup_tb_network.sh status   -> zeigt aktuelle TB-IP & Ping-Test

ROLE="${1:-status}"
SERVICE_NAME="${TB_SERVICE_NAME:-Thunderbolt Bridge}"
SUBNET_MASK="255.255.255.0"

case "${ROLE}" in
  studio)
    IP_ADDR="10.99.1.1"
    PEER_IP="10.99.1.2"
    ;;
  mini)
    IP_ADDR="10.99.1.2"
    PEER_IP="10.99.1.1"
    ;;
  status)
    echo "Aktuelle Konfiguration fuer '${SERVICE_NAME}':"
    networksetup -getinfo "${SERVICE_NAME}" || true
    echo ""
    echo "Aktive bridge/en-Interfaces mit 10.99.x.x:"
    ifconfig | grep -B1 -A2 "10.99." || echo "Keine 10.99.x.x IP aktiv."
    exit 0
    ;;
  *)
    echo "Verwendung: $0 {studio|mini|status}"
    exit 1
    ;;
esac

echo "Setze statische IP ${IP_ADDR} (${SUBNET_MASK}) auf '${SERVICE_NAME}'..."
sudo networksetup -setmanual "${SERVICE_NAME}" "${IP_ADDR}" "${SUBNET_MASK}" ""

echo ""
echo "Fertig! Aktuelle Konfiguration:"
networksetup -getinfo "${SERVICE_NAME}"

echo ""
echo "Hinweis: Stelle in Systemeinstellungen -> Netzwerk -> (...) -> Dienst-Reihenfolge festlegen"
echo "sicher, dass '${SERVICE_NAME}' ganz oben steht (oder nutze immer direkt ${PEER_IP} statt .local)."
echo ""
echo "Teste Verbindung zum Peer (${PEER_IP}):"
ping -c 3 -t 2 "${PEER_IP}" || echo "Peer ${PEER_IP} noch nicht erreichbar (Kabel + Gegenseite pruefen)."
