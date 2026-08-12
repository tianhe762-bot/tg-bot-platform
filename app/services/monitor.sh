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
    STATE_FILE="$ROOT/data/docker_alert.state"
    ABNORMAL=""
    if [ -n "$(docker ps -aq 2>/dev/null)" ]; then
        ABNORMAL=$(docker inspect -f '{{.Name}}|{{.State.Status}}|{{.State.ExitCode}}' $(docker ps -aq) 2>/dev/null \
            | awk -F'|' '$2=="exited" && $3!="0" {n=$1; sub(/^\//,"",n); print n " (code " $3 ")"}' \
            | sort -u | tr '\n' ' ' | sed 's/ $//')
    fi
    PREV=""
    [ -f "$STATE_FILE" ] && PREV=$(cat "$STATE_FILE" 2>/dev/null)
    if [ -n "$ABNORMAL" ]; then
        if [ "$ABNORMAL" != "$PREV" ]; then
            send_alert "Docker 异常退出容器: $ABNORMAL"
            printf '%s\n' "$ABNORMAL" > "$STATE_FILE"
        fi
    elif [ -n "$PREV" ]; then
        send_alert "Docker 异常已恢复"
        : > "$STATE_FILE"
    fi
fi
