#!/bin/bash


switch_execute()
{

CHAT_ID="$1"

ARGS="$2"

NAME=$(echo "$ARGS" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')


if [ -z "$NAME" ]
then
    RESULT="🔀 切换节点

用法:
/switch 节点名

示例:
/switch 香港01"
else
    RESULT=$(mihomo_switch "$NAME")
fi


telegram_send "$CHAT_ID" "$RESULT"


}
