# IFX-SESSION-003 — Weekly Peak Concurrent Physical Connections

## 1. Purpose

This document defines the engineering contract for:

`IFX-SESSION-003 — Weekly Peak Concurrent Physical Connections`

The metric reports the most recent weekly high-water value maintained by
Informix for concurrent physical connections.

It is not a peak since server startup and is not calculated from Zabbix
history.

---

## 2. Monitoring Domain

Domain: `Connections, Sessions and Concurrency`

Metric ID: `IFX-SESSION-003`

Metric name: `Weekly Peak Concurrent Physical Connections`

Lifecycle: `DEVELOPMENT_RUNTIME_VALIDATED`

---

## 3. Authoritative Development Source

Database: `sysmaster`

View: `sysfeatures`

Column: `max_conns`

`sysfeatures.max_conns` is the maximum number of concurrent physical
connections for a standalone server or a high-availability primary server
instance. Informix samples the information every 15 minutes and retains the
highest value for each week in its circular historical store.

The source has been observed in the development instance with rows:

```text
2026|38|6
2026|37|4
```

where the columns are `year`, `week`, and `max_conns`.

---

## 4. Approved Semantic

The metric is the `max_conns` value from the most recent `sysfeatures` week
with a non-null value.

It represents the highest concurrent physical-connection count observed by
Informix during that week. It does not promise equivalence to the client
session count of IFX-SESSION-001 because the two sources and scopes differ.

The metric does not use `max_sec_conns`, which is the corresponding source for
HDR or RSS secondary server instances and belongs to a future replication
design.

---

## 5. Authoritative SQL Contract

```sql
SELECT FIRST 1
    CAST(max_conns AS INT8) AS weekly_peak_concurrent_physical_connections
FROM sysfeatures
WHERE max_conns IS NOT NULL
ORDER BY
    year DESC,
    week DESC;
```

The runtime statement file must contain only the `SELECT`; isolation is set by
the common Informix query library.

---

## 6. Metric Type and Unit

Type: `GAUGE / weekly high-water value`

Unit: `CONNECTIONS`

The value may remain unchanged during a week and may decrease when Informix
advances to a new week with a lower high-water value.

---

## 7. Value and Zero Semantics

The normalized output is one non-negative integer.

```text
0
```

is valid only if Informix records a weekly high-water value of zero.

No row, malformed output, or collection failure is not zero and must fail the
collection.

---

## 8. Collection and Zabbix Contract

Collection method: SQL scalar statement through the common Informix collector
library.

Zabbix key: `ifx.session.weekly_peak_physical_connections`

Zabbix type: active Agent item.

Zabbix value type: Numeric (unsigned).

Development interval: `15m`, aligned with the documented Informix sampling
cadence.

Timeout: `30s`.

Discovery: No.

No direct trigger is defined initially. The metric is primarily a capacity and
trend input.

---

## 9. Relationship with Other Metrics

The following equality is prohibited:

```text
IFX-SESSION-003 = MAX(IFX-SESSION-001 history)
```

IFX-SESSION-003 is Informix-maintained weekly physical-connection history;
IFX-SESSION-001 is a current filtered client-session observation.

---

## 10. Runtime Validation

The Linux development topology validated:

1. the approved `sysmaster:sysfeatures` SQL query in DBeaver, returning `6`;
2. the versioned SQL statement through `ifx_db_execute`, returning `6|`;
3. the strict scalar collector, returning `6`;
4. the installed launcher executed as user `zabbix`, returning `6`;
5. the Zabbix Agent active key `ifx.session.weekly_peak_physical_connections`, returning `6`;
6. the active Zabbix template item with Numeric (unsigned), unit `connections`, 15-minute interval, and 30-second timeout;
7. the exported template definition;
8. uninstall/reinstall lifecycle, including removal and restoration of the launcher and Agent configuration.

Target Informix/AIX validation remains pending.