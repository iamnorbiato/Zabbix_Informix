# IFX-HDR-002 — Parser Specification

## Current Operational Status

`DEFINED`

No HDR parser or Zabbix dependent item exists yet.

## 1. Purpose

Define the future normalization of HDR configuration compliance for `IFX-HDR-002 — Expected HDR Configuration`.

## 2. Input Contract

The evaluator receives:

- valid `IFX_HDR_REQUIRED` value: `YES` or `NO`;
- normalized `local.role`;
- normalized `local.state`;
- count of discovered HDR peers.

It does not parse unstructured Informix output.

## 3. Output Domain

| Numeric output | Meaning |
|---:|---|
| `0` | `NOT_REQUIRED` |
| `1` | `COMPLIANT` |
| `2` | `REQUIRED_BUT_ABSENT` |
| `3` | `UNKNOWN` |

## 4. Evaluation Contract

`IFX_HDR_REQUIRED=NO` with a standalone/no-peer result produces `0`.

`IFX_HDR_REQUIRED=YES` with a primary or secondary role and at least one HDR peer produces `1`.

`IFX_HDR_REQUIRED=YES` without the required HDR relationship produces `2`.

Missing or unrecognized source fields produce `3`, never `0` or `1`.

## 5. Invalid Input

The evaluator fails for an invalid policy value, negative/non-numeric peer count, malformed master payload, or unsupported schema version.

## 6. Mock Validation

Validate `standalone` with policy `NO` => `0`; `hdr-required-but-absent` with `YES` => `2`; connected primary/secondary with `YES` => `1`.

## 7. Acceptance Criteria

- Policy configuration is validated strictly.
- Absence, unknown and collection failure remain distinct.
- The output supports deterministic Zabbix trigger evaluation.

