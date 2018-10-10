#!/bin/bash
# description:
# 定时查看nginx是否存在，如果不存在则启动nginx
# 如果启动失败，则停止keepalived

status=$(ps -C nginx --no-heading | wc -l)
if [ "${status}" = "0" ]; then
    service nginx start
    sleep 2
    status2=$(ps -C nginx --no-heading | wc -l)
    if [ "${status2}" = "0"  ]; then
        service keepalived stop
    fi
fi
