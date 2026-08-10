#!/bin/bash
# ============================================================
# TG Bot Deploy / Repair
# ============================================================

set -euo pipefail

TARGET="/opt/tg_bot"
SOURCE="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 权限运行"
    exit 1
fi

echo
echo "=========================================="
echo "       TG Bot 部署 / 修复"
echo "=========================================="
echo

if [ ! -f /etc/debian_version ]; then
    echo "⚠️ 当前不是 Debian/Ubuntu 系统，部署逻辑主要适应 Debian 系。"
fi

echo "[1/7] 检查并安装系统依赖..."
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

echo "✅ 依赖安装完成"

echo "[2/7] 创建目录结构..."
mkdir -p \
    "$TARGET/app/core" \
    "$TARGET/app/commands" \
    "$TARGET/app/modules" \
    "$TARGET/app/services" \
    "$TARGET/app/lib" \
    "$TARGET/config" \
    "$TARGET/data" \
    "$TARGET/logs" \
    "$TARGET/backups" \
    "$TARGET/scripts" \
    "$TARGET/deploy" \
    "$TARGET/systemd" \
    "$TARGET/templates" \
    "$TARGET/tests"

echo "✅ 目录创建完成"

echo "[3/7] 部署程序文件..."
SOURCE_REAL=$(readlink -f "$SOURCE" 2>/dev/null || echo "$SOURCE")
TARGET_REAL=$(readlink -f "$TARGET" 2>/dev/null || echo "$TARGET")

if [ "$SOURCE_REAL" != "$TARGET_REAL" ]; then
    [ -d "$SOURCE/app" ] && rsync -a --delete "$SOURCE/app/" "$TARGET/app/"
    [ -d "$SOURCE/scripts" ] && rsync -a --delete "$SOURCE/scripts/" "$TARGET/scripts/"
    [ -d "$SOURCE/deploy" ] && rsync -a --delete "$SOURCE/deploy/" "$TARGET/deploy/"
    [ -d "$SOURCE/systemd" ] && rsync -a --delete "$SOURCE/systemd/" "$TARGET/systemd/"
    [ -d "$SOURCE/templates" ] && rsync -a --delete "$SOURCE/templates/" "$TARGET/templates/"
    [ -d "$SOURCE/tests" ] && rsync -a --delete "$SOURCE/tests/" "$TARGET/tests/"
    
    [ -f "$SOURCE/VERSION" ] && cp "$SOURCE/VERSION" "$TARGET/VERSION"
    [ -f "$SOURCE/release.json" ] && cp "$SOURCE/release.json" "$TARGET/release.json"
else
    echo "当前正在目标运行目录内执行，跳过程序复制。"
fi

echo "✅ 程序部署完成"

echo "[4/7] 初始化配置文件..."
[ ! -f "$TARGET/config/user.env" ] && [ -f "$TARGET/templates/user.env.example" ] && cp "$TARGET/templates/user.env.example" "$TARGET/config/user.env"
[ ! -f "$TARGET/config/user.env" ] && touch "$TARGET/config/user.env"

[ ! -f "$TARGET/config/device.env" ] && [ -f "$TARGET/templates/device.env.example" ] && cp "$TARGET/templates/device.env.example" "$TARGET/config/device.env"
[ ! -f "$TARGET/config/device.env" ] && touch "$TARGET/config/device.env"

[ ! -f "$TARGET/config/system.env" ] && [ -f "$TARGET/templates/system.env.example" ] && cp "$TARGET/templates/system.env.example" "$TARGET/config/system.env"
[ ! -f "$TARGET/config/system.env" ] && touch "$TARGET/config/system.env"

chmod 600 "$TARGET/config/user.env" "$TARGET/config/device.env" "$TARGET/config/system.env"
echo "✅ 配置初始化完成"

echo "[5/7] 设置执行权限并校验语法..."
find "$TARGET/app" "$TARGET/scripts" "$TARGET/deploy" "$TARGET/tests" \
     -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

for DIR in "$TARGET/app" "$TARGET/app/core" "$TARGET/app/lib" "$TARGET/app/modules" "$TARGET/app/commands" "$TARGET/app/services"; do
    if [ -d "$DIR" ]; then
        for FILE in "$DIR"/*.sh; do
            [ -f "$FILE" ] || continue
            if ! bash -n "$FILE"; then
                echo "❌ 语法错误: $FILE"
                exit 1
            fi
        done
    fi
done

echo "✅ 权限和语法校验完成"

echo "[6/7] 配置 Systemd 服务..."
if [ -d "$TARGET/systemd" ]; then
    for UNIT in "$TARGET/systemd"/*.service "$TARGET/systemd"/*.timer; do
        [ -f "$UNIT" ] || continue
        cp "$UNIT" /etc/systemd/system/
    done
fi

systemctl daemon-reload 2>/dev/null || true

if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then
    systemctl enable tg_bot.service >/dev/null 2>&1 || true
fi

for TIMER in tg_monitor.timer tg_health.timer tg_backup.timer; do
    if systemctl list-unit-files "$TIMER" >/dev/null 2>&1; then
        systemctl enable "$TIMER" >/dev/null 2>&1 || true
    fi
done

echo "✅ Systemd 配置完成"

echo "[7/7] 安装管理快捷命令..."
if [ -f "$TARGET/deploy/manager.sh" ]; then
    ln -sf "$TARGET/deploy/manager.sh" /usr/local/bin/tg-bot
    chmod +x "$TARGET/deploy/manager.sh"
fi

if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then
    if grep -q '^TOKEN=' "$TARGET/config/user.env" 2>/dev/null; then
        systemctl restart tg_bot.service 2>/dev/null || true
    fi
fi

echo
echo "=========================================="
echo " ✅ TG Bot 部署 / 修复完成"
echo "=========================================="
echo "输入 'tg-bot' 即可进入管理菜单。"
echo
