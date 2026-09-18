# IFX-SESSION-003 — Historical Session Peak

## 1. Purpose

This document defines the engineering contract for:

`IFX-SESSION-003 — Historical Session Peak`

The metric represents the authoritative maximum number of simultaneous Informix sessions observed by the Informix engine since the relevant engine startup or authoritative statistics reset boundary.

This metric shall be sourced from an authoritative Informix-maintained statistic.

A maximum derived from Zabbix observations is not the source of this metric.

---

# 2. Monitoring Domain

Domain:

`Connections, Sessions and Concurrency`

Metric ID:

`IFX-SESSION-003`

Metric name:

`Historical Session Peak`

---

# 3. Monitoring Objective

The metric shall provide visibility into the highest simultaneous session population recorded by Informix within the current authoritative lifecycle boundary.

It is intended to support:

- session-capacity analysis;
- concurrency sizing;
- historical workload characterization;
- capacity headroom analysis;
- identification of connection peaks that may occur between monitoring polling intervals;
- correlation with engine configuration and resource pressure.

---

# 4. Architectural Source Decision

The source of this metric shall be:

`AUTHORITATIVE INFORMIX-MAINTAINED HISTORICAL MAXIMUM`

The metric shall not use a Zabbix-derived maximum of:

`IFX-SESSION-001 — Total Connected Sessions`

as its authoritative value.

This distinction is intentional.

---

# 5. Why Zabbix-Derived Maximum Is Not Equivalent

A Zabbix-derived maximum represents:

`maximum value observed at monitoring sample times`

An authoritative Informix-maintained maximum represents:

`maximum simultaneous session count observed by the engine`

These values are not necessarily equivalent.

A connection peak may occur entirely between two Zabbix polling intervals.

Therefore:

```text id="sspk31"
Zabbix observed maximum
        !=
authoritative engine maximum
```

in the general case.

---

# 6. Candidate Source

Candidate sources:

`sysmaster`

or an authoritative Informix internal statistic exposed through:

`onstat`

Exact authoritative object:

`PENDING SOURCE VALIDATION`

Exact SQL or command representation:

`PENDING SOURCE VALIDATION`

---

# 7. Source Requirement

Source validation must identify an Informix-maintained statistic whose semantic is equivalent to:

`maximum simultaneous session count since the relevant startup/reset boundary`

A source that merely reports current connected sessions is not sufficient.

A source reconstructed from monitoring history is not sufficient.

---

# 8. Lifecycle Boundary

The historical maximum is meaningful only relative to a lifecycle boundary.

Expected boundary:

`INFORMIX ENGINE STARTUP OR AUTHORITATIVE STATISTICS RESET`

The exact reset behavior must be established during source validation.

Possible reset mechanisms must not be assumed before validation.

---

# 9. Provisional Semantic

For mock validation:

`maximum simultaneous session count recorded by the authoritative Informix statistic within its current lifecycle boundary`

---

# 10. Metric Type

Type:

`GAUGE / HISTORICAL MAXIMUM`

Although the value normally behaves monotonically within a lifecycle boundary, it is not modeled as a cumulative event counter.

It represents a maximum state maintained by the engine.

---

# 11. Normalized Unit

Normalized unit:

`SESSIONS`

Example:

```text id="ew3pp8"
375
```

means that the authoritative Informix statistic reports a historical maximum of 375 simultaneous sessions within the current lifecycle boundary.

---

# 12. Value Domain

Valid normalized values are non-negative integers.

Examples:

```text id="1wm92p"
0
1
375
5000
```

Invalid examples:

```text id="jd1htz"
-1
10.5
peak
```

---

# 13. Zero Semantics

Zero is syntactically valid.

Input:

```text id="h3dw5m"
0
```

shall produce:

```text id="s0kzvb"
0
```

when collection succeeded.

Whether zero is operationally possible for the authoritative Informix statistic must be established during source validation.

Collection failure shall never become zero.

---

# 14. Expected In-Lifecycle Behavior

Within the same authoritative lifecycle boundary, the expected behavior is:

```text id="6xfawh"
new_peak >= previous_peak
```

The value may:

- remain unchanged;
- increase.

A decrease within the same confirmed lifecycle boundary may indicate:

- statistics reset;
- source semantic misunderstanding;
- collection inconsistency;
- engine behavior requiring investigation.

This behavior must be confirmed during source validation.

---

# 15. Lower Value After Lifecycle Boundary

A lower observation after an engine startup or authoritative statistics reset is valid.

Example:

```text id="quhyzz"
before restart: 375
after restart:   12
```

The parser shall not reject the value `12`.

Historical comparison belongs to the monitoring layer.

---

# 16. Relationship with Instance Uptime

This metric should be correlated with:

`IFX-HEALTH-002 — Instance Uptime`

A decrease in the historical session peak accompanied by an uptime reset may be consistent with an Informix restart.

This correlation shall not be implemented in the parser.

---

# 17. Relationship with Total Connected Sessions

This metric is related to:

`IFX-SESSION-001 — Total Connected Sessions`

Conceptually, within equivalent source semantics and lifecycle context:

```text id="9kmht8"
Historical Session Peak >= Current Connected Sessions
```

However, the parser shall not enforce this relationship.

Reasons include:

- collection timing differences;
- provisional source semantics;
- lifecycle transitions;
- source reset behavior.

---

# 18. Relationship with Active Sessions

This metric may also be correlated with:

`IFX-SESSION-002 — Active Sessions`

No direct parser-level constraint is defined.

---

# 19. Collection Method

Expected collection method:

`SQL statement or collector reading an authoritative Informix statistic`

Final method:

`PENDING SOURCE VALIDATION`

---

# 20. Collection Frequency

Catalog frequency:

`MEDIUM`

The historical maximum does not require high-frequency polling to capture transient peaks if the authoritative Informix source maintains the maximum internally.

This is an important advantage over a monitoring-derived maximum.

---

# 21. Collection Cost

Current catalog classification:

`UNKNOWN`

Source validation must establish the actual collection cost.

The preferred source shall have acceptable monitoring overhead.

---

# 22. Output Cardinality

Expected normalized output:

`one scalar per Informix instance`

Example:

```text id="8jsl6p"
375
```

Multiple normalized scalar values are invalid.

---

# 23. Aggregation Boundary

If the authoritative source exposes multiple rows or internal dimensions, any required aggregation must be defined as part of source validation.

The parser shall receive one normalized instance-level scalar.

It shall not silently aggregate multiple values.

---

# 24. Discovery

Zabbix Low-Level Discovery:

`NO`

The metric represents one historical maximum per Informix instance.

---

# 25. Trigger Potential

Trigger support:

`YES — CONDITIONAL`

Potential future conditions include:

- peak approaching configured session capacity;
- insufficient capacity headroom;
- unexpected peak reset without corresponding engine lifecycle change.

No fixed threshold is defined here.

---

# 26. Grafana

Grafana visualization:

`YES`

Useful representations may include:

- authoritative historical session peak;
- current connected sessions;
- active sessions;
- configured session capacity;
- remaining capacity headroom;
- engine restart boundaries.

---

# 27. Derived Zabbix Maximum

Zabbix may independently derive metrics such as:

- maximum connected sessions observed during one hour;
- maximum observed during 24 hours;
- maximum observed during seven days;
- maximum observed during a reporting period.

These are valid monitoring-derived statistics.

They are not:

`IFX-SESSION-003`

and shall not replace its authoritative engine-maintained value.

---

# 28. Collection Failure

Collection failure is distinct from every numeric value.

Examples include:

- SQL execution failure;
- Informix connection failure;
- command execution failure;
- permission failure;
- unavailable authoritative statistic;
- malformed output.

Collection failure shall not emit zero.

---

# 29. Mock Normalization Contract

For mock validation, the parser receives one file containing one normalized scalar.

Example:

```text id="qfx09x"
375
```

Expected output:

```text id="i83cyf"
375
```

The parser validates only the normalized scalar contract.

It does not validate the existence or semantics of the future authoritative Informix statistic.

---

# 30. Provisional Mock Scenarios

Planned mocks:

| Mock | Expected |
|---|---:|
| `normal.txt` | `375` |
| `zero.txt` | `0` |
| `single.txt` | `1` |
| `high.txt` | `5000` |
| `post-reset.txt` | `12` |
| `empty.txt` | `COLLECTION_FAILURE` |
| `non-numeric.txt` | `COLLECTION_FAILURE` |
| `negative.txt` | `COLLECTION_FAILURE` |
| `decimal.txt` | `COLLECTION_FAILURE` |
| `execution-error.txt` | `COLLECTION_FAILURE` |

`post-reset.txt` represents a syntactically valid lower historical maximum after a lifecycle/reset boundary.

The parser does not validate the boundary itself.

---

# 31. Parser Responsibilities

The future parser shall:

1. detect explicit source execution failure;
2. obtain the normalized scalar;
3. trim permitted surrounding whitespace;
4. require exactly one value;
5. validate a non-negative integer;
6. emit the normalized historical session peak.

---

# 32. Parser Non-Responsibilities

The parser shall not:

- execute the final SQL or command;
- calculate a maximum from session samples;
- maintain historical state;
- detect Informix restart;
- detect statistics reset;
- compare with previous peak;
- compare with current connected sessions;
- determine capacity threshold;
- convert collection failure into zero.

---

# 33. Source Validation Questions

Real Informix validation must answer at least:

1. Does Informix expose an authoritative historical maximum simultaneous session statistic?
2. Which `sysmaster` object or internal statistic exposes it?
3. Is an equivalent value exposed through `onstat`?
4. What exactly constitutes a session in that statistic?
5. What is the lifecycle boundary?
6. Does engine restart reset the statistic?
7. Can the statistic be reset independently of restart?
8. If so, how?
9. Is the statistic instance-wide?
10. Are internal sessions included?
11. What permissions are required?
12. What is the collection cost?
13. Are there relevant Informix version differences?
14. Can the result be independently verified?

---

# 34. Source Validation Acceptance Criteria

The metric may become:

`SOURCE_VALIDATED`

only after:

- an authoritative Informix-maintained maximum is identified;
- its session semantic is understood;
- lifecycle/reset boundary is established;
- exact source and collection method are documented;
- normalized unit is confirmed;
- scope is established;
- permissions are known;
- collection cost is acceptable;
- relevant version behavior is documented.

If no authoritative Informix-maintained statistic exists, the metric definition must return to architectural review.

It shall not silently become a Zabbix-derived maximum.

---

# 35. Mock Validation Acceptance Criteria

The metric may become:

`MOCK_VALIDATED`

when:

- mock inputs exist;
- parser specification exists;
- parser is implemented;
- all valid mock values are preserved;
- all invalid/error cases fail;
- collection failure never becomes zero.

Mock validation does not prove that the authoritative Informix statistic exists.

---

# 36. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Architectural source requirement:

`AUTHORITATIVE INFORMIX-MAINTAINED HISTORICAL MAXIMUM`

Current source status:

`PENDING SOURCE VALIDATION`

Candidate interfaces:

`sysmaster / onstat`

Current semantic:

`PROVISIONAL — MAXIMUM SIMULTANEOUS SESSION COUNT SINCE AUTHORITATIVE STARTUP/RESET BOUNDARY`

Metric semantics:

`GAUGE / HISTORICAL MAXIMUM`

Normalized unit:

`SESSIONS — MOCK CONTRACT`

Lifecycle/reset boundary:

`PENDING SOURCE VALIDATION`

Exact Informix source:

`PENDING SOURCE VALIDATION`

Exact SQL/command:

`PENDING SOURCE VALIDATION`

Zabbix-derived maximum as authoritative source:

`NOT ALLOWED`

Mock inputs:

`AVAILABLE`

Parser implementation:

`IMPLEMENTED`

Mock validation:

`PASSED — 10/10`

Real Informix/AIX validation:

`PENDING`

---

# 37. Next Step

Create the mock dataset for `IFX-SESSION-003`.

The mocks shall validate only the normalized authoritative historical-maximum scalar contract.

They shall not simulate a Zabbix-derived maximum or invent the real Informix source.
