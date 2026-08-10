#!/bin/bash
# ============================================================
# Scheduler
# ============================================================


case "$1" in


monitor)

bash /opt/tg_bot/app/services/monitor.sh

;;


health)

bash /opt/tg_bot/app/services/healthcheck.sh

;;


*)

echo "Usage:

scheduler.sh monitor

scheduler.sh health"

;;


esac
