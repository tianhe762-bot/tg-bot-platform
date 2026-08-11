#!/bin/bash
# ============================================================
# Alert Module
# ============================================================

source "${ROOT:-/opt/tg_bot}/app/lib/push.sh" 2>/dev/null || true

send_alert()
{
    MESSAGE="$1"
    TEXT="⚠️ 服务器报警

$MESSAGE"

    if [ -n "${ADMIN_CHAT_ID:-}" ] && telegram_send "$ADMIN_CHAT_ID" "$TEXT"; then
        return 0
    fi

    send_fallback "$TEXT" || true
}
