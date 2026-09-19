# Monitoring Metric Catalog

## 1. Purpose

This document defines the monitoring metric catalog for the AIX Informix Zabbix project.

The catalog translates monitoring requirements into explicit engineering metrics before implementation begins.

It establishes:

- what shall be monitored;
- why the metric exists;
- its candidate source;
- expected collection method;
- metric semantics;
- expected collection frequency;
- collection cost;
- discovery requirements;
- alerting relevance;
- visualization relevance;
- validation status.

This document does not yet define the final SQL statements, commands, collectors or thresholds.

Those shall be validated against real IBM Informix and IBM AIX environments before implementation.

---

# 2. Metric Status

Each metric shall progress through the following lifecycle:

```text
DEFINED
   ↓
SOURCE_VALIDATED
   ↓
COLLECTION_VALIDATED
   ↓
IMPLEMENTED
   ↓
RUNTIME_VALIDATED
```

Initial metrics in this catalog are considered:

`DEFINED`

unless explicitly stated otherwise.

---

# 3. Frequency Classes

Exact collection intervals are intentionally deferred.

The catalog initially uses frequency classes.

| Class | Intended Behavior |
|---|---|
| HIGH | Near-real-time operational condition |
| MEDIUM | Regular performance monitoring |
| LOW | Capacity, configuration or expensive collection |
| EVENT | Event-oriented collection |
| DISCOVERY | Resource discovery |

Exact intervals shall be established after collection cost is measured.

---

# 4. Collection Cost Classes

| Class | Meaning |
|---|---|
| LOW | Expected to be safe for frequent collection |
| MEDIUM | Requires validation before frequent collection |
| HIGH | Potentially expensive; caching or reduced frequency may be required |
| UNKNOWN | Must be measured during source validation |

---

# 5. Instance Availability and Health

## IFX-HEALTH-001 — Instance State

**Purpose**

Determine the current native operational mode of the Informix instance.

**Authoritative Source**

`sysmaster:sysshmhdr`, using `name = 'mode'`.

**Collection Method**

Remote SQL collector through the Informix Client SDK, exposed by a Zabbix Agent active item.

**Type**

State.

**Unit**

Native Informix mode code.

**Semantics**

Current engine mode observed at collection time.

**Frequency**

One minute in the development topology.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Yes. A High-severity problem is configured when the returned code differs from `5` (`Online`), and separately when no state is collected for three minutes.

**Grafana**

Pending.

**Validation Status**

DEVELOPMENT_RUNTIME_VALIDATED.

The Linux development topology validated the remote SQL source, parameterized installed collector, active Zabbix item and trigger configuration. Target Informix/AIX validation remains pending.

---

## IFX-HEALTH-002 — Instance Uptime

**Purpose**

Determine elapsed time since the current Informix engine startup.

**Authoritative Source**

`sysmaster:sysshmhdr`, using `name = 'bttime'`.

**Collection Method**

Remote SQL collector through the Informix Client SDK, exposed by a Zabbix Agent active item.

**Type**

Gauge.

**Unit**

Seconds, returned as `INT8`.

**Semantics**

Current uptime.

**Frequency**

One minute in the development topology.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Yes. A Warning-severity restart event is configured when the current uptime is lower than the preceding valid sample.

**Grafana**

Pending.

**Validation Status**

DEVELOPMENT_RUNTIME_VALIDATED.

The Linux development topology validated the `bttime` SQL source, monotonic uptime growth, installed collector, active Zabbix item and restart-trigger configuration. Target Informix/AIX validation remains pending.

---

## IFX-HEALTH-003 — Assert Failures

**Purpose**

Detect newly recorded critical Informix assertion-failure events.

**Authoritative Source**

`sysadmin:ph_alert`

Only Event Alarm records with Class ID `6` and Event ID `6300` or `6500` are classified as assertion failures.

**Collection Method**

Stateful remote SQL collector executed through the Informix Client SDK and exposed through a Zabbix Agent active item.

**Type**

Event batch and derived counter.

**Unit**

Failures.

**Semantics**

New classified assertion-failure events since the persisted `ph_alert.id` cursor.

**Frequency**

One-minute Zabbix active-check interval in the development topology.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Yes. A High-severity problem is opened when the derived assertion-failure count is greater than zero.

**Grafana**

Pending.

**Validation Status**

DEVELOPMENT_RUNTIME_VALIDATED.

The Linux development topology validated the remote SQL source, protected persistent state, collector locking, Zabbix Agent active collection, dependent counter item and High-severity trigger. Target Informix/AIX validation remains pending.

---

## IFX-HEALTH-004 — Checkpoint Count

**Purpose**

Measure cumulative Informix checkpoint activity.

**Validated Source**

`sysmaster:sysshmhdr.pf_numckpts`

**SQL Contract**

```sql
SELECT
    CAST(value AS INT8) AS checkpoint_count
FROM sysshmhdr
WHERE name = 'pf_numckpts';
```

**Collection Method**

Remote SQL collector through Informix Client SDK and Zabbix Agent active check.

**Zabbix Key**

`ifx.health.checkpoint_count`

**Type**

Counter.

**Unit**

Checkpoints.

**Semantics**

Raw cumulative checkpoint counter. A stable value is valid when no checkpoint occurs. A decrease can occur after instance restart or counter reset and must be interpreted together with `IFX-HEALTH-002 — Instance Uptime`.

**Frequency**

1 minute.

**Cost**

Low in the validated Linux development topology. Target Informix/AIX runtime cost remains pending.

**Discovery**

No.

**Trigger**

No direct trigger initially. Use the counter for trends and derived checkpoint-rate visualizations.

**Grafana**

Yes.

**Derived Metrics**

- checkpoints/minute;
- checkpoints/hour.

**Validation Status**

DEVELOPMENT_RUNTIME_VALIDATED.

---

## IFX-HEALTH-005 — Checkpoint Duration

**Purpose**

Measure the duration of the most recently completed Informix checkpoint.

**Validated Source**

`sysmaster:syscheckpoint.cp_time`

**SQL Contract**

```sql
SELECT FIRST 1
    cp_time AS checkpoint_duration_seconds
FROM syscheckpoint
ORDER BY clock_time DESC;
```

**Collection Method**

Remote SQL collector through Informix Client SDK and Zabbix Agent active check.

**Zabbix Key**

`ifx.health.checkpoint_duration`

**Type**

Gauge.

**Unit**

Seconds, with fractional precision.

**Semantics**

`cp_time` is the elapsed duration from checkpoint pending until checkpoint completion for the most recent checkpoint record.

**Frequency**

1 minute.

**Cost**

Low in the validated Linux development topology. Target Informix/AIX runtime cost remains pending.

**Discovery**

No.

**Trigger**

No direct trigger initially. Establish an environment-specific baseline before defining a duration threshold.

**Grafana**

Yes.

**Derived Metrics**

- checkpoint-duration trend;
- checkpoint-duration baseline deviation;
- correlation with checkpoint count, waits and write activity.

**Validation Status**

DEVELOPMENT_RUNTIME_VALIDATED.

---

## IFX-HEALTH-006 — Checkpoint Waits

**Purpose**

Measure the cumulative number of Informix thread waits for checkpoint completion.

**Validated Source**

`sysmaster:sysshmhdr.pf_ckptwts`

**SQL Contract**

```sql
SELECT
    CAST(value AS INT8) AS checkpoint_wait_count
FROM sysshmhdr
WHERE name = 'pf_ckptwts';
```

**Collection Method**

Remote SQL collector through Informix Client SDK and Zabbix Agent active check.

**Zabbix Key**

`ifx.health.checkpoint_waits`

**Type**

Counter.

**Unit**

Waits.

**Semantics**

Raw cumulative count of waits for checkpoint completion. A decrease can occur after an instance restart or source reset and must be interpreted with `IFX-HEALTH-002 — Instance Uptime`.

`syscheckpoint.n_crit_waits` remains a different per-checkpoint diagnostic value and is not the HEALTH-006 source.

**Frequency**

1 minute.

**Cost**

Low in the validated Linux development topology. Target Informix/AIX runtime cost remains pending.

**Discovery**

No.

**Trigger**

No direct trigger initially. Use the counter for trends and derived wait-rate visualizations.

**Grafana**

Yes.

**Derived Metrics**

- checkpoint waits/minute;
- checkpoint waits/hour;
- checkpoint waits per checkpoint;
- correlation with checkpoint duration and write activity.

**Validation Status**

DEVELOPMENT_RUNTIME_VALIDATED.

---

## IFX-HEALTH-007 — LRU Writes

**Purpose**

Measure cumulative buffer writes performed through the Informix LRU mechanism.

**Validated Source**

`sysmaster:sysprofile.lruwrites`

**SQL Contract**

```sql
SELECT
    CAST(value AS INT8) AS lru_write_count
FROM sysprofile
WHERE name = 'lruwrites';
```

**Collection Method**

Remote SQL collector through Informix Client SDK and Zabbix Agent active check.

**Zabbix Key**

`ifx.health.lru_writes`

**Type**

Counter.

**Unit**

Writes.

**Semantics**

Raw cumulative LRU-write counter. A decrease can occur after an instance restart or source reset and must be interpreted with `IFX-HEALTH-002 — Instance Uptime`.

**Frequency**

1 minute.

**Cost**

Low in the validated Linux development topology. Target Informix/AIX runtime cost remains pending.

**Discovery**

No.

**Trigger**

No direct trigger initially. Use the counter for trends and derived write-rate visualizations.

**Grafana**

Yes.

**Derived Metrics**

- LRU writes/minute;
- LRU writes/hour;
- LRU writes per checkpoint;
- correlation with foreground writes and checkpoint duration.

**Validation Status**

DEVELOPMENT_RUNTIME_VALIDATED.

---

## IFX-HEALTH-008 — Foreground Writes

**Purpose**

Measure cumulative foreground buffer writes and identify buffer-cleaning pressure.

**Validated Source**

`sysmaster:sysprofile.fgwrites`

**SQL Contract**

```sql
SELECT
    CAST(value AS INT8) AS foreground_write_count
FROM sysprofile
WHERE name = 'fgwrites';
```

**Collection Method**

Remote SQL collector through Informix Client SDK and Zabbix Agent active check.

**Zabbix Key**

`ifx.health.foreground_writes`

**Type**

Counter.

**Unit**

Writes.

**Semantics**

Raw cumulative foreground-write counter. A decrease can occur after an instance restart or source reset and must be interpreted with `IFX-HEALTH-002 — Instance Uptime`.

Foreground writes can indicate that a session needed buffers cleaned immediately; correlate their rate with LRU writes and checkpoint activity.

**Frequency**

1 minute.

**Cost**

Low in the validated Linux development topology. Target Informix/AIX runtime cost remains pending.

**Discovery**

No.

**Trigger**

No direct trigger initially. Use the counter for trends and derived write-rate visualizations.

**Grafana**

Yes.

**Derived Metrics**

- foreground writes/minute;
- foreground writes/hour;
- foreground-to-LRU write ratio;
- correlation with checkpoint duration and checkpoint waits.

**Validation Status**

DEVELOPMENT_RUNTIME_VALIDATED.

---

# 6. Connections, Sessions and Concurrency

## IFX-SESSION-001 — Total Connected Sessions

**Purpose**

Measure the number of currently connected Informix sessions.

**Candidate Source**

`sysmaster`.

Exact authoritative source and SQL remain pending real source validation.

**Collection Method**

SQL statement.

**Type**

Gauge.

**Unit**

Sessions.

**Frequency**

HIGH or MEDIUM.

**Cost**

LOW — provisional until real source validation.

**Discovery**

No.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

MOCK_VALIDATED.

---

## IFX-SESSION-002 — Active Sessions

**Purpose**

Measure the number of sessions currently classified as active according to the authoritative Informix source.

The exact operational definition of an active session remains pending real source validation.

**Candidate Source**

`sysmaster`.

Exact authoritative source and SQL remain pending real source validation.

**Collection Method**

SQL statement.

**Type**

Gauge.

**Unit**

Sessions.

**Frequency**

HIGH or MEDIUM.

**Cost**

LOW to MEDIUM — provisional until real source validation.

**Discovery**

No.

**Trigger**

Normally no direct trigger.

**Grafana**

Yes.

**Validation Status**

MOCK_VALIDATED.

---

## IFX-SESSION-003 — Historical Session Peak

**Purpose**

Measure the maximum simultaneous session count maintained by an authoritative Informix statistic since its relevant engine lifecycle, reset or statistics boundary.

The metric shall not be silently replaced by a maximum derived from Zabbix history.

If real source validation proves that Informix does not maintain an authoritative statistic with the required semantic, the metric returns to architectural review.

**Candidate Source**

Informix-maintained internal statistics exposed through `sysmaster` or `onstat`.

Exact authoritative source remains pending real source validation.

**Collection Method**

Statement or collector against the authoritative Informix-maintained statistic.

**Type**

Gauge / historical maximum.

**Unit**

Sessions.

**Frequency**

MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

No.

**Trigger**

Potentially when approaching configured session capacity.

**Grafana**

Yes.

**Validation Status**

MOCK_VALIDATED.

---

## IFX-SESSION-004 — Waiting Threads Total

**Purpose**

Measure the current total number of Informix threads classified as waiting by the authoritative source.

The metric represents current waiting state, not a cumulative wait-event counter.

**Candidate Source**

`sysmaster` or `onstat`.

Exact authoritative source and waiting-state semantics remain pending real source validation.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Threads.

**Frequency**

HIGH or MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

No.

**Trigger**

Potentially based on sustained waiting-thread conditions after operational baselines are established.

**Grafana**

Yes.

**Validation Status**

MOCK_VALIDATED.

---

## IFX-SESSION-005 — Waiting Threads by Reason

**Purpose**

Measure the current number of Informix threads waiting under each authoritative native wait reason.

The metric provides the dynamic diagnostic decomposition of waiting threads without inventing or silently grouping native wait reasons.

**Candidate Source**

`sysmaster` or `onstat`.

Exact authoritative source, wait-reason identity and taxonomy remain pending real source validation.

**Collection Method**

Collector producing a normalized dynamic wait-reason dataset.

**Type**

Gauge.

**Unit**

Threads.

**Frequency**

HIGH.

Final collection frequency remains subject to real collection-cost validation.

**Cost**

UNKNOWN.

**Discovery**

Yes — Zabbix Low-Level Discovery.

Preferred discovery identity is an authoritative stable wait-reason identifier when Informix provides one.

**Trigger**

Potentially by specific wait reason after authoritative semantics and operational baselines are established.

**Grafana**

Yes.

Dynamic wait-reason dimensions are intended for diagnostic visualization and correlation.

**Relationship with IFX-SESSION-004**

The relationship:

`IFX-SESSION-004 = SUM(IFX-SESSION-005 reason counts)`

is currently:

`UNPROVEN`

It shall not be assumed until real source validation establishes compatible scope, completeness, exclusivity and timing semantics.

**Validation Status**

MOCK_VALIDATED.

---

# 7. Locks, Deadlocks and Contention

## IFX-LOCK-001 — Sessions Waiting for Locks

**Purpose**

Measure sessions currently blocked waiting for locks.

**Candidate Source**

`sysmaster`.

**Collection Method**

SQL statement.

**Type**

Gauge.

**Unit**

Sessions.

**Frequency**

HIGH.

**Cost**

LOW to MEDIUM.

**Discovery**

No.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-LOCK-002 — Maximum Lock Wait Time

**Purpose**

Measure the age of the longest currently blocked lock wait.

**Candidate Source**

`sysmaster`.

**Collection Method**

SQL statement.

**Type**

Gauge.

**Unit**

Seconds.

**Frequency**

HIGH.

**Cost**

MEDIUM.

**Discovery**

No.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-LOCK-003 — Deadlocks

**Purpose**

Measure deadlocks detected by the Informix engine.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Counter.

**Unit**

Deadlocks.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Yes, preferably using change or rate.

**Grafana**

Yes.

**Derived Metrics**

- deadlocks/second;
- deadlocks/minute.

**Validation Status**

DEFINED.

---

## IFX-LOCK-004 — Latch Waits

**Purpose**

Identify internal contention involving Informix shared-memory synchronization structures.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Counter or gauge depending on validated source.

**Unit**

Waits.

**Frequency**

MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

Potentially no.

**Trigger**

Potentially after baseline validation.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-LOCK-005 — Buffer Waits

**Purpose**

Measure contention or waits involving buffer pool access.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Counter.

**Unit**

Waits.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Potentially based on rate and baseline.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

# 8. SQL and Query Performance

## IFX-SQL-001 — Long Running SQL Count

**Purpose**

Count currently executing SQL operations exceeding a defined execution-time threshold.

**Candidate Source**

`sysmaster`.

**Collection Method**

SQL statement.

**Type**

Gauge.

**Unit**

Queries.

**Frequency**

MEDIUM.

**Cost**

MEDIUM.

**Discovery**

No.

**Trigger**

Potentially.

**Grafana**

Yes.

**Threshold**

Not yet defined.

**Validation Status**

DEFINED.

---

## IFX-SQL-002 — Longest Running SQL

**Purpose**

Measure the runtime of the oldest currently executing SQL operation.

**Candidate Source**

`sysmaster`.

**Collection Method**

SQL statement.

**Type**

Gauge.

**Unit**

Seconds.

**Frequency**

MEDIUM.

**Cost**

MEDIUM.

**Discovery**

No.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-SQL-003 — Sequential Scans

**Purpose**

Measure sequential table scan activity.

**Candidate Source**

`sysmaster` or Informix engine statistics.

**Collection Method**

Statement or collector.

**Type**

Counter.

**Unit**

Scans.

**Frequency**

MEDIUM.

**Cost**

LOW to MEDIUM.

**Discovery**

No initially.

**Trigger**

No fixed threshold initially.

**Grafana**

Yes.

**Derived Metric**

Sequential scans/second.

**Validation Status**

DEFINED.

---

## IFX-SQL-004 — Indexed Read Activity

**Purpose**

Provide a comparison point against sequential scan activity where technically measurable and semantically meaningful.

**Candidate Source**

To be determined during source validation.

**Collection Method**

To be determined.

**Type**

Counter.

**Unit**

Operations.

**Frequency**

MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

No.

**Trigger**

No initially.

**Grafana**

Yes.

**Validation Status**

DEFINED — SOURCE REQUIRES INVESTIGATION.

---

## IFX-SQL-005 — Buffer Cache Hit Ratio

**Purpose**

Measure the efficiency of Informix buffer cache reads.

**Candidate Source**

Informix engine counters through `sysmaster` or `onstat`.

**Collection Method**

Statement, collector or derived metric.

**Type**

Derived gauge.

**Unit**

Percent.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Discovery**

Potentially by buffer pool if useful.

**Trigger**

Potentially after workload baseline validation.

**Grafana**

Yes.

**Important**

A fixed 95% threshold shall not initially be treated as universally valid.

Expected behavior depends on workload and buffer pool configuration.

**Validation Status**

DEFINED.

---

## IFX-SQL-006 — High CPU Sessions

**Purpose**

Identify sessions responsible for comparatively high processing activity.

**Candidate Source**

Requires validation against Informix internal session/thread statistics.

**Collection Method**

Statement or collector.

**Type**

Ranking / diagnostic dataset.

**Unit**

To be determined.

**Frequency**

LOW or MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

No.

**Trigger**

No initially.

**Grafana**

Yes.

**Validation Status**

DEFINED — SOURCE REQUIRES INVESTIGATION.

---

## IFX-SQL-007 — High Memory Sessions

**Purpose**

Identify sessions responsible for comparatively high temporary or session-related memory consumption.

**Candidate Source**

Requires validation against Informix internal memory/session structures.

**Collection Method**

Statement or collector.

**Type**

Ranking / diagnostic dataset.

**Unit**

Bytes.

**Frequency**

LOW or MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

No.

**Trigger**

No initially.

**Grafana**

Yes.

**Validation Status**

DEFINED — SOURCE REQUIRES INVESTIGATION.

---

# 9. Storage and Capacity

## IFX-STORAGE-001 — Dbspace Total Capacity

**Purpose**

Measure total capacity for each dbspace.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

LOW.

**Cost**

LOW.

**Discovery**

Yes — Dbspace LLD.

**Trigger**

No direct trigger.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-STORAGE-002 — Dbspace Used Capacity

**Purpose**

Measure used capacity for each dbspace.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

LOW.

**Cost**

LOW.

**Discovery**

Yes.

**Trigger**

Indirectly through capacity conditions.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-STORAGE-003 — Dbspace Free Capacity

**Purpose**

Measure remaining capacity for each dbspace.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

LOW.

**Cost**

LOW.

**Discovery**

Yes.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-STORAGE-004 — Dbspace Used Percentage

**Purpose**

Measure percentage utilization for each dbspace.

**Candidate Source**

Derived from capacity metrics.

**Collection Method**

Zabbix-derived metric.

**Type**

Gauge.

**Unit**

Percent.

**Frequency**

Dependent.

**Cost**

LOW.

**Discovery**

Yes.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-STORAGE-005 — Chunk Status

**Purpose**

Detect chunks in abnormal operational states.

Possible states include conditions such as:

- Down;
- Physical Recovery;
- Logical Recovery.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

State.

**Unit**

State code.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Discovery**

Yes — Chunk LLD.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-STORAGE-006 — Chunk Capacity

**Purpose**

Measure capacity and free space for individual chunks where operationally useful.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

LOW.

**Cost**

LOW.

**Discovery**

Yes.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-STORAGE-007 — Sbspace Capacity

**Purpose**

Measure allocated and available smart-large-object storage.

**Candidate Source**

Informix system metadata / utilities.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

LOW.

**Cost**

UNKNOWN.

**Discovery**

Yes where multiple sbspaces exist.

**Trigger**

Yes for capacity.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-STORAGE-008 — Sbspace Object Count

**Purpose**

Measure stored smart large objects where a reliable and sufficiently low-cost source exists.

**Candidate Source**

To be validated.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Objects.

**Frequency**

LOW.

**Cost**

UNKNOWN.

**Discovery**

Potentially.

**Trigger**

No initially.

**Grafana**

Potentially.

**Validation Status**

DEFINED — SOURCE REQUIRES INVESTIGATION.

---

## IFX-STORAGE-009 — Temporary Dbspace Usage

**Purpose**

Measure temporary dbspace utilization generated by operations such as sorts and grouping.

**Candidate Source**

`sysmaster` or Informix utility.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes and percent.

**Frequency**

MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

Yes.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

# 10. Logical Logs, Physical Log and Backup

## IFX-LOG-001 — Total Logical Logs

**Purpose**

Measure configured logical log capacity/count.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Logs.

**Frequency**

LOW.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

No.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-LOG-002 — Logical Logs Pending Backup

**Purpose**

Measure filled logical logs that have not yet been successfully backed up.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Logs.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-LOG-003 — Logical Logs Pending Backup Percentage

**Purpose**

Represent pending logical log backup pressure relative to available logical log capacity.

**Candidate Source**

Derived from logical log metrics.

**Collection Method**

Zabbix-derived metric.

**Type**

Gauge.

**Unit**

Percent.

**Frequency**

Dependent.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-LOG-004 — ALARMPROGRAM Configuration State

**Purpose**

Verify that an expected Informix ALARMPROGRAM configuration exists.

**Candidate Source**

Informix configuration.

**Collection Method**

Collector or configuration inspection.

**Type**

State.

**Unit**

Boolean/state.

**Frequency**

LOW.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Potentially.

**Grafana**

Potentially.

**Important**

Configuration presence does not prove successful logical-log backup operation.

**Validation Status**

DEFINED.

---

## IFX-LOG-005 — Last Successful Logical Log Backup

**Purpose**

Determine when logical log backup last completed successfully.

**Candidate Source**

Backup process evidence, Informix metadata or operational logs.

**Collection Method**

Collector.

**Type**

Timestamp.

**Unit**

Unix timestamp.

**Frequency**

MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

No.

**Trigger**

Yes.

**Grafana**

Yes.

**Derived Metric**

Backup age in seconds.

**Validation Status**

DEFINED — SOURCE REQUIRES INVESTIGATION.

---

## IFX-LOG-006 — Logical Log Backup Failures

**Purpose**

Detect failures in automatic logical log backup processing.

**Candidate Source**

Operational log / backup process evidence.

**Collection Method**

Event collector.

**Type**

Event/counter.

**Unit**

Failures.

**Frequency**

EVENT.

**Cost**

LOW to MEDIUM.

**Discovery**

No.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-LOG-007 — Physical Log Total

**Purpose**

Measure total configured Physical Log capacity.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Pages and/or bytes.

**Frequency**

LOW.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

No.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-LOG-008 — Physical Log Used

**Purpose**

Measure current Physical Log consumption.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Pages and/or bytes.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Yes.

**Grafana**

Yes.

**Derived Metric**

Physical Log used percentage.

**Validation Status**

DEFINED.

---

# 11. Replication and High Availability

## IFX-HA-001 — Replication Role

**Purpose**

Identify the role of the monitored Informix instance.

Examples may include:

- primary;
- HDR secondary;
- RSS secondary;
- SDS secondary;
- standalone.

**Candidate Source**

Informix replication metadata or `onstat`.

**Collection Method**

Statement or collector.

**Type**

State.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Discovery**

Potentially.

**Trigger**

Potentially for unexpected role changes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-HA-002 — Replication Connection State

**Purpose**

Determine whether configured replication relationships are operational.

**Candidate Source**

Informix replication metadata or `onstat`.

**Collection Method**

Statement or collector.

**Type**

State.

**Frequency**

HIGH or MEDIUM.

**Cost**

LOW to MEDIUM.

**Discovery**

Yes where peers can be identified reliably.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-HA-003 — Replication Backlog

**Purpose**

Measure outstanding log data awaiting transmission or application by secondary servers.

**Candidate Source**

Informix replication metadata or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Pages or validated equivalent.

**Frequency**

MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

Yes where appropriate.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-HA-004 — Replication Delay

**Purpose**

Provide an operational representation of replication delay.

**Candidate Source**

Derived from replication/log-position information where technically valid.

**Collection Method**

Collector or derived metric.

**Type**

Gauge.

**Unit**

Seconds if a reliable time-based representation can be established.

**Frequency**

MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

Yes where appropriate.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED — SEMANTICS REQUIRE VALIDATION.

---

# 12. Informix Shared Memory

## IFX-MEM-001 — Total Informix Shared Memory

**Purpose**

Measure total memory allocated by the Informix engine.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

MEDIUM.

**Cost**

LOW to MEDIUM.

**Discovery**

No.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-MEM-002 — SHMTOTAL

**Purpose**

Collect the configured Informix shared-memory ceiling when applicable.

**Candidate Source**

Informix configuration.

**Collection Method**

Statement, configuration query or collector.

**Type**

Gauge/configuration.

**Unit**

Bytes.

**Frequency**

LOW.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

No directly.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-MEM-003 — Shared Memory vs SHMTOTAL

**Purpose**

Represent allocated Informix memory relative to the configured SHMTOTAL limit.

**Candidate Source**

Derived.

**Collection Method**

Zabbix-derived metric.

**Type**

Gauge.

**Unit**

Percent.

**Frequency**

Dependent.

**Cost**

LOW.

**Discovery**

No.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-MEM-004 — Resident Memory Segment

**Purpose**

Measure Informix resident shared-memory allocation.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

MEDIUM.

**Cost**

LOW to MEDIUM.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-MEM-005 — Virtual Memory Segment

**Purpose**

Measure Informix virtual shared-memory allocation.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

MEDIUM.

**Cost**

LOW to MEDIUM.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-MEM-006 — Buffer Pool Memory

**Purpose**

Measure memory allocated to Informix buffer pools.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

MEDIUM.

**Cost**

LOW to MEDIUM.

**Discovery**

Potentially by buffer pool/page size.

**Trigger**

No initially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-MEM-007 — Additional Shared Memory Segments

**Purpose**

Provide visibility into additional relevant Informix shared-memory segments or extents.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge.

**Unit**

Bytes.

**Frequency**

LOW or MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

Potentially.

**Trigger**

No initially.

**Grafana**

Yes.

**Validation Status**

DEFINED — STRUCTURE REQUIRES VALIDATION.

---

# 13. Informix Virtual Processors

VP monitoring shall initially focus on VP classes rather than individual transient threads.

## IFX-VP-001 — CPU VP Count / Activity

**Purpose**

Monitor CPU virtual processors responsible for SQL and engine processing.

**Candidate Source**

`sysmaster` or `onstat`.

**Collection Method**

Statement or collector.

**Type**

Gauge/counter.

**Unit**

VPs and activity.

**Frequency**

MEDIUM.

**Cost**

UNKNOWN.

**Discovery**

Potentially by VP class.

**Trigger**

Potentially after baseline validation.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## IFX-VP-002 — AIO VP Count / Activity

Monitor asynchronous I/O virtual processors.

Source, semantics and implementation require validation.

**Validation Status**

DEFINED.

---

## IFX-VP-003 — PIO VP Count / Activity

Monitor Physical Log I/O virtual processors.

Source, semantics and implementation require validation.

**Validation Status**

DEFINED.

---

## IFX-VP-004 — LIO VP Count / Activity

Monitor Logical Log I/O virtual processors.

Source, semantics and implementation require validation.

**Validation Status**

DEFINED.

---

## IFX-VP-005 — SOC VP Count / Activity

Monitor network socket virtual processors.

Source, semantics and implementation require validation.

**Validation Status**

DEFINED.

---

## IFX-VP-006 — SSL VP Count / Activity

Monitor SSL-related virtual processors where present.

Source, semantics and implementation require validation.

**Validation Status**

DEFINED.

---

# 14. IBM AIX Operating System

## AIX-CPU-001 — LPAR CPU Utilization

**Purpose**

Measure CPU utilization within the AIX LPAR.

**Candidate Source**

Native Zabbix AIX capability or AIX operating-system interface.

**Collection Method**

Native metric or collector.

**Type**

Gauge.

**Unit**

Percent.

**Frequency**

HIGH or MEDIUM.

**Cost**

LOW.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-CPU-002 — Physical CPU Consumption

**Purpose**

Measure physical processing capacity consumed by the LPAR.

**Candidate Source**

AIX LPAR statistics.

**Collection Method**

Native metric or collector.

**Type**

Gauge.

**Unit**

Physical processors / processing units.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-CPU-003 — Entitled Capacity

**Purpose**

Collect the LPAR entitled processing capacity.

**Candidate Source**

AIX LPAR configuration/statistics.

**Collection Method**

Native metric or collector.

**Type**

Gauge/configuration.

**Unit**

Processing units.

**Frequency**

LOW.

**Cost**

LOW.

**Trigger**

No directly.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-CPU-004 — Entitlement Utilization

**Purpose**

Compare consumed physical CPU against entitled capacity.

**Candidate Source**

Derived.

**Collection Method**

Zabbix-derived metric.

**Type**

Gauge.

**Unit**

Percent.

**Frequency**

Dependent.

**Trigger**

Yes where appropriate.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-MEM-001 — Physical Memory Usage

**Purpose**

Measure AIX physical memory utilization.

**Candidate Source**

Native Zabbix metric or AIX memory statistics.

**Collection Method**

Native metric.

**Type**

Gauge.

**Unit**

Bytes/percent.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-MEM-002 — Paging Space Usage

**Purpose**

Measure allocated Paging Space utilization.

**Candidate Source**

AIX.

Possible validation source:

`lsps -a`

**Collection Method**

Native metric or collector.

**Type**

Gauge.

**Unit**

Bytes/percent.

**Frequency**

MEDIUM.

**Cost**

LOW.

**Trigger**

Yes, but not solely from a universal percentage threshold.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-MEM-003 — Active Paging Activity

**Purpose**

Detect active page-in/page-out behavior indicating current memory pressure.

**Candidate Source**

AIX virtual-memory statistics.

**Collection Method**

Native metric or collector.

**Type**

Counter/rate.

**Unit**

Pages or operations per second.

**Frequency**

HIGH or MEDIUM.

**Cost**

LOW.

**Trigger**

Yes when sustained.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-IO-001 — Disk Throughput

**Purpose**

Measure read/write throughput of storage devices supporting Informix.

**Candidate Source**

AIX disk statistics.

**Collection Method**

Native metric or collector.

**Type**

Counter/rate.

**Unit**

Bytes/second.

**Frequency**

MEDIUM.

**Cost**

LOW to MEDIUM.

**Discovery**

Yes — disk/device discovery.

**Trigger**

Normally no direct static threshold.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-IO-002 — Disk IOPS

**Purpose**

Measure storage operation rate.

**Candidate Source**

AIX disk statistics.

**Collection Method**

Native metric or collector.

**Type**

Counter/rate.

**Unit**

Operations/second.

**Frequency**

MEDIUM.

**Cost**

LOW to MEDIUM.

**Discovery**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-IO-003 — Disk Service Time / Latency

**Purpose**

Measure storage response latency affecting Informix I/O.

**Candidate Source**

AIX disk statistics such as data exposed by `iostat` or equivalent native interfaces.

**Collection Method**

Native metric or collector.

**Type**

Gauge.

**Unit**

Milliseconds.

**Frequency**

MEDIUM.

**Cost**

MEDIUM.

**Discovery**

Yes.

**Trigger**

Yes after storage baseline validation.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-IO-004 — Disk Queue / I/O Pressure

**Purpose**

Identify sustained queueing or saturation on storage devices used by Informix.

**Candidate Source**

AIX disk statistics.

**Collection Method**

Native metric or collector.

**Type**

Gauge.

**Frequency**

MEDIUM.

**Cost**

MEDIUM.

**Discovery**

Yes.

**Trigger**

Potentially.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-IO-005 — Fibre Channel / vSCSI Errors

**Purpose**

Detect storage-path errors affecting Informix I/O.

**Candidate Source**

AIX device statistics and/or `errpt`.

**Collection Method**

Collector/event monitoring.

**Type**

Counter/event.

**Frequency**

EVENT or MEDIUM.

**Cost**

LOW to MEDIUM.

**Discovery**

Potentially by adapter.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-ERR-001 — New PERM Errors

**Purpose**

Detect new AIX permanent hardware or I/O errors.

**Candidate Source**

`errpt`.

**Collection Method**

Stateful event collector.

**Type**

Event/counter.

**Frequency**

EVENT.

**Cost**

LOW to MEDIUM.

**Discovery**

Potentially by resource class.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

## AIX-ERR-002 — New PEND Errors

**Purpose**

Detect relevant pending AIX errors.

**Candidate Source**

`errpt`.

**Collection Method**

Stateful event collector.

**Type**

Event/counter.

**Frequency**

EVENT.

**Cost**

LOW to MEDIUM.

**Discovery**

Potentially.

**Trigger**

Yes.

**Grafana**

Yes.

**Validation Status**

DEFINED.

---

# 15. Cross-Layer Correlations

The following relationships shall be preserved for future dashboard design and diagnostic analysis.

## Checkpoint / Storage

Correlate:

- checkpoint duration;
- checkpoint waits;
- disk latency;
- disk throughput;
- disk queue.

## Buffer Pressure

Correlate:

- LRU writes;
- foreground writes;
- buffer waits;
- buffer cache hit ratio;
- physical memory;
- active paging.

## Session Contention

Correlate:

- total sessions;
- active sessions;
- lock waits;
- maximum lock wait;
- latch waits;
- CPU utilization.

## Informix Memory / AIX Memory

Correlate:

- Informix shared memory;
- SHMTOTAL;
- resident segment;
- virtual segment;
- buffer pool;
- AIX physical memory;
- Paging Space;
- active paging.

## Replication

Correlate:

- replication connection;
- replication backlog;
- replication delay;
- logical log activity;
- disk I/O;
- network behavior.

## SQL Performance

Correlate:

- long-running SQL;
- sequential scans;
- active sessions;
- CPU;
- temporary dbspace usage;
- disk latency.

---

# 16. Metrics Requiring Special Investigation

The following metrics require additional technical validation before their collection semantics can be considered established:

- historical session peak;
- indexed read activity;
- high CPU sessions;
- high memory sessions;
- latch wait semantics;
- sbspace object count;
- replication delay expressed in seconds;
- detailed Informix VP utilization;
- additional shared-memory segment classification;
- exact backup-success evidence;
- some AIX storage latency semantics depending on available interfaces.

These metrics remain within project scope.

Their implementation shall not be invented before validation.

---

# 17. Initial Metric Catalog Decision

This catalog establishes the monitoring requirements.

It intentionally does not claim that every candidate source is correct.

The next engineering phase shall validate each metric against real Informix and AIX systems.

During validation, each metric may result in one of the following decisions:

```text
APPROVED
APPROVED_WITH_CHANGE
ALTERNATIVE_SOURCE_REQUIRED
DEFERRED
REJECTED
```

A metric shall only progress from:

`DEFINED`

to:

`SOURCE_VALIDATED`

after its actual source and semantics have been demonstrated.

---

# 18. Current Engineering Status

The initial Informix Instance Availability and Health metric set is:

`DEVELOPMENT_RUNTIME_VALIDATED`

```text
IFX-HEALTH-001  Instance State
IFX-HEALTH-002  Instance Uptime
IFX-HEALTH-003  Assert Failures
IFX-HEALTH-004  Checkpoint Count
IFX-HEALTH-005  Checkpoint Duration
IFX-HEALTH-006  Checkpoint Waits
IFX-HEALTH-007  LRU Writes
IFX-HEALTH-008  Foreground Writes
```

Development runtime validation confirms, for every metric:

- validated Informix source and SQL contract;
- remote SQL collection through Informix Client SDK;
- collector normalization and failure handling;
- parameterized deployment launcher;
- Zabbix Agent active-check execution;
- Zabbix template item and exported YAML definition.

The target-environment phase remains pending.

It must validate the same release against the target Informix version and topology, including Informix/AIX compatibility where applicable, monitoring-user permissions, query cost, counter reset behavior and environment-specific alert baselines.

`DEVELOPMENT_RUNTIME_VALIDATED` does not claim production acceptance or target Informix/AIX validation.