# IFX-HEALTH-006 — Checkpoint Waits

## 1. Purpose

This document defines the engineering specification and validation state of metric:

`IFX-HEALTH-006 — Checkpoint Waits`

The metric represents checkpoint-related waiting observed by IBM Informix.

This document is the authoritative engineering definition of this metric before Zabbix implementation.

---

# 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-006`

Metric Name:

`Checkpoint Waits`

---

# 3. Objective

The objective of this metric is to expose checkpoint-related waiting so that operational impact associated with checkpoints can be detected and correlated with checkpoint duration, write pressure, workload and operating-system behavior.

The metric shall support:

- checkpoint-wait trending;
- detection of increased checkpoint-related contention;
- correlation with checkpoint duration;
- correlation with checkpoint frequency;
- correlation with LRU and foreground writes;
- correlation with storage and AIX performance.

---

# 4. Candidate Source

Primary candidate source:

`sysmaster`

The preferred architecture is to obtain checkpoint-wait information from a structured Informix monitoring source.

The exact:

- table or view;
- column;
- SQL statement;
- native unit;
- cumulative versus per-checkpoint semantics;

remain:

`PENDING SOURCE VALIDATION`

No specific `sysmaster` object shall be treated as authoritative before validation against a real Informix environment.

---

# 5. Semantic Ambiguity

The term:

`Checkpoint Waits`

may represent different source semantics.

Possible interpretations include:

- cumulative number of checkpoint waits;
- waits associated with the most recent checkpoint;
- number of sessions waiting for checkpoint activity;
- cumulative checkpoint wait time;
- checkpoint-specific internal wait counters.

These meanings are not interchangeable.

Therefore the exact operational semantic remains:

`PENDING SOURCE VALIDATION`

---

# 6. Provisional Metric Semantic

For the mock phase, the provisional semantic is:

`cumulative checkpoint-related wait count`

This allows the monitoring contract to be developed without claiming that the real Informix source exposes exactly this counter.

The provisional semantic must be confirmed or revised during source validation.

---

# 7. Metric Type

Under the provisional mock semantic:

`COUNTER`

The raw cumulative counter shall be preserved.

Rates and deltas shall be derived by Zabbix where appropriate.

---

# 8. Normalized Unit

Provisional normalized unit:

`waits`

Example:

```text
42
```

means a cumulative checkpoint-related wait count of 42 under the mock contract.

---

# 9. Counter Semantics

The collector shall expose the raw source counter.

It shall not calculate:

- waits per second;
- waits per checkpoint;
- interval delta;
- historical maximum;
- moving average.

Those are monitoring-layer derivations.

---

# 10. Counter Reset

A decrease between samples is not automatically a collection failure.

Example:

```text
previous = 150
current  = 7
```

may represent:

- Informix restart;
- counter reset;
- source-specific lifecycle;
- rollover.

The current value remains a valid sample if the source query itself succeeded.

Restart/reset interpretation should later be correlated with:

`IFX-HEALTH-002 — Instance Uptime`

---

# 11. Zero Semantics

A value of:

`0`

is a valid mock value.

It means that the approved source successfully returned zero under the provisional counter contract.

Collection failure must never become zero.

---

# 12. Expected Result Shape

The future approved source should ideally return one scalar value.

Conceptually:

```text
checkpoint_waits
----------------
42
```

Normalized collector output:

```text
42
```

---

# 13. Numeric Domain

For the provisional mock contract, valid values are:

`non-negative integers`

Examples:

```text
0
1
42
987654
```

Invalid examples:

```text
-1
12.5
waits
```

---

# 14. Multiple Values

Multiple unresolved values are invalid for the normalized parser contract.

Example:

```text
12
15
```

shall not cause the parser to:

- choose one arbitrarily;
- sum them;
- average them.

Any aggregation required by the real source belongs to the approved source query or to a separately documented collection rule.

---

# 15. Collection Failure

Examples include:

- inability to connect to Informix;
- inability to query `sysmaster`;
- SQL execution failure;
- empty result;
- malformed result;
- negative value;
- unexpected multiple values;
- parser failure.

Collection failure must remain distinct from a valid numeric zero.

---

# 16. Relationship with Checkpoint Count

Checkpoint occurrence belongs to:

`IFX-HEALTH-004 — Checkpoint Count`

Checkpoint waits and checkpoint count are related but separate.

A useful future derived diagnostic may compare:

```text
checkpoint wait delta
/
checkpoint count delta
```

Such derivation does not belong in this collector.

---

# 17. Relationship with Checkpoint Duration

Checkpoint duration belongs to:

`IFX-HEALTH-005 — Checkpoint Duration`

A long checkpoint does not necessarily imply checkpoint-related waits.

Likewise, increased waits may require correlation with checkpoint duration before operational interpretation.

---

# 18. Relationship with Writes

Checkpoint waits should later be correlated with:

`IFX-HEALTH-007 — LRU Writes`

and:

`IFX-HEALTH-008 — Foreground Writes`

This may help identify broader write or buffer pressure.

---

# 19. Relationship with AIX

Grafana diagnostics should eventually correlate checkpoint waits with AIX metrics such as:

- storage latency;
- storage queueing;
- CPU pressure;
- paging;
- filesystem behavior.

The Informix metric itself shall not attempt to diagnose the underlying AIX cause.

---

# 20. Candidate Zabbix Representation

Conceptual key:

`informix.checkpoint.waits`

Final naming remains unapproved.

Expected value type under the provisional counter contract:

`Numeric unsigned`

---

# 21. Zabbix Derived Metrics

If the source is confirmed as cumulative, Zabbix may derive:

- checkpoint waits per interval;
- checkpoint wait rate;
- waits per checkpoint.

The collector shall preserve the raw counter.

---

# 22. Alerting Relevance

Alerting:

`YES — CONDITIONAL`

A raw cumulative counter value alone is generally not an actionable condition.

Alerting should preferentially use:

- counter delta;
- sustained wait rate;
- baseline deviation;
- correlation with checkpoint duration;
- correlation with workload/storage behavior.

No threshold shall be invented during mock validation.

---

# 23. Grafana Relevance

Grafana:

`YES`

Expected uses include:

- raw checkpoint wait counter;
- checkpoint wait delta/rate;
- correlation with checkpoint duration;
- correlation with checkpoint count;
- correlation with writes;
- correlation with storage performance.

---

# 24. Candidate Collection Frequency

Frequency class:

`MEDIUM`

The final interval remains subject to runtime and source-cost validation.

---

# 25. Expected Collection Cost

Expected cost:

`LOW`

if a direct structured source exists.

Actual cost remains:

`SOURCE VALIDATION REQUIRED`

---

# 26. Shared Collection Opportunity

`IFX-HEALTH-004`, `IFX-HEALTH-005` and `IFX-HEALTH-006` should preferentially share a source query if real Informix validation shows that the required data can be retrieved safely and efficiently together.

Conceptually:

```text
checkpoint source
      │
      ├── count
      ├── duration
      └── waits
```

This avoids redundant database monitoring queries.

---

# 27. Discovery Requirement

Low-Level Discovery:

`NO`

The metric is instance-level.

---

# 28. Security and Permissions

The monitoring identity shall use read-only access to the approved Informix monitoring source.

Credentials shall not be stored in this repository.

---

# 29. Mock Validation Strategy

Mock validation shall test the provisional cumulative-counter contract.

Required scenarios:

1. normal counter;
2. zero counter;
3. small counter;
4. large counter;
5. reset sample;
6. empty result;
7. non-numeric result;
8. negative result;
9. decimal result;
10. simulated source execution failure.

---

# 30. Source Validation Requirements

Before the metric becomes:

`SOURCE_VALIDATED`

the real environment must establish:

- exact `sysmaster` source;
- exact SQL statement;
- exact meaning of the wait value;
- whether the source is cumulative;
- reset behavior;
- rollover behavior if applicable;
- native unit;
- behavior across Informix restart;
- query cost;
- required permissions;
- supported Informix versions.

If the source does not represent a cumulative wait count, this specification shall be revised before progressing.

---

# 31. Mock Acceptance Criteria

Mock validation shall demonstrate that:

- valid non-negative integers are preserved;
- zero is preserved;
- small counters are preserved;
- large counters are preserved;
- a lower/reset sample remains a valid sample;
- empty input fails;
- non-numeric input fails;
- negative input fails;
- decimal input fails under the provisional contract;
- source execution failure does not become zero.

---

# 32. Lifecycle

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

---

# 33. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Current source status:

`CANDIDATE SOURCE — sysmaster`

Current semantic:

`PROVISIONAL — CUMULATIVE CHECKPOINT-RELATED WAIT COUNT`

Metric semantics:

`COUNTER — PROVISIONAL`

Normalized unit:

`WAITS — MOCK CONTRACT`

Exact SQL source:

`PENDING SOURCE VALIDATION`

Mock inputs:

`AVAILABLE`

Parser implementation:

`IMPLEMENTED`

Mock validation:

`PASSED — 10/10`

Real Informix/AIX validation:

`PENDING`

---

# 34. Exit Criteria

`IFX-HEALTH-006` shall complete the current mock phase when:

- provisional semantics are documented;
- mock contract is approved;
- mocks are created;
- parser behavior is specified;
- parser implementation is completed;
- all approved mock tests pass.

After that:

`IFX-HEALTH-006 → MOCK_VALIDATED`

The actual Informix checkpoint-wait semantic remains pending until real source validation.