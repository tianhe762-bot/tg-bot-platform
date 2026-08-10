#!/bin/bash
# ============================================================
# Security Core
# ============================================================


require_admin()
{

USER_ID="$1"


for ID in $ADMINS

do

if [ "$USER_ID" = "$ID" ]

then

return 0

fi

done


return 1

}



require_confirm()
{


ACTION="$1"


FILE="/opt/tg_bot/data/confirm_$ACTION"



if [ -f "$FILE" ]

then

rm -f "$FILE"

return 0


else

touch "$FILE"

return 1

fi


}
