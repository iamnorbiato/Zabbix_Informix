# IFX-LOCK-005 — Lock Table Exhaustion Attempts — Parser Specification

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

## Input Contract

The approved `sysmaster:sysprofile` statement returns exactly one scalar in Informix unload format:

```text
<non-negative-integer>|
```

## Normalization Contract

The collector accepts only a dataset ending in `|`, removes that trailing delimiter, validates digits only, and prints the resulting integer followed by a newline. Empty, negative, non-numeric, multi-field or failed SQL output is an error, never zero.

## Runtime Binding

Collector: `05-collectors/informix/locks/ifx-lock-table-exhaustion.ksh`

Agent key: `ifx.lock.table_exhaustion_attempts`

Zabbix value type: Numeric unsigned. Unit: `attempts`.

The Zabbix trigger detects `change(...) > 0`, with severity `High` and tag `informix: lock-005`.

## Validation Evidence

The `ovlock` source shape, SQL statement, collector, launcher, Agent key, Zabbix item and trigger export were validated in development with a baseline value of `0`.
