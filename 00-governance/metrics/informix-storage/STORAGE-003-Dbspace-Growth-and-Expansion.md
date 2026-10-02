# STORAGE-003 — Dbspace Growth and Expansion

**Status:** DEFINED

**Implementation status:** Source validated in the production Informix topology; growth calculation, collector, launcher, Zabbix item and trigger implementation remain pending.

## Purpose

Identify dbspaces and chunks that are approaching capacity without sufficient expansion capability.

## Authoritative source

`sysmaster:sysdbstab` joined to `sysmaster:syschunks` by `dbsnum`.

Relevant fields include:

- `sysdbstab.extend_size`;
- `sysdbstab.max_size`;
- `syschunks.is_extendable`;
- `syschunks.chksize`;
- `syschunks.nfree`.

## Semantics

The metric must distinguish:

1. current usage;
2. whether the chunk is extendable;
3. configured extension size;
4. configured maximum size;
5. remaining free space before operational intervention is required.

`max_size = 0` must not automatically be interpreted as unlimited capacity without confirming the Informix version semantics. It is reported as source data and interpreted by the operational policy.

## Development evidence

The production source returned an extension size of `10000` pages and `is_extendable = 0` for the observed chunks. The observed `max_size` value was `0`.

Production identifiers and filesystem paths are intentionally omitted from this document.

## Classification

Growth and expansion policy is class-specific:

- application dbspaces: evaluate capacity and expansion risk;
- system and catalog dbspaces: monitor expansion capability, but do not apply generic growth alarms without a baseline;
- temporary dbspaces: evaluate according to temporary-workload behavior;
- physical-log and logical-log dbspaces: use their dedicated log metrics;
- chunks with inconsistent, offline or recovering state: raise an independent state alert.

## Alert policy

The primary risk condition is:

```text
used_percent is high AND is_extendable = 0
```

Suggested initial severity:

- Warning: application dbspace above 80% with no expansion capability;
- High: application dbspace above 90% with no expansion capability;
- Critical: no free pages or chunk state is offline/inconsistent/recovering.

The thresholds remain subject to environment-specific baseline review.

## Zabbix contract

The metric may be exposed through dependent items derived from a dbspace/chunk master dataset:

```text
ifx.storage.dbspace.extendable[{#IFX_DBSPACE}]
ifx.storage.dbspace.extend_size[{#IFX_DBSPACE}]
ifx.storage.dbspace.max_size[{#IFX_DBSPACE}]
```

Value types and units must follow the normalized source contract. Boolean state should be represented numerically; page counts should remain numeric unsigned values.

## Relationship with other metrics

`STORAGE-003` evaluates expansion risk. It does not replace:

- `STORAGE-001` — percentage used;
- `STORAGE-002` — absolute free space;
- `STORAGE-004` — chunk state;
- `STORAGE-007` — filesystem utilization.

## Lifecycle

The source semantics are validated. Runtime implementation remains pending final interpretation of `max_size = 0` and approval of class-specific thresholds.
