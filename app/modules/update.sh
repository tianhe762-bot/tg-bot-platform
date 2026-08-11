#!/bin/bash
# ============================================================
# Update Module
# ============================================================


# 获取最新版本号；获取失败输出空
# 测试可用 TG_UPDATE_API_URL 覆盖
update_latest()
{
    local API_URL RESULT LATEST REMOTE_URL

    API_URL="${TG_UPDATE_API_URL:-https://api.github.com/repos/tianhe762-bot/tg-bot-platform/releases/latest}"
    RESULT=$(curl -sSL --connect-timeout 10 --max-time 15 "$API_URL" 2>/dev/null || true)

    LATEST=$(echo "$RESULT" | jq -r '.tag_name // empty' 2>/dev/null | tr -d '\r' | sed 's/^v//')

    if [ -z "$LATEST" ]
    then
        REMOTE_URL=$(grep "^TG_VERSION_URL=" /opt/tg_bot/config/system.env 2>/dev/null | cut -d= -f2 | tr -d '"' || true)
        [ -n "$REMOTE_URL" ] && LATEST=$(curl -fsSL --connect-timeout 10 --max-time 15 "$REMOTE_URL" 2>/dev/null | tr -d ' \r\n' | sed 's/^v//' || true)
    fi

    echo "$LATEST"
}


# 版本检查：输出检查结果
# 返回: 0=有新版本, 1=已是最新, 2=获取失败
# 测试可用 TG_UPDATE_VERSION_FILE 覆盖本地版本文件
update_check()
{
    local CURRENT LATEST

    CURRENT=$(tr -d ' \r\n' < "${TG_UPDATE_VERSION_FILE:-/opt/tg_bot/VERSION}" 2>/dev/null || echo "unknown")
    LATEST=$(update_latest)

    if [ -z "$LATEST" ]
    then
        echo "❌ 无法获取最新版本，请检查网络后重试。"
        return 2
    fi

    if [ "$CURRENT" = "$LATEST" ]
    then
        echo "✅ 当前已是最新版本: v$CURRENT"
        return 1
    fi

    echo "📦 版本检查

当前版本: v$CURRENT
最新版本: v$LATEST

是否更新？
再次发送 /update 确认更新。"
    return 0
}
