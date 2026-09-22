# IFX-SESSION-005 — Waiting Client Sessions by Reason

## 1. Identity

| Field | Value |
| --- | --- |
| Metric ID | `IFX-SESSION-005` |
| Name | Waiting Client Sessions by Reason |
| Domain | Informix Sessions and Concurrency |
| Type | Dimensional current gauges |
| Unit | Sessions |
| Scope | One Informix instance |
| Lifecycle | `DEVELOPMENT_RUNTIME_VALIDATED` |

## 2. Monitoring Objective

Expose the current number of qualifying client sessions for each documented
`syssessions` waiting flag. The metric is a fixed six-dimension diagnostic
dataset, not a dynamic wait-reason discovery model.

## 3. Authoritative Development Source

**Database: `sysmaster`**

| Dimension ID | Display name | `syssessions` condition |
| --- | --- | --- |
| `LATCH` | Waiting client sessions - latch | `is_wlatch = 1` |
| `LOCK` | Waiting client sessions - lock | `is_wlock = 1` |
| `BUFFER` | Waiting client sessions - buffer | `is_wbuff = 1` |
| `CHECKPOINT` | Waiting client sessions - checkpoint | `is_wckpt = 1` |
| `LOG_BUFFER` | Waiting client sessions - log buffer | `is_wlogbuf = 1` |
| `TRANSACTION` | Waiting client sessions - transaction | `is_wtrans = 1` |

The stable dimension IDs are project-defined labels for documented source flags.
They do not claim to be an Informix native reason taxonomy beyond the exact
flag condition shown above.

## 4. Required Dataset Contract

Every successful collection returns exactly six rows, including dimensions with
zero values:

```text
LATCH|Waiting client sessions - latch|0
LOCK|Waiting client sessions - lock|0
BUFFER|Waiting client sessions - buffer|0
CHECKPOINT|Waiting client sessions - checkpoint|0
LOG_BUFFER|Waiting client sessions - log buffer|0
TRANSACTION|Waiting client sessions - transaction|0
```

Each count applies the client-session boundary of IFX-SESSION-004: non-empty
`hostname` and exclusion of the collector `DBINFO('sessionid')`.

## 5. Validation Evidence

The development schema exposes all six source fields. A controlled lock wait
proved that a blocked client session has `is_wlock = 1` and correlates with
`syslocks.waiter`.

The remaining dimensions are documented and structurally validated. Controlled
event exercises for their individual flags remain pending.

## 6. Value Semantics

| Value | Meaning |
| --- | --- |
| `0` | No qualifying client session matches that exact flag condition. |
| Positive integer | Number of qualifying client sessions matching that exact flag condition. |
| Missing dimension or malformed dataset | Collection failure, not zero. |

## 7. Relationship with IFX-SESSION-004

SESSION-004 counts distinct qualifying client sessions with one or more flags
set. SESSION-005 counts a session once per matching flag.

The following equality is prohibited unless future controlled validation proves
flag exclusivity:

```text
IFX-SESSION-004 = SUM(IFX-SESSION-005 dimensions)
```

## 8. Relationship with Locks

The `LOCK` dimension supports correlation with IFX-LOCK-001, but the two
metrics are not equivalent. `syslocks` and `syssessions` can have different
timing, visibility, and filtering behavior.

## 9. Implemented Zabbix Contract

Raw master key:

`ifx.session.waiting_client_sessions_by_reason.raw`

The active raw item receives the fixed six-row dataset. Six Numeric (unsigned)
dependent items, with unit `sessions`, extract the dimension values through
regular-expression preprocessing:

- `ifx.session.waiting_client_sessions.latch`
- `ifx.session.waiting_client_sessions.lock`
- `ifx.session.waiting_client_sessions.buffer`
- `ifx.session.waiting_client_sessions.checkpoint`
- `ifx.session.waiting_client_sessions.log_buffer`
- `ifx.session.waiting_client_sessions.transaction`

No low-level discovery, item prototypes, or dynamic dimensions are used.

## 10. Runtime Validation

The Linux development topology validated the SQL dataset, strict six-dimension
collector, parameterized launcher, Zabbix Agent active key, raw master item,
six dependent numeric items, exported template definition, and
uninstall/reinstall lifecycle. All six dependent items returned `0` without
preprocessing errors.

## 11. Target Validation

Before target/AIX rollout, validate the six columns, controlled behavior of all
applicable flags, full-dataset collection cost, and correlation with
operational lock incidents.
