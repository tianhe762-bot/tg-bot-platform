#!/bin/bash
# ============================================================
# TG Bot Bootstrap Installer
#
# Usage:
#
# bash install.sh
#
# 或
#
# bash install.sh https://example.com/tg_bot.tar.gz
#
# ============================================================

set -e


if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 权限运行"
    exit 1
fi


clear


echo "=========================================="
echo "       TG Bot Installer"
echo "=========================================="
echo


PACKAGE_URL="${1:-${TG_BOT_PACKAGE_URL:-}}"


# ============================================================
# 输入安装包地址
# ============================================================

if [ -z "$PACKAGE_URL" ]; then

    echo "请输入 TG Bot 程序安装包地址。"
    echo
    echo "要求为 .tar.gz 文件，例如:"
    echo
    echo "https://example.com/releases/tg_bot-latest.tar.gz"
    echo

    read -rp "安装包 URL: " PACKAGE_URL

fi


if [ -z "$PACKAGE_URL" ]; then
    echo "❌ URL不能为空"
    exit 1
fi


echo
echo "程序来源:"
echo "$PACKAGE_URL"
echo


# ============================================================
# Bootstrap依赖
# ============================================================

echo "[1/4] 安装基础工具..."


export DEBIAN_FRONTEND=noninteractive


apt-get update -qq


apt-get install -y \
    curl \
    ca-certificates \
    tar \
    rsync \
    >/dev/null


echo "✅ 完成"


# ============================================================
# 下载
# ============================================================

echo
echo "[2/4] 下载程序..."


TMP_DIR=$(mktemp -d)

PACKAGE="$TMP_DIR/tg_bot.tar.gz"

EXTRACT="$TMP_DIR/extract"


mkdir -p "$EXTRACT"


if ! curl -fL \
    --connect-timeout 15 \
    --retry 3 \
    "$PACKAGE_URL" \
    -o "$PACKAGE"
then

    echo
    echo "❌ 下载失败"

    rm -rf "$TMP_DIR"

    exit 1

fi


echo "✅ 下载完成"


# ============================================================
# 解压
# ============================================================

echo
echo "[3/4] 解压程序..."


if ! tar -xzf "$PACKAGE" -C "$EXTRACT"
then

    echo "❌ 解压失败"

    rm -rf "$TMP_DIR"

    exit 1

fi


SOURCE=$(find "$EXTRACT" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    | head -1)


if [ -z "$SOURCE" ]; then
    SOURCE="$EXTRACT"
fi


if [ ! -f "$SOURCE/deploy/deploy.sh" ]; then

    echo
    echo "❌ 安装包结构错误"
    echo
    echo "缺少:"
    echo "deploy/deploy.sh"

    rm -rf "$TMP_DIR"

    exit 1

fi


echo "✅ 解压完成"


# ============================================================
# 正式部署
# ============================================================

echo
echo "[4/4] 部署 TG Bot..."
echo


bash "$SOURCE/deploy/deploy.sh" "$SOURCE"


mkdir -p /opt/tg_bot/config


# 保存更新源

SYSTEM_ENV="/opt/tg_bot/config/system.env"

touch "$SYSTEM_ENV"


TMP_ENV=$(mktemp)

grep -v '^TG_BOT_PACKAGE_URL=' \
    "$SYSTEM_ENV" \
    > "$TMP_ENV" 2>/dev/null || true


printf 'TG_BOT_PACKAGE_URL=%q\n' \
    "$PACKAGE_URL" \
    >> "$TMP_ENV"


cat "$TMP_ENV" > "$SYSTEM_ENV"

rm -f "$TMP_ENV"

chmod 600 "$SYSTEM_ENV"


rm -rf "$TMP_DIR"


echo
echo "=========================================="
echo "      ✅ TG Bot 安装完成"
echo "=========================================="
echo
echo "现在运行:"
echo
echo "    tg-bot"
echo
echo "进入数字管理菜单。"
echo


if [ -f "/opt/tg_bot/deploy/first_setup.sh" ]

then


echo

echo "开始首次配置..."

echo


bash /opt/tg_bot/deploy/first_setup.sh


else


echo

echo "首次配置程序不存在"

echo "请运行:"
echo

echo "tg-bot"


fi
