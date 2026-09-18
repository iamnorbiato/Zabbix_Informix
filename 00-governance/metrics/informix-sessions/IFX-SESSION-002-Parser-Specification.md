# IFX-SESSION-002 — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-SESSION-002 — Active Sessions`

The parser normalizes an already classified and aggregated active-session count into a value suitable for monitoring.

This specification validates the provisional mock contract only.

It does not define what constitutes an active Informix session.

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

`current number of sessions classified as active by an already normalized source result`

The classification of active sessions remains outside the parser contract.

---

# 4. Source Scope

Expected input:

`one normalized instance-level scalar`

Session classification, filtering, session/thread correlation and aggregation belong to the future authoritative source query or collector.

---

# 5. Metric Type

Type:

`GAUGE`

Each successful observation represents the current active-session count.

---

# 6. Normalized Unit

Normalized unit:

`SESSIONS`

Example:

```text id="s8ny4n"
18
```

---

# 7. Input Contract

The parser receives one file containing the normalized scalar source result.

Example:

```text id="y04pnq"
18
```

Expected output:

```text id="04qtbf"
18
```

---

# 8. Execution Failure Contract

The mock:

`execution-error.txt`

represents source execution failure.

It shall produce:

`COLLECTION_FAILURE`

with no numeric metric value.

---

# 9. Valid Value Domain

Valid values are non-negative integers.

Examples:

```text id="n2e33w"
0
1
18
750
```

---

# 10. Zero Semantics

Input:

```text id="5z6kfn"
0
```

shall successfully produce:

```text id="6rlzk4"
0
```

Collection failure shall never be converted into zero.

---

# 11. Gauge Behavior

Observations may increase or decrease.

Example:

```text id="2h8ag5"
18
27
6
```

All are valid independent observations.

No reset semantics apply.

---

# 12. Empty Input

Empty input shall produce:

`COLLECTION_FAILURE`

---

# 13. Non-Numeric Input

Input:

```text id="r4uv81"
active
```

shall produce:

`COLLECTION_FAILURE`

---

# 14. Negative Input

Input:

```text id="l2k19d"
-1
```

shall produce:

`COLLECTION_FAILURE`

---

# 15. Decimal Input

Input:

```text id="1vjwwh"
4.5
```

shall produce:

`COLLECTION_FAILURE`

Session count must be an integer.

---

# 16. Multiple Values

Exactly one scalar is permitted.

Example:

```text id="nh3k3c"
10
8
```

shall produce:

`COLLECTION_FAILURE`

No aggregation shall be performed by the parser.

---

# 17. Whitespace

Leading and trailing whitespace may be ignored.

Example:

```text id="o2jyj2"
   18
```

may normalize to:

```text id="w81twc"
18
```

---

# 18. Cross-Metric Validation

The parser shall not compare its value with:

`IFX-SESSION-001 — Total Connected Sessions`

In particular, it shall not enforce:

```text id="xgzkou"
active <= connected
```

Cross-metric relationships belong to later monitoring and correlation logic.

---

# 19. Parser Responsibilities

The parser shall:

1. detect explicit source execution failure;
2. obtain the normalized scalar;
3. trim permitted surrounding whitespace;
4. require exactly one value;
5. validate a non-negative integer;
6. emit the normalized active-session count.

---

# 20. Parser Non-Responsibilities

The parser shall not:

- execute final SQL;
- define active-session semantics;
- inspect thread states;
- classify sessions;
- filter internal sessions;
- aggregate source rows;
- compare active and connected counts;
- calculate historical values;
- determine alert severity;
- convert collection failure into zero.

---

# 21. Processing Order

```text id="0stq6a"
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
emit active session count
```

---

# 22. Process Exit Contract

Successful parsing:

```text id="uob6b4"
stdout = normalized active session count
exit   = 0
```

Failure:

```text id="62jhrz"
stdout = no metric value
exit   = non-zero
```

---

# 23. Mock Inputs

Current mocks:

```text id="gqzw2l"
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

---

# 24. Mock Acceptance Criteria

Mock validation passes only if:

- all five valid inputs return their exact expected values;
- all five invalid/error inputs fail;
- failures emit no metric value;
- collection failure never becomes numeric zero.

---

# 25. Source Validation Impact

Real source validation must establish:

- authoritative definition of active session;
- authoritative `sysmaster` source;
- session/thread relationship;
- waiting-session semantics;
- idle-session semantics;
- internal-session treatment;
- duplicate prevention;
- exact SQL;
- permissions;
- collection cost;
- relevant Informix version differences.

These semantics shall not be hidden inside the normalization parser.

---

# 26. Current Status

Specification:

`APPROVED`

Primary candidate source:

`sysmaster`

Current semantic:

`PROVISIONAL — CURRENT ACTIVE SESSION COUNT`

Metric semantics:

`GAUGE`

Normalized unit:

`SESSIONS`

Active-session definition:

`PENDING SOURCE VALIDATION`

Session/thread relationship:

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

# 27. Next Step

Implement the minimum KornShell parser for the existing `IFX-SESSION-002` mock inputs.

The implementation shall validate only the normalized scalar active-session gauge contract.
