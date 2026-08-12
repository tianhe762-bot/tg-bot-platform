#!/bin/bash
# ============================================================
# TG Bot Bootstrap Installer (GitHub Release Automated)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tianhe762-bot/tg-bot-platform/main/install.sh | bash
#   或指定自定义包 URL:
#   bash install.sh https://example.com/tg_bot-v1.0.1.tar.gz
# ============================================================


set -euo pipefail


REPO="tianhe762-bot/tg-bot-platform"
PROXY_OPTS=()
[ -n "${TG_PROXY:-}" ] && PROXY_OPTS=(--proxy "$TG_PROXY")


if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 权限运行"
    exit 1
fi


clear


echo "=========================================="
echo "       TG Bot Installer"
echo "=========================================="
echo


# 1. 基础工具校验与安装
echo "[1/4] 检查并安装基础依赖..."
export DEBIAN_FRONTEND=noninteractive


apt-get update -qq
apt-get install -y \
    curl \
    ca-certificates \
    tar \
    rsync \
    jq \
    coreutils \
    >/dev/null


echo "✅ 完成"


# 2. 获取安装包 URL
PACKAGE_URL="${1:-${TG_BOT_PACKAGE_URL:-}}"
SHA256_URL=""


if [ -z "$PACKAGE_URL" ]; then
    echo
    echo "[2/4] 从 GitHub Release 获取最新版本..."

    LATEST_TAG=$(curl -s -o /dev/null -w '%{url_effective}' -L --max-time 20 "${PROXY_OPTS[@]}" \
        "https://github.com/${REPO}/releases/latest" 2>/dev/null | sed -n 's#.*/tag/##p')

    if [ -z "$LATEST_TAG" ]; then
        echo "⚠️ 无法自动获取最新 Release，转入手动输入。"
        read -rp "请输入安装包 URL (.tar.gz): " PACKAGE_URL
    else
        LATEST_VERSION="${LATEST_TAG#v}"
        PACKAGE_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/tg_bot-v${LATEST_VERSION}.tar.gz"
        SHA256_URL="${PACKAGE_URL}.sha256"
        echo "✅ 最新版本: ${LATEST_TAG}"
    fi
fi


if [ -z "$PACKAGE_URL" ] || [ "$PACKAGE_URL" = "null" ]; then
    echo "❌ 获取安装包地址失败"
    exit 1
fi


echo "下载源: $PACKAGE_URL"


# 3. 下载与校验
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT


PACKAGE="$TMP_DIR/tg_bot.tar.gz"
EXTRACT="$TMP_DIR/extract"
mkdir -p "$EXTRACT"


echo
echo "[3/4] 下载程序包并校验..."


if ! curl -fL --connect-timeout 15 --retry 3 "${PROXY_OPTS[@]}" "$PACKAGE_URL" -o "$PACKAGE"; then
    echo "❌ 下载安装包失败"
    exit 1
fi


if [ -n "$SHA256_URL" ]; then
    SHA256_FILE="$TMP_DIR/tg_bot.tar.gz.sha256"
    if curl -fL --connect-timeout 10 --retry 2 "${PROXY_OPTS[@]}" "$SHA256_URL" -o "$SHA256_FILE"; then
        EXPECTED_SHA=$(awk '{print $1}' "$SHA256_FILE")
        ACTUAL_SHA=$(sha256sum "$PACKAGE" | awk '{print $1}')

        if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
            echo "❌ SHA256 校验失败!"
            echo "期望值: $EXPECTED_SHA"
            echo "实际值: $ACTUAL_SHA"
            exit 1
        fi
        echo "✅ SHA256 校验通过"
    else
        echo "⚠️ 校验文件下载失败，跳过 SHA256 强校验"
    fi
fi


# 4. 解压与部署
echo
echo "[4/4] 解压并部署程序..."


if ! tar -xzf "$PACKAGE" -C "$EXTRACT"; then
    echo "❌ 解压失败"
    exit 1
fi


SOURCE=""
if [ -f "$EXTRACT/deploy/deploy.sh" ]; then
    SOURCE="$EXTRACT"
else
    SUB_DIR=$(find "$EXTRACT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n 1)
    if [ -n "$SUB_DIR" ] && [ -f "$SUB_DIR/deploy/deploy.sh" ]; then
        SOURCE="$SUB_DIR"
    fi
fi


if [ -z "$SOURCE" ] || [ ! -f "$SOURCE/deploy/deploy.sh" ]; then
    echo "❌ 安装包结构错误，缺少 deploy/deploy.sh"
    exit 1
fi


bash "$SOURCE/deploy/deploy.sh" "$SOURCE"


# 保存系统环境配置
mkdir -p /opt/tg_bot/config
SYSTEM_ENV="/opt/tg_bot/config/system.env"
touch "$SYSTEM_ENV"


TMP_ENV=$(mktemp)
grep -v '^TG_BOT_PACKAGE_URL=' "$SYSTEM_ENV" > "$TMP_ENV" 2>/dev/null || true
printf 'TG_BOT_PACKAGE_URL=%q\n' "$PACKAGE_URL" >> "$TMP_ENV"
cat "$TMP_ENV" > "$SYSTEM_ENV"
rm -f "$TMP_ENV"
chmod 600 "$SYSTEM_ENV"


echo
echo "=========================================="
echo "      ✅ TG Bot 安装完成"
echo "=========================================="
echo
echo "运行 'tg-bot' 命令进入控制菜单。"
echo

echo
echo
echo "首次配置："
echo
echo "请输入以下命令进入配置向导："
echo
echo "    tg-bot"
echo
echo "然后选择【首次安装配置】。"
echo
