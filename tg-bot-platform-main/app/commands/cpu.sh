#!/bin/bash


cpu_execute()
{

CHAT_ID="$1"



TEXT=$(uptime)



telegram_send "$CHAT_ID" \
"⚙️ CPU状态:

$TEXT"


}
