# IFX-HDR-004 — HDR Peer Connectivity

**Status:** `DEFINED`; remote HDR source values pending real-pair validation.
**Implementation status:** Documentation only.
**Collection database:** `sysmaster`.

## 1. Objective

Report the connection status of each **proven remote HDR peer** and raise a High problem on the first successfully sampled non-healthy connection state when HDR is required. This is an Informix engine signal, not a network ping.

## 2. Dependencies and source

`IFX-HDR-003` must first distinguish remote HDR rows from the local `syscluster` row and from RSS/SDS. Candidate source: `sysmaster:syscluster.connection_status` associated with the exact peer named by `IFX_HDR_EXPECTED_PEER`. The development standalone instance has a local `syscluster` row with a blank `connection_status`; that blank is **not** a remote-peer disconnect.

The exact connection strings and row behavior on primary and secondary remain unvalidated. Preserve each raw source string and do not label it `CONNECTED` until a real HDR pair confirms the mapping.

## 3. Proposed normalized values

| Value | Name | Treatment for required HDR |
|---:|---|---|
| `0` | `UNKNOWN` | Never healthy; monitoring-integrity problem. |
| `1` | `CONNECTED` | Healthy only after this source mapping is validated. |
| `2` | `CONNECTING` | High on the first observed sample; no implicit grace period. |
| `3` | `DISCONNECTED` | High on the first observed sample. |
| `4` | `FAILED` | High on the first observed sample. |

The future parser must not turn blank, missing, or unrecognized remote values into `CONNECTED`. If the peer row vanishes, HDR-002 owns the instance-level absent-peer High problem; discovery disappearance must not clear the outage.

## 4. Policy and Zabbix design

For a required HDR host, `IFX_HDR_REQUIRED=YES`, `IFX_HDR_ALERT_ON_DISCONNECT=YES`, and `IFX_HDR_EXPECTED_PEER` are mandatory. `IFX_HDR_ALERT_ON_DISCONNECT=NO` cannot suppress a required connection alert; that combination is invalid configuration.

Proposed dependent item prototype: `ifx.hdr.peer.connectivity[{#IFX_HDR_PEER}]`, numeric unsigned. Proposed High problem name: `Informix HDR peer {#IFX_HDR_PEER}: connection is not operational`. The exact trigger will be built in the Zabbix UI after real source values are verified, then exported as part of the complete template.

No default 90-second delay or connecting-state grace period is approved. Periodic polling observes only states present at successful sample times; a transient entirely between samples cannot be guaranteed detectable.

## 5. Recovery and failure

Recover only when the **same intended peer** is observed in the validated `CONNECTED` state in a fresh successful sample and HDR-002 confirms the expected relationship. A missing peer, SQL failure, unsupported item, unknown source string, or stale last value cannot resolve a problem.

Collector failure and `nodata` on a required-HDR host need a separate monitoring-integrity trigger so loss of telemetry is not mistaken for a healthy connection. Lag/acknowledgement alerts must not duplicate an active connectivity outage.

## 6. Real-source acceptance

On a real primary and secondary, record exact `sysdri` and `syscluster` rows while healthy, connecting, disconnected/failed, and recovered. Confirm whether a disconnected peer remains as a row or disappears, and validate the mapped strings on both roles. Do not create mock HDR rows or accept fixture-driven state transitions as source proof.
