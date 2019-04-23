#!/bin/bash

#=================================================
#   System Required: CentOS 7
#   Description: redis cluster 一键安装
#   Version: 1.0.0
#   Author: currycan
#   Github: https://github.com/currycan/keepalived-nginx
#=================================================

sh_ver=1.0.0

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"

set -e

nginx_install() {
    echo ">>> install keepalived"
    rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
    yum -y install nginx mailx
    setenforce 0
    sed -i /etc/selinux/config -r -e 's/^SELINUX=.*/SELINUX=disabled/g'
    \curl -so /etc/init.d/nginx https://raw.githubusercontent.com/currycan/keepalived-nginx/master/nginx
    chmod 755 /etc/init.d/nginx
    chkconfig --add /etc/init.d/nginx
    chkconfig nginx on
    echo ">>>> nginx installation done <<<<"
}

keepalived_install() {
    echo ">>> install keepalived"
    VERSION=2.0.7
    yum install -y gcc-c++ make mailx openssl-devel popt-devel ipvsadm libnl libnl-devel libnfnetlink-devel
    curl -o ./keepalived-$VERSION.tar.gz  http://www.keepalived.org/software/keepalived-$VERSION.tar.gz
    tar zxvf keepalived-$VERSION.tar.gz
    cd keepalived-$VERSION
    ./configure --prefix=/usr/local/keepalived
    make -j 4 && make install
    cp /usr/local/keepalived/sbin/keepalived /usr/sbin/keepalived
    mkdir -p /etc/keepalived
    cp /usr/local/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf
    cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
    cp ./keepalived/etc/init.d/keepalived /etc/init.d/
    chmod 755 /etc/init.d/keepalived
    chkconfig --add /etc/init.d/keepalived
    chkconfig keepalived on
    cd ..
    rm -rf keepalived-$VERSION
    rm -rf keepalived-$VERSION.tar.gz
    echo ">>>> keepalived installation done <<<<"
}

sed_conf() {
    local parameter="$1"
    local file_name="$2"
    sed -i -e "s!\${$parameter}!`eval echo '$'"$parameter"`!g" ${file_name}
    sed -i -e "s!\$$parameter!`eval echo '$'"$parameter"`!g" ${file_name}
}


# NET_DEV=`ip route|awk '/default/ { print $5 }'`
# AUTH_PASS=`cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -c ${LEN:-16}`
config() {
    \curl -so /etc/keepalived/keepalived.conf https://raw.githubusercontent.com/currycan/keepalived-nginx/master/keepalived_sample.conf
    \curl -so /etc/keepalived/check_nginx_alive.sh https://raw.githubusercontent.com/currycan/keepalived-nginx/master/check_nginx_alive.sh
    \curl -so /etc/keepalived/to_backup.sh https://raw.githubusercontent.com/currycan/keepalived-nginx/master/to_backup.sh
    \curl -so /etc/keepalived/to_fault.sh https://raw.githubusercontent.com/currycan/keepalived-nginx/master/to_fault.sh
    \curl -so /etc/keepalived/to_master.sh https://raw.githubusercontent.com/currycan/keepalived-nginx/master/to_master.sh
    chmod 770 /etc/keepalived/*.sh
    parameters=(ROLE1 NET_DEV PRIORITY1 AUTH_PASS IP_MASK1 ROLE2 PRIORITY2 IP_MASK2 VIR_ID1 VIR_ID2 HOST_IP ANOTHER_HOST_IP)
    echo -e " ${Green_font_prefix}配置集群keepalived.conf${Font_color_suffix}"
    read -p "请输入要虚拟网卡设备名[如：enp5s0]:" NET_DEV
    stty erase '^H' && read -p "keepalive是否为互为主备(双虚IP)? [Y/n] :" yn
    [ -z "${yn}" ] && yn="y"
    if [[ $yn == [Yy] ]]; then
        read -p "请输入本机IP地址[如：192.168.39.2]:" HOST_IP
        read -p "请输入另一主机IP地址[如：192.168.39.3]" ANOTHER_HOST_IP
        read -p "请输入虚IP1/MASK[如：192.168.39.22/24]:" IP_MASK1
        read -p "请输入虚IP2/MASK[如：192.168.39.33/24]:" IP_MASK2
        read -p "请输入虚IP1 virtual id[两个节点设置必须一样,同一局域网内若有多个keepalive服务，值必须不同，取值范围：0-255，如：11]:" VIR_ID1
        read -p "请输入虚IP2 virtual id[两个节点设置必须一样,同一局域网内若有多个keepalive服务，值必须不同，取值范围：0-255，如：22]:" VIR_ID2
    else
        read -p "请输入本机IP地址[如：192.168.39.2]:" HOST_IP
        read -p "请输入另一主机IP地址[如：192.168.39.3]" ANOTHER_HOST_IP
        read -p "请输入虚IP/MASK[如：192.168.39.22/24]:" IP_MASK1
        read -p "请输入虚IP virtual id[两个节点设置必须一样,同一局域网内若有多个keepalive服务，值必须不同，取值范围：0-255]:" VIR_ID1
        sed -i '38,65d' /etc/keepalived/keepalived.conf
    fi
    read -p "请输入用于异常告警的邮件地址[如：zhangsan@fmsh.com.cn]:" EMAIL_ADDR
    sed -e "s/\${EMAIL_ADDR}/$EMAIL_ADDR/g" -i /etc/keepalived/*.sh
}

master_config() {
    local ROLE1=MASTER
    local PRIORITY1=150
    local ROLE2=BACKUP
    local PRIORITY2=100
    config
    for key in ${parameters[@]};do sed_conf $key /etc/keepalived/keepalived.conf; done
    nl /etc/keepalived/keepalived.conf
}

backup_config() {
    local ROLE1=BACKUP
    local PRIORITY1=100
    local ROLE2=MASTER
    local PRIORITY2=150
    config
    for key in ${parameters[@]};do sed_conf $key /etc/keepalived/keepalived.conf; done
    nl /etc/keepalived/keepalived.conf
}

start_menu(){
clear
echo && echo -e " nginx keepalived 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}

 ————————————安装nginx,需手动配置配置文件————————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安装 nginx, 当前版本1.14.0

 ————————————安装keepalived——————————————————————————————
 ${Green_font_prefix}2.${Font_color_suffix} 安装 keepalived, 当前版本v2.0.7

 ————————————keepalived配置文件生成————————————
 ${Green_font_prefix}3.${Font_color_suffix} master 配置文件生成
 ${Green_font_prefix}4.${Font_color_suffix} backup 配置文件生成

 —————————————启动nginx服务———————————————
 ${Green_font_prefix}5.${Font_color_suffix} 启动nginx服务

  —————————————启动keepalived服务———————————————
 ${Green_font_prefix}6.${Font_color_suffix} 启动keepalived服务

  ————————————退出脚本————————————————————
 ${Green_font_prefix}0.${Font_color_suffix} 退出脚本
 ————————————————————————————————————————" && echo
echo

read -p " 请输入数字 [0-6]:" num
case "$num" in
    0)
    exit 1
    ;;
    1)
    nginx_install
    ;;
    2)
    keepalived_install
    ;;
    3)
    master_config
    ;;
    4)
    backup_config
    ;;
    5)
    service nginx start
    ;;
    6)
    service keepalived start
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
