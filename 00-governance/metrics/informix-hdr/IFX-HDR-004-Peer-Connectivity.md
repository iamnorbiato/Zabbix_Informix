# IFX-HDR-004 — HDR Peer Connectivity

**Status:** `DEFINED`  
**Implementation status:** Not implemented.  
**Collection database:** `sysmaster`  
**Runtime method:** SQL only; no `onstat` execution.

## 1. Objective

Expose whether each discovered HDR peer is connected to the monitored Informix instance and apply the approved disconnect-alert policy.

This is the primary availability signal for the HDR relationship. It assesses the engine-reported HDR connection state, not a generic network ping or TCP port test.

## 2. Dependencies

| Dependency | Purpose |
|---|---|
| `IFX-HDR-003` Peer Discovery | Establishes the HDR peer identity. |
| HDR master data contract | Supplies source connectivity values. |
| `IFX_HDR_ALERT_ON_DISCONNECT` | Determines whether a non-connected peer creates a Zabbix problem. |
| `IFX_HDR_REQUIRED` | Provides context for required HDR, evaluated separately by HDR-002. |

## 3. Source Contract

Initial source: `sysmaster:syscluster.connection_status` for rows classified as HDR.

Candidate source projection:

**Database: `sysmaster`**

```sql
SELECT
    name,
    nodetype,
    connection_status
FROM syscluster;
```

The target environment must validate the exact field name and every expected engine value before implementation.

## 4. Normalized Connectivity Value

Each discovered `{#IFX_HDR_PEER}` must produce one numeric item:

| Value | Name | Meaning |
|---:|---|---|
| `0` | `UNKNOWN` | Source value absent or unrecognized. |
| `1` | `CONNECTED` | Engine reports an operational HDR connection. |
| `2` | `CONNECTING` | HDR relationship exists but is being established. |
| `3` | `DISCONNECTED` | HDR relationship exists but is not connected. |
| `4` | `FAILED` | Engine reports an HDR relationship failure. |

Raw source status must remain available in the HDR master output for diagnosis.

## 5. Proposed Zabbix Design

| Element | Proposed value |
|---|---|
| Item prototype name | `HDR peer {#IFX_HDR_PEER}: connectivity` |
| Item prototype key | `ifx.hdr.peer.connectivity[{#IFX_HDR_PEER}]` |
| Type | Dependent item prototype |
| Value type | Numeric unsigned |
| Value mapping | `0=Unknown`, `1=Connected`, `2=Connecting`, `3=Disconnected`, `4=Failed` |
| Master item | Approved common HDR master item |
| Tags | `informix: hdr`, `hdr_peer: {#IFX_HDR_PEER}` |

## 6. Alert Policy

The connectivity trigger is enabled only when the private policy permits it.

| Configuration | Latest connectivity value | Expected trigger result |
|---|---:|---|
| `IFX_HDR_ALERT_ON_DISCONNECT=NO` | any | No connectivity problem. State remains visible. |
| `IFX_HDR_ALERT_ON_DISCONNECT=YES` | `1` | No problem. |
| `IFX_HDR_ALERT_ON_DISCONNECT=YES` | `2` | Policy-controlled grace behavior; initially a warning candidate, not immediate High. |
| `IFX_HDR_ALERT_ON_DISCONNECT=YES` | `3` | High problem. |
| `IFX_HDR_ALERT_ON_DISCONNECT=YES` | `4` | High problem. |
| any | `0` | No healthy assertion; item unsupported or explicit data-quality handling to be finalized. |

The final expression must include a target-approved grace period for `CONNECTING`, if a real HDR test demonstrates one is needed. `DISCONNECTED` and `FAILED` must not be masked by a generic grace period.

## 7. Proposed Trigger Semantics

Proposed problem name:

```text
Informix HDR peer {#IFX_HDR_PEER}: connection is not operational
```

Proposed priority: `High`.

Conceptual condition:

```text
IFX_HDR_ALERT_ON_DISCONNECT is YES
AND latest normalized connectivity is DISCONNECTED or FAILED
```

The configuration value must be reflected safely in the deployed item/trigger design; it must not be passed in a user-controlled item key.

## 8. Recovery Semantics

The High problem resolves automatically when the same discovered peer returns to `CONNECTED`.

If a peer disappears from discovery, recovery behavior must follow the approved lost-resource retention policy. A peer must not silently disappear immediately merely because one collection cycle failed.

## 9. Examples

| Observed engine condition | Normalized value | With alerting enabled |
|---|---|---|
| Healthy primary-to-secondary HDR link | `CONNECTED` (`1`) | Healthy. |
| Peer reconnect in progress | `CONNECTING` (`2`) | Visibility; trigger behavior after approved grace period. |
| Link interrupted | `DISCONNECTED` (`3`) | High problem. |
| Engine reports replication link failure | `FAILED` (`4`) | High problem. |

## 10. Failure Behavior

| Condition | Expected behavior |
|---|---|
| Peer is not discovered | No item prototype exists for that peer; HDR-002 evaluates whether absence is acceptable. |
| Master SQL fails | Existing dependent values are not replaced with a false `CONNECTED` value. |
| Connectivity source value is unknown | Emit `UNKNOWN` (`0`) and retain raw source data. |
| Policy configuration is invalid | Collector/configuration failure, never a silent disabled alert. |

## 11. Mock Validation

| Fixture | Alerting policy | Expected result |
|---|---|---|
| `primary-hdr-connected` | `YES` | `CONNECTED`; no problem. |
| `primary-hdr-connecting` | `NO` | `CONNECTING`; no problem. |
| `primary-hdr-connecting` | `YES` | Validate approved grace behavior. |
| `primary-hdr-disconnected` | `NO` | `DISCONNECTED`; no problem. |
| `primary-hdr-disconnected` | `YES` | `DISCONNECTED`; High problem. |
| `primary-hdr-failed` | `YES` | `FAILED`; High problem. |
| `unknown-peer-status` | either | `UNKNOWN`; never reported as connected. |

## 12. Acceptance Criteria

- Real HDR source values are mapped to the five normalized states.
- The disconnect policy is enforced exactly as configured.
- `DISCONNECTED` and `FAILED` generate High problems only when alerting is enabled.
- Connection recovery is demonstrated using a real or fixture-driven state transition.
- A failed collection cannot overwrite a non-healthy state with `CONNECTED`.

