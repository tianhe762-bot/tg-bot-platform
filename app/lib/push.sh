#!/bin/bash
# ============================================================
# Push Fallback: WeCom group robot / ServerChan
# Used when Telegram is unreachable
# ============================================================

send_fallback()
{
    local TEXT="$1"
    local JSON RESP

    if [ -n "${WECOM_WEBHOOK:-}" ]; then
        JSON=$(printf '%s' "$TEXT" | jq -Rs '{"msgtype":"text","text":{"content":.}}')
        RESP=$(curl -s --max-time 10 -X POST "$WECOM_WEBHOOK" \
            -H 'Content-Type: application/json' \
            -d "$JSON" 2>/dev/null)
        if printf '%s' "$RESP" | grep -q '"errcode":0'; then
            logger -t push_fallback "WeCom OK"
            echo "FALLBACK_WECOM_OK"
            return 0
        fi
        logger -t push_fallback "WeCom failed: $RESP"
    fi

    if [ -n "${SCT_KEY:-}" ]; then
        RESP=$(curl -s --max-time 10 "https://sctapi.ftqq.com/${SCT_KEY}.send" \
            --data-urlencode "title=服务器报警" \
            --data-urlencode "desp=$TEXT" 2>/dev/null)
        if printf '%s' "$RESP" | grep -q '"code":0'; then
            logger -t push_fallback "ServerChan OK"
            echo "FALLBACK_SCT_OK"
            return 0
        fi
        logger -t push_fallback "ServerChan failed: $RESP"
    fi

    echo "FALLBACK_FAIL"
    return 1
}
