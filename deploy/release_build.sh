#!/bin/bash
# ============================================================
# TG Bot Release Builder
# ============================================================


ROOT="/opt/tg_bot"

RELEASE="/opt/tg_release"


VERSION=$(cat "$ROOT/VERSION")


PACKAGE="tg_bot-v${VERSION}.tar.gz"



mkdir -p "$RELEASE/releases"



echo "当前版本:"
echo "$VERSION"


echo

echo "执行发布检查..."

bash "$ROOT/tests/release_check.sh"


if [ $? -ne 0 ]

then

echo "❌ 发布检查失败"

exit 1

fi



echo

echo "开始打包..."



tar \
-zczf "$RELEASE/releases/$PACKAGE" \
-C "$ROOT" \
app \
deploy \
scripts \
systemd \
templates \
tests \
VERSION \
install.sh \
release.json


cp "$ROOT/VERSION" \
"$RELEASE/VERSION"



cp "$ROOT/install.sh" \
"$RELEASE/install.sh"



echo

echo "================================"

echo "发布完成"

echo

echo "$RELEASE/releases/$PACKAGE"
echo

echo "生成SHA256..."

sha256sum \
"$RELEASE/releases/$PACKAGE" \
> "$RELEASE/releases/$PACKAGE.sha256"


echo

echo "SHA256完成:"
cat "$RELEASE/releases/$PACKAGE.sha256"

echo "================================"
