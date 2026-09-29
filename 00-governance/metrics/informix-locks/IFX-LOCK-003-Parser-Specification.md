# IFX-LOCK-003 — Lock Timeouts — Parser Specification

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

## Input Contract

The approved `sysmaster:sysptprof` statement returns exactly one scalar in Informix unload format:

```text
<non-negative-integer>|
```

## Normalization Contract

The collector accepts only a dataset ending in `|`, removes that trailing delimiter, validates digits only, and prints the resulting integer followed by a newline. Empty, negative, non-numeric, multi-field or failed SQL output is an error, never zero.

## Runtime Binding

Collector: `05-collectors/informix/locks/ifx-lock-timeouts.ksh`

Agent key: `ifx.lock.timeouts`

Zabbix value type: Numeric unsigned. Unit: `timeouts`.

## Validation Evidence

The SQL statement, collector, launcher and Agent returned `0` in development. A positive timeout scenario remains pending because it must be exercised safely.
