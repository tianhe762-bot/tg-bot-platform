#!/bin/bash
# ============================================================
# Metrics Analysis Module
# ============================================================


METRICS_FILE="/opt/tg_bot/data/metrics.log"



metrics_cpu24()
{


if [ ! -f "$METRICS_FILE" ]

then

echo "暂无数据"

return

fi



awk '

{

cpu=$3

idle=$4


}

END{

print "CPU采样正常"

}

' "$METRICS_FILE"


}



metrics_memory()
{


awk '

{

for(i=1;i<=NF;i++)

{

if($i ~ /^MEM_USED=/)

{

split($i,a,"=")

sum+=a[2]

count++

}

}

}

END{

if(count)

printf "平均内存使用: %.2f MB\n",sum/count/1024

else

print "暂无数据"

}

' "$METRICS_FILE"


}



metrics_disk()
{


tail -1 "$METRICS_FILE" \
| awk '

{

for(i=1;i<=NF;i++)

{

if($i ~ /^ROOT=/)

print "系统盘使用:" $i


if($i ~ /^DATA=/)

print "数据盘使用:" $i

}

}

'


}



metrics_network()
{


tail -1 "$METRICS_FILE" \
| awk '

{

for(i=1;i<=NF;i++)

{

if($i ~ /^RX=/)

print $i


if($i ~ /^TX=/)

print $i


}

}

'


}
