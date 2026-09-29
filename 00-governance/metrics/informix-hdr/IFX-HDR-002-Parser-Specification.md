# IFX-HDR-002 — Parser Specification

**Status:** `DEFINED`; standalone source evidence recorded, real HDR mapping pending.

## 1. Inputs

Receive validated `IFX_HDR_REQUIRED`, `IFX_HDR_ALERT_ON_DISCONNECT`, and `IFX_HDR_EXPECTED_PEER` policy values; a fresh local `sysdri` record; and classified remote HDR candidates from `syscluster`. The parser must exclude the local row and must not equate total `syscluster` row count with peer count.

`IFX_HDR_EXPECTED_PEER` is mandatory when `IFX_HDR_REQUIRED=YES`. `IFX_HDR_ALERT_ON_DISCONNECT` must then be `YES`. Invalid combinations fail configuration validation and never generate a healthy value.

## 2. Output domain

| Numeric value | Meaning |
|---:|---|
| `0` | `NOT_REQUIRED`: proven standalone and policy `NO`. |
| `1` | `EXPECTED_RELATIONSHIP_PRESENT`: required role and exact expected partner observed; connectivity/operational state evaluated separately. |
| `2` | `REQUIRED_BUT_ABSENT_OR_WRONG`: required relationship/partner missing or different. |
| `3` | `UNKNOWN`: a required source field or row classification is untrusted. |

SQL/collector failure yields no synthetic output. A currently observed HDR relationship under an intentionally standalone policy is a configuration mismatch, not `NOT_REQUIRED`.

## 3. Evidence and acceptance

On the real standalone development instance, `sysdri=Not Initialized/Off` and the sole `syscluster` row is local; with `IFX_HDR_REQUIRED=NO`, the expected result is `0`. The same real SQL evidence under an isolated `YES` policy with an explicit expected partner should yield `2`. A real HDR pair is needed to prove `1`, disappearance, wrong partner, and recovery. No mock HDR fixture substitutes for this evidence.
