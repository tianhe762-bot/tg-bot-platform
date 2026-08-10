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

load_modules

log "Bot started"
echo "Telegram Bot started"

OFFSET_FILE="$DATA/update_offset"

if [ -f "$OFFSET_FILE" ]; then
    OFFSET=$(cat "$OFFSET_FILE")
else
    OFFSET=0
fi

while true; do
    RESULT=$(curl -s \
        --connect-timeout 10 \
        --max-time 40 \
        "$API/getUpdates?timeout=30&offset=$OFFSET")

    COUNT=$(echo "$RESULT" | jq '.result | length' 2>/dev/null || echo 0)

    if [ "$COUNT" -gt 0 ]; then
        for ((i=0;i<COUNT;i++)); do
            UPDATE=$(echo "$RESULT" | jq -c ".result[$i]")
            OFFSET=$(echo "$UPDATE" | jq '.update_id + 1')
            echo "$OFFSET" > "$OFFSET_FILE"

            CHAT_ID=$(echo "$UPDATE" | jq -r '.message.chat.id // empty')
            USER_ID=$(echo "$UPDATE" | jq -r '.message.from.id // empty')
            TEXT=$(echo "$UPDATE" | jq -r '.message.text // empty')

            [ -z "$TEXT" ] && continue

            if ! is_admin "$USER_ID"; then
                telegram_send "$CHAT_ID" "❌ 无权限"
                continue
            fi

            CMD=$(echo "$TEXT" | awk '{print $1}' | cut -c2-)
            ARGS=$(echo "$TEXT" | cut -d' ' -f2-)
            CMD=${CMD#/}

            log_command "$USER_ID" "$CMD"
            route_command "$CMD" "$CHAT_ID" "$ARGS"
        done
    fi
    sleep 1
done

