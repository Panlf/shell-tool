#!/bin/bash
# ===================== 配置项 =====================
LOG_FILE="/data/log/nginx/access.log"
INTERVAL=600  # 调整为10分钟（600秒）
OFFSET_FILE="/data/tmp/nginx_ip_monitor.offset"
# 首次运行时只读取最后N行（建议设为10000，可根据服务器性能调整）
FIRST_RUN_LINES=10000
# ==================== 配置项结束 ====================

# 确保偏移量文件目录存在（避免/data/tmp不存在导致报错）
mkdir -p /data/tmp

# 增加调试输出
echo "【调试】脚本启动，日志文件：$LOG_FILE"
echo "【调试】日志文件是否存在：$(test -f $LOG_FILE && echo 是 || echo 否)"
echo "【调试】当前用户：$(whoami)"
echo "【调试】日志文件权限：$(ls -l $LOG_FILE 2>&1)"

if [ ! -f "$LOG_FILE" ]; then
    echo "错误：日志文件 $LOG_FILE 不存在！"
    exit 1
fi

# 首次运行处理（偏移量文件不存在或偏移量为0）
if [ ! -f "$OFFSET_FILE" ] || [ "$(cat $OFFSET_FILE 2>/dev/null)" -eq 0 ]; then
    echo "【调试】首次运行，仅读取日志最后 $FIRST_RUN_LINES 行（避免加载超大文件）"
    # 获取日志文件总行数（快速方式，避免wc -l遍历整个文件）
    # 直接读取最后N行，并记录当前文件大小作为下次偏移量
    CURRENT_SIZE=$(stat -c %s "$LOG_FILE")
    echo "$CURRENT_SIZE" > "$OFFSET_FILE"

    # 读取最后N行并统计
    NEW_LOGS=$(tail -n $FIRST_RUN_LINES "$LOG_FILE" 2>/dev/null)
else
    # 非首次运行：按偏移量读取新增内容
    LAST_OFFSET=$(cat "$OFFSET_FILE")
    CURRENT_SIZE=$(stat -c %s "$LOG_FILE")

    # 如果日志文件被切割/清空，重置偏移量（仅读取最后N行）
    if [ "$CURRENT_SIZE" -lt "$LAST_OFFSET" ]; then
        echo "检测到日志文件已被切割/清空，重置统计起点（读取最后 $FIRST_RUN_LINES 行）"
        NEW_LOGS=$(tail -n $FIRST_RUN_LINES "$LOG_FILE" 2>/dev/null)
        CURRENT_SIZE=$(stat -c %s "$LOG_FILE")
    else
        # 增量读取（只读新增内容，效率高）
        echo "【调试】上一次偏移量：$LAST_OFFSET，当前文件大小：$CURRENT_SIZE"
        echo "【调试】开始读取新增日志（从偏移量 $LAST_OFFSET 开始）"
        NEW_LOGS=$(tail -c +"$LAST_OFFSET" "$LOG_FILE" 2>/dev/null)
    fi
fi

# 统计并输出结果
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "========================================"
echo "统计时间：$CURRENT_TIME"
echo "========================================"

TOTAL_REQUESTS=$(echo "$NEW_LOGS" | wc -l)
echo "本次统计周期总请求量：$TOTAL_REQUESTS"

if [ "$TOTAL_REQUESTS" -eq 0 ]; then
    echo "提示：本次统计周期内无新增访问日志"
else
    echo "----------------------------------------"
    echo "IP访问次数统计（按访问量降序）："
    # 用管道分步处理，避免一次性加载所有内容到内存
    echo "$NEW_LOGS" | awk '{print $1}' | sort | uniq -c | sort -nr | head -50  # 只显示前50个IP
fi

# 保存当前偏移量（下次统计起点）
echo "$CURRENT_SIZE" > "$OFFSET_FILE"

# 循环执行（后续统计都是增量）
while true; do
    echo -e "\n等待 $((INTERVAL/60)) 分钟后进行下一次统计...\n"
    sleep "$INTERVAL"

    # 增量读取新增日志
    LAST_OFFSET=$(cat "$OFFSET_FILE")
    CURRENT_SIZE=$(stat -c %s "$LOG_FILE")

    if [ "$CURRENT_SIZE" -lt "$LAST_OFFSET" ]; then
        echo "检测到日志文件已被切割/清空，重置统计起点（读取最后 $FIRST_RUN_LINES 行）"
        NEW_LOGS=$(tail -n $FIRST_RUN_LINES "$LOG_FILE" 2>/dev/null)
        CURRENT_SIZE=$(stat -c %s "$LOG_FILE")
    else
        NEW_LOGS=$(tail -c +"$LAST_OFFSET" "$LOG_FILE" 2>/dev/null)
    fi

    # 统计输出
    CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    echo "========================================"
    echo "统计时间：$CURRENT_TIME"
    echo "========================================"
    TOTAL_REQUESTS=$(echo "$NEW_LOGS" | wc -l)
    echo "本次统计周期总请求量：$TOTAL_REQUESTS"

    if [ "$TOTAL_REQUESTS" -gt 0 ]; then
        echo "----------------------------------------"
        echo "IP访问次数统计（按访问量降序）："
        echo "$NEW_LOGS" | awk '{print $1}' | sort | uniq -c | sort -nr | head -20
    else
        echo "提示：本次统计周期内无新增访问日志"
    fi

    echo "$CURRENT_SIZE" > "$OFFSET_FILE"
done