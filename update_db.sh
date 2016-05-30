#/bin/bash

export ORACLE_HOME=/u01/oracle/app/vagrant/product/11.2.0/dbhome_1
export PATH=$PATH:/u01/oracle/app/vagrant/product/11.2.0/dbhome_1/bin
export ORACLE_SID=FMW

sqlplus / as sysdba <<EOF
ALTER SYSTEM SET open_cursors = 1600 scope=spfile;
ALTER SYSTEM SET session_cached_cursors = 500 scope=spfile;
ALTER SYSTEM SET aq_tm_processes = 1 scope=spfile;
ALTER SYSTEM SET session_max_open_files = 50 scope=spfile;
ALTER SYSTEM SET sessions = 500 scope=spfile;
ALTER SYSTEM SET sga_target = 536879120 scope=spfile;
ALTER SYSTEM SET pga_aggregate_target = 104857600 scope=spfile;
SHUTDOWN IMMEDIATE;
startup;
EOF

emctl stop dbconsole

