#!/bin/bash


ROOT="/opt/tg_bot"

DATE=$(date +"%Y%m%d")


tar czf - \
-C "$ROOT" \
config \
| openssl enc \
-aes-256-cbc \
-pbkdf2 \
-out "$ROOT/backups/config_$DATE.tar.gz.enc"


echo "配置加密备份完成"
