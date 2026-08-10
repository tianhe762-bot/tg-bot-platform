#!/bin/bash
# ============================================================
# Build Release Package
# ============================================================


ROOT="/opt/tg_bot"


VERSION=$(cat "$ROOT/VERSION")


NAME="tg_bot-v$VERSION"



OUTPUT="/opt/$NAME.tar.gz"



echo "开始打包:"
echo "$NAME"


tar \
-zczf "$OUTPUT" \
-C "$ROOT" \
\
app \
deploy \
scripts \
systemd \
templates \
VERSION \
install.sh



echo

echo "完成"

echo

echo "$OUTPUT"
