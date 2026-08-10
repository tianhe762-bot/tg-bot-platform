#!/bin/bash


load_modules()
{

MODULE_DIR="/opt/tg_bot/app/modules"



for FILE in "$MODULE_DIR"/*.sh

do

[ -f "$FILE" ] && source "$FILE"

done


}
