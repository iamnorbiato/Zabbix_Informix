# IFX-LOCK-001 — Sessions Waiting for Locks

## 1. Purpose

This document defines the engineering contract for:

`IFX-LOCK-001 — Sessions Waiting for Locks`

The metric represents the current number of Informix sessions blocked while waiting for a lock.

The metric belongs to the lock contention domain and represents current blocking state rather than historical lock activity.

---

# 2. Monitoring Domain

Domain:

`Locks, Deadlocks and Contention`

Metric ID:

`IFX-LOCK-001`

Metric name:

`Sessions Waiting for Locks`

---

# 3. Architectural Objective

The metric shall answer:

`HOW MANY INFORMIX SESSIONS ARE CURRENTLY BLOCKED WAITING FOR A LOCK?`

It provides an instance-level indication of current lock contention.

---

# 4. Provisional Semantic

For mock validation:

`CURRENT NUMBER OF INFORMIX SESSIONS BLOCKED WAITING FOR A LOCK`

This semantic is provisional until validated against an authoritative Informix source.

---

# 5. Critical Entity Question

The catalog currently defines the monitored entity as:

`SESSION`

This must be validated.

Informix may expose lock wait information primarily through:

- sessions;
- threads;
- lock waiters;
- transaction structures;
- another internal representation.

The monitoring architecture shall not silently treat:

```text
session
thread
waiter
transaction
```

as equivalent entities.

---

# 6. Entity Preservation Rule

If real source validation proves that the authoritative primitive is not a session, the metric must return to architectural review before becoming `SOURCE_VALIDATED`.

The implementation shall not merely count threads or lock-wait structures and label the result as sessions without proving the relationship.

---

# 7. Candidate Source

Candidate interface:

`sysmaster`

Alternative supporting interface:

`onstat`

Exact authoritative source:

`PENDING SOURCE VALIDATION`

Exact SQL or command:

`PENDING SOURCE VALIDATION`

---

# 8. Source Preference

`sysmaster` is preferred if it exposes the required relationship using structured, stable and sufficiently low-cost data.

`onstat` may be used if it provides semantics unavailable or unsuitable through `sysmaster`.

The final choice requires real Informix validation.

---

# 9. Metric Type

Type:

`GAUGE`

The value represents current state at collection time.

It is not a cumulative lock-wait counter.

---

# 10. Normalized Unit

Provisional normalized unit:

`SESSIONS`

This unit remains subject to authoritative entity validation.

---

# 11. Cardinality

Cardinality:

`ONE VALUE PER INFORMIX INSTANCE`

The metric produces a single scalar count.

No resource dimension is currently required.

---

# 12. Zabbix Discovery

Zabbix Low-Level Discovery:

`NO`

This metric represents an instance-level aggregate.

Detailed lock waiter discovery, blocker relationships or lock objects would belong to separate diagnostic metrics if later governed.

---

# 13. Value Domain

The normalized value must be a non-negative integer.

Valid examples:

```text
0
1
7
25
500
```

Invalid examples:

```text
-1
2.5
sessions
```

---

# 14. Zero Semantics

Value:

```text
0
```

means:

`NO SESSIONS CURRENTLY OBSERVED AS BLOCKED WAITING FOR A LOCK`

Zero is a valid monitoring value.

It must not represent collection failure.

---

# 15. Collection Failure

Collection failure is different from zero.

Examples of collection failure include:

- Informix connection failure;
- SQL execution failure;
- command execution failure;
- permission failure;
- malformed result;
- unavailable authoritative source.

Collection failure shall not be normalized to:

```text
0
```

---

# 16. Collection Method

Expected collection method:

`SQL statement or collector against authoritative Informix lock-wait information`

The source query or collection layer owns:

- identifying lock waits;
- determining the authoritative monitored entity;
- applying validated filtering;
- eliminating duplicates where semantically required;
- producing the final aggregate count.

The scalar parser shall not infer lock relationships from arbitrary source rows.

---

# 17. Aggregation Ownership

If the authoritative source exposes multiple rows per session, thread, transaction or lock object, aggregation must occur according to validated source semantics before the scalar parser.

For example, the parser shall not independently assume that:

```text
number of source rows
=
number of waiting sessions
```

unless source validation explicitly proves that relationship.

---

# 18. Relationship with IFX-SESSION-005

Related metric:

`IFX-SESSION-005 — Waiting Client Sessions by Reason`

The fixed `LOCK` dimension of `IFX-SESSION-005` counts qualifying client sessions for which:

```text
syssessions.is_wlock = 1
```

It can be correlated with `IFX-LOCK-001`, which identifies sessions waiting for locks through lock metadata.

However, the metrics are not declared equivalent. Their source timing, visibility, filtering and aggregation can differ.

No arithmetic or identity relationship is assumed.

---

# 19. Relationship with IFX-SESSION-004

Related metric:

`IFX-SESSION-004 — Waiting Client Sessions Total`

`IFX-SESSION-004` counts distinct qualifying client sessions with one or more documented `syssessions` waiting flags set.

A lock-waiting session identified by `IFX-LOCK-001` can also contribute to `IFX-SESSION-004` through:

```text
syssessions.is_wlock = 1
```

No arithmetic relationship is assumed.

In particular:

```text
IFX-LOCK-001 <= IFX-SESSION-004
```

is not an approved invariant because the metrics can differ in source timing, filtering, visibility and aggregation.

---

# 20. Relationship with Lock Wait Duration

Related future metric:

`IFX-LOCK-002 — Maximum Lock Wait Time`

`IFX-LOCK-001` represents:

`HOW MANY`

while `IFX-LOCK-002` represents:

`HOW LONG`

Together they may distinguish situations such as:

```text
many short lock waits
few long lock waits
many long lock waits
```

No trigger thresholds are defined at this stage.

---

# 21. Collection Frequency

Recommended frequency:

`HIGH`

Lock waits may be transient and operationally significant.

The final interval must balance detection resolution against collection overhead.

---

# 22. Collection Cost

Current classification:

`LOW TO MEDIUM — PROVISIONAL`

Real source validation must establish actual collection cost.

Monitoring overhead remains a first-class acceptance criterion.

---

# 23. Trigger Potential

Trigger potential:

`YES`

Possible future conditions include:

- waiting session count above an operational threshold;
- sustained non-zero lock waiting;
- correlation with maximum lock wait duration.

Exact thresholds require runtime baseline validation.

---

# 24. Grafana

Grafana visualization:

`YES`

The metric can support visualization and correlation with:

- maximum lock wait time;
- deadlocks;
- connected sessions;
- active sessions;
- waiting client sessions;
- wait reasons;
- SQL workload;
- CPU;
- I/O.

---

# 25. Parser Contract

The normalized parser input shall be a single scalar value.

Example:

```text
12
```

The parser validates the normalized collection contract.

It does not perform lock-state discovery or source aggregation.

---

# 26. Parser Responsibilities

The future scalar parser shall:

- detect explicit collection failure;
- accept one normalized scalar value;
- trim permitted surrounding whitespace;
- validate a non-negative integer;
- preserve zero;
- emit the normalized value.

---

# 27. Parser Non-Responsibilities

The parser shall not:

- query Informix;
- identify lock waiters;
- determine blocker relationships;
- count arbitrary source rows;
- deduplicate sessions;
- convert threads into sessions;
- classify wait reasons;
- derive lock duration;
- generate alerts;
- convert collection failure into zero.

---

# 28. Mock Strategy

Mock validation shall validate only the normalized scalar contract.

It shall not simulate or invent Informix lock internals.

Planned scenarios:

```text
normal
zero
single
high
lower
empty
nonnumeric
negative
decimal
execution-error
```

---

# 29. Source Validation Questions

Real Informix validation must answer at least:

1. Which authoritative source exposes current lock waits?
2. Which `sysmaster` objects are involved?
3. Is `onstat` required for supporting validation?
4. What entity represents a lock waiter?
5. Can one session have more than one applicable `syssessions` waiting flag?
6. Can one session produce multiple lock-wait rows?
7. Can one transaction produce multiple wait records?
8. What identifies the blocked session?
9. What identifies the blocker?
10. Are internal/system sessions represented?
11. Should any entities be excluded?
12. Is the count naturally available or must it be aggregated?
13. What deduplication semantics are required?
14. What permissions are required?
15. What is the collection cost?
16. How does cost scale with sessions and locks?
17. Are there relevant Informix-version differences?
18. Can this metric be authoritatively represented in units of sessions?
19. What relationship exists with `IFX-SESSION-005` lock-related wait reasons?
20. What relationship exists with `IFX-SESSION-004`?

---

# 30. Source Validation Acceptance Criteria

The metric may become:

`SOURCE_VALIDATED`

only after:

- authoritative source is identified;
- monitored entity is proven;
- session semantics are established;
- lock-wait semantics are established;
- aggregation rules are documented;
- deduplication rules are documented;
- scope is established;
- exact SQL/command is documented;
- permissions are known;
- collection cost is acceptable;
- relevant version behavior is documented.

If the authoritative entity cannot be proven to represent sessions, the metric returns to architectural review before lifecycle advancement.

---

# 31. Mock Validation Acceptance Criteria

The metric may become:

`MOCK_VALIDATED`

when:

- normalized scalar contract is approved;
- mock inputs exist;
- parser specification exists;
- parser is implemented;
- valid non-negative integers are accepted;
- zero is preserved;
- malformed values fail;
- collection failure remains distinct from zero.

Mock validation does not establish real Informix lock semantics.

---

# 32. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Architectural metric:

`Sessions Waiting for Locks`

Current semantic:

`PROVISIONAL — CURRENT NUMBER OF INFORMIX SESSIONS BLOCKED WAITING FOR A LOCK`

Metric semantics:

`GAUGE`

Normalized unit:

`SESSIONS — PROVISIONAL`

Cardinality:

`ONE VALUE PER INFORMIX INSTANCE`

Zabbix LLD:

`NO`

Candidate source:

`sysmaster`

Alternative supporting interface:

`onstat`

Authoritative monitored entity:

`PENDING SOURCE VALIDATION`

Exact Informix source:

`PENDING SOURCE VALIDATION`

Exact SQL/command:

`PENDING SOURCE VALIDATION`

Relationship with SESSION-004:

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

# 33. Next Step

Validate `IFX-LOCK-001` against the real Informix/AIX environment when it becomes available.

Real source validation must establish the authoritative lock-wait source, prove the monitored entity, define aggregation and deduplication semantics, determine collection cost and establish the relationships with `IFX-SESSION-004` and `IFX-SESSION-005`.

Until then, the metric remains:

`MOCK_VALIDATED`

---