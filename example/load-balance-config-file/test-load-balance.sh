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

mysql -u root -h 127.0.0.1 -P 4003 << EOF
DROP TABLE IF EXISTS test.test;
CREATE TABLE test.test (db VARCHAR(255));
INSERT INTO test.test (db) VALUES ('tidb-2');
EOF

# test load balance
mysql -u root -h 127.0.0.1 -P 6034 -t << EOF 
select * from test.test;
select * from test.test;
select * from test.test;
select * from test.test;
select * from test.test;
EOF
