#!/bin/bash
# ============================================================
# Alert Module
# ============================================================

source "${ROOT:-/opt/tg_bot}/app/lib/push.sh" 2>/dev/null || true

ALERT_COOLDOWN_FILE="${ALERT_COOLDOWN_FILE:-/opt/tg_bot/data/alert_cooldown.state}"
ALERT_COOLDOWN_MIN="${ALERT_COOLDOWN_MIN:-30}"

send_alert()
{
    MESSAGE="$1"
    TEXT="⚠️ 服务器报警

$MESSAGE"

    # 同内容冷却：同一文本在冷却窗口内不重复发送，防刷屏
    local HASH NOW LAST
    HASH=$(printf '%s' "$TEXT" | md5sum | awk '{print $1}')
    NOW=$(date +%s)
    LAST=0
    if [ -f "$ALERT_COOLDOWN_FILE" ]; then
        LAST=$(grep "^${HASH} " "$ALERT_COOLDOWN_FILE" 2>/dev/null | awk '{print $2}' | tail -1)
        LAST=${LAST:-0}
    fi
    if [ "$LAST" -gt 0 ] && [ $((NOW - LAST)) -lt $((ALERT_COOLDOWN_MIN * 60)) ]; then
        return 0
    fi

    if [ -n "${ADMIN_CHAT_ID:-}" ] && telegram_send "$ADMIN_CHAT_ID" "$TEXT"; then
        printf '%s %s\n' "$HASH" "$NOW" >> "$ALERT_COOLDOWN_FILE"
        return 0
    fi

    send_fallback "$TEXT" || true
    printf '%s %s\n' "$HASH" "$NOW" >> "$ALERT_COOLDOWN_FILE"

    # 简单清理：超过 200 行时丢弃已过期条目
    if [ -f "$ALERT_COOLDOWN_FILE" ] && [ "$(wc -l < "$ALERT_COOLDOWN_FILE")" -gt 200 ]; then
        awk -v now="$NOW" -v win=$((ALERT_COOLDOWN_MIN * 60)) '$2+win >= now' "$ALERT_COOLDOWN_FILE" > "$ALERT_COOLDOWN_FILE.tmp" 2>/dev/null && mv "$ALERT_COOLDOWN_FILE.tmp" "$ALERT_COOLDOWN_FILE" 2>/dev/null || true
    fi
}
