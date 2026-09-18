# IFX-HEALTH-002 — Parser Specification

> Historical mock-parser specification.
>
> This document is retained for engineering traceability. It is superseded for operational implementation by `IFX-HEALTH-002-Instance-Uptime.md`, which defines the remote SQL collector based on `sysmaster:sysshmhdr` and `bttime`.

## 1. Purpose

This document defines the expected parsing behavior for:

`IFX-HEALTH-002 — Instance Uptime`

This historical parser extracted uptime from mocked `onstat -` output and normalized it into total seconds.

It is not used by the deployed collector.

---

# 2. Historical Mock Input Source

Historical mock candidate source:

```text
onstat -
```

The parser shall receive a file containing the captured stdout of the source command during the current mock-validation phase.

The future collector architecture shall separately handle:

- command execution;
- exit code;
- stdout;
- stderr.

---

# 3. Output Model

Successful parsing shall return:

```text
uptime_seconds
```

The value shall be a non-negative integer.

Examples:

```text
123 days 04:32:10 → 10643530
1 days 00:00:01   → 86401
0 days 00:03:17   → 197
```

Collection/parsing failure is not a valid uptime value.

---

# 4. Uptime Pattern

For the current mock phase, the expected source representation is:

```text
Up <days> days <HH>:<MM>:<SS>
```

Example:

```text
Up 123 days 04:32:10
```

The exact production grammar remains subject to real Informix validation.

---

# 5. Normalization Formula

The parser shall calculate:

```text
TOTAL =
    DAYS    * 86400
  + HOURS   * 3600
  + MINUTES * 60
  + SECONDS
```

All resulting values shall be expressed in seconds.

---

# 6. Multi-Day Uptime

Mock:

```text
multi-day.txt
```

Input uptime:

```text
123 days 04:32:10
```

Expected result:

```text
10643530
```

---

# 7. Single-Day Uptime

Mock:

```text
single-day.txt
```

Input uptime:

```text
1 days 00:00:01
```

Expected result:

```text
86401
```

The use of `days` with value `1` is part of the current mock model only.

Whether Informix uses `day`, `days`, or another representation must be verified against the real source.

---

# 8. Near-Zero Uptime

Mock:

```text
near-zero.txt
```

Input uptime:

```text
0 days 00:03:17
```

Expected result:

```text
197
```

A legitimate small uptime value must not be treated as a collection failure.

---

# 9. State Independence

Mock:

```text
quiescent.txt
```

Input:

```text
IBM Informix Dynamic Server Version 14.10.FC10 -- Quiescent -- Up 5 days 12:30:15 -- 8388608 Kbytes
```

Expected result:

```text
477015
```

The parser shall extract uptime independently of the current Informix operational state.

---

# 10. Version and Memory Independence

Mock:

```text
different-version-memory.txt
```

Input:

```text
IBM Informix Dynamic Server Version 12.10.FC16 -- On-Line -- Up 2 days 01:02:03 -- 4194304 Kbytes
```

Expected result:

```text
176523
```

The parser shall not depend on:

- exact Informix version;
- instance state;
- shared-memory size.

---

# 11. Malformed Uptime

Mock:

```text
malformed-uptime.txt
```

Input:

```text
IBM Informix Dynamic Server Version 14.10.FC10 -- On-Line -- Up something-invalid -- 8388608 Kbytes
```

Expected result:

```text
COLLECTION_FAILURE
```

The parser shall not attempt to infer or manufacture an uptime value.

---

# 12. Missing Uptime

Mock:

```text
missing-uptime.txt
```

Input:

```text
IBM Informix Dynamic Server Version 14.10.FC10 -- On-Line -- 8388608 Kbytes
```

Expected result:

```text
COLLECTION_FAILURE
```

Missing uptime must not become:

```text
0
```

because zero is potentially a legitimate uptime value.

---

# 13. Numeric Validation

The parser shall verify that:

```text
days
hours
minutes
seconds
```

are numeric before performing arithmetic.

For the current grammar:

```text
0 <= hours   <= 23
0 <= minutes <= 59
0 <= seconds <= 59
days >= 0
```

Values outside those ranges shall result in:

```text
COLLECTION_FAILURE
```

unless future source validation demonstrates a different Informix representation.

---

# 14. Whitespace Handling

The parser should tolerate harmless differences in whitespace.

It shall not depend on exact fixed character positions.

The parser shall identify the semantic uptime structure rather than relying on a particular banner length.

---

# 15. Case Handling

The current canonical token is:

```text
Up
```

The mock parser may accept case-insensitive representation where this does not weaken parsing correctness.

Exact source capitalization shall still be preserved in mocks.

---

# 16. Informix Banner Validation

The parser shall require evidence that the input represents an Informix Dynamic Server response.

Current expected marker:

```text
IBM Informix Dynamic Server
```

An arbitrary line containing:

```text
Up 10 days 00:00:00
```

shall not automatically be accepted as valid Informix telemetry.

---

# 17. Failure Semantics

The following conditions shall result in parsing/collection failure:

- unreadable input;
- empty input;
- missing Informix banner;
- missing uptime;
- malformed uptime;
- non-numeric components;
- invalid time ranges.

Failure shall be represented through process failure, not by returning a synthetic numeric uptime.

---

# 18. Parser Contract

Conceptually:

```text
INPUT:
    Informix source output

OUTPUT:
    uptime_seconds OR collection_failure
```

Successful output:

```text
non-negative integer
```

Failure:

```text
no metric value
non-zero process exit code
```

---

# 19. Mock Test Matrix

| Mock | Expected |
|---|---:|
| `multi-day.txt` | `10643530` |
| `single-day.txt` | `86401` |
| `near-zero.txt` | `197` |
| `quiescent.txt` | `477015` |
| `different-version-memory.txt` | `176523` |
| `malformed-uptime.txt` | `COLLECTION_FAILURE` |
| `missing-uptime.txt` | `COLLECTION_FAILURE` |

---

# 20. Historical Shared Source Consideration

The former mock designs for `IFX-HEALTH-001` and `IFX-HEALTH-002` shared:

```text
onstat -
```

This section describes the former mock architecture only. The deployed HEALTH-001 and HEALTH-002 collectors use independent low-cost remote SQL statements against `sysmaster:sysshmhdr`.

---

# 21. Acceptance Criteria

The parser specification is approved for mock implementation when:

1. uptime is normalized to seconds;
2. multi-day uptime is supported;
3. zero-day uptime is supported;
4. operational state does not affect extraction;
5. version does not affect extraction;
6. memory size does not affect extraction;
7. malformed uptime fails;
8. missing uptime fails;
9. invalid time components fail;
10. failure never becomes synthetic uptime `0`.

---

# 22. Historical Status

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

# 23. Current Operational Reference

The operational implementation is defined by:

```text
00-governance/metrics/informix-health/IFX-HEALTH-002-Instance-Uptime.md
```

The deployed collector uses:

```text
sysmaster:sysshmhdr
name = 'bttime'
CAST(DBINFO('utc_current') - value AS INT8)
```
