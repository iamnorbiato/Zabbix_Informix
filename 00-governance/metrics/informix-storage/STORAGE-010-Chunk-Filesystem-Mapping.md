# STORAGE-010 — Chunk to Filesystem Mapping

**Status:** OUT_OF_SCOPE

**Implementation status:** Belongs to the operating-system/filesystem ownership boundary and is not implemented in this Informix package.

## Purpose

Associate each Informix chunk with its physical path, filesystem and dbspace class.

## Authoritative source

`sysmaster:syschunks.fname`, joined to `sysmaster:sysdbstab` by `dbsnum`, followed by host filesystem resolution.

## Normalized contract

```text
DBSPACE|CHUNK|CHUNK_PATH|FILESYSTEM|MOUNTPOINT|CLASS
```

The mapping must remain informational and must not execute the returned path as a command.

## Classification

The normalized record must identify system, temporary, physical-log, logical-log and application classes.

## Zabbix contract

This metric primarily supports discovery and correlation. It does not require a standalone numeric item.

Proposed discovery key:

```text
ifx.storage.mapping.discovery
```

## Lifecycle

Source relationship is validated. Runtime discovery remains pending.
