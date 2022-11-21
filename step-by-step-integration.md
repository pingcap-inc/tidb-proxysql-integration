# Integration TiDB with ProxySQL step by step

**_English_** | [中文](/step-by-step-integration-zh.md)

This document briefly describes how to integrate **_TiDB_** with **_ProxySQL_** using CentOS 7 as an example. If you have integration needs for other systems, check out the [Try Out](#4-try-out) section, which is an introduction to deploying a test integration environment using **_Docker_** and **_Docker Compose_**. You can also refer yourself to the following links for more information:

- [TiDB Documentation](https://docs.pingcap.com/)
- [TiDB Developer Guide](https://docs.pingcap.com/tidb/stable/dev-guide-overview)
- [ProxySQL Documentation](https://proxysql.com/documentation/)

## 1. Startup TiDB

### 1.1 Test Environment - Source compilation

1. Download [TiDB](https://github.com/pingcap/tidb) code, enter `tidb-server` folder and run `go build`.

    ```sh
    git clone git@github.com:pingcap/tidb.git
    cd tidb/tidb-server
    go build
    ```

2. Use the configuration file tidb-config.toml to start TiDB. Note that:
    - Use `unistore` as the storage engine, which is the test storage engine for TiDB, so please use it for testing only.
    - `TIDB_SERVER_PATH`: The location of the binary compiled with `go build` in the previous step. For example, if you did the previous step under `/usr/local`, then `TIDB_SERVER_PATH` should be: `/usr/local/tidb/tidb-server/tidb-server`.
    - `LOCAL_TIDB_LOG`: The location to export TiDB logs

    ```sh
    ${TIDB_SERVER_PATH} -config ./tidb-config.toml -store unistore -path "" -lease 0s > ${LOCAL_TIDB_LOG} 2>&1 &
    ```

### 1.2 Test Environment - TiUP startup

[TiUP](https://docs.pingcap.com/tidb/stable/tiup-overview), as the package manager, makes it far easier to manage different cluster components in the TiDB ecosystem.

1. Install TiUP

    ```sh
    curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
    ```

2. Test environment start TiDB

    ```sh
    tiup playground
    ```

### 1.3 Test Environment - TiDB Cloud Developer Tier

1. If you do not have a TiDB Cloud account, click [TiDB Cloud](https://tidbcloud.com/free-trial) to sign up for an account.
2. [Sign in](https://tidbcloud.com/) with your TiDB Cloud account.
3. To create a Developer Tier cluster for one year free, you can either select the **Developer Tier** plan on the [plan page](https://tidbcloud.com/console/plans) or click [Create a Cluster (Dev Tier)](https://tidbcloud.com/console/create-cluster?tier=dev).
4. On the **Create a Cluster (Dev Tier)** page, set up your cluster name, password, cloud provider (for now, only AWS is available for Developer Tier), and region (a nearby region is recommended). Then click **Create** to create your cluster.
5. Your TiDB Cloud cluster will be created in approximately 5 to 15 minutes. You can check the creation progress at [Active Clusters](https://tidbcloud.com/console/clusters).
6. After creating a cluster, on the **Active Clusters** page, click the name of your newly created cluster to navigate to the cluster control panel.

    ![active clusters](/doc-assert/tidb_cloud_1.png)

7. Click **Connect** to create a traffic filter (a list of client IPs allowed for TiDB connection).

    ![connect](/doc-assert/tidb_cloud_2.png)

8. In the popup window, click **Add Your Current IP Address** to fill in your current IP address, and then click **Create Filter** to create a traffic filter.
9. Copy the string to connect with a SQL client for later use.

    ![SQL string](/doc-assert/tidb_cloud_3.png)

### 1.4 Formal Environment - TiDB Cloud

We recommend using **TiDB Cloud** directly when you need hosting TiDB services (e.g., you can't manage it yourself, or you need a cloud-native environment, etc.) You can check out [TiDB Cloud - Create a TiDB Cluster](https://docs.pingcap.com/tidbcloud/create-tidb-cluster) to get a TiDB cluster in TiDB Cloud for a formal environment.

### 1.5 Formal Environment - Local Deploy

The formal environment is much more complex than the test environment, so we recommend reading the article [Deploy a TiDB Cluster Using TiUP](https://docs.pingcap.com/tidb/stable/production-deployment-using-tiup) and then deploying it based on hardware conditions.

## 2. Startup ProxySQL

### 2.1 Install by YUM

1. Adding repository:

    ```sh
    cat > /etc/yum.repos.d/proxysql.repo << EOF
    [proxysql]
    name=ProxySQL YUM repository
    baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.4.x/centos/\$releasever
    gpgcheck=1
    gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-2.4.x/repo_pub_key
    EOF
    ```

2. Install:

    ```sh
    yum install proxysql
    ```

3. Startup:

    ```sh
    systemctl start proxysql
    ```

### 2.2 Other

Please read [ProxySQL Github page](https://github.com/sysown/proxysql#installation) or the [official documentation](https://proxysql.com/documentation/) for installation.

## 3. ProxySQL Configuration

We need to write the host of TiDB in the ProxySQL configuration to use it as a proxy for TiDB. The required configuration items are listed below and the rest of the configuration items can be found in the ProxySQL [official documentation](https://proxysql.com/documentation/).

### 3.1 Simple Introduction to ProxySQL Configuration

ProxySQL uses a separate port for configuration management and another port for proxying. We call the entry point for configuration management **_ProxySQL Admin interface_** and the entry point for proxying **_ProxySQL MySQL interface_**.

- **_ProxySQL Admin interface_**: It is possible to connect to the admin interface either using a user with `admin` privileges to read and write configuration or a user with `stats` privileges that can only read certain statistics (no read or write configuration). The default credentials are `admin:admin` and `stats:stats`, but for security reasons, it is possible to connect locally using the default credentials. To connect remotely a new user needs to configure it, and often it is named `radmin`.
- **_ProxySQL MySQL interface_**: Used as a proxy to forward SQL to the configured service.

![proxysql config flow](/doc-assert/proxysql_config_flow.png)

ProxySQL has three layers of configuration: `runtime`, `memory`, and `disk`. You can change the configuration of the `memory` layer only. After changing the configuration, you can use `load xxx to runtime` to make the configuration effective, and/or you can use `save xxx to disk` to save to the disk to prevent configuation loss.

![proxysql config layer](/doc-assert/proxysql_config_layer.png)

### 3.2 Configure TiDB Server

Add TiDB backend in ProxySQL, you can add multiple TiDB backends if you have more than one. Please do this at **_ProxySQL Admin interface_**:

```sql
insert into mysql_servers(hostgroup_id,hostname,port) values(0,'127.0.0.1',4000);
load mysql servers to runtime;
save mysql servers to disk;
```

Field Explanation:

- `hostgroup_id`: ProxySQL manages backend services by **hostgroup**, you can configure several services that need load balancing as the same hostgroup, so that ProxySQL will distribute SQL to these services evenly. And when you need to distinguish different backend services (such as read/write splitting scenario), you can configure them as different hostgroups.
- `hostname`: IP or domain of the backend service.
- `port`: The port of the backend service.

### 3.3 Configure Proxy Login User

Add a TiDB backend login user to ProxySQL. ProxySQL will allow this account to login **_ProxySQL MySQL interface_** and ProxySQL will use it to create a connection to TiDB, so make sure this account has the appropriate permissions in TiDB. Please do this at **_ProxySQL Admin interface_**:

```sql
insert into mysql_users(username,password,active,default_hostgroup,transaction_persistent) values('root','',1,0,1);
load mysql users to runtime;
save mysql users to disk;
```

Field Explanation:

- `username`: username
- `password`: password
- `active`: `1` is active, `0` is inactive, only the `active = 1` user can login.
- `default_hostgroup`: This user default **hostgroup**, where its traffic will be sent unless query rules route the traffic to a different hostgroup.
- `transaction_persistent`: A value of `1` indicates transaction persistence, i.e., when a connection opens a transaction using this user, then until the transaction is committed or rolled back, 
All statements are routed to the same **hostgroup**.

### 3.4 Configure by Config File

In addition to configuration using **_ProxySQL Admin interface_**, configuration files can also be used for configuration. In [Official Explanation](https://github.com/sysown/proxysql#configuring-proxysql-through-the-config-file), the configuration file should only be considered as a secondary way of initialization and not as the primary way of configuration. The configuration file is only read when the SQLite database is not created and the configuration file will not continue to be read subsequently. Therefore, when using the config file, you should delete the SQLite database. It will ***LOSE*** the changes you made to the configuration in **_ProxySQL Admin interface_**:

```sh
rm /var/lib/proxysql/proxysql.db
```

Alternatively, it is also possible to run `LOAD xxx FROM CONFIG` to override the current in-memory configuration with the configuration on config file.

The config file is located at `/etc/proxysql.cnf`, we will translate the above required configuration to the config file way, only change `mysql_servers`, `mysql_users` two nodes, the rest of the configuration items can check `/etc/proxysql.cnf`:

```
mysql_servers =
 (
 	{
 		address="127.0.0.1"
 		port=4000
 		hostgroup=0
 		max_connections=2000
 	}
 )

mysql_users:
 (
    {
 		username = "root"
        password = ""
 		default_hostgroup = 0
 		max_connections = 1000
 		default_schema = "test"
 		active = 1
		transaction_persistent = 1
 	}
 )
```

Then use `systemctl restart proxysql` to restart the service and it will take effect. The SQLite database will be created automatically after the config file takes effect and the config file will not be read again.

### 3.5 Other Config Items

The above config items are required. You can get all the config items' names and their roles in the [Global Variables](https://proxysql.com/documentation/global-variables/) article in the ProxySQL documentation.
## 4. Try Out

You can use Docker and Docker Compose for quick start. Make sure the ports `4000` and `6033` are free.

```sh
docker-compose up -d
```

This has completed the startup of an integrated TiDB and ProxySQL environment, which will start two containers. ***DO NOT*** use it to create  in a production environment. You can connect to the port `6033` (ProxySQL) using the username `root` and an empty password. The container specific configuration can be found in [docker-compose.yaml](/docker-compose.yaml) and the ProxySQL specific configuration can be found in [proxysql-docker.cnf](/proxysql-docker.cnf).

## 5. Use

### 5.1 MySQL Client Connect ProxySQL

Run:

```sh
mysql -u root -h 127.0.0.1 -P 6033 -e "SELECT VERSION()"
```

Result:

```sql
+--------------------+
| VERSION()          |
+--------------------+
| 5.7.25-TiDB-v6.1.0 |
+--------------------+
```

### 5.2 Run Integration Test

If you satisfy the following dependencies:

- Permissions for the [tidb-test](https://github.com/pingcap/tidb-test) code repository tidb-test
- The machine needs to be connected to the network
- Golang SDK
- Git
- One of the following:

    1. Local Startup

        - CentOS 7 machine (can be a physical or virtual machine)
        - Yum

    2. Docker Startup

        - Docker
        - Docker Compose

Then you can run locally: `. /proxysql-initial.sh && . /test-local.sh` or use Docker: `. /test-docker.sh` to run integration tests.

There is more information available in the [integration test documentation](/README.md).


### 5.3 Example of Load Balancing - Admin Interface

#### 5.3.1 Operation Steps

Use **_ProxySQL Admin Interface_** to configure a load balancing traffic as an example. The example will do:

1. Start 3 TiDB containers through **Docker Compose**, all the  ports in the container are `4000`, and mapped to host ports `4001`, `4002`, `4003`.
2. Start one container of ProxySQL through **Docker Compose**, the port `6033` in the container is for **_ProxySQL MySQL Interface_**, and mapped host port 6034. The **_ProxySQL Admin Interface_** port is not exposed because it can only log in locally (i.e., inside the container).
3. Within the 3 TiDB instances, create the same table structure but write different data: `'tidb-server01-port-4001'`, `'tidb-server02-port-4002'`, and `'tidb-server03-port-4003'`, in order to distinguish between the different database instances.
4. Use the `docker-compose exec` command to run the prepared SQL file for configuring ProxySQL in **_ProxySQL Admin Interface_**, this SQL file will run:

    1. Add 3 TiDB backend hosts with `hostgroup_id` of `0`.
    2. Take effect the TiDB backend configuration and save it on disk.
    3. Add user `root` with an empty password and `default_hostgroup` as `0`, corresponding to the TiDB backend `hostgroup_id` above.
    4. Take effect the user configuration and save it on disk.

5. Log in to **_ProxySQL MySQL Interface_** with the `root` user and query 5 times, expecting three different returns: `'tidb-server01-port-4001'`, `'tidb-server02-port-4002'`, and `'tidb-server03-port-4003'`.
6. Stop and clear Docker Compose started resources, such as: containers and network topologies.


#### 5.3.2 Run

Dependencies:

- Docker
- Docker Compose
- MySQL Client

```sh
cd example/load-balance-admin-interface/
./test-load-balance.sh
```

#### 5.3.3 Expect Output

Because of load balancing, it is expected that the output will have three different results: `'tidb-server01-port-4001'`, `'tidb-server02-port-4002'`, and `'tidb-server03-port-4003'`. But the exact order cannot be expected. One of the expected outputs is:


```
# ./test-load-balance.sh
Creating network "load-balance-admin-interface_default" with the default driver
Creating load-balance-admin-interface_tidb-server03_1 ... done
Creating load-balance-admin-interface_tidb-server02_1 ... done
Creating load-balance-admin-interface_tidb-server01_1 ... done
Creating load-balance-admin-interface_proxysql_1      ... done
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server03-port-4003 |
+-------------------------+
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server01-port-4001 |
+-------------------------+
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server02-port-4002 |
+-------------------------+
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server02-port-4002 |
+-------------------------+
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server02-port-4002 |
+-------------------------+
Stopping load-balance-admin-interface_proxysql_1      ... done
Stopping load-balance-admin-interface_tidb-server03_1 ... done
Stopping load-balance-admin-interface_tidb-server01_1 ... done
Stopping load-balance-admin-interface_tidb-server02_1 ... done
Removing load-balance-admin-interface_proxysql_1      ... done
Removing load-balance-admin-interface_tidb-server03_1 ... done
Removing load-balance-admin-interface_tidb-server01_1 ... done
Removing load-balance-admin-interface_tidb-server02_1 ... done
Removing network load-balance-admin-interface_default
```

### 5.4 Example of User Split - Admin Interface

#### 5.4.1 Operation Steps

Use **_ProxySQL Admin Interface_** to configure a user split traffic as an example. The different users will use their own TiDB backend. The example will do:

1. Start 2 TiDB containers through **Docker Compose**,  all the ports in the container are `4000`, and mapped to host ports `4001` and `4002`.
2. Start one container of ProxySQL through **Docker Compose**, the port `6033` in the container is for **_ProxySQL MySQL Interface_**, and mapped host port 6034. The **_ProxySQL Admin Interface_** port is not exposed because it can only log in locally (i.e., inside the container).
3. Within the 2 TiDB instances, create the same table structure but write different data: `'tidb-server01-port-4001'`, `'tidb-server02-port-4002'`, in order to distinguish between the different database instances.
4. Use the `docker-compose exec` command to run the prepared SQL file for configuring ProxySQL in **_ProxySQL Admin Interface_**, this SQL file will run:

    1. Add 2 TiDB backend hosts. `hostgroup_id` of `tidb-server01` is `0`, and `hostgroup_id` of `tidb-server02` is `1`.
    2. Take effect the TiDB backend configuration and save it on disk.
    3. Add user `root` with an empty password and `default_hostgroup` as `0`. It means that the SQL will default route to `tidb-server01`.
    4. Add user `root1` with an empty password and `default_hostgroup` as `1`. It means that the SQL will default route to `tidb-server02`.
    5. Take effect the user configuration and save it on disk.

5. Log in to **_ProxySQL MySQL Interface_** with the `root` user and `root1` user. The expected return is `'tidb-server01'` and `'tidb-server02'`.
6. Stop and clear Docker Compose started resources, such as: containers and network topologies.

#### 5.4.2 Run

Dependencies:

- Docker
- Docker Compose
- MySQL Client

```sh
cd example/user-split-admin-interface/
./test-user-split.sh
```

#### 5.4.3 Expect Output

```
# ./test-user-split.sh 
Creating network "user-split-admin-interface_default" with the default driver
Creating user-split-admin-interface_tidb-server01_1 ... done
Creating user-split-admin-interface_tidb-server02_1 ... done
Creating user-split-admin-interface_proxysql_1      ... done
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server01-port-4001 |
+-------------------------+
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server02-port-4002 |
+-------------------------+
Stopping user-split-admin-interface_proxysql_1      ... done
Stopping user-split-admin-interface_tidb-server02_1 ... done
Stopping user-split-admin-interface_tidb-server01_1 ... done
Removing user-split-admin-interface_proxysql_1      ... done
Removing user-split-admin-interface_tidb-server02_1 ... done
Removing user-split-admin-interface_tidb-server01_1 ... done
Removing network user-split-admin-interface_default
```

### 5.5 Example of Proxy Rules - Admin Interface

#### 5.5.1 Operation Steps

Use **_ProxySQL Admin Interface_** to configure a common read/write separation traffic as an example. It will use the rules to match the SQL that will be run, thus forwarding the read and write SQL to different TiDB backends (if neither match, the user's `default_hostgroup` will be used). The example will do:

1. Start 2 TiDB containers through **Docker Compose**, all the ports in the container are `4000`, and mapped to host ports `4001` and `4002`.
2. Start one container of ProxySQL through **Docker Compose**, the port `6033` in the container is for **_ProxySQL MySQL Interface_**, and mapped host port 6034. The **_ProxySQL Admin Interface_** port is not exposed because it can only log in locally (i.e., inside the container).
3. Within the 2 TiDB instances, create the same table structure but write different data: `'tidb-server01-port-4001'`， `'tidb-server02-port-4002'`, in order to distinguish between the different database instances.
4. Use the `docker-compose exec` command to run the prepared SQL file for configuring ProxySQL in **_ProxySQL Admin Interface_**, this SQL file will run:

    1. Add 2 TiDB backend hosts. `hostgroup_id` of `tidb-server01` is `0`, and `hostgroup_id` of `tidb-server02` is `1`.
    2. Take effect the TiDB backend configuration and save it on disk.
    3. Add user `root` with an empty password and `default_hostgroup` as `0`. It means that the SQL will default route to `tidb-server01`.
    4. Take effect the user configuration and save it on disk.
    5. Add the rule `^SELECT.*FOR UPDATE$` with `rule_id` as `1` and `destination_hostgroup` as `0`. It means if SQL statements match this rule, it will be using the TiDB with `hostgroup` as `0` (this rule is for forwarding `SELECT ... FOR UPDATE` statement to the database where it is written).
    6. Add the rule `^SELECT` with `rule_id` as `2` and `destination_hostgroup` as `1`. It means if SQL statements match this rule, it will be using the TiDB with `hostgroup` as `1`.
    7. Take effect the rule configuration and save it on disk.

> **Note:**
> 
> About the matching rules:
> 
> - ProxySQL will try to match the rules one by one in the order of `rule_id` from smallest to largest.
> - `^` matches the beginning of the SQL statement, `$` matches the end.
> - `match_digest` is to match the parameterized SQL statement, see [query_processor_regex](https://proxysql.com/documentation/global-variables/mysql-variables/#mysql-query_processor_regex).
> - Important parameters:
> 
>   - `digest`: Match the parameterized hash value.
>   - `match_pattern`: Match the raw SQL statements.
>   - `negate_match_pattern`: When value is `1`, inverse the match for `match_digest` or `match_pattern`.
>   - `log`: Whether log the query.
>   - `replace_pattern`: If it is not empty, the value of this field will be replaced by the content of the matched part of SQL.
> 
> - See [mysql_query_rules](https://proxysql.com/documentation/main-runtime/#mysql_query_rules) for full parameters.

5. Log in to **_ProxySQL MySQL Interface_** with the `root`, and run:

    - `select * from test.tidb_server;`: Expect to match rules with `rule_id` of `2`. Forwarded to the TiDB backend `tidb-server02` with `hostgroup` of `1`.
    - `select * from test.tidb_server for update;`: Expect to match rules with `rule_id` of `1`. Forwarded to the TiDB backend `tidb-server01` with `hostgroup` of `0`.
    - `begin;insert into test.tidb_server (server_name) values ('insert this and rollback later'); select * from test.tidb_server; rollback;`: The `insert` statement is expected to not match all rules. It will use the `default_hostgroup` of the user (It is `0`) and thus forward to the TiDB backend `tidb-server01`(`hostgroup` is `0`). And ProxySQL turns on user `transaction_persistent` by default, this will cause all statements within the same transaction to run in the same `hostgroup`. So `select * from test.test;` will also be forwarded to the TiDB backend `tidb-server01`(`hostgroup` is `0`).

6. Stop and clear Docker Compose started resources, such as: containers and network topologies.

#### 5.5.2 Run

Dependencies:

- Docker
- Docker Compose
- MySQL Client

```sh
cd example/proxy-rule-admin-interface/
./proxy-rule-split.sh
```

#### 5.5.3 Expect Output

```
# ./proxy-rule-split.sh 
Creating network "proxy-rule-admin-interface_default" with the default driver
Creating proxy-rule-admin-interface_tidb-server01_1 ... done
Creating proxy-rule-admin-interface_tidb-server02_1 ... done
Creating proxy-rule-admin-interface_proxysql_1      ... done
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server02-port-4002 |
+-------------------------+
+-------------------------+
| server_name             |
+-------------------------+
| tidb-server01-port-4001 |
+-------------------------+
+--------------------------------+
| server_name                    |
+--------------------------------+
| tidb-server01-port-4001        |
| insert this and rollback later |
+--------------------------------+
Stopping proxy-rule-admin-interface_proxysql_1      ... done
Stopping proxy-rule-admin-interface_tidb-server01_1 ... done
Stopping proxy-rule-admin-interface_tidb-server02_1 ... done
Removing proxy-rule-admin-interface_proxysql_1      ... done
Removing proxy-rule-admin-interface_tidb-server01_1 ... done
Removing proxy-rule-admin-interface_tidb-server02_1 ... done
Removing network proxy-rule-admin-interface_default
```

### 5.6 Example of Load Balancing - Config File

Use config file to configure a load balancing traffic as an example. Achieves the same as [5.3 Example of Load Balancing - Admin Interface](#53-example-of-load-balancing---admin-interface), only changed using config file to initializing the ProxySQL configuration.

> **Note:**
>
> - The configuration of **ProxySQL** is stored in **SQLite**. Config file is only read when **SQLite** database does not exist.
> - ProxySQL does **_NOT_** recommend using config file for configuration changes, use them only for initial configuration, do not rely too much on configuration files.

**Run**

```sh
cd example/load-balance-config-file/
./test-load-balance.sh
```