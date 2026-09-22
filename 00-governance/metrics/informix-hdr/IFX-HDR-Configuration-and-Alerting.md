# IFX-HDR — Configuration and Alerting Policy

**Status:** `DEFINED`  
**Implementation status:** Documentation only. No collector, launcher, deployment integration, Zabbix item, or trigger is implemented by this document.

## 1. Purpose

Define the portable configuration policy for Informix HDR monitoring and the exact conditions under which Zabbix must consider HDR healthy, informational, or failed.

This policy supports installations where HDR is intentionally absent and installations where HDR is a required availability component.

## 2. Scope

This document governs the future `IFX-HDR-001` through `IFX-HDR-007` metrics.

It applies independently to each monitored Informix instance. A primary and a secondary are separate monitored hosts and can use different configuration values when their monitoring intent differs.

## 3. Configuration Parameters

### 3.1 `IFX_HDR_REQUIRED`

Accepted values: `YES` or `NO`.

Default: `NO`.

Meaning:

- `NO`: the instance may legitimately have no configured HDR peer. HDR absence is not an alert condition.
- `YES`: the instance is expected to participate in HDR. Absence of an HDR role, HDR peer, or required HDR relationship is an alert condition.

This parameter answers the question: **must this instance have HDR?**

### 3.2 `IFX_HDR_ALERT_ON_DISCONNECT`

Accepted values: `YES` or `NO`.

Default: `YES` when `IFX_HDR_REQUIRED=YES`; otherwise `NO`.

Meaning:

- `YES`: a discovered HDR peer that is not connected creates an alert.
- `NO`: peer connectivity is collected and visible, but a disconnected peer does not create an availability alert.

This parameter answers the question: **when HDR exists, should a disconnected relationship alert?**

### 3.3 `IFX_HDR_ACK_AGE_WARNING_SECONDS`

Accepted values: non-negative integer seconds, or empty to disable the warning threshold.

Default: empty.

Meaning: maximum acceptable age since the remote peer acknowledgement recorded by the engine, when the source and version expose an acknowledgement timestamp.

### 3.4 `IFX_HDR_ACK_AGE_HIGH_SECONDS`

Accepted values: non-negative integer seconds, or empty to disable the high threshold.

Default: empty.

Constraint: when both acknowledgement thresholds are configured, `IFX_HDR_ACK_AGE_HIGH_SECONDS` must be greater than or equal to `IFX_HDR_ACK_AGE_WARNING_SECONDS`.

### 3.5 `IFX_HDR_LOG_BACKLOG_WARNING`

Accepted values: non-negative integer, or empty to disable the warning threshold.

Default: empty.

Meaning: maximum tolerated measured log-progress backlog, only where the target Informix version exposes compatible progress fields and the unit is defined by the metric data contract.

### 3.6 `IFX_HDR_LOG_BACKLOG_HIGH`

Accepted values: non-negative integer, or empty to disable the high threshold.

Default: empty.

Constraint: when both backlog thresholds are configured, `IFX_HDR_LOG_BACKLOG_HIGH` must be greater than or equal to `IFX_HDR_LOG_BACKLOG_WARNING`.

## 4. Parameter Validation

Before any HDR collection begins, the future runtime must validate the parameters.

Invalid values must cause a collector failure with a precise error on standard error. They must never silently fall back to another value.

Examples of invalid configuration:

- `IFX_HDR_REQUIRED=MAYBE`
- `IFX_HDR_ALERT_ON_DISCONNECT=1`
- negative acknowledgement-age or backlog thresholds
- a high threshold lower than its warning threshold

## 5. Alert Decision Matrix

| Local HDR condition | `IFX_HDR_REQUIRED` | `IFX_HDR_ALERT_ON_DISCONNECT` | Expected monitoring outcome |
|---|---:|---:|---|
| Local instance has no HDR role or HDR peer | `NO` | either | Healthy; HDR is optional. |
| Local instance has no HDR role or HDR peer | `YES` | either | Problem: required HDR relationship is absent. |
| HDR peer is discovered and connected | either | either | Healthy, subject to optional lag thresholds. |
| HDR peer is discovered but connecting | `NO` | `NO` | Collected as non-healthy state; no availability problem. |
| HDR peer is discovered but connecting | either | `YES` | Problem: HDR peer is not connected. |
| HDR peer is disconnected or failed | `NO` | `NO` | Collected as non-healthy state; no availability problem. |
| HDR peer is disconnected or failed | either | `YES` | Problem: HDR peer is not connected. |
| Acknowledgement age exceeds warning threshold | either | either | Warning, if threshold is configured and source value is available. |
| Acknowledgement age exceeds high threshold | either | either | High, if threshold is configured and source value is available. |
| Backlog exceeds warning threshold | either | either | Warning, if threshold is configured and source value is available. |
| Backlog exceeds high threshold | either | either | High, if threshold is configured and source value is available. |

## 6. Absence, Unknown, and Failure Are Different States

The implementation must preserve these distinctions:

| State | Meaning | Zabbix treatment |
|---|---|---|
| `ABSENT` | HDR is not configured or no HDR peer is found. | Healthy only when HDR is optional; otherwise a problem. |
| `CONNECTED` | A discovered HDR peer is connected. | Healthy, subject to configured lag thresholds. |
| `NOT_CONNECTED` | A peer exists but is connecting, disconnected, or failed. | Alert only when disconnect alerting is enabled. |
| `UNKNOWN` | The engine source does not expose a required field or target compatibility is not validated. | Item should be unsupported or explicitly unknown; never reported as healthy. |
| `COLLECTOR_FAILURE` | SQL execution, parsing, permissions, or configuration validation failed. | Item failure; distinct from an HDR operational state. |

## 7. Zabbix Trigger Policy

Future Zabbix triggers must be based on normalized dependent values, not on free-form collector text.

The intended priorities are:

| Condition | Intended priority |
|---|---|
| HDR required but absent | High |
| Connected HDR peer becomes disconnected or failed | High |
| Peer remains in connecting state beyond its defined grace period | Warning or High, to be finalized with target operations policy |
| Acknowledgement age crosses warning threshold | Warning |
| Acknowledgement age crosses high threshold | High |
| Log backlog crosses warning threshold | Warning |
| Log backlog crosses high threshold | High |

No threshold trigger must be created until its source field, unit, and version compatibility are validated on a real HDR environment.

## 8. Recommended Per-Host Configuration Examples

### 8.1 Standalone development instance

```ksh
IFX_HDR_REQUIRED=NO
IFX_HDR_ALERT_ON_DISCONNECT=NO
```

### 8.2 Production primary where HDR is mandatory

```ksh
IFX_HDR_REQUIRED=YES
IFX_HDR_ALERT_ON_DISCONNECT=YES
```

### 8.3 Secondary monitored only for visibility during commissioning

```ksh
IFX_HDR_REQUIRED=YES
IFX_HDR_ALERT_ON_DISCONNECT=NO
```

The third example still identifies that HDR is required, but suppresses a connectivity alert only for the explicitly chosen commissioning period. This must not be the permanent production default without an operational decision.

## 9. Security and Deployment Boundary

These parameters belong in the private Zabbix Informix configuration area, not in the Git repository and not in the Zabbix item key.

They do not contain credentials, but they are environment-specific operational policy and must be installed through the portable deployment process.

## 10. Acceptance Criteria

Before HDR implementation begins, this policy is accepted when:

- the operations owner selects the required/disconnect behavior for each target role;
- optional lag thresholds are either defined with units or explicitly deferred;
- the mock-validation plan covers each row of the alert decision matrix;
- a real HDR target will be available for final source and trigger validation.

