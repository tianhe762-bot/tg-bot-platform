#!/bin/bash


reboot_execute()
{

CHAT_ID="$1"



if require_confirm "reboot"

then


RESULT=$(confirm_reboot)


else


RESULT="
⚠️ 危险操作:

即将重启服务器。

再次发送:

/reboot

确认执行。
"


fi



telegram_send "$CHAT_ID" "$RESULT"


}
