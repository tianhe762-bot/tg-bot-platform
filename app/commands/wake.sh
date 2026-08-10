#!/bin/bash


wake_execute()
{

CHAT_ID="$1"


RESULT=$(wake_pc)


telegram_send "$CHAT_ID" "$RESULT"


}
