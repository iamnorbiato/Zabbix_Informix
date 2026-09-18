# IFX-HEALTH-001 — Instance State

## 1. Purpose

This document defines the current engineering contract and validation status for:

`IFX-HEALTH-001 — Instance State`

The metric reports the native operational mode of one IBM Informix instance.

---

## 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-001`

Metric name:

`Instance State`

---

## 3. Objective

The metric determines the current engine mode returned by Informix and distinguishes a valid engine state from a failure to collect that state.

It answers these operational questions:

- Is the Informix instance Online?
- Is it in an administrative or transitional mode?
- Is a valid state currently being collected?

---

## 4. Authoritative Source

The operational source is:

`sysmaster:sysshmhdr`

The collector selects the row where:

```sql
name = 'mode'
```

The authoritative value is `sysshmhdr.value`.

The current operational statement is:

```sql
SELECT value
FROM sysshmhdr
WHERE name = 'mode';
```

The source was executed successfully in the Linux development topology and returned:

```text
5|
```

`5` means `Online`.

---

## 5. Native Informix Mode Mapping

The collector preserves the native numeric value. It does not translate it into an alternative numeric model.

| Value | Operational Mode | Technical Description |
|------:|------------------|-----------------------|
| 0 | Initialization | The instance is initializing shared-memory structures and allocating engine resources. |
| 1 | Quiescent | Administrative or single-user operational mode. |
| 2 | Recovery | The instance is performing recovery processing. |
| 3 | Backup | The instance is operating in applicable engine backup procedures. |
| 4 | Shutdown | The instance is actively shutting down engine resources. |
| 5 | Online | Normal operational state. The engine accepts normal user workload. |
| 6 | Abort | The instance is processing an abort condition. |
| 7 | User | Restricted user operational mode. |
| 255 | Off-Line | Off-line mode when observable through the engine state structure. |

The destination Informix/AIX environment must confirm the modes that are observable in that environment.

---

## 6. Metric Semantics

Metric type:

`STATE`

Each successful collection represents the native engine mode observed at that moment.

The metric is not cumulative and is not a counter.

The healthy operational value is:

```text
5 = Online
```

---

## 7. Collection Architecture

The collector is executed remotely from the collection host. It does not execute `onstat`, `oncheck`, or monitoring logic on the Informix server.

```text
Informix instance
    ↓ remote SQL through Informix Client SDK
sysmaster:sysshmhdr
    ↓
ifx-health-state.ksh
    ↓
Zabbix Agent active item
    ↓
Zabbix Server
```

The collector statement is:

```text
01-statements/informix-health/IFX-HEALTH-001-Instance-State.sql
```

The collector implementation is:

```text
05-collectors/informix/health/ifx-health-state.ksh
```

---

## 8. Collector Output Contract

On success, standard output contains exactly one supported native mode code:

```text
5
```

Supported values are:

```text
0, 1, 2, 3, 4, 5, 6, 7, 255
```

The collector returns a non-zero exit code for an empty, malformed, unsupported, or multi-record SQL result.

Diagnostics belong to standard error and must not be emitted as a valid state value.

---

## 9. Collection Failure Semantics

The following conditions MUST NOT produce a synthetic Informix state value:

- Informix Client SDK failure;
- remote SQL connection failure;
- invalid `INFORMIXSERVER` or `sqlhosts` configuration;
- permission failure;
- collector execution failure;
- timeout;
- malformed or unsupported `sysshmhdr.value`.

In particular, `255` MUST NOT be synthesized when the remote SQL connection fails.

A collection failure means that the state cannot be determined. It is semantically distinct from a successfully returned engine mode.

---

## 10. Parameterized Deployment Contract

The Zabbix Agent never executes the repository working tree directly.

The deployment process installs collector code to a configurable `IFX_COLLECTOR_HOME` and loads runtime values from a private configuration file.

Required runtime values are:

```text
IFX_COLLECTOR_HOME
IFX_INFORMIXDIR
IFX_INFORMIXSERVER
IFX_INFORMIXSQLHOSTS
IFX_CONFIG_DIR
IFX_STATE_DIR
IFX_CONNECT_FILE
```

The private Informix connection file is outside Git. It must be readable by the Zabbix service account and protected with restricted permissions.

The development deployment uses these product-owned locations:

```text
/opt/zabbix-informix
/etc/zabbix-informix
/usr/local/lib/zabbix-informix
/etc/zabbix/zabbix_agentd.d/zabbix-informix.conf
```

These are deployment defaults, not source-code paths. A destination environment may choose different configured locations.

---

## 11. Zabbix Representation

Template:

`Template Zabbix Tailor Informix Health`

Implemented item:

| Field | Value |
|---|---|
| Name | `HEALTH-001 — instance state code` |
| Type | Zabbix agent (active) |
| Key | `ifx.health.instance_state` |
| Value type | Numeric unsigned |
| Update interval | 1 minute |
| Timeout | 30 seconds |
| Trends | Disabled |

The item preserves the native Informix mode code. A future Zabbix value map may add human-readable presentation without changing the stored value.

---

## 12. Alerting

The following High-severity triggers are configured in the template.

### 12.1 Valid non-Online state

```text
Name: Informix HEALTH-001: instance is not Online
Expression: last(.../ifx.health.instance_state)<>5
```

This trigger applies only when the collector successfully returns a valid mode code other than `5`.

### 12.2 No state received

```text
Name: Informix HEALTH-001: instance state has not been collected for 3 minutes
Expression: nodata(.../ifx.health.instance_state,3m)=1
```

This trigger reports absence of data. It does not assert that the Informix instance is Off-Line.

The normal state `5` was collected and the template configuration was verified. A non-Online engine mode and a three-minute no-data condition were not forced in the development environment because doing so would require disrupting the instance or collection path.

Target-environment trigger severity and maintenance-window policy remain subject to operational validation.

---

## 13. Collection Frequency and Cost

Configured development interval:

`1 minute`

Configured timeout:

`30 seconds`

Observed development cost:

`LOW`

The collector executes one remote SQL query against `sysmaster:sysshmhdr`.

The target Informix/AIX environment must confirm acceptable cost under expected production workload.

---

## 14. Discovery Requirement

Low-Level Discovery:

`NO`

This metric represents one configured Informix instance. A future multi-instance host model must define explicit instance identity and deployment configuration.

---

## 15. Dependencies

The metric depends on:

- Informix Client SDK installed on the collection host;
- correct `INFORMIXSERVER` and `INFORMIXSQLHOSTS` values;
- a private connection file readable by the Zabbix service account;
- SQL access to `sysmaster:sysshmhdr`;
- Zabbix Agent active checks reaching the Zabbix Server.

---

## 16. Historical Mock Design

Earlier project work modeled this metric through `onstat -` output and a provisional mapping such as `4 = Online`.

That material remains historical mock-design context only. It is superseded for operational implementation by the native SQL mapping in section 5.

The historical mock parser is not used by the deployed collector.

---

## 17. Development Runtime Validation

Current lifecycle state:

`DEVELOPMENT_RUNTIME_VALIDATED`

Validated in the Linux development topology:

- remote SQL source `sysmaster:sysshmhdr`;
- returned native value `5` for the Online state;
- SQL statement artifact;
- state collector syntax and direct execution;
- parameterized installation independent from the repository path;
- execution through the installed launcher as user `zabbix`;
- Zabbix Agent active item;
- exported Zabbix template configuration;
- configured non-Online and no-data triggers.

Development topology:

```text
Informix and Zabbix Server: home
Informix Client SDK and Zabbix Agent: cluster-prime
```

---

## 18. Target Environment Validation Criteria

Before promotion beyond the development runtime status, validate against the destination Informix/AIX environment:

- availability and permissions for `sysmaster:sysshmhdr`;
- native `mode` values observed for relevant engine states;
- Informix Client SDK connectivity and authentication;
- Zabbix Agent service-account permissions;
- collector cost under expected workload;
- behavior during approved administrative transitions;
- trigger severity, maintenance-window and escalation policy;
- deployment and rollback using the versioned installation process.

---

## 19. Grafana

Grafana integration:

`PENDING`

A future dashboard may present the current native code, human-readable mapping, state history, uptime, restart events and related availability signals.

---

## 20. Exit Criteria

The development-runtime implementation phase is complete when:

- the authoritative SQL source is defined;
- native state-code semantics are documented;
- the collector preserves the native numeric value;
- collection failures remain distinct from state values;
- the Zabbix item and trigger configuration is installed and validated;
- deployment is parameterized and independent from the source repository path.

These criteria are satisfied in the Linux development topology.

Promotion to target-environment validation requires the checks defined in section 18.
