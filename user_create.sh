#!/bin/sh
#################################################
#	Title:	oracle创建用户	  
#	Auth:	Ryan Mok   
#	Date:	2019-07-08       
#   Description: 创建oracle用户
#   Argument: username password
#################################################

## 配置脚本执行路径
basepath=$(cd `dirname $0`;pwd)

## 导入环境变量及配置文件
source /etc/profile

## 进入当前目录
cd ${basepath}

## 脚本名称
shellName=$0

if [ $# != 2 ]; then
    echo "Usage: sh ${shellName##*/} username password"
    echo -e "For example: \n \tsh ${shellName##*/} dgbd dgbd_password"
exit 1;
fi

su - oracle<<EOF
sqlplus / as sysdba
select status from v\$instance;
EOF

oracleUser=$1
password=$2

echo -e "\n创建Oracle用户名：" ${oracleUser} "密码：" ${password}
su - oracle<<EOF
sqlplus / as sysdba
create user ${oracleUser} identified by ${password};
alter user ${oracleUser} account unlock;
grant create session to ${oracleUser};
grant connect to ${oracleUser};
grant resource to ${oracleUser};
grant imp_full_database to ${oracleUser};
grant create database link to ${oracleUser};
grant create view to ${oracleUser};
grant delete any table to ${oracleUser};
grant insert any table to ${oracleUser};
grant select any table to ${oracleUser};
grant unlimited tablespace to ${oracleUser};
grant update any table to ${oracleUser};
grant debug connect session to ${oracleUser};
grant dba to ${oracleUser};
EOF



