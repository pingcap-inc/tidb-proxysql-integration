-- -- VARIABLES
SET mysql-monitor_username="<serverless tier username>";
SET mysql-monitor_password="<serverless tier password>";
-- SELECT * FROM global_variables WHERE variable_name LIKE 'mysql-ssl%'\G;
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

-- Add user
insert into mysql_users(
	username,password,default_hostgroup
) 
values(
	'<serverless tier username>','<serverless tier password>',0
);
load mysql users to runtime;
save mysql users to disk;

-- SERVERS
insert into mysql_servers (
		hostgroup_id,
		hostname,
		port,
		use_ssl
	) 
values (
	0,
	'<serverless tier host>',
	4000,
	1
);
load mysql servers to runtime;
save mysql servers to disk;

-- Verify
select * from runtime_mysql_servers\G;