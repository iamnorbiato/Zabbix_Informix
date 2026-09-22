# IFX-HDR-005 — HDR Peer State and Sync Mode

**Status:** `DEFINED`  
**Implementation status:** Not implemented.  
**Collection database:** `sysmaster`  
**Runtime method:** SQL only; no `onstat` execution.

## 1. Objective

Expose the engine-reported role, server state, and synchronization mode for each discovered HDR peer.

This metric complements HDR-004. A peer can be connected while still operating in an unexpected role, state, or synchronization mode that deserves operational visibility.

## 2. Dependencies

| Dependency | Purpose |
|---|---|
| `IFX-HDR-003` Peer Discovery | Provides stable HDR peer identity. |
| `IFX-HDR-004` Peer Connectivity | Separately reports whether communication is operational. |
| HDR master data contract | Provides per-peer source fields. |

## 3. Source Contract

Initial source: `sysmaster:syscluster` for rows classified as HDR.

Candidate fields:

| Source field | Normalized field | Intended meaning |
|---|---|---|
| `name` | `peer_name` | HDR peer identity. |
| `role` | `peer_role` | Remote role reported by engine. |
| `server_status` | `peer_server_status` | Remote server operational state. |
| `syncmode` | `sync_mode` | HDR synchronization policy/mode. |
| `delayed_apply` | `delayed_apply` | Optional delayed-apply visibility. |
| `stop_apply` | `stop_apply` | Optional apply-stop visibility. |

Only the first four fields are candidates for the initial version. Delayed apply and stopped apply remain deferred until their target semantics are validated.

## 4. Candidate SQL

**Database: `sysmaster`**

```sql
SELECT
    name,
    nodetype,
    role,
    server_status,
    syncmode,
    delayed_apply,
    stop_apply
FROM syscluster;
```

This is a schema-validation candidate, not approved production SQL. Before implementation, it must be reduced to fields verified on the target Informix release.

## 5. Normalized Data Values

### 5.1 Peer role

| Value | Meaning |
|---|---|
| `PRIMARY` | Engine identifies peer as primary. |
| `SECONDARY` | Engine identifies peer as secondary. |
| `UNKNOWN` | Source value absent or unrecognized. |

### 5.2 Peer server state

The final value mapping requires real HDR evidence. The initial normalized model is:

| Value | Meaning |
|---|---|
| `ACTIVE` | Peer server is operational according to the engine source. |
| `INACTIVE` | Peer server is known but not operational. |
| `RECOVERING` | Peer is in an engine-reported recovery/transition state. |
| `FAILED` | Engine reports peer failure. |
| `UNKNOWN` | Source value absent or unrecognized. |

### 5.3 Synchronization mode

The initial normalized model is:

| Value | Meaning |
|---|---|
| `SYNC` | Synchronous HDR mode. |
| `ASYNC` | Asynchronous HDR mode. |
| `UNKNOWN` | Source value absent or unrecognized. |

No policy assertion is made that `SYNC` is universally better than `ASYNC`. The desired mode is an environment-specific design decision and must not create an alert until explicitly configured later.

## 6. Proposed Zabbix Design

| Element | Proposed value |
|---|---|
| Peer role item prototype | `ifx.hdr.peer.role[{#IFX_HDR_PEER}]` |
| Peer server-state item prototype | `ifx.hdr.peer.server_state[{#IFX_HDR_PEER}]` |
| Peer sync-mode item prototype | `ifx.hdr.peer.sync_mode[{#IFX_HDR_PEER}]` |
| Item type | Dependent item prototypes |
| Master item | Approved common HDR master item |
| Value type | Numeric unsigned with value mappings, or text only if Zabbix mapping cannot preserve source diagnostics cleanly. |
| Tags | `informix: hdr`, `hdr_peer: {#IFX_HDR_PEER}` |

The implementation should favor numeric values for trigger-capable operational state and preserve raw source strings in the master payload.

## 7. Alert Policy

The initial HDR documentation does not define an alert for sync mode drift. Synchronization policy is an operational design choice and requires an explicit desired-mode parameter before it can become a compliance condition.

Candidate future alerts, deferred pending target validation:

| Condition | Candidate severity | Decision gate |
|---|---|---|
| Peer server state is `FAILED` | High | Confirm source semantics and avoid duplicate HDR-004 alerts. |
| Peer server state is `INACTIVE` | High or Warning | Confirm relationship to connectivity source. |
| Peer state is `RECOVERING` beyond a grace period | Warning | Agree expected recovery duration. |
| Sync mode differs from configured expected mode | Warning | Add explicit desired-mode configuration first. |

## 8. Role Consistency

On a normal HDR relationship, observed local and peer roles should be complementary:

| Local role | Expected peer role |
|---|---|
| `PRIMARY` | `SECONDARY` |
| `SECONDARY` | `PRIMARY` |

Role inconsistency is a diagnostic signal. It must not immediately create an automatic trigger until actual source behavior during failover and role transition is documented.

## 9. Failure Behavior

| Condition | Expected behavior |
|---|---|
| Optional source field absent | Omit/defer the dependent item; do not invent a value. |
| Required role/state/mode source field absent | Collector fails clearly until a supported alternative is validated. |
| Source value unknown | Normalize to `UNKNOWN`, retaining raw evidence. |
| Peer not discovered | No peer prototype item; HDR-002 and HDR-003 govern absence. |

## 10. Mock Validation

| Fixture | Expected observation |
|---|---|
| `primary-hdr-connected` | Peer role `SECONDARY`, server state `ACTIVE`, sync mode fixture value. |
| `secondary-hdr-connected` | Peer role `PRIMARY`, server state `ACTIVE`. |
| `primary-hdr-connecting` | Validate transitional peer server state if fixture defines it. |
| `primary-hdr-failed` | Failed or non-operational peer state remains visible. |
| `unknown-peer-status` | Unknown values are preserved and not coerced. |

## 11. Acceptance Criteria

- Target `syscluster` fields and source values are captured from a real HDR environment.
- The meaning of `server_status` and `syncmode` is confirmed for the target version.
- Role-complementarity behavior is observed in steady state and, where safely possible, transition.
- Deferred fields are not implemented until their availability and semantics are validated.
- No connectivity alert is duplicated solely because this metric exposes the same engine failure through another field.

