#!/bin/sh

# Write ProxySQL yum repo
cat > /etc/yum.repos.d/proxysql.repo << EOF
[proxysql]
name=ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.4.x/centos/\$releasever
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.4.x/repo_pub_key
EOF

# Install ProxySQL and MariaDB client
yum install -y proxysql mysql

# Start
service proxysql start

# Run initial SQL with admin:admin at localhost:6032 (ProxySQL admin interface)
## - Add TiDB server
## - Add TiDB login users in ProxySQL
## - Set default charset is `utf8mb4`, and default collation is `utf8mb4_bin`;
mysql -uadmin -h127.0.0.1 -padmin -P6032 << EOF
insert into mysql_servers(hostgroup_id,hostname,port) values(0,'127.0.0.1',4000);
load mysql servers to runtime;
save mysql servers to disk;

insert into mysql_users(username,password,active,default_hostgroup,transaction_persistent) values('root','',1,0,1);
load mysql users to runtime;
save mysql users to disk;

set mysql-default_charset="utf8mb4";
set mysql-default_collation_connection="utf8mb4_bin";
load mysql variables to runtime;
save mysql variables to disk;
EOF