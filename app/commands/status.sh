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


# 字节容量格式化（B -> 易读单位）
status_bytes()
{
    local B="$1"

    if [ "$B" -ge 1073741824 ]
    then
        awk -v b="$B" 'BEGIN { printf "%.1fG", b / 1073741824 }'
    elif [ "$B" -ge 1048576 ]
    then
        awk -v b="$B" 'BEGIN { printf "%.0fM", b / 1048576 }'
    else
        awk -v b="$B" 'BEGIN { printf "%.0fK", b / 1024 }'
    fi
}


# CPU 使用率计算（纯计算，便于测试）
status_cpu_usage_calc()
{
    printf '%s\n%s\n' "$1" "$2" | awk '
        NR==1 { for(i=2;i<=NF;i++) t1+=$i; idle1=$5+$6 }
        NR==2 { for(i=2;i<=NF;i++) t2+=$i; idle2=$5+$6 }
        END {
            dt=t2-t1
            di=idle2-idle1
            if (dt > 0) printf "%d", (dt-di)*100/dt
            else printf "0"
        }'
}


# 当前 CPU 使用率（两次采样 /proc/stat）
status_cpu_usage()
{
    local S1 S2

    S1=$(awk '/^cpu / {print}' /proc/stat 2>/dev/null)
    sleep 0.5
    S2=$(awk '/^cpu / {print}' /proc/stat 2>/dev/null)

    if [ -n "$S1" ] && [ -n "$S2" ]
    then
        status_cpu_usage_calc "$S1" "$S2"
    else
        echo "-"
    fi
}


# CPU 温度（thermal_zone 最大值，毫摄氏度转 °C）
status_cpu_temp()
{
    local T

    T=$(awk '{print $1}' /sys/class/thermal/thermal_zone*/temp 2>/dev/null \
    | sort -rn | head -1)

    if [ -n "$T" ] && [ "$T" -gt 0 ]
    then
        awk -v t="$T" 'BEGIN { printf "%.0f°C", t / 1000 }'
    else
        echo "未知"
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


CPU_USAGE=$(status_cpu_usage)
CPU_TEMP=$(status_cpu_temp)


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


# 网络：默认路由网卡与累计流量
IFACE=$(ip route 2>/dev/null | awk '/default/ {print $5}')
NETWORK="未知"
if [ -n "$IFACE" ]
then
    RX=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
    TX=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
    NETWORK="网卡: $IFACE · 下载: $(status_bytes "$RX") · 上传: $(status_bytes "$TX")"
fi


DOCKER_LIST=$(docker ps --format '• {{.Names}} : {{.Status}}' 2>/dev/null || true)
DOCKER_COUNT=$(printf '%s\n' "$DOCKER_LIST" | grep -c '^•' || true)
DOCKER_COUNT=${DOCKER_COUNT:-0}


MIHOMO=$(mihomo_connected)


TEXT="
📋 服务器状态汇报

🖥️ 主机: $HOST

💻 系统: $OS

⏱️ 已持续运行: $UPTIME

📊 CPU 使用率: $CPU_USAGE% · 温度: $CPU_TEMP

🧠 内存: $MEM

💾 系统盘: $ROOT_DISK

🗄️ 数据盘: $DATA_DISK

🌐 网络: $NETWORK

🐳 Docker: $DOCKER_COUNT 个容器
$DOCKER_LIST

🛰️ Mihomo:
$MIHOMO
"


telegram_send "$CHAT_ID" "$TEXT"


}
