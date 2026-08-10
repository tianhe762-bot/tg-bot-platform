#!/bin/bash


shutdown_execute()
{

CHAT_ID="$1"



if require_confirm "shutdown"

then


RESULT=$(confirm_shutdown)


else


RESULT="
⚠️ 危险操作:

即将关闭服务器。

再次发送:

/shutdown

确认执行。
"


fi



telegram_send "$CHAT_ID" "$RESULT"


}
