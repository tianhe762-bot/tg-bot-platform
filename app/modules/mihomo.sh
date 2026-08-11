#!/bin/bash
# ============================================================
# Mihomo Module
# ============================================================


# 测速地址与过滤条件
MIHOMO_TEST_URL="https://www.gstatic.com/generate_204"
MIHOMO_DELAY_MAX=800
MIHOMO_DELAY_TIMEOUT=3000
MIHOMO_NODE_LIMIT=80


mihomo_api()
{
    echo "${MIHOMO_API:-http://127.0.0.1:9999}"
}


# URL 编码（兼容中文/空格节点名）
mihomo_uri()
{
    jq -rn --arg v "$1" '$v|@uri' | tr -d '\r'
}


# 获取主节点组：
# 优先匹配常见组名，其次第一个 Selector，再第一个 URLTest
mihomo_pick_group()
{
    local PROXIES GROUP

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
    [ -z "$PROXIES" ] && return 1

    GROUP=$(echo "$PROXIES" | jq -r '
        [ .proxies | to_entries[]
          | select(.value.type == "Selector" or .value.type == "URLTest")
          | { key: .key, type: .value.type } ] as $g
        | ( $g | map(select(.key | test("proxy|节点选择|选择|手动选择|global|全局"; "i"))) | .[0].key )
        // ( $g | map(select(.type == "Selector")) | .[0].key )
        // ( $g | map(select(.type == "URLTest")) | .[0].key )
        // empty' | tr -d '\r')

    [ -z "$GROUP" ] && return 1
    echo "$GROUP"
}


# 获取主节点组类型（Selector=可手动切换）
mihomo_group_type()
{
    local GROUP="$1"

    curl -s --max-time 3 "$(mihomo_api)/proxies" \
    | jq -r --arg g "$GROUP" '.proxies[$g].type // empty' | tr -d '\r'
}


# 获取当前选中节点
mihomo_current_node()
{
    local GROUP="$1"

    curl -s --max-time 3 "$(mihomo_api)/proxies" \
    | jq -r --arg g "$GROUP" '.proxies[$g].now // empty' | tr -d '\r'
}


# 递归解析到最底层节点（如 子组“美国” → 叶子“美国-洛杉矶01”）
mihomo_resolve_leaf()
{
    local NAME="$1" PROXIES TYPE NOW
    local -i DEPTH=0

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
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


# 获取最底层节点（过滤组/内置类型并去重）
mihomo_leaf_nodes()
{
    curl -s --max-time 3 "$(mihomo_api)/proxies" \
    | jq -r '
        [ .proxies | to_entries[]
          | select(.value.type as $t
            | ["Selector","URLTest","Fallback","LoadBalance","Relay","Direct","Reject","Compatible","Pass","GLOBAL"]
              | index($t) | not)
          | .key ]
        | unique[]' | tr -d '\r'
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


# /status 使用：汇报当前节点与延迟
mihomo_connected()
{
    local GROUP NODE DELAY

    GROUP=$(mihomo_pick_group) || { echo "❌ 未开启"; return 0; }
    NODE=$(mihomo_current_node "$GROUP")
    NODE=$(mihomo_resolve_leaf "$NODE")

    if [ -z "$NODE" ]
    then
        echo "✅ 已开启 · 节点组: $GROUP"
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


# /mihomo 使用：并行测速最底层节点，只显示连通且延迟 ≤800ms 的节点
mihomo_nodes()
{
    local GROUP NODE TMPDIR NODES NAME DELAY LINE RESULT
    local -a ITEMS
    local i COUNT TOTAL

    GROUP=$(mihomo_pick_group) || { echo "❌ Mihomo 未开启或无法连接"; return 0; }
    NODE=$(mihomo_current_node "$GROUP")
    NODE=$(mihomo_resolve_leaf "$NODE")

    TMPDIR=$(mktemp -d)

    mapfile -t NODES < <(mihomo_leaf_nodes)

    i=0
    for NAME in "${NODES[@]}"
    do
        mihomo_delay "$NAME" > "$TMPDIR/$i" &
        i=$((i + 1))
    done
    wait

    ITEMS=()
    i=0
    for NAME in "${NODES[@]}"
    do
        DELAY=$(cat "$TMPDIR/$i")
        i=$((i + 1))
        if [ -n "$DELAY" ] && [ "$DELAY" -le "$MIHOMO_DELAY_MAX" ]
        then
            ITEMS+=("$DELAY $NAME")
        fi
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
        RESULT="$RESULT当前没有可用节点
"
    fi
    [ "$TOTAL" -gt "$MIHOMO_NODE_LIMIT" ] && RESULT="$RESULT…共 $TOTAL 个可用节点
"

    rm -rf "$TMPDIR"
    echo "$RESULT"
}


# /switch 使用：切换节点并反馈新节点延迟
mihomo_switch()
{
    local NAME="$1"
    local PROXIES MAIN GROUP TYPE AUTO API_URL CODE DELAY JSON

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
    if [ -z "$PROXIES" ]
    then
        echo "❌ Mihomo 未开启，无法切换节点"
        return 0
    fi

    MAIN=$(mihomo_pick_group) || MAIN=""

    # 优先切换主节点组，其次找第一个包含该节点的 Selector 组
    GROUP=$(echo "$PROXIES" | jq -r --arg n "$NAME" --arg m "$MAIN" '
        [ ( if $m != "" and (.proxies[$m].type == "Selector") and ((.proxies[$m].all // []) | index($n)) then $m else empty end ),
          ( .proxies | to_entries[]
            | select(.value.type == "Selector" and ((.value.all // []) | index($n)))
            | .key ) ]
        | .[0] // empty' | tr -d '\r')

    if [ -z "$GROUP" ]
    then
        AUTO=$(echo "$PROXIES" | jq -r --arg n "$NAME" '
            [ .proxies | to_entries[]
              | select((( .value.all // [] ) | index($n)))
              | .key ] | .[0] // empty' | tr -d '\r')
        if [ -n "$AUTO" ]
        then
            echo "❌ 该节点位于自动选择组，无法手动切换"
        else
            echo "❌ 未找到该节点，请确认名称是否正确"
        fi
        return 0
    fi

    TYPE=$(echo "$PROXIES" | jq -r --arg g "$GROUP" '.proxies[$g].type // empty' | tr -d '\r')
    if [ "$TYPE" != "Selector" ]
    then
        echo "❌ 当前节点组为自动选择（$TYPE），无法手动切换"
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
