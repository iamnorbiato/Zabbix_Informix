# IFX-HDR-003 — Parser Specification

## Current Operational Status

`DEFINED`

No HDR low-level discovery rule or parser exists yet.

## 1. Purpose

Define the future discovery-output contract for `IFX-HDR-003 — HDR Peer Discovery`.

## 2. Input Contract

The master payload contains `hdr_peers`, an array of normalized peer objects. Every candidate record must include `peer_name` and `peer_node_type`.

## 3. Filtering Contract

Only records with:

```text
peer_node_type = HDR
```

are emitted by this discovery parser. RSS and SDS records are excluded without treating them as errors.

## 4. Output Contract

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

An empty valid `hdr_peers` array produces `{ "data": [] }`.

## 5. Invalid Input

Malformed JSON, missing peer name, empty peer name, unsupported schema version, duplicate discovery identity, or an unknown required node type must fail clearly. They must not create anonymous or unstable Zabbix resources.

## 6. Mock Validation

Validate `standalone` => empty discovery; connected primary/secondary => one HDR peer; `primary-hdr-and-rss` => only HDR peer.

## 7. Acceptance Criteria

- Stable peer identity is proven on target HDR.
- Empty discovery is distinct from collection failure.
- Non-HDR technologies are not emitted as HDR peers.

