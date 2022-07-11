#!/bin/sh

# start and stop
docker-compose up -d
trap 'docker-compose down' EXIT

# waiting for all containers runs well

sleep 5

# prepare data
mysql -u root -h 127.0.0.1 -P 4001 << EOF
DROP TABLE IF EXISTS test.test;
CREATE TABLE test.test (db VARCHAR(255));
INSERT INTO test.test (db) VALUES ('tidb-0');
EOF

mysql -u root -h 127.0.0.1 -P 4002 << EOF
DROP TABLE IF EXISTS test.test;
CREATE TABLE test.test (db VARCHAR(255));
INSERT INTO test.test (db) VALUES ('tidb-1');
EOF

# using admin interface to configure
docker-compose exec proxysql sh -c "mysql -uadmin -padmin -h127.0.0.1 -P6032 < ./proxysql-prepare.sql"

# query for different users
mysql -u root -h 127.0.0.1 -P 6034 -e "select * from test.test;"
mysql -u root -h 127.0.0.1 -P 6034 -e "select * from test.test for update;"
mysql -u root -h 127.0.0.1 -P 6034 -e "begin;insert into test.test (db) values ('insert this and rollback later'); select * from test.test; rollback;"
