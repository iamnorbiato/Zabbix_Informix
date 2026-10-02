# STORAGE-007 — Filesystem Utilization

**Status:** DEFINED

**Implementation status:** Source validation is available from the host operating system; runtime implementation remains pending.

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

Filesystem evidence is validated. Runtime implementation remains pending host-side collection design.
