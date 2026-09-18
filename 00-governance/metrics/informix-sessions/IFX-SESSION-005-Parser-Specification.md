# IFX-SESSION-005 — Waiting Threads by Reason — Parser Specification

## 1. Purpose

This document defines the parser contract for:

`IFX-SESSION-005 — Waiting Threads by Reason`

The parser validates and normalizes an already collected wait-reason dataset representing the current number of Informix threads waiting under each authoritative wait reason.

Unlike the previous session metrics, this parser handles a dynamic multidimensional dataset rather than a single scalar.

---

# 2. Architectural Metric

Metric:

`Waiting Threads by Reason`

Related aggregate metric:

`IFX-SESSION-004 — Waiting Threads Total`

The metric provides the diagnostic reason dimension associated with current waiting threads.

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

Each normalized row represents:

`CURRENT NUMBER OF INFORMIX THREADS CLASSIFIED UNDER ONE AUTHORITATIVE WAIT REASON`

The real wait-reason taxonomy remains pending source validation.

---

# 5. Metric Type

Metric type:

`GAUGE`

Each reason count represents current state.

The values are not cumulative wait-event counters.

---

# 6. Normalized Unit

Unit:

`THREADS`

---

# 7. Cardinality

Cardinality:

`DYNAMIC`

A successful collection may contain:

```text
0..N wait reasons
```

The number of rows may change between collections.

---

# 8. Normalized Input Dataset

The parser receives one input file.

For successful non-empty collection, every row shall use:

```text
WAIT_REASON_ID|WAIT_REASON_NAME|COUNT
```

Example using synthetic mock identities:

```text
REASON_A|Synthetic reason A|12
REASON_B|Synthetic reason B|7
REASON_C|Synthetic reason C|3
```

These identifiers and names are mock-only values.

They do not define actual Informix wait reasons.

---

# 9. Field Contract

Every successful non-empty row contains exactly three fields:

```text
field 1 = WAIT_REASON_ID
field 2 = WAIT_REASON_NAME
field 3 = COUNT
```

No additional fields are permitted by the current normalized contract.

---

# 10. WAIT_REASON_ID

`WAIT_REASON_ID` represents the discovery identity.

For mock validation it must:

- exist;
- be non-empty;
- contain no field delimiter;
- be unique within the dataset.

Example:

```text
REASON_A
```

The final identity semantics remain pending source validation.

---

# 11. WAIT_REASON_NAME

`WAIT_REASON_NAME` represents the human-readable native reason description when available.

For the current mock contract it must:

- exist;
- be non-empty;
- occupy exactly one field.

Example:

```text
Synthetic reason A
```

The parser shall preserve the description.

It shall not classify or rename it.

---

# 12. COUNT

`COUNT` represents the current number of threads classified under the reason.

It must be a non-negative integer.

Valid examples:

```text
0
1
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

# 13. Zero Count

A row containing:

```text
REASON_A|Synthetic reason A|0
```

is valid.

The parser shall preserve:

```text
0
```

Whether zero-count reasons should remain discoverable operationally belongs to source validation and Zabbix template lifecycle design.

---

# 14. Successful Empty Dataset

An empty input file may represent a successful collection containing no currently observable wait reasons.

Input:

```text
<empty file>
```

Expected semantic:

`SUCCESSFUL EMPTY DATASET`

This is not collection failure.

---

# 15. Execution Failure

An explicit execution-error input such as:

```text
EXIT_CODE=1
STDOUT=
STDERR=SQL execution failed
```

represents:

`COLLECTION_FAILURE`

It shall not be interpreted as an empty successful dataset.

---

# 16. Critical Empty-vs-Failure Rule

The parser must preserve this distinction:

```text
empty file
    =
successful collection with zero discovered reasons

EXIT_CODE != 0
    =
collection failure
```

This distinction is mandatory.

---

# 17. Duplicate Discovery Identity

Within one dataset, `WAIT_REASON_ID` must be unique.

Input:

```text
REASON_A|Synthetic reason A|12
REASON_A|Synthetic reason A|3
```

is invalid.

The parser shall fail.

It shall not:

- sum the values;
- choose the first;
- choose the last;
- silently rename one identity.

---

# 18. New Dynamic Reason

A previously unseen valid reason is accepted without code changes.

Example:

```text
REASON_NEW|Synthetic newly discovered reason|4
```

is valid.

This behavior is fundamental to the dynamic metric architecture.

---

# 19. Malformed Rows

Every non-empty successful row must contain exactly three fields.

Example:

```text
REASON_A|Synthetic reason A
```

is invalid.

Rows with more than three fields are also invalid under the current contract.

---

# 20. Whitespace

Leading and trailing whitespace around individual fields may be removed.

For example:

```text
 REASON_A | Synthetic reason A | 12
```

may normalize to:

```text
REASON_A|Synthetic reason A|12
```

Whitespace internal to `WAIT_REASON_NAME` shall be preserved.

---

# 21. Delimiter

Normalized field delimiter:

```text
|
```

The current mock contract does not permit an unescaped `|` inside:

- `WAIT_REASON_ID`;
- `WAIT_REASON_NAME`.

If the authoritative Informix source can produce this character inside native reason data, escaping or an alternative serialization format must be addressed during source validation before operational implementation.

---

# 22. Deterministic Output

For mock validation, successful non-empty output shall preserve the normalized row order supplied by the collection layer.

The parser shall not independently sort wait reasons.

Reason ordering has no monitoring semantic.

This rule avoids introducing unnecessary parser behavior before the authoritative source is known.

---

# 23. Output Contract

For a successful non-empty dataset, stdout shall contain the validated normalized rows.

Example input:

```text
REASON_A|Synthetic reason A|12
REASON_B|Synthetic reason B|7
REASON_C|Synthetic reason C|3
```

Expected stdout:

```text
REASON_A|Synthetic reason A|12
REASON_B|Synthetic reason B|7
REASON_C|Synthetic reason C|3
```

Return code:

```text
0
```

---

# 24. Successful Empty Output Contract

For a successful empty dataset:

```text
stdout = empty
stderr = empty
return code = 0
```

This contract is intentionally different from collection failure.

---

# 25. Failure Output Contract

On failure:

```text
stdout = empty
stderr = diagnostic message
return code != 0
```

No partial dataset shall be emitted.

If any row is invalid, the entire dataset validation fails.

---

# 26. Atomic Dataset Rule

Validation is atomic.

The parser shall validate the complete dataset before emitting normalized metric data.

For example:

```text
REASON_A|Synthetic reason A|12
REASON_B|Synthetic reason B|-1
REASON_C|Synthetic reason C|3
```

shall result in:

`COLLECTION_FAILURE`

The valid rows shall not be emitted independently.

This prevents Zabbix from receiving a partially valid dimensional snapshot.

---

# 27. Parser Responsibilities

The parser shall:

1. validate invocation;
2. validate input readability;
3. detect explicit source execution failure;
4. distinguish successful empty dataset from collection failure;
5. parse every non-empty row;
6. require exactly three fields;
7. trim permitted surrounding field whitespace;
8. require non-empty `WAIT_REASON_ID`;
9. require non-empty `WAIT_REASON_NAME`;
10. validate `COUNT` as a non-negative integer;
11. detect duplicate `WAIT_REASON_ID`;
12. preserve native reason identity;
13. preserve native reason description;
14. preserve input row order;
15. validate the complete dataset before emitting output;
16. emit the normalized dataset only after complete validation succeeds.

---

# 28. Parser Non-Responsibilities

The parser shall not:

- identify the final Informix source;
- execute the final SQL or command;
- determine which Informix threads are waiting;
- invent wait reasons;
- invent reason identifiers;
- rename native reasons;
- create synthetic operational categories;
- group multiple reasons;
- aggregate duplicate reason identities;
- calculate `IFX-SESSION-004`;
- assume `SESSION-004` equals the sum of reasons;
- maintain reason history;
- define Zabbix lost-resource behavior;
- generate alerts;
- convert collection failure into an empty dataset.

---

# 29. Processing Order

The parser shall process input in this order:

```text
validate invocation
        ↓
validate input readability
        ↓
detect explicit execution failure
        ↓
determine whether dataset is empty
        |
        +-- empty --> successful empty dataset
        |
        +-- non-empty
                ↓
        parse complete dataset
                ↓
        validate exactly three fields per row
                ↓
        trim permitted field whitespace
                ↓
        validate reason ID
                ↓
        validate reason name
                ↓
        validate non-negative count
                ↓
        validate unique reason IDs
                ↓
        complete validation successfully
                ↓
        emit entire normalized dataset
```

---

# 30. Zabbix LLD Boundary

The normalized parser output is an intermediate collection contract.

The parser does not need to generate final Zabbix LLD JSON during this mock-validation stage.

Conceptually, a later Zabbix integration layer may transform:

```text
REASON_A|Synthetic reason A|12
REASON_B|Synthetic reason B|7
```

into discovery/item structures using macros such as:

```text
{#WAIT_REASON_ID}
{#WAIT_REASON_NAME}
```

Separating normalized collection data from Zabbix-specific serialization keeps collection logic independent from monitoring-platform representation.

---

# 31. Conceptual Zabbix Mapping

If source validation confirms stable reason identifiers, a future mapping may use:

```text
ifx.thread.waiting[{#WAIT_REASON_ID}]
```

with a human-readable item name such as:

```text
Waiting Threads — {#WAIT_REASON_NAME}
```

Exact Zabbix implementation is outside this parser specification.

---

# 32. Mock Dataset

Mock directory:

`04-mocks/informix-sessions/IFX-SESSION-005/`

Cases:

| Mock | Expected Result |
|---|---|
| `normal.txt` | success — 3 preserved rows |
| `single-reason.txt` | success — 1 preserved row |
| `zero-count.txt` | success — count `0` preserved |
| `empty-success.txt` | success — empty output |
| `new-reason.txt` | success — dynamic new reason preserved |
| `duplicate-reason.txt` | failure |
| `negative-count.txt` | failure |
| `decimal-count.txt` | failure |
| `malformed-row.txt` | failure |
| `execution-error.txt` | failure |

---

# 33. Mock Acceptance Criteria

Mock validation passes only when all 10 scenarios behave exactly as defined.

Specifically:

```text
normal             -> rc=0, exact normalized dataset
single-reason      -> rc=0, exact normalized dataset
zero-count         -> rc=0, zero preserved
empty-success      -> rc=0, stdout empty
new-reason         -> rc=0, new identity preserved

duplicate-reason   -> rc!=0, stdout empty
negative-count     -> rc!=0, stdout empty
decimal-count      -> rc!=0, stdout empty
malformed-row      -> rc!=0, stdout empty
execution-error    -> rc!=0, stdout empty
```

Expected runner result:

```text
PASS: 10
FAIL: 0
```

---

# 34. Source Validation Requirements

Before operational implementation, real Informix validation must establish:

- authoritative thread-state source;
- authoritative wait-reason source;
- waiting-state semantics;
- stable reason identity availability;
- reason-description semantics;
- identity stability;
- reason cardinality;
- duplicate behavior;
- reason mutual exclusivity;
- unclassified wait behavior;
- internal/system-thread handling;
- zero-reason behavior;
- exact aggregation rules;
- exact SQL or command;
- required permissions;
- collection cost;
- scalability;
- relevant Informix version differences.

---

# 35. Relationship Validation with SESSION-004

Real validation must determine whether:

```text
IFX-SESSION-004
=
SUM(all IFX-SESSION-005 reason counts)
```

is authoritative.

Until proven, this relationship remains:

`UNPROVEN`

The parser shall not enforce it.

---

# 36. Serialization Review Requirement

The pipe-delimited representation is the normalized mock contract.

Before operational implementation, source validation must confirm that authoritative reason identities and descriptions can be represented safely by this format.

If native values can contain the delimiter or other problematic characters, the serialization contract shall be reviewed before:

`COLLECTION_VALIDATED`

No lossy escaping shall be introduced silently.

---

# 37. Lifecycle Advancement

Successful mock validation permits:

```text
DEFINED
   ↓
MOCK_VALIDATED
```

It does not permit:

`SOURCE_VALIDATED`

or:

`COLLECTION_VALIDATED`

Real Informix/AIX validation remains mandatory.

---

# 38. Current Status

Specification:

`APPROVED`

Architectural metric:

`Waiting Threads by Reason`

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

Normalized dataset:

`WAIT_REASON_ID|WAIT_REASON_NAME|COUNT`

Zabbix LLD:

`YES — FUTURE INTEGRATION LAYER`

Preferred discovery identity:

`AUTHORITATIVE STABLE WAIT REASON ID — IF AVAILABLE`

Native reason preservation:

`REQUIRED`

Synthetic grouping:

`NOT ALLOWED AS AUTHORITATIVE DATA`

Successful empty dataset:

`VALID`

Duplicate discovery identity:

`INVALID`

Partial dataset emission:

`NOT ALLOWED`

Relationship with SESSION-004 sum:

`UNPROVEN`

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

# 39. Next Step

Validate the metric and parser contract against the real Informix/AIX environment when it becomes available.

Source validation must confirm that the authoritative wait-reason representation is compatible with the normalized dataset contract or identify any required contract revision before collection validation.

Until then:

`IFX-SESSION-005 = MOCK_VALIDATED`

----