#!/bin/sh

# start and stop
docker compose up -d
trap 'docker compose down' EXIT

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

# tidb-server02 need another account
mysql -u root -h 127.0.0.1 -P 4002 << EOF
CREATE USER 'root1' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root1'@'%';
FLUSH PRIVILEGES;
EOF

# using admin interface to configure
docker compose exec proxysql sh -c "mysql -uadmin -padmin -h127.0.0.1 -P6032 < ./proxysql-prepare.sql"

# query for different users
mysql -u root -h 127.0.0.1 -P 6034 -e "select * from test.tidb_server;"
mysql -u root1 -h 127.0.0.1 -P 6034 -e "select * from test.tidb_server;"
