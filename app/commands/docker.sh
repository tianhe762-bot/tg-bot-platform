#!/bin/bash


docker_execute()
{

CHAT_ID="$1"

ARGS="$2"



if [[ "$ARGS" == restart* ]]

then


NAME=$(echo "$ARGS" | awk '{print $2}')



if require_confirm "docker"

then


RESULT=$(docker_restart "$NAME")


else


RESULT="
⚠️ Docker重启:

$NAME


再次发送:

/docker restart $NAME

确认。
"


fi



else


RESULT=$(docker_status)


fi



telegram_send "$CHAT_ID" "$RESULT"


}
