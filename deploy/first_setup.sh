#!/bin/bash
# ============================================================
# TG Bot First Setup Wizard
# ============================================================

set -euo pipefail

ROOT="/opt/tg_bot"
CONFIG="$ROOT/config"

mkdir -p "$CONFIG"

set_value() {
    local FILE="$1"
    local KEY="$2"
    local VALUE="$3"

    touch "$FILE"
    sed -i "/^${KEY}=/d" "$FILE"
    echo "${KEY}=\"${VALUE}\"" >> "$FILE"
}

clear

echo "=========================================="
echo "       TG Bot 首次安装向导"
echo "=========================================="
echo

# [1/5] Telegram
echo "[1/5] Telegram 配置"
echo
read -rp "请输入 Bot Token: " TOKEN
read -rp "请输入管理员 Telegram ID: " ADMIN_ID
read -rp "请输入报警 Chat ID [默认同管理员ID]: " CHAT_ID

if [ -z "$CHAT_ID" ]; then
    CHAT_ID="$ADMIN_ID"
fi

set_value "$CONFIG/user.env" "TOKEN" "$TOKEN"
set_value "$CONFIG/user.env" "ADMINS" "$ADMIN_ID"
set_value "$CONFIG/user.env" "ADMIN_CHAT_ID" "$CHAT_ID"

echo "✅ Telegram 配置完成"
echo

# [2/5] WOL
echo "[2/5] WOL 配置"
echo
read -rp "是否配置 WOL 唤醒电脑? (Y/n): " WOL_ENABLE

if [[ "$WOL_ENABLE" != "n" && "$WOL_ENABLE" != "N" ]]; then
    read -rp "请输入电脑 MAC 地址: " MAC
    set_value "$CONFIG/user.env" "WIN_MAC" "$MAC"
    echo "✅ WOL 配置完成"
else
    echo "跳过 WOL 配置"
fi
echo

# [3/5] Mihomo
echo "[3/5] Mihomo 配置"
echo
read -rp "是否配置 Mihomo 代理? (Y/n): " MIHOMO_ENABLE

if [[ "$MIHOMO_ENABLE" != "n" && "$MIHOMO_ENABLE" != "N" ]]; then
    read -rp "请输入 Mihomo API 地址 [http://127.0.0.1:9999]: " API
    if [ -z "$API" ]; then
        API="http://127.0.0.1:9999"
    fi
    set_value "$CONFIG/system.env" "MIHOMO_API" "$API"
    echo "✅ Mihomo 配置完成"
else
    echo "跳过 Mihomo 配置"
fi
echo

# [4/5] 数据目录
echo "[4/5] 数据存储目录"
read -rp "请输入数据目录 [/mnt/photos]: " DATA
if [ -z "$DATA" ]; then
    DATA="/mnt/photos"
fi
set_value "$CONFIG/device.env" "DATA_PATH" "$DATA"
echo "✅ 数据目录设置完成: $DATA"
echo

# [5/5] 更新源配置
echo "[5/5] 更新源设置"
echo "默认将通过 GitHub Release 自动更新到最新版本。"
read -rp "请输入自定义安装包地址 (留空使用官方 GitHub 自动更新): " PACKAGE_URL

if [ -n "$PACKAGE_URL" ]; then
    set_value "$CONFIG/system.env" "TG_BOT_PACKAGE_URL" "$PACKAGE_URL"
fi

chmod 600 "$CONFIG"/*.env 2>/dev/null || true

echo
echo "=========================================="
echo " 配置完成"
echo "=========================================="
echo

read -rp "现在启动 TG Bot 服务? (Y/n): " START

if [[ "$START" != "n" && "$START" != "N" ]]; then
    systemctl daemon-reload 2>/dev/null || true
    systemctl enable tg_bot.service 2>/dev/null || true
    systemctl restart tg_bot.service 2>/dev/null || true
    echo
    echo "✅ TG Bot 已尝试启动"
fi
