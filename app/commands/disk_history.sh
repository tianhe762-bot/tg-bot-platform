#!/bin/bash


disk_history_execute()
{

CHAT_ID="$1"


RESULT=$(metrics_disk)



telegram_send "$CHAT_ID" \
"💾 磁盘状态:

$RESULT"


}
