useradd oracle -m
groupadd oinstall
usermod -g oinstall oracle

yum install compat-libcap1-1.10-1-x86_64 compat-libstdc++-33 elfutils-libelf-devel gcc-c++ unixODBC unixODBC-devel libaio-devel compat-libstdc++-33.i686 libstdc++.i686 libaio-devel.i686 libaio.i686 unixODBC.i686 unixODBC-devel.i686 ksh unzip sysstat pdksh -y

fdisk /dev/sdb <<EOF
n
1
p
1


w
EOF
pvcreate /dev/sdb1
vgcreate VolGroup00 /dev/sdb1
lvcreate VolGroup00  -L 49G -n LogVol02
mkdir /u01
mkfs.ext3 /dev/mapper/VolGroup00-LogVol02

echo /dev/mapper/VolGroup00-LogVol02 /u01            ext3    defaults        1 1 >>/etc/fstab
mount /u01/

mkdir /u01/oracle
chown oracle:oracle /u01/oracle

cd /vagrant
#unzip /vagrant/linux.x64_11gR2_database_1of2.zip
#unzip /vagrant/linux.x64_11gR2_database_2of2.zip

#sed -i s/5.2.14/20060214/g database/stage/cvu/cvu_prereq.xml

sudo cat >>/etc/security/limits.conf <<EOF
*       hard    nofile  150000
*       hard    nproc   16384
*       soft    nproc   2047
EOF

sudo cat >>/etc/sysctl.conf <<EOF
kernel.sem = 250 32000 100 128
fs.file-max = 6815744
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
fs.aio-max-nr = 1048576
EOF

sed -i s/1024/4096/ /etc/security/limits.d/90-nproc.conf

echo "executing sysctl -p"
sysctl -p
echo "kernel tuned"

#yum -y install xorg-x11-utils -y
#yum install xorg-x11-xauth.x86_64 -y

#dd if=/dev/zero of=/u01/swapfile bs=1024 count=11485760
#dd if=/dev/zero of=/u01/swapfile bs=1024 count=12582912
dd if=/dev/zero of=/u01/swapfile bs=1k count=12288k
mkswap /u01/swapfile
swapon /u01/swapfile
cat >> /etc/fstab <<EOF
/u01/swapfile               swap                    swap    defaults        0 0
EOF

rpm -ivh /vagrant/jdk-7u79-linux-x64.rpm

#cd /vagrant/database/
mkdir /u01/oraInventory
chown oracle:oinstall /u01/oraInventory
cd /vagrant/packages/installers/database/Disk1

unset DISPLAY
#su oracle -c "./runInstaller -silent -responseFile /vagrant/db.rsp -ignorePrereq -waitforcompletion -jreLoc /usr/java/jdk1.7.0_79"
su oracle -c "./runInstaller -silent -responseFile /vagrant/db2.rsp -ignorePrereq -waitforcompletion -jreLoc /usr/java/jdk1.7.0_79"


#/u01/oracle/app/oraInventory/orainstRoot.sh
#/u01/oracle/app/vagrant/product/11.2.0/dbhome_1/root.sh
/u01/oraInventory/orainstRoot.sh
/u01/oracle/product/11.2.0/dbhome_1/root.sh

#echo "export ORACLE_HOME=/u01/oracle/app/vagrant/product/11.2.0/dbhome_1" >>/home/oracle/.bash_profile
echo "export ORACLE_HOME=/u01/oracle/product/11.2.0/dbhome_1/" >>/home/oracle/.bash_profile
echo "export ORACLE_SID=FMW" >>/home/oracle/.bash_profile
echo 'export PATH=$PATH:$ORACLE_HOME/bin' >>/home/oracle/.bash_profile
chown oracle:oinstall /home/oracle/.bash_profile

exit

# 	DB INSTALLED
#

yum -y install xorg-x11-server-Xorg.x86_64
yum -y install compat-libstdc++-33
yum -y install elfutils-libelf-devel
yum -y install gcc-c++
yum -y install glibc-devel-2.5
yum -y install libaio
yum -y install libaio-devel
yum -y install libstdc++
yum -y install sysstat
yum -y install redhat-lsb
yum -y install curl
yum -y install -y MAKEDEV
yum install -y oracle-rdbms-server-12cR1-preinstall

yum install -y xorg-x11-xinit
yum install -y xclock
yum install -y xterm
yum install -y openmotif
yum install -y openmotif22


#rm -rf /vagrant/database/*

cd /vagrant/packages
#find . -name \*.zip -exec unzip {} \;

su - oracle -c "/vagrant/update_db.sh"


#Run RCU 
cd /vagrant/packages/installers/fmw_rcu/linux
unzip rcuHome.zip
cd bin
cat  >/tmp/pass <<EOF
Password12
Password12
EOF
./rcu -silent -createRepository -databaseType ORACLE -connectString localhost:1521:FMW -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -schemaPrefix DEV -component OAM -component MDS -component IAU -component OPSS -component OMSM -f </tmp/pass

#Install Weblogic
su oracle -c "mkdir -p /u01/oracle/product/fmw/11.1.2"
cd /vagrant/packages/installers/weblogic/
su oracle -c "/vagrant/packages/jdk/bin/java -jar wls_generic.jar -mode=silent -silent_xml=/vagrant/weblogic_silent.xml"

#Install Oracle Identity Management
cd /vagrant/packages/installers/iamsuite/Disk1
su oracle -c "./runInstaller -silent -response /vagrant/OAM.res -jreLoc /usr/java/jdk1.7.0_79 -waitforcompletion"


#Extend domain
#WLST generated with: configToScript('/dbs/oracle/WLS/domains/iam','/home/oracle')
cd /u01/oracle/product/fmw/11.1.2/Oracle_IDM1/common/bin
cp /vagrant/oam_domain/* /home/oracle/oam
./config.sh /home/oracle/oam

#Create security store
cd /u01/oracle/product/fmw/11.1.2/oracle_common/common/bin
./wlst.sh ../../../Oracle_IDM1/common/tools/configureSecurityStore.py -d /u01/oracle/product/fmw/11.1.2/user_projects/domains/OAM -c IAM -p Password12 -m create
#./wlst.sh ../../../Oracle_IDM1/common/tools/configureSecurityStore.py -d /u01/oracle/product/fmw/11.1.2/user_projects/domains/OAM -p Password12 -m validate

#Install OUD
cd /vagrant/packages/installers/oud/Disk1
su oracle -c "./runInstaller -silent -response /vagrant/oud_ps3.response -jreLoc /usr/java/jdk1.7.0_79 -waitforcompletion"

#Start Weblogic
nohup /u01/oracle/product/fmw/11.1.2/user_projects/domains/OAM/startWebLogic.sh >home/oracle/admin.log &

#USING LCM - remove?

#cd /vagrant/software/installers/idmlcm/Disk1
#su oracle -c "./runInstaller -silent -response /vagrant/response_file -jreLoc /usr/java/jdk1.7.0_79 -waitforcompletion"

#su oracle -c "mkdir /u01/oracle/product/fmw/LCMStore"
#su oracle -c "mkdir /u01/oracle/product/fmw/Installation #Software Installation Location"
#su oracle -c "mkdir /u01/oracle/product/fmw/Config #Shared Configuration Location"



#cd /u01/oracle/product/fmw/Oracle_IDMLCM1/provisioning/bin/
#su oracle -c "./runIAMDeployment.sh -responseFile /vagrant/provisioning_oam.rsp  -target preverify"

