#!/bin/bash
# ============================================================
# Monitor Service
# ============================================================

ROOT="/opt/tg_bot"

source "$ROOT/app/lib/config.sh"
source "$ROOT/app/lib/telegram.sh"
source "$ROOT/app/modules/alert.sh"

load_config

LOAD=$(cat /proc/loadavg | awk '{print $1}')
CPU_INT=${LOAD%.*}

if [ "$CPU_INT" -ge 4 ]; then
    send_alert "CPU负载过高: $LOAD"
fi

MEM_TOTAL=$(free | awk '/Mem/ {print $2}')
MEM_FREE=$(free | awk '/Mem/ {print $7}')

if [ -n "$MEM_TOTAL" ] && [ "$MEM_TOTAL" -gt 0 ]; then
    USED=$((100*(MEM_TOTAL-MEM_FREE)/MEM_TOTAL))
    if [ "$USED" -ge 90 ]; then
        send_alert "内存使用率: ${USED}%"
    fi
fi

DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK" -ge 90 ]; then
    send_alert "系统盘空间不足: ${DISK}%"
fi

if command -v docker >/dev/null 2>&1; then
    STOPPED=$(docker ps -a --filter "status=exited" -q 2>/dev/null | wc -l || echo 0)
    if [ "$STOPPED" -gt 0 ]; then
        send_alert "存在异常退出的 Docker 容器数量: $STOPPED"
    fi
fi

