# STORAGE-008 — Filesystem Free Space

**Status:** DEFINED

**Implementation status:** Source validation is available from the host operating system; runtime implementation remains pending.

## Purpose

Measure absolute free space on filesystems used by Informix storage, logical-log archives and backups.

## Authoritative source

The operating-system filesystem utility executed on the Informix host.

## Calculation

```text
free_bytes = filesystem_available_blocks * filesystem_block_size
free_gb = free_bytes / 1073741824
```

## Alert policy

Absolute thresholds are environment-specific and must be evaluated together with filesystem percentage and expected growth.

## Zabbix contract

```text
ifx.storage.filesystem.free_gb[{#IFX_FILESYSTEM}]
```

Value type: Numeric (float). Unit: `GB`.

## Lifecycle

Filesystem evidence is validated. Runtime implementation remains pending host-side collection design.
