#!/bin/bash
# ============================================================
# WOL Module
# ============================================================


wake_pc()
{


if [ -z "${WIN_MAC:-}" ]

then

echo "❌ 未设置MAC地址"

return

fi



if ! command -v wakeonlan >/dev/null 2>&1

then

echo "❌ wakeonlan未安装"

return

fi



wakeonlan "$WIN_MAC"


echo

echo "🚀 WOL唤醒包已发送"

echo "$WIN_MAC"


}
