# IFX-HDR-004 — Parser Specification

**Status:** `DEFINED`; real remote connection values pending.

## 1. Input

Receive one **proven remote HDR** peer record for `{#IFX_HDR_PEER}`, including raw `syscluster.connection_status`. The standalone local `syscluster` row is never an input to this peer parser. Preserve raw status for diagnosis.

## 2. Proposed normalized output

| Value | State |
|---:|---|
| `0` | `UNKNOWN` |
| `1` | `CONNECTED` |
| `2` | `CONNECTING` |
| `3` | `DISCONNECTED` |
| `4` | `FAILED` |

Exact source-string mappings require observation on a real HDR pair. Blank, missing, or unrecognized remote status cannot map to `CONNECTED`. Malformed payload, wrong peer identity, or unsupported schema version fails the dependent item or emits explicit unknown according to the final parser contract.

## 3. Policy and acceptance

The parser reports state; it does not suppress an alert. On required HDR, values `2`–`4` are High at the first observed sample, and `0` requires monitoring-integrity handling. `IFX_HDR_ALERT_ON_DISCONNECT=NO` is invalid when HDR is required. A disappeared peer is reported by instance-level HDR-002, not silently resolved through prototype deletion.

Validate connected, connecting, disconnected, failed, disappearance, and recovery from real primary and secondary SQL output before source mappings or triggers are approved. No mock HDR transition is accepted as proof.
