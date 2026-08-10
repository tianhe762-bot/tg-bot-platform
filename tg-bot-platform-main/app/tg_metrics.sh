#!/bin/bash
# ============================================================
# Telegram Server Bot - Metrics Collector
# ============================================================

set -u

ROOT="/opt/tg_bot"
DATA="$ROOT/data"
LOG="$DATA/metrics.log"
LOCK="/tmp/tg_metrics.lock"

mkdir -p "$DATA"

exec 200>"$LOCK"
flock -n 200 || exit 0

TIME=$(date +%s)

read -r cpu u n s i iw irq so st g gn rest < /proc/stat
CPU_TOTAL=$((u+n+s+i+iw+irq+so+st))
CPU_IDLE=$((i+iw))

MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MEM_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
MEM_USED=$((MEM_TOTAL-MEM_AVAILABLE))

ROOT_USED=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')
DATA_USED=$(df -P /mnt/photos 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%' || echo 0)
[ -z "$DATA_USED" ] && DATA_USED=0

TEMP=""
if command -v sensors >/dev/null 2>&1; then
    TEMP=$(sensors 2>/dev/null | awk '/Package id 0/ {print $4}' | tr -d '+')
fi
[ -z "$TEMP" ] && TEMP="N/A"

IFACE=$(ip route 2>/dev/null | awk '/default/ {print $5}' | head -n 1)
IFACE=${IFACE:-eth0}
RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)

echo "$TIME CPU_TOTAL=$CPU_TOTAL CPU_IDLE=$CPU_IDLE MEM_USED=$MEM_USED MEM_TOTAL=$MEM_TOTAL ROOT=$ROOT_USED DATA=$DATA_USED TEMP=$TEMP RX=$RX TX=$TX" >> "$LOG"

CUTOFF=$(( $(date +%s) - 604800 ))
awk -v limit="$CUTOFF" '$1 >= limit' "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"

exit 0

