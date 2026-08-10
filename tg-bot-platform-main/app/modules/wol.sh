#!/bin/bash
# ============================================================
# WOL Module
# ============================================================


wake_pc()
{
    if [ -z "${WIN_MAC:-}" ]; then
        echo "❌ 未设置需要唤醒的电脑 MAC 地址，请先进入 tg-bot 菜单配置。"
        return
    fi


    if ! command -v wakeonlan >/dev/null 2>&1; then
        echo "❌ 系统未安装 wakeonlan 工具，请先运行修复命令安装依赖。"
        return
    fi


    wakeonlan "$WIN_MAC" >/dev/null 2>&1 || true


    echo
    echo "🚀 WOL 网络唤醒魔术包已发送！"
    echo "目标 MAC 地址: $WIN_MAC"
}