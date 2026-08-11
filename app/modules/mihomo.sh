#!/bin/bash
# ============================================================
# Mihomo Module（通用版：不依赖任何组名/配置结构）
# ============================================================


# 测速地址与过滤条件
MIHOMO_TEST_URL="https://www.gstatic.com/generate_204"
MIHOMO_DELAY_MAX=800
MIHOMO_DELAY_TIMEOUT=3000
MIHOMO_NODE_LIMIT=80


# 非节点（组/内置）类型集合
MIHOMO_GROUP_TYPES="Selector|URLTest|Fallback|LoadBalance|Relay|Direct|Reject|RejectDrop|Compatible|Pass|GLOBAL"


mihomo_api()
{
    echo "${MIHOMO_API:-http://127.0.0.1:9999}"
}


# URL 编码（兼容中文/空格节点名）
mihomo_uri()
{
    jq -rn --arg v "$1" '$v|@uri' | tr -d '\r'
}


# 获取最底层节点（过滤组/内置类型并去重）
mihomo_leaf_nodes_from()
{
    local PROXIES="$1"

    echo "$PROXIES" | jq -r --arg t "$MIHOMO_GROUP_TYPES" '
        [ .proxies | to_entries[]
          | select(.value.type as $ty | ($t | split("|")) | index($ty) | not)
          | .key ]
        | unique[]' | tr -d '\r'
}


mihomo_leaf_nodes()
{
    mihomo_leaf_nodes_from "$(curl -s --max-time 3 "$(mihomo_api)/proxies")"
}


# 主组识别（纯结构、无名字）：
# 优先 Selector，其次包含子组最多的组，再其次叶子最多的组
mihomo_main_group_from()
{
    local PROXIES="$1"

    echo "$PROXIES" | jq -r --arg t "$MIHOMO_GROUP_TYPES" '
        . as $p |
        [ $p.proxies | to_entries[]
          | select(.value.type == "Selector" or .value.type == "URLTest" or .value.type == "Fallback" or .value.type == "LoadBalance")
          | select(.key != "GLOBAL" and .key != "DIRECT" and .key != "REJECT" and .key != "REJECT-DROP")
          | { key: .key, type: .value.type,
              leaves: ([ .value.all[]? as $n | select(($p.proxies[$n].type // "") as $ty | ($t | split("|")) | index($ty) | not) | $n ] | length),
              groups: ([ .value.all[]? as $n | select(($p.proxies[$n].type // "") as $ty | ($t | split("|")) | index($ty)) | $n ] | length) } ] as $g
        | ( $g | sort_by(if .type == "Selector" then 0 else 1 end, -.groups, -.leaves) | .[0].key ) // empty' | tr -d '\r'
}


# 获取组当前选中项
mihomo_group_now_from()
{
    local PROXIES="$1" GROUP="$2"

    echo "$PROXIES" | jq -r --arg g "$GROUP" '.proxies[$g].now // empty' | tr -d '\r'
}


# 递归解析到最底层节点（沿 now 链）
mihomo_resolve_leaf_from()
{
    local PROXIES="$1" NAME="$2" TYPE NOW
    local -i DEPTH=0

    [ -z "$PROXIES" ] && { echo "$NAME"; return 0; }

    while [ "$DEPTH" -lt 10 ]
    do
        TYPE=$(echo "$PROXIES" | jq -r --arg n "$NAME" '.proxies[$n].type // empty' | tr -d '\r')
        case "$TYPE" in
            Selector|URLTest|Fallback|LoadBalance|Relay|Compatible)
                NOW=$(echo "$PROXIES" | jq -r --arg n "$NAME" '.proxies[$n].now // empty' | tr -d '\r')
                [ -z "$NOW" ] && break
                NAME="$NOW"
                DEPTH=$((DEPTH + 1))
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$NAME"
}


# 真实当前节点：优先 /connections 链路首元素（完全无组名依赖）
mihomo_real_node()
{
    local RAW NODE

    RAW=$(curl -s --max-time 3 "$(mihomo_api)/connections")
    [ -z "$RAW" ] && return 0

    NODE=$(echo "$RAW" | jq -r '
        [ .connections[]? | select((.chains // []) | length > 0) | .chains[0]
          | select(. != "DIRECT" and . != "REJECT" and . != "REJECT-DROP" and . != "GLOBAL" and . != "PASS") ][0] // empty' | tr -d '\r')

    if [ -z "$NODE" ]
    then
        NODE=$(echo "$RAW" | jq -r '.connections[]? | select((.chains // []) | length > 0) | .chains[0]' | head -1 | tr -d '\r')
    fi

    echo "$NODE"
}


# 当前节点：真实链路优先，无活跃连接时回退主组链解析
mihomo_current_node_effective()
{
    local PROXIES="$1" NODE MAIN

    NODE=$(mihomo_real_node)
    if [ -z "$NODE" ]
    then
        MAIN=$(mihomo_main_group_from "$PROXIES")
        NODE=$(mihomo_group_now_from "$PROXIES" "$MAIN")
        NODE=$(mihomo_resolve_leaf_from "$PROXIES" "$NODE")
    fi

    echo "$NODE"
}


# 测速单个节点，输出延迟毫秒；失败输出空
mihomo_delay()
{
    local NAME="$1"
    local RESULT

    RESULT=$(curl -s --max-time 3 \
        "$(mihomo_api)/proxies/$(mihomo_uri "$NAME")/delay?url=$MIHOMO_TEST_URL&timeout=$MIHOMO_DELAY_TIMEOUT")

    echo "$RESULT" | jq -r '.delay // empty' 2>/dev/null | tr -d '\r'
}


# /status 使用：汇报真实当前节点与延迟
mihomo_connected()
{
    local PROXIES NODE DELAY

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
    [ -z "$PROXIES" ] && { echo "❌ 未开启"; return 0; }

    NODE=$(mihomo_current_node_effective "$PROXIES")

    if [ -z "$NODE" ]
    then
        echo "✅ 已开启"
        return 0
    fi

    case "$NODE" in
        DIRECT|REJECT|GLOBAL|REJECT-DROP|PASS)
            echo "✅ 已开启 · 当前节点: $NODE"
            ;;
        *)
            DELAY=$(mihomo_delay "$NODE")
            if [ -n "$DELAY" ]
            then
                echo "✅ 已开启 · 当前节点: $NODE · 延迟: ${DELAY}ms"
            else
                echo "✅ 已开启 · 当前节点: $NODE · 延迟: 超时"
            fi
            ;;
    esac
}


# /mihomo 使用：平铺列出最底层节点与测速（不出现任何组名）
mihomo_nodes()
{
    local PROXIES NODE TMPDIR NAME DELAY LINE RESULT
    local -a LEAVES ITEMS
    declare -A DELAYS
    local i COUNT TOTAL

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
    if [ -z "$PROXIES" ]
    then
        echo "❌ Mihomo 未开启或无法连接"
        return 0
    fi

    NODE=$(mihomo_current_node_effective "$PROXIES")

    mapfile -t LEAVES < <(mihomo_leaf_nodes_from "$PROXIES")

    # 并行测速全部叶子
    TMPDIR=$(mktemp -d)
    i=0
    for NAME in "${LEAVES[@]}"
    do
        mihomo_delay "$NAME" > "$TMPDIR/$i" &
        i=$((i + 1))
    done
    wait

    i=0
    for NAME in "${LEAVES[@]}"
    do
        DELAY=$(cat "$TMPDIR/$i")
        i=$((i + 1))
        if [ -n "$DELAY" ] && [ "$DELAY" -le "$MIHOMO_DELAY_MAX" ]
        then
            DELAYS["$NAME"]="$DELAY"
        fi
    done
    rm -rf "$TMPDIR"

    ITEMS=()
    for NAME in "${LEAVES[@]}"
    do
        DELAY="${DELAYS[$NAME]:-}"
        [ -n "$DELAY" ] && ITEMS+=("$DELAY $NAME")
    done

    TOTAL=${#ITEMS[@]}
    COUNT=0
    RESULT="🚀 Mihomo 可用节点（$TOTAL 个）

"

    while IFS= read -r LINE
    do
        [ -z "$LINE" ] && continue
        DELAY=${LINE%% *}
        NAME=${LINE#* }
        COUNT=$((COUNT + 1))
        [ "$COUNT" -gt "$MIHOMO_NODE_LIMIT" ] && break

        if [ "$NAME" = "$NODE" ]
        then
            RESULT="$RESULT▶ $NAME — ${DELAY}ms
"
        else
            RESULT="$RESULT• $NAME — ${DELAY}ms
"
        fi
    done < <(printf '%s\n' "${ITEMS[@]}" | sort -n)

    if [ "$COUNT" -eq 0 ]
    then
        RESULT="🚀 Mihomo 可用节点（0 个）

当前没有可用节点
"
    fi
    [ "$TOTAL" -gt "$MIHOMO_NODE_LIMIT" ] && RESULT="$RESULT…共 $TOTAL 个可用节点
"

    echo "$RESULT"
}


# 切换目标组选择（无组名）：
# 1) 真实流量链路中最深的 Selector 组；2) 回退叶子最多的 Selector 组
mihomo_switch_group_from()
{
    local PROXIES="$1" NAME="$2"
    local CHAIN G T

    CHAIN=$(curl -s --max-time 3 "$(mihomo_api)/connections" \
        | jq -r '.connections[]? | select((.chains // []) | length > 1) | .chains | join("\n")' \
        | head -40 | tr -d '\r')

    while IFS= read -r G
    do
        [ -z "$G" ] && continue
        [ "$G" = "$NAME" ] && continue
        T=$(echo "$PROXIES" | jq -r --arg g "$G" '.proxies[$g].type // empty' | tr -d '\r')
        [ "$T" != "Selector" ] && continue
        if [ "$(echo "$PROXIES" | jq -r --arg g "$G" --arg n "$NAME" '((.proxies[$g].all // []) | index($n)) != null' | tr -d '\r')" = "true" ]
        then
            echo "$G"
            return 0
        fi
    done <<< "$CHAIN"

    echo "$PROXIES" | jq -r --arg n "$NAME" --arg t "$MIHOMO_GROUP_TYPES" '
        . as $p |
        [ $p.proxies | to_entries[]
          | select(.key != "GLOBAL" and .key != "DIRECT" and .key != "REJECT" and .key != "REJECT-DROP")
          | select(.value.type == "Selector" and ((.value.all // []) | index($n)))
          | { key: .key, leaves: ([.value.all[]? as $m | select(($p.proxies[$m].type // "") as $ty | ($t | split("|")) | index($ty) | not) | $m] | length) } ]
        | sort_by(-.leaves) | .[0].key // empty' | tr -d '\r'
}


# 自动组检测（仅自动类组包含该节点，无法手动切换）
mihomo_auto_group_from()
{
    local PROXIES="$1" NAME="$2"

    echo "$PROXIES" | jq -r --arg n "$NAME" '
        [ .proxies | to_entries[]
          | select(.key != "GLOBAL" and .key != "DIRECT" and .key != "REJECT" and .key != "REJECT-DROP")
          | select((.value.type == "URLTest" or .value.type == "Fallback" or .value.type == "LoadBalance" or .value.type == "Relay")
            and ((.value.all // []) | index($n)))
          | .key ] | .[0] // empty' | tr -d '\r'
}


# 主组联动：若主组包含目标组，把主组切过去，保证切换真正生效
mihomo_route_main_to()
{
    local PROXIES="$1" GROUP="$2"
    local MAIN MAIN_TYPE JSON

    MAIN=$(mihomo_main_group_from "$PROXIES")
    [ -z "$MAIN" ] && return 0
    [ "$MAIN" = "$GROUP" ] && return 0

    MAIN_TYPE=$(echo "$PROXIES" | jq -r --arg m "$MAIN" '.proxies[$m].type // empty' | tr -d '\r')
    [ "$MAIN_TYPE" != "Selector" ] && return 0

    [ "$(echo "$PROXIES" | jq -r --arg m "$MAIN" --arg g "$GROUP" '((.proxies[$m].all // []) | index($g)) != null' | tr -d '\r')" != "true" ] && return 0

    JSON=$(jq -cn --arg n "$GROUP" '{name:$n}' | tr -d '\r')
    printf '%s' "$JSON" | curl -s -o /dev/null --max-time 3 \
        -X PUT \
        -H "Content-Type: application/json" \
        --data-binary @- \
        "$(mihomo_api)/proxies/$(mihomo_uri "$MAIN")" || true
}


# /switch 使用：切换节点并反馈新节点延迟
mihomo_switch()
{
    local NAME="$1"
    local PROXIES GROUP TYPE AUTO API_URL CODE DELAY JSON MATCHES COUNT CANDIDATE

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
    if [ -z "$PROXIES" ]
    then
        echo "❌ Mihomo 未开启，无法切换节点"
        return 0
    fi

    GROUP=$(mihomo_switch_group_from "$PROXIES" "$NAME")

    # 精确匹配失败时模糊匹配：节点名可能丢失了国旗前缀等
    if [ -z "$GROUP" ]
    then
        MATCHES=$(echo "$PROXIES" | jq -r --arg n "$NAME" '
            [ .proxies | to_entries[]
              | select(.value.type as $t | ["Selector","URLTest","Fallback","LoadBalance","Relay","Direct","Reject","RejectDrop","Compatible","Pass","GLOBAL"] | index($t) | not)
              | select((.key | ascii_downcase) | index(($n | ascii_downcase)))
              | .key ]
            | unique[]' | tr -d '\r')

        COUNT=$(printf '%s\n' "$MATCHES" | sed '/^$/d' | wc -l)
        if [ "$COUNT" -eq 1 ]
        then
            NAME=$(printf '%s\n' "$MATCHES" | head -1)
            GROUP=$(mihomo_switch_group_from "$PROXIES" "$NAME")
        elif [ "$COUNT" -gt 1 ]
        then
            CANDIDATE=$(printf '%s\n' "$MATCHES" | head -1)
            echo "❓ 找到多个匹配节点，请发送完整节点名：

$(printf '%s\n' "$MATCHES" | head -10)

例如:
/switch $CANDIDATE"
            return 0
        fi
    fi

    if [ -z "$GROUP" ]
    then
        AUTO=$(mihomo_auto_group_from "$PROXIES" "$NAME")
        if [ -n "$AUTO" ]
        then
            echo "❌ 该节点位于自动选择组，无法手动切换"
        else
            echo "❌ 未找到该节点，请从 /mihomo 复制完整节点名（含国旗前缀）"
        fi
        return 0
    fi

    API_URL=$(mihomo_api)
    JSON=$(jq -cn --arg n "$NAME" '{name:$n}' | tr -d '\r')
    CODE=$(printf '%s' "$JSON" | curl -s -o /dev/null -w '%{http_code}' --max-time 3 \
        -X PUT \
        -H "Content-Type: application/json" \
        --data-binary @- \
        "$API_URL/proxies/$(mihomo_uri "$GROUP")")

    if [ "$CODE" = "204" ] || [ "$CODE" = "200" ]
    then
        # 主组联动，确保切换真正生效
        mihomo_route_main_to "$PROXIES" "$GROUP"

        DELAY=$(mihomo_delay "$NAME")
        if [ -n "$DELAY" ]
        then
            echo "✅ 已切换至: $NAME
📶 当前延迟: ${DELAY}ms"
        else
            echo "✅ 已切换至: $NAME
📶 当前延迟: 超时"
        fi
    else
        echo "❌ 切换失败（HTTP $CODE）：请确认节点名称是否正确"
    fi
}
