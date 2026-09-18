# IFX-HEALTH-005 — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-HEALTH-005 — Checkpoint Duration`

The parser normalizes the result obtained from the future approved Informix checkpoint source into a checkpoint duration suitable for monitoring.

This specification validates the mock normalized-result contract only.

It does not validate the actual `sysmaster` source, SQL statement, source unit or source precision.

---

# 2. Candidate Source

Current candidate source:

`sysmaster`

Exact SQL source:

`PENDING SOURCE VALIDATION`

The parser shall remain independent from the final SQL implementation wherever practical.

---

# 3. Intended Semantic

The intended metric semantic is:

`duration of the most recently completed checkpoint`

This semantic remains:

`PENDING SOURCE VALIDATION`

The parser shall not attempt to determine which checkpoint record is the most recent.

That responsibility belongs to the eventual approved source query.

---

# 4. Mock Normalized Unit

For the mock phase, input values are treated as:

`SECONDS`

This is a provisional normalized contract.

It does not establish that the real Informix source natively reports seconds.

---

# 5. Input Contract

For the mock phase, the parser receives one input file representing the successful scalar output of the future collection source.

Example:

```text id="l5o82m"
12
```

Normalized output:

```text id="z0l85u"
12
```

---

# 6. Execution Failure Contract

Source execution failure is different from malformed source output.

Conceptually:

```text id="qgy1mw"
source execution
      │
      ├── failure ──> COLLECTION_FAILURE
      │
      └── success
             │
             ▼
          parser
```

The mock:

`execution-error.txt`

represents a source-execution failure and shall produce collection failure.

---

# 7. Valid Value Domain

For the current mock contract, a valid checkpoint duration is:

`non-negative integer`

Accepted examples:

```text id="r6xclv"
0
1
12
3600
```

---

# 8. Invalid Value Domain

Invalid examples:

```text id="6zawj1"
-1
12.5
checkpoint_duration
abc
```

Empty input is also invalid.

---

# 9. Zero Semantics

Input:

```text id="jnyuv9"
0
```

shall produce:

```text id="qq0s9f"
0
```

with successful process exit.

During the mock phase, zero is considered a syntactically valid duration.

Whether zero has valid operational meaning in the real source remains subject to source validation.

---

# 10. Short Duration

Input:

```text id="k01dcm"
1
```

shall produce:

```text id="1b8ezr"
1
```

No artificial minimum checkpoint duration shall be introduced by the parser.

---

# 11. Long Duration

Input:

```text id="1h23gl"
3600
```

shall produce:

```text id="g60nqm"
3600
```

The parser shall not impose an arbitrary operational maximum.

Threshold interpretation belongs to the monitoring layer.

---

# 12. Fractional Duration

For the current mock contract:

```text id="xj7g0c"
12.5
```

shall produce:

`COLLECTION_FAILURE`

This rule is provisional.

It exists because the actual source precision has not yet been established.

If real source validation demonstrates meaningful fractional precision, this contract shall be revised before `SOURCE_VALIDATED`.

---

# 13. Negative Duration

Input:

```text id="bbdf4m"
-1
```

shall produce:

`COLLECTION_FAILURE`

Negative duration is outside the normalized metric contract.

---

# 14. Empty Input

An empty input shall produce:

`COLLECTION_FAILURE`

It shall never silently become:

```text id="1v3blj"
0
```

---

# 15. Non-Numeric Input

Input such as:

```text id="t58b8w"
checkpoint_duration
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not extract numeric fragments from arbitrary text.

---

# 16. Multiple Values

The parser expects exactly one scalar normalized value.

Input conceptually containing:

```text id="nd2m0c"
12
15
```

shall produce:

`COLLECTION_FAILURE`

The parser shall not select one value or calculate an aggregate.

Selection of the most recently completed checkpoint belongs to the source query.

---

# 17. Whitespace

Leading and trailing whitespace around the scalar may be ignored.

Example:

```text id="d71s8h"
   12
```

may normalize to:

```text id="3g6gbq"
12
```

Multiple non-empty values remain invalid.

---

# 18. Unit Conversion

The mock parser performs:

`NO UNIT CONVERSION`

Mock input is assumed to already represent normalized integer seconds.

Unit conversion shall only be implemented after the real source establishes:

- native unit;
- precision;
- conversion requirements.

---

# 19. Parser Responsibilities

The parser is responsible for:

1. receiving the source-result representation;
2. identifying explicit source-execution failure;
3. extracting the scalar result;
4. trimming permitted surrounding whitespace;
5. verifying exactly one value;
6. validating the current non-negative integer contract;
7. emitting the normalized value.

---

# 20. Parser Non-Responsibilities

The parser shall not:

- select the latest checkpoint from multiple records;
- calculate checkpoint frequency;
- calculate checkpoint averages;
- calculate checkpoint maximums;
- calculate checkpoint waits;
- detect Informix restart;
- determine alert severity;
- compare against historical values;
- convert collection failure into zero.

---

# 21. Processing Order

Conceptually:

```text id="02t5mt"
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
emit duration
```

---

# 22. Process Exit Contract

Successful parsing:

```text id="jsd01g"
stdout = normalized checkpoint duration
exit   = 0
```

Example:

```text id="04wn1u"
stdout = 12
exit   = 0
```

Collection/parsing failure:

```text id="xllhs9"
stdout = no metric value
exit   = non-zero
```

---

# 23. Mock Inputs

Current mock inputs:

```text id="j9c1kl"
normal.txt
zero.txt
short.txt
long.txt
empty.txt
non-numeric.txt
negative.txt
fractional.txt
execution-error.txt
```

Expected results:

| Mock | Expected |
|---|---:|
| `normal.txt` | `12` |
| `zero.txt` | `0` |
| `short.txt` | `1` |
| `long.txt` | `3600` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `fractional.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

---

# 24. Mock Acceptance Criteria

Mock validation passes only if:

1. normal duration returns `12`;
2. zero returns `0`;
3. short duration returns `1`;
4. long duration returns `3600`;
5. empty input fails;
6. non-numeric input fails;
7. negative input fails;
8. fractional input fails under the current provisional contract;
9. simulated source execution failure fails;
10. no collection failure becomes numeric zero.

---

# 25. Source Validation Impact

Real source validation may require changes to this parser contract.

Specifically, validation may establish:

- fractional duration support;
- a different normalized precision;
- native unit conversion;
- explicit handling of absence of completed checkpoints.

Such changes shall be documented before the metric progresses to `SOURCE_VALIDATED`.

---

# 26. Current Status

Specification:

`APPROVED`

Candidate source:

`sysmaster`

Intended semantic:

`MOST RECENTLY COMPLETED CHECKPOINT DURATION`

Mock normalized unit:

`SECONDS`

Exact SQL source:

`PENDING SOURCE VALIDATION`

Source unit/precision:

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

# 27. Next Step

After approval of this specification, implement the minimum KornShell parser for the existing `IFX-HEALTH-005` mock inputs.

The implementation shall preserve the provisional integer-seconds contract without asserting that the real Informix source uses the same representation.