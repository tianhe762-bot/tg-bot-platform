#!/bin/bash


network24_execute()
{

CHAT_ID="$1"


RESULT=$(metrics_network)



telegram_send "$CHAT_ID" \
"🌐 网络流量:

$RESULT"


}
