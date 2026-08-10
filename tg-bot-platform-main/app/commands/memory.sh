#!/bin/bash


memory_execute()
{

CHAT_ID="$1"


TEXT=$(free -h)



telegram_send "$CHAT_ID" \
"🧠 内存状态:

$TEXT"


}
