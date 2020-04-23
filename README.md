# oracle_11g_install
Install oracle 11g R2 server in silent mode by shell script

File contain:
---
* install_db.sh
* create_db.sh
* user_create.sh
* firewall_setup.sh

Installiation Envirement
---
CentOS 7 x64 minimal install with yum base repo available

Installiation
---
1. Download Oracle 11g R2 linux version from oracle website
2. Put the `linux.x64_11gR2_database_1of2.zip` and `linux.x64_11gR2_database_2of2.zip` together with the scripts in the same folder
3. Excute `install_db.sh` script, enter your server hostname, IP address, install path and SID name
4. Excute `create_db.sh` script, enter your SID name and install path
5. The you have installed your oracle server, use `create_db.sh` and `firewall_setup.sh` if you want, remember that user create script will create user as dba by default
