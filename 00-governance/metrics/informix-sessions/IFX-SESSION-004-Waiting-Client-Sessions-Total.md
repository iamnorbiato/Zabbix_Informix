# IFX-SESSION-004 — Waiting Client Sessions Total

## 1. Identity

| Field | Value |
| --- | --- |
| Metric ID | `IFX-SESSION-004` |
| Name | Waiting Client Sessions Total |
| Domain | Informix Sessions and Concurrency |
| Type | Current gauge |
| Unit | Sessions |
| Scope | One Informix instance |
| Lifecycle | `DEVELOPMENT_RUNTIME_VALIDATED` |

## 2. Monitoring Objective

Measure the current number of client sessions whose primary session state reports at least one documented Informix waiting flag.

The metric deliberately measures **sessions**, not engine threads and not cumulative wait events.

## 3. Authoritative Development Source

**Database: `sysmaster`**

The source is `syssessions`. The development instance exposes these waiting fields:

| Field | Meaning used by this metric |
| --- | --- |
| `is_wlatch` | Waiting on latch |
| `is_wlock` | Waiting on lock |
| `is_wbuff` | Waiting on buffer |
| `is_wckpt` | Waiting on checkpoint |
| `is_wlogbuf` | Waiting on log buffer |
| `is_wtrans` | Waiting on transaction-related condition |

The contract is satisfied when **any** flag has value `1` for a qualifying client session.

```sql
SELECT
    CAST(COUNT(*) AS INT8) AS waiting_client_sessions
FROM syssessions s
WHERE LENGTH(TRIM(s.hostname)) > 0
  AND s.sid <> DBINFO('sessionid')
  AND (
        s.is_wlatch = 1
     OR s.is_wlock = 1
     OR s.is_wbuff = 1
     OR s.is_wckpt = 1
     OR s.is_wlogbuf = 1
     OR s.is_wtrans = 1
  );
```

`CAST(... AS INT8)` is required because Informix `UNLOAD` can otherwise serialize `COUNT(*)` as a decimal value such as `7.0`.

## 4. Client-Session Boundary

The metric excludes:

- engine and service sessions with an empty `hostname`;
- the collector session itself, identified by `DBINFO('sessionid')`.

It does not attempt to infer waiting from `systhreads.th_state`. Development evidence showed that `th_state` does not provide a safe universal active/wait classification for this metric.

## 5. Controlled Source Validation

A controlled lock wait was created in database `tailor` using the retained table `zbx_ifx_session_test_lock`:

1. A DBeaver session held an exclusive lock.
2. A `dbaccess` session from `cluster-prime` attempted a conflicting operation.
3. The blocked client session appeared in `syssessions` with `is_wlock = 1`.
4. The session was correlated with `syslocks.waiter`.

This proves the metric entity and the `is_wlock` branch on the development Informix instance. The other documented flags remain part of the approved contract, but require separate controlled exercises before alert thresholds are based on their individual behavior.

## 6. Value Semantics

| Value | Meaning |
| --- | --- |
| `0` | No qualifying client session has any waiting flag set at collection time. |
| Positive integer | Number of qualifying client sessions with one or more waiting flags set. |
| No value / execution failure | Collection failed; it is not equivalent to zero. |

The metric is a gauge. A session with two or more flags still contributes **one** to this total.

## 7. Relationship with IFX-SESSION-005

`IFX-SESSION-005` provides one count per waiting-flag dimension. It is a diagnostic decomposition, not an arithmetic source for this metric.

The following equality is explicitly **not** assumed:

```text
IFX-SESSION-004 = SUM(IFX-SESSION-005 dimensions)
```

A session can theoretically have more than one flag set, causing a dimensional sum to exceed the distinct-session total.

## 8. Relationship with Locks

`IFX-LOCK-001` describes sessions waiting for locks through lock metadata. A lock-waiting client session may also contribute to this metric through `is_wlock = 1`.

No permanent arithmetic relationship is asserted because source timing and filtering can differ.

## 9. Zabbix Contract

The future Zabbix item shall be a numeric unsigned scalar with unit `sessions`. It shall collect one value per successful execution and preserve a collection failure as an item error rather than coercing it to zero.

No low-level discovery is required.

## 10. Development Runtime Validation

The Linux development topology validated the complete SESSION-004 collection path:

- `sysmaster:syssessions` SQL statement;
- strict scalar normalization by the KornShell collector;
- parameterized installed launcher;
- Zabbix Agent key `ifx.session.waiting_client_sessions`;
- Zabbix active item with unit `sessions`;
- exported Zabbix template definition;
- uninstall and reinstall lifecycle.

The statement, repository collector, installed launcher and Zabbix Agent all returned the same valid value:

```text
0
```
`0` represents the absence of qualifying waiting client sessions at the collection instant. It is a valid metric value, not a collection failure.

No alert threshold is implemented yet. Alerting requires operational baselines and additional controlled validation of the individual non-lock waiting flags.


## 11. Target Validation

Before target/AIX rollout, validate:

- all six fields exist and retain compatible semantics on the target Informix version;
- controlled waits for each applicable flag, where operationally safe;
- collection cost and an appropriate interval;
- coexistence with the lock metrics and production client workload.
