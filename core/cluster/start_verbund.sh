#!/bin/sh
# SS-CCC Verbund starten: Leitrechner (Rang 0) + Worker (Rang 1), ein Modell über beide Macs geteilt
# Schnittstelle danach: http://<Mac Studio>:8000/v1  (OpenAI-kompatibel)
#
# Netzwahl bei jedem Start (Adressen werden live ermittelt, DHCP-Wechsel sind egal):
#   1. Thunderbolt (10.99.1.x) erreichbar + LAN-Kabel -> beide gleichzeitig
#   2. Thunderbolt erreichbar                         -> Thunderbolt
#   3. LAN-Kabel am Studio (en0)                       -> LAN-Kabel
#   4. sonst                                           -> WLAN des Studio (Ausfallsicherung)
# Gemessen 2026-11-17: Kabel 0,6 ms / Austausch, WLAN 5,4 ms (Spitzen bis 55 ms).
# Überschreiben mit SSCCC_NET=both|tb|lan|wlan
B=${SSCCC_HOME:-/Users/Shared/ssccc}
eval "$("$B/venv/bin/python" "$B/ssccc_config.py" env)"
MODEL="$SSCCC_VERBUND_MODEL"
MINI="$SSCCC_WORKER_SSH"
[ -n "$MINI" ] || { echo "[SS-CCC] Kein Worker in cluster.json – Verbund-Modus braucht zwei Macs"; exit 1; }

ip_of() { ipconfig getifaddr "$1" 2>/dev/null; }
STUDIO_LAN=$(ip_of en0)
STUDIO_WLAN=$(ip_of en1)
MINI_LAN=$(ssh -o BatchMode=yes -o ConnectTimeout=5 $MINI 'ipconfig getifaddr en0 || ipconfig getifaddr en1' 2>/dev/null)
[ -z "$MINI_LAN" ] && MINI_LAN=$(ssh -G $MINI | awk '/^hostname /{print $2}')
TB_UP=0; ping -c1 -t1 10.99.1.2 >/dev/null 2>&1 && TB_UP=1

NET="${SSCCC_NET:-auto}"
if [ "$NET" = "auto" ]; then
  if   [ $TB_UP = 1 ] && [ -n "$STUDIO_LAN" ]; then NET=both
  elif [ $TB_UP = 1 ]; then NET=tb
  elif [ -n "$STUDIO_LAN" ]; then NET=lan
  else NET=wlan; fi
fi
case "$NET" in
  both) S_IPS="\"10.99.1.1\", \"$STUDIO_LAN\""; M_IPS="\"10.99.1.2\", \"$MINI_LAN\""; LINK="Thunderbolt + LAN-Kabel gleichzeitig" ;;
  tb)   S_IPS="\"10.99.1.1\"";                  M_IPS="\"10.99.1.2\"";               LINK="Thunderbolt" ;;
  lan)  S_IPS="\"$STUDIO_LAN\"";                M_IPS="\"$MINI_LAN\"";               LINK="LAN-Kabel" ;;
  *)    S_IPS="\"$STUDIO_WLAN\"";               M_IPS="\"$MINI_LAN\"";               LINK="WLAN (Ausfallsicherung)" ;;
esac
HOSTFILE="$B/hostfile_aktiv.json"
cat > "$HOSTFILE" <<EOF
[
  {"ssh": "127.0.0.1", "ips": [$S_IPS]},
  {"ssh": "$MINI", "ips": [$M_IPS]}
]
EOF
echo "[SS-CCC] $(date '+%Y-%m-%d %H:%M:%S') Verbindung: $LINK | Studio [$S_IPS] <-> Mini [$M_IPS]"

# Optimierte Aufteilung (gemessen 2026-11-17: 7,9 -> 11,6 tok/s über LAN-Kabel; 62,2 = 12,4 tok/s, aber Studio-RAM knapp):
#   60/4 Schichten (SSCCC_SPLIT überschreibbar), Embedding nur auf dem letzten Rang, lm_head nach Vokabular geteilt,
#   8-Bit-KV-Cache ab 4096 Token (stabil bis ~67k Token Kontext).
exec "$B/venv/bin/mlx.launch" \
  --backend ring \
  --hostfile "$HOSTFILE" \
  --python "$B/venv/bin/python" \
  --cwd "$B" \
  --env SSCCC_SPLIT=${SSCCC_SPLIT:-$SSCCC_DEFAULT_SPLIT} \
  --env SSCCC_DROP_EMBED=1 \
  --env SSCCC_VERBUND_REPO="$SSCCC_VERBUND_REPO" \
  --env SSCCC_SHARD_LMHEAD=1 \
  --env MLX_METAL_FAST_SYNCH=1 \
  --env HF_HOME=$B/hf \
  --env "SSCCC_SERVER_ARGS=--model $MODEL --pipeline --host 0.0.0.0 --port $SSCCC_PORT --prefill-step-size 512 --prompt-concurrency 2 --prompt-cache-size 4 --prompt-cache-bytes 1GB --kv-bits 8 --quantized-kv-start 4096 $*" \
  "$B/ssccc_server.py"
