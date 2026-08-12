#!/bin/bash
# ============================================================
# Update Module
# ============================================================

# 获取最新版本号；获取失败输出空（NET_LATEST_ERR 为原因）
update_latest()
{
    local LATEST TAG_FILE

    source /opt/tg_bot/config/system.env 2>/dev/null || true
    source /opt/tg_bot/app/lib/net.sh 2>/dev/null || true

    TAG_FILE=$(mktemp)
    net_latest_tag "tianhe762-bot/tg-bot-platform" > "$TAG_FILE" 2>/dev/null || true
    LATEST=$(cat "$TAG_FILE" 2>/dev/null || true)
    rm -f "$TAG_FILE"
    [ -n "$LATEST" ] && LATEST="${LATEST#v}"
    echo "$LATEST"
}

# 版本检查：输出检查结果
# 返回: 0=有新版本, 1=已是最新, 2=获取失败
update_check()
{
    local CURRENT LATEST TAG_FILE

    CURRENT=$(tr -d ' \r\n' < "${TG_UPDATE_VERSION_FILE:-/opt/tg_bot/VERSION}" 2>/dev/null || echo "unknown")

    source /opt/tg_bot/config/system.env 2>/dev/null || true
    source /opt/tg_bot/app/lib/net.sh 2>/dev/null || true

    TAG_FILE=$(mktemp)
    net_latest_tag "tianhe762-bot/tg-bot-platform" > "$TAG_FILE" 2>/dev/null || true
    LATEST=$(cat "$TAG_FILE" 2>/dev/null || true)
    rm -f "$TAG_FILE"
    LATEST="${LATEST#v}"

    if [ -z "$LATEST" ]; then
        echo "❌ 无法获取最新版本：${NET_LATEST_ERR:-未知原因}。请检查网络/代理后重试。"
        return 2
    fi

    if version_compare "$CURRENT" "$LATEST"; then
        echo "✅ 当前已是最新版本: v$CURRENT"
        return 1
    else
        VC=$?
        if [ "$VC" -eq 1 ]; then
            echo "✅ 当前版本 v$CURRENT 不低于远程 v$LATEST（可能包含未发布的修复），无需更新。"
            return 1
        fi
    fi

    echo "📦 版本检查
当前版本: v$CURRENT
最新版本: v$LATEST

是否更新？再次发送 /update 确认更新。"
    return 0
}
