#!/bin/bash
# ============================================================
# Telegram Server Bot
# Core Framework v4
# ============================================================


set -u


ROOT="/opt/tg_bot"
APP="$ROOT/app"
DATA="$ROOT/data"


mkdir -p "$DATA"


source "$APP/lib/config.sh"
source "$APP/lib/telegram.sh"
source "$APP/lib/utils.sh"


source "$APP/core/logger.sh"
source "$APP/core/loader.sh"
source "$APP/core/router.sh"
source "$APP/core/security.sh"


load_config


if [ -z "${TOKEN:-}" ]; then
    echo "TOKEN missing"
    exit 1
fi


if [ -z "${ADMINS:-}" ]; then
    echo "ADMINS missing"
    exit 1
fi


API="https://api.telegram.org/bot${TOKEN}"


# 自动挂载 Telegram 快捷菜单指令
telegram_set_commands || true


load_modules


log "Bot started"
echo "Telegram Bot started"


OFFSET_FILE="$DATA/update_offset"


while true; do
    if [ -f "$OFFSET_FILE" ]; then
        OFFSET=$(tr -d ' \r\n' < "$OFFSET_FILE" 2>/dev/null || echo 0)
    else
        OFFSET=0
    fi
    OFFSET=${OFFSET:-0}


    RESULT=$(curl -s \
        --connect-timeout 10 \
        --max-time 40 \
        "$API/getUpdates?timeout=30&offset=$OFFSET" || true)


    COUNT=$(echo "$RESULT" | jq '.result | length' 2>/dev/null || echo 0)


    if [ "$COUNT" -gt 0 ]; then
        for ((i=0;i<COUNT;i++)); do
            UPDATE=$(echo "$RESULT" | jq -c ".result[$i]" 2>/dev/null || continue)
            
            # 安全更新消息偏移量，防止重复轰炸循环
            RAW_UPDATE_ID=$(echo "$UPDATE" | jq -r '.update_id // empty' 2>/dev/null || true)
            if [ -n "$RAW_UPDATE_ID" ] && [[ "$RAW_UPDATE_ID" =~ ^[0-9]+$ ]]; then
                NEXT_OFFSET=$((RAW_UPDATE_ID + 1))
                echo "$NEXT_OFFSET" > "$OFFSET_FILE"
            fi


            CHAT_ID=$(echo "$UPDATE" | jq -r '.message.chat.id // empty' 2>/dev/null || true)
            USER_ID=$(echo "$UPDATE" | jq -r '.message.from.id // empty' 2>/dev/null || true)
            TEXT=$(echo "$UPDATE" | jq -r '.message.text // empty' 2>/dev/null || true)


            [ -z "$TEXT" ] && continue


            if ! is_admin "$USER_ID"; then
                telegram_send "$CHAT_ID" "❌ 无权限"
                continue
            fi


            CMD=$(echo "$TEXT" | awk '{print $1}' | cut -c2-)
            ARGS=$(echo "$TEXT" | cut -d' ' -f2-)
            CMD=${CMD#/}


            log_command "$USER_ID" "$CMD" 2>/dev/null || true
            
            # 捕获执行过程中的异常，防止任何报错破坏主循环
            route_command "$CMD" "$CHAT_ID" "$ARGS" 2>&1 || true
        done
    fi
    sleep 1
done