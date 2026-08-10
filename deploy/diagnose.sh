#!/bin/bash
# ============================================================
# TG Bot Diagnose
# ============================================================


ROOT="/opt/tg_bot"

CONFIG="$ROOT/config"


OK="✅"
FAIL="❌"


echo
echo "=========================================="
echo "        TG Bot 系统诊断"
echo "=========================================="
echo



# ------------------------------------------------
# 服务状态
# ------------------------------------------------

echo "[1] Bot服务"

if systemctl is-active tg_bot.service >/dev/null 2>&1

then

echo "$OK TG Bot运行正常"

else

echo "$FAIL TG Bot未运行"

fi


echo



# ------------------------------------------------
# 配置文件
# ------------------------------------------------

echo "[2] 配置检查"


for FILE in \
user.env \
device.env \
system.env

do


if [ -f "$CONFIG/$FILE" ]

then

echo "$OK $FILE"

else

echo "$FAIL 缺少 $FILE"

fi


done



echo



# ------------------------------------------------
# Telegram
# ------------------------------------------------

echo "[3] Telegram配置"


if grep -q "^TOKEN=" "$CONFIG/user.env" 2>/dev/null

then

echo "$OK Token存在"

else

echo "$FAIL Token缺失"

fi



echo



# ------------------------------------------------
# Docker
# ------------------------------------------------

echo "[4] Docker"


if command -v docker >/dev/null

then

echo "$OK Docker已安装"


COUNT=$(docker ps -q | wc -l)

echo "运行容器: $COUNT"


else

echo "$FAIL Docker未安装"

fi



echo


# ------------------------------------------------
# Mihomo
# ------------------------------------------------

echo "[5] Mihomo"


MIHOMO_OK=0



# 1. 检查TG Bot配置

if grep -q "^MIHOMO_API=" "$CONFIG/system.env" 2>/dev/null

then

echo "$OK Mihomo API 已配置"

MIHOMO_OK=1

fi



# 2. 检查进程

if ps aux | grep -v grep | grep -Ei "mihomo|clash" >/dev/null

then

echo "$OK Mihomo进程运行"

MIHOMO_OK=1

fi



# 3. 检查常见端口

if ss -lntp 2>/dev/null | grep -E "9090|7890|7891|9999" >/dev/null

then

echo "$OK Mihomo端口监听正常"

MIHOMO_OK=1

fi



if [ "$MIHOMO_OK" -eq 0 ]

then

echo "$FAIL 未检测到Mihomo"

fi


echo



# ------------------------------------------------
# WOL
# ------------------------------------------------

echo "[6] WOL"


MAC=$(grep WIN_MAC "$CONFIG/user.env" 2>/dev/null)


if [ -n "$MAC" ]

then

echo "$OK MAC已配置"

else

echo "$FAIL MAC未配置"

fi



echo



# ------------------------------------------------
# 磁盘
# ------------------------------------------------

echo "[7] 磁盘"


df -h /



echo



# ------------------------------------------------
# 内存
# ------------------------------------------------

echo "[8] 内存"


free -h



echo



# ------------------------------------------------
# Timer
# ------------------------------------------------

echo "[9] 定时任务"


systemctl list-timers --all \
| grep tg_ \
|| echo "无TG Timer"



echo



# ------------------------------------------------
# 更新源
# ------------------------------------------------

echo "[10] 更新配置"


if grep -q "^TG_PACKAGE_URL=" "$CONFIG/system.env" 2>/dev/null

then

echo "$OK 更新地址存在"

else

echo "$FAIL 未设置更新地址"

fi



echo

echo "=========================================="
echo "诊断完成"
echo "=========================================="
