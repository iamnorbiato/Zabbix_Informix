# IFX-HDR — Configuration and Alerting Policy

**Status:** `DEFINED`; standalone source evidence recorded, HDR-connected and failure transitions unvalidated.
**Implementation status:** Documentation only. This document does not install collectors, items, or triggers.

## 1. Purpose and monitoring boundary

Distinguish an intentionally standalone Informix instance from an instance that must participate in HDR, and alert on any observed degradation of a required HDR relationship. Apply this policy independently to each monitored Informix instance, including primary and secondary.

SQL collection uses the local instance's `sysmaster:sysdri` and `sysmaster:syscluster`. No production collector depends on `onstat` or fabricated HDR data.

Monitoring can only detect conditions represented by a successful sample. A transient that begins and ends entirely between samples cannot be guaranteed detectable by periodic SQL polling; collection interval and operational expectations must account for this limit.

## 2. Configuration

### `IFX_HDR_REQUIRED`

Accepted values: `YES` or `NO`. Default: `NO`.

- `NO`: this instance is intentionally permitted to run without HDR. An observed standalone state is normal and generates no HDR problem.
- `YES`: this instance must participate in HDR. Missing local HDR configuration, missing peer identity, missing qualifying HDR relationship, or loss of that relationship is a High problem.

Set `YES` on **both** monitored members of a required primary/secondary pair. `NO` cannot guarantee an alert if an HDR relationship disappears completely, because its resulting no-HDR state is intentionally allowed by policy.

### `IFX_HDR_EXPECTED_PEER`

Accepted value: the exact Informix server name of the intended remote HDR member. It is required when `IFX_HDR_REQUIRED=YES` and must be empty when `IFX_HDR_REQUIRED=NO`.

The expected peer is configuration, not a value learned only from the currently observed topology. This prevents a failed or replaced peer from silently redefining what the monitoring system considers correct. A missing or different observed partner is a High problem. The exact case and whitespace normalization rules must be confirmed against real HDR source output before implementation.

### `IFX_HDR_ALERT_ON_DISCONNECT`

This previously proposed switch must not suppress a problem for a required HDR relationship. The supported operational setting for an HDR installation is `YES`. `NO` is permitted only for an intentionally standalone installation with `IFX_HDR_REQUIRED=NO`; if HDR is observed while this switch is `NO`, report a policy-configuration problem rather than silently suppressing HDR failure alerts.

The future installer and collector must validate both parameters before publishing a healthy state. Invalid or contradictory values must not fall back silently.

### Optional lag thresholds

`IFX_HDR_ACK_AGE_WARNING_SECONDS`, `IFX_HDR_ACK_AGE_HIGH_SECONDS`, `IFX_HDR_LOG_BACKLOG_WARNING`, and `IFX_HDR_LOG_BACKLOG_HIGH` remain undefined by default. They must not produce triggers until the source values, units, idle behavior, and rollover behavior are proven on real HDR. Configured High thresholds must be greater than or equal to their Warning counterparts.

## 3. Observed standalone baseline (development Informix)

The following results were obtained from successful read-only SQL queries against `sysmaster` on the development instance `ol_informix1210`:

| Source | Observed result | Interpretation for this instance |
|---|---|---|
| `sysdri` | `type=Not Initialized`, `state=Off`, empty `name`, `intvl=0`, `timeout=30` | HDR is not initialized; there is no reported HDR partner. |
| `syscluster` | One row: `name=ol_informix1210`, `role=P`, `nodetype=PRIMARY`, `syncmode=SYNC`, `server_status=Active`, empty `connection_status` | This is a local-instance row. It is **not** evidence of a connected remote HDR peer. |

The local `syscluster` row must be excluded from peer discovery and must not be classified as a disconnected remote peer. A blank `connection_status` on this observed standalone local row is not an HDR fault. The same blank field on a proven remote HDR row must not be treated as healthy.

These observations establish only the no-HDR baseline. They do not validate any connected/disconnected HDR source value or transition.

## 4. Alert decision matrix

| Successful SQL observation | `IFX_HDR_REQUIRED` | Outcome |
|---|---|---|
| Confirmed standalone baseline; no remote HDR relationship | `NO` | Normal; no HDR alert. |
| Confirmed standalone baseline; no remote HDR relationship | `YES` | High: required HDR absent. |
| An observed partner differs from `IFX_HDR_EXPECTED_PEER` | `YES` | High: wrong HDR partner or partner identity cannot be verified. |
| Remote HDR relationship present and all validated role, connection, and server states healthy | `YES` | Normal, subject to separately validated lag thresholds. |
| Remote HDR relationship present but connection is connecting, disconnected, failed, blank, or unrecognized | `YES` | High: HDR relationship not confirmed healthy. Preserve raw source values. |
| Remote HDR relationship present but server state is not the validated operational state | `YES` | High: HDR peer state abnormal. Preserve raw source values. |
| HDR relationship observed while policy says `NO` and disconnect alerting says `NO` | `NO` | High policy-configuration problem; never silently suppress an observed HDR fault. |
| Required HDR relationship disappears from discovery | `YES` | High: required HDR absent, regardless of whether a per-peer item remains discoverable. |
| SQL, parsing, permission, or configuration validation fails | either | Collection/monitoring failure; never publish a synthetic healthy HDR state. |

The exact source strings that mean connected and operational must be recorded from a real HDR pair before implementing those positive mappings. An unknown value is not equivalent to `CONNECTED`.

## 5. Trigger ownership and lifecycle

- An **instance-level** required-HDR trigger must remain evaluable even when no peer is discovered. It owns the “required but absent” condition; a peer-only discovery trigger cannot provide this guarantee.
- Peer connection and peer server-state triggers own observed transport/operational degradation. They fire on the first successfully collected abnormal sample; there is no unapproved 90-second grace period.
- A separate collection-failure or `nodata` trigger is required where loss of SQL telemetry would otherwise hide an HDR problem. Its time window must be set from the real polling interval and tested before deployment.
- Recovery requires a successful sample showing the required relationship restored and its validated connection/server states healthy. A missing value, failed query, or vanished peer must not resolve a problem.
- `IFX_HDR_EXPECTED_PEER` identifies the intended partner independently of discovery. A discovered different partner must not satisfy required-HDR compliance.
- Avoid duplicate incident noise: an instance-level absence problem supersedes peer-specific connection problems when the peer disappears; lag alerts require a confirmed connected relationship.

## 6. Failure states

| State | Meaning | Treatment |
|---|---|---|
| `ABSENT` | Successful collection confirms no HDR relationship. | Normal only when `IFX_HDR_REQUIRED=NO`. |
| `CONNECTED` | Real-HDR source values have been validated as healthy. | Normal, subject to separately validated thresholds. |
| `NOT_CONNECTED` | Proven remote HDR relationship is not connected. | High when HDR is required. |
| `ABNORMAL_STATE` | Proven remote HDR relationship has an unhealthy server/role state. | High when HDR is required. |
| `UNKNOWN` | A required source field is absent or its meaning is unvalidated. | Never healthy; expose as unknown/unsupported and alert on monitoring integrity for required HDR. |
| `COLLECTOR_FAILURE` | SQL, parsing, permission, or configuration failure. | Non-zero collection result and independent monitoring-integrity alert. |

## 7. Per-host examples

Development standalone instance:

```ksh
IFX_HDR_REQUIRED=NO
IFX_HDR_ALERT_ON_DISCONNECT=NO
IFX_HDR_EXPECTED_PEER=
```

Production HDR primary **and** secondary, independently:

```ksh
IFX_HDR_REQUIRED=YES
IFX_HDR_ALERT_ON_DISCONNECT=YES
IFX_HDR_EXPECTED_PEER='nome_do_servidor_informix_parceiro'
```

These environment-specific settings belong in the private Zabbix Informix configuration area, not in Git or in Zabbix item keys. They do not contain Informix credentials.

## 8. Evidence and acceptance

The development standalone result is source-validated. Before production acceptance, a real HDR pair must establish the exact local and remote `sysdri`/`syscluster` rows and demonstrate healthy, connecting, disconnected, failed, disappeared, recovered, and (where operationally safe) role-transition behavior. Primary and secondary must each be observed through their own `sysmaster` connection. Lag/acknowledgement thresholds remain deferred until their semantics are proven.

No mock or fabricated HDR sample is accepted as a substitute for that source evidence. Documentation approval does not imply runtime validation of HDR-connected behavior.
