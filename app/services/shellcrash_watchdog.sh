#!/bin/bash
# ============================================================
# ShellCrash Watchdog
# Auto-heal when shellcrash fails to start (e.g. network check
# fails right after an abnormal boot). Runs via systemd timer.
# ============================================================

ROOT="/opt/tg_bot"

source "$ROOT/app/lib/config.sh"
source "$ROOT/app/lib/telegram.sh"
source "$ROOT/app/lib/push.sh"
source "$ROOT/app/modules/alert.sh"

load_config

STATE_FILE="/var/lib/tg_shellcrash_watchdog.state"
SERVICE="shellcrash.service"
PORT=7890

is_healthy()
{
    systemctl is-active "$SERVICE" >/dev/null 2>&1 || return 1
    ss -lnt 2>/dev/null | grep -q ":$PORT " || return 1
    return 0
}

read_state()
{
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE" 2>/dev/null
    else
        echo "unknown"
    fi
}

write_state()
{
    printf '%s\n' "$1" > "$STATE_FILE" 2>/dev/null || true
}

notify()
{
    local PREV NEW TEXT
    PREV=$(read_state)
    NEW="$1"
    TEXT="$2"
    if [ "$PREV" != "$NEW" ]; then
        send_alert "$TEXT" || true
        write_state "$NEW"
    fi
}

START_TS=$(date +%s)

if is_healthy; then
    if [ "$(read_state)" != "ok" ]; then
        write_state "ok"
    fi
    exit 0
fi

RECOVERED=0
for attempt in 1 2 3; do
    # archive start_error marker if present (rename, never delete)
    if [ -f /etc/ShellCrash/.start_error ]; then
        mv -f /etc/ShellCrash/.start_error "/etc/ShellCrash/.start_error.healed.$(date +%s)" 2>/dev/null || true
    fi
    systemctl restart "$SERVICE" >/dev/null 2>&1 || systemctl start "$SERVICE" >/dev/null 2>&1 || true
    sleep 5
    if is_healthy; then
        RECOVERED=1
        break
    fi
    [ "$attempt" -lt 3 ] && sleep 15
done

COST=$(( $(date +%s) - START_TS ))

if [ "$RECOVERED" = "1" ]; then
    notify "ok" "ShellCrash 已自动恢复（开机自启失败，耗时 ${COST}s）"
else
    notify "failed" "ShellCrash 自愈失败，请检查（已尝试 3 次）"
fi
