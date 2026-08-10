#!/bin/bash
# ============================================================
# TG Bot Restore
# ============================================================


ROOT="/opt/tg_bot"


if [ -z "$1" ]

then

echo "请输入备份文件"

echo

echo "示例:"

echo "./restore.sh backups/tg_bot_backup_xxx.tar.gz"

exit 1

fi



FILE="$1"



if [ ! -f "$FILE" ]

then

echo "文件不存在"

exit 1

fi



echo "停止服务..."

systemctl stop tg_bot.service 2>/dev/null || true



tar \
-xzf "$FILE" \
-C "$ROOT"



echo "启动服务..."

systemctl start tg_bot.service 2>/dev/null || true



echo

echo "恢复完成"
