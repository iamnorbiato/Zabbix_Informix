# STORAGE-001 — Dbspace Utilization

**Status:** DEVELOPMENT_RUNTIME_VALIDATED

**Implementation status:** Source, collector, launcher and Zabbix runtime validated in the Linux development topology; target Informix/AIX acceptance remains pending.

## Purpose

Measure the percentage of pages used in each Informix dbspace.

## Authoritative source

`sysmaster:sysdbstab` joined to `sysmaster:syschunks` by `dbsnum`.

## Calculation

For each dbspace:

```text
used_pages = SUM(chksize) - SUM(nfree)
used_percent = 100 * used_pages / SUM(chksize)
```

The result is an aggregate across all chunks belonging to the dbspace.

## Classification

Generic capacity triggers apply only to application dbspaces.

The following classes are handled separately:

- system and catalog dbspaces: `root_dbs`, `rootdbs`, `sysadm_dbs`, `sysadmin`, `catal_dbs`;
- temporary dbspaces: names beginning with `temp`;
- physical-log dbspaces: names such as `phys_dbs`;
- logical-log dbspaces: names such as `logs_dbs`;
- application dbspaces: all remaining configured dbspaces.

System, catalog, physical-log and logical-log dbspaces must not receive the generic application capacity trigger.

## Development evidence

The production source returned:

```text
prd_data_01_dbs   89.05 percent used
prd_idx_01_dbs    74.06 percent used
```

The corresponding free-space values were approximately:

```text
prd_data_01_dbs  73.60 GB free
prd_idx_01_dbs   49.49 GB free
```

These results demonstrate that percentage and absolute free space must be collected as separate metrics.

## Alert policy

The initial application-dbspace thresholds are:

- Warning: usage greater than 80 percent;
- High: usage greater than 90 percent.

Absolute free-space thresholds remain environment-specific and must not be hardcoded into this metric.

Chunk state, filesystem capacity, growth and temporary-dbspace pressure are monitored by separate metrics.

## Zabbix contract

Proposed item key:

```text
ifx.storage.dbspace.used_percent[{#IFX_DBSPACE}]
```

Type: dependent item from a dbspace discovery master item.

Value type: Numeric (float).

Unit: `%`.

Discovery: Yes, for configured dbspaces.

The discovery contract must expose the dbspace name and its classification so generic application triggers are not applied to excluded classes.

## Lifecycle

The metric is ready for SQL-contract review. No runtime implementation is accepted until classification behavior and production source semantics are confirmed.
