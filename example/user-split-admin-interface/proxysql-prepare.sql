-- Add 2 TiDB servers, hostgroup_id of tidb-server01 is `0`, hostgroup_id of tidb-server02 is `1`
insert into mysql_servers(hostgroup_id,hostname,port) values(0,'tidb-server01',4000);
insert into mysql_servers(hostgroup_id,hostname,port) values(1,'tidb-server02',4000);

-- Effect and save servers conifg
load mysql servers to runtime;
save mysql servers to disk;

-- Add 'root' user, default_hostgroup is 0
-- Add 'root1' user, default_hostgroup is 1
insert into mysql_users(username,password,default_hostgroup) values('root','',0);
insert into mysql_users(username,password,default_hostgroup) values('root1','',1);

-- Effect and save users conifg
load mysql users to runtime;
save mysql users to disk;