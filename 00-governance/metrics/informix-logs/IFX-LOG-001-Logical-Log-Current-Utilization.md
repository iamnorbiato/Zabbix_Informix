# IFX-LOG-001 — Logical Log Current Utilization

## 1. Purpose

This document defines the engineering contract for:

`IFX-LOG-001 — Logical Log Current Utilization`

The metric reports the percentage of the current Informix logical log that is used.

Lifecycle: `SOURCE_VALIDATED`

---

## 2. Monitoring Domain

Domain: `Logical Logs, Physical Log and Backup`

Metric type: `GAUGE`

Unit: `PERCENT`

Scope: one Informix instance.

---

## 3. Authoritative Development Source

Database: `sysmaster`

Primary table: `syslogs`

The current logical log is identified by `is_current = 1`. Its utilization is calculated as `used / size * 100`.

---

## 4. Approved SQL Contract

```sql
SELECT
    CAST(
        100.0 * MAX(CASE WHEN is_current = 1 THEN used ELSE NULL END)
        / MAX(CASE WHEN is_current = 1 THEN size ELSE NULL END)
        AS DECIMAL(10,2)
    ) AS current_log_utilization_percent
FROM syslogs;
```

The query must return exactly one numeric scalar value.

---

## 5. Scope and Semantics

The metric measures only the current logical log. It does not treat the number of full historical logs as the current utilization percentage.

`0` is a valid successful value only when the current log reports zero usage.

Missing current-log data, a null denominator, malformed output, connection failure, query failure, or permission failure is not zero and must fail collection.

---

## 6. Thresholds

Warning threshold: greater than `80%`.

High threshold: greater than `90%`.

The thresholds are applied to the current logical log utilization. They do not directly replace the separate metrics for logs pending backup or archive.

---

## 7. Collection and Zabbix Contract

Collection method: SQL scalar statement through the common Informix query library.

Proposed Zabbix key: `ifx.log.current_utilization`

Zabbix type: active Agent item.

Value type: Numeric (float).

Unit: `%`.

Development interval: one minute.

Discovery: No.

---

## 8. Validation Evidence

The local development Informix instance returned:

```text
current_log = 4
used = 4728
size = 5000
current_log_utilization = 94.56%
```

The production source validation returned a current-log utilization of approximately `78.34%` on a separately configured instance. Production evidence is recorded separately and is not a substitute for local runtime validation.

---

## 9. Implementation Status

The SQL source and threshold semantics are defined. Collector, launcher, Agent item, trigger, uninstall/reinstall validation, and exported-template validation remain pending.
