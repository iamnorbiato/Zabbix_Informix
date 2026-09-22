# IFX-HDR — Mock Validation Plan

**Status:** `DEFINED`  
**Implementation status:** Documentation only. No mock facility is implemented by this document.

## 1. Purpose

Define how the future HDR collectors, parsers, Zabbix preprocessing, discovery, and triggers can be validated before access to a real HDR environment exists.

Mocks validate deterministic handling of known payloads. They do not validate Informix engine semantics, production networking, replication throughput, or the schema exposed by a target Informix release.

## 2. Non-Production Boundary

Mock input is permitted only in explicit development or test execution.

The future production installation must not enable mock input, install mock fixtures into the private runtime configuration area, or accept mock data through a Zabbix item key.

The intended test-only control is:

```ksh
IFX_HDR_MOCK_FILE=/absolute/path/to/fixture.json
```

When this variable is empty or unset, the collector must use SQL against Informix. When it is set, the collector may use the named fixture only after validating that the file is a regular readable file and conforms to the approved payload schema.

## 3. Fixture Format

Fixtures must use the JSON contract defined in `IFX-HDR-Discovery-and-Data-Contract.md`.

Each fixture must have:

- `schema_version` set to the supported schema version;
- one `local` object;
- one `hdr_peers` array, including an empty array for no HDR peers;
- normalized values where the fixture is intended to test parser-independent downstream behavior.

Fixtures must not include Informix connection credentials, production hostnames, IP addresses, customer data, or copied production raw output.

## 4. Required Fixture Set

| Fixture identifier | Local role/state | HDR peers | Primary validation purpose |
|---|---|---|---|
| `standalone` | `STANDARD` / `OFF` | none | Optional HDR absence is healthy. |
| `hdr-required-but-absent` | `STANDARD` / `OFF` | none | Required HDR absence creates a problem. |
| `primary-hdr-connected` | `PRIMARY` / `ON` | one connected HDR secondary | Normal healthy primary behavior. |
| `secondary-hdr-connected` | `SECONDARY` / `ON` | one connected HDR primary | Normal healthy secondary behavior. |
| `primary-hdr-connecting` | `PRIMARY` / `CONNECTING` | one connecting HDR secondary | Grace-period and policy behavior. |
| `primary-hdr-disconnected` | `PRIMARY` / `ON` | one disconnected HDR secondary | Disconnect alert behavior. |
| `primary-hdr-failed` | `PRIMARY` / `FAILURE` | one failed HDR secondary | Failure-state handling. |
| `primary-hdr-and-rss` | `PRIMARY` / `ON` | one HDR peer and one RSS peer | HDR-only discovery filtering. |
| `unknown-peer-status` | `PRIMARY` / `ON` | one HDR peer with unknown state | Unknown-state preservation. |
| `ack-age-thresholds` | `PRIMARY` / `ON` | one connected HDR peer with tested acknowledgement age | Warning/high threshold behavior after source semantics are validated. |
| `backlog-thresholds` | `PRIMARY` / `ON` | one connected HDR peer with tested progress values | Warning/high backlog behavior after source semantics are validated. |

## 5. Minimum Fixture Examples

### 5.1 `standalone.json`

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

### 5.2 `primary-hdr-connected.json`

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

### 5.3 `primary-hdr-disconnected.json`

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
      "peer_connection_status": "DISCONNECTED",
      "peer_server_status": "UNKNOWN",
      "sync_mode": "ASYNC"
    }
  ]
}
```

## 6. Validation Matrix

| Test case | Fixture | Configuration | Expected result |
|---|---|---|---|
| Standalone permitted | `standalone` | `IFX_HDR_REQUIRED=NO` | Normal result; no HDR problem. |
| Standalone prohibited | `hdr-required-but-absent` | `IFX_HDR_REQUIRED=YES` | Required-HDR problem. |
| Connected primary | `primary-hdr-connected` | required/disconnect alert enabled | One HDR peer discovered; no connectivity problem. |
| Connected secondary | `secondary-hdr-connected` | required/disconnect alert enabled | One HDR peer discovered; no connectivity problem. |
| Connecting peer, alerts disabled | `primary-hdr-connecting` | `IFX_HDR_ALERT_ON_DISCONNECT=NO` | State visible; no connectivity problem. |
| Connecting peer, alerts enabled | `primary-hdr-connecting` | `IFX_HDR_ALERT_ON_DISCONNECT=YES` | Connectivity problem after approved grace behavior. |
| Disconnected peer, alerts disabled | `primary-hdr-disconnected` | `IFX_HDR_ALERT_ON_DISCONNECT=NO` | State visible; no connectivity problem. |
| Disconnected peer, alerts enabled | `primary-hdr-disconnected` | `IFX_HDR_ALERT_ON_DISCONNECT=YES` | High connectivity problem. |
| Failed peer | `primary-hdr-failed` | `IFX_HDR_ALERT_ON_DISCONNECT=YES` | High connectivity problem; failure state visible. |
| RSS filtering | `primary-hdr-and-rss` | any | Only HDR peer appears in HDR discovery. |
| Unknown status | `unknown-peer-status` | any | Peer remains visible as `UNKNOWN`; no false connected value. |
| Acknowledgement threshold crossing | `ack-age-thresholds` | thresholds configured | Correct warning/high trigger evaluation. |
| Backlog threshold crossing | `backlog-thresholds` | thresholds configured | Correct warning/high trigger evaluation. |

## 7. Required Validation Layers

### 7.1 Collector contract validation

Confirm that the test-only collector reads a fixture only when `IFX_HDR_MOCK_FILE` is explicitly set and emits the expected normalized payload.

### 7.2 Parser validation

Confirm malformed JSON, missing required properties, unsupported schema versions, and invalid normalized states fail clearly rather than producing partial healthy output.

### 7.3 Zabbix preprocessing validation

Confirm master item, dependent items, and low-level discovery extraction produce the expected values from every fixture.

### 7.4 Trigger validation

Confirm each alert matrix row creates, remains, and resolves the correct problem state when the fixture changes.

### 7.5 Production-boundary validation

Confirm a normal installed collector ignores mock behavior unless an operator deliberately supplies the test-only environment variable in a controlled execution.

## 8. What Requires a Real HDR Environment

The following cannot be accepted from fixtures alone:

- the actual schemas and values returned by `sysdri` and `syscluster` on the target Informix release;
- the meaning and timing of `connection_status`, `server_status`, and `syncmode` during real role transitions;
- the existence, data type, unit, and operational meaning of acknowledgement and log-progress fields;
- primary/secondary behavior during network interruption, reconnect, failover, and recovery;
- the production Zabbix polling load and alert timing.

## 9. Acceptance Criteria

The mock plan is ready when:

- all required fixtures are versioned as non-secret test assets;
- fixture payloads satisfy the data contract;
- the validation matrix is automated or reproducible through documented steps;
- the production installation explicitly excludes fixtures and mock enablement;
- real-HDR validation remains a recorded release gate.

