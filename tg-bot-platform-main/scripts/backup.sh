#!/bin/bash
# ============================================================
# TG Bot Backup v2
# ============================================================


ROOT="/opt/tg_bot"

BACKUP_DIR="$ROOT/backups"

DATE=$(date +"%Y%m%d_%H%M%S")


mkdir -p "$BACKUP_DIR"


PACKAGE="$BACKUP_DIR/tg_bot_backup_$DATE.tar.gz"



FILES="config app scripts VERSION"



# 如果存在systemd目录，则加入备份

if [ -d "$ROOT/systemd" ]

then

FILES="$FILES systemd"

fi



echo "开始备份..."

echo

echo "备份内容:"
echo "$FILES"

echo



tar \
-zczf "$PACKAGE" \
-C "$ROOT" \
$FILES



if [ $? -eq 0 ]

then

echo

echo "✅ 备份完成"

echo

echo "$PACKAGE"


else

echo

echo "❌ 备份失败"

fi
