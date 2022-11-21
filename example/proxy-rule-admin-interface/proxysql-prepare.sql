-- Add 2 TiDB servers, hostgroup_id of tidb-server01 is `0`, hostgroup_id of tidb-server02 is `1`
insert into mysql_servers(hostgroup_id,hostname,port) values(0,'tidb-server01',4000);
insert into mysql_servers(hostgroup_id,hostname,port) values(1,'tidb-server02',4000);

-- Effect and save servers conifg
load mysql servers to runtime;
save mysql servers to disk;

-- Add 'root' user, default_hostgroup is 0
insert into mysql_users(username,password,default_hostgroup) values('root','',0);

-- Effect and save users conifg
load mysql users to runtime;
save mysql users to disk;

-- Add proxy rules, `^` matching start, `$` matching end
-- 1. `SELECT ... FOR UPDATE`, using hostgroup `0`
-- 2. The other `SELECT` statement, using hostgroup `1`
INSERT INTO mysql_query_rules(rule_id,active,match_digest,destination_hostgroup,apply) VALUES (1,1,'^SELECT.*FOR UPDATE$',0,1),(2,1,'^SELECT',1,1);
load mysql query rules to runtime;
save mysql query rules to disk;