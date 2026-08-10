#!/bin/bash
# ============================================================
# TG Bot First Setup Wizard
# ============================================================


ROOT="/opt/tg_bot"

CONFIG="$ROOT/config"


mkdir -p "$CONFIG"


set_value()
{
    FILE="$1"
    KEY="$2"
    VALUE="$3"

    touch "$FILE"

    sed -i "/^${KEY}=/d" "$FILE"

    echo "${KEY}=\"${VALUE}\"" >> "$FILE"
}



clear

echo "=========================================="
echo "       TG Bot 首次安装向导"
echo "=========================================="

echo


# ============================================================
# Telegram
# ============================================================

echo "[1/5] Telegram 配置"

echo

read -rp "请输入 Bot Token: " TOKEN


read -rp "请输入管理员 Telegram ID: " ADMIN_ID


read -rp "请输入报警 Chat ID (默认管理员ID): " CHAT_ID



if [ -z "$CHAT_ID" ]

then

CHAT_ID="$ADMIN_ID"

fi



set_value \
"$CONFIG/user.env" \
"TOKEN" \
"$TOKEN"


set_value \
"$CONFIG/user.env" \
"ADMINS" \
"$ADMIN_ID"


set_value \
"$CONFIG/user.env" \
"ADMIN_CHAT_ID" \
"$CHAT_ID"



echo "✅ Telegram配置完成"

echo



# ============================================================
# WOL
# ============================================================

echo "[2/5] WOL 配置"

echo


read -rp "是否配置WOL唤醒电脑? (Y/n): " WOL_ENABLE



if [[ "$WOL_ENABLE" != "n" && "$WOL_ENABLE" != "N" ]]

then


read -rp "请输入电脑MAC地址: " MAC


set_value \
"$CONFIG/user.env" \
"WIN_MAC" \
"$MAC"


echo "✅ WOL配置完成"


else


echo "跳过WOL"


fi


echo



# ============================================================
# Mihomo
# ============================================================

echo "[3/5] Mihomo配置"

echo


read -rp "是否使用Mihomo? (Y/n): " MIHOMO_ENABLE



if [[ "$MIHOMO_ENABLE" != "n" && "$MIHOMO_ENABLE" != "N" ]]

then


read -rp "请输入Mihomo API地址 [http://127.0.0.1:9999]: " API



if [ -z "$API" ]

then

API="http://127.0.0.1:9999"

fi



set_value \
"$CONFIG/system.env" \
"MIHOMO_API" \
"$API"


echo "✅ Mihomo配置完成"


else


echo "跳过Mihomo"


fi



echo



# ============================================================
# 数据目录
# ============================================================

echo "[4/5] 数据目录"


read -rp "请输入数据目录 [/mnt/photos]: " DATA



if [ -z "$DATA" ]

then

DATA="/mnt/photos"

fi



set_value \
"$CONFIG/device.env" \
"DATA_PATH" \
"$DATA"



echo "✅ 数据目录完成"


echo



# ============================================================
# 更新源
# ============================================================

echo "[5/5] 更新配置"


read -rp "请输入VERSION地址(可空): " VERSION_URL


read -rp "请输入软件包地址(可空): " PACKAGE_URL



if [ -n "$VERSION_URL" ]

then

set_value \
"$CONFIG/system.env" \
"TG_VERSION_URL" \
"$VERSION_URL"

fi



if [ -n "$PACKAGE_URL" ]

then

set_value \
"$CONFIG/system.env" \
"TG_PACKAGE_URL" \
"$PACKAGE_URL"

fi



chmod 600 \
"$CONFIG"/*.env



echo

echo "=========================================="
echo " 配置完成"
echo "=========================================="

echo


read -rp "现在启动TG Bot? (Y/n): " START



if [[ "$START" != "n" && "$START" != "N" ]]

then

systemctl daemon-reload

systemctl enable tg_bot.service 2>/dev/null || true

systemctl restart tg_bot.service 2>/dev/null || true


echo

echo "✅ TG Bot 已启动"


fi
