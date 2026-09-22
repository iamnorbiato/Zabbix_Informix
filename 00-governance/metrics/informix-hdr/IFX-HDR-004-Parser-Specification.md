# IFX-HDR-004 — Parser Specification

## Current Operational Status

`DEFINED`

No HDR connectivity parser, dependent prototype, or trigger exists yet.

## 1. Purpose

Define normalization of a discovered peer's engine-reported HDR connection state.

## 2. Input Contract

One peer object identified by `{#IFX_HDR_PEER}` with `peer_connection_status` from the validated HDR master payload.

## 3. Output Domain

| Numeric output | Normalized state |
|---:|---|
| `0` | `UNKNOWN` |
| `1` | `CONNECTED` |
| `2` | `CONNECTING` |
| `3` | `DISCONNECTED` |
| `4` | `FAILED` |

## 4. Normalization Rules

Known target engine values map only after real-HDR evidence. Absent or unrecognized values map to `UNKNOWN`; they must never become `CONNECTED`.

## 5. Invalid Input

Malformed payload, absent peer identity, missing connection-status property, or unsupported schema version must fail the parser/item rather than publish a healthy state.

## 6. Policy Boundary

The parser reports state only. `IFX_HDR_ALERT_ON_DISCONNECT` controls trigger behavior and must not change the normalized value.

## 7. Mock Validation

Validate connected, connecting, disconnected, failed and unknown fixtures. Confirm that state transitions resolve only after the same peer is `CONNECTED` again.

## 8. Acceptance Criteria

- Target state strings are mapped with evidence.
- `UNKNOWN` remains distinguishable from a disconnected peer.
- Trigger configuration consumes numeric output, not free-form text.

