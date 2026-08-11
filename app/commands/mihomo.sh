#!/bin/bash


mihomo_execute()
{

CHAT_ID="$1"


RESULT=$(mihomo_nodes)


telegram_send "$CHAT_ID" "$RESULT"


}
