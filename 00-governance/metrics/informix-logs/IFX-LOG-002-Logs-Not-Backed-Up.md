# IFX-LOG-002 — Logical Logs Not Backed Up

**Status atual:** `DEFINED` — fonte e semântica definidas; implementação runtime ainda pendente.

## 1. Purpose

This document defines the engineering contract for:

`IFX-LOG-002 — Logical Logs Not Backed Up`

The metric counts Informix logical logs whose `is_backed_up` flag is zero.

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

`is_backed_up = 0` identifies a logical log that has not been backed up according to the current Informix catalog state.

---

## 4. Approved SQL Contract

```sql
SELECT
    COUNT(*) AS logical_logs_not_backed_up
FROM syslogs
WHERE is_backed_up = 0;
```

The query must return exactly one non-negative integer scalar value.

---

## 5. Scope and Semantics

The metric counts logs, not bytes and not sessions. A value of `0` is a valid successful observation: every catalogued logical log is currently marked backed up.

The metric does not by itself prove that a backup destination is reachable or that a backup completed successfully. Those concerns require separate backup-status evidence.

Missing rows, malformed output, connection failure, query failure, or permission failure is not zero and must fail collection.

---

## 6. Trigger Policy

Initial policy: no fixed threshold is declared until local runtime behavior and operational baseline are established.

Any positive value is operationally relevant, but alert severity must account for whether the count is stable, increasing, and accompanied by current-log pressure.

---

## 7. Collection and Zabbix Contract

Collection method: SQL scalar statement through the common Informix query library.

Proposed Zabbix key: `ifx.log.not_backed_up`

Zabbix type: active Agent item.

Value type: Numeric (unsigned).

Unit: `logs`.

Development interval: one minute.

Discovery: No.

---

## 8. Validation Evidence

The local development Informix instance returned a non-zero count during source validation. The production instance also returned non-zero pending-log state in its separate source evidence.

Exact runtime values must be recorded through the repository collector, installed launcher, and Zabbix Agent before the lifecycle advances beyond `SOURCE_VALIDATED`.

---

## 9. Implementation Status

The SQL source and metric semantics are defined. Statement, collector, launcher, Agent item, trigger policy, uninstall/reinstall validation, and exported-template validation remain pending.
