#!/bin/bash
# ============================================================
# Watchdog Registry & Control
# Shared by /watchdog command and deploy/manager.sh panel
# ============================================================

WATCHDOG_CONF="${WATCHDOG_CONF:-/opt/tg_bot/config/watchdogs.conf}"

# Output: idx|name|desc|enabled|timer
watchdogs_list()
{
    local IDX=0
    local NAME TIMER DESC STATE
    while IFS='|' read -r NAME TIMER DESC; do
        [ -z "$NAME" ] && continue
        case "$NAME" in \#*) continue ;; esac
        IDX=$((IDX + 1))
        STATE="disabled"
        if systemctl is-enabled "$TIMER" >/dev/null 2>&1; then
            STATE="enabled"
        fi
        printf '%s|%s|%s|%s|%s\n' "$IDX" "$NAME" "$DESC" "$STATE" "$TIMER"
    done < "$WATCHDOG_CONF"
}

watchdog_name_by_index()
{
    local IDX="$1"
    watchdogs_list | awk -F'|' -v i="$IDX" '$1==i {print $2; exit}'
}

watchdog_toggle()
{
    local NAME="$1"
    local ENTRY
    ENTRY=$(grep -E "^${NAME}\|" "$WATCHDOG_CONF" 2>/dev/null | head -1)
    if [ -z "$ENTRY" ]; then
        echo "⚠️ 未找到看门狗: $NAME"
        return 1
    fi
    local TIMER DESC
    TIMER=$(printf '%s' "$ENTRY" | cut -d'|' -f2)
    DESC=$(printf '%s' "$ENTRY" | cut -d'|' -f3)
    if systemctl is-enabled "$TIMER" >/dev/null 2>&1; then
        systemctl disable --now "$TIMER" >/dev/null 2>&1 || true
        printf '⭕ 已关闭：%s（不再轮询）\n' "$DESC"
    else
        systemctl enable --now "$TIMER" >/dev/null 2>&1 || true
        printf '✅ 已开启：%s\n' "$DESC"
    fi
}

watchdogs_menu_text()
{
    local OUT="🐶 看门狗管理\n\n"
    local IDX NAME DESC STATE TIMER
    while IFS='|' read -r IDX NAME DESC STATE TIMER; do
        if [ "$STATE" = "enabled" ]; then
            OUT+="${IDX}. ${DESC} — ✅已开启\n"
        else
            OUT+="${IDX}. ${DESC} — ⭕已关闭\n"
        fi
    done < <(watchdogs_list)
    OUT+="\n回复数字切换 开/关（或直接 /watchdog 数字）"
    printf '%b' "$OUT"
}
