#!/bin/sh

# start and stop
docker-compose up -d
trap 'docker-compose down' EXIT

# waiting for all containers runs well

sleep 5

# prepare data
mysql -u root -h 127.0.0.1 -P 4001 << EOF
DROP TABLE IF EXISTS test.tidb_server;
CREATE TABLE test.tidb_server (server_name VARCHAR(255));
INSERT INTO test.tidb_server (server_name) VALUES ('tidb-server01-port-4001');
EOF

mysql -u root -h 127.0.0.1 -P 4002 << EOF
DROP TABLE IF EXISTS test.tidb_server;
CREATE TABLE test.tidb_server (server_name VARCHAR(255));
INSERT INTO test.tidb_server (server_name) VALUES ('tidb-server02-port-4002');
EOF

mysql -u root -h 127.0.0.1 -P 4003 << EOF
DROP TABLE IF EXISTS test.tidb_server;
CREATE TABLE test.tidb_server (server_name VARCHAR(255));
INSERT INTO test.tidb_server (server_name) VALUES ('tidb-server03-port-4003');
EOF

# test load balance
mysql -u root -h 127.0.0.1 -P 6034 -t << EOF 
select * from test.tidb_server;
select * from test.tidb_server;
select * from test.tidb_server;
select * from test.tidb_server;
select * from test.tidb_server;
EOF
