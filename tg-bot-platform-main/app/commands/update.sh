#!/bin/bash


update_execute()
{

CHAT_ID="$1"



if require_confirm "update"

then


telegram_send "$CHAT_ID" \
"开始更新系统..."



apt update && apt upgrade -y



telegram_send "$CHAT_ID" \
"✅ 更新完成"


else


telegram_send "$CHAT_ID" \
"⚠️ 更新系统属于危险操作。

再次发送:

/update

确认执行。"


fi


}
