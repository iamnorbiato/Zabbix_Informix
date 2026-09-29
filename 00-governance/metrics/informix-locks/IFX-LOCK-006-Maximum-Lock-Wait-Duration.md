# IFX-LOCK-006 — Maximum Lock Wait Duration

Lifecycle: `SOURCE_REJECTED`

## Decision

This metric is not implemented.

## Investigation Evidence

Database: `sysmaster`.

`sysrstcb.sid` was joined to `syssessions.sid` during a controlled lock wait. The waiting client session was confirmed by `syssessions.is_wlock = 1`.

For that same session, `sysrstcb.lkwaittime` changed from `286.35884703568604` to `286.35875164493336` during an approximately twenty-second wait. The value neither represented elapsed wait seconds nor provided documented units or semantics suitable for a current maximum lock-wait duration.

## Outcome

No approved SQL statement, collector, launcher, Zabbix item or trigger exists for LOCK-006.

The metric may be reconsidered only if a supported Informix version exposes a documented SQL-visible current lock-wait age with proven units and session correlation.
