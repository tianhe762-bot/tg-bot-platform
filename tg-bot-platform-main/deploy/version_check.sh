#!/bin/bash
# ============================================================
# Version Check
# ============================================================

set -euo pipefail

REPO="tianhe762-bot/tg-bot-platform"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
ROOT="/opt/tg_bot"

LOCAL_VERSION="unknown"
if [ -f "$ROOT/VERSION" ]; then
    LOCAL_VERSION=$(tr -d ' \r\n' < "$ROOT/VERSION")
fi

echo "=========================================="
echo "        版本检测 (Version Check)"
echo "=========================================="
echo
echo "本地当前版本: v${LOCAL_VERSION}"

echo "正在从 GitHub 获取最新版本信息..."
RELEASE_JSON=$(curl -sSL --connect-timeout 10 --retry 3 "$API_URL" || true)

if [ -n "$RELEASE_JSON" ] && ! echo "$RELEASE_JSON" | grep -q "Not Found"; then
    LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty')
    REMOTE_VERSION="${LATEST_TAG#v}"
else
    REMOTE_VERSION=""
fi

if [ -z "$REMOTE_VERSION" ]; then
    echo "⚠️ 无法通过 GitHub API 获取版本，尝试检测自定义地址..."
    REMOTE_URL=$(grep "^TG_VERSION_URL=" "$ROOT/config/system.env" 2>/dev/null | cut -d= -f2 | tr -d '"' || true)
    if [ -n "$REMOTE_URL" ]; then
        REMOTE_VERSION=$(curl -fsSL "$REMOTE_URL" 2>/dev/null | tr -d ' \r\n' || true)
    fi
fi

if [ -z "$REMOTE_VERSION" ]; then
    echo "❌ 无法获取远程版本，请检查网络连接。"
    exit 1
fi

echo "远程最新版本: v${REMOTE_VERSION}"
echo

if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
    echo "✅ 当前已是最新版本。"
else
    echo "🎉 发现新版本 v${REMOTE_VERSION}！可在控制菜单中选择【在线更新】进行升级。"
fi
