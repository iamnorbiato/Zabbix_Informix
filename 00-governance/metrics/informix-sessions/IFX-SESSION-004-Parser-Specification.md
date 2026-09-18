# IFX-SESSION-004 — Waiting Threads Total — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-SESSION-004 — Waiting Threads Total`

The parser normalizes and validates an already classified and aggregated instance-level waiting-thread count.

It does not determine which Informix thread states qualify as waiting.

---

# 2. Architectural Metric

Metric:

`Waiting Threads Total`

The previous catalog concept:

`Generic Thread Waits`

is superseded by this current-state gauge contract.

---

# 3. Candidate Source

Candidate interfaces:

`sysmaster / onstat`

Exact authoritative source:

`PENDING SOURCE VALIDATION`

Exact SQL or command:

`PENDING SOURCE VALIDATION`

---

# 4. Provisional Semantic

The normalized value represents:

`CURRENT NUMBER OF INFORMIX THREADS CLASSIFIED AS WAITING BY THE AUTHORITATIVE SOURCE`

The exact waiting-state classification remains pending source validation.

---

# 5. Metric Type

Metric type:

`GAUGE`

The value represents current state.

It is not a cumulative wait-event counter.

---

# 6. Normalized Unit

Unit:

`THREADS`

---

# 7. Input Contract

The parser receives one input file containing one already normalized instance-level scalar.

Example:

```text id="62bxf1"
22
```

The collection layer owns any required thread filtering, classification and aggregation.

---

# 8. Source Execution Failure

A mock containing:

```text id="32t64d"
EXIT_CODE=1
STDOUT=
STDERR=SQL execution failed
```

represents collection failure.

Expected result:

`COLLECTION_FAILURE`

No numeric value shall be emitted.

---

# 9. Valid Value Domain

Valid values are non-negative integers.

Examples:

```text id="nq3lj8"
0
1
8
22
750
```

---

# 10. Invalid Values

The following are invalid:

- empty input;
- non-numeric input;
- negative integer;
- decimal value;
- multiple scalar values;
- explicit source execution failure.

---

# 11. Zero Semantics

Zero is valid.

Input:

```text id="ngywnb"
0
```

Expected output:

```text id="wxnf87"
0
```

It means that no threads were classified as waiting at the collection instant.

Collection failure shall not become zero.

---

# 12. Whitespace

Leading and trailing whitespace around the scalar may be removed.

Whitespace normalization shall not alter the numeric value.

---

# 13. Gauge Behavior

Each observation is independently valid.

The value may increase or decrease:

```text id="h8y1h8"
22
31
8
0
17
```

The parser shall maintain no historical state.

---

# 14. Output Cardinality

Exactly one normalized scalar is permitted.

Multiple values shall result in collection/parsing failure.

---

# 15. Classification Boundary

The parser shall not receive arbitrary thread rows and determine which are waiting.

Classification belongs to the validated collection layer.

Conceptually:

```text id="d2nyk5"
Informix authoritative thread state
              ↓
classification/filtering
              ↓
instance-level aggregation
              ↓
scalar parser
              ↓
22
```

---

# 16. Relationship with IFX-SESSION-005

Dynamic wait-reason metrics belong to:

`IFX-SESSION-005 — Waiting Threads by Reason`

This parser shall not:

- discover wait reasons;
- classify reasons;
- generate reason identifiers;
- produce LLD data;
- sum reason metrics.

---

# 17. No Silent Sum Rule

The parser shall not calculate:

```text id="91s0hx"
Waiting Threads Total =
SUM(Waiting Threads by Reason)
```

That relationship may only be established after real source validation proves that the wait-reason dimensions are complete, mutually exclusive and equivalent in scope.

---

# 18. Session Relationships

The parser shall not enforce relationships with:

`IFX-SESSION-001 — Total Connected Sessions`

or:

`IFX-SESSION-002 — Active Sessions`

Threads and sessions shall not be assumed to have a one-to-one relationship.

---

# 19. Parser Responsibilities

The parser shall:

1. validate invocation;
2. validate input readability;
3. detect explicit source execution failure;
4. extract non-empty normalized content;
5. trim surrounding whitespace;
6. require exactly one scalar;
7. validate a non-negative integer;
8. emit the value unchanged.

---

# 20. Parser Non-Responsibilities

The parser shall not:

- identify the final Informix source;
- execute final SQL or command;
- define waiting-state semantics;
- inspect individual thread records;
- classify thread states;
- classify wait reasons;
- count arbitrary input rows;
- perform LLD;
- derive `IFX-SESSION-005`;
- sum `IFX-SESSION-005`;
- compare with session metrics;
- maintain history;
- generate alerts;
- convert failure into zero.

---

# 21. Processing Order

The parser shall process input in this order:

```text id="ouyb4j"
validate invocation
        ↓
validate input readability
        ↓
detect explicit execution failure
        ↓
extract normalized non-empty content
        ↓
trim surrounding whitespace
        ↓
require exactly one scalar
        ↓
validate non-negative integer
        ↓
emit value
```

---

# 22. Successful Exit Contract

On success:

```text id="2m10cw"
stdout = normalized scalar
stderr = empty
return code = 0
```

Example:

```text id="7dsvk3"
22
```

---

# 23. Failure Exit Contract

On failure:

```text id="kg3x3w"
stdout = empty
stderr = diagnostic message
return code != 0
```

The diagnostic message is not part of the metric value.

---

# 24. Mock Dataset

Mock directory:

`04-mocks/informix-sessions/IFX-SESSION-004/`

Expected cases:

| Mock | Expected Result |
|---|---|
| `normal.txt` | `22` |
| `zero.txt` | `0` |
| `single.txt` | `1` |
| `high.txt` | `750` |
| `lower.txt` | `8` |
| `empty.txt` | failure |
| `non-numeric.txt` | failure |
| `negative.txt` | failure |
| `decimal.txt` | failure |
| `execution-error.txt` | failure |

---

# 25. Mock Acceptance Criteria

Mock validation passes only when:

- all five valid inputs return exactly the expected scalar;
- all five invalid/error inputs return non-zero;
- invalid/error inputs emit no metric value;
- zero remains valid.

Expected result:

```text id="p6hhtr"
PASS: 10
FAIL: 0
```

---

# 26. Source Validation Requirements

Before operational implementation, real Informix validation must establish:

- authoritative thread-state source;
- exact waiting-state semantics;
- exact `sysmaster` object or `onstat` representation;
- filtering rules;
- internal/system-thread handling;
- session/thread relationship;
- aggregation rules;
- exact SQL or command;
- required permissions;
- collection cost;
- relevant Informix version differences.

---

# 27. Relationship Validation with SESSION-005

Real validation shall additionally establish whether:

```text id="21pdcz"
SESSION-004 =
SUM(all SESSION-005 reason dimensions)
```

is semantically valid.

This relationship shall remain:

`UNPROVEN`

until source validation confirms completeness and mutual exclusivity of wait reasons.

---

# 28. Lifecycle Advancement

Successful mock validation permits:

```text id="xovpyq"
DEFINED
   ↓
MOCK_VALIDATED
```

It does not permit:

`SOURCE_VALIDATED`

Real Informix/AIX validation remains mandatory.

---

# 29. Current Status

Specification:

`APPROVED`

Architectural metric:

`Waiting Threads Total`

Previous catalog concept:

`Generic Thread Waits`

Candidate interfaces:

`sysmaster / onstat`

Current semantic:

`PROVISIONAL — CURRENT NUMBER OF INFORMIX THREADS CLASSIFIED AS WAITING`

Metric semantics:

`GAUGE`

Normalized unit:

`THREADS`

Waiting-state definition:

`PENDING SOURCE VALIDATION`

Exact source:

`PENDING SOURCE VALIDATION`

Exact SQL/command:

`PENDING SOURCE VALIDATION`

Relationship with SESSION-005 sum:

`UNPROVEN`

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

Implement the minimum KornShell scalar parser for the existing `IFX-SESSION-004` mock dataset.

Dynamic wait-reason discovery remains outside this parser and belongs to `IFX-SESSION-005`.
