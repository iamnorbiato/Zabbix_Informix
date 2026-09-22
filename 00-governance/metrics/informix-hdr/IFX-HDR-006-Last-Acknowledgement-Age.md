# IFX-HDR-006 — HDR Last Acknowledgement Age

**Status:** `DEFINED`  
**Implementation status:** Deferred until real-HDR source validation.  
**Collection database:** `sysmaster`  
**Runtime method:** SQL only; no `onstat` execution.

## 1. Objective

Measure how long it has been since each HDR peer last acknowledged replication progress, where the target Informix version exposes a documented, validated acknowledgement timestamp.

This metric is a lag/staleness signal. It is not a substitute for HDR-004 connectivity: a connected peer can still acknowledge progress too slowly.

## 2. Why This Metric Is Deferred

`syscluster.ack_time` is a candidate source field, but its availability, data type, unit, time basis, update behavior, and meaning during reconnect or idle workloads must be validated on a real target HDR environment.

Until those facts are established, no SQL statement, collector, Zabbix item, threshold, or trigger must be implemented for this metric.

## 3. Candidate Source Contract

Candidate source: `sysmaster:syscluster.ack_time` for rows classified as HDR.

Candidate validation projection:

**Database: `sysmaster`**

```sql
SELECT
    name,
    nodetype,
    connection_status,
    ack_time
FROM syscluster;
```

This query must be run only after the target HDR system is available. Its output and column definition must be recorded before design moves to implementation.

## 4. Required Target Evidence

Before implementation, capture and document:

| Question | Required evidence |
|---|---|
| Does `ack_time` exist? | Target `syscolumns` definition. |
| What is its data type? | Target `coltype` and representative values. |
| What unit/time representation does it use? | IBM documentation plus observed comparison with known time. |
| Which clock defines it? | Confirm local engine time, UTC, epoch, or another representation. |
| Does it update during idle workload? | Controlled observation. |
| What is its value while disconnected? | Controlled interruption or documented event. |
| What is its value during reconnect/failover? | Controlled observation where safe. |
| Does it represent receipt, application, or another acknowledgement stage? | Documentation and observed behavior. |

## 5. Proposed Normalized Value

After validation, the metric will expose one numeric value per discovered HDR peer:

```text
acknowledgement_age_seconds
```

Definition to be finalized:

```text
collection_timestamp_seconds - validated_acknowledgement_timestamp_seconds
```

The calculation must be performed only when both timestamps share a confirmed compatible time basis.

The following values are prohibited:

- a negative age silently converted to zero;
- an arbitrary conversion from an unverified integer;
- an age value reported for an absent or unknown acknowledgement source.

## 6. Proposed Zabbix Design

| Element | Proposed value |
|---|---|
| Item prototype name | `HDR peer {#IFX_HDR_PEER}: acknowledgement age` |
| Item prototype key | `ifx.hdr.peer.ack_age[{#IFX_HDR_PEER}]` |
| Type | Dependent item prototype |
| Value type | Numeric float or unsigned, selected after target source type is confirmed. |
| Units | `s` |
| Master item | Approved common HDR master item |
| Tags | `informix: hdr`, `hdr_peer: {#IFX_HDR_PEER}` |

The item must remain unsupported or absent if the target version cannot supply a validated source. It must not publish a fabricated zero.

## 7. Threshold Policy

Thresholds are opt-in and defined per monitored instance:

| Parameter | Meaning |
|---|---|
| `IFX_HDR_ACK_AGE_WARNING_SECONDS` | Warning threshold; empty disables warning. |
| `IFX_HDR_ACK_AGE_HIGH_SECONDS` | High threshold; empty disables high. |

Validation rule:

```text
HIGH >= WARNING
```

If the workload is idle, acknowledgement age may grow without an actual replication defect. Before enabling thresholds, operations must decide whether the source semantics distinguish idle replication from stalled replication. If it does not, threshold alerting must remain disabled.

## 8. Proposed Trigger Semantics

| Condition | Proposed priority |
|---|---|
| Age is greater than configured warning threshold | Warning |
| Age is greater than configured high threshold | High |

Threshold triggers must be gated by a `CONNECTED` HDR-004 state. A disconnected peer is already handled by the connectivity alert and should not generate misleading duplicate lag problems.

## 9. Failure and Unknown Behavior

| Condition | Expected behavior |
|---|---|
| `ack_time` unavailable on target version | Metric remains unimplemented/unsupported; document incompatibility. |
| Ack timestamp is null while connected | Report unknown; investigate semantics before thresholding. |
| Ack timestamp is invalid or from incompatible time basis | Collector/parser failure; no age calculated. |
| Peer disconnected | Connectivity metric owns the High alert; acknowledgement age is not asserted as healthy. |
| Source query fails | Existing value is not replaced by zero. |

## 10. Mock Validation

Fixtures may validate parser and Zabbix threshold behavior only after the timestamp contract is approved.

Required mock cases:

| Case | Expected result |
|---|---|
| Age below warning threshold | No problem. |
| Age equal to warning threshold | Confirm chosen inclusive/exclusive comparison; default proposal is no problem at equality. |
| Age above warning threshold | Warning. |
| Age above high threshold | High. |
| Connected peer with missing timestamp | Unknown/unsupported, not zero seconds. |
| Disconnected peer with stale timestamp | Connectivity problem only; no duplicate age alert. |

## 11. Acceptance Criteria

- Source field availability and semantics are evidenced on real HDR.
- Age calculation uses a confirmed time basis and unit.
- Idle-workload behavior is understood before thresholds are enabled.
- Trigger conditions are gated by connectivity to avoid duplicate or misleading alerts.
- Unsupported target versions fail safely without fabricated values.

