#!/bin/bash
# ============================================================
# Mihomo Module
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


# 从 /proxies JSON 中选取主节点组：
# 排除内置组，优先匹配常见组名，其次第一个 Selector，再第一个 URLTest
mihomo_pick_group_from()
{
    local PROXIES="$1"

    echo "$PROXIES" | jq -r '
        [ .proxies | to_entries[]
          | select(.value.type == "Selector" or .value.type == "URLTest")
          | select(.key != "GLOBAL" and .key != "DIRECT" and .key != "REJECT" and .key != "REJECT-DROP")
          | { key: .key, type: .value.type } ] as $g
        | ( $g | map(select(.key | test("proxy|节点选择|选择|手动选择|global|全局"; "i"))) | .[0].key )
        // ( $g | map(select(.type == "Selector")) | .[0].key )
        // ( $g | map(select(.type == "URLTest")) | .[0].key )
        // empty' | tr -d '\r'
}


mihomo_pick_group()
{
    mihomo_pick_group_from "$(curl -s --max-time 3 "$(mihomo_api)/proxies")"
}


# 获取主节点组类型（Selector=可手动切换）
mihomo_group_type_from()
{
    local PROXIES="$1" GROUP="$2"

    echo "$PROXIES" | jq -r --arg g "$GROUP" '.proxies[$g].type // empty' | tr -d '\r'
}


# 获取当前选中节点
mihomo_current_node_from()
{
    local PROXIES="$1" GROUP="$2"

    echo "$PROXIES" | jq -r --arg g "$GROUP" '.proxies[$g].now // empty' | tr -d '\r'
}


mihomo_current_node()
{
    mihomo_current_node_from "$(curl -s --max-time 3 "$(mihomo_api)/proxies")" "$1"
}


# 递归解析到最底层节点（如 子组 → 叶子节点）
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


mihomo_resolve_leaf()
{
    mihomo_resolve_leaf_from "$(curl -s --max-time 3 "$(mihomo_api)/proxies")" "$1"
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
    local PROXIES GROUP NODE DELAY

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
    [ -z "$PROXIES" ] && { echo "❌ 未开启"; return 0; }

    GROUP=$(mihomo_pick_group_from "$PROXIES")
    [ -z "$GROUP" ] && { echo "❌ 未开启"; return 0; }

    NODE=$(mihomo_current_node_from "$PROXIES" "$GROUP")
    NODE=$(mihomo_resolve_leaf_from "$PROXIES" "$NODE")

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


# 沿主组 now 链找到当前手动选择组（最后的 Selector 组）
mihomo_switch_target_from()
{
    local PROXIES="$1" NAME="$2" TYPE NOW TARGET
    local -i DEPTH=0

    [ -z "$NAME" ] && return 0

    while [ "$DEPTH" -lt 10 ]
    do
        TYPE=$(echo "$PROXIES" | jq -r --arg n "$NAME" '.proxies[$n].type // empty' | tr -d '\r')
        case "$TYPE" in
            Selector)
                TARGET="$NAME"
                ;;
            URLTest|Fallback|LoadBalance|Relay|Compatible)
                ;;
            *)
                break
                ;;
        esac
        NOW=$(echo "$PROXIES" | jq -r --arg n "$NAME" '.proxies[$n].now // empty' | tr -d '\r')
        [ -z "$NOW" ] && break
        NAME="$NOW"
        DEPTH=$((DEPTH + 1))
    done

    echo "$TARGET"
}


# /mihomo 使用：按区域组展示节点测速（只显示连通且延迟 ≤800ms 的节点）
mihomo_nodes()
{
    local PROXIES GROUP NODE TMPDIR NAME DELAY LINE RESULT SECTIONS SECTION
    local -a PROXY_GROUPS LEAVES GNODES ITEMS
    declare -A DELAYS SHOWN
    local i COUNT TOTAL

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
    if [ -z "$PROXIES" ]
    then
        echo "❌ Mihomo 未开启或无法连接"
        return 0
    fi

    GROUP=$(mihomo_pick_group_from "$PROXIES")
    NODE=$(mihomo_current_node_from "$PROXIES" "$GROUP")
    NODE=$(mihomo_resolve_leaf_from "$PROXIES" "$NODE")

    # 展示组：名称含“节点”的组（如 香港节点/美国节点），排除内置
    mapfile -t PROXY_GROUPS < <(echo "$PROXIES" | jq -r '
        [ .proxies | to_entries[]
          | select(.value.type == "Selector" or .value.type == "URLTest" or .value.type == "Fallback")
          | select(.key != "GLOBAL" and .key != "DIRECT" and .key != "REJECT" and .key != "REJECT-DROP")
          | select(.key | test("节点"))
          | .key ]
        | unique[]' | tr -d '\r')

    # 全部叶子节点（去重）
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

    TOTAL=0
    SECTIONS=""

    # 区域组区块
    for GROUP in "${PROXY_GROUPS[@]}"
    do
        mapfile -t GNODES < <(echo "$PROXIES" | jq -r --arg g "$GROUP" --arg t "$MIHOMO_GROUP_TYPES" '
            [ .proxies[$g].all[]? as $n
              | select((.proxies[$n].type // "") as $ty | ($t | split("|")) | index($ty) | not)
              | $n ]
            | unique[]' | tr -d '\r')

        ITEMS=()
        for NAME in "${GNODES[@]}"
        do
            DELAY="${DELAYS[$NAME]:-}"
            [ -n "$DELAY" ] && ITEMS+=("$DELAY $NAME")
        done
        [ "${#ITEMS[@]}" -eq 0 ] && continue

        SECTION="$GROUP:
"
        COUNT=0
        while IFS= read -r LINE
        do
            [ -z "$LINE" ] && continue
            DELAY=${LINE%% *}
            NAME=${LINE#* }
            COUNT=$((COUNT + 1))
            [ "$COUNT" -gt "$MIHOMO_NODE_LIMIT" ] && break
            SHOWN["$NAME"]=1
            TOTAL=$((TOTAL + 1))
            if [ "$NAME" = "$NODE" ]
            then
                SECTION="$SECTION▶ $NAME — ${DELAY}ms
"
            else
                SECTION="$SECTION• $NAME — ${DELAY}ms
"
            fi
        done < <(printf '%s\n' "${ITEMS[@]}" | sort -n)

        SECTIONS="$SECTIONS
$SECTION"
    done

    # 未归入区域组的可用节点
    ITEMS=()
    for NAME in "${LEAVES[@]}"
    do
        [ -n "${SHOWN[$NAME]:-}" ] && continue
        DELAY="${DELAYS[$NAME]:-}"
        [ -n "$DELAY" ] && ITEMS+=("$DELAY $NAME")
    done
    if [ "${#ITEMS[@]}" -gt 0 ]
    then
        SECTION="其他节点:
"
        while IFS= read -r LINE
        do
            [ -z "$LINE" ] && continue
            DELAY=${LINE%% *}
            NAME=${LINE#* }
            SHOWN["$NAME"]=1
            TOTAL=$((TOTAL + 1))
            if [ "$NAME" = "$NODE" ]
            then
                SECTION="$SECTION▶ $NAME — ${DELAY}ms
"
            else
                SECTION="$SECTION• $NAME — ${DELAY}ms
"
            fi
        done < <(printf '%s\n' "${ITEMS[@]}" | sort -n)
        SECTIONS="$SECTIONS
$SECTION"
    fi

    if [ "$TOTAL" -eq 0 ]
    then
        echo "🚀 Mihomo 节点测速

当前没有可用节点"
        return 0
    fi

    echo "🚀 Mihomo 节点测速（可用 $TOTAL 个）
$SECTIONS"
}


# /switch 使用：切换节点并反馈新节点延迟
mihomo_switch()
{
    local NAME="$1"
    local PROXIES MAIN CURRENT GROUP TYPE AUTO API_URL CODE DELAY JSON

    PROXIES=$(curl -s --max-time 3 "$(mihomo_api)/proxies")
    if [ -z "$PROXIES" ]
    then
        echo "❌ Mihomo 未开启，无法切换节点"
        return 0
    fi

    MAIN=$(mihomo_pick_group_from "$PROXIES")
    CURRENT=$(mihomo_switch_target_from "$PROXIES" "$MAIN")

    # 优先切换当前手动选择组，其次找第一个包含该节点的非内置 Selector 组
    GROUP=$(echo "$PROXIES" | jq -r --arg n "$NAME" --arg c "$CURRENT" '
        [ ( if $c != "" and (.proxies[$c].type == "Selector") and ((.proxies[$c].all // []) | index($n)) then $c else empty end ),
          ( .proxies | to_entries[]
            | select(.key != "GLOBAL" and .key != "DIRECT" and .key != "REJECT" and .key != "REJECT-DROP")
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

    TYPE=$(mihomo_group_type_from "$PROXIES" "$GROUP")
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
