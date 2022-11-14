#!/bin/sh

# start and stop
docker-compose up -d
# trap 'docker-compose down' EXIT

# waiting for all containers runs well

sleep 5

docker-compose exec proxysql sh -c "mysql -uadmin -padmin -h127.0.0.1 -P6032 < ./proxysql-prepare.sql"

docker-compose restart

mycli -u 'HZ5E7ifaDEjJTsh.root' -h 127.0.0.1 -P 16033 -D test --ssl-ca=/etc/ssl/certs/ca-certificates.crt --ssl-verify-server-cert