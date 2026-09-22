# IFX-LOCK-001 — Sessions Waiting for Locks — Parser Specification

## 1. Purpose

This document defines the runtime normalization contract for:

`IFX-LOCK-001 — Sessions Waiting for Locks`

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

---

## 2. Source Contract

Database: `sysmaster`

The approved statement joins `syslocks.waiter` to `syssessions.sid` and returns one `COUNT(DISTINCT waiter)` scalar for qualifying client sessions.

The collector does not infer waits from `syssessions.is_wlock`; that flag is supporting validation evidence, while `syslocks.waiter` is the authoritative lock-wait source for this metric.

---

## 3. Input Contract

`ifx_db_execute` unloads exactly one scalar with the project standard trailing field delimiter:

```text
1|
```

The collector accepts exactly one record containing one non-negative integer and an empty terminator field.

---

## 4. Output Contract

Successful output is exactly one non-negative integer and a newline:

```text
1
```

No labels, delimiters, connection messages, blank lines, or diagnostic text may be emitted to standard output.

---

## 5. Validity and Failure Rules

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

It shall not inspect lock rows, deduplicate waiters, apply client filters, or calculate alert severity. Those responsibilities belong to the approved SQL statement and Zabbix trigger configuration.

---

## 7. Zabbix Contract

Key: `ifx.lock.sessions_waiting`

Type: Zabbix Agent (active)

Value type: Numeric (unsigned)

Units: `sessions`

Update interval: `1m`

Timeout: `30s`

---

## 8. Validation Lifecycle

`DEVELOPMENT_RUNTIME_VALIDATED` records the controlled `syslocks.waiter` scenario and the complete Linux development runtime chain:

- the SQL contract returned `1` during the wait and `0` after release;
- the repository collector, installed launcher, and active Agent key returned valid normalized scalar values;
- the template active item received both states;
- the `HIGH` trigger opened for `1` and resolved after the returned value was `0`;
- the complete template was exported to the versioned YAML definition;
- uninstall and reinstall removed and restored the launcher and Agent integration successfully.

Target Informix/AIX validation remains pending.
