# IFX-HEALTH-005 — Checkpoint Duration

## 1. Purpose

This document defines the engineering specification and validation state of metric:

`IFX-HEALTH-005 — Checkpoint Duration`

The metric represents the duration of an IBM Informix checkpoint.

This document is the authoritative engineering definition of this metric before Zabbix implementation.

---

# 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-005`

Metric Name:

`Checkpoint Duration`

---

# 3. Objective

The objective of this metric is to expose checkpoint execution duration so that abnormal or progressively increasing checkpoint times can be detected and correlated with database and operating-system behavior.

The metric shall support:

- checkpoint-duration trending;
- detection of unusually long checkpoints;
- comparison with checkpoint frequency;
- correlation with checkpoint waits;
- correlation with write activity;
- correlation with storage latency and workload.

---

# 4. Validated Source

Database:

`sysmaster`

Table:

`syscheckpoint`

Most-recent record rule:

`ORDER BY clock_time DESC`

Duration column:

`cp_time`

Validated SQL contract:

```sql
SELECT FIRST 1
    cp_time AS checkpoint_duration_seconds
FROM syscheckpoint
ORDER BY clock_time DESC;
```

`cp_time` represents the elapsed duration from checkpoint pending until checkpoint completion.

The validated Linux development environment returned fractional-second values, for example:

```text
0.008315329443905282
```

The collector preserves this decimal precision and returns it as seconds to Zabbix.

The implemented collector is:

`05-collectors/informix/health/ifx-health-checkpoint-duration.ksh`

The implemented Zabbix active-check key is:

`ifx.health.checkpoint_duration`

The current development validation covers remote SQL execution, decimal normalization, deployment launcher, Zabbix Agent execution and the Zabbix numeric-float item.

Target Informix/AIX source compatibility, permissions and runtime cost remain pending validation.

---

# 5. Alternative Source

Possible validation/alternative source:

`Informix online message log`

Checkpoint-related log messages may contain timing information useful for validation.

The online log is not currently preferred as the primary runtime source because a structured source is preferable when equivalent semantics are available.

Log-based implementation would also introduce stateful collection behavior similar to `IFX-HEALTH-003`.

---

# 6. Metric Type

Metric type:

`GAUGE`

The normalized value represents checkpoint duration.

Unlike `IFX-HEALTH-004`, this metric is not a cumulative counter.

---

# 7. Normalized Unit

Normalized unit:

`seconds`

The collector shall expose checkpoint duration in seconds regardless of the unit eventually returned by the approved source.

Examples:

```text id="z7s3df"
0
1
5
12
45
```

If the real source provides fractional precision, the normalized contract may require refinement during source validation.

For the initial mock phase, integer seconds are used.

---

# 8. Semantic Question — Which Checkpoint?

The source may potentially expose:

- most recent checkpoint duration;
- current checkpoint duration;
- historical checkpoint records;
- maximum checkpoint duration;
- cumulative checkpoint timing.

These are not equivalent metrics.

For `IFX-HEALTH-005`, the initial intended semantic is:

`duration of the most recently completed checkpoint`

This semantic must be confirmed against the selected real source.

---

# 9. Completed Checkpoint Requirement

The preferred metric represents a completed checkpoint.

An in-progress checkpoint shall not automatically be interpreted as the last completed checkpoint duration unless the approved source explicitly defines that behavior.

Current and completed checkpoint semantics must remain distinct.

---

# 10. Zero Semantics

A value of:

`0`

may be legitimate only if the approved source reports a completed checkpoint duration of zero according to its native precision and semantics.

Collection failure must never become zero.

Real-source validation must determine whether zero is practically possible or whether it represents source-specific absence/uninitialized state.

---

# 11. Collection Failure

Examples include:

- inability to connect to Informix;
- inability to access `sysmaster`;
- SQL execution failure;
- missing expected result;
- malformed result;
- unexpected multiple-result condition;
- invalid unit;
- parser failure.

These conditions must remain separate from valid checkpoint-duration values.

---

# 12. Expected Result Shape

The preferred source shall eventually provide one scalar duration value for the selected checkpoint semantic.

Conceptually:

```text id="shwjql"
checkpoint_duration
-------------------
12
```

Normalized collector output:

```text id="9uk17j"
12
```

---

# 13. Numeric Domain

For the initial mock contract, valid values are:

`non-negative integers`

Examples:

```text id="vqbhtg"
0
1
12
300
```

Invalid examples:

```text id="b7i3zp"
-1
abc
12 seconds
```

Fractional values are intentionally deferred until the precision of the actual source is known.

---

# 14. Fractional Duration

A source may potentially provide values such as:

```text id="1pv1ok"
12.5
```

The mock phase shall initially reject fractional values.

This does not establish that fractional precision is undesirable.

It means the normalized precision shall not be invented before source validation establishes:

- source datatype;
- source unit;
- useful precision;
- Zabbix representation.

If necessary, the contract may later change to support decimal seconds or another normalized representation.

---

# 15. Unit Conversion

The collector shall not assume the source unit.

For example, a raw value of:

```text id="iyfwhu"
12000
```

could represent very different durations if the source unit were:

- seconds;
- milliseconds;
- microseconds.

Therefore unit conversion shall only be introduced after real source semantics are established.

Mock values are treated as already normalized seconds.

---

# 16. Relationship with Checkpoint Count

Checkpoint occurrence belongs to:

`IFX-HEALTH-004 — Checkpoint Count`

Example interpretation:

```text id="7p47n9"
checkpoint count increasing normally
+
checkpoint duration increasing
```

may indicate a different operational condition from:

```text id="wwm6y8"
checkpoint count increasing rapidly
+
checkpoint duration stable
```

The metrics should therefore remain separate.

---

# 17. Relationship with Checkpoint Waits

Checkpoint-related waiting belongs to:

`IFX-HEALTH-006 — Checkpoint Waits`

Duration and waits are correlated but not equivalent.

A long checkpoint does not automatically prove that sessions experienced checkpoint-related waits.

---

# 18. Relationship with Writes

Checkpoint duration should later be correlated with:

`IFX-HEALTH-007 — LRU Writes`

and:

`IFX-HEALTH-008 — Foreground Writes`

This helps distinguish checkpoint timing from broader buffer/write pressure.

---

# 19. Relationship with AIX

Grafana diagnostics should eventually correlate checkpoint duration with AIX metrics such as:

- disk latency;
- disk service time;
- queueing;
- filesystem/storage behavior;
- CPU pressure;
- paging.

Checkpoint-duration alerting should not attempt to diagnose the underlying AIX cause by itself.

---

# 20. Candidate Zabbix Representation

Conceptual key:

`informix.checkpoint.duration`

Final naming remains unapproved.

Expected value type for the initial integer-seconds contract:

`Numeric unsigned`

Expected unit:

`s`

---

# 21. Alerting Relevance

Alerting:

`YES — BASELINE/THRESHOLD REQUIRED`

Long checkpoint duration can be operationally significant.

However, no universal threshold shall be invented during mock validation.

Future triggers may use:

- static threshold validated for the environment;
- baseline deviation;
- sustained increase;
- correlation with waits or storage conditions.

---

# 22. Grafana Relevance

Grafana:

`YES`

Expected uses include:

- checkpoint duration over time;
- duration distribution/trend;
- correlation with checkpoint frequency;
- correlation with checkpoint waits;
- correlation with write activity;
- correlation with storage performance.

---

# 23. Candidate Collection Frequency

Frequency class:

`MEDIUM`

Collection should be frequent enough to observe checkpoint changes without unnecessarily querying Informix.

The final interval remains subject to runtime validation.

---

# 24. Expected Collection Cost

Expected cost:

`LOW`

if the approved structured source provides direct access to recent checkpoint information.

Actual cost remains:

`SOURCE VALIDATION REQUIRED`

---

# 25. Shared Collection Opportunity

`IFX-HEALTH-004`, `IFX-HEALTH-005` and `IFX-HEALTH-006` may potentially share one source query.

Preferred architecture if validated:

```text id="95uucg"
checkpoint source
      │
      ├── count
      ├── duration
      └── waits
```

This avoids executing redundant monitoring queries.

---

# 26. Discovery Requirement

Low-Level Discovery:

`NO`

The metric is instance-level.

---

# 27. Security and Permissions

The monitoring identity shall use read-only access to the approved Informix monitoring source.

Credentials shall not be stored in this repository.

---

# 28. Mock Validation Strategy

Mock validation shall focus on the normalized integer-seconds contract.

Required scenarios:

1. normal duration;
2. zero duration;
3. short duration;
4. long duration;
5. empty result;
6. non-numeric result;
7. negative result;
8. fractional result;
9. simulated source execution failure.

---

# 29. Source Validation Requirements

Before the metric becomes:

`SOURCE_VALIDATED`

the real environment must establish:

- exact `sysmaster` source;
- exact column semantics;
- whether the record represents the most recently completed checkpoint;
- source unit;
- source precision;
- behavior before the first checkpoint;
- availability/history depth;
- query cost;
- required permissions;
- relationship with actual checkpoint events/log messages.

---

# 30. Mock Acceptance Criteria

Mock validation shall demonstrate that:

- valid integer seconds are preserved;
- zero is preserved as zero;
- short durations are accepted;
- large durations are preserved;
- empty input fails;
- non-numeric input fails;
- negative input fails;
- fractional input currently fails;
- source execution failure does not become zero.

---

# 31. Lifecycle

Current lifecycle:

`DEVELOPMENT_RUNTIME_VALIDATED`

Progress achieved:

```text
DEFINED
   │
   ▼
MOCK_VALIDATED
   │
   ▼
DEVELOPMENT_RUNTIME_VALIDATED
```

The historical mock phase remains documented as evidence of the original parser contract. The remote SQL collector supersedes its provisional integer-only duration rule.

---

# 32. Current Status

Current lifecycle state:

`DEVELOPMENT_RUNTIME_VALIDATED`

Validated source:

`sysmaster:syscheckpoint.cp_time`

Intended semantic:

`MOST RECENTLY COMPLETED CHECKPOINT DURATION`

Normalized unit:

`SECONDS — DECIMAL`

Exact SQL source:

`01-statements/informix-health/IFX-HEALTH-005-Checkpoint-Duration.sql`

Collector:

`05-collectors/informix/health/ifx-health-checkpoint-duration.ksh`

Zabbix active-check key:

`ifx.health.checkpoint_duration`

Development validation:

`PASSED`

Target Informix/AIX validation:

`PENDING`

---

# 33. Remaining Acceptance Criteria

Before production rollout:

- validate `syscheckpoint.cp_time` availability and semantics on the target Informix version;
- validate monitoring-user permissions;
- measure query cost under target workload;
- establish normal checkpoint-duration baseline;
- define any duration trigger from observed operational behavior;
- validate deployment on the target AIX or Linux collection host.