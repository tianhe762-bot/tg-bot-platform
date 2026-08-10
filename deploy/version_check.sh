#!/bin/bash
# ============================================================
# Version Check
# ============================================================


ROOT="/opt/tg_bot"


LOCAL_VERSION="unknown"


if [ -f "$ROOT/VERSION" ]

then

LOCAL_VERSION=$(cat "$ROOT/VERSION")

fi



REMOTE_URL=$(grep TG_VERSION_URL \
"$ROOT/config/system.env" \
2>/dev/null \
| cut -d= -f2)



if [ -z "$REMOTE_URL" ]

then

echo "❌ 未设置远程版本地址"

echo

echo "请先进入:"
echo "tg-bot"
echo
echo "8. 更新管理"
echo "4. 设置更新地址"

exit 1

fi


REMOTE_VERSION=$(curl -fsSL "$REMOTE_URL" 2>/dev/null)


if [ -z "$REMOTE_VERSION" ]

then

echo "❌ 无法获取远程版本"

exit 1

fi



echo "当前版本:"
echo "$LOCAL_VERSION"

echo

echo "远程版本:"
echo "$REMOTE_VERSION"


if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]

then

echo

echo "已经是最新版本"

else

echo

echo "发现新版本"

fi
