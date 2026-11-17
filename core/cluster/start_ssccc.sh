#!/bin/sh
# SS-CCC Start (vom LaunchAgent aufgerufen). Betriebsart in /Users/Shared/ssccc/modus:
#   multimodel  – Leitrechner: Sprachmodell + MTP und Bildmodell auf Abruf; Worker als Reserve  [Standard]
#   verbund     – ein Sprachmodell über Leitrechner + Worker geteilt (mlx.launch ring)
# Umschalten:  echo verbund > /Users/Shared/ssccc/modus && launchctl kickstart -k gui/$(id -u)/de.sonnerstudio.ssccc-verbund
B=${SSCCC_HOME:-/Users/Shared/ssccc}
MODUS=$(cat "$B/modus" 2>/dev/null || "$B/venv/bin/python" -c "import sys; sys.path.insert(0,'$B'); import ssccc_config; print(ssccc_config.load()['mode'])")
echo "[SS-CCC] $(date '+%Y-%m-%d %H:%M:%S') Betriebsart: $MODUS"
case "$MODUS" in
  verbund) exec "$B/start_verbund.sh" "$@" ;;
  *)       exec "$B/venv/bin/python" "$B/ssccc_gateway.py" ;;
esac
