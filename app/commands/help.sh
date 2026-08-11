#!/bin/bash


help_execute()
{

CHAT_ID="$1"


telegram_send "$CHAT_ID" \
"📖 使用帮助


🖥️ 系统状态:
/status — 服务器状态总览（主机/系统/运行时间/CPU/内存/磁盘/Docker/Mihomo）
/network — 查看网卡与累计流量
/traffic — 查看下载/上传累计流量
/cpu24 — 近24小时CPU负载
/mem24 — 近24小时内存使用
/network24 — 近24小时网络流量
/disk_history — 磁盘空间历史
/logs — 查看最近日志
/backup — 备份数据与配置
/update — 检查版本并更新机器人
/reboot — 重启服务器（需二次确认）
/shutdown — 关闭服务器（需二次确认）


🚀 代理与设备:
/mihomo — 查看可用节点与测速（只显示≤800ms的可用节点）
/switch 节点名 — 切换代理节点（节点名从 /mihomo 复制）
/wake — 发送WOL唤醒包开机


ℹ️ 其他:
/help — 显示本帮助"

}
