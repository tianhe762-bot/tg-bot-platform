#!/bin/bash


help_execute()
{

CHAT_ID="$1"


telegram_send "$CHAT_ID" \
"📖 使用帮助


🖥️ 系统状态:
/status — 服务器状态总览（CPU使用率/温度/内存/磁盘/Docker/网络/Mihomo节点）
/ports — 查看各服务访问端口（Docker/其他程序/手动配置）
/update — 检查版本并更新机器人
/backup — 备份数据与配置
/reboot — 重启服务器（需二次确认）
/shutdown — 关闭服务器（需二次确认）


🚀 代理与设备:
/mihomo — 查看可用节点与测速
/switch — 切换代理节点
/wake — 发送WOL唤醒包开机


ℹ️ 其他:
/help — 显示本帮助


🔀 切换节点模板:
1. 发送 /mihomo 查看可用节点
2. 复制一个节点名
3. 把下面的“节点名”替换后发送:

/switch 节点名

例如:
/switch 美国-洛杉矶01"

}
