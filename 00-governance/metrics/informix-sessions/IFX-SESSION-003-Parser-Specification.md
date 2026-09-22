# IFX-SESSION-003 — Weekly Peak Concurrent Physical Connections — Parser Specification

## 1. Purpose

This document defines the runtime normalization contract for:

`IFX-SESSION-003 — Weekly Peak Concurrent Physical Connections`

The collector executes the approved `sysmaster:sysfeatures` statement and
normalizes the newest weekly `max_conns` high-water value.

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

---

## 2. Source Contract

Database: `sysmaster`

View: `sysfeatures`

Column: `max_conns`

The statement selects exactly one most-recent non-null weekly value, ordered by
`year DESC, week DESC`.

The collector must not calculate a peak from its own historical executions or
from Zabbix history.

---

## 3. Input Contract

`ifx_db_execute` unloads exactly one scalar with the project trailing field
delimiter:

```text
6|
```

The collector accepts exactly one record with:

1. one non-negative integer value;
2. one empty unload terminator field.

---

## 4. Output Contract

The normalized output is exactly one non-negative integer followed by a
newline:

```text
6
```

No labels, dates, weeks, delimiters, Informix connection messages, or blank
lines may appear on standard output.

---

## 5. Validity and Failure Rules

The collector must fail, without numeric output, on:

- `ifx_db_execute` failure;
- no row returned by `sysfeatures`;
- empty output;
- more than one record;
- missing or non-empty unload terminator;
- signed, decimal, alphabetic, or whitespace-padded values.

Failure must never become `0`.

---

## 6. Collector Responsibilities

The collector shall:

1. source the common Informix database library;
2. execute the versioned statement against `sysmaster`;
3. validate the strict scalar unload contract;
4. output the normalized integer;
5. return non-zero on failure.

The collector shall not:

- derive a maximum from collector history;
- reinterpret `max_conns` as client-session count;
- use `max_sec_conns`;
- calculate an alert threshold;
- convert failure into zero.

---

## 7. Zabbix Contract

Key: `ifx.session.weekly_peak_physical_connections`

Type: Zabbix Agent (active)

Value type: Numeric (unsigned)

Units: `connections`

Update interval: `15m`

Timeout: `30s`

The runtime launcher must obtain configuration only from the portable
deployment runtime environment.

---

## 8. Validation Lifecycle

`DEVELOPMENT_RUNTIME_VALIDATED` records successful SQL statement, strict scalar collector, installed launcher, Zabbix Agent active key, template item, exported template, and uninstall/reinstall lifecycle validation in the Linux development topology.

Target Informix/AIX validation remains pending.