#!/bin/bash


confirm_reboot_execute()
{

CHAT_ID="$1"


RESULT=$(confirm_reboot)


telegram_send "$CHAT_ID" "$RESULT"


}
