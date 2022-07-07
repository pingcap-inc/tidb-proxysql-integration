# TiDB With ProxySQL Integration Test

**_English_** | [中文](/README-zh.md)

## Objective

Figure out the incompatible features of [TiDB](https://docs.pingcap.com/tidb/stable/dev-guide-overview) when used with [ProxySQL](https://proxysql.com/).

## Build Solution

Use the [test case](https://github.com/pingcap/tidb-test/tree/master/mysql_test), which is also used in TiDB's CI pipeline. In this test case, I'm trying to treat **ProxySQL with TiDB** as **pure TiDB** to figure out the incompatible features.

![build way](/doc-assert/test_build_way.png)

## Dependency

- Permissions for the [tidb-test](https://github.com/pingcap/tidb-test) code repository tidb-test
- The machine needs to be connected to the network
- Golang SDK
- Git
- One of the following:

    1. Local Startup (Please use [Local Startup](#local-startup) in the "Run" section.)

        - CentOS 7 machine (can be a physical or virtual machine)
        - Yum

    2. Docker Startup (Please use [Docker Startup](#docker-startup) in the "Run" section.)

        - Docker
        - Docker Compose

## Run

### Local Startup

1. Installation, startup, configuration **_ProxySQL_**:

```sh
./proxysql-initial.sh
```

2. Download test code, compile test programs, compile TiDB programs, run test cases：

```sh
./test-local.sh
```

### Docker Startup

Use Docker Compose to start and configure a container of ProxySQL with TiDB, and run the test case:

```sh
./test-docker.sh
```

## Expected output

[Output File](/doc-assert/test.out)

## Incompatible features

Some test cases are skipped, see [run-test.sh](https://github.com/Icemap/tidb-proxysql-integration-test/blob/main/run-test.sh#L12-L25).

This is caused by some incompatible features between **_TiDB_** and **_ProxySQL_** (except for the test cases marked with `legency`, which are consistent with the test cases skipped in the CI flow):

- Related to the `CREATE USER` statement: TiDB and ProxySQL use different user management methods, TiDB uses the `CREATE USER` statement and ProxySQL uses the admin interface (on a different port).
- When the set `COLLATION` does not match the `CHARACTER SET`: TiDB doesn't report an error, but ProxySQL does.
    
    - e.g.: `Error 1253: COLLATION 'latin1_bin' is not valid for CHARACTER SET 'utf8mb4'`

- ProxySQL does not support `LOAD STATS`, `LOAD DATA LOCAL INFILE`, and other load file statements.
- When column is ambiguous：TiDB doesn't report an error, but ProxySQL does.

    - e.g.: `Error 1052: Column 'a' in field list is ambiguous`