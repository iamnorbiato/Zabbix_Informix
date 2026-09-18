# IFX-SESSION-004 — Waiting Threads Total

## 1. Purpose

This document defines the engineering contract for:

`IFX-SESSION-004 — Waiting Threads Total`

The metric represents the current total number of Informix threads classified by an authoritative Informix source as being in a waiting state.

It provides the instance-level aggregate view of current thread waiting pressure.

Detailed wait reasons are intentionally represented by a separate dynamic metric:

`IFX-SESSION-005 — Waiting Threads by Reason`

---

# 2. Monitoring Domain

Domain:

`Connections, Sessions and Concurrency`

Metric ID:

`IFX-SESSION-004`

Metric name:

`Waiting Threads Total`

---

# 3. Architectural Decision

The previous catalog concept:

`Generic Thread Waits`

is replaced by:

`Waiting Threads Total`

The metric represents current state.

It shall not represent a cumulative count of historical wait events.

Metric semantic:

`GAUGE`

---

# 4. Monitoring Objective

The metric shall provide visibility into the current amount of thread waiting activity inside the Informix instance.

It is intended to support:

- detection of abnormal waiting pressure;
- concurrency analysis;
- workload diagnostics;
- correlation with locks;
- correlation with I/O pressure;
- correlation with session activity;
- correlation with AIX resource pressure;
- comparison with wait-reason dimensions.

---

# 5. Candidate Source

Candidate sources:

`sysmaster`

and/or:

`onstat`

Exact authoritative source:

`PENDING SOURCE VALIDATION`

Exact SQL or command:

`PENDING SOURCE VALIDATION`

---

# 6. Critical Semantic Requirement

The exact meaning of an Informix thread being:

`WAITING`

must be established from the authoritative source.

No thread state shall be classified as waiting merely because its name appears to imply inactivity or delay.

Source validation must establish the actual Informix thread-state semantics.

---

# 7. Provisional Semantic

For mock validation:

`CURRENT NUMBER OF INFORMIX THREADS CLASSIFIED AS WAITING BY THE AUTHORITATIVE SOURCE`

---

# 8. Metric Type

Type:

`GAUGE`

This metric represents current state.

It is not:

- a cumulative wait counter;
- a rate;
- a historical total;
- a count of wait transitions.

---

# 9. Normalized Unit

Normalized unit:

`THREADS`

Example:

```text
22
```

means that 22 Informix threads are currently classified as waiting.

---

# 10. Value Domain

Valid normalized values are non-negative integers.

Examples:

```text
0
1
22
750
```

Invalid examples:

```text
-1
4.5
waiting
```

---

# 11. Zero Semantics

Zero is a valid operational value.

```text
0
```

means:

`no threads were classified as waiting at collection time`

Collection failure shall never become zero.

---

# 12. Gauge Behavior

The value may increase or decrease between observations.

Example:

```text
22
31
8
0
17
```

All are independently valid observations.

The parser shall maintain no historical state.

---

# 13. Instance Scope

Expected scope:

`ONE INFORMIX INSTANCE`

The normalized result shall contain one scalar representing the total current waiting threads for that instance.

Exact scope must be confirmed during source validation.

---

# 14. Thread Classification Boundary

The authoritative source must determine which threads belong to the waiting population.

The parser shall not classify individual thread records.

If source processing requires filtering or aggregation, that logic belongs to the validated collection layer.

---

# 15. Relationship with IFX-SESSION-005

Detailed wait-reason information shall be represented separately by:

`IFX-SESSION-005 — Waiting Threads by Reason`

Conceptually:

```text
Waiting Threads Total
        |
        +--> wait reason A
        +--> wait reason B
        +--> wait reason C
        +--> ...
```

However, `IFX-SESSION-004` shall remain an independent instance-level scalar contract.

---

# 16. No Silent Sum Rule

The value of:

`IFX-SESSION-004`

shall not automatically be calculated as:

```text
SUM(IFX-SESSION-005 wait reasons)
```

until real source validation proves that:

- wait-reason classes are mutually exclusive;
- every waiting thread has exactly one classified reason;
- no waiting thread is omitted;
- no thread can appear in multiple classes;
- both metrics share equivalent collection scope and timing.

Until then, total and dimensional views remain independently validated contracts.

---

# 17. Relationship with Sessions

This metric may be correlated with:

`IFX-SESSION-001 — Total Connected Sessions`

and:

`IFX-SESSION-002 — Active Sessions`

No parser-level relationship shall be enforced.

Threads and sessions shall not be assumed to have a one-to-one relationship.

---

# 18. Relationship with Locks

Some waiting threads may ultimately be associated with lock-related waits.

Lock-specific semantics shall not be inferred by this metric.

Lock diagnostics may be represented through:

- `IFX-SESSION-005 — Waiting Threads by Reason`;
- future lock-specific metrics.

---

# 19. Collection Method

Expected collection method:

`SQL statement or collector using authoritative Informix thread-state information`

Final collection method:

`PENDING SOURCE VALIDATION`

---

# 20. Collection Frequency

Recommended catalog frequency:

`HIGH`

The metric represents transient current state.

Collection frequency must balance:

- diagnostic usefulness;
- transient wait visibility;
- collection overhead.

Final interval shall be determined after real collection-cost validation.

---

# 21. Collection Cost

Current classification:

`UNKNOWN`

Real validation must measure or establish collection cost.

Monitoring overhead is a first-class acceptance criterion.

---

# 22. Output Cardinality

Expected normalized output:

`ONE SCALAR PER INFORMIX INSTANCE`

Example:

```text
22
```

Multiple normalized values are invalid.

---

# 23. Aggregation Boundary

If the authoritative source exposes individual thread rows, the collection layer may need to classify/filter/count them.

That aggregation shall occur before the scalar parser contract.

The scalar parser shall not silently count arbitrary input rows.

---

# 24. Discovery

Zabbix Low-Level Discovery:

`NO`

This metric represents one fixed total per Informix instance.

Dynamic discovery belongs to:

`IFX-SESSION-005 — Waiting Threads by Reason`

---

# 25. Trigger Potential

Trigger support:

`YES — CONDITIONAL`

Potential future conditions include:

- sustained high waiting-thread population;
- abnormal ratio between waiting and active workload;
- sudden increase in waiting pressure.

No fixed threshold is defined at this stage.

---

# 26. Grafana

Grafana visualization:

`YES`

Useful correlations include:

- waiting threads total;
- waiting threads by reason;
- active sessions;
- connected sessions;
- locks;
- I/O;
- CPU;
- memory;
- engine health.

---

# 27. Collection Failure

Collection failure is distinct from every numeric value.

Examples include:

- SQL execution failure;
- command execution failure;
- Informix connection failure;
- permission failure;
- malformed source result;
- unavailable thread-state information.

Collection failure shall not emit zero.

---

# 28. Mock Normalization Contract

For mock validation, the parser receives one file containing one already normalized scalar.

Example:

```text
22
```

Expected output:

```text
22
```

Mock validation does not establish which real Informix thread states qualify as waiting.

---

# 29. Provisional Mock Scenarios

Planned mocks:

| Mock | Expected |
|---|---:|
| `normal.txt` | `22` |
| `zero.txt` | `0` |
| `single.txt` | `1` |
| `high.txt` | `750` |
| `lower.txt` | `8` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

---

# 30. Parser Responsibilities

The future parser shall:

1. detect explicit source execution failure;
2. obtain the normalized scalar;
3. trim permitted surrounding whitespace;
4. require exactly one value;
5. validate a non-negative integer;
6. emit the normalized waiting-thread total.

---

# 31. Parser Non-Responsibilities

The parser shall not:

- determine the final SQL or command;
- define Informix waiting semantics;
- inspect individual thread states;
- classify wait reasons;
- count arbitrary thread rows;
- derive `SESSION-005`;
- sum `SESSION-005`;
- compare with sessions;
- maintain history;
- generate alerts;
- convert failure into zero.

---

# 32. Source Validation Questions

Real Informix validation must answer at least:

1. Which authoritative source exposes current thread state?
2. Which `sysmaster` object is relevant?
3. Which `onstat` representation is relevant?
4. What states constitute waiting?
5. Are waiting states mutually exclusive?
6. Are internal/system threads included?
7. Should any internal/system threads be excluded?
8. What is the relationship between sessions and threads?
9. Can one session own multiple relevant threads?
10. Can one thread transition among multiple wait states during collection?
11. Is there a native instance-level waiting total?
12. If not, what authoritative aggregation produces the total?
13. Are wait reasons exposed separately?
14. Are wait reasons stable identifiers or human-readable descriptions?
15. What permissions are required?
16. What is the collection cost?
17. Are there relevant Informix version differences?

---

# 33. Source Validation Acceptance Criteria

The metric may become:

`SOURCE_VALIDATED`

only after:

- authoritative waiting-state semantics are established;
- exact source is identified;
- scope is established;
- filtering rules are documented;
- aggregation rules are documented;
- exact SQL/command is documented;
- permissions are known;
- collection cost is acceptable;
- relevant version behavior is understood.

---

# 34. Mock Validation Acceptance Criteria

The metric may become:

`MOCK_VALIDATED`

when:

- mock inputs exist;
- parser specification exists;
- parser is implemented;
- all valid scalar cases are preserved;
- invalid/error cases fail;
- zero remains valid;
- collection failure never becomes zero.

Mock validation does not establish real waiting-state semantics.

---

# 35. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Previous catalog concept:

`Generic Thread Waits`

Architectural metric:

`Waiting Threads Total`

Current source status:

`PENDING SOURCE VALIDATION`

Candidate interfaces:

`sysmaster / onstat`

Current semantic:

`PROVISIONAL — CURRENT NUMBER OF INFORMIX THREADS CLASSIFIED AS WAITING`

Metric semantics:

`GAUGE`

Normalized unit:

`THREADS — MOCK CONTRACT`

Waiting-state definition:

`PENDING SOURCE VALIDATION`

Exact Informix source:

`PENDING SOURCE VALIDATION`

Exact SQL/command:

`PENDING SOURCE VALIDATION`

Dynamic wait-reason metric:

`IFX-SESSION-005 — Waiting Threads by Reason`

Relationship with SESSION-005 sum:

`UNPROVEN`

Zabbix LLD:

`NO — RESERVED FOR IFX-SESSION-005`

Mock inputs:

`AVAILABLE`

Parser implementation:

`IMPLEMENTED`

Mock validation:

`PASSED — 10/10`

Real Informix/AIX validation:

`PENDING`

---

# 36. Next Step

Create the mock dataset for `IFX-SESSION-004`.

The mocks shall validate only the normalized instance-level waiting-thread scalar contract.

Wait-reason discovery and dynamic metric generation belong exclusively to `IFX-SESSION-005`.
