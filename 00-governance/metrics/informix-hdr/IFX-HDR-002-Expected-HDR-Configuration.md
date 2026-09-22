# IFX-HDR-002 — Expected HDR Configuration

**Status:** `DEFINED`  
**Implementation status:** Not implemented.  
**Collection database:** `sysmaster` through the HDR master data contract.  
**Runtime method:** SQL-derived data plus private deployment configuration; no `onstat` execution.

## 1. Objective

Evaluate whether the monitored instance has the HDR configuration that its local monitoring policy requires.

This metric makes absence explicit. It does not confuse an intentional standalone instance with an instance that should participate in HDR but does not.

## 2. Inputs

| Input | Source | Meaning |
|---|---|---|
| `IFX_HDR_REQUIRED` | Private Zabbix Informix configuration | Whether HDR is mandatory for this instance. |
| `local_role` | `IFX-HDR-001` / HDR master payload | Normalized local role. |
| `local_state` | `IFX-HDR-001` / HDR master payload | Normalized local state. |
| `hdr_peer_count` | `IFX-HDR-003` / HDR master payload | Number of discovered HDR peers. |

`IFX_HDR_REQUIRED` accepts only `YES` or `NO`; any other value is a collector configuration error.

## 3. Normalized Result

The future dependent item must expose one numeric compliance value:

| Value | Name | Meaning |
|---:|---|---|
| `0` | `NOT_REQUIRED` | HDR is optional and no HDR relationship is present. |
| `1` | `COMPLIANT` | HDR is required and a valid HDR role/relationship is present; or HDR is optional and a relationship is present. |
| `2` | `REQUIRED_BUT_ABSENT` | HDR is required but the local role or HDR peer relationship is absent. |
| `3` | `UNKNOWN` | Required source input is unavailable or unrecognized. |

The textual state must be retained in the raw/master payload or represented through Zabbix value mapping. The numeric result is intended for dependable trigger expressions.

## 4. Evaluation Rules

| `IFX_HDR_REQUIRED` | Local role | HDR peer count | Result |
|---|---|---:|---|
| `NO` | `STANDARD` or `NOT_INITIALIZED` | `0` | `NOT_REQUIRED` (`0`) |
| `NO` | `PRIMARY` or `SECONDARY` | `>=1` | `COMPLIANT` (`1`) |
| `NO` | any recognized role | any | `COMPLIANT` (`1`) unless source is unknown |
| `YES` | `PRIMARY` or `SECONDARY` | `>=1` | `COMPLIANT` (`1`) |
| `YES` | `STANDARD` or `NOT_INITIALIZED` | `0` | `REQUIRED_BUT_ABSENT` (`2`) |
| `YES` | `PRIMARY` or `SECONDARY` | `0` | `REQUIRED_BUT_ABSENT` (`2`) pending target confirmation of transitional behavior |
| either | `UNKNOWN`, missing, or source unavailable | any | `UNKNOWN` (`3`) |

The initial design is deliberately strict for `IFX_HDR_REQUIRED=YES`: a role without a discovered HDR peer is not considered compliant. A documented temporary exception may be introduced later only after real target validation shows a legitimate stable state.

## 5. Zabbix Design

| Element | Proposed value |
|---|---|
| Dependent item key | `ifx.hdr.expected_configuration` |
| Value type | Numeric unsigned |
| Value mapping | `0=Not required`, `1=Compliant`, `2=Required but absent`, `3=Unknown` |
| Master source | `ifx.hdr.local.raw` or approved common HDR master item |
| Update interval | Inherited from HDR master collection; initial target: 60 seconds. |

The item must be dependent. It must not independently reconnect to Informix or reread private configuration outside the approved collector/master execution path.

## 6. Trigger Policy

Proposed trigger:

| Condition | Proposed severity | Meaning |
|---|---|---|
| Latest result is `2` | High | HDR is explicitly required but absent. |

`UNKNOWN` must not be silently treated as a healthy result. The final treatment—item unsupported versus a separate data-quality trigger—will be decided after target validation.

## 7. Examples

### 7.1 Standalone development instance

Configuration:

```ksh
IFX_HDR_REQUIRED=NO
```

Observed local data:

```text
local_role=STANDARD
hdr_peer_count=0
```

Expected result: `0` (`NOT_REQUIRED`). No problem.

### 7.2 Required production primary with connected secondary

Configuration:

```ksh
IFX_HDR_REQUIRED=YES
```

Observed local data:

```text
local_role=PRIMARY
hdr_peer_count=1
```

Expected result: `1` (`COMPLIANT`).

### 7.3 Required HDR relationship missing

Configuration:

```ksh
IFX_HDR_REQUIRED=YES
```

Observed local data:

```text
local_role=STANDARD
hdr_peer_count=0
```

Expected result: `2` (`REQUIRED_BUT_ABSENT`). High problem.

## 8. Failure Behavior

| Condition | Expected behavior |
|---|---|
| Parameter is invalid | Collector/configuration failure with explicit standard-error message. |
| Master payload is invalid | Dependent item becomes unsupported or returns documented unknown state; never `0` or `1` by default. |
| `local_role` is unknown | Result is `3` (`UNKNOWN`). |
| Peer discovery cannot be performed | Result is not compliant; preserve source failure separately. |

## 9. Mock Validation

| Fixture | `IFX_HDR_REQUIRED` | Expected result |
|---|---|---:|
| `standalone` | `NO` | `0` |
| `hdr-required-but-absent` | `YES` | `2` |
| `primary-hdr-connected` | `YES` | `1` |
| `secondary-hdr-connected` | `YES` | `1` |
| `unknown-peer-status` with valid role/peer | `YES` | `1`; connectivity is evaluated by a separate metric |

## 10. Acceptance Criteria

- The parameter behavior matches the approved configuration and alerting policy.
- A no-HDR instance is distinguishable from a failed query.
- The high-severity condition is limited to an explicitly required but absent HDR relationship.
- The evaluation is reproducible through approved mock fixtures.
- Target validation confirms whether transitional states require a grace period or exception.

