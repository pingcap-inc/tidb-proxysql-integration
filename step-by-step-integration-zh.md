# 手把手教你集成 TiDB 和 ProxySQL

此文档以 CentOS 7 为例，简单介绍 **_TiDB_** 与 **_ProxySQL_** 的集成方法，如果你有其他安装需求，可自行参阅以下链接：

- [TiDB 文档](https://docs.pingcap.com/)
- [TiDB 开发者文档](https://docs.pingcap.com/zh/tidb/stable/dev-guide-overview)
- [ProxySQL 官方文档](https://proxysql.com/documentation/)

## 1. 启动 TiDB

### 1.1 测试环境 - 源码编译启动

1. 下载 [TiDB](https://github.com/pingcap/tidb) 源码，进入 `tidb-server` 目录后，进行编译。

    ```sh
    git clone git@github.com:pingcap/tidb.git
    cd tidb/tidb-server
    go build
    ```

2. 随后，你可以使用配置文件 [tidb-config.toml](/tidb-config.toml) 来启动 TiDB。注意:

    - 此处使用 `unistore` 作为存储引擎，这是 TiDB 的测试存储引擎，请仅在测试时使用它。
    - `TIDB_SERVER_PATH`: 上一步中，使用 `go build` 编译的二进制文件位置，如你在 `/usr/local` 下进行上一步操作，那么此处的 `TIDB_SERVER_PATH` 应为：`/usr/local/tidb/tidb-server/tidb-server`
    - `LOCAL_TIDB_LOG`: 输出 TiDB 日志的位置

    ```sh
    ${TIDB_SERVER_PATH} -config ./tidb-config.toml -store unistore -path "" -lease 0s > ${LOCAL_TIDB_LOG} 2>&1 &
    ```

### 1.2 测试环境 - TiUP 启动

[TiUP](https://docs.pingcap.com/zh/tidb/stable/tiup-overview) 在 TiDB 中承担着包管理器的角色，管理着 TiDB 生态下众多的组件，如 TiDB、PD、TiKV 等。

1. 安装 TiUP

    ```sh
    curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
    ```

2. 启动测试环境 TiDB

    ```sh
    tiup playground
    ```

### 1.3 正式环境

正式环境相对测试环境会复杂许多，建议详阅[使用 TiUP 部署 TiDB 集群](https://docs.pingcap.com/zh/tidb/stable/production-deployment-using-tiup)一文，后根据硬件条件部署。

## 2. 启动 ProxySQL

### 2.1 yum 安装

1. 添加 RPM 仓库：

    ```sh
    cat <<EOF | tee /etc/yum.repos.d/proxysql.repo
    [proxysql_repo]
    name= ProxySQL YUM repository
    baseurl=https://repo.proxysql.com/ProxySQL/proxysql-2.1.x/centos/\$releasever
    gpgcheck=1
    gpgkey=https://repo.proxysql.com/ProxySQL/repo_pub_key
    EOF
    ```

2. 安装：

    ```sh
    yum install proxysql
    ```

3. 启动：

    ```sh
    systemctl start proxysql
    ```

### 2.2 其他安装

请参阅 ProxySQL 的 [Github 页面](https://github.com/sysown/proxysql#installation)或[官方文档](https://proxysql.com/documentation/)进行安装。

## 3. 配置 ProxySQL

我们需要将 ProxySQL 内的配置指向 TiDB，以此将 ProxySQL 作为 TiDB 的代理。此处将列举必需的配置项，其余配置项可参考 ProxySQL [官方文档](https://proxysql.com/documentation/)。

### 3.1 ProxySQL 配置的简单介绍

ProxySQL 使用一个单独的端口进行配置管理，另一个端口进行代理。我们把配置管理的入口，称为 **_ProxySQL Admin interface_**，把代理的入口，称为 **_ProxySQL Proxy interface_**。

- **_ProxySQL Admin interface_**: 读写权限用户仅可本地登录，无法开放远程登录。只读权限用户可远程登录。默认端口 `6032`。默认读写权限用户名 `admin`，密码 `admin`。默认只读权限用户名 `radmin`，密码 `radmin`。
- **_ProxySQL Proxy interface_**: 用于代理，将 SQL 转发到配置的服务中。

![proxysql config flow](/doc-assert/proxysql_config_flow.png)

ProxySQL 有三层配置：`runtime`、`memory`、`disk`。你仅能更改 `memory` 层的配置。在更改配置后，可以使用 `load xxx to runtime` 来生效这个配置，也可以使用 `save xxx to disk` 落盘，防止数据丢失。

![proxysql config layer](/doc-assert/proxysql_config_layer.png)

### 3.2 配置 TiDB 后端

在 ProxySQL 中添加 TiDB 后端，此处如果有多个 TiDB 后端，可以添加多条。请在 **_ProxySQL Admin interface_** 进行此操作：

```sql
insert into mysql_servers(hostgroup_id,hostname,port) values(0,'127.0.0.1',4000);
load mysql servers to runtime;
save mysql servers to disk;
```

字段解释：

- `hostgroup_id`: ProxySQL 是以 **hostgroup** 为单位管理后端服务的，可以将需要负载均衡的几个服务配置为同一个 hostgroup，这样 ProxySQL 将均匀的分发 SQL 到这些服务上。而在需要区分不同后端服务时（如读写分离场景等），可将其配置为不同的 hostgroup，以此配置不同的代理条件。
- `hostname`: 后端服务的 IP 或域名。
- `port`: 后端服务的端口。

### 3.3 配置 Proxy 登录账号

在 ProxySQL 中添加 TiDB 后端的登录账号。ProxySQL 将允许此账号来登录 **_ProxySQL Proxy interface_**，而且 ProxySQL 将以此创建与 TiDB 之间的连接，因此，请确保此账号在 TiDB 中拥有相应权限。请在 **_ProxySQL Admin interface_** 进行此操作：

```sql
insert into mysql_users(username,password,active,default_hostgroup,transaction_persistent) values('root','',1,0,1);
load mysql users to runtime;
save mysql users to disk;
```

字段解释：

- `username`: 用户名
- `password`: 密码
- `active`: 是否生效，`1` 为生效，`0` 为不生效，仅 `active = 1` 的用户可登录。
- `default_hostgroup`: 此账号默认使用的 **hostgroup**。
- `transaction_persistent`: 值为 `1` 时，表示事务持久化，即：当某连接使用该用户开启了一个事务后，那么在事务提交或回滚之前，
所有的语句都路由到同一个 **hostgroup** 中，避免语句分散到不同 **hostgroup**。

### 3.4 配置文件配置

除了使用 **_ProxySQL Admin interface_** 配置，也可以使用配置文件进行配置。[官方解释](https://github.com/sysown/proxysql#configuring-proxysql-through-the-config-file)中，配置文件仅应该被视为是一种辅助初始化的方式，而并非主要配置的手段。配置文件仅在 SQLite 数据库未被创建时读取，后续将不会继续读取配置文件。因此，使用配置文件配置时，你应进行 SQLite 数据库的删除，这将***丢失***你在 **_ProxySQL Admin interface_** 中对配置进行的更改：

```sh
rm /var/lib/proxysql/proxysql.db
```

配置文件的位置为 `/etc/proxysql.cnf`，我们将上方的必需配置翻译为配置文件方式，仅更改 `mysql_servers`、`mysql_users` 这两个配置节点，其余配置可自行查看 `/etc/proxysql.cnf`：

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

随后使用 `systemctl restart proxysql` 进行服务重启后即可生效，配置生效后将自动创建 SQLite 数据库，后续将不会再次读取配置文件。

### 3.5 其余配置项

仅以上配置为必需配置项，其余配置项并非必需。你可在 ProxySQL 文档中的 [Global Variables](https://proxysql.com/documentation/global-variables/) 一文中获取全部配置项名称及其作用。

## 4. 使用

### 4.1 MySQL Client 连接 ProxySQL

可运行:

```sh
mysql -u root -h 127.0.0.1 -P 6033 -e "SELECT VERSION()"
```

运行结果:

```sql
+--------------------+
| VERSION()          |
+--------------------+
| 5.7.25-TiDB-v6.1.0 |
+--------------------+
```

### 4.2 运行集成测试

如果你满足以下依赖项：

- 测试用例代码仓库 [tidb-test](https://github.com/pingcap/tidb-test) 的权限
- CentOS 7 机器（可为实体机或虚拟机，但不可为 Docker 容器，因为 ProxySQL 用到 `systemctl` 后台启动）
- 机器需连接网络
- Git
- Yum
- Golang SDK

那么你可以运行这两个脚本来运行集成测试：

```
./proxysql-initial.sh
./test.sh
```

在[集成测试文档](/README-zh.md)中有更多信息可供查看。

