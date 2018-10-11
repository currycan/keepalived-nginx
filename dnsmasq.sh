#!/bin/bash

yum install dnsmasq -y
sed -i "669i listen-address=127.0.0.1" /etc/dnsmasq.conf
sed -i "2i nameserver 127.0.0.1" /etc/resolv.conf
systemctl enable dnsmasq
systemctl start dnsmasq
