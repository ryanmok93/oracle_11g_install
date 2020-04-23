#!/bin/sh
#################################################
#	Title:	oracle 静默安装脚本	  
#	Auth:	Ryan Mok   
#	Date:	2019-07-04       
# --File Contain:   
#	--install_db.sh
#	--create_db.sh
#	--user_create.sh
#	--firewall_setup.sh
#	--linux.x64_11gR2_database_1of2.zip
#	--linux.x64_11gR2_database_2of2.zip
#	--pdksh-5.2.14-37.el5_8.1.x86_64.rpm
#################################################
echo -e "\nOracle 11g R2 installiation\n"


echo -e "请输入服务器IP：\c"
read ip_address
echo -e "请输入主机名(hostname): \c"
read hostname
cat>>/etc/hosts<<EOF
$ip_address $hostname
EOF
ping $hostname -c 3
echo -e "--------------------------------------------------------------------------\n"

echo -e "请输入安装路径：\c"
read install_path
echo -e "请输入安装服务名：\c"
read oracle_install_sid


echo "安装相关依赖"

yum makecache

yum install -y unzip
yum install -y binutils
yum install -y compat-libstdc++-33
yum install -y elfutils-libelf
yum install -y elfutils-libelf-devel
yum install -y expat
yum install -y gcc
yum install -y gcc-c++
yum install -y glibc
yum install -y glibc-common
yum install -y glibc-devel
yum install -y glibc-headers
yum install -y libaio
yum install -y libaio-devel
yum install -y libgcc
yum install -y libstdc++
yum install -y libstdc++-devel
yum install -y make
yum install -y pdksh
yum install -y sysstat
yum install -y unixODBC
yum install -y unixODBC-devel
yum install -y redhat-lsb-core

if [ $? -ne 0 ]; then
	echo "请检查yum源或网络配置"
	exit 1
fi

rpm -ivh pdksh-5.2.14-37.el5_8.1.x86_64.rpm
echo -e "-------------------------------------------------------------------------\n"


echo "创建oracle用户和组"
sleep 1
groupadd oinstall
groupadd dba
groupadd asmdba
groupadd asmadmin
userdel oracle
useradd -g oinstall -G dba,asmdba oracle -d /home/oracle
id oracle
passwd oracle<<EOF
oracle
oracle
EOF
echo -e "--------------------------------------------------------------------------\n"

echo "创建安装目录"
sleep 1
mkdir -pv ${install_path}/app/oracle
mkdir -pv ${install_path}/app/oracle/product/11.2.0
mkdir -pv ${install_path}/etc
mkdir -pv ${install_path}/app/oracle/inventory
mkdir -pv ${install_path}/app/oracle/fast_recovery_area
mkdir -pv ${install_path}/app/oracle/oradata
chown -R oracle:oinstall ${install_path}
chmod -R 775 ${install_path}/app/oracle
echo -e "-------------------------------------------------------------------------\n"


echo "配置用户环境变量"
echo "editing /home/oracle/.bashrc"
cat>>/home/oracle/.bashrc<<EOF
umask 022
export ORACLE_HOSTNAME=${hostname}
export ORACLE_BASE=${install_path}/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/
export ORACLE_SID=${oracle_install_sid}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib:$LD_LIBRARY_PATH
export PATH=.:\$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$ORACLE_HOME/jdk/bin:$PATH
export LC_ALL="en_US"
export LANG="en_US"
export NLS_LANG="AMERICAN_AMERICA.ZHS16GBK"
export NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"
EOF
cat /home/oracle/.bashrc
echo "------------------------------------------------------------------------"

echo "配置内核参数"
sys_memory=`free -m|grep -i "Mem"|awk '{print $2}'`
max_memory_use=$(printf "%.0f" `echo "scale=5;$sys_memory*0.8*1024*1024"|bc`)
echo "Setting Max Memory: "${max_memory_use}
cat>>/etc/sysctl.conf<<EOF
fs.aio-max-nr=1048576
fs.file-max=6815744
kernel.shmall=2097152
kernel.shmmni=4096
kernel.shmmax=${max_memory_use}
kernel.sem=250 32000 100 128
net.ipv4.ip_local_port_range=9000 65500
net.core.rmem_default=262144
net.core.rmem_max=4194304
net.core.wmem_default=262144
net.core.wmem_max=1048586
EOF
sysctl -p
echo "------------------------------------------------------------------------"

echo "关闭防火墙"
systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl status firewalld.service

echo "解压数据库安装文件"
unzip linux.x64_11gR2_database_1of2.zip -d ${install_path}
sleep 1
unzip linux.x64_11gR2_database_2of2.zip -d ${install_path}
echo "-----------------------------------------------------------------------"

echo "配置安装响应文件db_install.rsp"
cp ${install_path}/database/response/* ${install_path}/etc/ -rv
#Define db_install.rsp location
HOSTNAME=$hostname
DB_INSTALL_RESP_FILE=${install_path}/etc/db_install.rsp
sed -i 's/oracle.install.option=.*/oracle.install.option='INSTALL_DB_SWONLY'/g' ${DB_INSTALL_RESP_FILE}
sed -i 's/DECLINE_SECURITY_UPDATES=.*/DECLINE_SECURITY_UPDATES='true'/g' ${DB_INSTALL_RESP_FILE}
sed -i 's/UNIX_GROUP_NAME=.*/UNIX_GROUP_NAME='oinstall'/g' ${DB_INSTALL_RESP_FILE}
sed -i 's#INVENTORY_LOCATION=.*#INVENTORY_LOCATION='${install_path}/app/oracle/inventory'#g' ${DB_INSTALL_RESP_FILE}
sed -i 's/SELECTED_LANGUAGES=.*/SELECTED_LANGUAGES='en,zh_CN'/g' ${DB_INSTALL_RESP_FILE}
sed -i 's/ORACLE_HOSTNAME=.*/ORACLE_HOSTNAME='${HOSTNAME}'/g' ${DB_INSTALL_RESP_FILE}
sed -i 's#ORACLE_HOME=.*#ORACLE_HOME='${install_path}/app/oracle/product/11.2.0'#g' ${DB_INSTALL_RESP_FILE}
sed -i 's#ORACLE_BASE=.*#ORACLE_BASE='${install_path}/app/oracle'#g' ${DB_INSTALL_RESP_FILE}
sed -i 's/oracle.install.db.InstallEdition=.*/oracle.install.db.InstallEdition='EE'/g' ${DB_INSTALL_RESP_FILE}
sed -i 's/oracle.install.db.isCustomInstall=.*/oracle.install.db.isCustomInstall='true'/g' ${DB_INSTALL_RESP_FILE}
sed -i 's/oracle.install.db.DBA_GROUP=.*/oracle.install.db.DBA_GROUP='dba'/g' ${DB_INSTALL_RESP_FILE}
sed -i 's/oracle.install.db.OPER_GROUP=.*/oracle.install.db.OPER_GROUP='dba'/g' ${DB_INSTALL_RESP_FILE}
echo -e "-----------------------------------------------------------------------\n"

ORA_INST_FILE=/etc/oraInst.loc
if [ -f ${ORA_INST_FILE} ]; then
    echo -e ${ORA_INST_FILE} " file exist, deleting it\n"
    rm -rf ${ORA_INST_FILE}
else
    echo -e "No oraInst.loc found, continue...\n"
fi

echo "开始安装"
su - oracle << EOF
cd ${install_path}/database;
./runInstaller -silent -ignorePrereq -responseFile ${install_path}/etc/db_install.rsp;
EOF
