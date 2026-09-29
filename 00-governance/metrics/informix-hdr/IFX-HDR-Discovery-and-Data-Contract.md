# IFX-HDR — Discovery and Data Contract

**Status:** `DEFINED`; standalone source evidence recorded, remote HDR mapping pending.
**Implementation status:** Documentation only; no SQL statement, collector, Zabbix discovery rule, or trigger is implemented here.

## 1. Sources and observed baseline

Query each monitored instance's own `sysmaster` database through the existing read-only SQL collector path. Use `sysdri` for local role/state/partner and `syscluster` for candidate cluster and peer fields. Do not use `onstat`, fabricated HDR data, or unverified `sysha_*`/`sysrephdr` objects.

On development instance `ol_informix1210`, `sysdri` returned `Not Initialized`, `Off`, and an empty partner name. `syscluster` returned **one local row** named `ol_informix1210`, with `role=P`, `nodetype=PRIMARY`, `server_status=Active`, and blank `connection_status`. Accordingly, a successful one-row `syscluster` result can still mean **zero remote HDR peers**.

## 2. Local record

| Normalized field | Source | Requirement |
|---|---|---|
| `local_server_name` | Explicit monitored `INFORMIXSERVER` identity | Required to identify the queried instance independently of cluster row order. |
| `local_role_raw` | `sysdri.type` | Preserve source spelling and normalize only validated values. |
| `local_state_raw` | `sysdri.state` | Preserve source spelling and normalize only validated values. |
| `configured_peer_name_raw` | `sysdri.name` | May be empty on proven standalone instance. |
| `dr_interval`, `dr_timeout` | `sysdri.intvl`, `sysdri.timeout` | Diagnostic values; do not infer health from them alone. |

Source query failure, missing required columns, or an unexpected number of local `sysdri` rows is not a standalone result.

## 3. Classifying `syscluster` rows

Do **not** treat every row as a remote peer. Classify each row as local, candidate remote HDR, other HA technology, or unknown. The observed row named exactly as the queried `INFORMIXSERVER` is local and must be excluded from remote-peer discovery.

For remote HDR, require a validated node-type value and a non-local server name. `sysdri.name` and the independently configured `IFX_HDR_EXPECTED_PEER` must be evaluated alongside candidate `syscluster` rows. The exact remote-row predicate, `nodetype` values, and primary/secondary asymmetry must be confirmed on a real HDR pair before enabling peer discovery. A blank or unrecognized field on a candidate remote row must remain unknown, not healthy.

RSS and SDS rows must not satisfy an HDR requirement. Duplicate or ambiguous remote identities are collection/normalization errors, not healthy discoveries.

## 4. Candidate peer fields

| Field | Candidate source | Status |
|---|---|---|
| `peer_name` | `syscluster.name` | Identity rule pending real HDR validation. |
| `peer_node_type` | `syscluster.nodetype` | HDR-vs-local/RSS/SDS mapping pending. |
| `peer_role` | `syscluster.role` | Meaning pending on both primary and secondary. |
| `peer_connection_status` | `syscluster.connection_status` | Healthy and unhealthy source strings pending. |
| `peer_server_status` | `syscluster.server_status` | Healthy and unhealthy source strings pending. |
| `sync_mode` | `syscluster.syncmode` | Collect raw value; policy semantics pending. |
| `ack_time` | `syscluster.ack_time` | Deferred until timestamp meaning is proven. |
| sent/acked/applied log IDs and pages | `syscluster` progress columns | Deferred until units, ordering, and rollover are proven. |

Preserve raw strings in diagnostics. Normalized values are not allowed to invent a healthy state for an unknown source string.

## 5. Proposed collection and discovery contract

The future master collector must represent local state independently of peer discovery. A successful, proven standalone result has an empty remote HDR peer list, even though `syscluster` has a local row. This is a proposed schema illustration of the **observed standalone** condition, not a fabricated HDR sample:

```json
{
  "schema_version": 1,
  "local": {
    "server_name": "ol_informix1210",
    "role_raw": "Not Initialized",
    "state_raw": "Off",
    "configured_peer_name_raw": ""
  },
  "hdr_peers": []
}
```

An empty peer list is a valid collection result only after the required source queries succeed. It is normal only under `IFX_HDR_REQUIRED=NO`. With `IFX_HDR_REQUIRED=YES`, the instance-level HDR-002 item must signal required HDR absent even when no peer item exists.

The future discovery key `{#IFX_HDR_PEER}` is based on a proven stable remote server name. Do not enable peer prototypes until real HDR establishes uniqueness and lifecycle behavior. Discovery alone must not own the disappearance alert.

## 6. Failure and compatibility contract

| Condition | Required behavior |
|---|---|
| SQL connection or statement failure | Non-zero collector result; no synthetic empty/healthy payload. |
| Required table or column absent | Clear unsupported/source error; no guessed fallback. |
| Valid standalone source observation | Empty remote HDR list; evaluate `IFX_HDR_REQUIRED`. |
| Remote candidate with missing/unknown identity or state | Unknown/error; never `CONNECTED`. |
| Expected partner absent or different | Instance-level High problem under `IFX_HDR_REQUIRED=YES`. |
| Source stops reporting after a previous good sample | Monitoring-integrity problem; stale data cannot prove recovery. |

## 7. Real-source validation gate

The development instance validates the existence/schema of both tables and the standalone row pattern only. Before remote discovery or connection normalization is implemented, capture read-only `sysdri` and `syscluster` output on both members of a real HDR pair in healthy, disrupted, and recovered states. Record exact version, names, types, values, query identity, and collection timestamps. No mock or fixture output substitutes for these observations.
