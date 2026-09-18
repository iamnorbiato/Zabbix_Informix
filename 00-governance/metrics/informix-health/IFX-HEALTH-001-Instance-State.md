# IFX-HEALTH-001 — Instance State

## 1. Purpose

This document defines the engineering specification and validation state of metric:

`IFX-HEALTH-001 — Instance State`

The metric represents the current operational state of an IBM Informix instance.

This document is the authoritative engineering definition of this metric before Zabbix implementation.

---

# 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-001`

Metric Name:

`Instance State`

---

# 3. Objective

The objective of this metric is to determine whether the Informix instance is operational and identify its current engine state.

The metric shall allow the monitoring system to distinguish normal operation from transitional, administrative or unavailable states.

Typical operational questions answered by this metric are:

- Is the Informix instance running?
- Is the instance Online?
- Is it in Recovery?
- Is it Quiescent?
- Is it shutting down?
- Is the Informix engine unavailable?

---

# 4. Candidate Source

Initial candidate source:

```text
onstat -
```

`onstat -` is expected to provide the Informix engine status in the command header.

This source is currently considered:

`CANDIDATE`

It has not yet been validated against the target Informix environment.

---

# 5. Current Validation Mode

The target IBM AIX / Informix environment is not currently available.

Therefore this metric shall initially be validated through:

1. documented Informix behavior;
2. representative mocked command outputs;
3. collector parsing tests against those mocks.

This validation level shall be identified as:

`MOCK_VALIDATED`

and must not be confused with:

`SOURCE_VALIDATED`

Real environment validation remains mandatory before production deployment.

---

# 6. Metric Semantics

Metric type:

`STATE`

The metric represents the current state of the Informix engine.

The metric is not a counter.

The metric is not cumulative.

Each collection represents the state observed at that moment.

---

# 7. Expected Informix States

The initial state model shall consider at least the following conceptual conditions:

| Conceptual State | Meaning |
|---|---|
| Online | Instance available for normal operation |
| Quiescent | Engine running in restricted administrative state |
| Recovery | Engine performing recovery activity |
| Shutdown | Engine shutting down or intentionally unavailable |
| Down | Engine unavailable or inaccessible |

Exact textual representations returned by supported Informix versions remain subject to real environment validation.

No parser shall assume that these names are final until source validation is completed.

---

# 8. Internal Normalized Representation

Zabbix shall eventually receive a normalized numeric state rather than relying on arbitrary text.

Initial proposed normalized mapping:

| Value | State |
|---:|---|
| 0 | Down |
| 1 | Shutdown |
| 2 | Recovery |
| 3 | Quiescent |
| 4 | Online |
| 99 | Unknown |

This mapping is provisional until real Informix states are validated.

The mapping shall be represented in Zabbix through a Value Map.

---

# 9. Mock Input — Online

Representative input:

```text
IBM Informix Dynamic Server Version 14.10.FCxx -- On-Line -- Up 123 days 04:32:10 -- 1234567 Kbytes
```

Expected normalized result:

```text
4
```

Expected logical state:

```text
Online
```

---

# 10. Mock Input — Quiescent

Representative input:

```text
IBM Informix Dynamic Server Version 14.10.FCxx -- Quiescent -- Up 123 days 04:32:10 -- 1234567 Kbytes
```

Expected normalized result:

```text
3
```

Expected logical state:

```text
Quiescent
```

---

# 11. Mock Input — Recovery

Representative input:

```text
IBM Informix Dynamic Server Version 14.10.FCxx -- Fast Recovery -- Up 00:03:17 -- 1234567 Kbytes
```

Expected normalized result:

```text
2
```

Expected logical state:

```text
Recovery
```

The exact recovery-state strings must be verified against the actual Informix version.

---

# 12. Mock Input — Shutdown

A shutdown condition may be represented differently depending on the engine lifecycle stage.

The exact `onstat` output must be validated in the target environment.

For mock purposes, the conceptual expected result is:

```text
1
```

Expected logical state:

```text
Shutdown
```

No exact textual parser shall be finalized for this state before real source validation.

---

# 13. Mock Input — Down / Unavailable

A stopped Informix instance may cause `onstat` to fail rather than return a normal engine header.

Representative condition:

```text
onstat: cannot attach to shared memory
```

or another non-zero command execution result indicating that the engine cannot be accessed.

Expected normalized result:

```text
0
```

Expected logical state:

```text
Down
```

The distinction between:

```text
Informix is Down
```

and:

```text
collection itself failed
```

must be explicitly preserved.

A command failure caused by permission, environment or collector problems must not automatically be interpreted as Informix Down.

---

# 14. Unknown State

If the collector successfully accesses Informix but receives a state that it does not recognize, the result shall be:

```text
99
```

Logical state:

```text
Unknown
```

Unknown shall be treated differently from Down.

This protects the monitoring system against:

- new Informix versions;
- unexpected state strings;
- parser incompatibility;
- undocumented engine states.

---

# 15. Collection Failure Semantics

The following conditions must not automatically produce state `0`:

- `onstat` binary not found;
- incorrect Informix environment;
- invalid `INFORMIXSERVER`;
- permission failure;
- collector execution failure;
- timeout;
- parser failure.

These represent collection problems rather than proven Informix engine state.

The future collector shall therefore distinguish between:

```text
valid Informix state
```

and:

```text
collection failure
```

---

# 16. Expected Zabbix Representation

The future Zabbix item is expected to conceptually represent:

```text
informix.instance.state
```

Final item naming convention is not yet approved.

Expected type:

```text
Numeric unsigned
```

Expected Value Map:

```text
0  = Down
1  = Shutdown
2  = Recovery
3  = Quiescent
4  = Online
99 = Unknown
```

The exact Zabbix key shall be defined during template implementation.

---

# 17. Candidate Collection Frequency

Frequency class:

`HIGH`

The instance state is a primary availability metric and should be collected frequently.

The exact interval remains undefined until the Zabbix implementation phase.

Candidate intervals may later be evaluated in the range of tens of seconds rather than minutes.

No final interval is established by this document.

---

# 18. Expected Collection Cost

Expected cost:

`LOW`

`onstat -` is expected to be a lightweight engine-status operation.

This assumption must still be confirmed during real environment validation.

---

# 19. Discovery Requirement

Low-Level Discovery:

`NO`

This metric belongs to a specific Informix instance and does not require resource discovery.

If a single AIX host runs multiple Informix instances, instance-level discovery or host-modeling strategy shall be addressed separately.

---

# 20. Alerting Relevance

Alerting:

`YES`

The primary healthy state is expected to be:

```text
Online
```

Potential future severity model:

| State | Initial Interpretation |
|---|---|
| Online | OK |
| Quiescent | Warning |
| Recovery | Context-dependent |
| Shutdown | High / Disaster depending on context |
| Down | Disaster |
| Unknown | Warning / High depending on collection state |

These are not final trigger definitions.

Maintenance windows and expected administrative transitions must be considered before production triggers are implemented.

---

# 21. Grafana Relevance

Grafana:

`YES`

The metric should be visible in the Informix Overview dashboard.

Expected presentation:

- current state;
- state history;
- transitions between operational states;
- correlation with uptime and restart events.

---

# 22. Dependencies

This metric depends on:

- correct Informix environment;
- ability to execute the selected source;
- correct target instance identification;
- future collector execution mechanism.

The metric does not depend on SQL connectivity if `onstat -` remains the approved source.

---

# 23. Mock Validation Criteria

The metric may be marked `MOCK_VALIDATED` only when the future parser or collection logic demonstrates correct behavior for at least:

1. Online state;
2. Quiescent state;
3. Recovery state;
4. engine unavailable condition;
5. unknown state;
6. command execution failure;
7. malformed output.

Mock validation shall verify that:

- known states are normalized correctly;
- unknown states do not become Down;
- collection failures do not become valid engine states.

---

# 24. Real Environment Validation Criteria

The metric may progress to `SOURCE_VALIDATED` only after execution against a real Informix environment confirms:

- actual `onstat -` output;
- actual Online representation;
- supported recovery-state representation;
- behavior while Quiescent, if testable;
- behavior when the engine is stopped, if testable;
- command return codes;
- command execution cost;
- required permissions;
- differences caused by Informix version.

Observed outputs shall replace or supplement the mock examples in this document.

---

# 25. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Current source status:

`CANDIDATE SOURCE — onstat -`

Current validation environment:

`MOCK VALIDATION PASSED — 7/7 tests`

Real Informix/AIX validation:

`PENDING`

---

# 26. Exit Criteria

`IFX-HEALTH-001` shall be considered complete for the current documentation/mock phase when:

- metric semantics are approved;
- normalized state model is approved;
- mock scenarios are established;
- mock parsing behavior is validated;
- known collection failures are distinguished from engine state.

After that, work may proceed to:

`IFX-HEALTH-002 — Instance Uptime`

Real source validation of `IFX-HEALTH-001` shall remain pending until access to the target Informix/AIX environment becomes available.

## Instance State Mapping

The operational state is obtained from:

`sysmaster:sysshmhdr`

using the row:

`name = 'mode'`

| Value | Operational Mode | Technical Description |
|------:|------------------|-----------------------|
| 0 | Initialization | The instance is initializing shared-memory structures and allocating engine resources. User connections are not yet accepted. |
| 1 | Quiescent | Administrative/single-user operational mode. Normal user connections are restricted. |
| 2 | Recovery | The instance is performing recovery processing, including fast recovery and other recovery-related operations. |
| 3 | Backup | The instance is operating in backup mode during applicable engine backup procedures. |
| 4 | Shutdown | The instance is actively shutting down threads, flushing pending work, and dismantling engine resources. |
| 5 | Online | Normal operational state. The engine is available for normal user connections and workload processing. |
| 6 | Abort | The instance is in an abort processing state following a critical engine condition. |
| 7 | User | Restricted user operational mode used for controlled engine operations. |
| 255 | Off-Line | Off-line state when observable through the engine state structure. A remotely unreachable or stopped instance normally cannot expose this value through SQL. |

### Collection Semantics

`255` MUST NOT be synthesized when the remote SQL connection fails.

Failure to connect to Informix is a collection/availability failure and is semantically distinct from an engine state successfully returned by `sysshmhdr`.

The collector MUST preserve the numeric `mode` value as the authoritative metric value. Human-readable operational modes are presentation metadata and MUST NOT replace the numeric value.