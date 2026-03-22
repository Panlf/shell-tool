#!/bin/bash
LOG_FILE="/data/log/tengine/access.log"
STAT_MINUTES=10
TAIL_LINES=100000

while true; do
echo "========================================"
echo "统计时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "区间: 最近 ${STAT_MINUTES} 分钟（跨时/跨日/跨月自动兼容）"
echo "========================================"

# 生成最近10分钟、完全匹配 nginx 格式的前缀
PATTERN=""
for((i=0;i<STAT_MINUTES;i++));do
    P=$(date -d "-$i min" +"%d/%b/%Y:%H:%M")
    PATTERN+="\[$P|"
done
PATTERN=${PATTERN%|}

# ========== 新增：打印PATTERN字符串 ==========
echo "【调试】生成的匹配规则PATTERN：$PATTERN"
# ============================================

tail -n $TAIL_LINES "$LOG_FILE" \
| grep -E "$PATTERN" \
| awk '{ip[$1]++;all++}
END{
print "总请求数：",all
print "-----------------------------"
for(x in ip) printf "%8d %s\n",ip[x],x
}'|sort -nr

echo;echo "等待10分钟..."
sleep 600
done