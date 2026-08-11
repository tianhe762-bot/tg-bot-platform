#!/bin/bash
# ============================================================
# Watchdog Manager Command
# /watchdog -> menu; /watchdog <n> or reply <n> -> toggle
# ============================================================

source "${ROOT:-/opt/tg_bot}/app/lib/watchdogs.sh"

watchdog_execute()
{
    local CHAT_ID="$1"
    local ARGS="${2:-}"

    if [[ "$ARGS" =~ ^[0-9]+$ ]] && [ "${ARGS:-0}" -gt 0 ]; then
        local NAME
        NAME=$(watchdog_name_by_index "$ARGS")
        if [ -z "$NAME" ]; then
            telegram_send "$CHAT_ID" "⚠️ 无效编号：$ARGS"
            return
        fi
        telegram_send "$CHAT_ID" "$(watchdog_toggle "$NAME")"
        return
    fi

    printf '%s|watchdog|%s\n' "$CHAT_ID" "$(date +%s)" >> "${DATA:-/opt/tg_bot/data}/menu_state"
    telegram_send "$CHAT_ID" "$(watchdogs_menu_text)"
}
