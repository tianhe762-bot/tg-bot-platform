#!/bin/bash


# 内存容量格式化（KB -> 易读单位）
status_size()
{
    local KB="$1"

    if [ "$KB" -ge 1048576 ]
    then
        awk -v k="$KB" 'BEGIN { printf "%.1fG", k / 1048576 }'
    else
        awk -v k="$KB" 'BEGIN { printf "%.0fM", k / 1024 }'
    fi
}


status_execute()
{

CHAT_ID="$1"


# 主机名：优先使用设备配置，未配置时自动检测
HOST="${DEVICE_NAME:-}"
if [ -z "$HOST" ]
then
    HOST=$(hostname 2>/dev/null || echo "unknown")
fi


# 系统信息：优先使用设备配置，未配置时读取 /etc/os-release
OS="${OS_VERSION:-}"
if [ -z "$OS" ] && [ -r /etc/os-release ]
then
    OS=$(awk -F= '/^PRETTY_NAME=/ {gsub(/["\r]/, "", $2); print $2}' /etc/os-release)
fi
[ -z "$OS" ] && OS=$(uname -srm 2>/dev/null || echo "unknown")


UPTIME=$(uptime -p)


CPU_LOAD=$(uptime \
| sed -n 's/.*load average: *\([0-9.]*\), *\([0-9.]*\), *\([0-9.]*\).*/\1 \2 \3/p')
LOAD1=$(echo "$CPU_LOAD" | awk '{print $1}')
LOAD5=$(echo "$CPU_LOAD" | awk '{print $2}')
LOAD15=$(echo "$CPU_LOAD" | awk '{print $3}')
[ -z "$LOAD1" ] && LOAD1="-"
[ -z "$LOAD5" ] && LOAD5="-"
[ -z "$LOAD15" ] && LOAD15="-"


# 内存：直接读取 /proc/meminfo，避免依赖 free 命令
MEM_TOTAL_KB=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
MEM_AVAIL_KB=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
if [ -n "$MEM_TOTAL_KB" ] && [ -n "$MEM_AVAIL_KB" ] && [ "$MEM_TOTAL_KB" -gt 0 ]
then
    MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
    MEM_PERCENT=$((MEM_USED_KB * 100 / MEM_TOTAL_KB))
    MEM="$(status_size "$MEM_USED_KB") / $(status_size "$MEM_TOTAL_KB")（$MEM_PERCENT%）"
else
    MEM="未知"
fi


ROOT_DISK=$(df -h / \
| awk 'NR==2 {print $5}')


DATA_DISK=$(df -h /mnt/photos 2>/dev/null \
| awk 'NR==2 {print $5}')
[ -z "$DATA_DISK" ] && DATA_DISK="未挂载"


DOCKER_LIST=$(docker ps --format '• {{.Names}} : {{.Status}}' 2>/dev/null || true)
DOCKER_COUNT=$(printf '%s\n' "$DOCKER_LIST" | grep -c '^•' || true)
DOCKER_COUNT=${DOCKER_COUNT:-0}


MIHOMO=$(mihomo_connected)


TEXT="
📋 服务器状态汇报

🖥️ 主机: $HOST

💻 系统: $OS

⏱️ 已持续运行: $UPTIME

📊 CPU 负载: 1分钟 $LOAD1 · 5分钟 $LOAD5 · 15分钟 $LOAD15

🧠 内存: $MEM

💾 系统盘: $ROOT_DISK

🗄️ 数据盘: $DATA_DISK

🐳 Docker: $DOCKER_COUNT 个容器
$DOCKER_LIST

🛰️ Mihomo:
$MIHOMO
"


telegram_send "$CHAT_ID" "$TEXT"


}
