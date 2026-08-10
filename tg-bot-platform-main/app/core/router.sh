#!/bin/bash
# ============================================================
# Command Router v3
# 支持参数
# ============================================================


route_command()
{

CMD="$1"

CHAT_ID="$2"

shift 2

ARGS="$@"



CMD_FILE="/opt/tg_bot/app/commands/${CMD}.sh"


FUNCTION="${CMD}_execute"



if [ -f "$CMD_FILE" ]

then


source "$CMD_FILE"



if declare -f "$FUNCTION" >/dev/null

then


"$FUNCTION" "$CHAT_ID" "$ARGS"



else


telegram_send "$CHAT_ID" \
"命令模块错误"


fi



else


telegram_send "$CHAT_ID" \
"未知命令"


fi


}
