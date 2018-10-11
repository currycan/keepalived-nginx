#!/bin/bash

sh_ver=1.0.0

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"

set -e

server() {
    yum install -y ntp
    IP_NET=`ip route|awk '/default/ { print $5 }'`
    IP_MASK=$(ip route | grep $IP_NET | grep kernel | awk '{print $1}'| cut -d"/" -f1)
    sed -i "9i restrict $IP_MASK mask 255.255.255.0 nomodify notrap" /etc/ntp.conf
    sed -i -e 's!^server!# server!g' /etc/ntp.conf
    sed -i "25i server time7.aliyun.com iburst" /etc/ntp.conf
    sed -i "25i server time6.aliyun.com iburst" /etc/ntp.conf
    sed -i "25i server time5.aliyun.com iburst" /etc/ntp.conf
    sed -i "25i server time4.aliyun.com iburst" /etc/ntp.conf
    sed -i "25i server time3.aliyun.com iburst" /etc/ntp.conf
    sed -i "25i server time2.aliyun.com iburst" /etc/ntp.conf
    sed -i "25i server time1.aliyun.com iburst" /etc/ntp.conf
    nl /etc/ntp.conf
    systemctl enable ntpd
    systemctl start ntpd
    ntpdc -c loopinfo
    ntpq -p
    ntpstat
}

client() {
    yum install -y ntpdate ntp
    sed -i -e 's!^server!# server!g' /etc/ntp.conf
    echo -e " ${Green_font_prefix}客户端配置本地ntp服务端${Font_color_suffix}"
    read -p "请输入主ntp服务 IP[如：192.168.39.22]:" PREFER_IP
    read -p "请输入备ntp服务 IP[如：192.168.39.33]:" IBURST_IP
    sed -i "25i server $IBURST_IP iburst" /etc/ntp.conf
    sed -i "25i server $PREFER_IP prefer" /etc/ntp.conf
    nl /etc/ntp.conf
    systemctl enable ntpdate
    systemctl start ntpdate
    ntpdate $PREFER_IP
    echo '*/30 * * * * /usr/sbin/ntpdate -q $PREFER_IP >/dev/null 2>&1' > /tmp/crontab2.tmp
    crontab /tmp/crontab2.tmp
}

start_menu(){
clear
echo && echo -e " ntp 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}

 ————————————服务端安装配置————————————————
 ${Green_font_prefix}1.${Font_color_suffix} 服务端配置

 ————————————客户端安装配置————————————————
 ${Green_font_prefix}2.${Font_color_suffix} 客户端配置

  ————————————退出脚本————————————————————
 ${Green_font_prefix}0.${Font_color_suffix} 退出脚本
 ————————————————————————————————————————" && echo
echo

read -p " 请输入数字 [0-2]:" num
case "$num" in
    0)
    exit 1
    ;;
    1)
    server
    ;;
    2)
    client
    ;;
    *)
    clear
    echo -e "${Error}:请输入正确数字 [0-6]"
    sleep 5s
    start_menu
    ;;
esac
}
start_menu

