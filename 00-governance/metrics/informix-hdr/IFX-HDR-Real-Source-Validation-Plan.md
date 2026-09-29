# IFX-HDR — Real-Source Validation Plan

**Status:** `DEFINED`. The standalone baseline has been observed; real HDR transitions remain pending.  
**Replaces:** `IFX-HDR-Mock-Validation-Plan.md`. No mock HDR rows or fixture-driven source claims are permitted.

## 1. Purpose

Provide an evidence path for SQL-only HDR monitoring when the development Informix instance has no HDR pair. Distinguish what can be proven now from what requires a real primary and secondary.

## 2. Evidence already obtained on development Informix

Database: `sysmaster`. Both `sysdri` and `syscluster` exist and their schemas were inspected.

| Query source | Actual standalone output |
|---|---|
| `sysdri` | `type=Not Initialized`, `state=Off`, empty `name`, `intvl=0`, `timeout=30`. |
| `syscluster` | One row: `name=ol_informix1210`, `role=P`, `nodetype=PRIMARY`, `syncmode=SYNC`, `server_status=Active`, empty `connection_status`. |

This proves that a local cluster row is present without a remote HDR peer. It does **not** prove how a connected or disconnected HDR pair is represented.

## 3. Immediate development checks using real data

- Re-run both read-only queries on `sysmaster` through DBeaver and through the existing Informix Client SDK path; compare normalized results.
- Verify that a successful standalone collection has zero remote HDR peers and no HDR alert when `IFX_HDR_REQUIRED=NO`.
- Set `IFX_HDR_REQUIRED=YES` with an explicit `IFX_HDR_EXPECTED_PEER` only in an isolated monitoring configuration and verify the **required-but-absent** decision against the same real standalone SQL output. This changes monitoring policy, not Informix topology. It is not evidence of a real HDR disconnect.
- Verify that SQL errors, missing fields, invalid parameters, and absent samples never become a healthy/empty result. These are collector/monitoring-integrity checks, not fabricated HDR source states.
- Do not create fake `syscluster` rows, synthetic HDR files, or a mock mode in production collectors.

## 4. Required evidence from a real HDR pair

Collect from **both** primary and secondary, using each node's own `sysmaster`:

| Situation | Evidence to record |
|---|---|
| Healthy connected pair | Local `sysdri`; all relevant `syscluster` rows; local-vs-remote classification; exact partner names, roles, node types, connection/server states, and sync mode. |
| Connection establishing | Exact source strings, duration, and whether an abnormal sample is observable at the planned polling interval. |
| Link or peer failure | Exact source changes, whether the remote row remains or disappears, SQL accessibility, and first observable alert time. |
| Recovery/reconnect | Exact source changes and proof that the intended partner is restored before trigger recovery. |
| Role change/failover, if safely available | Local and remote role transitions and expected-peer policy behavior. |
| RSS/SDS coexistence, if present | Demonstrate that non-HDR rows do not satisfy the HDR requirement or enter HDR discovery. |

Capture Informix version/build, query text, execution time, host/instance identity, and timestamps with every observation. Do not perform disruptive failover/disconnect tests without the target environment owner's authorization.

## 5. Metric gates

| Metric | What may proceed now | What remains blocked |
|---|---|---|
| HDR-001 | Real standalone role/state normalization. | Real primary/secondary and transition mappings. |
| HDR-002 | Required-vs-optional policy against real standalone output. | Proof of absent/wrong peer behavior on an operating pair. |
| HDR-003 | Exclusion of the observed local row. | Remote HDR row identity, uniqueness, and disappearance behavior. |
| HDR-004 | No healthy remote status claim yet. | Connected/connecting/disconnected/failed source mappings. |
| HDR-005 | No healthy remote server-state claim yet. | Peer role, operational state, and sync-mode mappings. |
| HDR-006 | Candidate field/schema inspection only. | Timestamp meaning, clock basis, idle behavior, and thresholds. |
| HDR-007 | Candidate field/schema inspection only. | Log-position units, rollover, comparable progress, and thresholds. |

## 6. Zabbix acceptance

For a required HDR host, demonstrate separately: instance-level absence alert when the partner disappears; wrong-partner alert against `IFX_HDR_EXPECTED_PEER`; connection/state alerts on observed abnormal samples; collection-failure or `nodata` alert; and recovery only after a successful healthy sample. Validate that peer discovery deletion cannot clear an active outage without the instance-level condition remaining visible.

Polling cannot guarantee visibility of an interruption shorter than the interval between successful samples. Choose and document the interval accordingly. Do not assert that this plan alone proves production behavior.
