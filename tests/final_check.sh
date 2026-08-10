#!/bin/bash


ROOT="/opt/tg_bot"


ERROR=0


echo "================================"
echo " TG Bot Final Release Check"
echo "================================"


FILES=(

"VERSION"

"install.sh"

"release.json"

"deploy/deploy.sh"

"deploy/manager.sh"

"deploy/updater.sh"

"deploy/first_setup.sh"

"scripts/backup.sh"

)



for FILE in "${FILES[@]}"
do

if [ -f "$ROOT/$FILE" ]

then

echo "✅ $FILE"

else

echo "❌ $FILE"

ERROR=1

fi

done



echo


if [ "$ERROR" -eq 0 ]

then

echo "================================"

echo "✅ 发布检查全部通过"

echo "================================"

else

echo "================================"

echo "❌ 存在缺失文件"

echo "================================"

fi
