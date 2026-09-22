# IFX-HDR-005 — Parser Specification

## Current Operational Status

`DEFINED`

No parser or Zabbix item prototypes exist yet.

## 1. Purpose

Define normalization of peer role, peer server state and synchronization mode for `IFX-HDR-005 — HDR Peer State and Sync Mode`.

## 2. Input Contract

One discovered HDR peer object must provide `peer_role`, `peer_server_status` and `sync_mode` after target source validation.

## 3. Normalized Domains

| Field | Valid normalized values |
|---|---|
| `peer_role` | `PRIMARY`, `SECONDARY`, `UNKNOWN` |
| `peer_server_status` | `ACTIVE`, `INACTIVE`, `RECOVERING`, `FAILED`, `UNKNOWN` |
| `sync_mode` | `SYNC`, `ASYNC`, `UNKNOWN` |

## 4. Output Contract

The future parser yields one dependent value per field, keyed by `{#IFX_HDR_PEER}`. Numeric value mappings are preferred for trigger-capable states; raw source strings remain in the master payload.

## 5. Invalid Input

Missing required fields, malformed JSON and unsupported schema fail clearly. Unrecognized source values normalize to `UNKNOWN` only where a valid source record exists.

## 6. Deferred Fields

`delayed_apply` and `stop_apply` are not parser inputs until their target availability and semantics are validated.

## 7. Mock Validation

Validate complementary primary/secondary roles, active peer state, sync/async values and unknown values without coercion.

## 8. Acceptance Criteria

- Target values for all three fields are mapped.
- A role transition is not falsely classified as stable healthy state.
- Sync-mode visibility is separate from any future desired-mode policy.

