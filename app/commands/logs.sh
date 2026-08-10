#!/bin/bash


logs_execute()
{

CHAT_ID="$1"


RESULT=$(log_recent)


telegram_send "$CHAT_ID" "$RESULT"


}
