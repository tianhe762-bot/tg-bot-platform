#!/bin/bash


confirm_shutdown_execute()
{

CHAT_ID="$1"


RESULT=$(confirm_shutdown)


telegram_send "$CHAT_ID" "$RESULT"


}
