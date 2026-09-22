# IFX-HDR-001 — Local Role and State

**Status:** `DEFINED`  
**Implementation status:** Not implemented.  
**Collection database:** `sysmaster`  
**Runtime method:** SQL only; no `onstat` execution.

## 1. Objective

Expose the local Informix instance role and its Data Replication Interface state so operators can distinguish a standalone instance, an HDR primary, an HDR secondary, a role transition, and an engine-reported replication failure.

## 2. Business Value

Role and state are the foundation for all HDR interpretation. A peer connectivity value is not meaningful unless the monitored instance's own HDR role and state are known.

## 3. Source Contract

Initial source: `sysmaster:sysdri`.

Expected logical source fields:

| Source field | Normalized output | Purpose |
|---|---|---|
| `type` | `local_role` | Local DRI role. |
| `state` | `local_state` | Local DRI operational state. |
| `name` | `configured_peer_name` | Configured peer name when available. |

The exact target schema and values must be verified on a real HDR environment before implementation.

## 4. Candidate SQL

**Database: `sysmaster`**

```sql
SELECT
    type,
    state,
    name
FROM sysdri;
```

This query is a design candidate only. The production statement must use the established Informix SQL execution framework and its existing isolation handling.

## 5. Normalized Data Contract

Future master output must retain a raw representation and provide normalized fields:

```json
{
  "schema_version": 1,
  "local_role": "PRIMARY",
  "local_state": "ON",
  "configured_peer_name": "ifx_hdr_secondary"
}
```

### 5.1 `local_role`

Expected normalized values:

| Value | Meaning |
|---|---|
| `PRIMARY` | Local instance is the HDR primary. |
| `SECONDARY` | Local instance is the HDR secondary. |
| `STANDARD` | Local instance has no active HDR role. |
| `NOT_INITIALIZED` | HDR/DRI state is not initialized. |
| `UNKNOWN` | Source value is unavailable or unrecognized. |

### 5.2 `local_state`

Expected normalized values:

| Value | Meaning |
|---|---|
| `ON` | Local DRI/HDR state is operational according to engine source. |
| `OFF` | Local DRI/HDR state is disabled or absent. |
| `CONNECTING` | Local relationship is being established. |
| `FAILURE` | Engine source reports a failure state. |
| `READ_ONLY` | Engine source reports a read-only state. |
| `UNKNOWN` | Source value is unavailable or unrecognized. |

No unrecognized source string may be silently treated as `ON` or `OFF`.

## 6. Zabbix Design

| Element | Proposed value |
|---|---|
| Master item key | `ifx.hdr.local.raw` |
| Master item type | Zabbix agent active |
| Master item value type | Text |
| Dependent role key | `ifx.hdr.local.role` |
| Dependent state key | `ifx.hdr.local.state` |
| Dependent peer-name key | `ifx.hdr.local.configured_peer` |
| Update interval | To be finalized with collector grouping; initial target: 60 seconds. |

`IFX-HDR-001` may share a master collector with peer discovery only if the final JSON contract keeps local and peer fields independently extractable. It must not duplicate SQL polling unnecessarily.

## 7. Alert Policy

This metric alone does not determine whether HDR is required. That decision belongs to `IFX-HDR-002` and `IFX_HDR_REQUIRED`.

Future visibility triggers may report a sustained local `FAILURE` state, but the exact trigger expression and severity require target HDR evidence.

## 8. Expected Results

| Environment | Expected role | Expected state |
|---|---|---|
| Standalone instance | `STANDARD` | `OFF` or source-equivalent normalized value |
| Healthy HDR primary | `PRIMARY` | `ON` |
| Healthy HDR secondary | `SECONDARY` | `ON` |
| Role transition | source-dependent | `CONNECTING` or another documented transitional value |
| Engine-reported DRI failure | source-dependent | `FAILURE` |

## 9. Failure Behavior

| Condition | Expected behavior |
|---|---|
| `sysdri` unavailable | Collector fails clearly; no invented standalone value. |
| Source query returns unexpected cardinality | Collector fails clearly until target behavior is documented. |
| Source value unknown | Collector succeeds only if query succeeds; output is `UNKNOWN` and retains raw evidence. |
| Connection failure | Existing Informix execution framework returns non-zero. |

## 10. Validation Plan

1. Validate the candidate source in **Database: `sysmaster`** on a real target HDR primary and secondary.
2. Capture source values for healthy, connecting, disconnected, and failure situations where safely possible.
3. Verify all normalization mappings.
4. Validate the payload with `primary-hdr-connected`, `secondary-hdr-connected`, `standalone`, and `primary-hdr-failed` fixtures.
5. Validate Zabbix dependent-item extraction and history.

## 11. Acceptance Criteria

- `sysdri` source fields are evidenced on the target Informix version.
- Local role and state have documented normalization mappings.
- Standalone is distinguishable from an unavailable source.
- The metric can be collected without `onstat`.
- The Zabbix item design and any shared-master relationship are approved before coding.

