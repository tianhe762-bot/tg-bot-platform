#!/bin/bash
# ============================================================
# Net Helper: proxy first (TG_PROXY), direct fallback
# ============================================================

# 通用请求：参数原样传给 curl；代理优先，失败自动直连
net_curl()
{
    local args=("$@")
    local rc
    if [ -n "${TG_PROXY:-}" ]; then
        curl "${args[@]}" --proxy "$TG_PROXY" --connect-timeout 8 2>/dev/null
        rc=$?
        if [ "$rc" -eq 0 ]; then
            return 0
        fi
    fi
    curl "${args[@]}"
}

# 多通道获取最新 Release 标签；成功输出标签并设置 NET_LATEST_SRC
# 失败输出空并设置 NET_LATEST_ERR（原因）
net_latest_tag()
{
    local REPO="$1"
    local URL TAG BODY CODE
    NET_LATEST_SRC=""
    NET_LATEST_ERR=""

    # 1) github.com releases/latest 重定向
    URL=$(net_curl -s -o /dev/null -w '%{url_effective}' -L --max-time 20 \
        "https://github.com/${REPO}/releases/latest" 2>/dev/null)
    case "$URL" in
        */tag/v*)
            TAG="${URL##*/tag/}"
            if [ -n "$TAG" ]; then
                NET_LATEST_SRC="github.com 重定向"
                printf '%s' "$TAG"
                return 0
            fi
            ;;
    esac
    NET_LATEST_ERR="github.com 重定向失败（URL=${URL:-空}）"

    # 2) raw VERSION
    BODY=$(net_curl -fsSL --max-time 15 \
        "https://raw.githubusercontent.com/${REPO}/main/VERSION" 2>/dev/null)
    TAG=$(printf '%s' "$BODY" | tr -d ' \r\n')
    if [ -n "$TAG" ]; then
        NET_LATEST_SRC="raw.githubusercontent.com"
        case "$TAG" in v*) printf '%s' "$TAG" ;; *) printf 'v%s' "$TAG" ;; esac
        return 0
    fi
    NET_LATEST_ERR="raw VERSION 获取失败；${NET_LATEST_ERR}"

    # 3) 自定义地址
    if [ -n "${TG_VERSION_URL:-}" ]; then
        BODY=$(net_curl -fsSL --max-time 15 "$TG_VERSION_URL" 2>/dev/null)
        TAG=$(printf '%s' "$BODY" | tr -d ' \r\n')
        if [ -n "$TAG" ]; then
            NET_LATEST_SRC="自定义地址"
            case "$TAG" in v*) printf '%s' "$TAG" ;; *) printf 'v%s' "$TAG" ;; esac
            return 0
        fi
    fi
    NET_LATEST_ERR="自定义地址失败；${NET_LATEST_ERR}"

    # 4) api.github.com 兜底
    BODY=$(net_curl -s -w '\n%{http_code}' --max-time 15 \
        "https://api.github.com/repos/${REPO}/releases/latest")
    CODE=$(printf '%s' "$BODY" | tail -n1)
    BODY=$(printf '%s' "$BODY" | sed '$d')
    TAG=$(printf '%s' "$BODY" | jq -r '.tag_name // empty' 2>/dev/null)
    if [ -n "$TAG" ]; then
        NET_LATEST_SRC="api.github.com"
        printf '%s' "$TAG"
        return 0
    fi
    if [ "$CODE" = "403" ]; then
        NET_LATEST_ERR="api.github.com 返回 HTTP 403（临时限流/拒绝）；${NET_LATEST_ERR}"
    else
        NET_LATEST_ERR="api.github.com 返回 HTTP ${CODE:-未知}；${NET_LATEST_ERR}"
    fi
    return 1
}

# 版本比较：0=相等, 1=左>右, 2=左<右（按 主.次.补丁 数字比较）
version_compare()
{
    local a b i
    a=(${1//./ })
    b=(${2//./ })
    for i in 0 1 2; do
        if [ "${a[$i]:-0}" -gt "${b[$i]:-0}" ]; then return 1; fi
        if [ "${a[$i]:-0}" -lt "${b[$i]:-0}" ]; then return 2; fi
    done
    return 0
}
