#!/bin/bash
# ============================================================
# Version Check
# ============================================================

set -euo pipefail

REPO="tianhe762-bot/tg-bot-platform"
ROOT="/opt/tg_bot"

source "${ROOT}/config/system.env" 2>/dev/null || true
source "${ROOT}/app/lib/net.sh" 2>/dev/null || true

LOCAL_VERSION="unknown"
if [ -f "$ROOT/VERSION" ]; then
    LOCAL_VERSION=$(tr -d ' \r\n' < "$ROOT/VERSION")
fi

echo "=========================================="
echo "         版本检测 (Version Check)"
echo "=========================================="
echo
echo "本地当前版本: v${LOCAL_VERSION}"
echo "正在从 GitHub 获取最新版本信息..."

TAG_FILE=$(mktemp)
net_latest_tag "$REPO" > "$TAG_FILE" 2>/dev/null || true
LATEST_TAG=$(cat "$TAG_FILE" 2>/dev/null || true)
rm -f "$TAG_FILE"
REMOTE_VERSION="${LATEST_TAG#v}"

if [ -z "$REMOTE_VERSION" ]; then
    echo "❌ 无法获取远程版本，失败原因："
    echo "   ${NET_LATEST_ERR:-未知}"
    echo
    echo "请检查：1) 服务器能否访问 github.com（网络或代理）；2) 稍后重试（api.github.com 限流通常是临时的）。"
    exit 1
fi

echo "✅ 已通过【${NET_LATEST_SRC}】获取最新版本: v${REMOTE_VERSION}"
echo

if version_compare "$LOCAL_VERSION" "$REMOTE_VERSION"; then
    echo "✅ 当前已是最新版本。"
else
    VC=$?
    case "$VC" in
        1)
            echo "✅ 当前版本 v${LOCAL_VERSION} 不低于远程 v${REMOTE_VERSION}（可能包含未发布的修复），无需更新。"
            ;;
        2)
            echo "🎉 发现新版本 v${REMOTE_VERSION}！可在控制菜单中选择【在线更新】进行升级。"
            ;;
    esac
fi
