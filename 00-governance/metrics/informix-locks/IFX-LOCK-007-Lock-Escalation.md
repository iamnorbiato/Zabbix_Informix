# IFX-LOCK-007 — Lock Escalation

Lifecycle: `SOURCE_REJECTED`

## Decision

This metric is not implemented.

## Investigation Evidence

Database: `sysmaster`.

The SMI catalog was searched for table and column names matching `*escal*`; no result was returned. `sysprofile` was also searched for profile names matching `*escal*`; no result was returned.

`onstat -k` can show active table locks, but it does not distinguish a table lock acquired by application design from one created by an escalation event. It is not an authoritative historical escalation counter.

## Outcome

No approved SQL statement, collector, launcher, Zabbix item or trigger exists for LOCK-007.

The metric may be reconsidered only when a documented and SQL-visible Informix source exists.
