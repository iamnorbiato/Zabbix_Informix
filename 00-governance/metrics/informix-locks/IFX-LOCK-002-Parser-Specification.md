# IFX-LOCK-002 — Maximum Lock Wait Time — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-LOCK-002 — Maximum Lock Wait Time`

The parser validates and normalizes the scalar collection result representing the age, in seconds, of the oldest currently active Informix lock wait.

Mock validation establishes the normalized scalar duration contract only.

It does not establish the authoritative Informix lock source or timing representation.

---

# 2. Architectural Metric

Metric:

`Maximum Lock Wait Time`

Domain:

`Locks, Deadlocks and Contention`

Metric ID:

`IFX-LOCK-002`

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

`AGE IN SECONDS OF THE OLDEST CURRENTLY ACTIVE LOCK WAIT`

This is a current-state duration.

It is not a historical maximum.

---

# 5. Metric Type

Metric type:

`GAUGE`

Historical maximum:

`NO`

Monotonic:

`NO`

The value may legitimately increase or decrease between collections.

---

# 6. Normalized Unit

Unit:

`SECONDS`

Mock-contract precision:

`WHOLE SECONDS`

Final source precision remains pending real source validation.

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
45
```

The value must already represent the maximum current lock-wait age calculated by the validated collection layer.

---

# 9. Value Domain

The value must be a non-negative integer.

Valid examples:

```text
0
1
45
3600
```

Invalid examples:

```text
-1
3.5
seconds
```

---

# 10. Zero Semantics

Input:

```text
0
```

is valid.

It may represent:

`NO CURRENTLY ACTIVE LOCK WAIT`

and may also be compatible with a newly observed wait whose age is below the source's effective whole-second precision.

Exact source semantics remain pending validation.

The parser shall preserve zero.

---

# 11. Empty Input

An empty successful input is invalid.

Input:

```text
<empty>
```

shall result in parser failure.

A successful collection with no active lock waits must explicitly normalize to:

```text
0
```

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
   45
```

may normalize to:

```text
45
```

Internal whitespace or additional tokens are invalid.

---

# 14. Single-Value Rule

A successful input must normalize to exactly one scalar value.

Multiple values are invalid.

For example:

```text
45
50
```

shall fail.

The parser shall not:

- select one value;
- calculate the maximum;
- calculate an average;
- sum the values.

---

# 15. Maximum Calculation Boundary

The parser does not calculate the oldest wait from individual lock-wait records.

The validated collection layer owns:

- identifying currently active lock waits;
- obtaining authoritative timing information;
- calculating current wait age when necessary;
- calculating the maximum current wait age;
- producing the normalized scalar.

The parser receives only that scalar.

---

# 16. Timing Calculation Boundary

If Informix provides a wait-start timestamp rather than elapsed duration, timestamp arithmetic belongs to the validated collection layer.

The parser shall not:

- obtain current time;
- compare timestamps;
- perform timezone conversion;
- compensate for clock adjustments;
- calculate elapsed duration.

---

# 17. Lower Subsequent Values

A lower value is valid.

Conceptually:

```text
collection N:

45

collection N+1:

8
```

does not represent parser failure.

The oldest previous wait may have completed, leaving a younger active wait.

The parser therefore shall not enforce monotonicity.

---

# 18. Output Contract

For successful input:

```text
stdout = normalized non-negative integer
stderr = empty
return code = 0
```

Example:

Input:

```text
45
```

Output:

```text
45
```

Return code:

```text
0
```

---

# 19. Failure Output Contract

On validation or collection failure:

```text
stdout = empty
stderr = diagnostic message
return code != 0
```

No fallback duration shall be emitted.

---

# 20. Parser Responsibilities

The parser shall:

1. validate invocation;
2. validate input readability;
3. detect explicit collection execution failure;
4. require a scalar result;
5. trim permitted surrounding whitespace;
6. validate exactly one value;
7. validate a non-negative integer;
8. preserve zero;
9. accept lower values without historical comparison;
10. emit the normalized integer only after successful validation.

---

# 21. Parser Non-Responsibilities

The parser shall not:

- query Informix;
- execute the final SQL or command;
- identify active lock waits;
- identify blocked sessions or threads;
- obtain wait-start timestamps;
- calculate elapsed time;
- compare clocks;
- inspect multiple wait records;
- calculate the maximum;
- maintain previous values;
- enforce monotonicity;
- derive a historical maximum;
- correlate with `IFX-LOCK-001`;
- generate alerts;
- convert collection failure into zero.

---

# 22. Processing Order

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
emit normalized seconds
```

---

# 23. Mock Dataset

Mock directory:

`04-mocks/informix-locks/IFX-LOCK-002/`

Cases:

| Mock | Expected Result |
|---|---|
| `normal.txt` | success — `45` |
| `zero.txt` | success — `0` |
| `single-second.txt` | success — `1` |
| `long.txt` | success — `3600` |
| `lower.txt` | success — `8` |
| `empty.txt` | failure |
| `nonnumeric.txt` | failure |
| `negative.txt` | failure |
| `decimal.txt` | failure |
| `execution-error.txt` | failure |

---

# 24. Mock Acceptance Criteria

Mock validation passes only when all 10 scenarios behave exactly as defined.

Expected results:

```text
normal           -> rc=0, stdout=45
zero             -> rc=0, stdout=0
single-second    -> rc=0, stdout=1
long             -> rc=0, stdout=3600
lower            -> rc=0, stdout=8

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

# 25. Source Validation Requirements

Before operational collection, real Informix validation must establish:

- authoritative current lock-wait source;
- authoritative timing representation;
- active-wait semantics;
- duration or wait-start semantics;
- timing precision;
- clock semantics when timestamp arithmetic is required;
- aggregation rules;
- empty-population behavior;
- exact SQL or command;
- required permissions;
- collection cost;
- scalability;
- relevant Informix-version behavior.

---

# 26. Relationship with IFX-LOCK-001

Related metric:

`IFX-LOCK-001 — Sessions Waiting for Locks`

Conceptually:

```text
LOCK-001 = quantity
LOCK-002 = oldest current duration
```

No cross-metric invariant is enforced by the parser.

Relationship status:

`UNPROVEN`

---

# 27. Relationship with IFX-SESSION-005

Related metric:

`IFX-SESSION-005 — Waiting Threads by Reason`

Lock-related wait dimensions may correlate with the maximum lock-wait duration.

The parser shall not assume an arithmetic or identity relationship.

Relationship status:

`UNPROVEN`

---

# 28. Lifecycle Advancement

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

# 29. Current Status

Specification:

`APPROVED`

Architectural metric:

`Maximum Lock Wait Time`

Current semantic:

`PROVISIONAL — AGE IN SECONDS OF THE OLDEST CURRENTLY ACTIVE LOCK WAIT`

Metric semantics:

`GAUGE`

Historical maximum:

`NO`

Monotonic:

`NO`

Normalized unit:

`SECONDS`

Normalized precision:

`WHOLE SECONDS — PROVISIONAL`

Cardinality:

`ONE VALUE PER INFORMIX INSTANCE`

Candidate source:

`sysmaster`

Alternative supporting interface:

`onstat`

Authoritative timing representation:

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

# 30. Next Step

Validate the metric and parser contract against the real Informix/AIX environment when it becomes available.

Source validation must confirm the authoritative current lock-wait source, timing representation, elapsed-time semantics, precision, aggregation rules and compatibility with the normalized whole-seconds scalar contract.

Until then:

`IFX-LOCK-002 = MOCK_VALIDATED`

---