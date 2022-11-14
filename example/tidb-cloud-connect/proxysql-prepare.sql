-- -- VARIABLES
SET mysql-ssl_p2s_cert="/etc/ssl/certs/ca-certificates.crt";
SET mysql-ssl_p2s_key="/etc/ssl/certs/ca-certificates.crt";
SET mysql-monitor_username="HZ5E7ifaDEjJTsh.root";
SET mysql-monitor_password="wqz1994625";
SET mysql-monitor_enabled="false";
-- SELECT * FROM global_variables WHERE variable_name LIKE 'mysql-ssl%'\G;
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

-- Add user
insert into mysql_users(
	username,password,default_hostgroup,use_ssl
) 
values(
	'HZ5E7ifaDEjJTsh.root','wqz1994625',0,1
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
	'gateway01.us-west-2.prod.aws.tidbcloud.com',
	4000,
	1
);
load mysql servers to runtime;
save mysql servers to disk;

-- Verify
select * from runtime_mysql_servers\G;