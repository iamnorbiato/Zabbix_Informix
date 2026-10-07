# STORAGE-005 — Chunk Utilization

**Status:** DEVELOPMENT_RUNTIME_VALIDATED

**Implementation status:** Source and runtime implementation validated in development; target acceptance remains pending.

## Purpose

Measure the percentage of pages used in each individual Informix chunk.

## Authoritative source

`sysmaster:syschunks`, joined to `sysmaster:sysdbstab` by `dbsnum`.

## Calculation

```text
used_pages = chksize - nfree
used_percent = 100 * used_pages / chksize
```

## Alert policy

Apply generic capacity thresholds only to application chunks:

- Warning: above 80%;
- High: above 90%.

System, catalog, temporary, physical-log and logical-log chunks require class-specific treatment.

## Zabbix contract

```text
ifx.storage.chunk.used_percent[{#IFX_DBSPACE},{#IFX_CHUNK}]
```

Value type: Numeric (float). Unit: `%`.

## Lifecycle

Source semantics and runtime implementation are validated in development; target baseline remains pending.
