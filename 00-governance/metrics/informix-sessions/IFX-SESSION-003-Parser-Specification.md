# IFX-SESSION-003 — Historical Session Peak — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-SESSION-003 — Historical Session Peak`

The parser normalizes and validates an already collected authoritative Informix historical session peak value.

It does not calculate the historical maximum.

---

# 2. Architectural Constraint

The input shall ultimately originate from:

`AUTHORITATIVE INFORMIX-MAINTAINED HISTORICAL MAXIMUM`

The parser shall not calculate a maximum from:

- `IFX-SESSION-001`;
- Zabbix history;
- repeated session samples;
- local collector state.

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

`MAXIMUM SIMULTANEOUS SESSION COUNT SINCE THE AUTHORITATIVE STARTUP/RESET BOUNDARY`

The exact Informix lifecycle/reset behavior remains pending source validation.

---

# 5. Metric Type

Metric type:

`GAUGE / HISTORICAL MAXIMUM`

The value represents a maximum state maintained by Informix.

It is not treated as a cumulative event counter.

---

# 6. Normalized Unit

Unit:

`SESSIONS`

---

# 7. Input Contract

The parser receives one input file.

For successful collection, the file shall contain one normalized scalar.

Example:

```text id="gj3zue"
375
```

---

# 8. Source Execution Failure

A mock containing:

```text id="d6aq9n"
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

```text id="gj0qz1"
0
1
12
375
5000
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

Zero is syntactically valid.

Input:

```text id="e9i67o"
0
```

Expected output:

```text id="rlfzlg"
0
```

Collection failure shall not become zero.

---

# 12. Whitespace

Leading and trailing whitespace around the scalar may be removed.

Whitespace normalization shall not alter the numeric meaning.

---

# 13. Historical Behavior

Within one authoritative lifecycle boundary, the metric is expected to remain unchanged or increase.

However, the parser shall not maintain previous state.

Therefore it shall not enforce monotonic behavior.

---

# 14. Post-Reset Lower Value

A lower value after an Informix startup or authoritative statistics reset is valid.

Example:

```text id="y8t8vl"
12
```

shall be accepted independently of any previously observed value.

The parser does not determine whether a reset occurred.

---

# 15. Cross-Metric Validation

The parser shall not enforce:

```text id="49ej5b"
Historical Session Peak >= Total Connected Sessions
```

or any relationship with:

`IFX-SESSION-002 — Active Sessions`

Cross-metric validation belongs to the monitoring layer.

---

# 16. Parser Responsibilities

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

# 17. Parser Non-Responsibilities

The parser shall not:

- identify the final Informix source;
- execute the final SQL or command;
- calculate a historical maximum;
- derive a maximum from Zabbix history;
- maintain state between executions;
- detect engine startup;
- detect statistics reset;
- enforce monotonic behavior;
- compare against current connected sessions;
- compare against active sessions;
- determine capacity headroom;
- generate alerts;
- convert failure into zero.

---

# 18. Processing Order

The parser shall process input in this order:

```text id="hd54gm"
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

# 19. Successful Exit Contract

On success:

```text id="ypg1ug"
stdout = normalized scalar
stderr = empty
return code = 0
```

Example:

```text id="sf6y2f"
375
```

---

# 20. Failure Exit Contract

On failure:

```text id="c6ohdd"
stdout = empty
stderr = diagnostic message
return code != 0
```

The diagnostic message is operational information and is not part of the metric value.

---

# 21. Mock Dataset

Mock directory:

`04-mocks/informix-sessions/IFX-SESSION-003/`

Expected cases:

| Mock | Expected Result |
|---|---|
| `normal.txt` | `375` |
| `zero.txt` | `0` |
| `single.txt` | `1` |
| `high.txt` | `5000` |
| `post-reset.txt` | `12` |
| `empty.txt` | failure |
| `non-numeric.txt` | failure |
| `negative.txt` | failure |
| `decimal.txt` | failure |
| `execution-error.txt` | failure |

---

# 22. Mock Acceptance Criteria

Mock validation passes only when:

- all five valid inputs return exactly the expected scalar;
- all five invalid/error inputs return non-zero;
- invalid/error inputs emit no metric value;
- zero remains a valid value;
- `post-reset.txt` is accepted without historical comparison.

Expected result:

```text id="dp6dkm"
PASS: 10
FAIL: 0
```

---

# 23. Source Validation Requirements

Before operational implementation, real Informix validation must establish:

- existence of the authoritative historical maximum;
- exact `sysmaster` object or `onstat` representation;
- exact session semantic;
- instance scope;
- lifecycle boundary;
- startup reset behavior;
- independent statistics reset behavior, if any;
- internal-session inclusion behavior;
- exact SQL or command;
- required permissions;
- collection cost;
- relevant Informix version differences.

---

# 24. Source Absence Rule

If real validation establishes that Informix does not provide an authoritative engine-maintained historical session maximum, this parser contract shall not automatically be repurposed for a Zabbix-derived maximum.

Instead:

`IFX-SESSION-003`

shall return to architectural review.

---

# 25. Lifecycle Advancement

Successful mock validation permits:

```text id="2qynlp"
DEFINED
   ↓
MOCK_VALIDATED
```

It does not permit:

```text id="b83t22"
SOURCE_VALIDATED
```

Real Informix/AIX validation remains mandatory.

---

# 26. Current Status

Specification:

`APPROVED`

Architectural source requirement:

`AUTHORITATIVE INFORMIX-MAINTAINED HISTORICAL MAXIMUM`

Candidate interfaces:

`sysmaster / onstat`

Current semantic:

`PROVISIONAL — MAXIMUM SIMULTANEOUS SESSION COUNT SINCE AUTHORITATIVE STARTUP/RESET BOUNDARY`

Metric semantics:

`GAUGE / HISTORICAL MAXIMUM`

Normalized unit:

`SESSIONS`

Lifecycle/reset behavior:

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

# 27. Next Step

Implement the minimum KornShell parser for the existing mock dataset.

The parser shall validate only the normalized scalar contract and shall contain no historical-state or maximum-calculation logic.
