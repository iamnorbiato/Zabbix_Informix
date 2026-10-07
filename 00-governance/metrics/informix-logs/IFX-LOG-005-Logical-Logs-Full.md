# IFX-LOG-005 — Logical Logs Full

**Status atual:** `DEFINED` — fonte e semântica definidas; implementação runtime ainda pendente.

## 1. Purpose

This document defines the engineering contract for:

`IFX-LOG-005 — Logical Logs Full`

The metric counts logical logs whose used space is greater than or equal to their configured size.

Lifecycle: `SOURCE_VALIDATED`

---

## 2. Monitoring Domain

Domain: `Logical Logs, Physical Log and Backup`

Metric type: `GAUGE`

Unit: `LOGS`

Scope: one Informix instance.

---

## 3. Authoritative Development Source

Database: `sysmaster`

Primary table: `syslogs`

A logical log is treated as full when `used >= size`.

---

## 4. Approved SQL Contract

```sql
SELECT
    CAST(SUM(CASE WHEN used >= size THEN 1 ELSE 0 END) AS INT) AS logical_logs_full
FROM syslogs;
```

The query must return exactly one non-negative integer scalar value.

---

## 5. Scope and Semantics

The metric counts full logical-log files. It is not a percentage and does not identify the reason why a log cannot be reused.

`0` is a valid successful observation: no logical log is currently full.

A positive value indicates pressure and must be correlated with LOG-001, LOG-002, and LOG-003 before operational diagnosis.

Missing rows, malformed output, connection failure, query failure, or permission failure is not zero and must fail collection.

---

## 6. Trigger Policy

Initial trigger policy: `>0` opens a `HIGH` problem.

The event resolves automatically when the next valid value returns to `0`.

This is intentionally stricter than the utilization warning because a full logical log is a discrete operational condition.

---

## 7. Collection and Zabbix Contract

Collection method: SQL scalar statement through the common Informix query library.

Proposed Zabbix key: `ifx.log.full`

Zabbix type: active Agent item.

Value type: Numeric (unsigned).

Unit: `logs`.

Development interval: one minute.

Discovery: No.

---

## 8. Validation Evidence

The local development Informix instance returned five full logical logs during source validation. A later observation may differ as the active logical log advances.

Exact runtime values must be recorded through the repository collector, installed launcher, and Zabbix Agent before the lifecycle advances beyond `SOURCE_VALIDATED`.

---

## 9. Implementation Status

The SQL source and trigger semantics are defined. Statement, collector, launcher, Agent item, trigger, uninstall/reinstall validation, and exported-template validation remain pending.
