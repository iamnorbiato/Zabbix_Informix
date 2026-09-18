# IFX-SESSION-002 — Active Sessions

## 1. Purpose

This document defines the engineering contract for:

`IFX-SESSION-002 — Active Sessions`

The metric measures the current number of Informix sessions considered active according to a future authoritative source definition.

This specification defines the provisional semantic and normalized collection contract that can be validated without access to a real Informix/AIX environment.

The authoritative definition of an active session remains pending real source validation.

---

# 2. Monitoring Domain

Domain:

`Connections, Sessions and Concurrency`

Metric ID:

`IFX-SESSION-002`

Metric name:

`Active Sessions`

---

# 3. Monitoring Objective

The metric shall provide visibility into the current level of active session workload within the Informix instance.

It is intended to support:

- current workload visibility;
- active-versus-connected session analysis;
- concurrency analysis;
- abnormal workload detection;
- correlation with SQL activity;
- correlation with locks and waits;
- correlation with Informix and AIX resource pressure.

---

# 4. Candidate Source

Primary candidate source:

`sysmaster`

Exact authoritative table/view:

`PENDING SOURCE VALIDATION`

Exact authoritative SQL:

`PENDING SOURCE VALIDATION`

---

# 5. Critical Semantic Question

The term:

`active session`

is not considered authoritative at this stage.

Real source validation must determine what Informix state or combination of states represents activity for this metric.

Possible interpretations may include sessions:

- currently executing SQL;
- associated with actively executing threads;
- currently runnable;
- currently performing engine work;
- not idle;
- waiting while participating in active work.

These possibilities are investigative questions only.

No one interpretation is approved by this specification.

---

# 6. Session and Thread Relationship

Informix activity may require correlation between session and thread information.

Real validation must determine whether activity is represented directly at session level or must be inferred from associated thread state.

The mock contract shall not encode assumptions about this relationship.

---

# 7. Waiting and Blocked Sessions

A session may be connected and performing workload while temporarily waiting for:

- locks;
- I/O;
- memory;
- network activity;
- engine resources;
- another session.

Whether such a session is considered active must be determined from authoritative Informix semantics.

The mock parser shall not make this decision.

---

# 8. Internal Sessions

The authoritative source may expose:

- client sessions;
- administrative sessions;
- internal engine sessions;
- system-generated activity.

Real source validation must establish which categories belong in the active-session count.

---

# 9. Provisional Semantic

For mock validation, the metric semantic is:

`current number of sessions classified as active by an already normalized authoritative source result`

The classification itself is outside the mock contract.

---

# 10. Metric Type

Type:

`GAUGE`

Each successful sample represents the current observed active-session count.

It is not a cumulative counter.

---

# 11. Normalized Unit

Normalized unit:

`SESSIONS`

Example:

```text id="5ttodx"
18
```

means:

`18 sessions currently classified as active`

under the future approved definition.

---

# 12. Value Domain

The normalized value shall be a non-negative integer.

Valid examples:

```text id="3djnra"
0
1
18
250
```

Invalid examples:

```text id="xt56sp"
-1
4.5
active
```

---

# 13. Zero Semantics

Zero is a valid successful observation.

Input:

```text id="td7b7q"
0
```

shall produce:

```text id="ojkmlb"
0
```

if collection succeeded.

Collection failure must never be converted into zero.

---

# 14. Gauge Behavior

Samples may increase or decrease freely.

Example:

```text id="b77svw"
18
31
7
```

All observations are independently valid.

No reset semantics apply.

---

# 15. Relationship with Total Connected Sessions

This metric is closely related to:

`IFX-SESSION-001 — Total Connected Sessions`

Conceptually, active sessions represent some subset or classification within overall session activity.

However, the parser shall not enforce:

```text id="jvmrqs"
Active Sessions <= Total Connected Sessions
```

Reasons include:

- metrics may be collected at different instants;
- source semantics remain provisional;
- source queries may have different timing;
- session populations may change between samples.

Cross-metric consistency belongs to later monitoring and correlation logic.

---

# 16. Collection Method

Provisional collection method:

`SQL statement through collector`

Final implementation remains subject to source validation.

---

# 17. Collection Frequency

Catalog frequency:

`HIGH or MEDIUM`

Exact polling interval:

`PENDING IMPLEMENTATION DESIGN`

---

# 18. Collection Cost

Catalog expectation:

`LOW to MEDIUM`

Actual cost must be measured or reasonably established during source validation.

---

# 19. Output Cardinality

Expected normalized output:

`one scalar per Informix instance`

Example:

```text id="tndw07"
18
```

Multiple scalar values are invalid under the normalized parser contract.

---

# 20. Aggregation Boundary

Any source-level classification, filtering or aggregation belongs to the authoritative query or collector.

The normalization parser shall receive one already aggregated scalar.

It shall not:

- count source rows;
- inspect thread states;
- classify sessions;
- filter internal sessions;
- determine idle status;
- aggregate multiple scalar results.

---

# 21. Discovery

Zabbix Low-Level Discovery:

`NO`

This metric represents an instance-level aggregate.

Future per-session diagnostics require a separate design.

---

# 22. Trigger Potential

Catalog trigger position:

`NORMALLY NO DIRECT TRIGGER`

The metric is primarily contextual.

Future derived conditions may use:

- sustained active-session growth;
- active/connected relationship;
- concurrency baselines;
- correlation with waits or resource saturation.

No fixed threshold is defined here.

---

# 23. Grafana

Grafana visualization:

`YES`

Useful representations may include:

- current active sessions;
- active-session history;
- active versus connected sessions;
- workload periods;
- correlations with locks;
- correlations with SQL activity;
- correlations with CPU, memory and I/O.

---

# 24. Collection Failure

Collection failure is distinct from every numeric observation.

Examples include:

- SQL execution failure;
- Informix connection failure;
- authentication failure;
- permission failure;
- unavailable source;
- malformed output.

Collection failure shall not emit zero as a valid metric.

---

# 25. Mock Normalization Contract

For mock validation, the parser receives one file containing one normalized scalar.

Example:

```text id="ntym0j"
18
```

Expected output:

```text id="eycv4j"
18
```

The parser validates only the scalar gauge contract.

It does not validate the definition of active session.

---

# 26. Provisional Mock Scenarios

Planned mocks:

| Mock | Expected |
|---|---:|
| `normal.txt` | `18` |
| `zero.txt` | `0` |
| `single.txt` | `1` |
| `high.txt` | `750` |
| `lower.txt` | `6` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

Values are synthetic and do not represent production baselines.

---

# 27. Parser Responsibilities

The future mock parser shall:

1. detect explicit source execution failure;
2. obtain the normalized scalar;
3. trim permitted surrounding whitespace;
4. require exactly one value;
5. require a non-negative integer;
6. emit the normalized active-session count.

---

# 28. Parser Non-Responsibilities

The parser shall not:

- execute the final SQL;
- define active-session semantics;
- classify sessions;
- inspect Informix thread state;
- determine idle status;
- filter internal sessions;
- compare against total connected sessions;
- determine alert severity;
- convert collection failure into zero.

---

# 29. Source Validation Questions

Real Informix validation must answer at least:

1. What is the authoritative definition of an active session?
2. Which `sysmaster` object or objects expose the required information?
3. Is activity represented at session or thread level?
4. What thread states correspond to active work?
5. Are sessions waiting for locks considered active?
6. Are sessions waiting for I/O considered active?
7. Are idle connected sessions excluded?
8. Are internal engine sessions exposed?
9. Which internal or administrative sessions should be excluded?
10. Can one session have multiple relevant threads?
11. How must such relationships be counted without double-counting sessions?
12. What exact SQL produces the desired instance-level count?
13. What permissions are required?
14. What is the query cost?
15. Are there relevant differences between supported Informix versions?
16. Is there an appropriate `onstat` view for independent validation?

---

# 30. Source Validation Acceptance Criteria

The metric may become:

`SOURCE_VALIDATED`

only after:

- authoritative activity semantic is established;
- authoritative source is identified;
- session/thread relationship is understood;
- inclusion and exclusion rules are documented;
- exact SQL is validated;
- duplicate-session counting is prevented;
- normalized unit is confirmed;
- permissions are known;
- collection cost is understood;
- relevant version differences are documented;
- independent validation is performed where practical.

---

# 31. Mock Validation Acceptance Criteria

The metric may become:

`MOCK_VALIDATED`

when:

- mock inputs exist;
- parser specification exists;
- parser is implemented;
- all valid mock scenarios return expected values;
- all invalid scenarios fail;
- collection failure never becomes numeric zero.

Mock validation does not establish what an active Informix session is.

---

# 32. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Current source status:

`CANDIDATE SOURCE — sysmaster`

Current semantic:

`PROVISIONAL — CURRENT ACTIVE SESSION COUNT`

Metric semantics:

`GAUGE`

Normalized unit:

`SESSIONS — MOCK CONTRACT`

Active-session definition:

`PENDING SOURCE VALIDATION`

Session/thread relationship:

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

Create the mock dataset for `IFX-SESSION-002`.

The mocks shall validate only the normalized instance-level active-session gauge contract.

They shall not encode an unvalidated definition of Informix session activity.
