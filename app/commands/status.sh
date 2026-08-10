#!/bin/bash


status_execute()
{


CHAT_ID="$1"



UPTIME=$(uptime -p)


CPU=$(uptime \
| awk -F'load average:' '{print $2}')


MEM=$(free -h \
| awk '/Mem:/ {print $3" / "$2}')


ROOT_DISK=$(df -h / \
| awk 'NR==2 {print $5}')


DATA_DISK=$(df -h /mnt/photos 2>/dev/null \
| awk 'NR==2 {print $5}')


DOCKER_COUNT=$(docker ps -q 2>/dev/null | wc -l)


MIHOMO=$(curl -s \
--max-time 2 \
"${MIHOMO_API:-http://127.0.0.1:9999}/version")



TEXT="
🖥 服务器状态

主机:
${DEVICE_NAME:-unknown}

系统:
${OS_VERSION:-unknown}

运行:
$UPTIME

CPU:
$CPU

内存:
$MEM

系统盘:
$ROOT_DISK

数据盘:
$DATA_DISK

Docker:
$DOCKER_COUNT 个容器

Mihomo:
$MIHOMO
"



telegram_send "$CHAT_ID" "$TEXT"


}
