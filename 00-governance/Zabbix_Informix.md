# AIX Informix Zabbix Informix

## 1. Purpose

Zabbix Informix is a monitoring and observability engineering project focused on IBM Informix running on IBM AIX environments, using Zabbix as the primary monitoring and alerting platform and Grafana as the visualization and diagnostic platform.

The project exists to design, validate, document and maintain reusable monitoring artifacts before they are deployed into production monitoring environments.

Zabbix Informix shall provide a controlled engineering repository for:

- Informix monitoring definitions;
- IBM AIX monitoring definitions;
- SQL statements used for Informix telemetry collection;
- Zabbix templates, items, triggers, discovery rules and dashboards;
- Grafana dashboards and related visualization definitions;
- monitoring architecture and engineering decisions;
- operational monitoring standards.

The repository is not the production runtime environment.

Artifacts developed here are intended to be validated, versioned and subsequently exported or deployed into the environments where Informix, AIX, Zabbix and Grafana are actually running.

---

# 2. Core Objective

The primary objective of Zabbix Informix is to provide reliable operational visibility into the complete Informix execution stack.

The monitoring architecture shall cover four main layers:

1. Informix database engine;
2. Informix workload and SQL execution;
3. IBM AIX operating system and infrastructure;
4. visualization and operational alerting.

The solution shall allow operators to answer questions such as:

- Is the Informix instance operational?
- Is the instance healthy?
- Is database performance degrading?
- Are sessions waiting for locks or other resources?
- Are checkpoints behaving normally?
- Is the buffer pool under pressure?
- Are foreground writes occurring excessively?
- Are dbspaces or chunks approaching capacity limits?
- Are logical or physical logs under pressure?
- Are backups operating correctly?
- Is replication healthy?
- Is the Informix engine experiencing memory or VP contention?
- Is the underlying AIX LPAR experiencing CPU, memory, paging or I/O pressure?
- Is a database problem actually caused by the operating system or storage layer?

The architecture shall prioritize correlation between these layers instead of treating each subsystem independently.

---

# 3. Technology Scope

The initial project scope consists of the following technologies.

## 3.1 IBM Informix

Informix is the primary monitored application.

The monitoring architecture shall cover, progressively:

- instance availability and state;
- uptime;
- assert failures;
- checkpoints;
- LRU and foreground writes;
- sessions;
- active sessions;
- session concurrency;
- lock waits;
- deadlocks;
- latch waits;
- buffer waits;
- SQL execution;
- sequential scans;
- buffer cache efficiency;
- dbspaces;
- chunks;
- sbspaces;
- temporary dbspaces;
- logical logs;
- physical log;
- backup activity;
- replication;
- shared memory;
- virtual processors.

Not every metric must be implemented immediately.

Metrics shall be introduced incrementally and only after their collection method and semantics have been validated.

---

## 3.2 IBM AIX

IBM AIX is the operating system layer supporting Informix.

The monitoring architecture shall progressively cover:

- LPAR CPU utilization;
- physical CPU consumption;
- entitled capacity;
- memory utilization;
- paging space;
- active paging;
- disk I/O;
- storage latency;
- Fibre Channel or vSCSI behavior;
- network behavior;
- hardware and I/O errors;
- relevant `errpt` events.

AIX monitoring shall complement Informix monitoring.

AIX metrics shall not be interpreted independently when database behavior requires correlation between operating system and database engine activity.

---

## 3.3 Zabbix

Zabbix is the primary monitoring and alerting platform.

Its responsibilities include:

- collecting metrics;
- storing monitoring history;
- calculating derived metrics where appropriate;
- performing Low-Level Discovery;
- evaluating triggers;
- generating operational alerts;
- maintaining monitoring state;
- providing operational dashboards when useful.

Zabbix shall be the authoritative alerting layer of the solution.

Alerting logic should not be unnecessarily duplicated in Grafana.

---

## 3.4 Grafana

Grafana is the primary visualization and diagnostic layer.

Its responsibilities include:

- historical visualization;
- metric correlation;
- performance analysis;
- operational investigation;
- dashboard composition;
- cross-layer visualization between Informix and AIX.

Grafana shall primarily answer:

- what happened;
- when it happened;
- how long it lasted;
- which metrics changed together;
- which infrastructure condition may have contributed to the database condition.

Grafana is not intended to replace Zabbix as the primary alerting engine.

---

# 4. Architectural Principles

The project shall follow the principles defined below.

## 4.1 Documentation First

Monitoring artifacts shall not be developed before their purpose, source and behavior are sufficiently understood.

Architecture and engineering decisions shall be documented before significant implementation.

---

## 4.2 Source Validation Before Automation

Every metric shall have a validated source before being implemented in Zabbix.

Possible collection sources include:

- Informix `sysmaster`;
- Informix `onstat`;
- Informix logs such as `online.log`;
- Informix utilities;
- IBM AIX commands and system interfaces.

The existence of a possible command or SQL query does not automatically make it an approved monitoring source.

Its meaning, cost and reliability must first be understood.

---

## 4.3 Prefer Structured Sources

When equivalent information is available through a stable and structured Informix source, structured data should normally be preferred over parsing human-readable command output.

Therefore, where technically appropriate:

`sysmaster` should be preferred over textual parsing of `onstat`.

This is not an absolute rule.

`onstat` remains a valid source when it provides information that is more appropriate, complete or reliable for a particular metric.

---

## 4.4 Separate Collection From Monitoring Logic

Complex parsing and Informix-specific collection logic should not be embedded unnecessarily inside individual Zabbix items.

The architecture should favor reusable collectors or statements where this reduces:

- duplicated execution;
- parsing complexity;
- database overhead;
- maintenance complexity;
- dependence on command output formatting.

Zabbix should consume well-defined monitoring values whenever practical.

---

## 4.5 Minimize Collection Overhead

Monitoring must not become a material source of load on Informix or AIX.

Metrics shall therefore be classified according to collection cost.

Collection intervals shall be selected according to operational value and execution cost.

Expensive commands or queries should not be executed repeatedly when a single collection can supply multiple related metrics.

---

## 4.6 Distinguish Gauges From Counters

Every metric shall have defined semantics.

Examples include:

Gauge:

- number of current sessions;
- percentage of dbspace usage;
- replication state;
- current memory usage.

Counter:

- deadlocks since startup;
- sequential scans since startup;
- foreground writes;
- buffer waits.

Counters should normally preserve the raw accumulated value while also allowing rates or deltas to be calculated when operationally useful.

---

## 4.7 Automatic Discovery Where Appropriate

Dynamic Informix structures should not require unnecessary manual monitoring configuration.

Low-Level Discovery should be evaluated for resources such as:

- dbspaces;
- chunks;
- sbspaces;
- temporary dbspaces;
- replication peers;
- other dynamically discoverable components.

A newly created monitored resource should appear automatically whenever technically feasible.

---

## 4.8 Avoid Uncontrolled Metric Cardinality

The monitoring design shall avoid creating excessively dynamic metric dimensions.

Examples of information that should not automatically become metric labels or permanent Zabbix item identities include:

- complete SQL text;
- arbitrary session identifiers;
- highly transient thread identifiers;
- unconstrained object names.

Operational usefulness must be balanced against monitoring-system scalability.

---

## 4.9 Correlation Over Isolated Metrics

The project shall favor metrics that allow causal or temporal correlation.

Examples:

- checkpoint duration versus disk latency;
- foreground writes versus buffer pressure;
- Informix memory usage versus AIX paging;
- session waits versus CPU utilization;
- replication backlog versus network or disk activity;
- tempdb usage versus expensive SQL operations.

Individual metrics are useful.

Correlated metrics provide diagnosis.

---

# 5. Monitoring Domains

The initial monitoring domains are defined as follows.

## 5.1 Instance Availability and Health

Includes:

- instance state;
- uptime;
- assert failures;
- checkpoints;
- checkpoint waits;
- LRU writes;
- foreground writes.

---

## 5.2 Connections, Sessions and Concurrency

Includes:

- total sessions;
- active sessions;
- historical session peak;
- waiting sessions;
- thread waits.

---

## 5.3 Locks and Contention

Includes:

- lock wait sessions;
- maximum lock wait time;
- deadlocks;
- latch waits;
- buffer waits.

---

## 5.4 SQL and Query Performance

Includes:

- long-running SQL;
- sequential scans;
- indexed access behavior where measurable;
- buffer cache efficiency;
- high-resource sessions;
- query execution behavior.

---

## 5.5 Storage and Capacity

Includes:

- dbspaces;
- chunks;
- sbspaces;
- temporary dbspaces;
- total capacity;
- used capacity;
- free capacity;
- capacity percentage;
- resource status.

---

## 5.6 Transaction Logs and Continuity

Includes:

- logical logs;
- logical log backup state;
- physical log;
- backup automation;
- continuity indicators.

---

## 5.7 Replication and High Availability

Includes technologies such as:

- HDR;
- RSS;
- SDS.

Monitoring may include:

- replication role;
- connection state;
- backlog;
- log position;
- estimated replication delay.

---

## 5.8 Informix Memory and Virtual Processors

Includes:

- shared memory;
- SHMTOTAL relationship;
- resident memory;
- virtual memory;
- buffer memory;
- internal memory segments;
- CPU VPs;
- AIO VPs;
- PIO VPs;
- LIO VPs;
- SOC VPs;
- SSL VPs.

---

## 5.9 IBM AIX Infrastructure

Includes:

- LPAR CPU;
- entitled capacity;
- physical CPU utilization;
- memory;
- paging space;
- active paging;
- disk I/O;
- storage latency;
- Fibre Channel or vSCSI;
- hardware errors;
- I/O errors;
- `errpt`.

---

# 6. Repository Structure

The initial repository structure is:

```text
Zabbix_Informix/
├── 00-governance/
├── 01-statements/
├── 02-zabbix/
└── 03-grafana/
```

## 6.1 `00-governance`

Contains project governance and architecture documentation.

Examples may include:

- architecture;
- monitoring principles;
- metric catalog;
- architectural decisions;
- engineering standards;
- implementation plans;
- handoff documents.

---

## 6.2 `01-statements`

Contains SQL statements and database queries used by the monitoring architecture.

These may include queries against:

- `sysmaster`;
- other Informix system databases where appropriate.

Statements shall be documented and validated before production use.

---

## 6.3 `02-zabbix`

Contains Zabbix artifacts.

These may include:

- templates;
- items;
- dependent items;
- preprocessing definitions;
- triggers;
- discovery rules;
- item prototypes;
- trigger prototypes;
- value maps;
- dashboards;
- export files.

---

## 6.4 `03-grafana`

Contains Grafana artifacts.

These may include:

- dashboards;
- dashboard JSON definitions;
- visualization definitions;
- supporting documentation.

---

# 7. Development and Runtime Separation

The repository path used for development is:

```text
/Volumes/cluster-prime/development/Informix/Zabbix_Informix
```

This repository is the engineering workspace.

Informix, AIX, Zabbix and Grafana may exist in separate runtime environments.

The project shall therefore avoid unnecessary assumptions that development artifacts execute directly from this repository.

The expected lifecycle is:

```text
Design
   ↓
Document
   ↓
Validate source
   ↓
Develop artifact
   ↓
Test
   ↓
Version
   ↓
Export / Deploy
   ↓
Runtime environment
```

The portable runtime topology and controlled deployment flow are defined in [Deployment-Topology-Contract.md](Deployment-Topology-Contract.md).

The exact target automation mechanism remains dependent on the target environment and is intentionally deferred.

---

# 8. Metric Engineering Standard

Before a metric becomes part of the monitoring solution, the following characteristics should be defined whenever applicable:

- metric name;
- monitoring domain;
- purpose;
- source;
- collection command or SQL statement;
- value type;
- unit;
- gauge or counter semantics;
- collection interval;
- expected collection cost;
- discovery requirement;
- preprocessing requirement;
- trigger applicability;
- trigger severity;
- dependencies;
- visualization relevance.

This information shall form the monitoring metric catalog.

The catalog will be developed before large-scale implementation of Zabbix artifacts.

---

# 9. Alerting Philosophy

Alerts shall represent actionable operational conditions.

The project shall avoid creating alerts simply because a metric exists.

Triggers should consider:

- duration;
- severity;
- operational context;
- dependencies;
- expected transient states;
- baseline behavior.

Examples of potentially poor alerting behavior include:

- alerting immediately on every short lock wait;
- alerting solely because paging space contains allocated pages;
- alerting on a counter solely because its absolute value is high;
- alerting on a temporary recovery state without considering expected operational activity.

The objective is signal quality rather than trigger quantity.

---

# 10. Visualization Philosophy

Dashboards shall be designed around operational questions rather than simply displaying every available metric.

The initial visualization model is expected to evolve toward areas such as:

- Informix Overview;
- Sessions and Locks;
- SQL Performance;
- Storage and Logs;
- Memory and Virtual Processors;
- Replication;
- IBM AIX Infrastructure.

Dashboards should favor correlation and diagnosis.

---

# 11. Initial Engineering Sequence

The initial project sequence shall be:

1. establish governance documentation;
2. define monitoring architecture;
3. create the metric catalog;
4. define and validate collection sources;
5. validate statements and commands against real environments;
6. develop Informix monitoring incrementally;
7. develop AIX monitoring incrementally;
8. develop Zabbix alerts and discovery;
9. develop Grafana visualization;
10. refine thresholds and operational baselines.

Implementation shall proceed by monitoring domain rather than attempting to implement the complete monitoring scope at once.

---

# 12. Initial Boundaries

The following are not yet considered finalized architectural decisions:

- exact Zabbix version requirements;
- exact Grafana version requirements;
- Zabbix Agent versus Zabbix Agent 2 usage;
- exact deployment automation mechanism;
- credential management;
- collector implementation language;
- script installation paths on AIX;
- naming convention for all Zabbix items;
- final collection intervals;
- final trigger thresholds;
- Grafana datasource architecture;
- high-availability monitoring implementation details;
- SQL performance collection methodology.

These decisions shall be made explicitly during subsequent architecture work.

They shall not be assumed prematurely.

---

# 13. Source of Truth

This document defines the high-level purpose and architectural direction of Zabbix Informix.

Detailed technical decisions may be represented by additional governance documents as the project evolves.

When implementation behavior conflicts with documented architectural decisions, the documented architecture shall be reviewed before the implementation is treated as authoritative.

Zabbix Informix shall evolve through explicit engineering decisions rather than undocumented conventions.