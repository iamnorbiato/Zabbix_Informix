# IFX-HEALTH-007 — Parser Specification

## Current Operational Status

`DEVELOPMENT_RUNTIME_VALIDATED`

The historical mock parser was replaced by a remote SQL collector.

The current operational collector is:

`05-collectors/informix/health/ifx-health-lru-writes.ksh`

It executes the approved statement against `sysmaster`, requires exactly one scalar `UNLOAD` result terminated by `|`, removes the terminal delimiter and accepts only a non-negative integer.

## 1. Purpose

This document defines the current normalized-output contract for:

`IFX-HEALTH-007 — LRU Writes`

The collector exposes the cumulative Informix LRU-write counter as a non-negative integer suitable for Zabbix active collection.

The remaining mock-parser sections are preserved as historical validation evidence. They do not describe the current operational collection path.

---

# 2. Validated Source

Database:

`sysmaster`

Table:

`sysprofile`

Row selector:

`name = 'lruwrites'`

Approved SQL statement:

```sql
SELECT
    CAST(value AS INT8) AS lru_write_count
FROM sysprofile
WHERE name = 'lruwrites';
```

---

# 3. Validated Semantic

The metric represents the cumulative count of least-recently-used buffer writes performed by Informix.

A decrease is a valid numeric sample and can indicate an Informix restart or source reset. It must be interpreted with:

`IFX-HEALTH-002 — Instance Uptime`

---

# 4. Normalized Unit

`WRITES`

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

```text id="ekotnw"
125000
```

---

# 7. Input Contract

The parser receives one input file representing the normalized scalar source result.

Example input:

```text id="t7flnp"
125000
```

Output:

```text id="3glfkb"
125000
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

```text id="bznqu7"
0
1
125000
987654321
```

---

# 10. Zero Semantics

Input:

```text id="pkksjn"
0
```

shall produce:

```text id="2i9b46"
0
```

with successful process exit.

Collection failure shall never be converted into zero.

---

# 11. Small Counter

Input:

```text id="8fgzmx"
1
```

shall produce:

```text id="y3lgfz"
1
```

No artificial minimum is introduced.

---

# 12. Large Counter

Input:

```text id="axn1vw"
987654321
```

shall be preserved without truncation or artificial thresholding.

---

# 13. Reset Sample

Input:

```text id="2isqkk"
120
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

```text id="pvq6lr"
lru_writes
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not extract numeric fragments from arbitrary text.

---

# 16. Negative Input

Input:

```text id="9a9fcw"
-1
```

shall produce:

`COLLECTION_FAILURE`

Negative values are outside the counter contract.

---

# 17. Decimal Input

Input:

```text id="6a4k0g"
12.5
```

shall produce:

`COLLECTION_FAILURE`

The provisional metric represents a write count and therefore requires integer values.

---

# 18. Multiple Values

Exactly one normalized scalar is permitted.

Input such as:

```text id="ij83cd"
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

```text id="u5d9ln"
   125000
```

may normalize to:

```text id="pyqgsf"
125000
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
7. emitting the normalized LRU-write counter.

---

# 21. Parser Non-Responsibilities

The parser shall not:

- calculate write rate;
- calculate counter delta;
- compare historical samples;
- infer Informix restart;
- aggregate buffer pools;
- calculate LRU/foreground ratios;
- determine alert severity;
- convert collection failure into zero.

---

# 22. Processing Order

Conceptually:

```text id="5c68fz"
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
emit LRU write counter
```

---

# 23. Process Exit Contract

Successful parsing:

```text id="qtr7l2"
stdout = normalized LRU write counter
exit   = 0
```

Collection/parsing failure:

```text id="oh94l5"
stdout = no metric value
exit   = non-zero
```

---

# 24. Mock Inputs

Current mock inputs:

```text id="0swh6f"
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
| `normal.txt` | `125000` |
| `zero.txt` | `0` |
| `small.txt` | `1` |
| `large.txt` | `987654321` |
| `reset.txt` | `120` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

---

# 25. Mock Acceptance Criteria

Mock validation passes only if:

1. normal counter returns `125000`;
2. zero returns `0`;
3. small counter returns `1`;
4. large counter returns `987654321`;
5. reset sample returns `120`;
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

Validated source:

`sysmaster:sysprofile.lruwrites`

Current semantic:

`CUMULATIVE LRU WRITE COUNT`

Metric semantics:

`COUNTER`

Normalized unit:

`WRITES`

SQL statement:

`01-statements/informix-health/IFX-HEALTH-007-LRU-Writes.sql`

Collector implementation:

`05-collectors/informix/health/ifx-health-lru-writes.ksh`

Zabbix active-check key:

`ifx.health.lru_writes`

Metric lifecycle state:

`DEVELOPMENT_RUNTIME_VALIDATED`

Development runtime validation:

`PASSED`

Target Informix/AIX validation:

`PENDING`

---

# 28. Next Step

Use the collected counter for trends, rate derivation and correlation with foreground writes and checkpoint activity.

Do not create a direct threshold trigger from the raw counter alone.

Before production rollout, validate source compatibility, permissions and query cost on the target Informix/AIX environment.