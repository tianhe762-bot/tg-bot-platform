#!/bin/bash
# ============================================================
# Telegram Server Bot
# Device Auto Configuration v4
#
# 第二阶段：
# 自动生成设备配置
#
# 特点：
# 1. 不依赖 sda/sdb 名称
# 2. 使用 UUID
# 3. 支持换设备
# 4. 自动检测 Mihomo API
# ============================================================


set -e


ROOT="/opt/tg_bot"
CONFIG="$ROOT/config/device.conf"


echo "================================"
echo "开始设备自动检测"
echo "================================"


# ============================================================
# 基础系统
# ============================================================


DEVICE_NAME=$(hostname)


OS_VERSION=$(grep PRETTY_NAME /etc/os-release \
| cut -d '"' -f2)


CPU_MODEL=$(lscpu \
| awk -F: '/Model name/ {print $2}' \
| xargs)


MEMORY=$(free -h \
| awk '/Mem:/ {print $2}')


SERVER_IP=$(hostname -I \
| awk '{print $1}')


MAIN_INTERFACE=$(ip route \
| awk '/default/ {print $5}')



# ============================================================
# 系统盘识别
# ============================================================


ROOT_PARTITION=$(findmnt -n -o SOURCE /)


SYSTEM_UUID=$(blkid -s UUID -o value "$ROOT_PARTITION")


SYSTEM_DISK=$(lsblk -no PKNAME "$ROOT_PARTITION")



echo
echo "系统分区:"
echo "$ROOT_PARTITION"

echo "系统UUID:"
echo "$SYSTEM_UUID"



# ============================================================
# 数据盘识别
# ============================================================


DATA_UUID=""

DATA_DISK=""

DATA_PATH="/mnt/photos"



# 优先寻找已经挂载的数据目录

if mountpoint -q "$DATA_PATH"
then

    DATA_SOURCE=$(findmnt -n -o SOURCE "$DATA_PATH")


    DATA_UUID=$(blkid "$DATA_SOURCE" \
    | sed -n 's/.*UUID="\([^"]*\)".*/\1/p')


    DATA_DISK=$(lsblk -no PKNAME "$DATA_SOURCE")


else


    # 没挂载时寻找非系统 ext4

    while read DEV
    do

UUID=$(blkid -s UUID -o value "/dev/$DEV" 2>/dev/null || true)

        if [ -n "$UUID" ] && [ "$UUID" != "$SYSTEM_UUID" ]
        then

            DATA_UUID="$UUID"

            DATA_DISK="$DEV"

            break

        fi


    done < <(lsblk -dn -o NAME)



fi



echo
echo "数据盘:"
echo "$DATA_DISK"

echo "数据UUID:"
echo "$DATA_UUID"



# ============================================================
# Docker
# ============================================================


if command -v docker >/dev/null 2>&1
then

    DOCKER_STATUS="installed"

else

    DOCKER_STATUS="not_installed"

fi



# ============================================================
# Mihomo API自动检测
# ============================================================


MIHOMO_API=""


for PORT in 9090 9097 9999
do

    RESULT=$(curl -s \
    --max-time 2 \
    "http://127.0.0.1:$PORT/" || true)


    if echo "$RESULT" | grep -q "mihomo"
    then

        MIHOMO_API="http://127.0.0.1:$PORT"

        break

    fi


done



# ============================================================
# 写入配置
# ============================================================


cat > "$CONFIG" <<EOF
# ============================================================
# 自动生成设备配置
# 时间：
# $(date)
# ============================================================


DEVICE_NAME="$DEVICE_NAME"


OS_VERSION="$OS_VERSION"


CPU_MODEL="$CPU_MODEL"


MEMORY="$MEMORY"


SERVER_IP="$SERVER_IP"


MAIN_INTERFACE="$MAIN_INTERFACE"



SYSTEM_DISK="$SYSTEM_DISK"


SYSTEM_UUID="$SYSTEM_UUID"



DATA_DISK="$DATA_DISK"


DATA_UUID="$DATA_UUID"


DATA_PATH="$DATA_PATH"



MIHOMO_API="$MIHOMO_API"



DOCKER_STATUS="$DOCKER_STATUS"

EOF



echo
echo "================================"
echo "检测完成"
echo "================================"


cat "$CONFIG"
