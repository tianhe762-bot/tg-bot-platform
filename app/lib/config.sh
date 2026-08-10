#!/bin/bash

ROOT="/opt/tg_bot"

CONFIG_DIR="$ROOT/config"


load_config()
{

for FILE in \
system.env \
user.env \
device.env

do

    if [ -f "$CONFIG_DIR/$FILE" ]
    then
        source "$CONFIG_DIR/$FILE"
    fi

done

}
