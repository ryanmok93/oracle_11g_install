#!/bin/sh 
#################################################
#	Title:	oracle初始化	  
#	Auth:	Ryan Mok   
#	Date:	2019-07-08       
#   Description: 创建Oracle数据库及初始化
#################################################

HOSTNAME=`hostname`

echo -e "请输入安装服务名：\c"
read oracle_install_sid

echo -e "请输入安装路径：\c"
read install_path

echo "执行root.sh & orainstRoot.sh脚本"
sh ${install_path}/app/oracle/inventory/orainstRoot.sh
sh ${install_path}/app/oracle/product/11.2.0/root.sh


echo "配置静默监听"
su - oracle << EOF
netca /silent /responsefile /db/etc/netca.rsp
EOF

LISTENER_ORA_FILE=${install_path}/app/oracle/product/11.2.0/network/admin/listener.ora

cat>>${LISTENER_ORA_FILE}<<EOF
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${oracle_install_sid})
      (ORACLE_HOME = /db/app/oracle/product/11.2.0/)
      (SID_NAME = ${oracle_install_sid})
    )
  )
EOF

sed -i 's#ORACLE_HOME =.*#ORACLE_HOME = '${install_path}/app/oracle/product/11.2.0/\)'#g' ${LISTENER_ORA_FILE}
sed -i 's/HOST =.*/HOST = '${HOSTNAME}\)\)\(PORT = 1521\)'/g' ${LISTENER_ORA_FILE}

su - oracle << EOF
lsnrctl stop;
lsnrctl start;
lsnrctl status;
EOF

echo "查看监听"
netstat -lntp | grep 1521 --color=auto
sleep 1
echo -e "-----------------------------------------------------------------------\n"


echo "创建数据库"
cp ${install_path}/database/response/dbca.rsp ${install_path}/etc/ -rv

DBCA_RSP=${install_path}/etc/dbca.rsp
sys_memory=`free -m|grep -i "Mem"|awk '{print $2}'`
dbca_memory=$(printf "%.0f" `echo "scale=5;$sys_memory*0.8"|bc`)
sed -i 's/GDBNAME =.*/GDBNAME ='\"${oracle_install_sid}\"'/g' ${DBCA_RSP}
sed -i 's/SID =.*/SID = '\"${oracle_install_sid}\"'/g' ${DBCA_RSP}
sed -i 's/#SYSPASSWORD =.*/SYSPASSWORD = '\"oracle\"'/g' ${DBCA_RSP}
sed -i 's/#SYSTEMPASSWORD =.*/SYSTEMPASSWORD ='\"oracle\"'/g' ${DBCA_RSP}
sed -i 's/#SYSMANPASSWORD =.*/SYSMANPASSWORD ='\"oracle\"'/g' ${DBCA_RSP}
sed -i 's/#DBSNMPPASSWORD =.*/DBSNMPPASSWORD ='\"oracle\"'/g' ${DBCA_RSP}
sed -i 's%#DATAFILEDESTINATION =.*%DATAFILEDESTINATION = '${install_path}/app/oracle/oradata'%g' ${DBCA_RSP}
sed -i 's%#RECOVERYAREADESTINATION =.*%RECOVERYAREADESTINATION = '${install_path}/app/oracle/fast_recovery_area'%g' ${DBCA_RSP}
sed -i 's/#CHARACTERSET =.*/CHARACTERSET ='\"AL32UTF8\"'/g' ${DBCA_RSP}
sed -i 's/#TOTALMEMORY =.*/TOTALMEMORY ='\"${dbca_memory}\"'/g' ${DBCA_RSP}

su - oracle << EOF
dbca -silent -responseFile ${install_path}/etc/dbca.rsp
EOF
echo -e "-----------------------------------------------------------------------\n"

ps -ef|grep ora_ --color=auto | grep -v grep

su - oracle << EOF
lsnrctl status;
EOF

cp -rv ${install_path}/app/oracle/admin/${oracle_install_sid}*/pfile/init.ora* ${install_path}/app/oracle/product/11.2.0/dbs/init${oracle_install_sid}.ora

chown -R oracle:oinstall ${install_path}/app/oracle/product/11.2.0/dbs/init${oracle_install_sid}.ora

