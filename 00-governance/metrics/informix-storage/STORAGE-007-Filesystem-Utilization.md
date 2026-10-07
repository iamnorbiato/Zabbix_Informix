# STORAGE-007 — Filesystem Utilization

**Status:** OUT_OF_SCOPE

**Implementation status:** Owned by the operating-system/AIX monitoring package; this Informix SQL package must not use client-side `df`.

## Purpose

Measure filesystem utilization for filesystems containing Informix chunks, logical-log archives or backup destinations.

## Authoritative source

The operating-system filesystem utility executed on the Informix host, using chunk and backup paths discovered from Informix configuration.

## Calculation

```text
used_percent = filesystem_used / filesystem_size * 100
```

## Alert policy

Initial generic thresholds:

- Warning: above 80%;
- High: above 90%.

Thresholds may be overridden per filesystem because backup and archive destinations have different operational behavior.

## Zabbix contract

```text
ifx.storage.filesystem.used_percent[{#IFX_FILESYSTEM}]
```

Value type: Numeric (float). Unit: `%`.

## Lifecycle

Filesystem evidence is validated. Runtime collection is `OUT_OF_SCOPE` for this Informix package and belongs to the host-side SO/AIX monitoring.
