# IFX-LOCK-003 — Lock Timeouts

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

## Purpose

Measure the cumulative number of lock timeouts recorded for currently open table profiles.

## Source and SQL Contract

Database: `sysmaster`.

Authoritative source: `sysptprof.lktouts`.

```sql
SELECT
    CAST(COALESCE(SUM(p.lktouts), 0) AS INT8) AS lock_timeouts
FROM sysptprof p;
```

The statement always returns one non-negative integer. The source is cumulative and profile-scoped while tables remain open.

## Runtime Contract

Statement: `01-statements/informix-locks/IFX-LOCK-003-Lock-Timeouts.sql`

Collector: `05-collectors/informix/locks/ifx-lock-timeouts.ksh`

Launcher: `03-deployment/launchers/ifx-lock-003`

Zabbix Agent key: `ifx.lock.timeouts`

Zabbix item: active Agent item, Numeric unsigned, unit `timeouts`, interval `1m`.

No trigger is configured. A rate/increment policy remains an operational decision.

## Development Validation

The source, SQL statement, repository collector, installed launcher, Zabbix Agent key, Zabbix item, template export and install lifecycle returned and retained `0` in the Linux development topology.

Target Informix/AIX validation and a safely controlled timeout exercise remain pending.
