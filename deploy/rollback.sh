#!/bin/bash
# ============================================================
# Rollback
# ============================================================


ROOT="/opt/tg_bot"

BACKUP_DIR="$ROOT/backups/update_backup"



FILE=$(ls -t "$BACKUP_DIR"/*.tar.gz \
2>/dev/null \
| head -1)



if [ -z "$FILE" ]

then

echo "没有可用备份"

exit 1

fi



echo "恢复:"
echo "$FILE"



systemctl stop tg_bot.service



tar \
-zxf "$FILE" \
-C "$ROOT"



systemctl daemon-reload


systemctl start tg_bot.service



echo

echo "✅ 回滚完成"
