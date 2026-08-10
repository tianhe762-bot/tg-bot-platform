#!/bin/bash
# ============================================================
# Telegram Server Bot
# Installation Framework
#
# 第一阶段：
# 创建项目结构
# 不安装Bot
# 不修改系统服务
# ============================================================

set -e


ROOT="/opt/tg_bot"


echo "================================"
echo "创建 Telegram Bot 项目目录"
echo "================================"


mkdir -p "$ROOT"

mkdir -p "$ROOT/app"

mkdir -p "$ROOT/config"

mkdir -p "$ROOT/data"

mkdir -p "$ROOT/logs"

mkdir -p "$ROOT/backups"

mkdir -p "$ROOT/scripts"



echo
echo "================================"
echo "创建默认配置文件"
echo "================================"


cat > "$ROOT/config/default.conf" <<'EOF'
# ============================================================
# Telegram Server Bot
# Default Configuration
#
# 此文件属于程序默认值
# 不建议修改
# ============================================================


# 项目路径

TG_ROOT="/opt/tg_bot"

APP_DIR="/opt/tg_bot/app"

DATA_DIR="/opt/tg_bot/data"

LOG_DIR="/opt/tg_bot/logs"



# 默认历史保存

METRICS_DAYS=7


# 默认消息长度

MESSAGE_LIMIT=3900


# 默认检测端口

MIHOMO_SCAN_PORTS="9090 9097 9999"


EOF



echo
echo "================================"
echo "创建空设备配置"
echo "================================"


cat > "$ROOT/config/device.conf" <<'EOF'
# ============================================================
# Device Configuration
#
# 自动生成或通过 reconfigure.sh 修改
# ============================================================


DEVICE_NAME=""


OS_VERSION=""


CPU_MODEL=""


MEMORY=""


SERVER_IP=""


MAIN_INTERFACE=""


DATA_DISK=""


DATA_UUID=""


MIHOMO_API=""


DOCKER_STATUS=""


EOF



echo
echo "================================"
echo "创建用户配置模板"
echo "================================"


cat > "$ROOT/config/user.conf" <<'EOF'
# ============================================================
# User Configuration
# 用户需要填写
# ============================================================


# Telegram Bot Token

TOKEN=""


# 管理员Telegram数字ID

ADMINS=""


# WOL目标电脑MAC

WIN_MAC=""


EOF



echo
echo "================================"
echo "创建基础文件"
echo "================================"


touch "$ROOT/data/metrics.log"

touch "$ROOT/data/update_offset"

touch "$ROOT/logs/tg_bot.log"



echo
echo "================================"
echo "权限设置"
echo "================================"


chmod 700 "$ROOT"

chmod 700 "$ROOT/scripts"

chmod 600 "$ROOT/config/"*.conf



echo
echo "================================"
echo "安装框架完成"
echo "================================"


echo

echo "目录:"
tree "$ROOT" 2>/dev/null || ls -R "$ROOT"
