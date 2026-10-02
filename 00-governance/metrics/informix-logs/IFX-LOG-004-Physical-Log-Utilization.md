# IFX-LOG-004 — Physical Log Utilization

## 1. Purpose

This document defines the engineering contract for:

`IFX-LOG-004 — Physical Log Utilization`

The metric reports the percentage of the Informix physical log currently in use.

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

Primary table: `sysplog`

`pl_phyused` is divided by `pl_physize` to calculate the current physical-log utilization.

---

## 4. Approved SQL Contract

```sql
SELECT
    CAST(
        100.0 * pl_phyused / pl_physize
        AS DECIMAL(10,2)
    ) AS physical_log_utilization_percent
FROM sysplog;
```

The query must return exactly one numeric scalar value.

---

## 5. Scope and Semantics

The metric measures physical-log occupancy and is independent of logical-log count or current logical-log utilization.

`0` is a valid successful observation when `pl_phyused` is zero.

Missing rows, a zero denominator, malformed output, connection failure, query failure, or permission failure is not zero and must fail collection.

---

## 6. Thresholds

Warning threshold: greater than `80%`.

High threshold: greater than `90%`.

These thresholds are initial development policy and may be refined after operational baselines are established.

---

## 7. Collection and Zabbix Contract

Collection method: SQL scalar statement through the common Informix query library.

Proposed Zabbix key: `ifx.log.physical_utilization`

Zabbix type: active Agent item.

Value type: Numeric (float).

Unit: `%`.

Development interval: one minute.

Discovery: No.

---

## 8. Validation Evidence

The local development Informix instance returned `18910/25000`, approximately `75.64%`.

Production source validation returned `3761221/4999947`, approximately `75.22%`. Production evidence is recorded separately and is not a substitute for local runtime validation.

---

## 9. Implementation Status

The SQL source and threshold semantics are defined. Statement, collector, launcher, Agent item, triggers, uninstall/reinstall validation, and exported-template validation remain pending.
