# IFX-SESSION-001 — Total Connected Client Sessions — Parser Specification

## 1. Purpose

This document defines the runtime normalization contract for:

`IFX-SESSION-001 — Total Connected Client Sessions`

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

---

## 2. Source Contract

Database: `sysmaster`

Table: `syssessions`

The collector executes the approved versioned SQL statement. Session inclusion
and exclusions are defined by that statement and are not reimplemented by the
parser.

---

## 3. Input Contract

`ifx_db_execute` unloads exactly one scalar with the project standard trailing
field delimiter:

```text
4|
```

The collector accepts exactly one record with:

1. one non-negative integer value;
2. one empty unload terminator field.

---

## 4. Output Contract

Successful output is exactly one non-negative integer and a newline:

```text
4
```

No delimiter, label, connection message, blank line, or diagnostic may be
written to standard output.

---

## 5. Validity Rules

The collector must fail without numeric output on:

- Informix query failure;
- empty output;
- more than one record;
- missing or non-empty unload terminator;
- signed, decimal, alphabetic, or whitespace-padded value.

`0` is valid. Failure must never become `0`.

---

## 6. Collector Responsibilities

The collector shall:

1. source the common Informix database library;
2. execute the versioned statement against `sysmaster`;
3. validate the strict scalar unload contract;
4. emit one normalized integer;
5. return non-zero on failure.

The collector shall not classify session rows, add exclusions, derive a peak,
or calculate an alert threshold.

---

## 7. Zabbix Contract

Key: `ifx.session.total_connected`

Type: Zabbix Agent (active)

Value type: Numeric (unsigned)

Units: `sessions`

Update interval: `1m`

The launcher receives configuration from the portable deployment runtime
environment; no source-checkout path is used at runtime.

---

## 8. Validation Lifecycle

`DEVELOPMENT_RUNTIME_VALIDATED` records successful SQL, collector, launcher,
Zabbix Agent active key, and template-item validation in the Linux development
topology.

Target Informix/AIX validation remains pending.
