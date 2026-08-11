#!/bin/bash
# ============================================================
# TG Bot Auto-Updater (GitHub Release Automated)
# ============================================================

set -euo pipefail

REPO="tianhe762-bot/tg-bot-platform"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
INSTALL_DIR="/opt/tg_bot"
BACKUP_DIR="${INSTALL_DIR}/backups"
VERSION_FILE="${INSTALL_DIR}/VERSION"

echo "=========================================="
echo "       TG Bot Platform Updater"
echo "=========================================="
echo

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 权限运行更新程序"
    exit 1
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ 找不到当前版本文件: $VERSION_FILE"
    exit 1
fi

CURRENT_VERSION=$(tr -d ' \r\n' < "$VERSION_FILE")
echo "当前本地版本: v${CURRENT_VERSION}"

echo "正在检查 GitHub 最新版本..."
RELEASE_JSON=$(curl -sSL --connect-timeout 10 --retry 3 "$API_URL" || true)

if [ -z "$RELEASE_JSON" ] || echo "$RELEASE_JSON" | grep -q "Not Found"; then
    echo "❌ 无法获取最新 Release 信息，请检查网络。"
    exit 1
fi

LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty')
LATEST_VERSION="${LATEST_TAG#v}"

if [ -z "$LATEST_VERSION" ]; then
    echo "❌ 解析最新版本号失败"
    exit 1
fi

echo "GitHub 最新版本: v${LATEST_VERSION}"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "✅ 当前已是最新版本，无需更新。"
    exit 0
fi

PACKAGE_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith(".tar.gz") and (endswith(".tar.gz.sha256") | not)) | .browser_download_url' | head -n 1)
SHA256_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith(".tar.gz.sha256")) | .browser_download_url' | head -n 1)

if [ -z "$PACKAGE_URL" ] || [ "$PACKAGE_URL" = "null" ]; then
    echo "❌ 未找到最新版本的安装包"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

PACKAGE="$TMP_DIR/update.tar.gz"
EXTRACT="$TMP_DIR/extract"
mkdir -p "$EXTRACT" "$BACKUP_DIR"

echo
echo "正在下载更新包 (v${LATEST_VERSION})..."
if ! curl -fL --connect-timeout 15 --retry 3 "$PACKAGE_URL" -o "$PACKAGE"; then
    echo "❌ 下载更新包失败"
    exit 1
fi

if [ -n "$SHA256_URL" ] && [ "$SHA256_URL" != "null" ]; then
    SHA256_FILE="$TMP_DIR/update.tar.gz.sha256"
    if curl -fL --connect-timeout 10 --retry 2 "$SHA256_URL" -o "$SHA256_FILE"; then
        EXPECTED_SHA=$(awk '{print $1}' "$SHA256_FILE")
        ACTUAL_SHA=$(sha256sum "$PACKAGE" | awk '{print $1}')
        if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
            echo "❌ SHA256 校验失败，终止更新！"
            exit 1
        fi
        echo "✅ SHA256 校验通过"
    fi
fi

# 解压新文件
tar -xzf "$PACKAGE" -C "$EXTRACT"

# 兼容两种包结构：带顶层目录的压缩包取其目录，平铺压缩包直接用解压根目录
ENTRIES=$(find "$EXTRACT" -mindepth 1 -maxdepth 1 | wc -l)
TOP_DIR=$(find "$EXTRACT" -mindepth 1 -maxdepth 1 -type d | head -n 1)
if [ "$ENTRIES" -eq 1 ] && [ -d "$TOP_DIR" ]; then
    SOURCE="$TOP_DIR"
else
    SOURCE="$EXTRACT"
fi

# 1. 备份当前版本
BACKUP_TAG="$(date +%Y%m%d_%H%M%S)"
BACKUP_TAR="${BACKUP_DIR}/tg_bot_v${CURRENT_VERSION}_${BACKUP_TAG}.tar.gz"

echo
echo "正在备份当前版本到: ${BACKUP_TAR}..."
tar -czf "$BACKUP_TAR" \
    --exclude="backups" \
    --exclude="logs" \
    --exclude="config/*.env" \
    -C "$INSTALL_DIR" .

echo "✅ 备份完成"

# 2. rsync 覆盖升级 (保留用户配置与日志)
echo "正在应用更新..."
rsync -av --delete \
    --exclude="config/*.env" \
    --exclude="logs/" \
    --exclude="backups/" \
    --exclude="data/update_offset" \
    "$SOURCE/" "$INSTALL_DIR/"

echo "✅ 文件更新完成"

# 3. 重启并进行健康检查
echo
echo "正在重启 tg_bot 服务并检查健康状态..."
if systemctl is-active --quiet tg_bot; then
    systemctl restart tg_bot || true
fi

sleep 3

if systemctl is-active --quiet tg_bot; then
    echo
    echo "=========================================="
    echo "  ✅ 成功升级至 v${LATEST_VERSION}！"
    echo "=========================================="
else
    echo
    echo "⚠️ 新服务启动失败，正在自动回滚..."
    tar -xzf "$BACKUP_TAR" -C "$INSTALL_DIR"
    systemctl restart tg_bot || true
    echo "❌ 更新失败，已成功回滚至 v${CURRENT_VERSION}"
    exit 1
fi
