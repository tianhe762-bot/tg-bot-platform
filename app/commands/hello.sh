#!/bin/bash


hello_execute()
{

CHAT_ID="$1"


telegram_send "$CHAT_ID" \
"你好，服务器机器人已经上线。"

}
