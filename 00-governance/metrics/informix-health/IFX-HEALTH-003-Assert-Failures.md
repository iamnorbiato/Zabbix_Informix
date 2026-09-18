# IFX-HEALTH-003 — Assert Failures

## 1. Purpose

This document defines the engineering specification and validation state of metric:

`IFX-HEALTH-003 — Assert Failures`

The metric represents newly observed IBM Informix assertion-failure events recorded in the Informix Event Alarm history (`sysadmin:ph_alert`).

This document is the authoritative engineering definition of this metric before Zabbix implementation.

---

## Authoritative Architecture Status

The operational collection architecture for this metric is remote SQL collection through `sysadmin:ph_alert`.

The earlier `online.log`-based material retained in this document is historical engineering context only. It is superseded for operational implementation and MUST NOT be used as the collector source, state model, or runtime contract.

The normative implementation contract is defined by the later sections:

- `## Source Validation`
- `## Incremental Collection State`

Current implementation status:

- SQL source and dataset contract: validated against `sysadmin:ph_alert`;
- query-layer `LAST_ID` parameterization: validated;
- persistent collector state and exclusive lock: implemented and validated;
- HEALTH-003 collector: implemented and validated;
- Zabbix Agent active item, dependent counter item and High-severity trigger: implemented and validated;
- Grafana integration: not implemented;
- target Informix/AIX validation: pending.

---

# 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-003`

Metric Name:

`Assert Failures`

---

# 3. Objective

The objective of this metric is to detect new Informix assertion failures and expose them to the monitoring platform without repeatedly reporting historical failures already processed.

The metric shall support:

- detection of newly occurring assertion failures;
- alerting on new assertion-failure events;
- historical counting of assertion failures;
- preservation of relevant diagnostic context;
- correlation with instance state, restarts, storage, memory and AIX events.

---

# 4. Candidate Source

Primary candidate source:

```text
Informix online message log
```

The log location is controlled by the Informix:

```text
MSGPATH
```

configuration parameter.

A typical UNIX default may be:

```text
$INFORMIXDIR/tmp/online.log
```

but no collector shall assume this path without configuration or source validation.

The actual target path must be determined from the target Informix configuration.

---

# 5. Assertion Failure Identification

The initial candidate event marker is:

```text
Assert Failed:
```

Representative form:

```text
Assert Failed: <failure description>
```

The occurrence of this marker in the Informix online message log represents the beginning of an assertion-failure diagnostic message.

The parser shall initially treat:

```text
Assert Failed:
```

as distinct from:

```text
Assert Warning:
```

`Assert Warning` shall not automatically be counted as an `IFX-HEALTH-003` assertion failure.

If monitoring of assertion warnings is later required, it shall be modeled separately or explicitly incorporated through a documented change.

---

# 6. Diagnostic Context

An assertion-failure log entry may be followed by diagnostic information such as:

```text
Who:
Thread:
File:
Line:
Result:
Action:
stack trace
See Also:
```

The associated diagnostic output may reference an Informix assertion-failure file such as:

```text
af.<identifier>
```

The exact fields and formatting may vary by Informix version and failure type.

The collector must therefore distinguish between:

1. detecting the event;
2. preserving useful context;
3. interpreting the cause.

`IFX-HEALTH-003` is responsible primarily for event detection.

It shall not attempt to diagnose the root cause of an assertion failure.

---

# 7. Associated AF Files

Informix may create diagnostic files with names similar to:

```text
af.<identifier>
```

Their location is controlled by:

```text
DUMPDIR
```

These files contain diagnostic information related to assertion failures.

They are not currently the primary source for `IFX-HEALTH-003`.

The initial architecture is:

```text
online.log
    │
    ├── Detect Assert Failed event
    │
    └── Optional reference to af.* diagnostic artifact
```

The collector shall not require reading the full `af.*` file merely to determine whether an assertion failure occurred.

---

# 8. Metric Semantics

`IFX-HEALTH-003` has two related semantics:

```text
EVENT
```

and:

```text
COUNTER
```

The primary source observation is event-oriented.

Each newly detected assertion failure represents one event.

The monitoring platform may derive or maintain:

- total detected events;
- events per interval;
- events per hour/day;
- time since last assertion failure.

The collector itself shall avoid maintaining unnecessary monitoring aggregates if Zabbix can derive them from raw observations.

---

# 9. Event Identity

An assertion failure must not be repeatedly reported on every collection cycle simply because the historical message still exists in `online.log`.

The collector therefore requires stateful log processing.

Conceptually:

```text
online.log
    │
    ▼
last processed position
    │
    ▼
new log content only
    │
    ▼
new Assert Failed events
```

Historical content that has already been processed shall not be emitted again.

---

# 10. Initial Collection State

When monitoring an existing `online.log` for the first time, the collector must explicitly define bootstrap behavior.

The initial preferred behavior is:

```text
establish current end-of-file position
```

and then monitor only new events written after monitoring begins.

This prevents potentially old assertion failures from immediately generating production alerts.

Alternative historical scanning may be useful during diagnostics but shall not be the default production behavior.

The final bootstrap policy remains subject to implementation and operational approval.

---

# 11. State Persistence

The future collector will require persistent state sufficient to determine which portion of the log was already processed.

Candidate state information may include:

- file path;
- file identity;
- last byte offset;
- last processed timestamp;
- optional event fingerprint.

The exact state-file format and location remain deferred.

State must survive normal collector executions.

---

# 12. Log Growth

For normal append-only growth:

```text
previous size < current size
```

the collector shall read only content appended after the previously processed position.

The existing historical portion shall not be reparsed as new telemetry.

---

# 13. Log Truncation

If:

```text
current size < saved offset
```

the collector must assume that the log may have been truncated, recreated or replaced.

The collector shall not blindly continue using the old offset.

It shall re-establish log state safely and avoid:

- skipping all future events;
- repeatedly reprocessing historical events;
- interpreting truncation itself as an assertion failure.

Exact recovery behavior will be defined during collector implementation.

---

# 14. Log Rotation or Replacement

If the online log is rotated, replaced or recreated, file path alone may not be sufficient to identify continuity.

The future implementation should be capable of detecting that the underlying file changed.

On UNIX-like systems this may involve file identity information in addition to size and offset.

AIX compatibility must be validated before choosing the mechanism.

---

# 15. Multiple Events in One Collection

More than one assertion failure may occur between collector executions.

Example:

```text
previous read
    │
    ├── Assert Failed event A
    ├── normal messages
    ├── Assert Failed event B
    └── new read position
```

The collector must not collapse these into a single event.

If two independent `Assert Failed:` markers are detected in new content:

```text
event_count = 2
```

---

# 16. Event Boundary

For mock validation, an event begins when a new line contains the candidate marker:

```text
Assert Failed:
```

Following diagnostic lines may belong to the same assertion-failure event.

The next independent `Assert Failed:` marker begins another event.

The exact amount of diagnostic context preserved with an event will be defined separately from basic counting.

---

# 17. Timestamp Handling

The Informix online log commonly includes time information associated with messages.

The collector should preserve the source timestamp where reliably available.

However:

- timestamp parsing shall not be required merely to detect an assertion failure;
- malformed timestamps shall not cause an otherwise valid assertion-failure event to disappear;
- exact timestamp grammar must be validated against the target Informix version.

Collector observation time and source event time are different concepts and should not be silently conflated.

---

# 18. Expected Primary Output

For the minimum collection model, the collector should be capable of returning:

```text
number of newly detected assertion failures
```

for the new portion of the log.

Examples:

```text
0
1
2
3
...
```

This value represents newly observed events for that collection window, not the lifetime total contained in the log.

---

# 19. Event Detail Output

A future event-detail mechanism may additionally expose information such as:

```text
source timestamp
failure description
Who
Thread
File
Line
Result
Action
AF file reference
```

Not all fields are guaranteed to exist.

Missing optional diagnostic fields shall not invalidate the assertion-failure event itself.

---

# 20. Zero Semantics

For this metric:

```text
0
```

is a legitimate result only when:

- log collection succeeded;
- the relevant new log range was successfully processed;
- no new assertion failures were found.

A collection failure must not become:

```text
0
```

because that would falsely indicate that the collector successfully verified absence of new assertion failures.

---

# 21. Collection Failure

Examples of collection failure include:

- online log does not exist;
- log path cannot be determined;
- permission denied;
- state file cannot be read or safely updated;
- unexpected log replacement condition cannot be handled safely;
- read operation fails;
- collector internal failure.

These conditions must be represented separately from:

```text
0 new assertion failures
```

---

# 22. Assert Warning Distinction

For the current metric definition:

```text
Assert Failed:
```

is considered a candidate assertion-failure event.

The following:

```text
Assert Warning:
```

is not counted by `IFX-HEALTH-003`.

This distinction is intentional.

Warnings may still represent important Informix conditions, but their severity and semantics are not assumed to be identical to assertion failures.

Monitoring of `Assert Warning` shall require an explicit metric or specification change.

---

# 23. Case Sensitivity

Canonical source text shall be preserved in mocks.

The parser may use case-insensitive matching if necessary for compatibility.

However, matching must remain specific enough to distinguish:

```text
Assert Failed:
```

from unrelated messages.

Loose matching such as:

```text
Assert
```

alone is not acceptable.

---

# 24. Historical Events

Existing historical assertion failures in the log are operationally useful for diagnostics but are different from newly observed monitoring events.

Therefore the architecture distinguishes:

```text
historical scan
```

from:

```text
continuous monitoring
```

The production monitoring collector shall not continuously recount all historical matches in the entire file.

---

# 25. Candidate Zabbix Representation

The eventual Zabbix model may contain more than one item derived from this collection source.

Conceptual examples:

```text
informix.assert.new.count
informix.assert.last.message
informix.assert.last.timestamp
```

Final Zabbix naming and item structure remain deferred.

A single collection execution may feed multiple dependent metrics.

---

# 26. Alerting Relevance

Alerting:

`YES`

A new genuine Informix assertion failure is operationally significant.

Initial alert semantics should be based on:

```text
new assertion failure detected
```

rather than:

```text
the log contains an assertion failure somewhere
```

This avoids persistent alerts caused solely by historical entries.

Final severity and recovery behavior remain deferred until Zabbix trigger design.

---

# 27. Grafana Relevance

Grafana:

`YES`

Expected uses include:

- assertion failures over time;
- last detected failure;
- correlation with instance state;
- correlation with restarts;
- correlation with checkpoint anomalies;
- correlation with AIX hardware/I/O events;
- correlation with storage and memory pressure.

Grafana shall visualize collected monitoring data rather than independently scanning the Informix log.

---

# 28. Candidate Collection Frequency

Frequency class:

`EVENT`

Collection should occur frequently enough to provide useful operational detection.

The exact polling interval is not yet defined.

Collection frequency must balance:

- detection latency;
- log size;
- filesystem overhead;
- Zabbix polling model.

---

# 29. Expected Collection Cost

Expected normal incremental cost:

`LOW`

provided the implementation reads only newly appended data.

Repeatedly scanning the complete `online.log` would increase cost as the log grows and is therefore not the intended architecture.

---

# 30. Discovery Requirement

Low-Level Discovery:

`NO`

for a single Informix instance log.

If an AIX host contains multiple Informix instances, instance discovery/modeling shall be addressed separately.

Each monitored instance must maintain independent log state.

---

# 31. Security and Permissions

The collector requires read access to the Informix online message log.

The monitoring identity should receive only the permissions required for collection.

The collector shall not:

- modify `online.log`;
- delete log content;
- modify `af.*` files;
- alter Informix diagnostic configuration.

---

# 32. Monitoring Impact Protection

The collector must avoid:

- reading the entire growing log on every cycle;
- loading large logs entirely into memory;
- repeatedly reading diagnostic dumps;
- performing expensive regex processing over historical content.

Incremental processing is required for the eventual production collector.

---

# 33. Mock Validation Scope

Because the real Informix environment is currently unavailable, mock validation shall verify the logical behavior of:

1. no assertion failure;
2. one assertion failure;
3. multiple assertion failures;
4. assertion failure with diagnostic context;
5. `Assert Warning` without `Assert Failed`;
6. mixed normal and failure messages;
7. historical content not reprocessed;
8. new content processed after saved position;
9. empty new content;
10. malformed/unexpected log content;
11. collection/read failure semantics.

---

# 34. Mock Event Examples

A minimal candidate event may resemble:

```text
10:08:20 Assert Failed: Example failure
10:08:20 Who: Session(...)
10:08:20 Thread(...)
10:08:20 File: example.c Line: 123
10:08:20 Action: Example action
10:08:20 See Also: /informix/tmp/af.example
```

Mock content shall be treated as representative only.

It shall not establish an authoritative Informix diagnostic format until real source validation occurs.

---

# 35. Real Environment Validation Criteria

The metric may progress to:

```text
SOURCE_VALIDATED
```

only after validation against the real Informix/AIX environment confirms:

- actual `MSGPATH`;
- actual log permissions;
- actual `Assert Failed:` representation;
- actual multiline diagnostic structure;
- timestamp representation;
- behavior of `Assert Warning`;
- log rotation/truncation behavior;
- AF-file references;
- log growth characteristics;
- safe incremental-reading strategy.

---

# 36. Collection Architecture Consideration

Unlike `IFX-HEALTH-001` and `IFX-HEALTH-002`, which currently use command output, `IFX-HEALTH-003` requires stateful collection.

Conceptually:

```text
online.log
      │
      ▼
incremental reader
      │
      ├── persistent read position
      ├── event detection
      └── context extraction
      │
      ▼
normalized collection result
      │
      ▼
Zabbix
```

This is the first metric in the project that requires persistent collector state.

Therefore implementation of this metric will also establish an important reusable pattern for future log-oriented metrics.

---

# 37. Current Status

Current lifecycle state:

`DEVELOPMENT_RUNTIME_VALIDATED`

Authoritative source:

`sysadmin:ph_alert`

Classification:

`Class ID 6 with Event ID 6300 or 6500`

Collection architecture:

`Stateful remote SQL collector using the Informix Client SDK and Zabbix Agent active checks`

Development validation completed:

- protected state directory and `last_id` cursor;
- bootstrap and incremental collection behavior;
- invalid cursor and concurrent collector lock handling;
- structured standard output containing only `COUNT|...` and optional `EVENT|...` lines;
- protected temporary batch, result, rendered-statement and diagnostic files;
- Zabbix raw item, dependent numeric counter and High-severity trigger;
- isolated synthetic assertion-event test, including problem opening and recovery.

Development topology:

`Informix and Zabbix Server on home; Informix Client SDK and Zabbix Agent on cluster-prime`

Target Informix/AIX validation:

`PENDING`

Grafana integration:

`PENDING`

---

# 38. Exit Criteria

The development-runtime implementation phase is complete when:

- the authoritative remote SQL source is defined;
- assertion-failure classification is explicitly defined;
- bootstrap and incremental cursor semantics are implemented;
- protected persistent state and exclusive locking are implemented;
- collector output contains only the structured batch contract on standard output;
- Zabbix collection, derived counter and trigger behavior are validated.

These criteria are satisfied for the Linux development topology.

Before promotion to target-environment validation, the implementation must be validated against the destination Informix/AIX environment, including:

- `sysadmin:ph_alert` availability and permissions;
- Informix version-specific Event Alarm semantics;
- Client SDK connectivity and authentication;
- state-directory ownership and permissions;
- collection cost and scheduling;
- expected operational alert volume and trigger tuning.

After those validations:

```text
IFX-HEALTH-003 → TARGET_ENVIRONMENT_VALIDATED
```

Grafana delivery remains a separate pending integration.

## Source Validation

The authoritative SQL source for remotely observable Informix assertion failures is:

`sysadmin:ph_alert`

Informix Event Alarms persisted in `ph_alert` provide the SQL-accessible representation used by this metric.

### Assert Failure Classification

The following generic Event Alarm identifiers are considered authoritative assertion failure events for this metric:

| Class ID | Event ID | Classification |
|---------:|---------:|----------------|
| 6 | 6300 | Assert Failure |
| 6 | 6500 | Fatal internal error resulting in Assertion Failure |

The following event MUST NOT be counted:

| Class ID | Event ID | Classification |
|---------:|---------:|----------------|
| 6 | 6100 | Assert Warning |

Other Informix Event IDs may result in an Assertion Failure under specific conditions. They MUST NOT be automatically classified as assertion failures by this metric unless their semantics are explicitly incorporated into the metric contract.

`alert_type = 'ERROR'` and `alert_color = 'RED'` MUST NOT, by themselves, be interpreted as an assertion failure because these classifications may represent other severe engine conditions.

Message-text matching such as `LIKE '%assert%'` MUST NOT be used as the authoritative classification mechanism.

### Collection Semantics

The metric counts assertion failure events represented by the authoritative Event Alarm identifiers defined above.

The Event Alarm Class ID is obtained from `alert_object_name`.

The Event Alarm Event ID is obtained from `alert_object_info`.

The collector MUST query `sysadmin:ph_alert` remotely through SQL.

The collector MUST NOT read `online.log`, execute `onstat`, or execute monitoring logic locally on the Informix server.

The SQL-based metric is intentionally narrower than arbitrary textual occurrences of `Assert Failed:` in `online.log`. It represents assertion failures that can be classified authoritatively through the Informix Event Alarm interface.

Failure to query `sysadmin:ph_alert` is a collection failure and MUST NOT be represented as zero assertion failures.

## Incremental Collection State

`sysadmin:ph_alert` is a retained event history and MUST NOT be interpreted as a cumulative counter.

The `ph_alert.id` column is a `SERIAL` value with a unique index and is used as the incremental collection cursor.

The Informix `AlertCleanup` routine removes historical alert records through individual `DELETE` operations. It does not truncate or recreate `ph_alert` as part of its normal cleanup procedure.

### Initial Baseline

On the first successful collection, the collector MUST establish:

`last_id = MAX(ph_alert.id)`

Existing records MUST NOT be published as new assertion failure events.

If `ph_alert` contains no records, the collector MUST establish an empty baseline and begin observing subsequent events.

### Incremental Collection

After the initial baseline, each successful collection MUST inspect records where:

`id > last_id`

Only Event Alarms classified by this metric as assertion failures are published:

| Class ID | Event ID |
|---------:|---------:|
| 6 | 6300 |
| 6 | 6500 |

The collection cursor MUST advance to the greatest `ph_alert.id` observed during the successful collection, regardless of whether any of those records are assertion failures.

This prevents repeatedly scanning unrelated alerts when no assertion failures occur.

### State Advancement

The collection state MUST advance only after successful processing of the retrieved dataset.

A collection or processing failure MUST NOT advance `last_id`.

A successful collection containing no new records MUST preserve the existing `last_id`.

A successful collection containing new records but no assertion failures MUST advance `last_id` to the greatest observed ID without publishing an assertion failure event.

### State Loss

An absent state file is treated as state loss. The collector MUST establish a new baseline at the current `MAX(ph_alert.id)` and MUST NOT publish retained historical records.

An existing state file that cannot be read, is empty, or does not contain a non-negative decimal integer is a collection failure. The collector MUST NOT overwrite that state, publish events, or advance `last_id`.

Deliberate removal of the state file is an explicit state-reset operation. The next successful collector execution MUST establish a new baseline.

Historical records still retained in `ph_alert` MUST NOT be replayed automatically after state loss.

### Retention Boundary

The collector is expected to run frequently enough that new `ph_alert` records are observed before Informix removes them according to its configured alert-history retention policy.

Retention cleanup MUST NOT be interpreted as an assertion counter reset.

The monitoring layer is responsible for retaining the assertion failure events after successful collection.


## Persistent State Storage Contract

The collector state is private operational data and MUST NOT be stored in Git.

The default state directory is:

```text
${IFX_CONFIG_DIR}/state
```

The collector configuration will expose:

```text
IFX_STATE_DIR
```

with `${IFX_CONFIG_DIR}/state` as its default value.

Each Informix instance and metric combination MUST use an independent state file:

```text
${IFX_STATE_DIR}/ifx-health-003.${IFX_INFORMIXSERVER}.last-id
```

The state directory MUST have permissions `700`. Each state file MUST have permissions `600`.

The state file contains exactly one non-negative decimal integer followed by a newline:

```text
16
```

An empty `ph_alert` baseline MUST be persisted as:

```text
0
```

State advancement MUST be atomic. The collector MUST write the next cursor value to a protected temporary file in `IFX_STATE_DIR` and replace the state file only after all retrieval, classification, and publication processing succeeds.

The collector MUST acquire an exclusive lock before reading or changing the state. If another execution already holds that lock, the collector MUST fail without querying, publishing, or advancing state.

The state file MUST NOT contain credentials, SQL text, event payloads, or any other sensitive operational data.


## Collector Output and Delivery Contract

The HEALTH-003 collector MUST emit one structured batch to standard output for each successful collection.

The first line is always the summary:

```text
COUNT|<assertion-count>
```

Each classified assertion failure is emitted on a subsequent line:

```text
EVENT|<id>|<class-id>|<event-id>|<alert-time>|<alert-message>
```

Only Class ID `6` with Event ID `6300` or `6500` may be emitted as an `EVENT` line.

A successful collection with no new assertion failures MUST emit exactly:

```text
COUNT|0
```

The collector MUST NOT emit connection status, diagnostics, or errors to standard output. Such messages belong to standard error.

The collector retrieves all records with `id > last_id`, but emits `EVENT` lines only for classified assertion failures. The next cursor value is the greatest observed `id`, including unrelated alerts.

Delivery semantics are at least once. The collector MUST emit the complete batch before atomically advancing `last_id`.

If batch emission succeeds but state persistence fails, the collector MUST return failure and MUST NOT advance state. The same event records may be emitted again on the next execution.

Every `EVENT` line includes the unique `ph_alert.id`, allowing downstream deduplication when required.

The collector MUST NOT advance state before successful batch emission.
