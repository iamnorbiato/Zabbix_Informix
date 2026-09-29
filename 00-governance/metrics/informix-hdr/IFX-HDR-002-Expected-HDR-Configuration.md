# IFX-HDR-002 — Expected HDR Configuration

**Status:** `DEVELOPMENT_RUNTIME_VALIDATED`; standalone source and required-HDR absence behavior validated; required-HDR behavior on a real pair pending.
**Implementation status:** Implemented and validated in the standalone Linux development topology.
**Collection database:** `sysmaster` plus private expected-topology configuration.

## 1. Objective

Evaluate whether the monitored instance has the intended HDR relationship. This is an **instance-level** metric: it must continue to exist and alert even when no remote HDR peer is discoverable.

## 2. Inputs

| Input | Source | Rule |
|---|---|---|
| `IFX_HDR_REQUIRED` | Private deployment configuration | `YES` or `NO`; `YES` on both members of a required HDR pair. |
| `IFX_HDR_EXPECTED_PEER` | Private deployment configuration | Exact intended remote Informix server name; required with `YES`, empty with `NO`. |
| `IFX_HDR_ALERT_ON_DISCONNECT` | Private deployment configuration | Must be `YES` when HDR is required; `NO` only for intentionally standalone instances. |
| Local role/state and engine-reported partner | `sysmaster:sysdri` | Must come from a successful query. |
| Remote HDR candidate records | `sysmaster:syscluster` | Exclude the local row; classify remote rows only with validated HDR rules. |

Invalid or contradictory configuration is a collection/configuration error, never a healthy result.

## 3. Proposed output

| Value | Name | Meaning |
|---:|---|---|
| `0` | `NOT_REQUIRED` | A successful SQL sample proves no HDR relationship, and `IFX_HDR_REQUIRED=NO`. |
| `1` | `EXPECTED_RELATIONSHIP_PRESENT` | Required local HDR role and exact expected partner are present in validated source records. Connection and operational health are evaluated separately by HDR-004/005. |
| `2` | `REQUIRED_BUT_ABSENT_OR_WRONG` | Required relationship or exact expected partner is absent or different. |
| `3` | `UNKNOWN` | Required source field is absent/unrecognized or topology classification cannot be trusted. Never healthy. |

Do not derive `1` from `syscluster` row count alone. The development standalone instance returned one **local** `syscluster` row while `sysdri` was `Not Initialized`/`Off` with no partner.

## 4. Evaluation

| Policy and successful SQL observation | Result | Alert |
|---|---:|---|
| `NO`, proven standalone/no remote HDR | `0` | None. |
| `YES`, proven standalone/no remote HDR | `2` | High. |
| `YES`, observed partner missing or different from `IFX_HDR_EXPECTED_PEER` | `2` | High. |
| `YES`, expected relationship present with validated role/identity | `1` | No HDR-002 problem; HDR-004/005 still decide connection/state health. |
| Unexpected or unvalidated source values | `3` | Monitoring-integrity problem; do not claim compliance. |
| SQL failure or no fresh sample | No synthetic value | Collection/`nodata` problem. |

If policy says `NO` while an HDR relationship is observed, the result must not be called `NOT_REQUIRED`; report policy mismatch and require explicit configuration correction. A currently observed relationship cannot silently redefine the intended partner.

## 5. Zabbix design

Proposed dependent numeric item key: `ifx.hdr.expected_configuration`. Its High trigger fires for value `2`. A separate High monitoring-integrity trigger covers `3`, unsupported item, collector error, or `nodata` on a required-HDR host. Exact expressions will be set through the Zabbix UI and exported as a complete template, following the project's established workflow.

The item must not depend on a discovered peer prototype: when the peer disappears, this instance-level item remains evaluable. Recovery requires a fresh successful sample showing the intended partner present. A stale value or deletion of a discovery resource cannot resolve the problem.

## 6. Evidence and acceptance

The real development baseline supports `NO` => `0` and, with monitoring policy changed in an isolated test, `YES` => `2` against the **same real SQL output**. This does not validate a real HDR outage. A real primary and secondary are required to prove that the expected peer identity, row classification, disappearance, and restoration behave as designed. No mock HDR row or fixture is an acceptance substitute.
