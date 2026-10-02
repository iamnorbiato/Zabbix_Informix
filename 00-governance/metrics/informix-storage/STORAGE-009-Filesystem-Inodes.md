# STORAGE-009 — Filesystem Inode Utilization

**Status:** DEFINED

**Implementation status:** Source validation is available from the host operating system; runtime implementation remains pending.

## Purpose

Detect filesystem inode exhaustion before file creation or archive operations fail.

## Authoritative source

The operating-system filesystem utility executed on the Informix host.

## Calculation

```text
inode_used_percent = inodes_used / inodes_total * 100
```

Filesystems without inode accounting must return an explicit unsupported state rather than zero.

## Alert policy

Initial thresholds:

- Warning: above 80%;
- High: above 90%.

## Zabbix contract

```text
ifx.storage.filesystem.inode_used_percent[{#IFX_FILESYSTEM}]
```

Value type: Numeric (float). Unit: `%`.

## Lifecycle

Source semantics are defined. Runtime implementation remains pending AIX/Linux normalization.
