# IFX-HDR-003 — HDR Peer Discovery

**Status:** `DEFINED`  
**Implementation status:** Not implemented.  
**Collection database:** `sysmaster`  
**Runtime method:** SQL only; no `onstat` execution.

## 1. Objective

Discover every HDR peer associated with the monitored Informix instance and expose each peer as an independently addressable Zabbix discovery entity.

This metric is topology discovery. It does not, by itself, decide whether a discovered peer is connected or healthy.

## 2. Scope

Included:

- peers whose normalized `node_type` is `HDR`;
- peer identity, remote role, and basic topology attributes;
- zero peers as a valid result.

Excluded from this metric:

- RSS peers;
- SDS peers;
- Enterprise Replication participants;
- automatic discovery of remote hosts in Zabbix;
- remote SQL execution against the peer.

## 3. Source Contract

Initial source: `sysmaster:syscluster`.

Candidate fields:

| Source field | Normalized field | Required |
|---|---|---:|
| `name` | `peer_name` | Yes |
| `nodetype` | `peer_node_type` | Yes |
| `role` | `peer_role` | Yes |
| `syncmode` | `sync_mode` | Yes where exposed |

The target environment must validate exact field names, data types, null behavior, and identity uniqueness before SQL is implemented.

## 4. Candidate SQL

**Database: `sysmaster`**

```sql
SELECT
    name,
    nodetype,
    role,
    syncmode
FROM syscluster;
```

The production statement must apply the HDR-only filter using the actual target value semantics. It must not assume a case-sensitive literal until target validation confirms it.

Conceptual target filtering is:

```text
normalized(nodetype) == HDR
```

## 5. Discovery Identity

The initial Zabbix low-level discovery macro is:

```text
{#IFX_HDR_PEER}
```

It holds normalized `peer_name`.

Before implementation, target validation must prove that peer name is unique and stable for the monitored instance. If it is not, the discovery key must be extended with another documented stable source field; no generated sequence number may be used.

## 6. Discovery Payload

Proposed Zabbix low-level discovery output:

```json
{
  "data": [
    {
      "{#IFX_HDR_PEER}": "ifx_hdr_secondary",
      "{#IFX_HDR_NODE_TYPE}": "HDR",
      "{#IFX_HDR_ROLE}": "SECONDARY",
      "{#IFX_HDR_SYNC_MODE}": "SYNC"
    }
  ]
}
```

No-HDR result:

```json
{
  "data": []
}
```

An empty discovery array is successful collection. HDR requirement is evaluated separately by `IFX-HDR-002`.

## 7. Proposed Zabbix Design

| Element | Proposed value |
|---|---|
| Discovery rule key | `ifx.hdr.peer.discovery` |
| Discovery type | Dependent discovery rule |
| Master item | Approved common HDR raw/master item |
| Discovery interval | Inherited from master item; initial target: 60 seconds. |
| Lost-resource lifetime | To be finalized with operations policy; no automatic removal without explicit retention decision. |
| Primary macro | `{#IFX_HDR_PEER}` |

Future item prototypes for connectivity, server state, synchronization mode, acknowledgement age, and backlog must use this discovery identity.

## 8. Normalization Rules

| Raw condition | Normalized behavior |
|---|---|
| Node type represents HDR | Include one discovery record. |
| Node type represents RSS or SDS | Exclude from HDR discovery. |
| Node type absent or unknown | Do not classify as HDR; retain raw evidence in master payload. |
| Peer name empty | Treat as data-contract failure; do not create an anonymous discovery entity. |
| Duplicate peer identity | Treat as data-contract failure until an approved stable composite identity exists. |

## 9. Failure Behavior

| Condition | Expected behavior |
|---|---|
| `syscluster` unavailable | Master collector fails; discovery is not updated with an empty result. |
| No qualifying HDR row | Successful `data: []` payload. |
| Source row has missing name | Collector fails or suppresses the malformed row with explicit error policy to be finalized before coding. |
| Unsupported schema | Collector fails clearly; no guessed-column fallback. |

## 10. Mock Validation

| Fixture | Expected discovery result |
|---|---|
| `standalone` | Empty `data` array. |
| `primary-hdr-connected` | One HDR peer. |
| `secondary-hdr-connected` | One HDR peer. |
| `primary-hdr-and-rss` | Only the HDR peer appears. |
| malformed duplicate-peer fixture | Clear failure; no unstable duplicate discovery. |

## 11. Acceptance Criteria

- Target `syscluster` schema is recorded from a real HDR environment.
- HDR rows are distinguishable from RSS and SDS rows.
- Peer identity is unique and stable.
- No-peer discovery is represented as a successful empty result.
- Discovery output is compatible with Zabbix 7.0 dependent low-level discovery.

