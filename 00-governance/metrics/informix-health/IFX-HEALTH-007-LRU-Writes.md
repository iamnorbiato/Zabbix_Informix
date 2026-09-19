# IFX-HEALTH-007 — LRU Writes

## 1. Purpose

This document defines the engineering specification and validation state of metric:

`IFX-HEALTH-007 — LRU Writes`

The metric represents IBM Informix LRU write activity.

This document is the authoritative engineering definition of this metric before Zabbix implementation.

---

# 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-007`

Metric Name:

`LRU Writes`

---

# 3. Objective

The objective of this metric is to expose Informix LRU write activity so that buffer-cleaning behavior and write pressure can be observed and correlated with checkpoint activity, foreground writes and operating-system storage behavior.

The metric shall support:

- LRU write trending;
- LRU write rate analysis;
- detection of changes in buffer-cleaning behavior;
- comparison with foreground writes;
- correlation with checkpoint behavior;
- correlation with storage performance.

---

# 4. Validated Source

Database:

`sysmaster`

Table:

`sysprofile`

Row selector:

`name = 'lruwrites'`

Value column:

`value`

Validated SQL contract:

```sql
SELECT
    CAST(value AS INT8) AS lru_write_count
FROM sysprofile
WHERE name = 'lruwrites';
```

`lruwrites` is the cumulative counter of Informix least-recently-used buffer writes.

The validated Linux development environment returned:

```text
0
```

Zero is valid and means no LRU writes have been counted in the current counter lifetime.

The implemented collector is:

`05-collectors/informix/health/ifx-health-lru-writes.ksh`

The implemented Zabbix active-check key is:

`ifx.health.lru_writes`

The current development validation covers remote SQL execution, collector normalization, deployment launcher, Zabbix Agent execution and the Zabbix numeric item.

Target Informix/AIX source compatibility, permissions and runtime cost remain pending validation.

---

# 5. Alternative Source

Candidate alternative/validation source:

`onstat -F`

Informix operational output may expose buffer-flush/write statistics useful for source validation or as an alternative collection source.

Whether `onstat -F` is appropriate for production collection remains:

`PENDING SOURCE VALIDATION`

A structured source is preferred if equivalent semantics are available.

---

# 6. Provisional Semantic

For the mock phase, the metric semantic is:

`cumulative number of LRU writes`

This semantic must be confirmed against the real Informix source.

---

# 7. Metric Type

Metric type:

`COUNTER — PROVISIONAL UNTIL SOURCE VALIDATION`

The collector shall preserve the raw cumulative counter.

Rate and delta calculations belong to Zabbix.

---

# 8. Normalized Unit

Provisional normalized unit:

`writes`

Example:

```text id="3g10js"
125000
```

represents a cumulative LRU write count of 125000 under the mock contract.

---

# 9. Counter Semantics

The collector shall not calculate:

- writes per second;
- writes per minute;
- interval delta;
- percentage of total writes;
- ratio against foreground writes.

The raw counter shall be retained so derived metrics can be calculated consistently by the monitoring layer.

---

# 10. Counter Reset

A lower value than a previous sample remains syntactically valid.

Example:

```text id="fek24e"
previous = 500000
current  = 120
```

Possible explanations include:

- Informix restart;
- counter reset;
- counter rollover;
- source-specific lifecycle.

The parser shall not reject the current sample solely because it decreased.

Restart interpretation should later be correlated with:

`IFX-HEALTH-002 — Instance Uptime`

---

# 11. Zero Semantics

A successfully collected value of:

`0`

is valid under the mock contract.

Collection failure must remain distinct from zero.

---

# 12. Expected Result Shape

The future approved source should ideally provide one scalar cumulative value.

Conceptually:

```text id="5ccg6u"
lru_writes
----------
125000
```

Normalized output:

```text id="b0v67g"
125000
```

---

# 13. Numeric Domain

For the provisional mock contract:

`non-negative integers`

are valid.

Examples:

```text id="i5d57b"
0
1
125000
987654321
```

Invalid examples:

```text id="q3x9nb"
-1
12.5
lru_writes
```

---

# 14. Multiple Values

Exactly one normalized scalar value is expected.

Multiple unresolved values shall result in collection/parsing failure.

The parser shall not silently aggregate values from multiple buffer pools or source rows.

If the real source exposes LRU writes per buffer pool, the aggregation or discovery model must be explicitly designed during source validation.

---

# 15. Buffer Pool Scope

The real Informix source may expose statistics:

- globally;
- per buffer pool;
- per page-size buffer pool;
- through another internal scope.

This is a critical source-validation question.

The mock contract assumes one already-normalized instance-level cumulative value.

It does not define how multiple buffer-pool values should be combined.

---

# 16. Collection Failure

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

# 17. Relationship with Foreground Writes

Foreground write activity belongs to:

`IFX-HEALTH-008 — Foreground Writes`

LRU writes and foreground writes should be analyzed together.

An increase in foreground writes may indicate conditions materially different from normal LRU-driven buffer cleaning.

The collector itself shall not calculate a ratio between them.

---

# 18. Relationship with Checkpoints

LRU writes should later be correlated with:

`IFX-HEALTH-004 — Checkpoint Count`

`IFX-HEALTH-005 — Checkpoint Duration`

`IFX-HEALTH-006 — Checkpoint Waits`

This allows write behavior to be analyzed in the context of checkpoint activity.

---

# 19. Relationship with Buffer Configuration

LRU write behavior may be influenced by Informix buffer-pool configuration and dirty-buffer thresholds.

Configuration interpretation belongs to diagnostics and tuning.

The metric collector shall expose observed behavior without attempting to determine whether configuration is correct.

---

# 20. Relationship with AIX

Grafana should eventually correlate LRU write rates with AIX metrics such as:

- disk throughput;
- disk latency;
- queueing;
- filesystem activity;
- CPU pressure;
- paging.

This metric shall not attempt to diagnose the AIX storage layer itself.

---

# 21. Candidate Zabbix Representation

Conceptual key:

`informix.writes.lru`

Final naming remains unapproved.

Expected value type:

`Numeric unsigned`

---

# 22. Zabbix Derived Metrics

If cumulative semantics are confirmed, Zabbix may derive:

- LRU writes per interval;
- LRU writes per second;
- LRU/foreground write ratio;
- change from baseline.

The collector shall preserve the raw counter.

---

# 23. Alerting Relevance

Alerting:

`CONDITIONAL`

A raw cumulative LRU write count is not directly actionable.

Potential alerting should depend on validated behavior such as:

- abnormal write rate;
- significant baseline deviation;
- unusual relationship with foreground writes;
- correlation with checkpoint or storage pressure.

No threshold shall be invented during mock validation.

---

# 24. Grafana Relevance

Grafana:

`YES`

Expected uses include:

- LRU write rate over time;
- comparison with foreground writes;
- checkpoint correlation;
- storage-performance correlation;
- workload trend analysis.

---

# 25. Candidate Collection Frequency

Frequency class:

`MEDIUM`

The final collection interval depends on source cost and the operational resolution required for derived write rates.

---

# 26. Expected Collection Cost

Expected cost:

`LOW`

if an efficient structured cumulative counter exists.

Actual cost remains:

`SOURCE VALIDATION REQUIRED`

---

# 27. Shared Collection Opportunity

`IFX-HEALTH-007` and `IFX-HEALTH-008` should preferentially share a collection source if real Informix validation confirms that LRU and foreground write counters are available together.

Conceptually:

```text id="xshg33"
Informix write statistics
          │
          ├── LRU writes
          └── foreground writes
```

This avoids redundant source execution.

---

# 28. Discovery Requirement

Current expectation:

`NO`

for the normalized instance-level metric.

However, if the authoritative source exposes meaningful per-buffer-pool statistics that should be retained independently, this decision may be revised to use discovery.

---

# 29. Security and Permissions

The monitoring identity shall use read-only access to the approved Informix monitoring source.

Credentials shall not be stored in this repository.

---

# 30. Mock Validation Strategy

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

# 31. Source Validation Requirements

Before the metric becomes:

`SOURCE_VALIDATED`

the real environment must establish:

- exact authoritative source;
- exact `sysmaster` object if used;
- exact SQL statement if used;
- whether `onstat -F` provides equivalent semantics;
- whether the value is cumulative;
- whether statistics are global or per buffer pool;
- aggregation requirements, if any;
- reset behavior;
- rollover behavior;
- behavior across Informix restart;
- query/command cost;
- required permissions;
- relevant Informix-version differences.

---

# 32. Mock Acceptance Criteria

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

# 33. Lifecycle

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

The historical mock phase remains documented as evidence of the original normalized-counter contract.

---

# 34. Current Status

Current lifecycle state:

`DEVELOPMENT_RUNTIME_VALIDATED`

Validated source:

`sysmaster:sysprofile.lruwrites`

Current semantic:

`CUMULATIVE LRU WRITE COUNT`

Metric semantics:

`COUNTER`

Normalized unit:

`WRITES`

Exact SQL source:

`01-statements/informix-health/IFX-HEALTH-007-LRU-Writes.sql`

Collector:

`05-collectors/informix/health/ifx-health-lru-writes.ksh`

Zabbix active-check key:

`ifx.health.lru_writes`

Development validation:

`PASSED`

Target Informix/AIX validation:

`PENDING`

---

# 35. Remaining Acceptance Criteria

Before production rollout:

- validate `sysprofile.lruwrites` availability and semantics on the target Informix version;
- validate monitoring-user permissions;
- measure query cost under target workload;
- establish normal LRU-write rate;
- correlate counter resets with `IFX-HEALTH-002 — Instance Uptime`;
- validate deployment on the target AIX or Linux collection host.