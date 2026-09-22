# IFX-SESSION-005 — Waiting Client Sessions by Reason — Parser Specification

## 1. Identity

| Field | Value |
| --- | --- |
| Metric ID | `IFX-SESSION-005` |
| Input type | Fixed six-row Informix SQL dataset |
| Output type | Six normalized unsigned integer dimensions |
| Unit | Sessions |
| Lifecycle | `DEVELOPMENT_RUNTIME_VALIDATED` |

## 2. Fixed Dimension Contract

The successful dataset contains each dimension exactly once:

| ID | Source flag |
| --- | --- |
| `LATCH` | `is_wlatch` |
| `LOCK` | `is_wlock` |
| `BUFFER` | `is_wbuff` |
| `CHECKPOINT` | `is_wckpt` |
| `LOG_BUFFER` | `is_wlogbuf` |
| `TRANSACTION` | `is_wtrans` |

The parser shall reject an unknown ID, a missing expected ID, or a duplicate ID. It shall not create dimensions dynamically.

## 3. Input Dataset

Each row has exactly three pipe-delimited fields:

```text
DIMENSION_ID|DISPLAY_NAME|COUNT
```

Example:

```text
LATCH|Waiting client sessions - latch|0
LOCK|Waiting client sessions - lock|1
BUFFER|Waiting client sessions - buffer|0
CHECKPOINT|Waiting client sessions - checkpoint|0
LOG_BUFFER|Waiting client sessions - log buffer|0
TRANSACTION|Waiting client sessions - transaction|0
```

## 4. Field Validation

- `DIMENSION_ID` must be one of the six exact IDs.
- `DISPLAY_NAME` must match the approved fixed name for its ID.
- `COUNT` must match `0|[1-9][0-9]*`.
- Whitespace around fields may be removed before comparison.
- Decimal values, negative values, exponent notation, embedded delimiters, blank fields, and additional fields are invalid.

## 5. Atomic Success Rule

The collector succeeds only if all six required dimensions are present exactly once and all values validate. It must then write the normalized six-row dataset to standard output in a deterministic order.

Recommended output order:

```text
LATCH
LOCK
BUFFER
CHECKPOINT
LOG_BUFFER
TRANSACTION
```

## 6. Failure Contract

On source execution failure or contract violation:

- return non-zero;
- write one concise diagnostic to standard error;
- write no partial data to standard output.

A partial dataset is not a successful zero-value collection.

## 7. Parser Responsibilities

- validate all source rows;
- enforce fixed identities and deterministic output;
- preserve zero counts;
- prevent partial or ambiguous Zabbix ingestion.

## 8. Parser Non-Responsibilities

The parser does not:

- infer wait state from `systhreads.th_state`;
- claim that the display IDs are a native Informix reason taxonomy;
- sum the six dimensions to generate SESSION-004;
- create discovery objects, triggers, or dashboards.

## 9. Required Tests

- Full six-row all-zero dataset succeeds.
- The controlled `LOCK=1` dataset succeeds.
- Each missing dimension fails.
- Each duplicate and unknown dimension fails.
- Decimal, negative, blank, and non-numeric counts fail.
- Extra field, malformed delimiter, and query failure fail without partial output.

## 10. Development Runtime Validation

The scalar collector was implemented and validated in the Linux development topology.

The validation covered:

- execution of the `sysmaster:syssessions` source statement;
- strict acceptance of one non-negative integer;
- repository collector execution;
- installed parameterized launcher execution;
- Zabbix Agent key `ifx.session.waiting_client_sessions`;
- Zabbix active item and exported template definition;
- uninstall and reinstall lifecycle.

The validated runtime value was:

```text
0
```
The parser continues to reject invalid, decimal, negative, blank and multi-row scalar input. Target Informix/AIX validation remains pending.