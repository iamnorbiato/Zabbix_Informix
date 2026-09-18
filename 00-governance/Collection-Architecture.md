# Collection Architecture

## 1. Purpose

This document defines the collection architecture for the AIX Informix Zabbix project.

Its purpose is to establish how monitoring information shall be obtained from IBM Informix and IBM AIX, transformed into monitoring metrics and delivered to Zabbix.

This document defines architectural rules.

It does not define the complete metric catalog, final collection intervals, final trigger thresholds or implementation details for every collector.

Those definitions shall be developed progressively after this architecture is approved.

---

# 2. Architectural Objective

The collection architecture shall provide a reliable, low-impact and maintainable path between the monitored environment and Zabbix.

The architecture must support information originating from:

- Informix `sysmaster`;
- Informix utilities such as `onstat`;
- Informix operational logs;
- IBM AIX operating system interfaces and commands.

The collection layer shall normalize these different sources into predictable monitoring values that can be consumed by Zabbix.

The architecture shall prioritize:

- correctness;
- low monitoring overhead;
- predictable behavior;
- maintainability;
- reuse;
- observability of the collection mechanism itself.

---

# 3. High-Level Architecture

The logical collection flow is:

```text
IBM AIX
   │
   ├── Operating System
   │      │
   │      ├── CPU / LPAR
   │      ├── Memory
   │      ├── Paging
   │      ├── Disk / I/O
   │      ├── Network
   │      └── errpt
   │
   └── IBM Informix
          │
          ├── sysmaster
          ├── onstat
          ├── online.log
          └── Informix utilities
                 │
                 ▼
          Collection Layer
                 │
                 ├── direct collection
                 ├── SQL statements
                 ├── collectors
                 ├── parsing
                 └── local cache
                         │
                         ▼
                       Zabbix
                         │
                 ┌───────┴───────┐
                 │               │
              Alerting         History
                                 │
                                 ▼
                              Grafana
```

The collection layer exists to prevent Zabbix monitoring definitions from becoming unnecessarily coupled to complex Informix or AIX collection logic.

---

# 4. Collection Sources

The architecture recognizes four primary classes of collection sources.

## 4.1 Informix sysmaster

`sysmaster` is the preferred source when the required information is available through stable and sufficiently documented system tables or views.

Typical use cases include:

- sessions;
- locks;
- database structures;
- internal engine statistics;
- storage information;
- memory information;
- performance counters.

Advantages include:

- structured data;
- predictable columns;
- easier filtering;
- easier aggregation;
- reduced dependency on textual command formatting.

The use of `sysmaster` must still be validated for:

- semantic correctness;
- query cost;
- Informix version compatibility;
- required permissions.

The existence of data in `sysmaster` does not automatically make a query appropriate for frequent monitoring.

---

## 4.2 Informix onstat

`onstat` is an approved monitoring source when it provides information that is more appropriate or more directly representative of the Informix engine state.

Typical use cases may include:

- instance state;
- engine statistics;
- checkpoints;
- virtual processors;
- memory structures;
- replication state;
- diagnostic engine information.

`onstat` output is primarily intended for human diagnostics.

Therefore, parsing shall be isolated from Zabbix item definitions whenever parsing becomes non-trivial.

A change in `onstat` formatting should ideally require modification of one collector rather than modification of multiple Zabbix items.

---

## 4.3 Informix Operational Logs

Informix operational logs, including `online.log`, are event-oriented sources.

They may provide information such as:

- assert failures;
- engine errors;
- abnormal shutdown information;
- recovery events;
- backup-related events;
- replication-related events.

Logs shall not normally be repeatedly scanned from the beginning.

Collection mechanisms should preserve position or state whenever necessary to identify new events efficiently.

Log-derived monitoring shall distinguish between:

- historical occurrences;
- newly detected events;
- current engine state.

An old error present in a log must not automatically represent a current failure.

---

## 4.4 IBM AIX

IBM AIX is the source for operating-system and infrastructure metrics.

Possible sources include AIX commands and system interfaces related to:

- CPU;
- LPAR entitlement;
- memory;
- paging;
- disks;
- I/O;
- Fibre Channel;
- vSCSI;
- network;
- hardware errors;
- `errpt`.

AIX commands shall be evaluated for execution cost before frequent collection is enabled.

Where Zabbix already provides a reliable native metric, unnecessary custom collectors should not be introduced.

Custom collection shall be used when native monitoring does not provide the required AIX-specific information.

---

# 5. Source Selection Policy

For every metric, the collection source shall be explicitly defined.

When multiple sources can provide similar information, selection shall consider:

1. semantic correctness;
2. stability;
3. collection cost;
4. structure of the returned data;
5. compatibility across supported Informix or AIX versions;
6. required privileges;
7. implementation complexity.

As a general preference:

```text
Structured native metric
        ↓
sysmaster
        ↓
specific Informix/AIX utility
        ↓
text parsing
        ↓
log parsing
```

This ordering is a preference, not an absolute rule.

The source that most accurately represents the desired metric shall prevail.

---

# 6. Collection Methods

The architecture defines three primary collection methods.

## 6.1 Direct Collection

Direct collection may be used when a value can be obtained cheaply and predictably.

Examples may include:

- simple operating-system metrics;
- lightweight commands;
- simple instance-state checks;
- native Zabbix agent metrics.

The logical flow is:

```text
Zabbix
   │
   ▼
Collection request
   │
   ▼
Command / native metric
   │
   ▼
Value
```

Direct collection should not contain complex parsing pipelines.

---

## 6.2 Statement-Based Collection

SQL statements shall be used when `sysmaster` is the selected source.

Statements developed by this project shall reside under:

```text
01-statements/
```

The statement layer shall be responsible for obtaining structured Informix information.

SQL statements should:

- return only required information;
- avoid unnecessary scans;
- avoid expensive operations where possible;
- use predictable output;
- be independently testable;
- document their monitoring purpose.

Complex monitoring logic should not be hidden inside SQL unless there is a clear reason for performing the calculation within Informix.

---

## 6.3 Collector-Based Collection

Collectors shall be introduced when collection requires:

- multiple commands;
- non-trivial parsing;
- aggregation;
- state tracking;
- caching;
- normalization;
- combining multiple related metrics;
- processing logs;
- protecting Informix from repeated collection.

A collector acts as an abstraction between the monitored technology and Zabbix.

Conceptually:

```text
Informix / AIX
      │
      ▼
   Collector
      │
      ▼
Normalized data
      │
      ▼
    Zabbix
```

The collector implementation technology is intentionally not defined yet.

The project shall first determine collector requirements before selecting shell, Perl, Python or another implementation approach compatible with the target AIX environment.

---

# 7. Collector Responsibilities

Collectors may perform the following responsibilities when required:

- execute source commands;
- execute approved SQL statements;
- parse command output;
- normalize values;
- convert units;
- maintain collection state;
- identify new log events;
- produce discovery information;
- generate structured output;
- cache expensive results;
- report collection failures.

Collectors shall not become a second monitoring platform.

Their purpose is collection and normalization.

Alerting logic belongs primarily to Zabbix.

Visualization logic belongs primarily to Grafana.

---

# 8. Local Cache Architecture

Repeated execution of expensive Informix commands or SQL statements shall be avoided.

When several metrics originate from the same expensive source, a single collection may populate a local cache.

Example:

```text
             onstat / sysmaster
                    │
                    │ one execution
                    ▼
                Collector
                    │
                    ▼
             Structured Cache
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
     Metric A    Metric B    Metric C
```

Instead of:

```text
Metric A → onstat
Metric B → onstat
Metric C → onstat
Metric D → onstat
```

The cache mechanism shall eventually define:

- location;
- ownership;
- permissions;
- maximum age;
- refresh behavior;
- failure behavior;
- atomic update mechanism.

These implementation details are intentionally deferred.

---

# 9. Metric Semantics

Every collected value shall be classified according to its semantics.

## 9.1 Gauge

A gauge represents a current value.

Examples:

- current sessions;
- lock wait sessions;
- current dbspace usage;
- current replication backlog;
- current memory usage.

A gauge may increase or decrease independently between collections.

---

## 9.2 Counter

A counter represents an accumulated value.

Examples may include:

- deadlocks;
- sequential scans;
- foreground writes;
- buffer waits;
- engine operations.

Counters normally increase until an engine restart or counter reset occurs.

Zabbix may retain the raw counter and calculate:

- delta;
- change;
- rate per second;
- rate per minute;
- rate per hour.

Collector implementations should not unnecessarily destroy the original counter semantics.

---

## 9.3 State

A state represents a discrete operational condition.

Examples:

- Online;
- Quiescent;
- Recovery;
- Down;
- replication connected;
- chunk status.

States should preferably be represented internally by stable machine-readable values.

Zabbix value maps may provide human-readable representations.

---

## 9.4 Event

An event represents something that occurred.

Examples:

- assert failure;
- hardware error;
- abnormal shutdown;
- backup failure.

Event collection must distinguish new events from previously observed events.

---

# 10. Derived Metrics

Not every operational metric needs to be collected directly.

Some values should be calculated from raw metrics.

Examples:

```text
deadlocks per second
foreground writes per second
sequential scans per second
dbspace used percentage
replication backlog
backup age
```

When possible, raw source metrics should be preserved and derived metrics calculated by Zabbix.

This allows historical recalculation and avoids embedding unnecessary monitoring semantics inside collectors.

---

# 11. Collection Frequency

Collection frequency shall not be globally uniform.

Metrics shall be classified according to operational urgency and collection cost.

Conceptually:

```text
High frequency
    │
    ├── availability
    ├── critical state
    └── immediate contention

Medium frequency
    │
    ├── sessions
    ├── checkpoints
    ├── locks
    └── performance counters

Low frequency
    │
    ├── capacity
    ├── configuration
    ├── discovery
    └── expensive diagnostics
```

Exact intervals shall be defined in the metric catalog.

No interval shall be selected solely because it is technically possible.

---

# 12. Discovery Architecture

Dynamic resources should use Zabbix Low-Level Discovery when appropriate.

Potential discovery domains include:

- dbspaces;
- chunks;
- sbspaces;
- temporary dbspaces;
- replication peers.

The logical flow is:

```text
Informix
   │
   ▼
Discovery Collector / Statement
   │
   ▼
Structured discovery data
   │
   ▼
Zabbix Low-Level Discovery
   │
   ├── Item Prototypes
   ├── Trigger Prototypes
   └── Graph / related objects
```

Discovery should use stable identifiers whenever possible.

Transient identifiers shall not be used as persistent monitoring identities unless technically required.

---

# 13. Collection Failure Handling

Failure to collect a metric is itself operationally relevant.

The architecture shall distinguish between:

```text
metric value = 0
```

and:

```text
metric could not be collected
```

Collectors must not silently convert execution failures into valid-looking zero values.

Possible collection failures include:

- Informix unavailable;
- SQL connection failure;
- insufficient permissions;
- command execution failure;
- malformed output;
- collector timeout;
- stale cache;
- missing source file;
- AIX command failure.

Collection health shall eventually be monitored by Zabbix.

---

# 14. Timeout and Execution Protection

Monitoring commands and SQL statements shall not be allowed to execute indefinitely.

Collectors and statements shall eventually define appropriate timeout behavior.

A monitoring request that exceeds its expected execution time shall fail predictably rather than accumulate processes or sessions on the monitored host.

The exact timeout values shall be defined during implementation.

---

# 15. Privilege Principle

Monitoring shall operate with the minimum privileges required to collect approved metrics.

The monitoring architecture shall avoid unnecessary use of:

- root;
- Informix administrative identities;
- unrestricted database credentials.

Where elevated privileges are unavoidable, their use shall be explicitly documented.

Credential management is not yet defined and shall be addressed before runtime deployment.

Credentials shall not be stored directly inside repository artifacts.

---

# 16. Monitoring Impact Protection

The monitoring system must not materially degrade the system it monitors.

Therefore:

- expensive SQL shall be identified;
- expensive commands shall be identified;
- repeated equivalent collection shall be avoided;
- discovery shall run less frequently than operational metrics where appropriate;
- collectors may cache expensive results;
- SQL shall avoid unnecessary full scans;
- collection intervals shall reflect collection cost;
- timeout protection shall be implemented.

A metric that creates unacceptable overhead shall not be deployed simply because it is operationally desirable.

An alternative collection method must be evaluated.

---

# 17. Zabbix Responsibilities

Zabbix shall be responsible for:

- scheduling collection;
- receiving monitoring values;
- storing historical metrics;
- preprocessing where appropriate;
- calculating derived metrics where appropriate;
- performing discovery;
- maintaining item state;
- evaluating triggers;
- evaluating dependencies;
- generating operational alerts;
- exposing monitoring data for visualization.

Zabbix shall remain the authoritative monitoring and alerting layer.

---

# 18. Grafana Responsibilities

Grafana shall consume monitoring information for visualization and diagnostic purposes.

Grafana shall not directly execute operational commands against Informix or AIX as part of the normal monitoring architecture.

The expected flow is:

```text
Informix / AIX
      │
      ▼
Collection
      │
      ▼
Zabbix
      │
      ▼
Grafana
```

This preserves one primary collection pipeline and prevents duplicated monitoring load.

---

# 19. Initial Collection Domains

Collection shall be developed progressively.

The initial domains are:

1. Informix instance health;
2. sessions and concurrency;
3. locks and contention;
4. checkpoints and writes;
5. storage and capacity;
6. transaction logs and backup;
7. replication and HA;
8. Informix memory and virtual processors;
9. IBM AIX infrastructure;
10. SQL performance.

The implementation order may differ when technical dependencies require it.

---

# 20. Metric Catalog Dependency

No large-scale implementation shall begin before the metric catalog defines the first implementation domain.

For every metric, the catalog shall establish at minimum:

```text
Metric
Purpose
Source
Collection method
Type
Unit
Semantics
Frequency
Collection cost
Discovery requirement
```

Additional attributes such as triggers, severity and visualization may be added where applicable.

The metric catalog is the bridge between this architecture and implementation.

---

# 21. Initial Decisions

The following architectural decisions are established by this document:

1. Zabbix is the primary monitoring and alerting platform.
2. Grafana is primarily the visualization and diagnostic platform.
3. Informix and AIX remain the authoritative sources of runtime telemetry.
4. `sysmaster` is preferred when it provides an appropriate structured source.
5. `onstat` remains an approved source when technically appropriate.
6. Operational logs are treated as event-oriented sources.
7. Complex parsing should be isolated from Zabbix item definitions.
8. Expensive collection may use local caching.
9. Dynamic resources should use Low-Level Discovery where appropriate.
10. Raw counters should normally be preserved.
11. Derived rates should preferably be calculated from raw counters.
12. Collection failures must not be represented as valid zero values.
13. Monitoring overhead is an explicit architectural concern.
14. Grafana shall not create a second direct collection path to Informix or AIX.

---

# 22. Deferred Decisions

The following decisions remain intentionally open:

- collector implementation language;
- collector installation path;
- cache location;
- cache format;
- Zabbix Agent versus Zabbix Agent 2;
- exact Zabbix item naming standard;
- exact SQL execution mechanism;
- credential management;
- exact collection intervals;
- timeout values;
- supported Informix versions;
- supported AIX versions;
- Grafana datasource implementation;
- exact deployment automation mechanism.

These decisions shall be resolved only when sufficient technical information is available.

The portable deployment topology and controlled promotion flow are defined in [Deployment-Topology-Contract.md](Deployment-Topology-Contract.md). The exact automation mechanism remains dependent on the target environment.

---

# 23. Next Engineering Step

After approval of this collection architecture, the next engineering step is:

**Build the Monitoring Metric Catalog.**

The metric catalog shall transform the monitoring requirements into an explicit engineering matrix and determine, metric by metric, what will actually be collected and how.