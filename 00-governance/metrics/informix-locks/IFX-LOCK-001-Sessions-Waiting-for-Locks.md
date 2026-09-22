# IFX-LOCK-001 — Sessions Waiting for Locks

## 1. Purpose

This document defines the engineering contract for:

`IFX-LOCK-001 — Sessions Waiting for Locks`

The metric counts qualifying Informix client sessions currently represented as lock waiters in `sysmaster:syslocks`.

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

---

## 2. Monitoring Domain

Domain: `Locks, Deadlocks and Contention`

Metric type: `GAUGE`

Unit: `SESSIONS`

Scope: one Informix instance.

---

## 3. Authoritative Development Source

Database: `sysmaster`

Primary table: `syslocks`

Supporting table: `syssessions`

`syslocks.waiter` identifies a session waiting for a lock. The join to `syssessions.sid` preserves the monitored entity as a session and permits the client-session filter.

---

## 4. Controlled Validation Evidence

A controlled lock scenario used two independent client transactions against `tailor.zbx_ifx_session_test_lock`.

The validation returned:

```text
owner_sid   = 12941
waiter_sid  = 14544
is_wlock    = 1
```

The waiter session had a client hostname and DBeaver program identity. The approved aggregate query returned `1` while the wait existed and `0` after the blocking transaction was released.

---

## 5. Approved SQL Contract

```sql
SELECT
    CAST(COUNT(DISTINCT l.waiter) AS INT8) AS sessions_waiting_for_locks
FROM syslocks l
INNER JOIN syssessions s
    ON s.sid = l.waiter
WHERE l.waiter > 0
  AND s.sid <> DBINFO('sessionid')
  AND LENGTH(TRIM(s.hostname)) > 0;
```

`COUNT(DISTINCT l.waiter)` is required because one waiting session can appear in more than one `syslocks` row.

---

## 6. Scope and Zero Semantics

The metric includes lock waiters with a non-empty client hostname and excludes the collector session.

`0` is a valid successful observation: no qualifying client session is currently waiting for a lock.

No row, malformed output, connection failure, query failure, or permission failure is not zero and must fail collection.

---

## 7. Relationship with Session Metrics

IFX-SESSION-005 exposes a `LOCK` dimension sourced from `syssessions.is_wlock`. The controlled test showed both sources identify the same waiting client session.

The metrics are not declared equivalent as a permanent arithmetic invariant: `syslocks` and `syssessions` have distinct source timing and aggregation behavior.

---

## 8. Collection and Zabbix Contract

Collection method: SQL scalar statement through the common Informix query library.

Zabbix key: `ifx.lock.sessions_waiting`

Zabbix type: active Agent item.

Value type: Numeric (unsigned).

Unit: `sessions`.

Development interval: one minute.

Discovery: No.

Trigger: `Informix LOCK-001: session(s) waiting for locks detected`.

Expression:

```text
last(/Template Zabbix Tailor Informix Health/ifx.lock.sessions_waiting)>0
```

Severity: `HIGH`.

A value greater than `0` opens the configured high-severity alert. The event resolves automatically when the next valid value is `0`.

---

## 9. Runtime Validation Evidence

The Linux development topology validated all of the following:

1. the versioned `sysmaster` SQL statement returned `0` with no lock wait;
2. the same statement returned `1` during a controlled lock wait;
3. the repository collector, installed launcher running as `zabbix`, and Zabbix Agent active key each returned the expected value;
4. the active template item received `1` and later `0`;
5. the exported template contains the active item and the `HIGH` trigger;
6. the controlled wait opened a visible red `High` problem in Zabbix;
7. after the blocking transaction was committed, the value returned to `0` and the Zabbix problem became `RESOLVED`;
8. uninstall removed the launcher and Agent integration, and reinstall restored the Agent key with a valid value of `0`.

Target Informix/AIX validation remains separate.
