# IFX-LOCK-002 — Lock Waits

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

## Purpose

Measure the cumulative number of lock waits recorded for currently open table profiles.

## Source and SQL Contract

Database: `sysmaster`.

Authoritative source: `sysptprof.lockwts`.

```sql
SELECT
    CAST(COALESCE(SUM(p.lockwts), 0) AS INT8) AS lock_waits
FROM sysptprof p;
```

The statement always returns one non-negative integer. The source is an in-memory cumulative profile whose rows exist while their tables are open; it is not a permanent historical counter.

## Runtime Contract

Statement: `01-statements/informix-locks/IFX-LOCK-002-Lock-Waits.sql`

Collector: `05-collectors/informix/locks/ifx-lock-waits.ksh`

Launcher: `03-deployment/launchers/ifx-lock-002`

Zabbix Agent key: `ifx.lock.waits`

Zabbix item: active Agent item, Numeric unsigned, unit `waits`, interval `1m`.

No trigger is configured. A lock wait is not necessarily an incident; operational baselines must define any rate-based alert.

## Development Validation

The controlled lock exercise on `tailor:zbx_ifx_session_test_lock` increased the source from `2` to `3`. The SQL statement, repository collector, installed launcher, Zabbix Agent key, Zabbix item, template export and install lifecycle were validated in the Linux development topology.

Target Informix/AIX validation remains pending.
