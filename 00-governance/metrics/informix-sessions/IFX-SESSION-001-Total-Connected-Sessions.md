# IFX-SESSION-001 — Total Connected Sessions

## 1. Purpose

This document defines the engineering contract for:

`IFX-SESSION-001 — Total Connected Sessions`

The metric measures the current number of connected Informix sessions.

This specification defines the provisional semantic and collection contract that can be validated without access to a real Informix/AIX environment.

Authoritative source semantics remain pending real source validation.

---

# 2. Monitoring Domain

Domain:

`Connections, Sessions and Concurrency`

Metric ID:

`IFX-SESSION-001`

Metric name:

`Total Connected Sessions`

---

# 3. Monitoring Objective

The metric shall provide visibility into the current number of sessions connected to the Informix instance.

It is intended to support:

- current connection-load visibility;
- session-capacity monitoring;
- workload correlation;
- abnormal connection-growth detection;
- historical concurrency analysis;
- correlation with engine and operating-system pressure.

---

# 4. Candidate Source

Primary candidate source:

`sysmaster`

Exact authoritative table/view:

`PENDING SOURCE VALIDATION`

Exact authoritative SQL:

`PENDING SOURCE VALIDATION`

---

# 5. Source Validation Requirement

The exact Informix definition of a connected session must be established against a real Informix environment.

Source validation must determine which `sysmaster` records represent sessions that belong in the metric.

In particular, validation must determine whether the candidate source includes:

- external client sessions;
- administrative sessions;
- internal engine sessions;
- system-generated sessions;
- inactive but still connected sessions;
- sessions in transitional states.

No filtering rule shall be considered authoritative before this validation.

---

# 6. Provisional Semantic

For mock validation, the metric semantic is:

`current number of connected sessions represented by an already normalized source result`

The mock contract deliberately does not define how Informix rows are filtered or counted.

That responsibility remains pending source validation.

---

# 7. Metric Type

Type:

`GAUGE`

The metric represents the current observed number of connected sessions.

It is not a cumulative counter.

---

# 8. Normalized Unit

Normalized unit:

`SESSIONS`

Example:

```text
42
```

means:

`42 currently connected sessions`

under the future approved source definition.

---

# 9. Value Domain

The normalized value shall be a non-negative integer.

Valid examples:

```text
0
1
42
500
```

Invalid examples:

```text
-1
12.5
sessions
```

---

# 10. Zero Semantics

Zero is a syntactically valid value.

Input:

```text
0
```

shall produce:

```text
0
```

if collection succeeded.

Whether zero connected sessions is operationally expected for a particular running Informix instance is a monitoring interpretation and not a parser decision.

Collection failure must never be converted into zero.

---

# 11. Gauge Semantics

Each successful sample represents the current observed session count.

A later sample may be:

- greater;
- equal;
- lower.

Example:

```text
42
57
31
```

All three observations are independently valid.

No reset semantics apply because this metric is a gauge.

---

# 12. Collection Method

Provisional collection method:

`SQL statement through collector`

The final implementation method remains subject to source validation.

---

# 13. Collection Frequency

Catalog frequency:

`HIGH or MEDIUM`

Exact polling interval:

`PENDING IMPLEMENTATION DESIGN`

The interval shall balance timely detection of connection changes against monitoring overhead.

---

# 14. Collection Cost

Expected cost:

`LOW`

Actual query and collection cost must be confirmed during source validation.

---

# 15. Output Cardinality

Expected normalized output:

`one scalar per Informix instance`

Example:

```text
42
```

Multiple scalar values are invalid under this contract.

---

# 16. Aggregation Boundary

The future source query may need to count multiple `sysmaster` rows.

That aggregation belongs to the authoritative source/query definition.

The normalization parser shall receive one already aggregated scalar.

The parser shall not independently:

- count rows;
- classify sessions;
- filter session types;
- infer client versus internal sessions;
- aggregate multiple scalar values.

---

# 17. Discovery

Zabbix Low-Level Discovery:

`NO`

This metric represents an instance-level aggregate.

Per-session monitoring, if introduced later, belongs to a separate metric/discovery design.

---

# 18. Trigger Potential

Trigger support:

`YES — CONDITIONAL`

Possible future monitoring conditions include:

- sustained unusually high connection count;
- approach to configured session capacity;
- abnormal connection growth.

No fixed threshold is defined by this specification.

Threshold design belongs to later Zabbix implementation and baseline tuning.

---

# 19. Grafana

Grafana visualization:

`YES`

Useful representations may include:

- current connected sessions;
- session-count history;
- peak observed concurrency;
- correlation with active sessions;
- correlation with locks and waits;
- correlation with Informix and AIX resource pressure.

---

# 20. Relationship with Other Metrics

This metric is expected to correlate with:

`IFX-SESSION-002 — Active Sessions`

and potentially:

`IFX-SESSION-003 — Historical Session Peak`

It may also be correlated with:

- locks and contention;
- SQL workload;
- memory consumption;
- CPU utilization;
- Informix thread activity;
- configured session capacity.

---

# 21. Historical Maximum

This metric itself does not calculate a historical maximum.

A historical maximum may be:

- provided by an authoritative Informix source; or
- derived from this metric by Zabbix.

That architectural decision belongs to:

`IFX-SESSION-003 — Historical Session Peak`

---

# 22. Collection Failure

Collection failure is distinct from every numeric value.

Examples include:

- SQL execution failure;
- Informix connection failure;
- authentication failure;
- malformed source output;
- unavailable source;
- permission failure.

A collection failure shall not emit:

```text
0
```

as a valid session count.

---

# 23. Mock Normalization Contract

For mock validation, the parser shall receive a file containing one normalized scalar.

Example input:

```text
42
```

Expected output:

```text
42
```

The parser validates the normalized metric contract only.

It does not validate the future SQL statement.

---

# 24. Valid Mock Inputs

The mock set shall include successful examples for:

- normal session count;
- zero sessions;
- single session;
- high session count;
- lower subsequent observation.

---

# 25. Invalid Mock Inputs

The mock set shall include failure examples for:

- empty result;
- non-numeric result;
- negative value;
- decimal value;
- source execution failure.

---

# 26. Provisional Mock Scenarios

Planned mock scenarios:

| Mock | Expected |
|---|---:|
| `normal.txt` | `42` |
| `zero.txt` | `0` |
| `single.txt` | `1` |
| `high.txt` | `5000` |
| `lower.txt` | `17` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

The values are synthetic and do not represent production baselines.

---

# 27. Parser Responsibilities

The future mock parser shall:

1. detect explicit source execution failure;
2. obtain the normalized scalar;
3. ignore permitted surrounding whitespace;
4. require exactly one value;
5. require a non-negative integer;
6. emit the normalized session count.

---

# 28. Parser Non-Responsibilities

The parser shall not:

- execute the final SQL statement;
- determine which Informix sessions count;
- classify session types;
- count multiple source rows;
- calculate historical maximum;
- calculate trends;
- determine alert severity;
- convert collection failure into zero.

---

# 29. Source Validation Questions

Real Informix validation must answer at least:

1. Which `sysmaster` table or view is authoritative?
2. Which rows represent connected sessions?
3. Are internal engine sessions present?
4. Should internal sessions be excluded?
5. Are administrative sessions included?
6. Are inactive but connected clients included?
7. Are transitional session states relevant?
8. What exact SQL produces the desired instance-level count?
9. Does the source differ across supported Informix versions?
10. What permissions are required?
11. What is the query cost under realistic concurrency?
12. Is there an appropriate `onstat` representation for independent validation?

---

# 30. Source Validation Acceptance Criteria

The metric may become:

`SOURCE_VALIDATED`

only after:

- authoritative source is identified;
- session inclusion semantics are established;
- exclusion rules are documented;
- exact SQL is validated;
- normalized unit is confirmed;
- query cost is measured or reasonably established;
- required permissions are known;
- relevant version differences are understood;
- results are compared with an independent operational view where practical.

---

# 31. Mock Validation Acceptance Criteria

The metric may become:

`MOCK_VALIDATED`

when:

- mock inputs exist;
- parser contract is documented;
- parser is implemented;
- all valid mock scenarios return the expected scalar;
- all invalid scenarios fail collection;
- collection failure never becomes numeric zero.

Mock validation does not satisfy source validation.

---

# 32. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Current source status:

`CANDIDATE SOURCE — sysmaster`

Current semantic:

`PROVISIONAL — CURRENT CONNECTED SESSION COUNT`

Metric semantics:

`GAUGE`

Normalized unit:

`SESSIONS — MOCK CONTRACT`

Session inclusion rules:

`PENDING SOURCE VALIDATION`

Exact sysmaster source:

`PENDING SOURCE VALIDATION`

Exact SQL:

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

# 33. Next Step

Create the mock dataset for `IFX-SESSION-001`.

The mocks shall validate only the normalized instance-level session-count contract.

They shall not encode assumptions about which Informix session rows belong in the authoritative count.
