# IFX-HDR — Discovery and Data Contract

**Status:** `DEFINED`  
**Implementation status:** Documentation only. No SQL statement, collector, Zabbix low-level discovery rule, item prototype, or trigger prototype is implemented by this document.

## 1. Purpose

Define the SQL sources, normalized HDR peer record, discovery behavior, and compatibility boundary for future HDR monitoring.

The design is SQL-only at runtime. It does not execute `onstat` or parse `onstat` output.

## 2. Authoritative Runtime Sources

The initial source design uses the following documented System Monitoring Interface tables in `sysmaster`:

| Source | Intended use |
|---|---|
| `sysmaster:sysdri` | Local Data Replication Interface role, state, peer name, interval, and timeout. |
| `sysmaster:syscluster` | Per-peer high-availability topology, role, node type, synchronization mode, connection status, and where available log-progress and acknowledgement fields. |

The future SQL statements must execute with the existing collector isolation policy and explicitly select only required fields.

The design must not depend on unverified objects such as `sysha_hdr`, `sysrephdr`, `sysha_node`, or `sysha_rss`. Their availability and field definitions were not confirmed as supported runtime sources for the target Informix versions.

`syscdr*` tables are not an HDR source. They describe Enterprise Replication and must not be interpreted as HDR health.

## 3. Local Instance Record

The collector must obtain one normalized local record before attempting peer discovery.

| Normalized field | Initial source | Meaning |
|---|---|---|
| `local_role` | `sysdri.type` | Local role such as primary, secondary, standard, or not initialized. |
| `local_state` | `sysdri.state` | Local DRI/HDR state such as on, off, connecting, failure, or read-only. |
| `configured_peer_name` | `sysdri.name` | Engine-reported configured peer DB server name, if present. |
| `dr_interval` | `sysdri.intvl` | Replication interval, if exposed and meaningful for the target configuration. |
| `dr_timeout` | `sysdri.timeout` | Replication timeout, if exposed and meaningful for the target configuration. |

The future parser must retain the source value and a normalized value when their spelling or case differs.

## 4. HDR Peer Discovery Scope

`syscluster` can expose several high-availability technologies. The discovery process must retain only rows whose node type is HDR.

RSS and SDS rows must not be reported as HDR peers. They may become separate monitoring scope in the future.

The discovery key must be stable and safe for Zabbix use. The initial proposed identity is:

```text
{#IFX_HDR_PEER}
```

Its value is the peer server name exactly as normalized by the collector. If the target version permits duplicate names, the implementation must extend the identity using a documented stable peer identifier before Zabbix discovery is introduced.

## 5. Normalized HDR Peer Record

For every discovered HDR peer, the collector must produce the following logical record:

| Field | Required before implementation | Initial source candidate | Notes |
|---|---:|---|---|
| `peer_name` | Yes | `syscluster.name` | Unique discovery identity after normalization. |
| `peer_node_type` | Yes | `syscluster.nodetype` | Must normalize to `HDR` for this metric family. |
| `peer_role` | Yes | `syscluster.role` | Remote role as exposed by engine. |
| `peer_connection_status` | Yes | `syscluster.connection_status` | Normalized connectivity state. |
| `peer_server_status` | Yes | `syscluster.server_status` | Remote operational state where exposed. |
| `sync_mode` | Yes | `syscluster.syncmode` | Synchronization policy/mode. |
| `delayed_apply` | No | `syscluster.delayed_apply` | Future visibility field; validation required. |
| `stop_apply` | No | `syscluster.stop_apply` | Future visibility field; validation required. |
| `logid_sent` | No | `syscluster.logid_sent` | Candidate log-progress component; validation required. |
| `logpage_sent` | No | `syscluster.logpage_sent` | Candidate log-progress component; validation required. |
| `logid_acked` | No | `syscluster.logid_acked` | Candidate acknowledgement component; validation required. |
| `logpage_acked` | No | `syscluster.logpage_acked` | Candidate acknowledgement component; validation required. |
| `ack_time` | No | `syscluster.ack_time` | Candidate acknowledgement timestamp; unit/semantics require validation. |

The implementation must not assume that optional fields exist, have the same type, or retain the same semantics in every supported Informix release.

## 6. Connectivity Normalization

Source values vary by engine version and operating state. The parser must normalize known values to these logical states:

| Normalized state | Meaning |
|---|---|
| `CONNECTED` | The HDR peer relationship is operationally connected. |
| `CONNECTING` | A peer relationship exists but is being established. |
| `DISCONNECTED` | A peer relationship exists but is not connected. |
| `FAILED` | The engine reports failure for the relationship. |
| `UNKNOWN` | The source value is absent, unsupported, or not recognized by the parser. |

Unknown source values must be preserved in the raw data and reported as `UNKNOWN`; they must not be coerced to `CONNECTED` or `DISCONNECTED`.

## 7. Proposed Discovery Payload

The future master discovery collector will emit one compact JSON document to standard output. The final schema may evolve only with a documented compatibility update.

Illustrative connected-peer payload:

```json
{
  "schema_version": 1,
  "local": {
    "role": "PRIMARY",
    "state": "ON",
    "configured_peer_name": "ifx_hdr_secondary"
  },
  "hdr_peers": [
    {
      "peer_name": "ifx_hdr_secondary",
      "peer_node_type": "HDR",
      "peer_role": "SECONDARY",
      "peer_connection_status": "CONNECTED",
      "peer_server_status": "ACTIVE",
      "sync_mode": "SYNC"
    }
  ]
}
```

Illustrative standalone payload:

```json
{
  "schema_version": 1,
  "local": {
    "role": "STANDARD",
    "state": "OFF",
    "configured_peer_name": ""
  },
  "hdr_peers": []
}
```

The payload is a collection contract, not a Zabbix alert decision. Alert decisions remain governed by `IFX-HDR-Configuration-and-Alerting.md`.

## 8. No-Peer Behavior

An empty `hdr_peers` array is a valid SQL collection result. It means no HDR peer was discovered, not that the collector failed.

The expected-HDR metric evaluates whether the empty discovery result is acceptable according to `IFX_HDR_REQUIRED`.

## 9. Version Compatibility Gate

Before coding against a target Informix environment, perform the following read-only validation in **Database: `sysmaster`**:

```sql
SELECT
    tabname
FROM systables
WHERE tabname IN ('sysdri', 'syscluster')
ORDER BY tabname;
```

Then inspect the available columns:

```sql
SELECT
    t.tabname,
    c.colname,
    c.coltype,
    c.collength
FROM systables AS t
JOIN syscolumns AS c
    ON c.tabid = t.tabid
WHERE t.tabname IN ('sysdri', 'syscluster')
ORDER BY
    t.tabname,
    c.colno;
```

The target validation record must capture the Informix version, the returned schemas, representative safe output, and any field-name or semantic differences.

## 10. Failure Contract

| Condition | Collector result |
|---|---|
| SQL connection or statement execution fails | Non-zero exit; precise standard-error message; no synthetic healthy payload. |
| Required table or column is absent | Non-zero exit; identify the unavailable source; no fallback to unverified SQL. |
| SQL returns no `sysdri` local row where one is expected | Non-zero exit or explicit `UNKNOWN`, finalized after real HDR validation. |
| SQL succeeds and no HDR peer exists | Zero exit with `hdr_peers: []`. |
| Source status is unrecognized | Zero exit only if record collection succeeds; normalize status to `UNKNOWN`. |

## 11. Acceptance Criteria

This data contract is ready for implementation only after:

- `sysdri` and `syscluster` structures are captured from a real target HDR environment;
- the mapping of source connectivity values to normalized states is evidenced;
- unique peer identity is confirmed;
- optional lag fields are either validated with their units or deferred;
- mock fixtures conform exactly to the approved JSON schema.

