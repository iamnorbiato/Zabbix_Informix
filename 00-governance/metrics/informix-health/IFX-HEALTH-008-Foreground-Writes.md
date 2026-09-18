# IFX-HEALTH-008 — Foreground Writes

## 1. Purpose

This document defines the engineering specification and validation state of metric:

`IFX-HEALTH-008 — Foreground Writes`

The metric represents IBM Informix foreground write activity.

This document is the authoritative engineering definition of this metric before Zabbix implementation.

---

# 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-008`

Metric Name:

`Foreground Writes`

---

# 3. Objective

The objective of this metric is to expose Informix foreground write activity so that conditions where sessions or foreground processing must participate in buffer flushing can be observed and correlated with LRU writes, checkpoints, workload and storage behavior.

The metric shall support:

- foreground write trending;
- foreground write rate analysis;
- comparison with LRU writes;
- detection of changes in buffer/write pressure;
- checkpoint correlation;
- storage-performance correlation.

---

# 4. Candidate Source

Primary candidate source:

`sysmaster`

A structured Informix monitoring source is preferred when it provides stable cumulative foreground-write statistics with acceptable collection cost.

The exact:

- table or view;
- column;
- SQL statement;
- counter scope;
- reset behavior;

remain:

`PENDING SOURCE VALIDATION`

No specific `sysmaster` object shall be considered authoritative before real environment validation.

---

# 5. Alternative Source

Candidate alternative/validation source:

`onstat -F`

Informix operational output may expose foreground-write statistics useful for validation or as an alternative source.

Whether `onstat -F` is appropriate for production collection remains:

`PENDING SOURCE VALIDATION`

A structured source is preferred if equivalent semantics are available.

---

# 6. Provisional Semantic

For the mock phase, the metric semantic is:

`cumulative number of foreground writes`

This semantic must be confirmed against the real Informix source.

---

# 7. Metric Type

Metric type:

`COUNTER — PROVISIONAL UNTIL SOURCE VALIDATION`

The raw cumulative counter shall be preserved.

Rates and deltas belong to Zabbix.

---

# 8. Normalized Unit

Provisional normalized unit:

`writes`

Example:

```text id="4vvp8p"
750
```

represents a cumulative foreground write count of 750 under the mock contract.

---

# 9. Operational Interpretation

Foreground writes are operationally important because they may indicate write activity occurring outside the preferred background/LRU cleaning path.

However, the metric alone shall not assert that any particular foreground-write rate represents a problem.

Operational interpretation requires validated baselines and correlation.

---

# 10. Counter Semantics

The collector shall expose the raw cumulative value.

It shall not calculate:

- writes per second;
- interval delta;
- percentage of total writes;
- ratio against LRU writes;
- baseline deviation.

These belong to the monitoring layer.

---

# 11. Counter Reset

A lower value than a previous sample remains syntactically valid.

Example:

```text id="ow98or"
previous = 10000
current  = 15
```

Possible explanations include:

- Informix restart;
- counter reset;
- rollover;
- source-specific lifecycle.

The parser shall not reject a sample because it decreased.

Restart interpretation should later be correlated with:

`IFX-HEALTH-002 — Instance Uptime`

---

# 12. Zero Semantics

A successfully collected value of:

`0`

is valid under the mock contract.

Collection failure must remain distinct from zero.

---

# 13. Expected Result Shape

The future approved source should ideally provide one scalar cumulative value.

Conceptually:

```text id="0czd13"
foreground_writes
-----------------
750
```

Normalized output:

```text id="azrx6f"
750
```

---

# 14. Numeric Domain

For the provisional mock contract:

`non-negative integers`

are valid.

Examples:

```text id="zj34vr"
0
1
750
987654321
```

Invalid examples:

```text id="ijyj9x"
-1
12.5
foreground_writes
```

---

# 15. Multiple Values

Exactly one normalized scalar is expected.

Multiple unresolved values shall result in collection/parsing failure.

The parser shall not silently aggregate values from multiple buffer pools or source rows.

If the real source exposes foreground writes per buffer pool, the aggregation or discovery model must be explicitly designed.

---

# 16. Buffer Pool Scope

The authoritative source may expose foreground-write statistics:

- globally;
- per buffer pool;
- per page-size buffer pool;
- through another internal scope.

The mock contract assumes one already-normalized instance-level scalar.

It does not define aggregation behavior.

---

# 17. Collection Failure

Examples include:

- Informix connection failure;
- `sysmaster` query failure;
- `onstat` execution failure;
- empty result;
- malformed result;
- negative value;
- unexpected multiple values;
- parser failure.

Collection failure shall not produce numeric zero.

---

# 18. Relationship with LRU Writes

LRU write activity belongs to:

`IFX-HEALTH-007 — LRU Writes`

The two metrics should be analyzed together.

Conceptually:

```text id="5ox75l"
LRU writes
     +
Foreground writes
     │
     ▼
buffer/write behavior
```

A future derived ratio may be useful, but shall not be calculated by this collector.

---

# 19. Relationship with Checkpoints

Foreground writes should later be correlated with:

`IFX-HEALTH-004 — Checkpoint Count`

`IFX-HEALTH-005 — Checkpoint Duration`

`IFX-HEALTH-006 — Checkpoint Waits`

This allows changes in foreground write activity to be evaluated in the context of checkpoint behavior.

---

# 20. Relationship with Buffer Configuration

Foreground-write behavior may be influenced by:

- buffer-pool sizing;
- dirty-buffer thresholds;
- workload characteristics;
- checkpoint behavior;
- storage responsiveness.

Configuration diagnosis belongs to later tuning and diagnostics.

The metric collector shall expose observed behavior only.

---

# 21. Relationship with AIX

Grafana should eventually correlate foreground-write rate with AIX metrics such as:

- disk throughput;
- disk latency;
- queueing;
- filesystem activity;
- CPU pressure;
- paging.

This metric shall not attempt to diagnose the AIX layer itself.

---

# 22. Candidate Zabbix Representation

Conceptual key:

`informix.writes.foreground`

Final naming remains unapproved.

Expected value type:

`Numeric unsigned`

---

# 23. Zabbix Derived Metrics

If cumulative semantics are confirmed, Zabbix may derive:

- foreground writes per interval;
- foreground writes per second;
- foreground/LRU write ratio;
- change from baseline.

The collector shall preserve the raw counter.

---

# 24. Alerting Relevance

Alerting:

`YES — CONDITIONAL`

Foreground write activity can be operationally significant, but the raw cumulative counter is not directly actionable.

Potential alerting should use validated behavior such as:

- sustained foreground-write rate;
- significant baseline deviation;
- abnormal relationship with LRU writes;
- correlation with checkpoint or storage pressure.

No threshold shall be invented during mock validation.

---

# 25. Grafana Relevance

Grafana:

`YES`

Expected uses include:

- foreground write rate over time;
- comparison with LRU write rate;
- checkpoint correlation;
- storage-performance correlation;
- workload trend analysis.

---

# 26. Candidate Collection Frequency

Frequency class:

`MEDIUM`

The final collection interval depends on source cost and desired resolution for derived rates.

---

# 27. Expected Collection Cost

Expected cost:

`LOW`

if an efficient structured cumulative counter exists.

Actual cost remains:

`SOURCE VALIDATION REQUIRED`

---

# 28. Shared Collection Opportunity

`IFX-HEALTH-007` and `IFX-HEALTH-008` should preferentially share a collection source if real Informix validation confirms that both counters are available together.

Conceptually:

```text id="rvw08w"
Informix write statistics
          │
          ├── LRU writes
          └── foreground writes
```

This avoids redundant source execution.

---

# 29. Discovery Requirement

Current expectation:

`NO`

for the normalized instance-level metric.

If real source validation demonstrates meaningful per-buffer-pool statistics that should remain individually observable, this decision may be revised to use discovery.

---

# 30. Security and Permissions

The monitoring identity shall use read-only access to the approved Informix monitoring source.

Credentials shall not be stored in this repository.

---

# 31. Mock Validation Strategy

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

# 32. Source Validation Requirements

Before the metric becomes:

`SOURCE_VALIDATED`

the real environment must establish:

- exact authoritative source;
- exact `sysmaster` object if used;
- exact SQL statement if used;
- whether `onstat -F` provides equivalent semantics;
- whether the value is cumulative;
- exact definition of foreground write in the source;
- whether statistics are global or per buffer pool;
- aggregation requirements, if any;
- reset and rollover behavior;
- behavior across Informix restart;
- query/command cost;
- required permissions;
- relevant Informix-version differences.

---

# 33. Mock Acceptance Criteria

Mock validation shall demonstrate that:

- valid counters are preserved;
- zero is preserved;
- small counters are preserved;
- large counters are preserved;
- lower/reset samples remain valid;
- empty input fails;
- non-numeric input fails;
- negative input fails;
- decimal input fails under the provisional contract;
- execution failure does not become zero.

---

# 34. Lifecycle

Current lifecycle:

`DEFINED`

Expected progression:

```text id="tn9ml2"
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

# 35. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Current source status:

`CANDIDATE SOURCE — sysmaster`

Alternative validation source:

`CANDIDATE — onstat -F`

Current semantic:

`PROVISIONAL — CUMULATIVE FOREGROUND WRITE COUNT`

Metric semantics:

`COUNTER — PROVISIONAL`

Normalized unit:

`WRITES — MOCK CONTRACT`

Source scope:

`PENDING SOURCE VALIDATION`

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

# 36. Exit Criteria

`IFX-HEALTH-008` shall complete the current mock phase when:

- provisional semantics are documented;
- mock contract is approved;
- mocks are created;
- parser behavior is specified;
- parser implementation is completed;
- all approved mock tests pass.

After that:

`IFX-HEALTH-008 → MOCK_VALIDATED`

The authoritative source and instance-versus-buffer-pool scope remain pending until real Informix validation.