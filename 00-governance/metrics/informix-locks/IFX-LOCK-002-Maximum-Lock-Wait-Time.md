# IFX-LOCK-002 — Maximum Lock Wait Time

## 1. Purpose

This document defines the engineering contract for:

`IFX-LOCK-002 — Maximum Lock Wait Time`

The metric represents the age, in seconds, of the oldest currently active Informix lock wait.

It provides an instance-level indication of the severity and persistence of current lock contention.

---

# 2. Monitoring Domain

Domain:

`Locks, Deadlocks and Contention`

Metric ID:

`IFX-LOCK-002`

Metric name:

`Maximum Lock Wait Time`

---

# 3. Architectural Objective

The metric shall answer:

`HOW LONG HAS THE OLDEST CURRENTLY ACTIVE LOCK WAIT BEEN WAITING?`

This complements:

`IFX-LOCK-001 — Sessions Waiting for Locks`

which answers:

`HOW MANY ARE CURRENTLY WAITING?`

---

# 4. Provisional Semantic

For mock validation:

`AGE IN SECONDS OF THE OLDEST CURRENTLY ACTIVE LOCK WAIT`

The semantic represents current lock-wait state.

It does not represent a historical maximum.

---

# 5. Critical Current-vs-Historical Rule

The metric must not be interpreted as:

`LONGEST LOCK WAIT EVER OBSERVED`

or:

`LONGEST LOCK WAIT SINCE ENGINE STARTUP`

or:

`MAXIMUM VALUE STORED IN ZABBIX HISTORY`

Instead, each collection represents the oldest wait that remains active at that collection instant.

Conceptually:

```text
current lock waits:

wait A = 3 seconds
wait B = 17 seconds
wait C = 8 seconds

IFX-LOCK-002 = 17
```

When wait B ends, the next value may legitimately decrease.

---

# 6. Non-Monotonic Behavior

Because this is a current-state gauge, values may:

- increase while the oldest wait remains blocked;
- decrease when the oldest wait ends;
- return to zero when no active lock waits remain;
- increase again when new contention occurs.

No monotonic behavior is expected.

---

# 7. Candidate Source

Preferred candidate interface:

`sysmaster`

Alternative supporting interface:

`onstat`

Exact authoritative source:

`PENDING SOURCE VALIDATION`

Exact SQL or command:

`PENDING SOURCE VALIDATION`

---

# 8. Source Requirement

The authoritative source must provide sufficient information to determine the age of currently active lock waits.

This may conceptually require:

- an authoritative wait-start timestamp;
- an authoritative wait duration;
- another engine-maintained representation from which current wait age can be calculated reliably.

The exact mechanism remains pending source validation.

---

# 9. Time Calculation Ownership

If the authoritative source provides a wait-start timestamp rather than a duration, calculation of elapsed wait time belongs to the validated collection layer.

Conceptually:

```text
current collection time
-
authoritative wait start time
=
current wait age
```

The scalar parser shall not perform this calculation.

---

# 10. Clock Semantics

If elapsed time must be derived from timestamps, source validation must establish the relevant clock semantics.

The implementation must avoid silently introducing errors caused by:

- incompatible clocks;
- timezone conversion;
- timestamp precision;
- clock adjustments;
- source timestamp semantics.

Whenever Informix exposes an authoritative elapsed duration directly, that representation may be preferable.

---

# 11. Metric Type

Type:

`GAUGE`

The metric represents current state at collection time.

---

# 12. Normalized Unit

Normalized unit:

`SECONDS`

The normalized scalar value shall use whole seconds for the mock contract.

Final source precision remains subject to source validation.

---

# 13. Cardinality

Cardinality:

`ONE VALUE PER INFORMIX INSTANCE`

The metric represents the maximum current wait age across the relevant active lock-wait population.

---

# 14. Zabbix Discovery

Zabbix Low-Level Discovery:

`NO`

This is an instance-level aggregate.

Future detailed lock-wait diagnostics may use separate dimensional metrics if governed.

---

# 15. Value Domain

The normalized value must be a non-negative integer.

Valid examples:

```text
0
1
15
120
3600
```

Invalid examples:

```text
-1
3.5
seconds
```

---

# 16. Zero Semantics

Value:

```text
0
```

means:

`NO CURRENTLY ACTIVE LOCK WAIT HAS A POSITIVE OBSERVED AGE`

Operationally, this is expected primarily when no active lock waits exist.

Source validation must confirm whether a newly observed wait can legitimately produce an age of zero seconds due to source precision.

Therefore zero remains valid regardless.

---

# 17. Collection Failure

Collection failure is different from:

```text
0
```

Examples of collection failure include:

- Informix connection failure;
- SQL execution failure;
- command execution failure;
- permission failure;
- malformed result;
- unavailable timing information;
- invalid timestamp relationship.

Collection failure shall not be normalized to zero.

---

# 18. Aggregation

The validated collection layer owns calculation of the maximum current wait age.

Conceptually:

```text
MAX(current age of each authoritative active lock wait)
```

The scalar parser shall not receive multiple wait records and independently calculate the maximum.

It receives only the normalized scalar result.

---

# 19. Empty Lock-Wait Population

If the authoritative source successfully establishes that there are no active lock waits, the normalized collection result shall be:

```text
0
```

The scalar parser therefore still receives an explicit value.

An empty scalar result is not equivalent to no lock waits.

---

# 20. Relationship with IFX-LOCK-001

Related metric:

`IFX-LOCK-001 — Sessions Waiting for Locks`

Conceptually:

```text
IFX-LOCK-001
=
quantity of current lock contention

IFX-LOCK-002
=
age of the oldest current lock contention
```

Together they distinguish conditions such as:

```text
many short waits
few long waits
many long waits
```

---

# 21. Cross-Metric Invariants

It may eventually be reasonable to expect:

```text
IFX-LOCK-001 = 0
→
IFX-LOCK-002 = 0
```

However, this relationship is currently:

`UNPROVEN`

The metrics may ultimately differ in entity scope, timing or source semantics.

No cross-metric invariant shall be enforced before real source validation.

---

# 22. Relationship with IFX-SESSION-005

Related metric:

`IFX-SESSION-005 — Waiting Client Sessions by Reason`

The fixed `LOCK` dimension of `IFX-SESSION-005` counts qualifying client sessions for which:

```text
syssessions.is_wlock = 1
```

It can be correlated with maximum lock-wait duration, but no direct arithmetic, timing, or identity relationship is assumed.

The metrics differ by purpose:

- `IFX-SESSION-005` is a current client-session count;
- `IFX-LOCK-002` is an elapsed-time metric;
- source timing, filtering and aggregation can differ.

---

# 23. Collection Method

Expected collection method:

`SQL statement or collector against authoritative current lock-wait information`

The collection layer owns:

1. identifying active lock waits;
2. determining authoritative wait timing;
3. calculating wait age when necessary;
4. identifying the oldest active wait;
5. producing one normalized scalar value in seconds.

---

# 24. Collection Frequency

Recommended frequency:

`HIGH`

Long lock waits can become operationally significant quickly.

The final interval must balance detection resolution against collection overhead.

---

# 25. Collection Cost

Current classification:

`MEDIUM — PROVISIONAL`

Real source validation must establish actual collection cost and scalability.

Monitoring overhead remains a first-class acceptance criterion.

---

# 26. Trigger Potential

Trigger potential:

`YES`

This metric is particularly suitable for duration-based contention alerts.

Possible future conditions include:

```text
maximum lock wait > threshold
```

and sustained conditions correlated with:

`IFX-LOCK-001`

Exact thresholds require runtime baseline validation.

---

# 27. Grafana

Grafana visualization:

`YES`

The metric supports visualization and correlation with:

- sessions waiting for locks;
- waiting client sessions;
- wait reasons;
- deadlocks;
- SQL workload;
- transaction activity;
- CPU;
- I/O.

---

# 28. Parser Contract

The normalized parser input shall be a single scalar value expressed in whole seconds.

Example:

```text
45
```

The parser validates the normalized collection contract.

It does not calculate elapsed time or inspect individual lock waits.

---

# 29. Parser Responsibilities

The future scalar parser shall:

- detect explicit collection failure;
- accept one normalized scalar value;
- trim permitted surrounding whitespace;
- validate a non-negative integer;
- preserve zero;
- emit the normalized value.

---

# 30. Parser Non-Responsibilities

The parser shall not:

- query Informix;
- identify lock waiters;
- identify blockers;
- calculate elapsed time;
- compare timestamps;
- inspect multiple wait records;
- calculate the maximum;
- derive historical maxima;
- correlate with LOCK-001;
- generate alerts;
- convert collection failure into zero.

---

# 31. Mock Strategy

Mock validation shall validate only the normalized scalar contract.

It shall not simulate Informix timing internals.

Planned scenarios:

```text
normal
zero
single-second
long
lower
empty
nonnumeric
negative
decimal
execution-error
```

The `lower` scenario explicitly confirms that a lower value is valid because the metric is a non-monotonic current-state gauge.

---

# 32. Source Validation Questions

Real Informix validation must answer at least:

1. Which authoritative source exposes current lock waits?
2. Which `sysmaster` objects are involved?
3. Can Informix expose current wait duration directly?
4. If not, does it expose an authoritative wait-start timestamp?
5. What is the timestamp or duration precision?
6. Which clock semantics apply?
7. What identifies an active lock wait?
8. Can one session or thread have multiple relevant wait records?
9. What entity owns the wait?
10. Are internal/system waits represented?
11. Should any wait classes be excluded?
12. Is maximum duration naturally available or must it be aggregated?
13. How should an empty wait population be represented?
14. Can an active wait legitimately have age zero?
15. What permissions are required?
16. What is the collection cost?
17. How does cost scale with sessions, threads and locks?
18. Are there relevant Informix-version differences?
19. Can the relationship with `IFX-LOCK-001` be established authoritatively?
20. Can lock-related dimensions from `IFX-SESSION-005` be correlated authoritatively?

---

# 33. Source Validation Acceptance Criteria

The metric may become:

`SOURCE_VALIDATED`

only after:

- authoritative lock-wait source is identified;
- active-wait semantics are established;
- timing source is established;
- elapsed-time calculation semantics are documented;
- precision is understood;
- clock behavior is understood when relevant;
- aggregation rules are documented;
- scope is established;
- empty-population behavior is established;
- exact SQL/command is documented;
- permissions are known;
- collection cost is acceptable;
- relevant version behavior is documented.

---

# 34. Mock Validation Acceptance Criteria

The metric may become:

`MOCK_VALIDATED`

when:

- normalized scalar contract is approved;
- mock inputs exist;
- parser specification exists;
- parser is implemented;
- valid non-negative integer seconds are accepted;
- zero is preserved;
- lower subsequent values are accepted;
- malformed values fail;
- collection failure remains distinct from zero.

Mock validation does not establish real Informix lock timing semantics.

---

# 35. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Architectural metric:

`Maximum Lock Wait Time`

Current semantic:

`PROVISIONAL — AGE IN SECONDS OF THE OLDEST CURRENTLY ACTIVE LOCK WAIT`

Metric semantics:

`GAUGE`

Historical maximum:

`NO`

Monotonic:

`NO`

Normalized unit:

`SECONDS`

Normalized precision:

`WHOLE SECONDS — PROVISIONAL`

Cardinality:

`ONE VALUE PER INFORMIX INSTANCE`

Zabbix LLD:

`NO`

Candidate source:

`sysmaster`

Alternative supporting interface:

`onstat`

Authoritative timing representation:

`PENDING SOURCE VALIDATION`

Exact Informix source:

`PENDING SOURCE VALIDATION`

Exact SQL/command:

`PENDING SOURCE VALIDATION`

Relationship with LOCK-001:

`UNPROVEN`

Relationship with SESSION-005:

`UNPROVEN`

Mock inputs:

`AVAILABLE`

Parser implementation:

`IMPLEMENTED`

Mock validation:

`PASSED — 10/10`

Real Informix/AIX validation:

`PENDING`

---

# 36. Next Step

Validate `IFX-LOCK-002` against the real Informix/AIX environment when it becomes available.

Real source validation must establish the authoritative current lock-wait source, timing representation, elapsed-time semantics, precision, aggregation rules, empty-population behavior, collection cost and relationship with `IFX-LOCK-001`.

Until then, the metric remains:

`MOCK_VALIDATED`

---