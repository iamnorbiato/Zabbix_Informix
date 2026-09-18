# IFX-HEALTH-003 — Collector Specification

## 1. Purpose

This document defines the collection and parsing behavior for:

`IFX-HEALTH-003 — Assert Failures`

Unlike `IFX-HEALTH-001` and `IFX-HEALTH-002`, this metric is based on a continuously growing log and therefore requires persistent collection state.

---

# 2. Source

Candidate source:

`Informix online message log`

The actual path shall eventually be obtained from the Informix `MSGPATH` configuration.

No production collector shall assume a fixed `online.log` path.

---

# 3. Event Marker

Current candidate assertion-failure marker:

```text id="swp19j"
Assert Failed:
```

The following marker shall not be counted:

```text id="m0p1ig"
Assert Warning:
```

Matching shall remain sufficiently specific to distinguish the two conditions.

---

# 4. Primary Output

The minimum collector shall return:

```text id="5it9ox"
number of newly observed assertion failures
```

Valid successful output:

```text id="k8w9te"
0
1
2
3
...
```

The output represents new events since the previously committed read position.

It does not represent the total number of assertion failures historically present in the file.

---

# 5. Collection State

The collector requires persistent state.

For the mock implementation, the minimum state shall contain:

```text id="88fx55"
log file identity
last successfully processed byte offset
```

Conceptually:

```text id="f8eqbb"
FILE_ID=<identity>
OFFSET=<byte-offset>
```

The exact implementation format may evolve after AIX validation.

---

# 6. State Commit Rule

Collection state shall only advance after the newly read log range has been successfully processed.

Conceptually:

```text id="mbyzvq"
read saved state
      │
      ▼
read new log range
      │
      ▼
parse successfully?
      │
      ├── NO ──> keep previous state
      │
      └── YES
             │
             ▼
        commit new offset
```

This prevents failed collection from silently skipping future processing of unread log content.

---

# 7. First Execution

If no previous state exists, the default production-oriented bootstrap behavior shall be:

```text id="a1s8kl"
save current EOF
return 0
```

Existing historical entries shall not generate new monitoring events.

Example:

```text id="t1lqv6"
online.log already contains 10 old Assert Failed entries

first collector execution
        │
        ├── OFFSET = current EOF
        └── output = 0
```

This behavior prevents alert storms when monitoring is first enabled.

---

# 8. Empty Existing File

If the file exists, is readable and is empty during first execution:

```text id="m8xxuw"
OFFSET=0
output=0
```

This is a successful bootstrap.

It is not a collection failure.

---

# 9. Normal Incremental Collection

Given:

```text id="9shbkd"
saved offset = N
current size > N
```

the collector shall process only bytes after `N`.

Conceptually:

```text id="lgmz7v"
0 ---------------- N ---------------- EOF
historical data     new data
                    ^^^^^^^^^^^^^^^^^
                    process only this
```

After successful processing:

```text id="s3rbyy"
OFFSET=current EOF
```

---

# 10. No New Content

If:

```text id="iz0rba"
saved offset == current size
```

the collector shall return:

```text id="wtc9dj"
0
```

and preserve the current state.

This represents successful collection with no new events.

---

# 11. Assertion Counting

Each newly encountered line containing the approved assertion-failure marker represents one event.

Example:

```text id="w7al2k"
Assert Failed: failure A
...
Assert Failed: failure B
```

Result:

```text id="ujfjzg"
2
```

Associated diagnostic lines shall not increment the event count.

---

# 12. Assert Warning

Input containing only:

```text id="dmb7jd"
Assert Warning:
```

shall produce:

```text id="q1rb4w"
0
```

`Assert Warning` must not match the `Assert Failed:` detection rule.

---

# 13. Mixed Content

Normal Informix messages, checkpoint messages, logical-log messages and diagnostic context may appear in the same newly read range.

Only independent approved assertion-failure markers increment the result.

---

# 14. Partial-Line Boundary

A byte offset may theoretically occur while a log write is incomplete.

The collector must avoid treating an incomplete trailing line as a complete event if the source may still be writing it.

For the initial mock implementation, input files are assumed to represent completed writes.

Production handling of partial trailing records remains subject to real-source validation.

---

# 15. File Truncation

If:

```text id="d0iz3i"
current file size < saved offset
```

the previous offset is no longer valid.

This condition shall be classified as:

```text id="tcd6gq"
LOG_RESET
```

The collector shall not:

- attempt to seek beyond EOF indefinitely;
- report old state as healthy without correction;
- automatically interpret truncation as an assertion failure.

For the initial mock architecture, safe recovery shall be:

```text id="btdn86"
establish current EOF as new baseline
return 0
commit new state
```

This intentionally avoids interpreting potentially historical content from the recreated file as new events.

---

# 16. File Replacement

If the path remains the same but file identity changes, the previous offset belongs to a different file.

This condition shall also be treated conceptually as:

```text id="5s0o94"
LOG_RESET
```

Initial recovery:

```text id="dgn4ao"
establish new file EOF
return 0
commit new identity and offset
```

The exact AIX-compatible file identity mechanism must be source validated.

---

# 17. File Identity

During Linux mock validation, file identity may be represented using filesystem metadata such as device/inode information.

This mechanism shall not automatically become the production AIX implementation.

The production mechanism must be validated against AIX filesystem behavior and available utilities.

---

# 18. Read Failure

If the log cannot be read because of:

- permission failure;
- missing file;
- filesystem error;
- invalid path;
- unexpected collector error;

the collector shall return a non-zero process exit status.

It shall not emit:

```text id="blfpi3"
0
```

as a valid metric result.

Existing state shall not advance.

---

# 19. State Read Failure

If persistent state exists but cannot be safely interpreted, the collector must not guess the previous offset.

The condition shall result in:

`COLLECTION_FAILURE`

The state shall not be silently overwritten unless an explicitly defined recovery procedure exists.

---

# 20. State Write Failure

If new log content is successfully parsed but the new state cannot be persisted, the collection cycle shall be considered unsuccessful.

Reason:

Returning the event count while failing to save the offset could cause the same assertion failures to be emitted again on the next execution.

Therefore:

```text id="3t6n9b"
parse success
+
state commit failure
=
COLLECTION_FAILURE
```

---

# 21. Atomic State Update

The future collector should avoid partially written state.

Conceptually:

```text id="3vrf9f"
write temporary state
        │
        ▼
successful write
        │
        ▼
replace committed state
```

The exact mechanism shall remain compatible with AIX and the selected filesystem.

---

# 22. Concurrent Execution

Two collector instances must not independently process and commit the same state file at the same time.

Concurrent execution could produce:

- duplicated events;
- lost offsets;
- state regression;
- corrupted state.

Production implementation therefore requires protection against overlapping execution.

The exact locking mechanism remains deferred until AIX capabilities are validated.

Mock implementation may initially assume a single collector process.

---

# 23. State Scope

State must be unique per monitored Informix instance and source log.

Conceptually:

```text id="8y71cg"
<instance>/<metric>/<state>
```

A state file belonging to one Informix instance must never control another instance's log position.

The final state directory convention remains deferred.

---

# 24. Event Context

The minimum mock collector only needs to return the new event count.

However, the collection architecture should preserve the possibility of later extracting:

- source timestamp;
- assertion description;
- diagnostic file reference;
- thread/session information;
- source file and line.

These additions shall not alter the basic event-count semantics.

---

# 25. Historical Scan

Historical scanning is explicitly different from continuous monitoring.

The normal collector shall operate incrementally.

A future diagnostic utility may intentionally scan an entire log, but that behavior shall not be silently incorporated into the production monitoring collector.

---

# 26. Mock Scenarios

The current mock set includes:

```text id="jst4sz"
initial-clean.log
one-assert.log
multiple-asserts.log
assert-warning.log
mixed-events.log
empty.log
truncated.log
read-error.txt
incremental-step-1.log
incremental-step-2.log
```

---

# 27. Stateless Parsing Expectations

When evaluating complete mock content independently for parser verification:

| Mock | Assertion Markers |
|---|---:|
| `initial-clean.log` | `0` |
| `one-assert.log` | `1` |
| `multiple-asserts.log` | `2` |
| `assert-warning.log` | `0` |
| `mixed-events.log` | `1` |
| `empty.log` | `0` |

This stateless count is useful for validating event recognition.

It is not sufficient to validate the complete collector lifecycle.

---

# 28. Stateful Incremental Scenario

Initial source:

```text id="df36ai"
incremental-step-1.log
```

First execution:

```text id="fnms8o"
state does not exist
```

Expected:

```text id="uj4imf"
output = 0
offset = EOF of incremental-step-1.log
```

Then the source evolves to the content represented by:

```text id="b32z8h"
incremental-step-2.log
```

The second file contains all original content plus one new assertion failure.

Second execution shall:

```text id="y9prwh"
start from previously saved offset
process appended content only
detect 1 Assert Failed event
output 1
commit new EOF
```

A third execution with no further changes shall return:

```text id="40lgpq"
0
```

This sequence is the principal stateful mock-validation scenario.

---

# 29. Truncation Scenario

Given an existing saved offset larger than:

```text id="cjz3ru"
truncated.log
```

current size, the collector shall detect:

```text id="66sdxn"
LOG_RESET
```

Expected mock behavior:

```text id="izbsvw"
output = 0
new offset = current EOF
```

The old offset shall be replaced only after successful reset handling.

---

# 30. Collection Failure Scenario

`read-error.txt` describes a simulated collection failure.

Expected behavior:

```text id="l3kkgz"
no metric value
non-zero process exit
state unchanged
```

The scenario file itself shall not be interpreted as Informix log content.

---

# 31. Collector Contract

Conceptually:

```text id="5i1mge"
INPUT:
    log path
    state path

PROCESS:
    validate source
    read state
    determine file continuity
    determine unread range
    parse new content
    count new assertion failures
    commit state

OUTPUT:
    new_assert_failure_count
```

Successful process exit:

```text id="lbbdy9"
0
```

Collection failure process exit:

```text id="xflkxh"
non-zero
```

---

# 32. Zero Contract

The following distinction is mandatory:

```text id="l3o69n"
stdout "0" + exit 0
```

means:

```text id="0e0fs7"
collection succeeded and no new assertion failures were detected
```

Whereas:

```text id="hjz8qs"
no metric value + non-zero exit
```

means:

```text id="axwy79"
collection failed
```

These conditions must never be conflated.

---

# 33. Mock Acceptance Criteria

The mock collector shall demonstrate:

1. first execution establishes EOF without reporting historical events;
2. new appended assertion failure is detected exactly once;
3. repeated execution without changes returns `0`;
4. multiple new assertion failures are counted independently;
5. `Assert Warning` is not counted;
6. normal messages are ignored;
7. empty readable content is valid;
8. truncation is detected and safely re-baselined;
9. source read failure does not become `0`;
10. state read failure does not become `0`;
11. state commit failure does not report successful collection;
12. failed collection does not advance state.

---

# 34. Current Status

Specification:

`APPROVED`

Mock inputs:

`AVAILABLE`

Stateful collector:

`IMPLEMENTED`

State persistence:

`IMPLEMENTED`

Mock validation:

`PASSED — 11/11`

Metric lifecycle state:

`MOCK_VALIDATED`

Real environment validation:

`PENDING`

---

# 35. Next Step

After approval of this specification, implement the minimum stateful KornShell collector for `IFX-HEALTH-003`.

The implementation shall initially target the Linux mock environment while preserving portability considerations for the future IBM AIX runtime.

No Zabbix template implementation shall begin as part of this step.