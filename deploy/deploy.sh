#!/bin/bash
# ============================================================
# TG Bot Deploy / Repair
# ============================================================

set -e

TARGET="/opt/tg_bot"

SOURCE="${1:-$(cd "$(dirname "$0")/.." && pwd)}"


# ============================================================
# Root检查
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 权限运行"
    exit 1
fi


echo
echo "=========================================="
echo " TG Bot 部署 / 修复"
echo "=========================================="
echo


# ============================================================
# 系统检查
# ============================================================

if [ ! -f /etc/debian_version ]; then
    echo "⚠️ 当前不是 Debian/Ubuntu 系统。"
    echo "安装器暂时主要针对 Debian 系。"
fi


# ============================================================
# 安装依赖
# ============================================================

echo "[1/7] 检查依赖..."

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

echo "✅ 依赖完成"


# ============================================================
# 创建目录
# ============================================================

echo "[2/7] 创建目录..."

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

echo "✅ 目录完成"


# ============================================================
# 部署程序
# ============================================================

echo "[3/7] 部署程序..."


SOURCE_REAL=$(readlink -f "$SOURCE")
TARGET_REAL=$(readlink -f "$TARGET")


if [ "$SOURCE_REAL" != "$TARGET_REAL" ]; then

    [ -d "$SOURCE/app" ] && \
    rsync -a --delete "$SOURCE/app/" "$TARGET/app/"

    [ -d "$SOURCE/scripts" ] && \
    rsync -a --delete "$SOURCE/scripts/" "$TARGET/scripts/"

    [ -d "$SOURCE/deploy" ] && \
    rsync -a --delete "$SOURCE/deploy/" "$TARGET/deploy/"

    [ -d "$SOURCE/systemd" ] && \
    rsync -a --delete "$SOURCE/systemd/" "$TARGET/systemd/"

    [ -d "$SOURCE/templates" ] && \
    rsync -a --delete "$SOURCE/templates/" "$TARGET/templates/"

    [ -d "$SOURCE/tests" ] && \
    rsync -a --delete "$SOURCE/tests/" "$TARGET/tests/"

    if [ -f "$SOURCE/VERSION" ]; then
        cp "$SOURCE/VERSION" "$TARGET/VERSION"
    fi

else

    echo "当前正在本机目录内执行，跳过程序复制。"

fi


echo "✅ 程序完成"


# ============================================================
# 初始化配置
# ============================================================

echo "[4/7] 初始化配置..."


# user.env
if [ ! -f "$TARGET/config/user.env" ]; then

    if [ -f "$TARGET/templates/user.env.example" ]; then
        cp "$TARGET/templates/user.env.example" \
           "$TARGET/config/user.env"
    else
        touch "$TARGET/config/user.env"
    fi

fi


# device.env
if [ ! -f "$TARGET/config/device.env" ]; then

    if [ -f "$TARGET/templates/device.env.example" ]; then
        cp "$TARGET/templates/device.env.example" \
           "$TARGET/config/device.env"
    else
        touch "$TARGET/config/device.env"
    fi

fi


# system.env
if [ ! -f "$TARGET/config/system.env" ]; then

    if [ -f "$TARGET/templates/system.env.example" ]; then
        cp "$TARGET/templates/system.env.example" \
           "$TARGET/config/system.env"
    else
        touch "$TARGET/config/system.env"
    fi

fi


chmod 600 \
    "$TARGET/config/user.env" \
    "$TARGET/config/device.env" \
    "$TARGET/config/system.env"


echo "✅ 配置完成"

# ============================================================
# 权限与语法
# ============================================================

echo "[5/7] 设置权限..."


find "$TARGET/app" \
     "$TARGET/scripts" \
     "$TARGET/deploy" \
     "$TARGET/tests" \
     -type f -name "*.sh" \
     -exec chmod +x {} \; 2>/dev/null || true


if [ -f "$TARGET/app/tg_bot.sh" ]; then

    if ! bash -n "$TARGET/app/tg_bot.sh"; then
        echo "❌ tg_bot.sh 语法错误"
        exit 1
    fi

fi


for DIR in \
    "$TARGET/app/core" \
    "$TARGET/app/lib" \
    "$TARGET/app/modules" \
    "$TARGET/app/commands" \
    "$TARGET/app/services"

do

    if [ -d "$DIR" ]; then

        for FILE in "$DIR"/*.sh
        do

            [ -f "$FILE" ] || continue

            if ! bash -n "$FILE"; then
                echo "❌ 语法错误: $FILE"
                exit 1
            fi

        done

    fi

done


echo "✅ 权限和语法完成"


# ============================================================
# systemd
# ============================================================

echo "[6/7] 配置 systemd..."


if [ -d "$TARGET/systemd" ]; then

    for UNIT in "$TARGET/systemd"/*.service "$TARGET/systemd"/*.timer
    do

        [ -f "$UNIT" ] || continue

        cp "$UNIT" /etc/systemd/system/

    done

fi


systemctl daemon-reload


if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then

    systemctl enable tg_bot.service >/dev/null 2>&1 || true

fi


for TIMER in tg_monitor.timer tg_health.timer tg_backup.timer
do

    if systemctl list-unit-files "$TIMER" >/dev/null 2>&1; then

        systemctl enable "$TIMER" >/dev/null 2>&1 || true

    fi

done


echo "✅ systemd完成"


# ============================================================
# 安装管理命令
# ============================================================

echo "[7/7] 安装管理菜单..."


if [ -f "$TARGET/deploy/manager.sh" ]; then

    ln -sf "$TARGET/deploy/manager.sh" /usr/local/bin/tg-bot

    chmod +x "$TARGET/deploy/manager.sh"

fi


if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then

    if grep -q '^TOKEN=' "$TARGET/config/user.env" 2>/dev/null; then
        systemctl restart tg_bot.service || true
    fi

fi


echo
echo "=========================================="
echo " ✅ TG Bot 部署 / 修复完成"
echo "=========================================="
echo
echo "管理命令:"
echo
echo "    tg-bot"
echo
