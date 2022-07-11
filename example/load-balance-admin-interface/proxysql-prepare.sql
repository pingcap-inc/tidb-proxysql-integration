-- Add 3 TiDB servers
insert into mysql_servers(hostgroup_id,hostname,port) values(0,'tidb-0',4000);
insert into mysql_servers(hostgroup_id,hostname,port) values(0,'tidb-1',4000);
insert into mysql_servers(hostgroup_id,hostname,port) values(0,'tidb-2',4000);

-- Effect and save servers conifg
load mysql servers to runtime;
save mysql servers to disk;

-- Add 'root' user
insert into mysql_users(username,password,default_hostgroup) values('root','',0);

-- Effect and save users conifg
load mysql users to runtime;
save mysql users to disk;