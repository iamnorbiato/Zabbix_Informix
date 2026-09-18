# Deployment Topology Contract

## 1. Purpose

This document defines the portable deployment topology for Zabbix Informix monitoring artifacts.

The repository is the engineering source. Runtime installation, credentials, state, Zabbix configuration, and target-specific network values are external to Git.

## 2. Deployment Roles

The deployment model separates the following roles:

| Role | Responsibility |
|---|---|
| Informix Host | Runs the IBM Informix instance and exposes the authorized SQL interface. |
| Zabbix Server Host | Runs Zabbix Server and processes monitoring values, alerting, and history. |
| Zabbix Database Host | Runs the dedicated PostgreSQL database used by Zabbix Server. |
| Client SDK Host | Runs the Informix Client SDK and connects remotely to Informix through SQL. |
| Collection Agent Host | Runs the Zabbix Agent and executes the local Informix collectors. |

The Client SDK Host and Collection Agent Host MUST be the same host.

Other roles MAY be colocated or separated according to the target environment.

## 3. Supported Topologies

The architecture supports, among others:

```text
Informix AIX → Collector/Agent Linux → Zabbix Server Linux → PostgreSQL
Informix AIX → Collector/Agent AIX → Zabbix Server Linux → PostgreSQL
Informix AIX + Zabbix Server + PostgreSQL on one host
Zabbix Server + PostgreSQL on separate hosts
```

The Informix Host does not require a Zabbix Agent for remote SQL collection.

A Zabbix Agent on the Informix Host is optional and is intended for operating-system monitoring of that host.

## 4. Development Topology

The current development topology is:

```text
home
  ├─ Informix
  ├─ Zabbix Server
  └─ PostgreSQL for Zabbix

cluster-prime
  ├─ Informix Client SDK
  ├─ Informix collectors
  ├─ private collector state
  └─ Zabbix Agent
```

This topology validates remote SQL collection and Agent-to-Server delivery as separate network paths.

## 5. Parameterization Boundaries

Repository artifacts MUST NOT contain development hostnames, production hostnames, IP addresses, passwords, or target-specific TLS material.

### 5.1 Informix Client and Collector Parameters

The Client SDK and collector runtime use:

```text
IFX_CONFIG_DIR
IFX_CONNECT_FILE
IFX_STATE_DIR
IFX_INFORMIXDIR
IFX_INFORMIXSERVER
IFX_INFORMIXSQLHOSTS
```

The Informix network endpoint is configured through the target Client SDK `sqlhosts` file and private connection configuration. It MUST NOT be embedded in collector SQL statements.

### 5.2 Zabbix Agent Parameters

The Collection Agent Host requires target-specific Agent configuration for:

```text
Hostname
ServerActive
Server
TLSConnect
TLSAccept
```

The preferred default is an active Agent check, where the Collection Agent Host initiates the connection to Zabbix Server or Zabbix Proxy.

Passive Agent checks remain supported when Server or Proxy connectivity to the Collection Agent Host is intentionally available.

### 5.3 Zabbix Server Parameters

Zabbix Server deployment requires target-specific configuration for:

```text
Zabbix Server endpoint
PostgreSQL endpoint
dedicated Zabbix database
database credentials
TLS and certificate material
```

The PostgreSQL database used by Zabbix MUST be dedicated to Zabbix and MUST NOT be a shared application database.

## 6. Runtime Separation

The deployment package contains versioned repository artifacts such as:

```text
01-statements/
05-collectors/
02-zabbix/
```

The runtime environment contains private operational data outside Git:

```text
Informix connection credentials
Client SDK sqlhosts configuration
collector state files
Zabbix Agent configuration
TLS certificates and keys
```

State files from development MUST NOT be copied into another environment.

## 7. Deployment Flow

```text
Validate source artifacts
  ↓
Create approved release artifact
  ↓
Install collectors and statements on Client SDK / Collection Agent Host
  ↓
Create private runtime configuration and credentials
  ↓
Install or update Zabbix Agent configuration
  ↓
Import the version-compatible Zabbix template
  ↓
Execute controlled smoke tests
  ↓
Promote to runtime monitoring
```

## 8. Deployment Preconditions

Before deploying to a target environment, validate:

- supported Zabbix version;
- supported Agent version for the Collection Agent Host operating system;
- Informix Client SDK compatibility;
- SQL network connectivity from Client SDK Host to Informix Host;
- Agent-to-Server or Agent-to-Proxy connectivity;
- firewall rules;
- TLS configuration;
- private configuration permissions;
- collector execution identity;
- collection timeout and interval;
- Zabbix template compatibility.

## 9. Non-Negotiable Rules

- Informix monitoring collection remains remote SQL collection.
- Collectors MUST execute on the Client SDK / Collection Agent Host.
- Credentials, TLS material, and state MUST NOT be committed to Git.
- A deployment target MUST begin with its own baseline state.
- A topology change MUST be applied through target configuration, not by modifying SQL statements or collector source code.
