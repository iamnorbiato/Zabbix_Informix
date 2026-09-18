# IFX-HEALTH-001 — Parser Specification

> Historical mock-parser specification.
>
> This document is retained for engineering traceability. It is superseded for operational implementation by `IFX-HEALTH-001-Instance-State.md`, which defines the remote SQL collector based on `sysmaster:sysshmhdr` and `name = 'mode'`.

## 1. Purpose

This document defines the expected parsing behavior for:

`IFX-HEALTH-001 — Instance State`

This historical parser transformed mocked Informix instance-state output into a provisional normalized monitoring value.

It is not used by the deployed collector.

Its purpose is to make parser behavior deterministic and testable.

---

# 2. Historical Mock Input Source

Historical mock candidate source:

```text
onstat -
```

The parser shall receive:

- command exit code;
- stdout;
- stderr.

The parser shall not evaluate stdout alone.

Command execution status is part of the collection result.

---

# 3. Output Model

A successful state collection shall return one of the following normalized values:

| Value | State |
|---:|---|
| 0 | Down |
| 1 | Shutdown |
| 2 | Recovery |
| 3 | Quiescent |
| 4 | Online |
| 99 | Unknown |

Collection failure is not a valid state value.

A collection failure shall be represented separately by the future collector execution mechanism.

---

# 4. Processing Order

The parser shall evaluate input in the following logical order:

```text
Command execution
      │
      ▼
Was execution successful?
      │
      ├── No ──> Collection Failure
      │
      ▼
     Yes
      │
      ▼
Is expected Informix header present?
      │
      ├── No ──> Evaluate known unavailable condition
      │              │
      │              ├── Proven Down ──> 0
      │              └── Otherwise ────> Collection Failure
      │
      ▼
Extract state
      │
      ▼
Normalize known state
      │
      ├── known ─────> normalized value
      │
      └── unknown ───> 99
```

---

# 5. Online State

Recognized conceptual source state:

```text
On-Line
```

Normalized result:

```text
4
```

Logical representation:

```text
Online
```

Mock:

```text
04-mocks/informix-health/IFX-HEALTH-001/online.txt
```

Expected result:

```text
PASS → 4
```

---

# 6. Quiescent State

Recognized conceptual source state:

```text
Quiescent
```

Normalized result:

```text
3
```

Logical representation:

```text
Quiescent
```

Mock:

```text
04-mocks/informix-health/IFX-HEALTH-001/quiescent.txt
```

Expected result:

```text
PASS → 3
```

---

# 7. Recovery State

Initial recognized conceptual source:

```text
Fast Recovery
```

Normalized result:

```text
2
```

Logical representation:

```text
Recovery
```

Mock:

```text
04-mocks/informix-health/IFX-HEALTH-001/recovery.txt
```

Expected result:

```text
PASS → 2
```

Additional recovery-state strings shall not be introduced until validated.

---

# 8. Shutdown State

Normalized result:

```text
1
```

Logical representation:

```text
Shutdown
```

No definitive parser rule is currently approved for Shutdown.

The actual Informix representation must be validated against a real environment before this state can be considered source-valid.

Current parser behavior:

```text
NO MATCH RULE
```

This state remains reserved in the normalized model.

---

# 9. Down State

Normalized result:

```text
0
```

Logical representation:

```text
Down
```

A Down result requires evidence that the Informix engine itself is unavailable.

The mock currently contains:

```text
onstat: cannot attach to shared memory
```

However, this string alone shall not yet be considered sufficient production evidence for state `Down`.

The same or similar error may potentially result from:

- incorrect Informix environment;
- incorrect `INFORMIXSERVER`;
- permissions;
- shared-memory access problems;
- engine being stopped.

Therefore the mock may be used for parser development, but the production rule remains provisional.

Current validation status:

```text
MOCK ONLY
```

---

# 10. Unknown State

If command execution succeeds and a valid Informix header is detected, but the state text is not recognized, the parser shall return:

```text
99
```

Example mock:

```text
Maintenance Mode
```

Expected result:

```text
99
```

The parser must not:

- guess the meaning;
- classify it as Online;
- classify it as Down;
- fail solely because the state is new.

This behavior protects compatibility with unexpected Informix states or future versions.

---

# 11. Malformed Output

Mock:

```text
04-mocks/informix-health/IFX-HEALTH-001/malformed.txt
```

Input:

```text
IBM Informix Dynamic Server
```

This does not provide enough information to determine engine state.

Expected result:

```text
COLLECTION_FAILURE
```

It must not result in:

```text
0
```

or:

```text
99
```

Reason:

The collector has not demonstrated that it obtained a valid state-bearing Informix response.

---

# 12. Command Execution Failure

Mock:

```text
04-mocks/informix-health/IFX-HEALTH-001/execution-error.txt
```

Representative condition:

```text
EXIT_CODE=127
STDERR=onstat: not found
```

Expected result:

```text
COLLECTION_FAILURE
```

It shall never result in:

```text
0
```

because inability to execute `onstat` does not prove that Informix is Down.

---

# 13. Case Sensitivity

The initial parser should not depend unnecessarily on capitalization.

For example:

```text
On-Line
ON-LINE
on-line
```

may eventually be normalized before comparison.

However, canonical source strings shall still be preserved in tests.

The parser must not use loose substring matching capable of accidentally matching unrelated content.

---

# 14. Whitespace Handling

The parser shall tolerate harmless formatting differences such as:

- repeated spaces;
- leading whitespace;
- trailing whitespace.

The parser shall not depend on an exact byte position for the state field unless real Informix validation demonstrates that positional parsing is more reliable.

Semantic parsing is preferred over fragile fixed-column parsing.

---

# 15. Version Independence

The parser shall not depend on an exact Informix version string such as:

```text
14.10.FC10
```

The following portion:

```text
IBM Informix Dynamic Server Version ...
```

may vary by version.

Instance-state extraction shall therefore avoid coupling to a specific release identifier.

---

# 16. Memory Value Independence

The parser shall not depend on the reported shared-memory value.

Example:

```text
8388608 Kbytes
```

is unrelated to the state metric.

Changes in memory allocation must not affect state parsing.

---

# 17. Uptime Independence

The parser shall not depend on uptime.

Example:

```text
Up 123 days 04:32:10
```

belongs conceptually to:

`IFX-HEALTH-002 — Instance Uptime`

The state parser may encounter the uptime field but shall not interpret or validate it beyond what is necessary to recognize a valid header.

---

# 18. Parser Contract

Conceptually, the future parser shall implement the following contract:

```text
INPUT:
    exit_code
    stdout
    stderr

OUTPUT:
    state OR collection_failure
```

Valid state output:

```text
0
1
2
3
4
99
```

Invalid behavior:

```text
empty output interpreted as 0
command failure interpreted as 0
malformed output interpreted as 0
unrecognized valid state interpreted as 0
```

---

# 19. Mock Test Matrix

| Mock | Expected Result |
|---|---:|
| `online.txt` | `4` |
| `quiescent.txt` | `3` |
| `recovery.txt` | `2` |
| `down.txt` | provisional `0` |
| `unknown-state.txt` | `99` |
| `malformed.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

The `down.txt` expectation remains provisional until real-environment validation establishes a safe distinction between engine-down and collection/environment failure.

---

# 20. Acceptance Criteria

The parser specification is considered approved for mock implementation when:

1. Online maps to `4`;
2. Quiescent maps to `3`;
3. Fast Recovery maps to `2`;
4. Unknown valid state maps to `99`;
5. malformed output causes collection failure;
6. command execution failure causes collection failure;
7. state parsing does not depend on uptime;
8. state parsing does not depend on memory size;
9. state parsing does not depend on exact Informix version;
10. Down remains explicitly provisional until real validation.

---

# 21. Historical Status

Historical specification:

`ARCHIVED — SUPERSEDED FOR OPERATIONAL IMPLEMENTATION`

Mock inputs:

`AVAILABLE`

Historical parser implementation:

`RETAINED AS MOCK MATERIAL ONLY`

Mock validation:

`PASSED — 7/7 tests`

Operational metric lifecycle state:

`DEVELOPMENT_RUNTIME_VALIDATED`

Target Informix/AIX validation:

`PENDING`

---

# 22. Current Operational Reference

The operational implementation is defined by:

```text
00-governance/metrics/informix-health/IFX-HEALTH-001-Instance-State.md
```

The deployed collector uses:

```text
sysmaster:sysshmhdr
name = 'mode'
```
