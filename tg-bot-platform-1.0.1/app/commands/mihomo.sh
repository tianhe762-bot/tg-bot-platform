#!/bin/bash


mihomo_execute()
{

CHAT_ID="$1"


RESULT=$(mihomo_status)


telegram_send "$CHAT_ID" "$RESULT"


}
