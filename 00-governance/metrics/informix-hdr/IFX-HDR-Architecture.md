# IFX-HDR — Monitoring Architecture

## 1. Purpose

This document defines the intended monitoring architecture for IBM Informix
High-Availability Data Replication (HDR) in Zabbix.

It is a design specification only. No HDR SQL statement, collector, Zabbix
template, launcher, deployment artifact or trigger is approved for
implementation until the related metric specifications and mock-validation plan
are approved.

Current status:

`DEFINED`

---

## 2. Scope

The HDR monitoring domain answers the following operational questions:

- Is the local Informix instance an HDR primary, HDR secondary or standard server?
- Is HDR enabled and in the expected state?
- Which remote Informix server is the configured HDR peer?
- Is every discovered HDR peer connected?
- Is the remote peer operational and using the expected synchronization mode?
- Is acknowledgement activity recent?
- Is log transmission or acknowledgement falling behind?

The domain complements, but does not replace, `IFX-HEALTH-001` through
`IFX-HEALTH-008`.

---

## 3. Explicit Non-Goals

This initial HDR domain does not monitor:

- Enterprise Replication;
- replication topology managed solely by an external product;
- RSS or SDS health as if it were HDR health;
- automated failover or promotion;
- configuration changes to Informix;
- replication repair or resynchronization.

RSS and SDS peers can be discovered as cluster context, but HDR-specific
triggers shall apply only to peers whose node type is HDR.

---

## 4. SQL-Only Collection Principle

The normal runtime design shall use SQL against the `sysmaster` database.

The preferred System-Monitoring Interface sources are:

| Source | Intended use |
|---|---|
| `sysdri` | Local HDR role, state, configured peer and DR parameters |
| `syscluster` | Per-peer node type, connection state, server state, log progress and acknowledgement time |

`onstat` output is not a production collection dependency for this domain.

`syscdr*` tables are excluded because they describe Enterprise Replication, not
HDR.

Undocumented shared-memory fields shall not be used as the authoritative HDR
interface.

---

## 5. Topology Model

Each Informix instance is monitored as an independent Zabbix host.

```text
Informix primary host                 Informix HDR secondary host
        |                                        |
        | SQL to local sysmaster                  | SQL to local sysmaster
        v                                        v
Zabbix collection identity                Zabbix collection identity
        |                                        |
        +---------------- Zabbix Server ---------+
```

The collection host can be colocated with the Informix engine or can connect by
Informix Client SDK, provided it is able to query the correct local `sysmaster`
instance for each Zabbix host.

The primary and secondary must never be represented as one Zabbix host merely
because they form one HDR pair.

---

## 6. Expected-Topology Parameters

HDR alerting shall be controlled by explicit runtime parameters.

| Parameter | Allowed values | Meaning |
|---|---|---|
| `IFX_HDR_ALERT_ON_DISCONNECT` | `YES`, `NO` | Enables or suppresses alerts for discovered disconnected HDR peers |
| `IFX_HDR_REQUIRED` | `YES`, `NO` | Declares whether this instance is expected to participate in HDR |

The parameters express monitoring intent. They do not enable, disable or alter
HDR in Informix.

Expected behavior:

| HDR discovered | Peer connected | Required | Result |
|---|---|---|---|
| No | N/A | `NO` | Normal, HDR not applicable |
| No | N/A | `YES` | Problem, required HDR is absent |
| Yes | Yes | Either | Normal |
| Yes | No | Either, alerting enabled | Problem, HDR peer disconnected |

---

## 7. Discovery Model

`sysdri` describes the local relationship. `syscluster` can return one row per
remote high-availability peer.

The HDR collector shall produce a discovery dataset containing only peers whose
node type is HDR. An environment without HDR shall return an empty discovery
dataset, not a collection failure.

Each discovered peer shall have a stable logical identity based on its Informix
server name. Display names must not be used as identifiers.

---

## 8. Proposed Metric Set

| Metric ID | Name | Scope |
|---|---|---|
| `IFX-HDR-001` | Local Role and State | Instance |
| `IFX-HDR-002` | Expected HDR Configuration | Instance |
| `IFX-HDR-003` | HDR Peer Discovery | Discovery |
| `IFX-HDR-004` | HDR Peer Connectivity | Peer |
| `IFX-HDR-005` | HDR Peer State and Sync Mode | Peer |
| `IFX-HDR-006` | HDR Last Acknowledgement Age | Peer |
| `IFX-HDR-007` | HDR Log Progress and Backlog | Peer |

No individual metric is approved until its own specification is approved.

---

## 9. Alerting Principles

Alerts shall distinguish configuration expectations from observed transport
state.

- Missing HDR is a problem only when `IFX_HDR_REQUIRED=YES`.
- A disconnected discovered HDR peer is a problem only when
  `IFX_HDR_ALERT_ON_DISCONNECT=YES`.
- A raw log-position difference is not sufficient by itself to represent lag.
- Log IDs rotate; log positions, acknowledgement time and backlog require
  source-specific interpretation.
- Thresholds for backlog and acknowledgement age require target-environment
  baselines.

Alerts shall include the discovered peer name and node type.

---

## 10. Mock Validation Strategy

No HDR environment exists in the development laboratory. Before implementation,
fixtures shall model the SQL-normalized data contract for these scenarios:

| Fixture | Required result |
|---|---|
| `standalone` | No HDR discovery; normal when HDR is not required |
| `primary-hdr-connected` | One connected HDR peer; no connectivity problem |
| `primary-hdr-disconnected` | One HDR peer; connectivity problem when alerting is enabled |
| `secondary-hdr-connected` | Local secondary with connected primary peer |
| `primary-hdr-and-rss` | HDR discovery includes HDR only; RSS remains context only |
| `hdr-required-but-absent` | Required-HDR problem |

Fixtures shall be test-only inputs. They shall not be installed or enabled in a
production runtime configuration.

---

## 11. Security and Deployment Principles

- SQL access shall be read-only.
- HDR parameters contain no Informix password.
- Credentials remain in the existing protected connection file.
- The collector must not require shell access to the Informix engine host solely
  to run `onstat`.
- The release must support installation, ordinary uninstallation and explicit
  purge through the existing parameterized deployment lifecycle.

---

## 12. Target-Environment Validation

Before HDR monitoring can become runtime validated, a real HDR environment must
confirm:

- availability and exact column set of `sysdri` and `syscluster`;
- SQL permissions of the monitoring identity;
- meaning of role, state and peer-status values in the deployed Informix version;
- behavior during connect, disconnect, failover and recovery;
- log progress, acknowledgement and backlog semantics;
- collection cost under production workload;
- expected primary/secondary topology and alert parameters.

---

## 13. Acceptance Boundary

Completion of this document approves only the architectural direction.

It does not approve implementation or assert that HDR was validated in the
development environment.
