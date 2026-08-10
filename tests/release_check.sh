#!/bin/bash
# ============================================================
# Release Check
# ============================================================


ROOT="/opt/tg_bot"


ERROR=0



FILES=(

"app/tg_bot.sh"

"deploy/deploy.sh"

"deploy/manager.sh"

"install.sh"

"VERSION"

)



for FILE in "${FILES[@]}"

do


if [ ! -f "$ROOT/$FILE" ]

then

echo "缺少:"
echo "$FILE"

ERROR=1


fi


done



if [ "$ERROR" -eq 0 ]

then

echo

echo "✅ 发布检查通过"


else

echo

echo "❌ 发布检查失败"

fi
