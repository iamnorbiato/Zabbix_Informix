# IFX-HEALTH-002 — Instance Uptime

## 1. Purpose

This document defines the engineering specification and validation state of metric:

`IFX-HEALTH-002 — Instance Uptime`

The metric represents the elapsed time since the current IBM Informix instance was started.

This document is the authoritative engineering definition of this metric before Zabbix implementation.

---

# 2. Monitoring Domain

Domain:

`Informix Instance Availability and Health`

Metric ID:

`IFX-HEALTH-002`

Metric Name:

`Instance Uptime`

---

# 3. Objective

The objective of this metric is to determine how long the current Informix instance has been running.

The metric shall support:

- detection of recent instance restarts;
- visualization of instance availability history;
- correlation of restarts with operational events;
- identification of unexpected uptime resets;
- future restart-related alerting.

---

# 4. Candidate Source

Initial candidate source:

```text
onstat -
```

Representative output:

```text
IBM Informix Dynamic Server Version 14.10.FC10 -- On-Line -- Up 123 days 04:32:10 -- 8388608 Kbytes
```

The same source currently used by `IFX-HEALTH-001` exposes both instance state and uptime.

This creates an important future collection optimization opportunity: one execution of `onstat -` may supply both metrics.

No duplicate `onstat -` execution should be introduced merely because the metrics have different IDs.

---

# 5. Current Validation Mode

The target IBM AIX / Informix environment is not currently available.

Validation shall initially use:

1. documented Informix behavior;
2. representative mocked outputs;
3. parser tests against those mocks.

Current validation target:

`MOCK_VALIDATED`

Real environment validation remains mandatory before `SOURCE_VALIDATED`.

---

# 6. Metric Semantics

Metric type:

`GAUGE`

Unit:

`seconds`

The normalized value shall represent total elapsed uptime in seconds.

Example:

```text
Up 1 days 01:00:00
```

shall become:

```text
90000
```

The original formatted Informix uptime string shall not be used as the primary monitoring value.

---

# 7. Normalization

The parser shall convert the Informix uptime representation into total seconds.

Conceptually:

```text
total_seconds =
    (days * 86400)
  + (hours * 3600)
  + (minutes * 60)
  + seconds
```

Example:

```text
123 days 04:32:10
```

becomes:

```text
10643530
```

---

# 8. Expected Input Variations

Initial mocks shall cover at least:

```text
Up 123 days 04:32:10
Up 1 days 00:00:01
Up 0 days 00:03:17
```

Possible singular/plural and formatting differences must remain subject to source validation.

The parser shall not assume that mocked formatting is authoritative for every supported Informix version.

---

# 9. State Independence

Instance uptime is a separate metric from instance state.

For example, an Informix banner containing:

```text
Quiescent -- Up 123 days 04:32:10
```

still contains a potentially valid uptime.

The uptime parser shall not require the instance to be `On-Line` merely to extract uptime.

---

# 10. Version Independence

The parser shall not depend on a specific Informix version such as:

```text
14.10.FC10
```

Version information is unrelated to uptime normalization.

---

# 11. Memory Independence

The parser shall not depend on the shared-memory value appearing after the uptime.

Example:

```text
8388608 Kbytes
```

must have no effect on the resulting uptime value.

---

# 12. Invalid or Missing Uptime

If a valid uptime cannot be identified, the collector must not return:

```text
0
```

unless the source explicitly and validly reports zero uptime.

Missing, malformed or unparseable uptime represents:

`COLLECTION_FAILURE`

This distinction prevents parser failures from being interpreted as a newly started Informix instance.

---

# 13. Instance Down

If the Informix instance is unavailable and `onstat -` cannot provide a valid uptime, this metric shall not manufacture an uptime value.

Instance availability belongs primarily to:

`IFX-HEALTH-001 — Instance State`

Therefore an unavailable instance normally means that no valid uptime sample can be collected.

The future Zabbix architecture shall determine how unsupported/unavailable uptime samples are represented operationally.

---

# 14. Restart Semantics

A significant decrease in uptime between valid samples indicates that the Informix instance was restarted or that collection changed to a different instance.

Example:

```text
Previous: 864000
Current : 120
```

The raw metric itself shall only report uptime.

Restart detection should preferably be derived by Zabbix rather than embedded as monitoring logic inside the parser.

---

# 15. Expected Zabbix Representation

Conceptual future item key:

```text
informix.instance.uptime
```

Final naming convention remains unapproved.

Expected value type:

`Numeric unsigned`

Expected unit:

`uptime`

or equivalent Zabbix representation appropriate for seconds.

The stored raw value shall remain seconds.

---

# 16. Candidate Collection Frequency

Frequency class:

`MEDIUM`

However, because `IFX-HEALTH-001` and `IFX-HEALTH-002` currently share the same candidate source, the eventual collection architecture should avoid executing `onstat -` independently for each metric.

The final effective frequency may therefore follow the shared collection cycle.

---

# 17. Expected Collection Cost

Expected source cost:

`LOW`

The actual cost must still be confirmed against the real Informix environment.

---

# 18. Discovery Requirement

Low-Level Discovery:

`NO`

The metric belongs to a specific Informix instance.

Multi-instance host modeling remains a separate architectural concern.

---

# 19. Alerting Relevance

Alerting:

`CONDITIONAL`

Uptime itself is primarily informational.

Useful future conditions may include:

- unexpected restart;
- restart outside maintenance window;
- repeated restarts;
- unusually short uptime.

These conditions should be derived from the raw metric rather than encoded in the parser.

---

# 20. Grafana Relevance

Grafana:

`YES`

Expected uses include:

- current uptime;
- restart visualization;
- correlation with assert failures;
- correlation with checkpoint behavior;
- correlation with backup/replication events;
- correlation with AIX events.

---

# 21. Collection Optimization

`IFX-HEALTH-001` and `IFX-HEALTH-002` currently share:

```text
onstat -
```

as their candidate source.

Therefore the architecture should eventually favor:

```text
one source execution
        │
        ├── Instance State
        └── Instance Uptime
```

rather than:

```text
onstat - → State
onstat - → Uptime
```

This follows the project principle that shared or expensive source execution should not be unnecessarily repeated.

The current standalone parsers may remain independent for mock validation.

---

# 22. Mock Validation Criteria

The metric may become `MOCK_VALIDATED` when tests demonstrate:

1. valid multi-day uptime conversion;
2. valid single-day uptime conversion;
3. valid near-zero uptime conversion;
4. uptime extraction independent of instance state;
5. malformed uptime causes collection failure;
6. missing uptime causes collection failure;
7. parser does not depend on Informix version;
8. parser does not depend on memory value;
9. collection failure does not become uptime `0`.

---

# 23. Real Environment Validation Criteria

The metric may become `SOURCE_VALIDATED` only after the real environment confirms:

- actual `onstat -` uptime format;
- singular/plural day representation;
- behavior immediately after startup;
- behavior in non-Online engine states;
- behavior when uptime is unavailable;
- command return codes;
- source execution cost;
- version-specific formatting differences.

---

# 24. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Current source status:

`CANDIDATE SOURCE — onstat -`

Current validation environment:

`MOCK VALIDATION PASSED — 7/7 tests`

Real Informix/AIX validation:

`PENDING`

---

# 25. Exit Criteria

`IFX-HEALTH-002` shall complete the current documentation/mock phase when:

- metric semantics are approved;
- uptime normalization is approved;
- mocks are established;
- parser behavior is specified;
- parser is implemented;
- all approved mock tests pass.

After that:

`IFX-HEALTH-002 → MOCK_VALIDATED`

Real source validation shall remain pending until access to the target Informix/AIX environment becomes available.