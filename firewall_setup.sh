#!/bin/sh
#################################################
#	Title:	防火墙配置	  
#	Auth:	Ryan Mok   
#	Date:	2019-07-08       
#   Description: 将oracle端口1521加入防火墙
#################################################

systemctl restart firewalld
firewall-cmd --zone=public --add-port=1521/tcp --permanent
firewall-cmd --reload
