#!/bin/bash


# Telegram API 请求：优先走代理（TG_PROXY），代理不可用时自动直连
telegram_curl()
{
    local args=("$@")
    local out
    local rc

    if [ -n "${TG_PROXY:-}" ]; then
        out=$(curl "${args[@]}" \
            --proxy "$TG_PROXY" \
            --connect-timeout 5 \
            --max-time 30 \
            --fail \
            2>/dev/null)
        rc=$?
        if [ "$rc" -eq 0 ]; then
            printf '%s' "$out"
            return 0
        fi
    fi

    curl "${args[@]}"
}


telegram_send()
{
    local CHAT_ID="$1"
    local TEXT="$2"


    telegram_curl -s \
        -X POST \
        "$API/sendMessage" \
        --data-urlencode "chat_id=$CHAT_ID" \
        --data-urlencode "text=$TEXT" \
        >/dev/null 2>&1 || true
}


telegram_set_commands()
{
    local COMMANDS_JSON='[
        {"command":"status","description":"查看系统运行状态"},
        {"command":"ports","description":"查看服务端口"},
        {"command":"mihomo","description":"Mihomo 节点与测速"},
        {"command":"switch","description":"切换代理节点"},
        {"command":"wake","description":"发送 WOL 唤醒包"},
        {"command":"backup","description":"数据及配置备份"},
        {"command":"update","description":"版本检查与更新"},
        {"command":"help","description":"查看使用帮助与说明"}
    ]'


    telegram_curl -s -X POST \
        "$API/setMyCommands" \
        -H "Content-Type: application/json" \
        -d "{\"commands\":$COMMANDS_JSON}" \
        >/dev/null 2>&1 || true
}
