#!/bin/bash
# ============================================================
# TG Bot Repair
# ============================================================

set -euo pipefail

ROOT="/opt/tg_bot"

echo "=========================================="
echo "        TG Bot 自动修复"
echo "=========================================="
echo

echo "[1] 检查并修复系统依赖..."
export DEBIAN_FRONTEND=noninteractive
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
echo "✅ 依赖修复完成"
echo

echo "[2] 修复脚本权限..."
find "$ROOT" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "✅ 权限修复完成"
echo

echo "[3] 修复基础配置文件..."
mkdir -p "$ROOT/config"
for FILE in user.env device.env system.env; do
    if [ ! -f "$ROOT/config/$FILE" ]; then
        case "$FILE" in
            user.env)
                [ -f "$ROOT/templates/user.env.example" ] && cp "$ROOT/templates/user.env.example" "$ROOT/config/user.env" || touch "$ROOT/config/user.env"
                ;;
            device.env)
                [ -f "$ROOT/templates/device.env.example" ] && cp "$ROOT/templates/device.env.example" "$ROOT/config/device.env" || touch "$ROOT/config/device.env"
                ;;
            system.env)
                [ -f "$ROOT/templates/system.env.example" ] && cp "$ROOT/templates/system.env.example" "$ROOT/config/system.env" || touch "$ROOT/config/system.env"
                ;;
        esac
    fi
done
chmod 600 "$ROOT/config"/*.env 2>/dev/null || true
echo "✅ 配置修复完成"
echo

echo "[4] 重新加载 Systemd 配置..."
systemctl daemon-reload 2>/dev/null || true
echo "✅ Systemd 完成"
echo

echo "[5] 重启 TG Bot 服务..."
if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then
    systemctl restart tg_bot.service 2>/dev/null || true
fi

echo
echo "=========================================="
echo " ✅ 自动修复完成"
echo "=========================================="
