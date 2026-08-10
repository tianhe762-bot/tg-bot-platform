#!/bin/bash


cpu24_execute()
{

CHAT_ID="$1"


RESULT=$(metrics_cpu24)



telegram_send "$CHAT_ID" \
"📊 CPU历史:

$RESULT"


}
