#!/bin/bash


ROOT="/opt/tg_bot"


echo "=============================="
echo " TG Bot Security Check"
echo "=============================="


echo


echo "[1] 配置权限"


for f in $ROOT/config/*.env
do

PERM=$(stat -c "%a" "$f")

echo "$f : $PERM"

done



echo


echo "[2] 脚本权限"


find "$ROOT" \
-name "*.sh" \
-perm /111 \
| wc -l



echo


echo "[3] 敏感文件"


grep -R "TOKEN=" \
"$ROOT" \
--exclude-dir=config \
2>/dev/null



echo

echo "检查完成"
