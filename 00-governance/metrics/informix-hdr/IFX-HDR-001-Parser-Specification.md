# IFX-HDR-001 — Parser Specification

## Current Operational Status

`DEFINED`

No HDR SQL statement, collector, parser, launcher, Zabbix item, or template definition exists yet.

## 1. Purpose

Define the future normalized-output contract for `IFX-HDR-001 — Local Role and State`.

## 2. Candidate Input Contract

The approved HDR master payload will contain one `local` object:

```json
{
  "schema_version": 1,
  "local": {
    "role": "PRIMARY",
    "state": "ON",
    "configured_peer_name": "ifx_hdr_secondary"
  },
  "hdr_peers": []
}
```

The future parser extracts `role`, `state`, and `configured_peer_name`. It does not independently query Informix.

## 3. Valid Value Domains

| Field | Valid normalized values |
|---|---|
| `role` | `PRIMARY`, `SECONDARY`, `STANDARD`, `NOT_INITIALIZED`, `UNKNOWN` |
| `state` | `ON`, `OFF`, `CONNECTING`, `FAILURE`, `READ_ONLY`, `UNKNOWN` |
| `configured_peer_name` | Empty string or a non-empty validated peer name. |

## 4. Invalid Input

The parser must fail rather than infer a healthy value when:

- JSON is malformed;
- `schema_version` is unsupported;
- `local` is absent or not an object;
- `role` or `state` is absent;
- a value is outside the approved normalized domain.

## 5. Output Contract

Proposed dependent values:

```text
ifx.hdr.local.role
ifx.hdr.local.state
ifx.hdr.local.configured_peer
```

`UNKNOWN` is a valid explicit normalized value. It is not equivalent to an absent payload or collection failure.

## 6. Mock Validation

Validate `standalone`, `primary-hdr-connected`, `secondary-hdr-connected`, and `primary-hdr-failed` fixtures. Each must yield its stated normalized local role/state without coercion.

## 7. Acceptance Criteria

- Target `sysdri` values are evidenced and mapped.
- The payload schema is approved.
- Malformed source data cannot become `STANDARD`/`OFF` by default.

