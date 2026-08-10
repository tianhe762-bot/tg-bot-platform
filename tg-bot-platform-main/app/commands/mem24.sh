#!/bin/bash


mem24_execute()
{

CHAT_ID="$1"


RESULT=$(metrics_memory)



telegram_send "$CHAT_ID" \
"🧠 内存历史:

$RESULT"


}
