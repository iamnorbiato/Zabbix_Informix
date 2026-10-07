# STORAGE-006 — Chunk Free Space

**Status:** DEVELOPMENT_RUNTIME_VALIDATED

**Implementation status:** Source and runtime implementation validated in development; target acceptance remains pending.

## Purpose

Measure absolute free space in each Informix chunk.

## Authoritative source

`sysmaster:syschunks`, with `pagesize` supplied by the associated dbspace.

## Calculation

```text
free_pages = nfree
free_bytes = nfree * pagesize
free_gb = free_bytes / 1073741824
```

## Alert policy

Absolute thresholds are environment-specific. They must be evaluated together with percentage utilization and filesystem capacity.

## Zabbix contract

```text
ifx.storage.chunk.free_gb[{#IFX_DBSPACE},{#IFX_CHUNK}]
```

Value type: Numeric (float). Unit: `GB`.

## Lifecycle

Source semantics and runtime implementation are validated in development; target baseline remains pending.
