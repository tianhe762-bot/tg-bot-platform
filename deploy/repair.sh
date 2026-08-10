#!/bin/bash
# ============================================================
# TG Bot Repair
# ============================================================


ROOT="/opt/tg_bot"


echo

echo "=========================================="
echo "        TG Bot 自动修复"
echo "=========================================="

echo



echo "[1] 检查依赖"



apt-get update -qq


apt-get install -y \
curl \
jq \
wakeonlan \
rsync \
tar \
ca-certificates \
iproute2 \
util-linux \
>/dev/null



echo "✅ 依赖完成"



echo



echo "[2] 修复权限"


find "$ROOT" \
-type f \
-name "*.sh" \
-exec chmod +x {} \;



echo "✅ 权限完成"



echo



echo "[3] 修复配置"



for FILE in \
user.env \
device.env \
system.env

do


if [ ! -f "$ROOT/config/$FILE" ]

then


case "$FILE" in

user.env)

cp "$ROOT/templates/user.env.example" \
"$ROOT/config/user.env"

;;

device.env)

cp "$ROOT/templates/device.env.example" \
"$ROOT/config/device.env"

;;

system.env)

cp "$ROOT/templates/system.env.example" \
"$ROOT/config/system.env"

;;

esac


fi


done



echo "✅ 配置完成"



echo



echo "[4] systemd"


systemctl daemon-reload



echo "✅ systemd完成"



echo



echo "[5] 重启Bot"


systemctl restart tg_bot.service 2>/dev/null || true



echo

echo "=========================================="
echo "修复完成"
echo "=========================================="
