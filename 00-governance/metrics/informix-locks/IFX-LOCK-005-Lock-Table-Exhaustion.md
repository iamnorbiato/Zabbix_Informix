# IFX-LOCK-005 — Lock Table Exhaustion Attempts

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

## Purpose

Measure attempts to exceed the configured Informix per-session lock limit.

## Source and SQL Contract

Database: `sysmaster`.

Authoritative source: `sysprofile` entry `ovlock`.

```sql
SELECT
    CAST(
        COALESCE(
            MAX(
                CASE
                    WHEN TRIM(name) = 'ovlock' THEN value
                END
            ),
            0
        ) AS INT8
    ) AS lock_table_exhaustion_attempts
FROM sysprofile;
```

The statement always returns one non-negative integer. `ovlock` is a cumulative engine profile counter.

## Runtime Contract

Statement: `01-statements/informix-locks/IFX-LOCK-005-Lock-Table-Exhaustion.sql`

Collector: `05-collectors/informix/locks/ifx-lock-table-exhaustion.ksh`

Launcher: `03-deployment/launchers/ifx-lock-005`

Zabbix Agent key: `ifx.lock.table_exhaustion_attempts`

Zabbix item: active Agent item, Numeric unsigned, unit `attempts`, interval `1m`.

Trigger: `change(/Template Zabbix Tailor Informix Health/ifx.lock.table_exhaustion_attempts)>0`, severity `High`, tag `informix: lock-005`.

The trigger opens only when `ovlock` increases and resolves on the next collection without another increment.

## Development Validation

The source shape (`name`, `value`), SQL statement, repository collector, installed launcher, Zabbix Agent key, Zabbix item, trigger definition, template export and install lifecycle returned and retained `0` in the Linux development topology.

Deliberately exhausting locks is excluded from development validation. Target Informix/AIX validation remains pending.
