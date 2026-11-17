#!/bin/sh
# Gibt die echten Hardware-Daten dieses Macs als JSON aus (für den SS-CCC-Verbundstatus).
s() { /usr/sbin/sysctl -n "$1" 2>/dev/null; }
NAME=$(scutil --get ComputerName 2>/dev/null)
CHIP=$(s machdep.cpu.brand_string)
MODEL=$(s hw.model)
RAM=$(s hw.memsize)
P=$(s hw.perflevel0.physicalcpu); E=$(s hw.perflevel1.physicalcpu)
WIRED=$(s iogpu.wired_limit_mb)
GPU=$(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Total Number of Cores/{print $2; exit}')
OS=$(sw_vers -productVersion)
LAN=$(ipconfig getifaddr en0 2>/dev/null); WLAN=$(ipconfig getifaddr en1 2>/dev/null)
TB=$(ifconfig bridge0 2>/dev/null | awk '/inet 10\.99/{print $2}')
DISK=$(df -k /System/Volumes/Data | awk 'NR==2{print $2, $4}')
THERM=$(pmset -g therm 2>/dev/null | awk -F'= ' '/CPU_Speed_Limit/{print $2}')
B=${SSCCC_HOME:-/Users/Shared/ssccc}
M=$("$B/venv/bin/python" -c "import sys; sys.path.insert(0,'$B'); import ssccc_config as c; print(c.path(c.load()['verbund']['model_dir']))" 2>/dev/null)
MODEL_OK=false; [ -f "$M/config.json" ] && ls "$M"/*.safetensors >/dev/null 2>&1 && MODEL_OK=true
MLX_OK=false; [ -x "$B/venv/bin/python" ] && MLX_OK=true
WIRED_PERSIST=false; [ -f /Library/LaunchDaemons/de.sonnerstudio.wiredlimit.plist ] && WIRED_PERSIST=true
printf '{"name":"%s","chip":"%s","model":"%s","ram_bytes":%s,"p_cores":%s,"e_cores":%s,"gpu_cores":%s,"wired_limit_mb":%s,"os":"%s","lan_ip":"%s","wlan_ip":"%s","tb_ip":"%s","ssd_total_kb":%s,"ssd_free_kb":%s,"cpu_speed_limit":"%s","model_ok":%s,"mlx_ok":%s,"wired_persistent":%s}\n' \
  "$NAME" "$CHIP" "$MODEL" "${RAM:-0}" "${P:-0}" "${E:-0}" "${GPU:-0}" "${WIRED:-0}" "$OS" "$LAN" "$WLAN" "$TB" $DISK "${THERM:-100}" "$MODEL_OK" "$MLX_OK" "$WIRED_PERSIST"
