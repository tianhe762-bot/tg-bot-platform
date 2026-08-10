#!/bin/bash
# ============================================================
# TG Bot Uninstall Script
# ============================================================


set -euo pipefail


if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请使用 root 权限运行卸载程序"
    exit 1
fi


echo "=========================================="
echo "       TG Bot 卸载程序"
echo "=========================================="
echo


read -rp "⚠️ 确定要彻底卸载 TG Bot Platform 吗? (yes/no): " CONFIRM


if [ "$CONFIRM" != "yes" ]; then
    echo "卸载已取消。"
    exit 0
fi


echo
echo "[1/4] 停止并禁用所有 Systemd 服务与定时器..."
systemctl stop tg_bot.service 2>/dev/null || true
systemctl disable tg_bot.service 2>/dev/null || true


for timer in tg_monitor.timer tg_health.timer tg_backup.timer; do
    systemctl stop "$timer" 2>/dev/null || true
    systemctl disable "$timer" 2>/dev/null || true
done


echo "[2/4] 清理 Systemd 配置文件..."
rm -f /etc/systemd/system/tg_*.service /etc/systemd/system/tg_*.timer
systemctl daemon-reload 2>/dev/null || true


echo "[3/4] 移除快捷访问软链接..."
rm -f /usr/local/bin/tg-bot


echo "[4/4] 配置文件与数据清理..."
read -rp "是否同时删除运行数据及配置文件 (/opt/tg_bot)? (y/N): " DEL_DATA


if [[ "$DEL_DATA" == "y" || "$DEL_DATA" == "Y" ]]; then
    rm -rf /opt/tg_bot
    echo "✅ 已成功清除所有程序目录与个人数据。"
else
    echo "已保留 /opt/tg_bot 目录及数据。"
fi


echo
echo "=========================================="
echo " ✅ TG Bot Platform 已成功卸载！"
echo "=========================================="