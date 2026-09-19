# IFX-HEALTH-004 — Checkpoint Count

## 1. Purpose

This document defines the engineering specification and validation state of metric:

`IFX-HEALTH-004 — Checkpoint Count`

The metric represents the cumulative number of checkpoints observed for an IBM Informix instance.

This document is the authoritative engineering definition of this metric before Zabbix implementation.

---

# 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-004`

Metric Name:

`Checkpoint Count`

---

# 3. Objective

The objective of this metric is to expose checkpoint activity as a cumulative counter suitable for monitoring checkpoint frequency and detecting changes in checkpoint behavior.

The metric shall support:

- checkpoint frequency analysis;
- checkpoint-rate calculation;
- correlation with checkpoint duration;
- correlation with checkpoint waits;
- correlation with write activity;
- correlation with workload and storage behavior.

---

# 4. Validated Source

Database:

`sysmaster`

Table:

`sysshmhdr`

Row selector:

`name = 'pf_numckpts'`

Value column:

`value`

Validated SQL contract:

```sql
SELECT
    CAST(value AS INT8) AS checkpoint_count
FROM sysshmhdr
WHERE name = 'pf_numckpts';
```

The query returned a valid scalar checkpoint counter in the Linux development environment.

The implemented collector is:

`05-collectors/informix/health/ifx-health-checkpoint-count.ksh`

The implemented Zabbix active-check key is:

`ifx.health.checkpoint_count`

The current development validation covers remote SQL execution, collector normalization, deployment launcher, Zabbix Agent execution and the Zabbix item.

Target Informix/AIX source compatibility, permissions and runtime cost remain pending validation.

---

# 5. Alternative Source

Possible alternative source:

`Informix online message log`

Checkpoint completion messages may provide evidence of checkpoint activity.

However, log parsing is not currently the preferred primary source for this metric because:

- it introduces stateful log-processing requirements;
- historical log retention affects available history;
- rotation/truncation must be handled;
- structured data is preferable when equivalent semantics are available through `sysmaster`.

The online log may later be useful for validation or diagnostic correlation.

---

# 6. Metric Type

Metric type:

`COUNTER`

The normalized value represents a monotonically increasing checkpoint count within the lifetime of the relevant Informix counter.

Example:

```text
120
121
122
123
```

---

# 7. Counter Semantics

The collector shall expose the raw cumulative checkpoint counter when the selected source provides one.

The collector shall not convert the counter into a rate.

Rate calculations belong to the monitoring layer.

Conceptually:

```text
Informix raw counter
        │
        ▼
collector
        │
        ▼
12345
        │
        ▼
Zabbix
        │
        ├── delta
        └── checkpoints/time
```

---

# 8. Counter Reset

A decrease in the checkpoint counter may indicate:

- Informix restart;
- counter reset;
- source-semantic change;
- counter rollover.

The collector shall not automatically reinterpret a decrease as collection failure.

Zabbix shall evaluate counter changes in conjunction with:

`IFX-HEALTH-002 — Instance Uptime`

A simultaneous uptime reset provides strong contextual evidence of an instance restart.

---

# 9. Zero Semantics

A returned value of:

`0`

is valid only if the selected source successfully reports a checkpoint count of zero.

Collection failure must not be represented as zero.

---

# 10. Collection Failure

Examples include:

- inability to connect to Informix;
- inability to access `sysmaster`;
- SQL execution failure;
- missing expected result;
- malformed result;
- permission failure;
- unexpected multiple-result condition;
- parser failure.

These conditions must produce collection failure rather than a numeric value.

---

# 11. Expected Result Shape

The preferred SQL source shall eventually return exactly one numeric scalar.

Conceptually:

```text
checkpoint_count
----------------
12345
```

Normalized collector output:

```text
12345
```

Only a non-negative integer is valid.

---

# 12. Multiple Rows

The final SQL statement should ideally aggregate the source into one scalar value.

If the collector expects one scalar and receives multiple unresolved values, collection shall fail rather than arbitrarily selecting one.

---

# 13. Null or Empty Result

The following are invalid:

```text
NULL
```

```text
<empty>
```

They shall result in collection failure.

They shall not become:

```text
0
```

---

# 14. Numeric Validation

Accepted normalized values:

```text
0
1
2
100
123456
```

Rejected values include:

```text
-1
12.5
abc
1 checkpoint
```

The collector contract requires a non-negative integer.

---

# 15. Historical Derivation

The collector shall not calculate checkpoint frequency from historical samples.

For example, given:

```text
T1 = 1000
T2 = 1005
```

Zabbix may derive:

```text
5 checkpoints during the interval
```

This preserves the raw source counter and keeps monitoring calculations outside the collector.

---

# 16. Relationship with Checkpoint Duration

`IFX-HEALTH-004` measures occurrence/count.

It does not measure checkpoint duration.

Duration belongs to:

`IFX-HEALTH-005 — Checkpoint Duration`

The metrics are related but semantically independent.

---

# 17. Relationship with Checkpoint Waits

Checkpoint-related waiting or blocking belongs to:

`IFX-HEALTH-006 — Checkpoint Waits`

A high checkpoint rate does not by itself imply a checkpoint problem.

Interpretation should consider count, duration, waits and workload together.

---

# 18. Candidate Zabbix Representation

Conceptual key:

`informix.checkpoint.count`

Final naming remains unapproved.

Expected Zabbix value type:

`Numeric unsigned`

The raw counter should be retained.

Derived metrics may later calculate:

- checkpoints per minute;
- checkpoints per hour;
- interval between checkpoints;
- abnormal changes relative to baseline.

---

# 19. Alerting Relevance

Direct alerting:

`CONDITIONAL`

Checkpoint count alone is primarily diagnostic.

Alerting may become useful when derived behavior indicates conditions such as:

- checkpoint frequency unexpectedly high;
- checkpoint activity unexpectedly absent;
- checkpoint behavior materially deviating from baseline.

Such triggers shall not be defined until source semantics and operational baseline are validated.

---

# 20. Grafana Relevance

Grafana:

`YES`

Expected uses include:

- checkpoint frequency over time;
- checkpoint rate;
- correlation with checkpoint duration;
- correlation with checkpoint waits;
- correlation with LRU writes;
- correlation with foreground writes;
- correlation with AIX storage latency and workload.

---

# 21. Candidate Collection Frequency

Frequency class:

`MEDIUM`

Checkpoint count does not require extremely high-frequency collection.

The final interval shall be selected after runtime cost and checkpoint behavior are understood.

---

# 22. Expected Collection Cost

Expected cost:

`LOW`

provided the selected `sysmaster` query is lightweight and properly scoped.

Actual cost remains:

`SOURCE VALIDATION REQUIRED`

Monitoring overhead must be measured in the target environment.

---

# 23. Shared Collection Opportunity

`IFX-HEALTH-004`, `IFX-HEALTH-005` and `IFX-HEALTH-006` may potentially obtain data from the same structured checkpoint source.

If validated, the preferred runtime architecture is:

```text
single checkpoint source query
            │
            ├── checkpoint count
            ├── checkpoint duration
            └── checkpoint waits
```

rather than executing independent expensive queries for each metric.

This remains an architectural optimization subject to source validation.

---

# 24. Discovery Requirement

Low-Level Discovery:

`NO`

for the instance-level checkpoint count.

If future source semantics expose multiple checkpoint-related objects, they shall not automatically become discovered entities without separate modeling.

---

# 25. Security and Permissions

The monitoring identity shall receive only the database permissions required to query the approved monitoring source.

Credentials shall not be stored in this repository.

The collector shall perform read-only monitoring operations.

---

# 26. Mock Validation Strategy

Because the target Informix environment is currently unavailable, mock validation shall initially focus on the normalized SQL-result contract.

Mock scenarios shall include:

1. normal positive counter;
2. zero counter;
3. large counter;
4. counter after apparent reset;
5. empty result;
6. non-numeric result;
7. negative result;
8. decimal result;
9. simulated SQL execution failure.

Counter reset shall be validated as a legitimate numeric sample, not as parser failure.

---

# 27. Source Validation Requirements

Before the metric may become:

`SOURCE_VALIDATED`

the following must be confirmed against the target Informix environment:

- exact `sysmaster` source;
- exact table or view;
- exact column semantics;
- whether the value is cumulative;
- counter lifetime;
- restart behavior;
- rollover behavior, if applicable;
- availability across the target Informix version;
- query execution cost;
- required permissions;
- relationship to actual checkpoint events.

---

# 28. Mock Acceptance Criteria

The mock parser shall demonstrate that:

- valid non-negative integer values are accepted;
- zero remains zero;
- large counters are preserved without transformation;
- a lower valid counter remains a valid sample;
- empty results fail;
- non-numeric results fail;
- negative values fail;
- decimal values fail;
- SQL execution failure does not become zero.

---

# 29. Lifecycle

Current lifecycle:

`DEFINED`

Expected progression:

```text
DEFINED
   │
   ▼
MOCK_VALIDATED
   │
   ▼
SOURCE_VALIDATED
   │
   ▼
COLLECTION_VALIDATED
   │
   ▼
IMPLEMENTED
   │
   ▼
RUNTIME_VALIDATED
```

Mock validation confirms only the collector/parser contract.

It does not validate the candidate Informix source.

---

# 30. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Current source status:

`CANDIDATE SOURCE — sysmaster`

Exact SQL source:

`PENDING SOURCE VALIDATION`

Metric semantics:

`COUNTER`

Mock inputs:

`AVAILABLE`

Parser implementation:

`IMPLEMENTED`

Mock validation:

`PASSED — 9/9`

Real Informix/AIX validation:

`PENDING`

---

# 31. Exit Criteria

`IFX-HEALTH-004` shall complete the current mock phase when:

- metric semantics are approved;
- normalized counter contract is approved;
- mocks are created;
- parser behavior is specified;
- parser implementation is completed;
- all approved mock tests pass.

After that:

`IFX-HEALTH-004 → MOCK_VALIDATED`

Selection and approval of the actual `sysmaster` SQL source remain required before:

`SOURCE_VALIDATED`