#!/bin/bash


LOG_FILE="/opt/tg_bot/logs/bot.log"



log()
{

echo "$(date '+%F %T') $1" >> "$LOG_FILE"

}



log_command()
{

USER="$1"

CMD="$2"


log "USER=$USER COMMAND=$CMD"

}
