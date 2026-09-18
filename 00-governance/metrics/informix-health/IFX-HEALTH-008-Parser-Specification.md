# IFX-HEALTH-008 — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-HEALTH-008 — Foreground Writes`

The parser normalizes the result obtained from the future approved Informix foreground-write source into a value suitable for monitoring.

This specification validates the provisional mock contract only.

It does not validate the actual `sysmaster` source, SQL statement, `onstat -F` representation or source scope.

---

# 2. Candidate Source

Primary candidate source:

`sysmaster`

Alternative validation source:

`onstat -F`

Exact authoritative source:

`PENDING SOURCE VALIDATION`

No specific source object or command-output field is authoritative at this stage.

---

# 3. Provisional Semantic

For the mock phase, the parser assumes:

`cumulative number of foreground writes`

This semantic must be confirmed or revised during real Informix source validation.

---

# 4. Source Scope

The mock parser assumes that its input already represents:

`one normalized instance-level scalar`

The parser does not aggregate per-buffer-pool values.

If the authoritative source exposes multiple buffer pools, aggregation or discovery must be designed explicitly before `SOURCE_VALIDATED`.

---

# 5. Metric Type

Under the provisional semantic:

`COUNTER`

The raw cumulative counter is preserved.

---

# 6. Mock Normalized Unit

Normalized mock unit:

`WRITES`

Example:

```text id="zuvjsl"
750
```

---

# 7. Input Contract

The parser receives one input file representing the normalized scalar source result.

Example input:

```text id="d5uwak"
750
```

Output:

```text id="ddn1ec"
750
```

---

# 8. Execution Failure Contract

Source execution failure is distinct from malformed source output.

The mock:

`execution-error.txt`

represents source execution failure.

It shall produce:

`COLLECTION_FAILURE`

and no numeric metric value.

---

# 9. Valid Value Domain

Valid values under the mock contract are:

`non-negative integers`

Examples:

```text id="r37yzs"
0
1
750
987654321
```

---

# 10. Zero Semantics

Input:

```text id="i0hqvl"
0
```

shall produce:

```text id="3i2rz7"
0
```

with successful process exit.

Collection failure shall never be converted into zero.

---

# 11. Small Counter

Input:

```text id="49qemf"
1
```

shall produce:

```text id="hv0qeq"
1
```

No artificial minimum is introduced.

---

# 12. Large Counter

Input:

```text id="j1fy8o"
987654321
```

shall be preserved without truncation or artificial thresholding.

---

# 13. Reset Sample

Input:

```text id="9lycfz"
15
```

is valid even if a previous observation was larger.

The parser does not compare historical samples.

Counter-reset interpretation belongs to the monitoring layer.

---

# 14. Empty Input

Empty input shall produce:

`COLLECTION_FAILURE`

It shall not become zero.

---

# 15. Non-Numeric Input

Input:

```text id="53n8hw"
foreground_writes
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not extract numeric fragments from arbitrary text.

---

# 16. Negative Input

Input:

```text id="wzrz3v"
-1
```

shall produce:

`COLLECTION_FAILURE`

Negative values are outside the counter contract.

---

# 17. Decimal Input

Input:

```text id="y0iz0s"
12.5
```

shall produce:

`COLLECTION_FAILURE`

The provisional metric represents a write count and therefore requires integer values.

---

# 18. Multiple Values

Exactly one normalized scalar is permitted.

Input such as:

```text id="80z41m"
100
200
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not:

- choose one row;
- sum rows;
- average rows;
- infer buffer-pool aggregation.

---

# 19. Whitespace

Leading and trailing whitespace around the scalar may be ignored.

Example:

```text id="74s24h"
   750
```

may normalize to:

```text id="o9f9p3"
750
```

Multiple non-empty values remain invalid.

---

# 20. Parser Responsibilities

The parser is responsible for:

1. receiving the normalized source-result representation;
2. detecting explicit source-execution failure;
3. extracting the scalar result;
4. trimming permitted surrounding whitespace;
5. verifying exactly one value;
6. validating the non-negative integer contract;
7. emitting the normalized foreground-write counter.

---

# 21. Parser Non-Responsibilities

The parser shall not:

- calculate write rate;
- calculate counter delta;
- compare historical samples;
- infer Informix restart;
- aggregate buffer pools;
- calculate foreground/LRU ratios;
- determine alert severity;
- convert collection failure into zero.

---

# 22. Processing Order

Conceptually:

```text id="vhffzk"
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
emit foreground write counter
```

---

# 23. Process Exit Contract

Successful parsing:

```text id="0rnvhj"
stdout = normalized foreground write counter
exit   = 0
```

Collection/parsing failure:

```text id="sgj2hj"
stdout = no metric value
exit   = non-zero
```

---

# 24. Mock Inputs

Current mock inputs:

```text id="k1h8hr"
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
| `normal.txt` | `750` |
| `zero.txt` | `0` |
| `small.txt` | `1` |
| `large.txt` | `987654321` |
| `reset.txt` | `15` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

---

# 25. Mock Acceptance Criteria

Mock validation passes only if:

1. normal counter returns `750`;
2. zero returns `0`;
3. small counter returns `1`;
4. large counter returns `987654321`;
5. reset sample returns `15`;
6. empty input fails;
7. non-numeric input fails;
8. negative input fails;
9. decimal input fails;
10. simulated source execution failure fails;
11. no collection failure becomes numeric zero.

---

# 26. Source Validation Impact

Real source validation must establish:

- authoritative source;
- cumulative semantics;
- exact foreground-write definition;
- source scope;
- instance-level versus buffer-pool representation;
- aggregation requirements;
- reset behavior;
- rollover behavior.

If multiple buffer pools must remain individually observable, the architecture shall be revised rather than silently aggregating them in this parser.

---

# 27. Current Status

Specification:

`APPROVED`

Primary candidate source:

`sysmaster`

Alternative validation source:

`onstat -F`

Current semantic:

`PROVISIONAL — CUMULATIVE FOREGROUND WRITE COUNT`

Metric semantics:

`COUNTER — PROVISIONAL`

Mock normalized unit:

`WRITES`

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

Metric lifecycle state:

`MOCK_VALIDATED`

Real environment validation:

`PENDING`

---

# 28. Next Step

Implement the minimum KornShell parser for the existing `IFX-HEALTH-008` mock inputs.

The implementation shall validate only the normalized scalar counter contract and shall not introduce source aggregation behavior.