#!/bin/bash
# ============================================================
# Telegram Server Bot
# Status Check v1
# ============================================================


echo "================================"
echo "Telegram Bot 状态"
echo "================================"


systemctl status tg_bot \
--no-pager \
2>/dev/null | head -20



echo

echo "================================"
echo "Mihomo"
echo "================================"


curl -s \
--max-time 2 \
http://127.0.0.1:9999/version \
|| echo "Mihomo API unavailable"



echo

echo "================================"
echo "Docker"
echo "================================"


if command -v docker >/dev/null
then

docker ps --format \
"{{.Names}}\t{{.Status}}"

else

echo "Docker 未安装"

fi



echo

echo "================================"
echo "磁盘"
echo "================================"


df -h | grep -E "/$|/mnt/photos"



echo

echo "================================"
echo "内存"
echo "================================"


free -h



echo

echo "================================"
echo "CPU"
echo "================================"


uptime


