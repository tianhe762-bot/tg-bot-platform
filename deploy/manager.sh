#!/bin/bash
# ============================================================
# TG Bot Server Manager
# ============================================================

set -u

ROOT="/opt/tg_bot"
CONFIG_DIR="$ROOT/config"
LOG_DIR="$ROOT/logs"
BACKUP_DIR="$ROOT/backups"

mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$BACKUP_DIR"


# ============================================================
# 基础函数
# ============================================================

pause()
{
    echo
    read -rp "按回车继续..." _
}


header()
{
    clear

    VERSION="unknown"

    if [ -f "$ROOT/VERSION" ]; then
        VERSION=$(cat "$ROOT/VERSION")
    fi

    echo "=========================================="
    echo "       TG Bot Server Manager"
    echo "       Version: $VERSION"
    echo "=========================================="
    echo
}


set_env()
{
    FILE="$1"
    KEY="$2"
    VALUE="$3"

    touch "$FILE"

    TMP=$(mktemp)

    grep -v "^${KEY}=" "$FILE" > "$TMP" 2>/dev/null || true

    printf '%s=%q\n' "$KEY" "$VALUE" >> "$TMP"

    cat "$TMP" > "$FILE"

    rm -f "$TMP"

    chmod 600 "$FILE"
}


get_env()
{
    FILE="$1"
    KEY="$2"

    if [ ! -f "$FILE" ]; then
        return
    fi

    (
        source "$FILE" 2>/dev/null || true
        eval "printf '%s' \"\${$KEY:-}\""
    )
}


restart_bot()
{
    if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then
        systemctl restart tg_bot.service
    fi
}


# ============================================================
# Telegram配置
# ============================================================

telegram_config()
{
    header

    FILE="$CONFIG_DIR/user.env"

    echo "Telegram Bot 配置"
    echo

    read -rsp "请输入 Bot Token（输入时不显示）: " TOKEN
    echo

    read -rp "请输入管理员 Telegram User ID: " ADMIN_ID

    read -rp "请输入报警 Chat ID [默认同管理员ID]: " CHAT_ID

    if [ -z "$CHAT_ID" ]; then
        CHAT_ID="$ADMIN_ID"
    fi

    set_env "$FILE" "TOKEN" "$TOKEN"
    set_env "$FILE" "ADMINS" "$ADMIN_ID"
    set_env "$FILE" "ADMIN_CHAT_ID" "$CHAT_ID"

    echo
    echo "✅ Telegram配置已保存"

    restart_bot

    pause
}


# ============================================================
# WOL配置
# ============================================================

wol_config()
{
    header

    FILE="$CONFIG_DIR/user.env"

    echo "WOL 唤醒配置"
    echo

    CURRENT=$(get_env "$FILE" "WIN_MAC")

    if [ -n "$CURRENT" ]; then
        echo "当前 MAC: $CURRENT"
        echo
    fi

    read -rp "请输入需要唤醒电脑的 MAC 地址: " MAC

    if [ -z "$MAC" ]; then
        echo "❌ MAC不能为空"
        pause
        return
    fi

    set_env "$FILE" "WIN_MAC" "$MAC"

    echo
    echo "✅ MAC地址已保存"

    restart_bot

    pause
}


# ============================================================
# Mihomo配置
# ============================================================

mihomo_config()
{
    header

    FILE="$CONFIG_DIR/system.env"

    CURRENT=$(get_env "$FILE" "MIHOMO_API")

    echo "Mihomo API 配置"
    echo
    echo "当前: ${CURRENT:-http://127.0.0.1:9999}"
    echo

    read -rp "请输入 Mihomo API 地址 [http://127.0.0.1:9999]: " API

    if [ -z "$API" ]; then
        API="http://127.0.0.1:9999"
    fi

    set_env "$FILE" "MIHOMO_API" "$API"

    echo
    echo "✅ Mihomo API已保存"

    restart_bot

    pause
}


# ============================================================
# 存储配置
# ============================================================

storage_config()
{
    header

    FILE="$CONFIG_DIR/device.env"

    CURRENT=$(get_env "$FILE" "DATA_PATH")

    echo "数据盘配置"
    echo
    echo "当前: ${CURRENT:-/mnt/photos}"
    echo

    read -rp "请输入数据目录 [/mnt/photos]: " PATH_INPUT

    if [ -z "$PATH_INPUT" ]; then
        PATH_INPUT="/mnt/photos"
    fi

    set_env "$FILE" "DATA_PATH" "$PATH_INPUT"

    echo
    echo "✅ 数据目录已保存为:"
    echo "$PATH_INPUT"

    restart_bot

    pause
}


# ============================================================
# 服务管理
# ============================================================

service_menu()
{
    while true
    do
        header

        echo "服务管理"
        echo
        echo "1. 启动 Bot"
        echo "2. 停止 Bot"
        echo "3. 重启 Bot"
        echo "4. 查看 Bot 状态"
        echo "5. 启用开机启动"
        echo "6. 禁止开机启动"
        echo "7. 启动所有 Timer"
        echo "8. 查看 Timer"
        echo "0. 返回"
        echo

        read -rp "请选择: " CHOICE

        case "$CHOICE" in

        1)
            systemctl start tg_bot.service
            echo "✅ Bot已启动"
            pause
            ;;

        2)
            systemctl stop tg_bot.service
            echo "✅ Bot已停止"
            pause
            ;;

        3)
            systemctl restart tg_bot.service
            echo "✅ Bot已重启"
            pause
            ;;

        4)
            systemctl status tg_bot.service --no-pager
            pause
            ;;

        5)
            systemctl enable tg_bot.service
            echo "✅ 已启用开机启动"
            pause
            ;;

        6)
            systemctl disable tg_bot.service
            echo "✅ 已关闭开机启动"
            pause
            ;;

        7)
            systemctl start tg_monitor.timer 2>/dev/null || true
            systemctl start tg_health.timer 2>/dev/null || true
            systemctl start tg_backup.timer 2>/dev/null || true

            echo "✅ Timer已启动"
            pause
            ;;

        8)
            systemctl list-timers --all | grep -E 'tg_|NEXT|LEFT' || true
            pause
            ;;

        0)
            return
            ;;

        *)
            echo "无效选项"
            sleep 1
            ;;

        esac
    done
}


# ============================================================
# 备份管理
# ============================================================

backup_menu()
{

while true
do

header


echo "备份管理"
echo
echo "1. 立即备份"
echo "2. 查看备份文件"
echo "3. 恢复备份"
echo "4. 删除旧备份"
echo "5. 查看备份空间"
echo "0. 返回"
echo


read -rp "请选择: " CHOICE



case "$CHOICE" in



1)

echo

echo "开始备份..."

bash "$ROOT/scripts/backup.sh"

pause

;;



2)

echo

echo "备份列表:"

echo


if [ -d "$BACKUP_DIR" ]

then

ls -lh "$BACKUP_DIR"

else

echo "暂无备份"

fi


pause

;;



3)

echo

echo "可用备份:"

echo


if [ -d "$BACKUP_DIR" ]

then

ls -1 "$BACKUP_DIR"

else

echo "暂无备份"

pause

continue

fi


echo

read -rp "请输入备份文件完整路径: " FILE



if [ -z "$FILE" ]

then

echo "❌ 未输入文件"

pause

continue

fi



bash "$ROOT/scripts/restore.sh" "$FILE"


pause

;;



4)

echo

echo "删除30天以前的旧备份..."



find "$BACKUP_DIR" \
-name "*.tar.gz" \
-mtime +30 \
-delete



echo

echo "✅ 清理完成"


pause

;;



5)

echo

echo "备份空间占用:"

echo


du -sh "$BACKUP_DIR" 2>/dev/null || \
echo "暂无备份"



echo

echo "备份文件数量:"

find "$BACKUP_DIR" \
-name "*.tar.gz" \
| wc -l



pause

;;



0)

return

;;



*)

echo "无效选项"

sleep 1

;;



esac


done

}

# ============================================================
# 日志
# ============================================================

logs_menu()
{
    header

    echo "========== systemd =========="
    echo

    journalctl -u tg_bot.service -n 50 --no-pager 2>/dev/null || true

    echo
    echo "========== bot.log =========="
    echo

    if [ -f "$LOG_DIR/bot.log" ]; then
        tail -50 "$LOG_DIR/bot.log"
    else
        echo "暂无 bot.log"
    fi

    pause
}


# ============================================================
# 状态
# ============================================================

status_menu()
{
    header

    echo "Bot:"
    systemctl is-active tg_bot.service 2>/dev/null || true

    echo
    echo "开机启动:"
    systemctl is-enabled tg_bot.service 2>/dev/null || true

    echo
    echo "系统:"
    uname -a

    echo
    echo "运行时间:"
    uptime -p

    echo
    echo "内存:"
    free -h

    echo
    echo "磁盘:"
    df -h /

    echo
    echo "Docker:"
    docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null || \
    echo "Docker不可用"

    echo
    echo "Timers:"
    systemctl list-timers --all | grep tg_ || true

    pause
}


# ============================================================
# 更新源
# ============================================================

configure_update_url()
{
    header

    FILE="$CONFIG_DIR/system.env"

    CURRENT=$(get_env "$FILE" "TG_BOT_PACKAGE_URL")

    echo "程序更新源"
    echo
    echo "当前:"
    echo "${CURRENT:-未设置}"
    echo
    echo "请输入完整 tar.gz 下载地址。"
    echo

    read -rp "URL: " URL

    if [ -z "$URL" ]; then
        echo "未修改"
        pause
        return
    fi

    set_env "$FILE" "TG_BOT_PACKAGE_URL" "$URL"

    echo
    echo "✅ 更新地址已保存"

    pause
}


# ============================================================
# 在线更新
# ============================================================

online_update()
{
    header

    FILE="$CONFIG_DIR/system.env"

    URL=$(get_env "$FILE" "TG_BOT_PACKAGE_URL")

    if [ -z "$URL" ]; then
        echo "❌ 尚未设置程序下载地址"
        echo
        echo "请先选择“设置更新地址”。"
        pause
        return
    fi

    echo "下载:"
    echo "$URL"
    echo

    TMP_DIR=$(mktemp -d)
    PACKAGE="$TMP_DIR/package.tar.gz"
    EXTRACT="$TMP_DIR/extract"

    mkdir -p "$EXTRACT"

    if ! curl -fL "$URL" -o "$PACKAGE"; then
        echo "❌ 下载失败"
        rm -rf "$TMP_DIR"
        pause
        return
    fi

    if ! tar -xzf "$PACKAGE" -C "$EXTRACT"; then
        echo "❌ 解压失败"
        rm -rf "$TMP_DIR"
        pause
        return
    fi

    SOURCE=$(find "$EXTRACT" -mindepth 1 -maxdepth 1 -type d | head -1)

    if [ -z "$SOURCE" ]; then
        SOURCE="$EXTRACT"
    fi

    if [ ! -f "$SOURCE/deploy/deploy.sh" ]; then
        echo "❌ 安装包中没有 deploy/deploy.sh"
        rm -rf "$TMP_DIR"
        pause
        return
    fi

    echo
    echo "开始更新..."

    bash "$SOURCE/deploy/deploy.sh" "$SOURCE"

    RESULT=$?

    rm -rf "$TMP_DIR"

    if [ "$RESULT" -eq 0 ]; then
        echo
        echo "✅ 更新完成"
    else
        echo
        echo "❌ 更新失败"
    fi

    pause
}


update_menu()
{

while true
do


header


echo "更新管理"
echo
echo "1. 检查更新"
echo "2. 在线更新"
echo "3. 回滚版本"
echo "4. 设置更新地址"
echo "5. 查看当前版本"
echo "6. 查看更新备份"
echo "0. 返回"
echo


read -rp "请选择: " CHOICE



case "$CHOICE" in



1)

echo

echo "检查远程版本..."

echo


if [ -f "$ROOT/deploy/version_check.sh" ]

then

bash "$ROOT/deploy/version_check.sh"

else

echo "❌ version_check.sh 不存在"

fi


pause

;;



2)

echo

echo "开始在线更新..."

echo



if [ -f "$ROOT/deploy/updater.sh" ]

then

bash "$ROOT/deploy/updater.sh"

else

echo "❌ updater.sh 不存在"

fi


pause

;;



3)

echo

echo "准备回滚..."

echo


read -rp "确认执行回滚? (yes/no): " CONFIRM



if [ "$CONFIRM" = "yes" ]

then


if [ -f "$ROOT/deploy/rollback.sh" ]

then

bash "$ROOT/deploy/rollback.sh"

else

echo "❌ rollback.sh 不存在"

fi


else

echo "已取消"

fi


pause

;;



4)

header


echo "设置更新地址"

echo

echo "需要设置两个地址："

echo

echo "1. VERSION地址"

echo "2. 软件包下载地址"

echo



FILE="$ROOT/config/system.env"



touch "$FILE"



read -rp "VERSION URL: " VERSION_URL


read -rp "PACKAGE URL: " PACKAGE_URL



if [ -n "$VERSION_URL" ]

then

sed -i '/^TG_VERSION_URL=/d' "$FILE"

echo "TG_VERSION_URL=\"$VERSION_URL\"" >> "$FILE"

fi



if [ -n "$PACKAGE_URL" ]

then

sed -i '/^TG_PACKAGE_URL=/d' "$FILE"

echo "TG_PACKAGE_URL=\"$PACKAGE_URL\"" >> "$FILE"

fi



chmod 600 "$FILE"



echo

echo "✅ 更新地址保存完成"


pause

;;



5)

header


echo "当前版本:"

echo


if [ -f "$ROOT/VERSION" ]

then

cat "$ROOT/VERSION"

else

echo "unknown"

fi


echo

echo "安装目录:"

echo "$ROOT"


pause

;;



6)

header


echo "更新备份列表"

echo


DIR="$ROOT/backups/update_backup"



if [ -d "$DIR" ]

then

ls -lh "$DIR"

else

echo "暂无更新备份"

fi


pause

;;



0)

return

;;



*)

echo "无效选项"

sleep 1

;;



esac


done

}

# ============================================================
# 主菜单
# ============================================================

main_menu()
{

while true
do


header


echo "1. 安装 / 修复"
echo "2. Telegram Bot 配置"
echo "3. WOL / MAC 配置"
echo "4. Mihomo 配置"
echo "5. 数据盘配置"
echo "6. 服务管理"
echo "7. 备份管理"
echo "8. 更新管理"
echo
echo "9. 查看系统状态"
echo "10. 查看日志"
echo "11. 系统诊断"
echo "12. 一键修复"
echo
echo "0. 退出"
echo


read -rp "请选择: " CHOICE



case "$CHOICE" in



1)

bash "$ROOT/deploy/deploy.sh"

pause

;;



2)

telegram_config

;;



3)

wol_config

;;



4)

mihomo_config

;;



5)

storage_config

;;



6)

service_menu

;;



7)

backup_menu

;;



8)

update_menu

;;



9)

status_menu

;;



10)

logs_menu

;;



11)

echo

echo "启动系统诊断..."

echo


if [ -f "$ROOT/deploy/diagnose.sh" ]

then

bash "$ROOT/deploy/diagnose.sh"

else

echo "❌ diagnose.sh 不存在"

fi


pause

;;



12)

echo

read -rp "确认执行自动修复? (yes/no): " CONFIRM



if [ "$CONFIRM" = "yes" ]

then


if [ -f "$ROOT/deploy/repair.sh" ]

then

bash "$ROOT/deploy/repair.sh"

else

echo "❌ repair.sh 不存在"

fi



else

echo "已取消"

fi


pause

;;



0)

clear

exit 0

;;



*)

echo "无效选项"

sleep 1

;;


esac


done

}

if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 权限运行 tg-bot"
    exit 1
fi


main_menu
