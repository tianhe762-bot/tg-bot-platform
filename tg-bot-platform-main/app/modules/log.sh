#!/bin/bash


log_recent()
{


FILE="/opt/tg_bot/logs/bot.log"


if [ ! -f "$FILE" ]

then

echo "暂无日志"

return

fi



tail -30 "$FILE"


}
