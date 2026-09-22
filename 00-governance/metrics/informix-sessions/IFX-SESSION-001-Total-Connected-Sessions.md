# IFX-SESSION-001 — Total Connected Client Sessions

## 1. Purpose

This document defines the engineering contract for:

`IFX-SESSION-001 — Total Connected Client Sessions`

The metric counts currently connected Informix client sessions using the approved
`sysmaster:syssessions` source and explicit collector-infrastructure exclusions.

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

---

## 2. Monitoring Domain

Domain: `Connections, Sessions and Concurrency`

Metric type: `GAUGE`

Unit: `SESSIONS`

Scope: one Informix instance.

---

## 3. Authoritative Development Source

Database: `sysmaster`

Table: `syssessions`

The source has one row per user session. The metric uses `hostname` to identify
client-originated rows and applies explicit exclusions observed in the
development topology.

---

## 4. Approved SQL Contract

```sql
SELECT
    CAST(COUNT(*) AS INT8) AS total_connected_sessions
FROM syssessions s,
     syssessions collector_session
WHERE collector_session.sid = DBINFO('sessionid')
  AND LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND (
      s.feprogram IS NULL
      OR TRIM(s.feprogram) NOT MATCHES '*ontape*'
  )
  AND NOT (
      TRIM(s.hostname) = TRIM(collector_session.hostname)
      AND s.feprogram IS NOT NULL
      AND TRIM(s.feprogram) MATCHES '*/dbaccess'
  );
```

The runtime statement file contains only this `SELECT`; the common Informix
query library sets isolation.

---

## 5. Inclusion and Exclusion Rules

The metric includes rows with a non-empty client `hostname`.

It excludes:

1. engine-only rows with an empty hostname;
2. the collector session itself;
3. the Informix `ontape` logical-log archive service;
4. concurrent `dbaccess` sessions from the same host as the collector.

The last exclusion prevents collector-host diagnostic connections from inflating
this production monitoring count. Client programs from other hosts, including
DBeaver, remain within scope.

---

## 6. Output and Zero Semantics

The normalized output is one non-negative integer:

```text
4
```

`0` is a valid successful observation. An Informix failure, malformed unload
record, missing value, or multiple values is a collection failure and must not
be emitted as zero.

---

## 7. Collection and Zabbix Contract

Statement file:

`01-statements/informix-sessions/IFX-SESSION-001-Total-Connected-Sessions.sql`

Collector:

`05-collectors/informix/sessions/ifx-session-total-connected.ksh`

Zabbix key: `ifx.session.total_connected`

Zabbix type: active Agent item.

Value type: Numeric (unsigned).

Unit: `sessions`.

Development interval: one minute.

No direct trigger is defined until an operational baseline establishes a useful
threshold.

---

## 8. Relationship with Other Session Metrics

IFX-SESSION-001 is a current filtered client-session count.

It can be correlated with:

- IFX-SESSION-002 — Sessions in Read Call;
- IFX-SESSION-003 — Weekly Peak Concurrent Physical Connections;
- IFX-SESSION-004 — Waiting Client Sessions Total;
- IFX-SESSION-005 — Waiting Client Sessions by Reason.

No equality or ordering relationship is a parser invariant because the metrics
have distinct semantics, filters, and observation instants.

---

## 9. Runtime Validation

The Linux development topology validated:

1. the SQL statement through `ifx_db_execute`;
2. strict scalar collector normalization;
3. the installed launcher executed as user `zabbix`;
4. the Zabbix Agent active key;
5. the active template item and exported template definition.

The same valid value was confirmed through collector, installed launcher, and
Zabbix Agent execution.

Target Informix/AIX validation remains pending.
