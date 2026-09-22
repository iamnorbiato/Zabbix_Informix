# IFX-HDR-007 — HDR Log Progress and Backlog

**Status:** `DEFINED`  
**Implementation status:** Deferred until real-HDR source validation.  
**Collection database:** `sysmaster`  
**Runtime method:** SQL only; no `onstat` execution.

## 1. Objective

Expose HDR log transmission and acknowledgement progress for each discovered peer and, only when a valid unit can be proven, derive an actionable replication backlog measure.

This metric is intended to identify a connected HDR relationship that is falling behind. It does not replace the availability signal in HDR-004.

## 2. Why This Metric Is Deferred

Candidate `syscluster` fields appear to expose sent and acknowledged log identifiers/pages, but their availability, ordering rules, rollover behavior, units, and comparability must be validated on a real target HDR environment.

Subtracting log identifiers or page numbers without those semantics can yield a number that looks precise but is operationally false. No implementation is permitted until the evidence gate is passed.

## 3. Candidate Source Contract

Candidate source: `sysmaster:syscluster` HDR rows.

Candidate fields:

| Candidate field | Intended meaning requiring validation |
|---|---|
| `logid_sent` | Last logical log identifier sent to peer. |
| `logpage_sent` | Last log page sent to peer. |
| `logid_acked` | Last logical log identifier acknowledged by peer. |
| `logpage_acked` | Last log page acknowledged by peer. |

Candidate validation query:

**Database: `sysmaster`**

```sql
SELECT
    name,
    nodetype,
    connection_status,
    logid_sent,
    logpage_sent,
    logid_acked,
    logpage_acked
FROM syscluster;
```

This query is for schema and behavior validation only. Do not create a production statement from it until source compatibility is evidenced.

## 4. Required Target Evidence

| Question | Required evidence |
|---|---|
| Do all four candidate fields exist? | Target column definitions from `syscolumns`. |
| Are values numeric, character, or structured? | Column data types and representative values. |
| What constitutes ordering across log IDs? | IBM documentation and observed progression. |
| How does page ordering behave within one log? | Controlled sequence observation. |
| What occurs at log rollover? | Observed rollover or authoritative documentation. |
| What occurs after reconnect/failover? | Controlled observation where safe. |
| Do acknowledged values represent receipt or apply completion? | Documentation plus observed correlation. |
| Can a single scalar backlog unit be derived safely? | Explicit formula and validation. |

## 5. Data Model

The first implementation stage, if source fields are validated, must expose raw progress components before deriving a backlog:

| Proposed per-peer item | Meaning |
|---|---|
| `sent_log_id` | Validated source log ID sent. |
| `sent_log_page` | Validated source log page sent. |
| `acked_log_id` | Validated source acknowledged log ID. |
| `acked_log_page` | Validated source acknowledged log page. |

The derived `backlog` item is optional and may be omitted if no reliable, stable, and useful scalar unit exists.

## 6. Backlog Calculation Gate

No formula is approved yet.

The following tempting formulas are explicitly prohibited until target evidence confirms they are correct:

```text
logid_sent - logid_acked
logpage_sent - logpage_acked
(logid_sent * pages_per_log + logpage_sent) - (logid_acked * pages_per_log + logpage_acked)
```

A future formula must document:

- all input units;
- the ordering and rollover rule;
- any required `pages_per_log` source;
- behavior for a negative or inconsistent result;
- its operational interpretation and threshold unit.

## 7. Proposed Zabbix Design

### 7.1 Raw progress items

| Element | Proposed value |
|---|---|
| Sent log ID key | `ifx.hdr.peer.logid_sent[{#IFX_HDR_PEER}]` |
| Sent log page key | `ifx.hdr.peer.logpage_sent[{#IFX_HDR_PEER}]` |
| Acked log ID key | `ifx.hdr.peer.logid_acked[{#IFX_HDR_PEER}]` |
| Acked log page key | `ifx.hdr.peer.logpage_acked[{#IFX_HDR_PEER}]` |
| Type | Dependent item prototypes |
| Master item | Approved common HDR master item |

### 7.2 Derived backlog item

| Element | Proposed value |
|---|---|
| Backlog key | `ifx.hdr.peer.log_backlog[{#IFX_HDR_PEER}]` |
| Units | Undefined until formula and unit are validated. |
| Type | Dependent item prototype, only after backlog contract approval. |

## 8. Threshold Policy

The optional thresholds are:

| Parameter | Meaning |
|---|---|
| `IFX_HDR_LOG_BACKLOG_WARNING` | Warning threshold in the validated backlog unit. |
| `IFX_HDR_LOG_BACKLOG_HIGH` | High threshold in the validated backlog unit. |

Both parameters remain unused until the backlog unit is formally defined. Empty values disable alerting.

Thresholds must be evaluated only while HDR-004 reports `CONNECTED`. A disconnected peer is governed by the connectivity problem; lag thresholds must not mask or duplicate it.

## 9. Failure and Unknown Behavior

| Condition | Expected behavior |
|---|---|
| Candidate fields absent | Metric remains unsupported/deferred on that target version. |
| Progress fields present but semantics unvalidated | Collect no derived backlog; retain no production threshold. |
| Values are inconsistent or regress unexpectedly | Preserve raw evidence and report unknown/collection failure according to approved parser rules. |
| Peer disconnected | Do not assert a normal backlog; HDR-004 owns the availability alert. |
| Source query fails | Never replace prior non-zero backlog with zero. |

## 10. Mock Validation

After a source formula is approved, fixtures must cover:

| Case | Expected result |
|---|---|
| Sent and acknowledged progress equal | Validated zero backlog. |
| Peer slightly behind | Positive backlog below warning. |
| Backlog above warning | Warning problem. |
| Backlog above high | High problem. |
| Log rollover | Correct backlog according to validated formula. |
| Inconsistent or reverse progress | Unknown/error; never a negative healthy value. |
| Disconnected peer | Connectivity problem; backlog alert suppressed. |

## 11. Acceptance Criteria

- Target `syscluster` progress fields are documented and observed on real HDR.
- A backlog formula and unit are proven across normal progression and rollover.
- Raw progress values are retained for diagnosis.
- Thresholds cannot be configured meaningfully until their unit is documented.
- Connectivity gating prevents duplicate or misleading lag alerts.

