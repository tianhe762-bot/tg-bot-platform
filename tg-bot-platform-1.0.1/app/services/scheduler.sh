#!/bin/bash
# ============================================================
# Scheduler
# ============================================================

case "${1:-}" in
    monitor)
        bash /opt/tg_bot/app/services/monitor.sh
        ;;
    health)
        bash /opt/tg_bot/app/services/healthcheck.sh
        ;;
    *)
        echo "Usage: $0 {monitor|health}"
        exit 1
        ;;
esac

