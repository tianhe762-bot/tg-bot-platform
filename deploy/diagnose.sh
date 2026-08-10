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

# [1] 服务状态
echo "[1] Bot服务状态"
if systemctl is-active tg_bot.service >/dev/null 2>&1; then
    echo "$OK TG Bot 运行正常"
else
    echo "$FAIL TG Bot 未运行"
fi
echo

# [2] 配置文件检查
echo "[2] 配置文件检查"
for FILE in user.env device.env system.env; do
    if [ -f "$CONFIG/$FILE" ]; then
        echo "$OK $FILE 存在"
    else
        echo "$FAIL 缺少 $FILE"
    fi
done
echo

# [3] Telegram配置
echo "[3] Telegram配置"
if grep -q "^TOKEN=" "$CONFIG/user.env" 2>/dev/null; then
    echo "$OK Bot Token 已配置"
else
    echo "$FAIL Bot Token 缺失"
fi
echo

# [4] Docker检查
echo "[4] Docker环境"
if command -v docker >/dev/null 2>&1; then
    echo "$OK Docker 已安装"
    COUNT=$(docker ps -q 2>/dev/null | wc -l || echo 0)
    echo "    当前运行容器数: $COUNT"
else
    echo "$FAIL Docker 未安装"
fi
echo

# [5] Mihomo代理检查
echo "[5] Mihomo"
MIHOMO_OK=0
if grep -q "^MIHOMO_API=" "$CONFIG/system.env" 2>/dev/null; then
    echo "$OK Mihomo API 已配置"
    MIHOMO_OK=1
fi

if ps aux | grep -v grep | grep -Ei "mihomo|clash" >/dev/null 2>&1; then
    echo "$OK Mihomo 进程运行中"
    MIHOMO_OK=1
fi

if ss -lntp 2>/dev/null | grep -E "9090|7890|7891|9999" >/dev/null 2>&1; then
    echo "$OK Mihomo 端口监听正常"
    MIHOMO_OK=1
fi

if [ "$MIHOMO_OK" -eq 0 ]; then
    echo "$FAIL 未检测到 Mihomo"
fi
echo

# [6] WOL网络唤醒
echo "[6] WOL 网络唤醒"
MAC=$(grep "^WIN_MAC=" "$CONFIG/user.env" 2>/dev/null || true)
if [ -n "$MAC" ]; then
    echo "$OK MAC 地址已配置"
else
    echo "$FAIL MAC 地址未配置"
fi
echo

# [7] 资源占用
echo "[7] 磁盘与内存空间"
df -h /
echo
free -h
echo

# [8] Timer定时任务
echo "[8] 定时任务状态"
systemctl list-timers --all 2>/dev/null | grep tg_ || echo "无运行中的 TG Timer"
echo

# [9] 更新源与网络检查
echo "[9] 更新源配置"
if grep -q "^TG_BOT_PACKAGE_URL=" "$CONFIG/system.env" 2>/dev/null || grep -q "^TG_PACKAGE_URL=" "$CONFIG/system.env" 2>/dev/null; then
    echo "$OK 已配置自定义更新源"
else
    echo "$OK 使用默认 GitHub Release 自动更新源"
fi
echo

echo "=========================================="
echo "诊断完成"
echo "=========================================="
