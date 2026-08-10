#!/bin/bash
# ============================================================
# Monitor Service
# ============================================================


ROOT="/opt/tg_bot"



source "$ROOT/app/lib/config.sh"

source "$ROOT/app/lib/telegram.sh"

source "$ROOT/app/modules/alert.sh"



load_config



# CPU Load


LOAD=$(cat /proc/loadavg | awk '{print $1}')



CPU_INT=${LOAD%.*}



if [ "$CPU_INT" -ge 4 ]

then

send_alert "CPU负载过高:

$LOAD"

fi



# 内存


MEM_TOTAL=$(free | awk '/Mem/ {print $2}')

MEM_FREE=$(free | awk '/Mem/ {print $7}')



USED=$((100*(MEM_TOTAL-MEM_FREE)/MEM_TOTAL))



if [ "$USED" -ge 90 ]

then

send_alert "内存使用率:

${USED}%"

fi



# 磁盘


DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')



if [ "$DISK" -ge 90 ]

then

send_alert "系统盘空间不足:

${DISK}%"

fi



# Docker


if command -v docker >/dev/null

then


STOPPED=$(docker ps -a \
--filter "status=exited" \
-q | wc -l)



if [ "$STOPPED" -gt 0 ]

then

send_alert "存在异常退出Docker容器:

$STOPPED"

fi


fi
