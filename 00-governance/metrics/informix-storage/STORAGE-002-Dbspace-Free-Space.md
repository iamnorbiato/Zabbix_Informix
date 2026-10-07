# STORAGE-002 — Dbspace Free Space

**Status:** DEVELOPMENT_RUNTIME_VALIDATED

**Implementation status:** Source, collector, launcher and Zabbix runtime validated in the Linux development topology; target acceptance remains pending.

## Purpose

Measure the absolute free space available in each Informix dbspace.

## Authoritative source

`sysmaster:sysdbstab` joined to `sysmaster:syschunks` by `dbsnum`.

## Calculation

For each dbspace:

```text
free_pages = SUM(nfree)
free_bytes = free_pages * pagesize
free_gb = free_bytes / 1073741824
```

The result is aggregated across all chunks belonging to the dbspace.

## Classification

Free-space values are collected for all dbspace classes, but alert policy is class-specific.

System and catalog dbspaces, temporary dbspaces, physical-log dbspaces and logical-log dbspaces must not use the generic application free-space threshold.

Application dbspaces use environment-specific absolute free-space thresholds in addition to the percentage metric from `STORAGE-001`.

## Development evidence

The development instance returned approximately `55.35 MB` free for `tailor/rootdbs`.

An anonymized production sample returned approximately:

```text
prd_data_01_dbs  73.60 GB free
prd_idx_01_dbs   49.49 GB free
```

The values are evidence of the metric behavior only; production identifiers are intentionally omitted.

## Alert policy

No universal absolute free-space threshold is embedded in this metric.

The threshold must be configured per environment and per dbspace class, considering expected growth and the physical filesystem capacity.

The metric may support Warning and High triggers after operational baselines are established.

## Zabbix contract

Proposed item key:

```text
ifx.storage.dbspace.free_gb[{#IFX_DBSPACE}]
```

Type: dependent item from a dbspace discovery master item.

Value type: Numeric (float).

Unit: `GB`.

Discovery: Yes, using the same dbspace discovery contract as `STORAGE-001`.

## Relationship with STORAGE-001

`STORAGE-001` measures relative consumption. `STORAGE-002` measures absolute remaining capacity. Neither metric replaces the other.

## Lifecycle

The metric is implemented and runtime-validated in development. Classification, thresholds and target-environment acceptance remain pending.
