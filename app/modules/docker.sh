#!/bin/bash


docker_status()
{


docker ps \
--format "• {{.Names}} : {{.Status}}"


}



docker_restart()
{

NAME="$1"


if docker restart "$NAME"

then

echo "✅ 已重启:

$NAME"

else

echo "❌ 重启失败"

fi


}
