#!/bin/bash
# ============================================================
# TG Bot Updater
# ============================================================


set -e


ROOT="/opt/tg_bot"

BACKUP="$ROOT/backups/update_backup"


PACKAGE_URL=$(grep TG_PACKAGE_URL \
"$ROOT/config/system.env" \
2>/dev/null \
| cut -d= -f2)



if [ -z "$PACKAGE_URL" ]

then

echo "❌ 未设置更新地址"

exit 1

fi



DATE=$(date +"%Y%m%d_%H%M%S")


mkdir -p "$BACKUP"



echo "1. 创建更新备份..."



tar \
-zcf "$BACKUP/before_$DATE.tar.gz" \
-C "$ROOT" \
app \
config \
scripts \
systemd \
VERSION



echo "✅ 备份完成"



TMP=$(mktemp -d)


echo

echo "2. 下载新版..."



curl -fL \
"$PACKAGE_URL" \
-o "$TMP/update.tar.gz"

CHECK_URL="${PACKAGE_URL}.sha256"


echo
echo "下载校验文件..."


curl -fsSL \
"$CHECK_URL" \
-o "$TMP/update.sha256" \
|| true



if [ -f "$TMP/update.sha256" ]

then


echo

echo "验证完整性..."


cd "$TMP"


if sha256sum -c update.sha256

then

echo "✅ 校验通过"

else

echo "❌ 校验失败"

exit 1

fi


fi


echo "✅ 下载完成"



echo

echo "3. 解压..."



mkdir "$TMP/new"


tar \
-zxf "$TMP/update.tar.gz" \
-C "$TMP/new"



SOURCE=$(find "$TMP/new" \
-mindepth 1 \
-maxdepth 1 \
-type d \
| head -1)



if [ -z "$SOURCE" ]

then

SOURCE="$TMP/new"

fi



if [ ! -f "$SOURCE/VERSION" ]

then

echo "❌ 更新包错误"

exit 1

fi



echo

echo "4. 停止服务..."

systemctl stop tg_bot.service || true



echo

echo "5. 更新程序..."



rsync -a \
--exclude config \
"$SOURCE/" \
"$ROOT/"



echo

echo "6. 恢复配置..."



systemctl daemon-reload


systemctl start tg_bot.service



echo

echo "7. 检查服务..."

sleep 5



if systemctl is-active tg_bot.service >/dev/null

then

echo

echo "================================"

echo "✅ 更新成功"

echo "================================"


else


echo

echo "❌ 服务启动失败"

echo "准备回滚"



exit 1


fi



rm -rf "$TMP"
