#!/bin/sh

CURRENT_PATH=`pwd`
TEST_PATH=${CURRENT_PATH}/tidb-test/mysql_test
TIDB_PATH=${CURRENT_PATH}/tidb
TIDB_SERVER_PATH=${TIDB_PATH}/tidb-server

# Sync `tidb-test` and `tidb` repo
git submodule init
git submodule update

# TiDB build
LOCAL_TIDB_LOG="local_tidb_proxysql.log"
cd ${TIDB_SERVER_PATH}
go build
cd ${CURRENT_PATH}

TIDB_SERVER_PATH=${TIDB_SERVER_PATH}/tidb-server
TIDB_CONFIG_PATH=${CURRENT_PATH}/tidb-config.toml

# TiDB run
echo "starting tidb-servers, log file: ${LOCAL_TIDB_LOG}"
${TIDB_SERVER_PATH} -config ${TIDB_CONFIG_PATH} -store unistore -path "" -lease 0s > ${LOCAL_TIDB_LOG} 2>&1 &
SERVER_PID=$!
sleep 5
echo "tidb-server(PID: ${SERVER_PID}) started"
trap 'kill ${SERVER_PID}' EXIT

./run-test.sh