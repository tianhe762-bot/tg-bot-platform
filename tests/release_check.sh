#!/bin/bash
# ============================================================
# Release Check
# ============================================================


set -e


ROOT="$(cd "$(dirname "$0")/.." && pwd)"


ERROR=0


FILES=(

"app/tg_bot.sh"

"app/modules/system.sh"

"deploy/deploy.sh"

"deploy/manager.sh"

"deploy/updater.sh"

"deploy/release_build.sh"

"install.sh"

"VERSION"

"release.json"

)



echo "TG Bot Release Check"

echo "================================"


for FILE in "${FILES[@]}"
do

if [ ! -f "$ROOT/$FILE" ]

then

echo "❌ 缺少:"
echo "$FILE"

ERROR=1

else

echo "✅ $FILE"

fi

done



echo

echo "检查Shell语法..."


while IFS= read -r FILE
do

if ! bash -n "$FILE"
then

echo "❌ 语法错误:"
echo "$FILE"

ERROR=1

fi


done < <(find "$ROOT" -type f -name "*.sh" -not -path "$ROOT/.git/*")



echo


if [ "$ERROR" -eq 0 ]

then

echo "================================"

echo "✅ 发布检查全部通过"

echo "================================"

else

echo "================================"

echo "❌ 发布检查失败"

echo "================================"

exit 1

fi
