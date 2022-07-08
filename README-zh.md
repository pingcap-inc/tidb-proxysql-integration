# TiDB 与 ProxySQL 的集成测试

[English](/README.md) | **_中文_**

如果你不需要进行集成测试，仅对集成方案感兴趣，可以阅读 [手把手教你集成 TiDB 和 ProxySQL](/step-by-step-integration-zh.md)。

## 目的

找出 [TiDB](https://docs.pingcap.com/tidb/stable/dev-guide-overview) 与 [ProxySQL](https://proxysql.com/) 使用时的不兼容特性。

## 搭建方案

使用 TiDB 当前集成测试流水线中的[测试用例](https://github.com/pingcap/tidb-test)。将 **TiDB 与 ProxySQL** 当成是**原生的 TiDB** 来测试。以此来找出特性不兼容的部分。

![build way](/doc-assert/test_build_way.png)

## 依赖

- 测试用例代码仓库 [tidb-test](https://github.com/pingcap/tidb-test) 的权限
- 测试机器需连接网络
- Golang SDK
- Git
- 以下两者其一：
    1. 本地启动（请在"运行"一节中使用[本地启动](#本地启动)）

        - CentOS 7 机器（可为实体机或虚拟机）
        - Yum
        
    2. Docker 启动（请在"运行"一节中使用[Docker 启动](#docker-启动)）

        - Docker
        - Docker Compose

## 运行

### 本地启动

1. 安装、启动、配置 ProxySQL：

```sh
./proxysql-initial.sh
```

2. 下载测试代码、编译测试程序、编译 TiDB 程序、运行测试用例：

```sh
./test-local.sh
```

### Docker 启动

使用 Docker Compose 启动并配置 ProxySQL 与 TiDB 的容器，运行测试用例：

```sh
./test-docker.sh
```

## 预期输出

[输出文件](/doc-assert/test.out)

## 已知不兼容特性

当前跳过了一些测试用例，见 [run-test.sh](https://github.com/Icemap/tidb-proxysql-integration-test/blob/main/run-test.sh#L12-L25)。

这是因为 TiDB 与 ProxySQL 的一些不兼容特性导致的（除 `legency` 标注的测试用例，这是为了和 CI 流水线中跳过的测试用例保持一致）：

- 涉及 `CREATE USER` 语句: TiDB 和 ProxySQL 使用不同的用户管理方式，TiDB 使用 `CREATE USER` 语句，而 ProxySQL 使用 admin interface (在另一个端口上)。
- 设置的排序方式与字符集不匹配时：TiDB 不报错，ProxySQL 报错。
    
    - 例如：`Error 1253: COLLATION 'latin1_bin' is not valid for CHARACTER SET 'utf8mb4'`

- ProxySQL 不支持 `LOAD STATS`、`LOAD DATA LOCAL INFILE` 等读取文件语句。
- 在列涉及二义性时：TiDB 不报错，ProxySQL 报错。

    - 例如：`Error 1052: Column 'a' in field list is ambiguous`