# IFX-SESSION-001 — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-SESSION-001 — Total Connected Sessions`

The parser normalizes an already aggregated session-count source result into a value suitable for monitoring.

This specification validates the provisional mock contract only.

It does not validate the actual `sysmaster` source, SQL statement or session inclusion rules.

---

# 2. Candidate Source

Primary candidate source:

`sysmaster`

Exact authoritative source:

`PENDING SOURCE VALIDATION`

Exact SQL:

`PENDING SOURCE VALIDATION`

---

# 3. Provisional Semantic

For the mock phase, the parser assumes:

`current number of connected sessions represented by an already normalized source result`

The definition of which Informix sessions belong in this count remains pending source validation.

---

# 4. Source Scope

The parser expects:

`one normalized instance-level scalar`

Any filtering and aggregation of `sysmaster` rows belongs to the future authoritative source query.

The parser does not count or classify sessions.

---

# 5. Metric Type

Type:

`GAUGE`

Each successful sample represents the current observed connected-session count.

---

# 6. Normalized Unit

Normalized unit:

`SESSIONS`

Example:

```text id="vq6t8e"
42
```

---

# 7. Input Contract

The parser receives one input file containing the normalized scalar source result.

Example:

```text id="u8pywv"
42
```

Expected output:

```text id="p6f9wd"
42
```

---

# 8. Execution Failure Contract

The mock representation:

`execution-error.txt`

represents source execution failure.

It shall produce:

`COLLECTION_FAILURE`

and no numeric metric value.

---

# 9. Valid Value Domain

Valid values are:

`non-negative integers`

Examples:

```text id="t4xv7n"
0
1
42
5000
```

---

# 10. Zero Semantics

Input:

```text id="c08myn"
0
```

shall successfully produce:

```text id="97d9za"
0
```

Collection failure shall never be converted into zero.

---

# 11. Gauge Behavior

Samples may increase or decrease freely.

For example:

```text id="rz6l3c"
42
57
17
```

are all valid independent observations.

The parser does not implement reset detection because this metric is not a counter.

---

# 12. Empty Input

Empty input shall produce:

`COLLECTION_FAILURE`

---

# 13. Non-Numeric Input

Input:

```text id="1rrslw"
sessions
```

shall produce:

`COLLECTION_FAILURE`

---

# 14. Negative Input

Input:

```text id="pj5rlj"
-1
```

shall produce:

`COLLECTION_FAILURE`

---

# 15. Decimal Input

Input:

```text id="o23awh"
12.5
```

shall produce:

`COLLECTION_FAILURE`

Session count must be an integer.

---

# 16. Multiple Values

Exactly one normalized scalar is permitted.

Example invalid input:

```text id="f88ekg"
20
22
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not sum or otherwise aggregate multiple values.

---

# 17. Whitespace

Leading and trailing whitespace may be ignored.

Example:

```text id="xshj2p"
   42
```

may normalize to:

```text id="cbz1yx"
42
```

---

# 18. Parser Responsibilities

The parser shall:

1. receive the normalized source-result representation;
2. detect explicit source execution failure;
3. extract the scalar result;
4. trim permitted surrounding whitespace;
5. require exactly one value;
6. validate the non-negative integer contract;
7. emit the normalized session count.

---

# 19. Parser Non-Responsibilities

The parser shall not:

- execute the final SQL;
- determine which Informix sessions count;
- classify sessions;
- filter internal sessions;
- count source rows;
- calculate historical peaks;
- determine alert thresholds;
- convert collection failure into zero.

---

# 20. Processing Order

```text id="vh7tpp"
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
emit connected session count
```

---

# 21. Process Exit Contract

Successful parsing:

```text id="sn69w1"
stdout = normalized connected session count
exit   = 0
```

Failure:

```text id="g9s2mj"
stdout = no metric value
exit   = non-zero
```

---

# 22. Mock Inputs

Current mocks:

```text id="vpwsq7"
normal.txt
zero.txt
single.txt
high.txt
lower.txt
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
| `single.txt` | `1` |
| `high.txt` | `5000` |
| `lower.txt` | `17` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

---

# 23. Mock Acceptance Criteria

Mock validation passes only if all five valid inputs return their exact expected values and all five invalid/error inputs fail without producing a metric value.

Collection failure must never become numeric zero.

---

# 24. Source Validation Impact

Real source validation must establish:

- authoritative `sysmaster` object;
- exact SQL;
- definition of connected session;
- inclusion/exclusion rules;
- treatment of internal sessions;
- required permissions;
- query cost;
- relevant Informix version differences.

Changes required by authoritative source semantics shall revise the source/query contract rather than being hidden inside this parser.

---

# 25. Current Status

Specification:

`APPROVED`

Primary candidate source:

`sysmaster`

Current semantic:

`PROVISIONAL — CURRENT CONNECTED SESSION COUNT`

Metric semantics:

`GAUGE`

Normalized unit:

`SESSIONS`

Session inclusion rules:

`PENDING SOURCE VALIDATION`

Exact SQL:

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

# 26. Next Step

Implement the minimum KornShell parser for the existing `IFX-SESSION-001` mock inputs.

The implementation shall validate only the normalized scalar session-count contract.
