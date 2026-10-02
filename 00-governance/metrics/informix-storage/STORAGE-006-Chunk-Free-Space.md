# STORAGE-006 — Chunk Free Space

**Status:** DEFINED

**Implementation status:** Source validated in the production Informix topology; runtime implementation remains pending.

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

Source semantics are validated. Runtime implementation remains pending.
