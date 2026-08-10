#!/bin/bash


telegram_send()
{

CHAT_ID="$1"

TEXT="$2"


curl -s \
-X POST \
"$API/sendMessage" \
--data-urlencode "chat_id=$CHAT_ID" \
--data-urlencode "text=$TEXT" \
>/dev/null

}
