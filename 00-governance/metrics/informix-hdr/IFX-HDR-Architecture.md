# IFX-HDR — Monitoring Architecture

**Status:** `DEFINED`; standalone source evidence recorded, real HDR behavior pending.
**Implementation status:** Documentation only.

## 1. Purpose

Monitor the local Informix HDR role/state, intended partner, connection, peer operational state, and—only after source validation—acknowledgement and log progress. An intentionally standalone instance must not alert. A required HDR pair must alert if its configuration, partner identity, connection, or operational state becomes abnormal.

## 2. Scope and topology

Each Informix instance is an independent Zabbix host and is queried through its own `sysmaster` database, whether the collector runs locally or through Informix Client SDK on another host. A primary and its secondary must not share a single collection identity.

This domain covers HDR, not Enterprise Replication, RSS, SDS, automatic promotion, or repair. RSS/SDS rows may be retained as cluster context but must not satisfy an HDR requirement.

## 3. SQL-only sources

| Source | Purpose | Evidence status |
|---|---|---|
| `sysmaster:sysdri` | Local DRI/HDR role, state, partner name, DR parameters | Table, schema, and standalone values observed on development Informix. |
| `sysmaster:syscluster` | Cluster rows and candidate peer connection/server state, sync mode, acknowledgement, and log progress | Table, schema, and a **local** standalone row observed. Remote HDR row semantics remain unvalidated. |

Production collection must not run or parse `onstat`. No undocumented `sysha_*` or `sysrephdr` table is assumed. SQL failures cannot be converted into an empty healthy topology.

## 4. Real standalone baseline

On development instance `ol_informix1210`, a successful `sysmaster` query returned `sysdri.type=Not Initialized`, `sysdri.state=Off`, and an empty `sysdri.name`. `syscluster` returned one row named `ol_informix1210` with `role=P`, `nodetype=PRIMARY`, `server_status=Active`, and an empty `connection_status`.

Therefore, `syscluster` row count is **not** a peer count. The observed local row must not be discovered as a remote HDR partner, and its blank connection field is not an HDR disconnect. This evidence does not establish the values or row shape that a real HDR pair will produce.

## 5. Required topology policy

The canonical policy is [IFX-HDR-Configuration-and-Alerting.md](IFX-HDR-Configuration-and-Alerting.md):

| Parameter | Standalone | Required HDR |
|---|---|---|
| `IFX_HDR_REQUIRED` | `NO` | `YES` on both primary and secondary hosts |
| `IFX_HDR_ALERT_ON_DISCONNECT` | `NO` | `YES`; suppression is not permitted |
| `IFX_HDR_EXPECTED_PEER` | empty | Exact intended remote Informix server name |

`IFX_HDR_EXPECTED_PEER` is an independent expected-state input. Learning the expectation only from currently observed discovery cannot guarantee detection of a missing or substituted peer.

## 6. Metric architecture

| Metric | Responsibility |
|---|---|
| `IFX-HDR-001` | Local role and state from `sysdri`. |
| `IFX-HDR-002` | Instance-level expected-HDR compliance, including absent or wrong partner; remains evaluable when discovery is empty. |
| `IFX-HDR-003` | Remote HDR peer discovery after local-row and node-type rules are proven. |
| `IFX-HDR-004` | Connection state of a proven remote HDR peer. |
| `IFX-HDR-005` | Peer operational state, role, and synchronization mode. |
| `IFX-HDR-006` | Acknowledgement age; deferred pending real-HDR timestamp semantics. |
| `IFX-HDR-007` | Log progress/backlog; deferred pending real-HDR unit and rollover semantics. |

The instance-level HDR-002 item prevents a vanished peer from resolving its own discovery-based problem. A separate monitoring-integrity trigger must cover collection failure or missing samples when HDR is required.

## 7. Alert and recovery principles

- No HDR observed and `IFX_HDR_REQUIRED=NO`: normal, no HDR alert.
- Required HDR absent, or observed partner differs from `IFX_HDR_EXPECTED_PEER`: High problem.
- Required partner observed but not in validated healthy connection and operational states: High problem at the first successful abnormal sample; no implicit grace period.
- Unknown status, missing required source fields, or failed collection: never report healthy. Expose monitoring-integrity failure separately.
- Recovery requires a successful sample proving the intended partner and validated healthy role, connection, and server states. A disappeared peer or stale value cannot resolve a problem.
- Periodic SQL polling cannot guarantee observation of a disturbance that begins and ends between samples.

## 8. Validation gates

The local no-HDR baseline is real-source validated. Real primary and secondary must still establish exact `sysdri`/`syscluster` row behavior, role and connection values, partner identity, transition/disconnect/recovery semantics, and collection cost. HDR-006/007 remain deferred until their source semantics are proven. See [IFX-HDR-Real-Source-Validation-Plan.md](IFX-HDR-Real-Source-Validation-Plan.md).

No mock or fabricated HDR dataset can establish production acceptance. Documentation approval is not runtime validation.
