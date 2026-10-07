# IFX-LOG-006 — Level-0 Backup Age by Database and Dbspace

**Status atual:** `DEFINED` — fonte e semântica definidas; implementação runtime ainda pendente.

## 1. Purpose

This document defines the engineering contract for:

`IFX-LOG-006 — Level-0 Backup Age by Database and Dbspace`

The metric exposes the age of the most recent Level-0 physical backup for each monitored database/dbspace association.

Lifecycle: `SOURCE_VALIDATED`

---

## 2. Monitoring Domain

Domain: `Logical Logs, Physical Log and Backup`

Metric type: `GAUGE`

Unit: `DAYS`

Scope: one Informix instance, database and dbspace association.

---

## 3. Authoritative Development Source

Database: `sysmaster`

Primary tables: `sysdatabases`, `sysdbstab`, `syscfgtab`

The database is associated with its dbspace through `dbsnum = TRUNC(partnum / 1048576)`. The configured backup destination is read from `syscfgtab` where `cf_name = 'TAPEDEV'`.

Temporary dbspaces are excluded from discovery.

---

## 4. Data Contract

Each discovered database/dbspace association must expose:

- database name;
- dbspace name;
- Level-0 backup age in days;
- Level-0 timestamp;
- Level-1 timestamp or `Nenhum`;
- Level-2 timestamp or `Nenhum`;
- configured backup destination.

The numeric item value is:

- `-1` when `level0 = 0`;
- otherwise the elapsed age in days since `level0`.

---

## 5. Source SQL Contract

The source query joins `sysdatabases`, `sysdbstab` and `syscfgtab`, and filters `TAPEDEV`. The collector must normalize the result into a discovery-safe contract with stable database and dbspace identifiers.

The collector must not treat Level-1 or Level-2 being absent as an error when the operational policy uses Level-0 backups.

---

## 6. Trigger Policy

Warning when the Level-0 backup age exceeds seven days:

```text
last(/Template Zabbix Tailor Informix Health/ifx.log.backup_age_days[{#IFX_DBSPACE}])>7
```

Trigger name:

```text
Informix LOG-006: Level-0 backup older than 7 days on {#IFX_DBSPACE}
```

Severity: `WARNING`.

High when no Level-0 backup exists:

```text
last(/Template Zabbix Tailor Informix Health/ifx.log.backup_age_days[{#IFX_DBSPACE}])=-1
```

Trigger name:

```text
Informix LOG-006: no Level-0 backup exists on {#IFX_DBSPACE}
```

Severity: `HIGH`.

---

## 7. Collection and Zabbix Contract

Collection method: SQL discovery and per-dbspace values through the common Informix query library.

Discovery key: `ifx.log.backup.discovery`

Item prototype key: `ifx.log.backup_age_days[{#IFX_DBSPACE}]`

Value type: Numeric (float).

Unit: `days`.

Development interval: one hour.

Discovery: Yes.

---

## 8. Validation Evidence

Production source validation returned recent Level-0 backups for permanent dbspaces and a configured destination of `/backup/PRODUCAO/ARCHIVE`. Level-1 and Level-2 were absent, which is valid for a Level-0-only policy.

Local runtime validation remains required before implementation status advances beyond `SOURCE_VALIDATED`.

---

## 9. Implementation Status

The source relationship, exclusion rule, age semantics, destination field and trigger policy are defined. SQL discovery, collector, launcher, Agent integration, Zabbix prototypes, uninstall/reinstall validation and exported-template validation remain pending.
