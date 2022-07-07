# TiDB With ProxySQL Integration Test

**_English_** | [中文](/README-zh.md)

## Objective

Figure out the incompatible features of [TiDB](https://docs.pingcap.com/tidb/stable/dev-guide-overview) when used with [ProxySQL](https://proxysql.com/).

## Build Solution

Use the [test case](https://github.com/pingcap/tidb-test/tree/master/mysql_test), which is also used in TiDB's CI pipeline. In this test case, I'm trying to treat **ProxySQL with TiDB** as **pure TiDB** to figure out the incompatible features.

![build way](/doc-assert/test_build_way.png)

## Dependency

- Permissions for the [tidb-test](https://github.com/pingcap/tidb-test) code repository tidb-test
- CentOS 7 machine (can be a physical or virtual machine, but not a Docker container, because ProxySQL uses `systemctl` to start in the background)
- The machine needs to be connected to the network
- Git
- Yum
- Golang SDK

## Run

1. Installation, startup, configuration **_ProxySQL_**:

```sh
./proxysql-initial.sh
```

2. Download test code, compile test programs, compile TiDB programs, run test cases：

```sh
./test.sh
```

## Expected output

[Output File](/doc-assert/test.out)

## Incompatible features

Some test cases are skipped, see [test.sh](https://github.com/Icemap/tidb-proxysql-integration-test/blob/main/test.sh#L34-L47).

This is caused by some incompatible features between **_TiDB_** and **_ProxySQL_** (except for the test cases marked with `legency`, which are consistent with the test cases skipped in the CI flow):

- Related to the `CREATE USER` statement: TiDB and ProxySQL use different user management methods, TiDB uses the `CREATE USER` statement and ProxySQL uses the admin interface (on a different port).
- When the set `COLLATION` does not match the `CHARACTER SET`: TiDB doesn't report an error, but ProxySQL does.
    
    - e.g.: `Error 1253: COLLATION 'latin1_bin' is not valid for CHARACTER SET 'utf8mb4'`

- ProxySQL does not support `LOAD STATS`, `LOAD DATA LOCAL INFILE`, and other load file statements.
- When column is ambiguous：TiDB doesn't report an error, but ProxySQL does.

    - e.g.: `Error 1052: Column 'a' in field list is ambiguous`