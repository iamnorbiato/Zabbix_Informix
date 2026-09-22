# IFX-SESSION-002 — Sessions in Read Call — Parser Specification

## 1. Purpose

This document defines the runtime normalization contract for:

`IFX-SESSION-002 — Sessions in Read Call`

The collector executes the approved `sysmaster:syssessions` SQL statement and
emits one normalized session count.

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

---

## 2. Source Contract

Database: `sysmaster`

Table: `syssessions`

The SQL source counts qualifying client sessions where:

```sql
BITAND(state, 32) = 32
```

Bit `32` is the documented `In a read call` flag. The collector must not
reinterpret this as active SQL execution or generic session activity.

---

## 3. Input Contract

`ifx_db_execute` unloads one scalar, using the project standard trailing field
delimiter:

```text
0|
```

The collector accepts exactly one record with exactly two fields split by `|`:

1. a non-negative integer value;
2. an empty unload terminator field.

Examples of valid source output:

```text
0|
18|
```

---

## 4. Output Contract

Successful normalized output is exactly one non-negative integer followed by a
newline:

```text
18
```

The collector must not emit Informix connection messages, labels, blank lines,
diagnostic text, or a trailing delimiter to standard output.

---

## 5. Validity Rules

The collector must reject:

- command failure from `ifx_db_execute`;
- empty output;
- more than one record;
- a missing or non-empty unload terminator;
- decimal, signed, alphabetic, or whitespace-padded scalar values;
- more than one value field.

`0` is valid and means no qualifying client session was observed in a read
call.

---

## 6. Failure Contract

Any invalid input must:

1. write a concise diagnostic to standard error;
2. return non-zero;
3. emit no numeric value to standard output.

Collection failure must never be normalized to `0`.

---

## 7. Collector Responsibilities

The collector shall:

1. source the common Informix database library;
2. execute the versioned statement against `sysmaster`;
3. validate the strict one-scalar unload contract;
4. emit the normalized integer;
5. preserve a meaningful non-zero failure status.

The collector shall not:

- classify thread states;
- inspect individual session rows;
- change the SQL definition of `In a read call`;
- calculate a rate, total, peak, or alert threshold;
- convert errors into zero.

---

## 8. Zabbix Contract

Key: `ifx.session.in_read_call`

Type: Zabbix Agent (active)

Value type: Numeric (unsigned)

Units: `sessions`

Update interval: `1m`

Timeout: `30s`

The launcher must obtain all environment and connection settings from the
portable deployment runtime environment. No source-checkout path is permitted
at runtime.

---

## 9. Validation Lifecycle

`DEVELOPMENT_RUNTIME_VALIDATED` records successful SQL statement, strict scalar collector, installed launcher, Zabbix Agent active key, template item, exported template, and uninstall/reinstall lifecycle validation in the Linux development topology.

Target Informix/AIX validation remains pending.