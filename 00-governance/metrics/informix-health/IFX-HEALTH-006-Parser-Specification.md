# IFX-HEALTH-006 — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-HEALTH-006 — Checkpoint Waits`

The parser normalizes the result obtained from the future approved Informix checkpoint-wait source into a value suitable for monitoring.

This specification validates the provisional mock contract only.

It does not validate the actual `sysmaster` source, SQL statement or checkpoint-wait semantics.

---

# 2. Candidate Source

Current candidate source:

`sysmaster`

Exact SQL source:

`PENDING SOURCE VALIDATION`

No specific `sysmaster` table, view or column is authoritative at this stage.

---

# 3. Provisional Semantic

For the mock phase, the parser assumes:

`cumulative checkpoint-related wait count`

This semantic is provisional.

It must be confirmed or revised during real Informix source validation.

---

# 4. Metric Type

Under the provisional semantic:

`COUNTER`

The parser exposes the raw counter.

It does not calculate rate or delta.

---

# 5. Mock Normalized Unit

For the mock phase:

`WAITS`

Example:

```text id="43vyfh"
42
```

represents a cumulative checkpoint-related wait count of 42 under the provisional contract.

---

# 6. Input Contract

The parser receives one input file representing the scalar result of the future source query.

Example:

```text id="quy0q3"
42
```

Normalized output:

```text id="vblf6v"
42
```

---

# 7. Execution Failure Contract

Source execution failure is distinct from malformed output.

The mock:

`execution-error.txt`

represents a source-execution failure.

It shall produce:

`COLLECTION_FAILURE`

and shall not emit a numeric metric value.

---

# 8. Valid Value Domain

For the provisional mock contract, valid values are:

`non-negative integers`

Examples:

```text id="77ay55"
0
1
42
987654321
```

---

# 9. Zero Semantics

Input:

```text id="7vtmv4"
0
```

shall produce:

```text id="mlvbf7"
0
```

with successful process exit.

Collection failure must never be converted into zero.

---

# 10. Small Counter

Input:

```text id="52e2oh"
1
```

shall produce:

```text id="9w1mwl"
1
```

No artificial minimum shall be introduced.

---

# 11. Large Counter

Input:

```text id="9bg5ba"
987654321
```

shall be preserved:

```text id="39uj7w"
987654321
```

The parser shall not impose an arbitrary monitoring threshold or maximum.

---

# 12. Reset Sample

Input:

```text id="y4swz7"
7
```

is a valid sample even if a previous observation was larger.

The parser does not compare samples.

Counter reset interpretation belongs to the monitoring layer and may later be correlated with:

`IFX-HEALTH-002 — Instance Uptime`

---

# 13. Empty Input

Empty input shall produce:

`COLLECTION_FAILURE`

It shall not produce zero.

---

# 14. Non-Numeric Input

Input such as:

```text id="h3ggrz"
checkpoint_waits
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not extract numeric fragments from arbitrary text.

---

# 15. Negative Input

Input:

```text id="5dtuxp"
-1
```

shall produce:

`COLLECTION_FAILURE`

Negative values are outside the provisional counter contract.

---

# 16. Decimal Input

Input:

```text id="3h8r83"
12.5
```

shall produce:

`COLLECTION_FAILURE`

The provisional metric is an integer counter.

If the real source exposes time rather than count semantics, this specification must be revised rather than adapting the parser silently.

---

# 17. Multiple Values

Exactly one normalized scalar is permitted.

Example:

```text id="zhyueo"
12
15
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not:

- select one value;
- sum values;
- average values.

Aggregation belongs to the approved source query or a separately documented collection rule.

---

# 18. Whitespace

Leading and trailing whitespace around the scalar may be ignored.

Example:

```text id="2v3b28"
   42
```

may normalize to:

```text id="ad6pk9"
42
```

Multiple non-empty values remain invalid.

---

# 19. Parser Responsibilities

The parser is responsible for:

1. receiving the source-result representation;
2. detecting explicit source-execution failure;
3. extracting the scalar result;
4. trimming permitted surrounding whitespace;
5. verifying exactly one value;
6. validating the non-negative integer contract;
7. emitting the normalized value.

---

# 20. Parser Non-Responsibilities

The parser shall not:

- calculate counter delta;
- calculate waits per second;
- calculate waits per checkpoint;
- compare current and previous samples;
- infer Informix restart;
- aggregate multiple unresolved records;
- determine alert severity;
- convert collection failure into zero.

---

# 21. Processing Order

Conceptually:

```text id="ucvzi4"
input
  │
  ▼
source execution successful?
  │
  ├── NO ──> COLLECTION_FAILURE
  │
  ▼
scalar result present?
  │
  ├── NO ──> COLLECTION_FAILURE
  │
  ▼
exactly one value?
  │
  ├── NO ──> COLLECTION_FAILURE
  │
  ▼
valid non-negative integer?
  │
  ├── NO ──> COLLECTION_FAILURE
  │
  ▼
emit checkpoint wait counter
```

---

# 22. Process Exit Contract

Successful parsing:

```text id="nquqko"
stdout = normalized checkpoint wait value
exit   = 0
```

Collection/parsing failure:

```text id="jyz3m8"
stdout = no metric value
exit   = non-zero
```

---

# 23. Mock Inputs

Current mock inputs:

```text id="rjvukn"
normal.txt
zero.txt
small.txt
large.txt
reset.txt
empty.txt
non-numeric.txt
negative.txt
decimal.txt
execution-error.txt
```

Expected results:

| Mock | Expected |
|---|---:|
| `normal.txt` | `42` |
| `zero.txt` | `0` |
| `small.txt` | `1` |
| `large.txt` | `987654321` |
| `reset.txt` | `7` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

---

# 24. Mock Acceptance Criteria

Mock validation passes only if:

1. normal counter returns `42`;
2. zero returns `0`;
3. small counter returns `1`;
4. large counter returns `987654321`;
5. reset sample returns `7`;
6. empty input fails;
7. non-numeric input fails;
8. negative input fails;
9. decimal input fails;
10. simulated source execution failure fails;
11. no collection failure becomes numeric zero.

---

# 25. Source Validation Impact

Real source validation must establish whether this provisional counter model is correct.

If Informix exposes checkpoint waiting as:

- wait duration;
- per-checkpoint value;
- session count;
- current waiters;
- another semantic;

this specification shall be revised before the metric becomes:

`SOURCE_VALIDATED`

The parser shall not define source semantics by implementation accident.

---

# 26. Current Status

Specification:

`APPROVED`

Candidate source:

`sysmaster`

Current semantic:

`PROVISIONAL — CUMULATIVE CHECKPOINT-RELATED WAIT COUNT`

Metric semantics:

`COUNTER — PROVISIONAL`

Mock normalized unit:

`WAITS`

Exact SQL source:

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

# 27. Next Step

Implement the minimum KornShell parser for the existing `IFX-HEALTH-006` mock inputs.

The implementation shall validate only the provisional normalized counter contract and shall not introduce assumptions about the real Informix source.