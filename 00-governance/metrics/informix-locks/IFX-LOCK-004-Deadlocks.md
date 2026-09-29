# IFX-LOCK-004 — Deadlocks

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

## Purpose

Measure accumulated deadlocks recorded for currently open table profiles.

## Source and SQL Contract

Database: `sysmaster`.

Authoritative source: `sysptprof.deadlks`.

```sql
SELECT
    CAST(COALESCE(SUM(p.deadlks), 0) AS INT8) AS deadlocks
FROM sysptprof p;
```

The statement always returns one non-negative integer. The value is a cumulative profile counter.

## Runtime Contract

Statement: `01-statements/informix-locks/IFX-LOCK-004-Deadlocks.sql`

Collector: `05-collectors/informix/locks/ifx-lock-deadlocks.ksh`

Launcher: `03-deployment/launchers/ifx-lock-004`

Zabbix Agent key: `ifx.lock.deadlocks`

Zabbix item: active Agent item, Numeric unsigned, unit `deadlocks`, interval `1m`.

Trigger: `change(/Template Zabbix Tailor Informix Health/ifx.lock.deadlocks)>0`, severity `High`, tag `informix: lock-004`.

The trigger opens only on a new counter increment and resolves on the next collection without another increment.

## Development Validation

The source, SQL statement, repository collector, installed launcher, Zabbix Agent key, Zabbix item, trigger definition, template export and install lifecycle returned and retained `0` in the Linux development topology.

Target Informix/AIX validation and a safely controlled deadlock exercise remain pending.
