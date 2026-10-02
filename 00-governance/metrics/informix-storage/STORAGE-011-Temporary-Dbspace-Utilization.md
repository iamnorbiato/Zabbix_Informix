# STORAGE-011 — Temporary Dbspace Utilization

**Status:** DEFINED

**Implementation status:** Source validated in a production topology; runtime implementation remains pending.

## Purpose

Monitor temporary dbspaces separately from permanent application and catalog dbspaces.

## Authoritative source

`sysmaster:sysdbstab` joined to `sysmaster:syschunks` by `dbsnum`.

Temporary dbspaces are identified by the configured temporary-dbspace policy and validated names, not by assuming every environment uses the same naming convention.

## Calculation

```text
used_percent = 100 * (SUM(chksize) - SUM(nfree)) / SUM(chksize)
free_pages = SUM(nfree)
```

## Development evidence

An anonymized production sample showed temporary dbspaces at approximately `3.08%` used, with no immediate capacity concern.

## Alert policy

Temporary-dbspace thresholds must be workload-specific. A high value may reflect legitimate sort or temporary-table activity, so sustained duration and recovery behavior should be considered before raising a High alert.

## Zabbix contract

```text
ifx.storage.temp_dbspace.used_percent[{#IFX_DBSPACE}]
ifx.storage.temp_dbspace.free_gb[{#IFX_DBSPACE}]
```

Value types: Numeric (float). Units: `%` and `GB`.

## Lifecycle

Source semantics are validated. Runtime implementation remains pending temporary-dbspace classification and baseline approval.
