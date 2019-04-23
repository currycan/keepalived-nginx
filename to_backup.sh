#!/bin/bash
Date=$(date +%F" "%T)
HOST_NAME=$(hostname)
IP=$(ip addr | grep 192 | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')
Mail="${EMAIL_ADDR}"
echo "$Date：主机$HOST_NAME切换为BACKUP，IP：$IP，请确认Nginx服务运行状态。"|mail -s "主机$HOST_NAME切换为BACKUP警告" $Mail
