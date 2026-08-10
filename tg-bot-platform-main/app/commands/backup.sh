#!/bin/bash


backup_execute()
{

CHAT_ID="$1"


RESULT=$(backup_run)


telegram_send "$CHAT_ID" "$RESULT"


}
