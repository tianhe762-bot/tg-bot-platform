#!/bin/bash
# ============================================================
# Mihomo Module
# ============================================================


mihomo_status()
{


API_URL="${MIHOMO_API:-http://127.0.0.1:9999}"


RESULT=$(curl -s \
--max-time 3 \
"$API_URL/version")



if [ -z "$RESULT" ]

then

echo "❌ Mihomo 无响应"

else

echo "🚀 Mihomo"

echo

echo "$RESULT"

fi


}
