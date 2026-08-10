#!/bin/bash


network_execute()
{

CHAT_ID="$1"


IFACE=$(ip route | awk '/default/ {print $5}')



RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)

TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)



telegram_send "$CHAT_ID" \
"🌐 网络:

网卡:
$IFACE

下载:
$RX bytes

上传:
$TX bytes"


}
