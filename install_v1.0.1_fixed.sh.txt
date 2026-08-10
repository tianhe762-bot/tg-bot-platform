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
API_URL="https://api.github.com/repos/${REPO}/releases/latest"


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
    
    RELEASE_JSON=$(curl -sSL --connect-timeout 10 --retry 3 "$API_URL" || true)
    
    if [ -z "$RELEASE_JSON" ] || echo "$RELEASE_JSON" | grep -q "Not Found"; then
        echo "⚠️ 无法从 GitHub API 获取最新 Release，转为手动输入。"
        read -rp "请输入安装包 URL (.tar.gz): " PACKAGE_URL
    else
        PACKAGE_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith(".tar.gz") and (endswith(".tar.gz.sha256") | not)) | .browser_download_url' | head -n 1)
        SHA256_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith(".tar.gz.sha256")) | .browser_download_url' | head -n 1)
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


if ! curl -fL --connect-timeout 15 --retry 3 "$PACKAGE_URL" -o "$PACKAGE"; then
    echo "❌ 下载安装包失败"
    exit 1
fi


if [ -n "$SHA256_URL" ] && [ "$SHA256_URL" != "null" ]; then
    SHA256_FILE="$TMP_DIR/tg_bot.tar.gz.sha256"
    if curl -fL --connect-timeout 10 --retry 2 "$SHA256_URL" -o "$SHA256_FILE"; then
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


if [ -f "/opt/tg_bot/deploy/first_setup.sh" ]; then
    echo "开始首次配置..."
    echo
    bash /opt/tg_bot/deploy/first_setup.sh
else
    echo "首次配置脚本不存在，请运行 'tg-bot'"
fi