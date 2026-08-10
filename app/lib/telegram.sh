#!/bin/bash


telegram_send()
{
    local CHAT_ID="$1"
    local TEXT="$2"


    curl -s \
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
        {"command":"cpu","description":"查看 CPU 负载"},
        {"command":"memory","description":"查看内存使用率"},
        {"command":"disk","description":"查看磁盘空间"},
        {"command":"docker","description":"Docker 容器管理"},
        {"command":"mihomo","description":"Mihomo 代理状态"},
        {"command":"wake","description":"发送 WOL 唤醒包"},
        {"command":"backup","description":"数据及配置备份"},
        {"command":"update","description":"版本检查与更新"},
        {"command":"help","description":"查看使用帮助与说明"}
    ]'


    curl -s -X POST \
        "$API/setMyCommands" \
        -H "Content-Type: application/json" \
        -d "{\"commands\":$COMMANDS_JSON}" \
        >/dev/null 2>&1 || true
}