# IFX-LOCK-001 — Sessions Waiting for Locks — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-LOCK-001 — Sessions Waiting for Locks`

The parser validates and normalizes the scalar collection result representing the current number of Informix sessions blocked while waiting for a lock.

Mock validation establishes the normalized scalar contract only.

It does not establish the authoritative Informix source or prove that the source entity is a session.

---

# 2. Architectural Metric

Metric:

`Sessions Waiting for Locks`

Domain:

`Locks, Deadlocks and Contention`

Metric ID:

`IFX-LOCK-001`

---

# 3. Candidate Source

Preferred candidate interface:

`sysmaster`

Alternative supporting interface:

`onstat`

Exact authoritative source:

`PENDING SOURCE VALIDATION`

Exact SQL or command:

`PENDING SOURCE VALIDATION`

---

# 4. Provisional Semantic

The normalized value provisionally represents:

`CURRENT NUMBER OF INFORMIX SESSIONS BLOCKED WAITING FOR A LOCK`

The session entity remains subject to real source validation.

---

# 5. Metric Type

Metric type:

`GAUGE`

The value represents current state at collection time.

It is not a cumulative lock-wait counter.

---

# 6. Normalized Unit

Provisional unit:

`SESSIONS`

This unit remains pending authoritative entity validation.

---

# 7. Cardinality

Cardinality:

`ONE VALUE PER INFORMIX INSTANCE`

The parser receives one scalar result.

---

# 8. Input Contract

For successful collection, the parser receives exactly one normalized scalar value.

Example:

```text
12
```

The value must represent the already aggregated result produced by the validated collection layer.

---

# 9. Value Domain

The value must be a non-negative integer.

Valid examples:

```text
0
1
12
500
```

Invalid examples:

```text
-1
2.5
waiting
```

---

# 10. Zero Semantics

Input:

```text
0
```

is valid.

It provisionally means:

`NO SESSIONS CURRENTLY OBSERVED AS BLOCKED WAITING FOR A LOCK`

The parser shall preserve zero.

---

# 11. Empty Input

An empty successful input is invalid.

Input:

```text
<empty>
```

shall result in parser failure.

Unlike the dynamic `IFX-SESSION-005` dataset, this scalar metric requires one explicit value for every successful collection.

---

# 12. Execution Failure

An explicit execution-error input such as:

```text
EXIT_CODE=1
STDOUT=
STDERR=SQL execution failed
```

represents:

`COLLECTION_FAILURE`

The parser shall fail.

It shall not convert collection failure into:

```text
0
```

---

# 13. Whitespace

Leading and trailing whitespace around the scalar value may be removed.

Example:

```text
   12
```

may normalize to:

```text
12
```

Internal whitespace or additional tokens are invalid.

---

# 14. Single-Value Rule

A successful input must normalize to exactly one scalar value.

Multiple result values are invalid.

For example:

```text
12
13
```

shall fail.

The parser shall not:

- choose the first value;
- choose the last value;
- sum the values;
- average the values.

---

# 15. Aggregation Boundary

The parser does not calculate the number of waiting sessions from source rows.

The validated collection layer owns:

- lock-wait identification;
- entity identification;
- filtering;
- deduplication;
- aggregation.

The parser receives only the resulting scalar.

---

# 16. Entity Boundary

The parser does not determine whether the authoritative Informix entity is:

```text
session
thread
waiter
transaction
```

That question belongs to `SOURCE_VALIDATED`.

The parser validates only the provisional scalar contract.

---

# 17. Output Contract

For successful input:

```text
stdout = normalized non-negative integer
stderr = empty
return code = 0
```

Example:

Input:

```text
12
```

Output:

```text
12
```

Return code:

```text
0
```

---

# 18. Failure Output Contract

On validation or collection failure:

```text
stdout = empty
stderr = diagnostic message
return code != 0
```

No numeric fallback value shall be emitted.

---

# 19. Parser Responsibilities

The parser shall:

1. validate invocation;
2. validate input readability;
3. detect explicit collection execution failure;
4. require a scalar result;
5. trim permitted surrounding whitespace;
6. validate exactly one value;
7. validate a non-negative integer;
8. preserve zero;
9. emit the normalized integer only after successful validation.

---

# 20. Parser Non-Responsibilities

The parser shall not:

- query Informix;
- execute the final SQL;
- identify lock waiters;
- identify blockers;
- count source rows;
- deduplicate sessions;
- convert threads into sessions;
- infer the monitored entity;
- classify lock types;
- derive lock wait duration;
- correlate with other metrics;
- generate alerts;
- convert failure into zero.

---

# 21. Processing Order

The parser shall process input in this order:

```text
validate invocation
        ↓
validate input readability
        ↓
detect explicit execution failure
        ↓
read normalized result
        ↓
reject empty result
        ↓
validate exactly one scalar
        ↓
trim surrounding whitespace
        ↓
validate non-negative integer
        ↓
emit normalized value
```

---

# 22. Mock Dataset

Mock directory:

`04-mocks/informix-locks/IFX-LOCK-001/`

Cases:

| Mock | Expected Result |
|---|---|
| `normal.txt` | success — `12` |
| `zero.txt` | success — `0` |
| `single.txt` | success — `1` |
| `high.txt` | success — `500` |
| `lower.txt` | success — `3` |
| `empty.txt` | failure |
| `nonnumeric.txt` | failure |
| `negative.txt` | failure |
| `decimal.txt` | failure |
| `execution-error.txt` | failure |

---

# 23. Mock Acceptance Criteria

Mock validation passes only when all 10 scenarios behave exactly as defined.

Expected results:

```text
normal           -> rc=0, stdout=12
zero             -> rc=0, stdout=0
single           -> rc=0, stdout=1
high             -> rc=0, stdout=500
lower            -> rc=0, stdout=3

empty            -> rc!=0, stdout empty
nonnumeric       -> rc!=0, stdout empty
negative         -> rc!=0, stdout empty
decimal          -> rc!=0, stdout empty
execution-error  -> rc!=0, stdout empty
```

Expected runner result:

```text
PASS: 10
FAIL: 0
```

---

# 24. Source Validation Requirements

Before operational collection, real Informix validation must establish:

- authoritative lock-wait source;
- monitored entity;
- session identity semantics;
- lock-wait semantics;
- aggregation rules;
- deduplication rules;
- internal/system entity handling;
- exact SQL or command;
- required permissions;
- collection cost;
- scalability;
- relevant Informix version behavior.

---

# 25. Relationship with IFX-SESSION-004

Related metric:

`IFX-SESSION-004 — Waiting Client Sessions Total`

No arithmetic relationship is enforced by the parser.

The monitored entities may differ.

Relationship status:

`UNPROVEN`

---

# 26. Relationship with IFX-SESSION-005

Related metric:

`IFX-SESSION-005 — Waiting Client Sessions by Reason`

The fixed `LOCK` dimension of `IFX-SESSION-005` represents qualifying client sessions for which:

```text
syssessions.is_wlock = 1
```

It may correlate with `IFX-LOCK-001`, but the parser shall not assume equivalence, identity, or an arithmetic relationship.

The two metrics can differ in source timing, session filtering, visibility and aggregation.

Relationship status:

`UNPROVEN`

---

# 27. Lifecycle Advancement

Successful mock validation permits:

```text
DEFINED
   ↓
MOCK_VALIDATED
```

It does not permit:

`SOURCE_VALIDATED`

or:

`COLLECTION_VALIDATED`

Real Informix/AIX validation remains mandatory.

---

# 28. Current Status

Specification:

`APPROVED`

Architectural metric:

`Sessions Waiting for Locks`

Current semantic:

`PROVISIONAL — CURRENT NUMBER OF INFORMIX SESSIONS BLOCKED WAITING FOR A LOCK`

Metric semantics:

`GAUGE`

Normalized unit:

`SESSIONS — PROVISIONAL`

Cardinality:

`ONE VALUE PER INFORMIX INSTANCE`

Candidate source:

`sysmaster`

Alternative supporting interface:

`onstat`

Authoritative monitored entity:

`PENDING SOURCE VALIDATION`

Exact source:

`PENDING SOURCE VALIDATION`

Exact SQL/command:

`PENDING SOURCE VALIDATION`

Mock inputs:

`AVAILABLE`

Parser implementation:

`IMPLEMENTED`

Mock validation:

`PASSED — 10/10`

Metric lifecycle state:

`MOCK_VALIDATED`

Real environment validation:

`PENDING`

---

# 29. Next Step

Validate the metric and parser contract against the real Informix/AIX environment when it becomes available.

Source validation must confirm the authoritative lock-wait source, monitored entity, aggregation and deduplication semantics, and compatibility with the normalized scalar contract.

Until then:

`IFX-LOCK-001 = MOCK_VALIDATED`

---
