#!/bin/bash
# ============================================================
# Build Release Package
# ============================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"

if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ VERSION 文件不存在"
    exit 1
fi

VERSION=$(tr -d ' \r\n' < "$VERSION_FILE")
NAME="tg_bot-v$VERSION"
OUTPUT="/opt/$NAME.tar.gz"

echo "开始打包: $NAME"

tar -czf "$OUTPUT" \
    -C "$ROOT" \
    app deploy scripts systemd templates VERSION install.sh release.json

echo "✅ 打包完成: $OUTPUT"


