#!/bin/bash


wake_execute()
{
    local CHAT_ID="$1"
    local RESULT=""
    
    RESULT=$(wake_pc 2>&1 || echo "❌ 执行唤醒出现异常")
    telegram_send "$CHAT_ID" "$RESULT"
}