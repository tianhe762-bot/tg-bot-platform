#!/bin/bash
# ============================================================
# Alert Module
# ============================================================


send_alert()
{


MESSAGE="$1"



if [ -z "${ADMIN_CHAT_ID:-}" ]

then

return

fi



telegram_send \
"$ADMIN_CHAT_ID" \
"⚠️ 服务器报警

$MESSAGE"


}
