-- -- VARIABLES
SET mysql-ssl_p2s_cert="/cert.pem";
SET mysql-ssl_p2s_key="/cert.pem";
SET mysql-monitor_username="<serverless tier user>";
SET mysql-monitor_password="<serverless tier password>";
SET mysql-monitor_enabled="false";
-- SELECT * FROM global_variables WHERE variable_name LIKE 'mysql-ssl%'\G;
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

-- Add user
insert into mysql_users(
	username,password,default_hostgroup,use_ssl
) 
values(
	'<serverless tier user>','<serverless tier password>',0,1
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