#!/bin/bash
# ============================================================
# Health Check
# ============================================================

ROOT="/opt/tg_bot"

source "$ROOT/app/lib/config.sh"
source "$ROOT/app/lib/telegram.sh"
source "$ROOT/app/modules/alert.sh"

load_config

RESULT=$(curl -s --max-time 3 "${MIHOMO_API:-http://127.0.0.1:9999}/version" || true)

if [ -z "$RESULT" ]; then
    send_alert "Mihomo API异常"
fi

if ! docker info >/dev/null 2>&1; then
    send_alert "Docker服务异常"
fi

