# IFX-SESSION-005 — Waiting Threads by Reason

## 1. Purpose

This document defines the engineering contract for:

`IFX-SESSION-005 — Waiting Threads by Reason`

The metric represents the current number of Informix threads waiting for each distinct wait reason exposed by an authoritative Informix source.

The metric is dynamic and preserves the native wait-reason dimensionality provided by Informix.

---

# 2. Monitoring Domain

Domain:

`Connections, Sessions and Concurrency`

Metric ID:

`IFX-SESSION-005`

Metric name:

`Waiting Threads by Reason`

---

# 3. Architectural Objective

The metric shall answer both:

`HOW MANY THREADS ARE WAITING?`

and, through its dimension:

`WHY ARE THEY WAITING?`

The instance-level total is represented separately by:

`IFX-SESSION-004 — Waiting Threads Total`

This metric provides the diagnostic decomposition by wait reason.

---

# 4. Architectural Model

Conceptually:

```text
Informix thread states
        |
        +--> waiting thread
        |       |
        |       +--> reason A
        |       +--> reason B
        |       +--> reason C
        |       +--> ...
        |
        +--> non-waiting thread
```

The resulting monitoring model is:

```text
IFX-SESSION-004
Waiting Threads Total
        |
        +-- IFX-SESSION-005
            Waiting Threads by Reason
                 |
                 +-- reason A = N
                 +-- reason B = N
                 +-- reason C = N
                 +-- ...
```

---

# 5. Dynamic Metric Decision

Wait reasons shall not be statically enumerated in the monitoring architecture before real source validation.

The metric is:

`DYNAMIC`

New authoritative wait reasons may appear without requiring a new metric definition for each reason.

---

# 6. Candidate Source

Candidate interfaces:

`sysmaster / onstat`

Exact authoritative source:

`PENDING SOURCE VALIDATION`

Exact SQL or command:

`PENDING SOURCE VALIDATION`

---

# 7. Native Reason Preservation

The collection architecture shall preserve the native Informix wait-reason identity whenever technically possible.

The collector shall not arbitrarily transform multiple native reasons into broad categories such as:

```text
lock
io
condition
other
```

These names are examples only.

They are not approved Informix wait classes.

---

# 8. Stable Identity Preference

If Informix exposes both:

- a stable reason identifier;
- a human-readable reason description;

the preferred normalized model is:

```text
WAIT_REASON_ID
WAIT_REASON_NAME
COUNT
```

Example only:

```text
LCK|Lock wait|12
IO|I/O wait|7
COND|Condition wait|3
```

The actual identifiers and descriptions must come from the authoritative Informix source.

---

# 9. Identity Fallback

If Informix does not expose a stable wait-reason identifier, the native reason representation may become the discovery identity.

This decision requires source validation.

The collector shall not invent artificial identifiers merely to satisfy discovery.

---

# 10. Provisional Semantic

For mock validation:

`CURRENT NUMBER OF INFORMIX THREADS CLASSIFIED UNDER EACH AUTHORITATIVE WAIT REASON`

---

# 11. Metric Type

Type:

`GAUGE`

Each reason represents current state.

The metric is not:

- a cumulative wait-event counter;
- a historical count;
- a rate;
- a count of transitions into a wait state.

---

# 12. Normalized Unit

Normalized unit:

`THREADS`

Each discovered reason produces one current thread count.

---

# 13. Cardinality

Cardinality:

`DYNAMIC — N WAIT REASONS PER INFORMIX INSTANCE`

There may be:

```text
0..N
```

wait-reason dimensions at a collection instant.

The practical discovery behavior must be finalized during source validation.

---

# 14. Zabbix Discovery

Zabbix Low-Level Discovery:

`YES`

Preferred discovery dimension:

`WAIT_REASON_ID`

Optional human-readable dimension:

`WAIT_REASON_NAME`

Conceptual LLD macros:

```text
{#WAIT_REASON_ID}
{#WAIT_REASON_NAME}
```

Exact Zabbix implementation belongs to the template engineering phase.

---

# 15. Conceptual Zabbix Item

If a stable reason identifier exists, the conceptual item key is:

```text
ifx.thread.waiting[{#WAIT_REASON_ID}]
```

Example only:

```text
ifx.thread.waiting[LCK]
ifx.thread.waiting[IO]
ifx.thread.waiting[COND]
```

These identifiers are illustrative only.

---

# 16. Human-Readable Item Name

When a native description exists, a conceptual Zabbix item name may be:

```text
Waiting Threads — {#WAIT_REASON_NAME}
```

The stable identifier and human-readable presentation should remain separate whenever the authoritative source supports both.

---

# 17. Dataset Contract

Unlike `IFX-SESSION-004`, this metric does not use a single scalar contract.

The normalized collection result is a dataset.

Conceptually:

```text
WAIT_REASON_ID|WAIT_REASON_NAME|COUNT
```

Example only:

```text
LCK|Lock wait|12
IO|I/O wait|7
COND|Condition wait|3
```

---

# 18. Value Domain

For every discovered reason:

`COUNT`

must be a non-negative integer.

Valid examples:

```text
0
1
7
12
500
```

Invalid examples:

```text
-1
3.5
threads
```

---

# 19. Zero Semantics

A reason count of:

```text
0
```

is numerically valid.

However, source validation must determine whether zero-count reasons:

- remain present in the authoritative source;
- disappear when inactive;
- should remain discovered in Zabbix for a retention period.

These are discovery lifecycle concerns, not parser numeric-validation concerns.

---

# 20. Unknown Reasons

An unknown or previously unseen authoritative wait reason shall not automatically become:

`other`

The native reason shall be preserved whenever possible.

This protects diagnostic information and avoids silent semantic loss.

---

# 21. No Silent Grouping Rule

The collector shall not silently perform:

```text
native reason A \
native reason B  +--> synthetic category X
native reason C /
```

unless a future explicitly governed derived metric defines such grouping.

The raw native reason dimensions remain authoritative.

---

# 22. Duplicate Reason Rule

A normalized dataset shall contain at most one row for each discovery identity.

Duplicate `WAIT_REASON_ID` values are invalid unless source validation explicitly defines an aggregation rule before normalization.

The parser shall not silently resolve duplicate identities.

---

# 23. Relationship with SESSION-004

Related metric:

`IFX-SESSION-004 — Waiting Threads Total`

Conceptually, it may eventually be true that:

```text
SESSION-004 =
SUM(SESSION-005 reason counts)
```

This relationship is currently:

`UNPROVEN`

It shall not be assumed before source validation.

---

# 24. Why the Sum Is Not Yet Assumed

Source validation must determine whether:

- every waiting thread has a reason;
- reasons are mutually exclusive;
- one thread can have multiple reason representations;
- some waits are unclassified;
- internal threads are treated identically;
- total and dimensional sources have identical scope.

Until these properties are established, the total remains independently authoritative.

---

# 25. Relationship with Sessions

The metric may be correlated with:

`IFX-SESSION-001 — Total Connected Sessions`

and:

`IFX-SESSION-002 — Active Sessions`

No one-to-one relationship between sessions and threads is assumed.

---

# 26. Collection Method

Expected collection method:

`collector using authoritative Informix thread-state and wait-reason information`

The collection layer may need to:

1. obtain thread records;
2. identify waiting threads;
3. obtain their authoritative wait reason;
4. group by stable reason identity;
5. count threads per reason;
6. emit the normalized dataset.

Exact implementation remains pending source validation.

---

# 27. Collection Frequency

Recommended frequency:

`HIGH`

Wait reasons may be transient.

The final interval must balance diagnostic resolution against collection overhead.

---

# 28. Collection Cost

Current classification:

`UNKNOWN`

Real validation must establish collection cost and scalability relative to thread population.

Monitoring overhead remains a first-class acceptance criterion.

---

# 29. Discovery Lifecycle

Zabbix discovery must eventually define behavior for reasons that:

- newly appear;
- temporarily disappear;
- permanently disappear;
- change description while retaining identity.

Exact lost-resource retention behavior belongs to the Zabbix template phase.

---

# 30. Grafana

Grafana visualization:

`YES`

The dynamic dimensions should support visualizations such as:

```text
Waiting Threads by Reason

Lock-related reason       12
I/O-related reason         7
Condition-related reason   3
...
```

Actual labels shall come from validated native Informix reasons.

This supports correlation with:

- waiting threads total;
- sessions;
- locks;
- I/O;
- CPU;
- memory;
- checkpoints;
- SQL workload.

---

# 31. Collection Failure

Collection failure is different from:

`zero waiting reasons`

and from:

`reason count = 0`

Examples of collection failure include:

- Informix connection failure;
- SQL execution failure;
- command execution failure;
- permission failure;
- malformed dataset;
- duplicate discovery identity;
- invalid count.

Collection failure shall not be represented as an empty successful dataset.

---

# 32. Empty Dataset Semantics

A genuinely successful collection with no currently observable wait reasons may validly produce an empty dataset.

Therefore:

```text
successful empty dataset
```

and:

```text
collection failure
```

must remain distinguishable.

---

# 33. Mock Dataset Strategy

Mock validation shall test the normalized dynamic dataset contract without inventing real Informix wait classes.

Mock identifiers shall therefore be explicitly synthetic.

Example:

```text
REASON_A|Synthetic reason A|12
REASON_B|Synthetic reason B|7
REASON_C|Synthetic reason C|3
```

Synthetic mock identifiers do not imply actual Informix reason names.

---

# 34. Planned Mock Scenarios

The mock set shall include at least:

```text
normal
single-reason
zero-count
empty-success
new-reason
duplicate-reason
negative-count
decimal-count
malformed-row
execution-error
```

The dataset contract will be finalized in the parser specification before implementation.

---

# 35. Parser Responsibilities

The future parser shall:

- detect collection execution failure;
- parse the normalized dataset;
- validate row structure;
- validate discovery identities;
- validate non-negative integer counts;
- detect duplicate identities;
- preserve native reason identity;
- preserve native reason description;
- produce deterministic structured output suitable for the Zabbix collection/discovery layer.

---

# 36. Parser Non-Responsibilities

The parser shall not:

- invent wait reasons;
- rename native reasons arbitrarily;
- create broad synthetic categories;
- classify Informix thread states without a validated source contract;
- silently aggregate duplicate identities;
- derive SESSION-004;
- assume SESSION-004 equals the sum of reasons;
- generate alerts;
- define Zabbix lost-resource retention;
- convert collection failure into an empty successful dataset.

---

# 37. Source Validation Questions

Real Informix validation must answer at least:

1. Which authoritative source exposes thread wait reasons?
2. Which `sysmaster` object is relevant?
3. Which `onstat` representation is relevant?
4. Is there a stable wait-reason identifier?
5. Is there a human-readable description?
6. Are reason identifiers stable across engine runtime?
7. Are they stable across Informix versions?
8. Can one waiting thread expose more than one reason?
9. Are reasons mutually exclusive?
10. Can a waiting thread have no reason?
11. Are internal/system threads included?
12. Should any thread classes be excluded?
13. Can reasons appear and disappear dynamically?
14. Are zero-count reasons exposed?
15. Is source-side grouping possible?
16. What aggregation is authoritative?
17. What permissions are required?
18. What is the collection cost?
19. How does cost scale with thread population?
20. Are there important Informix-version differences?
21. Can SESSION-004 be proven equal to the sum of all SESSION-005 dimensions?

---

# 38. Source Validation Acceptance Criteria

The metric may become:

`SOURCE_VALIDATED`

only after:

- authoritative wait-reason source is identified;
- waiting semantics are established;
- reason identity semantics are established;
- reason descriptions are understood;
- dimensional cardinality is understood;
- duplicate behavior is understood;
- aggregation rules are documented;
- scope is established;
- exact SQL/command is documented;
- permissions are known;
- collection cost is acceptable;
- relevant version behavior is documented.

---

# 39. Mock Validation Acceptance Criteria

The metric may become:

`MOCK_VALIDATED`

when:

- normalized dataset contract is approved;
- mock datasets exist;
- parser specification exists;
- parser is implemented;
- valid dynamic dimensions are preserved;
- invalid counts fail;
- malformed rows fail;
- duplicate identities fail;
- successful empty dataset remains distinct from collection failure.

Mock validation does not establish real Informix wait-reason semantics.

---

# 40. Current Status

Current lifecycle state:

`MOCK_VALIDATED`

Architectural metric:

`Waiting Threads by Reason`

Current source status:

`PENDING SOURCE VALIDATION`

Candidate interfaces:

`sysmaster / onstat`

Current semantic:

`PROVISIONAL — CURRENT WAITING THREAD COUNT DIMENSIONED BY AUTHORITATIVE WAIT REASON`

Metric semantics:

`GAUGE`

Normalized unit:

`THREADS`

Cardinality:

`DYNAMIC`

Zabbix LLD:

`YES`

Preferred discovery identity:

`AUTHORITATIVE STABLE WAIT REASON ID — IF AVAILABLE`

Native reason preservation:

`REQUIRED`

Synthetic grouping:

`NOT ALLOWED AS AUTHORITATIVE DATA`

Relationship with SESSION-004 sum:

`UNPROVEN`

Exact Informix source:

`PENDING SOURCE VALIDATION`

Exact SQL/command:

`PENDING SOURCE VALIDATION`

Mock inputs:

`AVAILABLE`

Parser implementation:

`IMPLEMENTED`

Mock validation:

`PASSED — 10/10`

Real Informix/AIX validation:

`PENDING`

---

# 41. Next Step

Validate `IFX-SESSION-005` against the real Informix/AIX environment when it becomes available.

Real source validation must establish the authoritative wait-reason source, identity semantics, cardinality behavior, aggregation rules, collection cost and the relationship with `IFX-SESSION-004`.

Until then, the metric remains:

`MOCK_VALIDATED`

---
