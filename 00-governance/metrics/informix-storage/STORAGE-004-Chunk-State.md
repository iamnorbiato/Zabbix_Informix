# STORAGE-004 — Chunk State

**Status:** DEVELOPMENT_RUNTIME_VALIDATED

**Implementation status:** Source, collector, launcher and Zabbix runtime validated in development; target acceptance remains pending.

## Purpose

Detect chunks that are offline, recovering or inconsistent, regardless of their capacity utilization.

## Authoritative source

`sysmaster:syschunks`, joined to `sysmaster:sysdbstab` by `dbsnum` for dbspace identity.

Relevant fields:

- `chknum`;
- `fname`;
- `is_offline`;
- `is_recovering`;
- `is_inconsistent`;
- `is_extendable`.

## Normalized state contract

Each chunk must produce one normalized record:

```text
DBSPACE|CHUNK|PATH|OFFLINE|RECOVERING|INCONSISTENT|EXTENDABLE
```

The state fields are numeric flags:

```text
0 = false
1 = true
```

The path is source evidence and must be protected from accidental command interpretation by the collector.

## Development evidence

The development chunk returned:

```text
OFFLINE=0
RECOVERING=0
INCONSISTENT=0
EXTENDABLE=0
```

The production source also exposed these flags for individual chunks. Production dbspace and path identifiers are intentionally omitted.

## Alert policy

The following conditions are independently alertable:

- `is_offline = 1` — High;
- `is_recovering = 1` — Warning or High according to operational policy;
- `is_inconsistent = 1` — High;
- a previously present chunk disappears from discovery — High after the loss-of-resource grace period.

`is_extendable = 0` is not itself an incident. It contributes to the expansion-risk logic in `STORAGE-003`.

## Zabbix contract

Proposed discovery key:

```text
ifx.storage.chunk.discovery
```

Proposed item keys:

```text
ifx.storage.chunk.offline[{#IFX_DBSPACE},{#IFX_CHUNK}]
ifx.storage.chunk.recovering[{#IFX_DBSPACE},{#IFX_CHUNK}]
ifx.storage.chunk.inconsistent[{#IFX_DBSPACE},{#IFX_CHUNK}]
```

Value type: Numeric (unsigned).

Units: none.

Discovery must retain stable dbspace and chunk identifiers and must not use real production names in governance examples.

## Relationship with capacity metrics

Chunk state is independent of capacity. A chunk can be healthy while nearly full, or unhealthy while mostly empty.

## Lifecycle

The source fields, normalized output and runtime implementation are validated in development. Target baseline and discovery-contract acceptance remain pending.
