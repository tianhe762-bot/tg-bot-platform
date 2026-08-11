#!/bin/bash


update_execute()
{

CHAT_ID="$1"

LATEST=""

TEXT=$(update_check)

RC=$?


if [ "$RC" -eq 0 ]
then
    if require_confirm "update"
    then
        if [ ! -f /opt/tg_bot/deploy/updater.sh ]
        then
            telegram_send "$CHAT_ID" "❌ 未找到更新脚本（deploy/updater.sh）"
            return 0
        fi
        LATEST=$(update_latest)
        [ -z "$LATEST" ] && LATEST="最新版"
        telegram_send "$CHAT_ID" \
"🚀 开始更新，正在升级至 v${LATEST}，请稍候…

更新完成后服务会自动重启。"
        nohup bash /opt/tg_bot/deploy/updater.sh \
        >> /opt/tg_bot/logs/update.log 2>&1 &
    else
        telegram_send "$CHAT_ID" "$TEXT"
    fi
else
    telegram_send "$CHAT_ID" "$TEXT"
fi


}
