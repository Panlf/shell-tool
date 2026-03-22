#!/bin/bash

# ===================== 配置项 =====================
# 日志文件路径
LOG_FILE="/data/log/tengine/access.log"
# 统计时间间隔（秒），10分钟 = 600秒
INTERVAL=600
# 临时文件路径（用于存储上一次统计的文件位置）
OFFSET_FILE="/tmp/nginx_ip_monitor.offset"
# ==================== 配置项结束 ====================

# 检查日志文件是否存在
if [ ! -f "$LOG_FILE" ]; then
    echo "错误：日志文件 $LOG_FILE 不存在！"
    exit 1
fi

# 检查是否有偏移量文件，没有则创建（初始偏移量为0）
if [ ! -f "$OFFSET_FILE" ]; then
    echo "0" > "$OFFSET_FILE"
fi

# 循环执行统计
while true; do
    # 获取当前时间（用于输出）
    CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    echo "========================================"
    echo "统计时间：$CURRENT_TIME"
    echo "========================================"

    # 读取上一次的文件偏移量
    LAST_OFFSET=$(cat "$OFFSET_FILE")
    # 获取当前日志文件的大小（字节）
    CURRENT_SIZE=$(stat -c %s "$LOG_FILE")

    # 如果日志文件被切割/清空，重置偏移量
    if [ "$CURRENT_SIZE" -lt "$LAST_OFFSET" ]; then
        echo "检测到日志文件已被切割/清空，重置统计起点"
        LAST_OFFSET=0
    fi

    # 统计新增日志中的IP访问次数
    # 使用tail -c +$LAST_OFFSET 从指定偏移量开始读取新增内容
    # awk '{print $1}' 提取第一列（IP地址）
    # sort | uniq -c 统计每个IP的出现次数
    # sort -nr 按访问次数降序排列
    echo "IP访问次数统计（按访问量降序）："
    tail -c +"$LAST_OFFSET" "$LOG_FILE" 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr

    # 保存当前文件偏移量（下次统计起点）
    echo "$CURRENT_SIZE" > "$OFFSET_FILE"

    echo -e "\n等待 $((INTERVAL/60)) 分钟后进行下一次统计...\n"
    sleep "$INTERVAL"
done