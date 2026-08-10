#!/bin/bash


disk_execute()
{

CHAT_ID="$1"


TEXT=$(df -h | grep -E "/$|/mnt/photos")



telegram_send "$CHAT_ID" \
"💾 磁盘状态:

$TEXT"


}


