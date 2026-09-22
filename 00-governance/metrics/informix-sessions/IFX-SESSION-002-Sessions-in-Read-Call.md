# IFX-SESSION-002 — Sessions in Read Call

## 1. Purpose

This document defines the engineering contract for:

`IFX-SESSION-002 — Sessions in Read Call`

The metric counts qualifying client sessions whose `syssessions.state` bitmask
contains the documented `0x00000020` flag: `In a read call`.

It is not a measure of SQL statements executing, CPU consumption, runnable
threads, or generic business workload.

---

## 2. Monitoring Domain

Domain: `Connections, Sessions and Concurrency`

Metric ID: `IFX-SESSION-002`

Metric name: `Sessions in Read Call`

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

---

## 3. Monitoring Objective

The metric provides a narrow, source-backed view of client sessions observed by
Informix while the server is reading a client call.

It supports correlation with:

- total connected client sessions (IFX-SESSION-001);
- client wait conditions (IFX-SESSION-004 and IFX-SESSION-005);
- lock contention;
- workload and connection-pattern investigations.

---

## 4. Authoritative Development Source

Database: `sysmaster`

Table: `syssessions`

Column: `state`

The documented bit value `32` (`0x00000020`) means `In a read call`.
The `state` column is a bitmask; the source predicate must therefore use
`BITAND(state, 32) = 32`.

---

## 5. Approved Semantic

One qualifying session is counted when all conditions below are true:

1. its `hostname` is non-empty;
2. it is not the collector query session;
3. its `state` bitmask contains flag `32`;
4. it is not the Informix logical-log archive process (`ontape`).

The metric does not classify a session as active. The historical name `Active
Sessions` is retired for IFX-SESSION-002.

---

## 6. Authoritative SQL Contract

```sql
SELECT
    CAST(COUNT(*) AS INT8) AS sessions_in_read_call
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND BITAND(s.state, 32) = 32
  AND (
      s.feprogram IS NULL
      OR TRIM(s.feprogram) NOT MATCHES '*ontape*'
  );
```

The runtime statement file must contain only the `SELECT`; isolation is set by
the common Informix query library.

---

## 7. Internal and Collector Scope

`hostname` excludes engine-only user-thread rows that have no client host.

The query excludes its own `DBINFO('sessionid')` session so collection does not
count itself. `ontape` is excluded because it is an Informix service process,
not a client interaction.

No other client program is excluded by name.

---

## 8. Metric Type and Unit

Type: `GAUGE`

Unit: `SESSIONS`

Each successful sample is an instantaneous count and can increase or decrease
between collections.

---

## 9. Value and Zero Semantics

The normalized output is exactly one non-negative integer.

```text
0
```

is a valid successful observation: no qualifying client session was observed
in a read call at that instant.

Failure, malformed output, or multiple scalar values must fail collection and
must never become `0`.

---

## 10. Relationship with Other Session Metrics

IFX-SESSION-002 is not equivalent to IFX-SESSION-001, IFX-SESSION-004, or
IFX-SESSION-005.

In particular, it shall not enforce:

```text
IFX-SESSION-002 <= IFX-SESSION-001
```

as a parser invariant. The metrics can be observed at different instants and
use intentionally different filters.

---

## 11. Collection and Zabbix Contract

Collection method: SQL scalar statement through the common Informix collector
library.

Zabbix type: active Agent item.

Zabbix value type: Numeric (unsigned).

Discovery: No.

Development interval: one minute.

No direct trigger is defined initially. The metric is contextual until an
operational baseline establishes a useful alert condition.

---

## 12. Runtime Validation

The Linux development topology validated:

1. the approved `sysmaster:syssessions` SQL query in DBeaver, returning `0`;
2. the versioned SQL statement through `ifx_db_execute`, returning `0|`;
3. the strict scalar collector, returning `0`;
4. the installed launcher executed as user `zabbix`, returning `0`;
5. the Zabbix Agent active key `ifx.session.in_read_call`, returning `0`;
6. the active Zabbix template item with Numeric (unsigned), unit `sessions`, one-minute interval, and 30-second timeout;
7. the exported template definition;
8. uninstall/reinstall lifecycle, including removal and restoration of the launcher and Agent configuration.

Target Informix/AIX validation remains pending.