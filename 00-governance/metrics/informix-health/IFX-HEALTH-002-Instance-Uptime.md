# IFX-HEALTH-002 — Instance Uptime

## 1. Purpose

This document defines the engineering contract and validation status for:

`IFX-HEALTH-002 — Instance Uptime`

The metric reports elapsed time, in seconds, since the current IBM Informix engine startup.

---

## 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-002`

Metric name:

`Instance Uptime`

---

## 3. Objective

The metric supports:

- visibility of the current engine uptime;
- detection of a decrease in uptime, indicating an instance restart;
- correlation of restart events with Informix, Zabbix and operating-system events.

---

## 4. Authoritative Source

The operational source is:

`sysmaster:sysshmhdr`

The collector uses the row where:

```sql
name = 'bttime'
```

`bttime` is the engine boot-time epoch value. Uptime is calculated from the current UTC epoch value.

```sql
SELECT
    CAST(DBINFO('utc_current') - value AS INT8) AS uptime_seconds
FROM sysshmhdr
WHERE name = 'bttime';
```

The `INT8` cast is required so that the SQL collector receives an integer result rather than a decimal-formatted unload value.

---

## 5. Metric Semantics

Metric type:

`GAUGE`

Unit:

`seconds`

The returned value is the elapsed time since the current engine boot time.

It is not a counter. A lower valid value than the previous valid sample indicates a restart or a change of monitored instance identity.

---

## 6. Source Validation

The Linux development topology returned:

```text
bttime:      1789492156
utc_current: 1789749221
uptime:      257065 seconds
```

After a subsequent collection, uptime changed from `257065` to `257102`, an increase of `37` seconds.

The explicit `INT8` query returned:

```text
raw_uptime:     257300
uptime_seconds: 257300
```

This validates the source calculation and its expected continuous growth in the development environment.

---

## 7. Collection Architecture

```text
Informix instance
    ↓ remote SQL through Informix Client SDK
sysmaster:sysshmhdr (bttime)
    ↓
ifx-health-uptime.ksh
    ↓
Zabbix Agent active item
    ↓
Zabbix Server
```

The collector statement is:

```text
01-statements/informix-health/IFX-HEALTH-002-Instance-Uptime.sql
```

The collector implementation is:

```text
05-collectors/informix/health/ifx-health-uptime.ksh
```

---

## 8. Collector Output Contract

On success, standard output contains one non-negative integer:

```text
257337
```

An empty, decimal-formatted, malformed, negative or multi-record result is a collection failure. It must not become a synthetic uptime value.

Diagnostics belong to standard error.

---

## 9. Collection Failure Semantics

The following conditions MUST NOT produce uptime `0` or any other synthetic value:

- Informix Client SDK failure;
- remote SQL connection failure;
- invalid `INFORMIXSERVER` or `sqlhosts` configuration;
- permission failure;
- collector execution failure;
- timeout;
- malformed query result.

A collection failure means that uptime cannot be determined. It is distinct from a valid near-zero uptime after a restart.

---

## 10. Parameterized Deployment

The collector is installed through the versioned deployment process and does not execute the repository working tree.

The deployment installs a dedicated HEALTH-002 launcher and publishes:

```text
ifx.health.instance_uptime
```

Runtime paths, Client SDK location, Informix server identifier, sqlhosts and private connection file are provided through the external runtime configuration.

Credentials remain outside Git.

---

## 11. Zabbix Representation

Template:

`Template Zabbix Tailor Informix Health`

Implemented item:

| Field | Value |
|---|---|
| Name | `HEALTH-002 — instance uptime` |
| Type | Zabbix agent (active) |
| Key | `ifx.health.instance_uptime` |
| Value type | Numeric unsigned |
| Units | `uptime` |
| Update interval | 1 minute |
| Timeout | 30 seconds |
| Trends | 365 days in the development template |

The Zabbix frontend renders the received seconds as a human-readable uptime value. The stored source value remains seconds.

---

## 12. Restart Detection

Implemented trigger:

```text
Name: Informix HEALTH-002: instance restart detected
Severity: Warning
Expression: last(.../ifx.health.instance_uptime)<last(.../ifx.health.instance_uptime,#2)
```

The trigger opens when a valid current uptime is lower than the preceding valid sample and recovers on the following non-decreasing sample.

The normal uptime collection and trigger configuration were validated. A restart was not forced in the development environment.

Target-environment validation must define maintenance-window handling, expected restart scenarios and escalation policy.

---

## 13. Dependencies

The metric depends on:

- Informix Client SDK on the collection host;
- correct `INFORMIXSERVER` and `INFORMIXSQLHOSTS` values;
- private connection credentials readable by the Zabbix service account;
- SQL access to `sysmaster:sysshmhdr`;
- Zabbix Agent active checks reaching the Zabbix Server.

---

## 14. Historical Mock Design

Earlier project work parsed uptime from `onstat -` output. That parser and its mock cases remain historical design material only.

They are superseded for operational implementation by the remote SQL source defined in section 4.

---

## 15. Development Runtime Validation

Current lifecycle state:

`DEVELOPMENT_RUNTIME_VALIDATED`

Validated in the Linux development topology:

- `bttime` source discovery;
- UTC epoch subtraction and `INT8` output typing;
- monotonic increase between valid samples;
- SQL statement and collector execution;
- installed launcher execution as user `zabbix`;
- Zabbix Agent active key;
- Zabbix item with `uptime` unit and 30-second timeout;
- configured Warning restart-detection trigger;
- exported template configuration.

Development topology:

```text
Informix and Zabbix Server: home
Informix Client SDK and Zabbix Agent: cluster-prime
```

---

## 16. Target Environment Validation Criteria

Before promotion beyond development runtime validation, validate against the destination Informix/AIX environment:

- `bttime` availability and permissions;
- UTC epoch and `INT8` arithmetic behavior for the deployed Informix version;
- engine boot-time semantics across Informix restart;
- Client SDK connectivity and authentication;
- service-account permissions;
- collection cost under expected workload;
- restart trigger behavior during an approved restart;
- maintenance-window and escalation policy;
- deployment and rollback through the versioned scripts.

---

## 17. Grafana

Grafana integration:

`PENDING`

A future dashboard may present uptime, restart markers, state transitions, assert failures and related AIX events.

---

## 18. Exit Criteria

The development-runtime phase is complete when:

- a SQL source and native unit are defined;
- uptime is returned as an integer number of seconds;
- collection failure remains distinct from zero uptime;
- the installed collector and active Agent key are validated;
- restart trigger configuration is versioned;
- deployment is independent from the repository path.

These criteria are satisfied in the Linux development topology.

Promotion to target-environment validation requires the checks in section 16.
