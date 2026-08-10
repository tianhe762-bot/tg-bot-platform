#!/bin/bash
# ============================================================
# TG Bot Server Manager
# ============================================================


set -uo pipefail


ROOT="/opt/tg_bot"
CONFIG_DIR="$ROOT/config"
LOG_DIR="$ROOT/logs"
BACKUP_DIR="$ROOT/backups"


mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$BACKUP_DIR"


pause() {
    echo
    read -rp "按回车继续..." _
}


header() {
    clear
    VERSION="unknown"
    if [ -f "$ROOT/VERSION" ]; then
        VERSION=$(tr -d ' \r\n' < "$ROOT/VERSION")
    fi


    echo "=========================================="
    echo "       TG Bot Server Manager"
    echo "       Version: v$VERSION"
    echo "=========================================="
    echo
}


set_env() {
    local FILE="$1"
    local KEY="$2"
    local VALUE="$3"


    touch "$FILE"
    local TMP=$(mktemp)
    grep -v "^${KEY}=" "$FILE" > "$TMP" 2>/dev/null || true
    printf '%s=%q\n' "$KEY" "$VALUE" >> "$TMP"
    cat "$TMP" > "$FILE"
    rm -f "$TMP"
    chmod 600 "$FILE"
}


get_env() {
    local FILE="$1"
    local KEY="$2"
    if [ ! -f "$FILE" ]; then
        return
    fi
    (
        source "$FILE" 2>/dev/null || true
        eval "printf '%s' \"\${$KEY:-}\""
    )
}


restart_bot() {
    if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then
        systemctl restart tg_bot.service || true
    fi
}


telegram_config() {
    header
    local FILE="$CONFIG_DIR/user.env"


    echo "Telegram Bot 配置"
    echo


    while true; do
        read -rsp "请输入 Bot Token（输入时不显示）: " TOKEN
        echo
        if [ -n "$TOKEN" ]; then
            break
        fi
        echo "❌ Token 不能为空，请输入有效 Bot Token！"
        echo
    done


    while true; do
        read -rp "请输入管理员 Telegram User ID: " ADMIN_ID
        if [ -n "$ADMIN_ID" ]; then
            break
        fi
        echo "❌ 管理员 ID 不能为空，请输入有效 Telegram User ID！"
        echo
    done


    read -rp "请输入报警 Chat ID [默认同管理员ID]: " CHAT_ID
    if [ -z "$CHAT_ID" ]; then
        CHAT_ID="$ADMIN_ID"
    fi


    set_env "$FILE" "TOKEN" "$TOKEN"
    set_env "$FILE" "ADMINS" "$ADMIN_ID"
    set_env "$FILE" "ADMIN_CHAT_ID" "$CHAT_ID"


    echo
    echo "✅ Telegram 配置已保存"
    restart_bot
    pause
}


wol_config() {
    header
    local FILE="$CONFIG_DIR/user.env"


    echo "WOL 唤醒配置"
    echo
    CURRENT=$(get_env "$FILE" "WIN_MAC")
    if [ -n "$CURRENT" ]; then
        echo "当前已配置唤醒 MAC: $CURRENT"
    else
        echo "当前状态: 未配置 MAC 地址"
    fi
    echo
    echo "1. 修改 / 设置唤醒 MAC (覆盖已有设置)"
    echo "2. 清除 / 删除唤醒 MAC"
    echo "0. 返回"
    echo
    read -rp "请选择: " CHOICE


    case "$CHOICE" in
        1)
            read -rp "请输入需要唤醒电脑的 MAC 地址: " MAC
            if [ -z "$MAC" ]; then
                echo "❌ MAC 不能为空"
                pause
                return
            fi
            set_env "$FILE" "WIN_MAC" "$MAC"
            echo "✅ MAC 地址已保存: $MAC"
            restart_bot
            pause
            ;;
        2)
            set_env "$FILE" "WIN_MAC" ""
            echo "✅ 已成功清除 MAC 配置"
            restart_bot
            pause
            ;;
        0) return ;;
        *) echo "无效选项"; sleep 1 ;;
    esac
}


mihomo_config() {

    header

    local FILE="$CONFIG_DIR/system.env"

    CURRENT=$(get_env "$FILE" "MIHOMO_API")

    echo "Mihomo API 配置"
    echo
    echo "当前: ${CURRENT:-http://127.0.0.1:9999}"
    echo
    echo "输入 0 返回"
    echo

    read -rp "请输入 Mihomo API 地址 [http://127.0.0.1:9999]: " API


    if [ "$API" = "0" ]; then
        return
    fi


    if [ -z "$API" ]; then
        API="http://127.0.0.1:9999"
    fi


    set_env "$FILE" "MIHOMO_API" "$API"

    echo
    echo "✅ Mihomo API 已保存"

    restart_bot

    pause
}


storage_config() {
    header
    local FILE="$CONFIG_DIR/device.env"
    CURRENT=$(get_env "$FILE" "DATA_PATH")
    echo "数据盘存储目录配置"
    echo "说明: 用于监控数据存储盘磁盘空间 (例如外接挂载的存储盘或照片盘)"
    echo
    echo "当前配置路径: ${CURRENT:-/mnt/photos}"
    echo
    read -rp "请输入数据盘挂载路径 [/mnt/photos]: " PATH_INPUT
    if [ -z "$PATH_INPUT" ]; then
        PATH_INPUT="/mnt/photos"
    fi


    set_env "$FILE" "DATA_PATH" "$PATH_INPUT"
    echo
    echo "✅ 数据盘存储目录已保存为: $PATH_INPUT"
    restart_bot
    pause
}


backup_menu() {
    while true; do
        header
        echo "备份管理"
        echo
        echo "1. 立即备份"
        echo "2. 查看备份文件列表"
        echo "3. 恢复备份"
        echo "4. 清理 30 天以前的旧备份"
        echo "5. 查看备份空间占用"
        echo "0. 返回"
        echo
        read -rp "请选择: " CHOICE


        case "$CHOICE" in
            1)
                echo
                if [ -f "$ROOT/scripts/backup.sh" ]; then
                    bash "$ROOT/scripts/backup.sh"
                else
                    echo "❌ 备份脚本不存在"
                fi
                pause
                ;;
            2)
                echo
                echo "可用备份文件列表:"
                if [ -d "$BACKUP_DIR" ]; then
                    ls -lh "$BACKUP_DIR"
                else
                    echo "暂无备份"
                fi
                pause
                ;;
            3)
                echo
                echo "可用备份文件完整路径清单（复制下方任意完整路径或按序号选择即可）："
                echo
                idx=1
                declare -A BACKUP_MAP
                if [ -d "$BACKUP_DIR" ] && [ -n "$(find "$BACKUP_DIR" -maxdepth 2 -name "*.tar.gz" -type f 2>/dev/null)" ]; then
                    while IFS= read -r file; do
                        echo "  [$idx] $file"
                        BACKUP_MAP["$idx"]="$file"
                        idx=$((idx + 1))
                    done < <(find "$BACKUP_DIR" -maxdepth 2 -name "*.tar.gz" -type f | sort -r)
                else
                    echo "暂无可用备份"
                    pause
                    continue
                fi


                echo
                read -rp "请复制上方完整的备份路径 (或直接输入序号/文件名): " INPUT
                if [ -z "$INPUT" ]; then
                    echo "❌ 未输入内容"
                    pause
                    continue
                fi


                TARGET_FILE=""
                if [[ "$INPUT" =~ ^[0-9]+$ ]] && [ -n "${BACKUP_MAP[$INPUT]:-}" ]; then
                    TARGET_FILE="${BACKUP_MAP[$INPUT]}"
                elif [ -f "$INPUT" ]; then
                    TARGET_FILE="$INPUT"
                elif [ -f "$BACKUP_DIR/$INPUT" ]; then
                    TARGET_FILE="$BACKUP_DIR/$INPUT"
                fi


                if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
                    echo "❌ 备份文件不存在: $INPUT"
                    pause
                    continue
                fi


                echo "准备恢复备份: $TARGET_FILE"
                if [ -f "$ROOT/scripts/restore.sh" ]; then
                    bash "$ROOT/scripts/restore.sh" "$TARGET_FILE"
                elif [ -f "$ROOT/deploy/rollback.sh" ]; then
                    bash "$ROOT/deploy/rollback.sh" "$TARGET_FILE"
                fi
                pause
                ;;
            4)
                echo
                echo "清理 30 天前的旧备份..."
                find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
                echo "✅ 清理完成"
                pause
                ;;
            5)
                echo
                echo "备份空间占用:"
                du -sh "$BACKUP_DIR" 2>/dev/null || echo "暂无备份"
                echo
                echo "备份文件总数:"
                find "$BACKUP_DIR" -name "*.tar.gz" 2>/dev/null | wc -l
                pause
                ;;
            0) return ;;
            *) echo "无效选项"; sleep 1 ;;
        esac
    done
}


update_menu() {
    while true; do
        header
        echo "更新管理"
        echo
        echo "1. 检查更新 (单纯检测版本，不自动安装)"
        echo "2. 在线更新 (下载最新 Release 并执行更新)"
        echo "3. 回滚版本 (快速恢复到更新前的备份)"
        echo "4. 设置自定义更新源 (配置自定义下载 URL)"
        echo "5. 查看当前版本"
        echo "6. 查看更新备份列表"
        echo "0. 返回"
        echo
        read -rp "请选择: " CHOICE


        case "$CHOICE" in
            1)
                echo
                echo "开始检测远程最新版本..."
                if [ -f "$ROOT/deploy/version_check.sh" ]; then
                    bash "$ROOT/deploy/version_check.sh"
                fi
                pause
                ;;
            2)
                header
                echo "在线更新"
                echo
                echo "请选择更新模式："
                echo "1. 标准更新 (推荐，保留您的 config/*.env 个人配置、日志与备份)"
                echo "2. 完全重置更新 (清空所有个人配置并进行全量重装)"
                echo "0. 返回"
                echo
                read -rp "请选择更新模式 [默认 1]: " MODE
                MODE=${MODE:-1}


                if [ "$MODE" = "0" ]; then
                    continue
                fi


                if [ "$MODE" = "2" ]; then
                    read -rp "⚠️ 确定要完全清空配置并重装吗? (yes/no): " RESET_CONFIRM
                    if [ "$RESET_CONFIRM" = "yes" ]; then
                        rm -rf "$CONFIG_DIR"/*.env 2>/dev/null || true
                    fi
                fi


                echo
                if [ -f "$ROOT/deploy/updater.sh" ]; then
                    bash "$ROOT/deploy/updater.sh"
                fi
                pause
                ;;
            3)
                echo
                read -rp "确认执行版本回滚? (yes/no): " CONFIRM
                if [ "$CONFIRM" = "yes" ]; then
                    if [ -f "$ROOT/deploy/rollback.sh" ]; then
                        bash "$ROOT/deploy/rollback.sh"
                    fi
                else
                    echo "已取消"
                fi
                pause
                ;;
            4)
                header
                echo "设置自定义更新源"
                echo "说明: 设置后，【在线更新】功能将使用您配置的地址进行下载升级。"
                echo
                FILE="$ROOT/config/system.env"
                touch "$FILE"
                read -rp "请输入自定义软件包 URL (.tar.gz，留空还原为官方 GitHub): " PACKAGE_URL
                if [ -n "$PACKAGE_URL" ]; then
                    set_env "$FILE" "TG_BOT_PACKAGE_URL" "$PACKAGE_URL"
                    echo "✅ 自定义更新源已保存: $PACKAGE_URL"
                else
                    set_env "$FILE" "TG_BOT_PACKAGE_URL" ""
                    echo "已恢复为默认 GitHub Release 官方自动更新源"
                fi
                pause
                ;;
            5)
                header
                echo "当前系统版本:"
                if [ -f "$ROOT/VERSION" ]; then
                    cat "$ROOT/VERSION"
                else
                    echo "unknown"
                fi
                echo
                echo "系统安装目录: $ROOT"
                pause
                ;;
            6)
                header
                echo "更新备份列表:"
                if [ -d "$BACKUP_DIR" ]; then
                    ls -lh "$BACKUP_DIR"
                else
                    echo "暂无备份"
                fi
                pause
                ;;
            0) return ;;
            *) echo "无效选项"; sleep 1 ;;
        esac
    done
}

service_menu() {

    while true; do

        header

        echo "服务管理"
        echo
        echo "1. 查看 TG Bot 服务状态"
        echo "2. 启动 TG Bot"
        echo "3. 停止 TG Bot"
        echo "4. 重启 TG Bot"
        echo "5. 查看 Systemd 日志"
        echo "0. 返回"
        echo

        read -rp "请选择: " CHOICE


        case "$CHOICE" in

            1)
                systemctl status tg_bot.service --no-pager
                pause
                ;;

            2)
                systemctl start tg_bot.service
                echo "✅ 服务已启动"
                pause
                ;;

            3)
                systemctl stop tg_bot.service
                echo "✅ 服务已停止"
                pause
                ;;

            4)
                systemctl restart tg_bot.service
                echo "✅ 服务已重启"
                pause
                ;;

            5)
                journalctl -u tg_bot.service -n 50 --no-pager
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



logs_menu() {

    while true; do

        header

        echo "日志查看"
        echo
        echo "1. 查看 TG Bot 实时日志"
        echo "2. 查看 Systemd 服务日志"
        echo "0. 返回"
        echo

        read -rp "请选择: " CHOICE


        case "$CHOICE" in

            1)

                echo
                echo "TG Bot 日志:"
                echo

                if [ -f "$LOG_DIR/bot.log" ]; then
                    tail -50 "$LOG_DIR/bot.log"
                else
                    echo "❌ bot.log 不存在"
                fi

                pause
                ;;


            2)

                echo
                echo "Systemd 日志:"
                echo

                journalctl -u tg_bot.service -n 50 --no-pager || true

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


# ==============================
# 系统状态查看
# ==============================

status_menu() {

    header

    echo "系统状态"
    echo
    echo "=============================="

    echo
    echo "【系统信息】"
    hostnamectl 2>/dev/null || echo "无法获取系统信息"

    echo
    echo "【运行时间】"
    uptime

    echo
    echo "【CPU / 内存】"
    free -h

    echo
    echo "【磁盘空间】"
    df -h /

    echo
    echo "【TG Bot 服务】"

    if systemctl list-unit-files tg_bot.service >/dev/null 2>&1; then
        systemctl status tg_bot.service --no-pager || true
    else
        echo "❌ tg_bot.service 不存在"
    fi

    pause
}


main_menu() {
    while true; do
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
        echo "13. 一键卸载"
        echo
        echo "0. 退出"
        echo
        read -rp "请选择: " CHOICE


        case "$CHOICE" in
            1) [ -f "$ROOT/deploy/deploy.sh" ] && bash "$ROOT/deploy/deploy.sh"; pause ;;
            2) telegram_config ;;
            3) wol_config ;;
            4) mihomo_config ;;
            5) storage_config ;;
            6) service_menu ;;
            7) backup_menu ;;
            8) update_menu ;;
            9) status_menu ;;
            10) logs_menu ;;
            11) [ -f "$ROOT/deploy/diagnose.sh" ] && bash "$ROOT/deploy/diagnose.sh" || echo "❌ diagnose.sh 不存在"; pause ;;
            12)
                read -rp "确认执行自动修复? (yes/no): " CONFIRM
                if [ "$CONFIRM" = "yes" ]; then
                    [ -f "$ROOT/deploy/repair.sh" ] && bash "$ROOT/deploy/repair.sh" || echo "❌ repair.sh 不存在"
                fi
                pause
                ;;
            13)
                if [ -f "$ROOT/deploy/uninstall.sh" ]; then
                    bash "$ROOT/deploy/uninstall.sh"
                fi
                pause
                ;;
            0) clear; exit 0 ;;
            *) echo "无效选项"; sleep 1 ;;
        esac
    done
}


if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 权限运行 tg-bot"
    exit 1
fi


main_menu