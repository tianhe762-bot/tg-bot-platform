#!/bin/bash


# URL 组装（无 IP 时只显示端口）
ports_url()
{
    local IP="$1" PORT="$2"

    if [ -n "$IP" ]
    then
        echo "http://$IP:$PORT"
    else
        echo "端口 $PORT"
    fi
}


# 解析 docker ps 输出（stdin）：行格式 名称\t端口映射
ports_parse_docker()
{
    awk '
        function add_port(name, port,    key) {
            if (port == "") return
            key = name "|" port
            if (!(key in seen)) {
                seen[key] = 1
                print name "|" port
            }
        }
        BEGIN { FS = "\t" }
        {
            name = $1
            if (name == "") next
            n = split($2, maps, ",")
            for (i = 1; i <= n; i++) {
                host = maps[i]
                gsub(/^[ \t]+/, "", host)
                sub(/->.*/, "", host)
                port = host
                sub(/^.*:/, "", port)
                add_port(name, port)
            }
        }'
}


# 解析 ss -lntp 输出（stdin）
ports_parse_ss()
{
    awk '
        $1 == "LISTEN" {
            port = $4
            sub(/^.*:/, "", port)
            if (port == "") next
            idx = index($0, "users:((\"")
            if (idx == 0) next
            proc = substr($0, idx + 9)
            sub(/".*/, "", proc)
            if (proc == "" || proc == "docker-proxy") next
            print proc "|" port
        }'
}


# 解析 netstat -tlnp 输出（stdin，ss 不可用时的回退）
ports_parse_netstat()
{
    awk '
        $6 == "LISTEN" {
            port = $4
            sub(/^.*:/, "", port)
            if (port == "") next
            proc = $7
            sub(/^[0-9]+\//, "", proc)
            sub(/^\//, "", proc)
            if (proc == "" || proc == "-" || proc == "docker-proxy") next
            print proc "|" port
        }'
}


# 获取 Docker 容器端口（测试可用 PORTS_DOCKER_RAW 覆盖）
ports_docker_lines()
{
    if [ -n "${PORTS_DOCKER_RAW:-}" ]
    then
        printf '%s\n' "$PORTS_DOCKER_RAW" | ports_parse_docker
    elif command -v docker >/dev/null 2>&1
    then
        docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | ports_parse_docker
    fi
}


# 获取非 Docker 监听端口（测试可用 PORTS_SS_RAW 覆盖）
ports_other_lines()
{
    if [ -n "${PORTS_SS_RAW:-}" ]
    then
        printf '%s\n' "$PORTS_SS_RAW" | ports_parse_ss
    elif command -v ss >/dev/null 2>&1
    then
        ss -lntp 2>/dev/null | ports_parse_ss
    elif command -v netstat >/dev/null 2>&1
    then
        netstat -tlnp 2>/dev/null | ports_parse_netstat
    fi
}


# 生成端口报告
ports_report()
{
    local IP LINE NAME PORT RESULT SECTION MIHOMO_PORT OTHER_RAW
    local -a DOCKER_LINES
    declare -A SEEN
    local COUNT=0

    IP="${PORTS_IP:-$(hostname -I 2>/dev/null | awk '{print $1}')}"

    RESULT="🌐 局域网服务端口"
    [ -n "$IP" ] && RESULT="$RESULT

服务器IP: $IP"

    # Docker 容器
    mapfile -t DOCKER_LINES < <(ports_docker_lines)
    SECTION=""
    for LINE in "${DOCKER_LINES[@]}"
    do
        NAME=${LINE%%|*}
        PORT=${LINE#*|}
        if [ -z "${SEEN[$PORT]:-}" ]
        then
            SEEN[$PORT]=1
            COUNT=$((COUNT + 1))
            SECTION="$SECTION• $NAME — $(ports_url "$IP" "$PORT")
"
        fi
    done
    if [ -n "$SECTION" ]
    then
        RESULT="$RESULT

🐳 Docker:
$SECTION"
    fi

    # 其他程序：Mihomo 面板优先，再补充监听端口扫描
    SECTION=""
    MIHOMO_PORT=$(echo "${MIHOMO_API:-}" | sed -n 's#.*:\([0-9][0-9]*\)/*$#\1#p')
    if [ -n "$MIHOMO_PORT" ] && [ -z "${SEEN[$MIHOMO_PORT]:-}" ]
    then
        SEEN[$MIHOMO_PORT]=1
        COUNT=$((COUNT + 1))
        SECTION="$SECTION• Mihomo 面板 — $(ports_url "$IP" "$MIHOMO_PORT")
"
    fi
    OTHER_RAW=$(ports_other_lines)
    while IFS= read -r LINE
    do
        [ -z "$LINE" ] && continue
        NAME=${LINE%%|*}
        PORT=${LINE#*|}
        if [ -z "${SEEN[$PORT]:-}" ]
        then
            SEEN[$PORT]=1
            COUNT=$((COUNT + 1))
            SECTION="$SECTION• $NAME — $(ports_url "$IP" "$PORT")
"
        fi
    done <<< "$OTHER_RAW"
    if [ -n "$SECTION" ]
    then
        RESULT="$RESULT

💻 其他程序:
$SECTION"
    fi

    # 手动配置补充
    SECTION=""
    for ITEM in ${PANEL_SERVICES:-}
    do
        NAME=${ITEM%%=*}
        PORT=${ITEM#*=}
        case "$PORT" in
            ''|*[!0-9]*) continue ;;
        esac
        if [ -z "${SEEN[$PORT]:-}" ]
        then
            SEEN[$PORT]=1
            COUNT=$((COUNT + 1))
            SECTION="$SECTION• $NAME — $(ports_url "$IP" "$PORT")
"
        fi
    done
    if [ -n "$SECTION" ]
    then
        RESULT="$RESULT

📝 手动配置:
$SECTION"
    fi

    if [ "$COUNT" -eq 0 ]
    then
        echo "❌ 未发现可访问的服务端口，请检查 Docker 与网络。"
        return 0
    fi

    echo "$RESULT"
}


ports_execute()
{

CHAT_ID="$1"


RESULT=$(ports_report)


telegram_send "$CHAT_ID" "$RESULT"


}
