# STORAGE-009 — Filesystem Inode Utilization

**Status:** OUT_OF_SCOPE

**Implementation status:** Owned by the operating-system/AIX monitoring package; not implemented here.

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

Source semantics are defined. Runtime collection is `OUT_OF_SCOPE` for this Informix package and belongs to the AIX/Linux monitoring owner.
