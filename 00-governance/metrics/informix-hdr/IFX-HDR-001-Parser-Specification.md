# IFX-HDR-001 — Parser Specification

## Current Operational Status

`DEVELOPMENT_RUNTIME_VALIDATED`

The real sysdri SQL statement, strict pipe-delimited collector, parameterized launcher, Zabbix Agent active check, raw Zabbix item, and exported template definition were validated in the standalone Linux development topology. Real HDR-pair role and state mappings remain pending.

## 1. Purpose

Define and document the validated pipe-delimited output contract for `IFX-HDR-001 — Local Role and State`.

## 2. Implemented Source and Output Contract

The proposed HDR master payload will contain one `local` object. The following normalized standalone values derive from the observed real `sysdri` output; the JSON envelope remains a design proposal:

The implemented SQL source is `sysmaster:sysdri`. The collector validates exactly one row and emits:

```text
<type>|<state>|<name>
```

For the real standalone development instance, the validated output is:

```text
Not Initialized|Off|
```

An empty `name` is emitted as an empty final field. The collector does not normalize unvalidated HDR-pair values and does not claim that a standalone row represents a remote peer.

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

## 6. Real Source Validation

Standalone `sysdri` values (`Not Initialized`, `Off`, empty partner) were observed on real development Informix. Capture `sysdri` on both members of a real HDR pair during healthy, disrupted, and recovered states before approving other role/state mappings. Do not use fabricated HDR input as source proof.

## 7. Acceptance Criteria

- Target `sysdri` values are evidenced and mapped.
- The payload schema is approved.
- Malformed source data cannot become `STANDARD`/`OFF` by default.

