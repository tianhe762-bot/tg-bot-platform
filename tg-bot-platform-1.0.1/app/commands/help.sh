#!/bin/bash


help_execute()
{

CHAT_ID="$1"



telegram_send "$CHAT_ID" \
"可用命令:


基础:
/status
/disk
/memory
/cpu
/network


历史:
/cpu24
/mem24
/network24
/disk_history
/traffic


服务:
/docker
/mihomo
/wake
/backup
/logs
/update"

}
