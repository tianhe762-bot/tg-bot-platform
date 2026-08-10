#!/bin/bash
# ============================================================
# Rollback
# ============================================================

set -euo pipefail

ROOT="/opt/tg_bot"
BACKUP_DIR="$ROOT/backups"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ 没有备份目录"
    exit 1
fi

FILE=$(find "$BACKUP_DIR" -maxdepth 2 -name "*.tar.gz" -type f | sort -r | head -n 1)

if [ -z "$FILE" ]; then
    echo "❌ 没有可用备份"
    exit 1
fi

echo "准备恢复备份文件: $FILE"

systemctl stop tg_bot.service 2>/dev/null || true

tar -xzf "$FILE" -C "$ROOT"

systemctl daemon-reload 2>/dev/null || true
if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then
    systemctl start tg_bot.service 2>/dev/null || true
fi

echo
echo "✅ 回滚恢复完成"
