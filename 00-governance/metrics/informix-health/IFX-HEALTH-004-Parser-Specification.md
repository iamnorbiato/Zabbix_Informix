# IFX-HEALTH-004 — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-HEALTH-004 — Checkpoint Count`

The parser normalizes the result obtained from the future approved Informix checkpoint source into a non-negative integer suitable for Zabbix collection.

This specification validates the normalized result contract only.

It does not validate the actual `sysmaster` source, table, column or SQL statement.

---

# 2. Candidate Source

Current candidate source:

`sysmaster`

Exact SQL source:

`PENDING SOURCE VALIDATION`

The parser shall remain independent from the final SQL implementation wherever practical.

---

# 3. Input Contract

For the mock phase, the parser receives one input file representing the successful scalar output of the future SQL collection operation.

Example:

```text id="j4g0c3"
12345
```

Normalized output:

```text id="ny8sy8"
12345
```

---

# 4. Execution Failure Contract

SQL execution failure is different from malformed SQL output.

Conceptually:

```text id="3c2m0p"
SQL execution
     │
     ├── failure ──> COLLECTION_FAILURE
     │
     └── success
            │
            ▼
         parser
```

The mock file:

`execution-error.txt`

represents an execution failure scenario.

It is not valid scalar SQL output and shall result in collection failure.

---

# 5. Valid Value Domain

A valid checkpoint count is:

`non-negative integer`

Accepted examples:

```text id="yzk24x"
0
1
17
12345
987654321
```

---

# 6. Invalid Value Domain

Invalid examples include:

```text id="w3a93n"
-1
12.5
checkpoint_count
abc
```

Empty input is also invalid.

---

# 7. Zero Semantics

Input:

```text id="s9b8bn"
0
```

shall produce:

```text id="ve9gbg"
0
```

with successful process exit.

Zero is a legitimate metric value.

It shall not be confused with collection failure.

---

# 8. Counter Reset Semantics

The parser receives one sample at a time.

It shall not compare the current sample against previous samples.

Therefore:

```text id="a8rbmz"
17
```

is valid regardless of whether a previous monitoring sample was:

```text id="if9llh"
12000
```

Counter decrease/reset interpretation belongs to the monitoring layer and may later be correlated with:

`IFX-HEALTH-002 — Instance Uptime`

---

# 9. Large Values

The parser shall preserve valid large non-negative integer values without applying:

- rate calculation;
- unit conversion;
- truncation;
- scaling.

Example:

```text id="xdmqz8"
987654321
```

must remain:

```text id="mrx7ss"
987654321
```

The practical upper bound of the real Informix source remains subject to source validation.

---

# 10. Whitespace

Leading and trailing whitespace surrounding the scalar value may be ignored.

Conceptually:

```text id="w2knmq"
   12345
```

may normalize to:

```text id="c5hfc1"
12345
```

Whitespace must not make otherwise invalid embedded content valid.

---

# 11. Empty Input

An empty input file shall produce:

`COLLECTION_FAILURE`

It shall not produce:

```text id="k0k5g4"
0
```

---

# 12. Non-Numeric Input

Input:

```text id="0xy2qg"
checkpoint_count
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not attempt to extract digits from arbitrary text.

---

# 13. Negative Input

Input:

```text id="u9z67k"
-1
```

shall produce:

`COLLECTION_FAILURE`

Negative checkpoint counts are outside the normalized metric contract.

---

# 14. Decimal Input

Input:

```text id="37sxmo"
12.5
```

shall produce:

`COLLECTION_FAILURE`

The metric contract requires an integer.

---

# 15. Multiple Values

The normalized contract expects exactly one scalar value.

Input conceptually containing:

```text id="rlk0dh"
123
124
```

shall not be interpreted as:

```text id="8ltlhk"
123
```

or:

```text id="jsv9bz"
247
```

Unless the future SQL contract explicitly defines otherwise, multiple non-empty result values shall produce:

`COLLECTION_FAILURE`

---

# 16. Parser Responsibilities

The parser is responsible for:

1. receiving the source-result representation;
2. determining whether the input represents collection failure;
3. extracting the scalar result;
4. removing permitted surrounding whitespace;
5. validating that exactly one value exists;
6. validating that the value is a non-negative integer;
7. emitting the normalized value.

---

# 17. Parser Non-Responsibilities

The parser shall not:

- calculate checkpoint rate;
- calculate deltas;
- detect Informix restart;
- compare previous samples;
- calculate checkpoint duration;
- calculate checkpoint waits;
- diagnose checkpoint behavior;
- query Zabbix history;
- convert collection failure into zero.

---

# 18. Processing Order

Conceptually:

```text id="fwp9zw"
input
  │
  ▼
collection successful?
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
non-negative integer?
  │
  ├── NO ──> COLLECTION_FAILURE
  │
  ▼
emit normalized value
```

---

# 19. Process Exit Contract

Successful parsing:

```text id="n75ln9"
stdout = normalized checkpoint count
exit   = 0
```

Example:

```text id="nx9xxs"
stdout = 12345
exit   = 0
```

Collection/parsing failure:

```text id="gvpdyf"
stdout = no metric value
exit   = non-zero
```

---

# 20. Mock Inputs

Current mock inputs:

```text id="vhvyz6"
normal.txt
zero.txt
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
| `normal.txt` | `12345` |
| `zero.txt` | `0` |
| `large.txt` | `987654321` |
| `reset.txt` | `17` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

---

# 21. Mock Acceptance Criteria

Mock validation passes only if:

1. normal counter returns `12345`;
2. zero returns `0`;
3. large counter returns unchanged;
4. reset sample returns `17`;
5. empty input fails;
6. non-numeric input fails;
7. negative input fails;
8. decimal input fails;
9. simulated execution failure fails;
10. no failure scenario returns numeric zero.

---

# 22. Source Independence

Passing these mock tests shall establish only that the normalized scalar parser behaves according to specification.

It shall not establish that:

- the selected `sysmaster` source exists;
- the source contains the intended semantic value;
- the source counter is cumulative;
- the SQL statement is correct;
- the query cost is acceptable.

Those questions belong to real source validation.

---

# 23. Current Status

Specification:

`APPROVED`

Candidate source:

`sysmaster`

Exact SQL source:

`PENDING SOURCE VALIDATION`

Mock inputs:

`AVAILABLE`

Parser implementation:

`IMPLEMENTED`

Mock validation:

`PASSED — 9/9`

Metric lifecycle state:

`MOCK_VALIDATED`

Real environment validation:

`PENDING`

---

# 24. Next Step

After approval of this specification, implement the minimum KornShell parser for the existing `IFX-HEALTH-004` mock inputs.

No real `sysmaster` SQL statement shall be introduced as authoritative during this step.