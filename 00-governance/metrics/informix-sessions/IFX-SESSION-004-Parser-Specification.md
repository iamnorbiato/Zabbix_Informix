# IFX-SESSION-004 — Waiting Client Sessions Total — Parser Specification

## 1. Identity

| Field | Value |
| --- | --- |
| Metric ID | `IFX-SESSION-004` |
| Input type | Scalar Informix SQL result |
| Output type | One unsigned integer |
| Unit | Sessions |
| Lifecycle | `DEVELOPMENT_RUNTIME_VALIDATED` |

## 2. Source Contract

**Database: `sysmaster`**

The statement returns exactly one value: the number of qualifying client sessions for which at least one of `is_wlatch`, `is_wlock`, `is_wbuff`, `is_wckpt`, `is_wlogbuf`, or `is_wtrans` is `1`.

The source query must:

- exclude sessions with an empty `hostname`;
- exclude its own Informix session with `DBINFO('sessionid')`;
- use `CAST(COUNT(*) AS INT8)`.

## 3. Normalized Input

The parser receives one line containing a non-negative base-10 integer, optionally followed by the Informix UNLOAD delimiter:

```text
0|
17|
```

Leading and trailing horizontal whitespace may be removed before validation.

## 4. Accepted Values

Accepted value grammar:

```text
0|[1-9][0-9]*
```

Examples of valid input:

```text
0|
4|
120|
```

Examples of invalid input:

```text

4.0|
-1|
1e3|
4|extra
```

## 5. Output Contract

On success, write exactly one unsigned integer followed by one newline to standard output.

```text
4
```

The parser must not print Informix connection messages, diagnostics, labels, or additional rows to standard output.

## 6. Failure Contract

If query execution fails, no row is returned, more than one non-empty data row is returned, or the value violates the accepted grammar:

- return a non-zero exit status;
- write a concise diagnostic to standard error;
- write no metric value to standard output.

Failure is never normalized to `0`.

## 7. Semantics Boundary

The parser validates serialization only. It does not:

- decide whether a flag is operationally important;
- infer a thread wait from `systhreads.th_state`;
- sum SESSION-005 dimensions;
- create alerts or Zabbix discovery objects.

## 8. Relationship with IFX-SESSION-005

The output is a distinct-session count. A qualifying session contributes once even when more than one waiting flag is `1`.

Therefore the parser must not derive its output by summing dimensional values from `IFX-SESSION-005`.

## 9. Required Tests

- `0|` normalizes to `0`.
- A positive integer normalizes unchanged.
- Decimal input such as `4.0|` fails.
- Negative, non-numeric, blank, and multi-row input fail.
- A query failure emits no standard-output value.

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