#!/bin/bash

# Freqtrade机器人启动脚本
# 参数: BOT_ID USER_ID CONFIG_PATH

BOT_ID=$1
USER_ID=$2
CONFIG_PATH=${3:-"/freqtrade/user_data/config_${BOT_ID}.json"}
LOG_PATH="/freqtrade/user_data/logs/bot_${BOT_ID}.log"
DB_PATH="/freqtrade/user_data/tradesv3_${BOT_ID}.sqlite"

# 确保目录存在
mkdir -p /freqtrade/user_data/logs
mkdir -p /freqtrade/user_data/strategies
mkdir -p /freqtrade/user_data/data

# 检查配置文件是否存在
if [ ! -f "$CONFIG_PATH" ]; then
    echo "错误: 配置文件不存在: $CONFIG_PATH"
    exit 1
fi

# 验证配置文件格式
if ! python3 -m json.tool "$CONFIG_PATH" > /dev/null 2>&1; then
    echo "错误: 配置文件格式无效: $CONFIG_PATH"
    exit 1
fi

echo "启动Freqtrade机器人..."
echo "机器人ID: $BOT_ID"
echo "用户ID: $USER_ID"
echo "配置文件: $CONFIG_PATH"
echo "日志文件: $LOG_PATH"
echo "数据库文件: $DB_PATH"

# 启动Freqtrade
exec freqtrade trade \
    --config "$CONFIG_PATH" \
    --logfile "$LOG_PATH" \
    --db-url "sqlite:///$DB_PATH" \
    --strategy SampleStrategy
