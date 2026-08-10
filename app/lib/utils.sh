#!/bin/bash


is_admin()
{

USER="$1"


for ID in $ADMINS

do

if [ "$USER" = "$ID" ]

then

return 0

fi

done


return 1

}
