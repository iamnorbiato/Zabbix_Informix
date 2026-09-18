# Zabbix Informix Deployment

## Purpose

This directory contains the versioned deployment assets for the Zabbix Informix collectors.

The deployment separates source code, private configuration and Zabbix Agent integration. The Agent never executes a repository working tree directly.

## Components

| Artifact | Purpose |
|---|---|
| `install-zabbix-informix.ksh` | Installs or updates collector code, runtime configuration, launchers and the Agent include file. |
| `uninstall-zabbix-informix.ksh` | Removes Agent integration and launchers. It preserves code and private configuration unless `--purge` is supplied. |
| `runtime.env.example` | Credential-free example of the runtime configuration. |
| `zabbix-informix.conf.template` | Template for Zabbix Agent UserParameters. |
| `launchers/` | Runtime launchers for the implemented collectors. |

## Deployment Model

```text
Versioned release
    ↓ install script
Configured collector home
    ↓ launchers
Zabbix Agent active checks
    ↓
Zabbix Server
```

The source repository may exist anywhere. The runtime path is supplied through `IFX_COLLECTOR_HOME` in the generated runtime configuration.

## Required Parameters

The installer requires all of the following:

| Parameter | Meaning |
|---|---|
| `--install-home` | Product-owned directory where collector code is installed. |
| `--config-home` | Product-owned directory for runtime configuration, private connection file and state. |
| `--launcher-home` | Directory where Agent launchers are installed. |
| `--agent-include-dir` | Directory included by the local Zabbix Agent configuration. |
| `--informix-home` | Informix Client SDK directory on the collection host. |
| `--informix-server` | Informix server identifier used by the Client SDK. |
| `--informix-sqlhosts` | Client SDK `sqlhosts` file. |
| `--connection-file` | Existing private Informix connection file. |
| `--state-source` | Optional existing state directory to migrate during first installation. |

All deployment paths must be absolute paths.

## Private Configuration

Credentials are never stored in Git.

The connection file is installed as:

```text
<CONFIG_HOME>/informix-connect.sql
```

Expected permissions are:

```text
CONFIG_HOME                 root:zabbix 1730
informix-connect.sql        root:zabbix 0640
state/                      zabbix:zabbix 0700
state files                 zabbix:zabbix 0600
runtime.env                 root:zabbix 0640
```

`runtime.env` contains paths and Informix runtime identifiers only. It does not contain credentials.

## Linux Development Installation Example

The current development topology uses:

```text
INSTALL_HOME=/opt/zabbix-informix
CONFIG_HOME=/etc/zabbix-informix
LAUNCHER_HOME=/usr/local/lib/zabbix-informix
AGENT_INCLUDE_DIR=/etc/zabbix/zabbix_agentd.d
INFORMIX_HOME=/opt/informix
```

Initial migration from an existing configuration and state directory:

```bash
sudo ksh 03-deployment/install-zabbix-informix.ksh \
  --install-home /opt/zabbix-informix \
  --config-home /etc/zabbix-informix \
  --launcher-home /usr/local/lib/zabbix-informix \
  --agent-include-dir /etc/zabbix/zabbix_agentd.d \
  --informix-home /opt/informix \
  --informix-server ol_informix1210 \
  --informix-sqlhosts /opt/informix/etc/sqlhosts \
  --connection-file /path/to/existing/informix-connect.sql \
  --state-source /path/to/existing/state
```

Subsequent installation or update using the installed private configuration:

```bash
sudo ksh 03-deployment/install-zabbix-informix.ksh \
  --install-home /opt/zabbix-informix \
  --config-home /etc/zabbix-informix \
  --launcher-home /usr/local/lib/zabbix-informix \
  --agent-include-dir /etc/zabbix/zabbix_agentd.d \
  --informix-home /opt/informix \
  --informix-server ol_informix1210 \
  --informix-sqlhosts /opt/informix/etc/sqlhosts \
  --connection-file /etc/zabbix-informix/informix-connect.sql
```

Restart the Zabbix Agent with the service-management command appropriate to the host after installation. On the Linux development host:

```bash
sudo systemctl restart zabbix-agent
sudo systemctl is-active zabbix-agent
```

For AIX, provide the correct Agent service-management command for that environment. The installer intentionally does not assume `systemd`.

## Standard Uninstallation

The default uninstaller removes only the Agent integration:

- the product-specific Agent include file;
- the installed collector launchers.

It preserves:

- `INSTALL_HOME` collector code;
- `CONFIG_HOME`;
- the private connection file;
- the HEALTH-003 cursor and any future collector state.

Example:

```bash
sudo ksh 03-deployment/uninstall-zabbix-informix.ksh \
  --install-home /opt/zabbix-informix \
  --config-home /etc/zabbix-informix \
  --launcher-home /usr/local/lib/zabbix-informix \
  --agent-include-dir /etc/zabbix/zabbix_agentd.d
```

Restart the Agent after a standalone uninstallation.

## Full Removal with `--purge`

`--purge` additionally removes these exclusive product directories:

```text
INSTALL_HOME
CONFIG_HOME
```

This deletes the private connection file and all persistent collector state. It is irreversible unless those files were backed up separately.

Example:

```bash
sudo ksh 03-deployment/uninstall-zabbix-informix.ksh \
  --install-home /opt/zabbix-informix \
  --config-home /etc/zabbix-informix \
  --launcher-home /usr/local/lib/zabbix-informix \
  --agent-include-dir /etc/zabbix/zabbix_agentd.d \
  --purge
```

The uninstaller accepts only product paths ending in `/zabbix-informix` for `INSTALL_HOME`, `CONFIG_HOME` and `LAUNCHER_HOME`. This prevents a broad removal of unrelated directories.

Use `--purge` only with explicit authorization and after confirming that the connection file and state may be destroyed.

## Development Validation

The Linux development topology validated:

- installation of collector code, configuration, launchers and Agent include file;
- HEALTH-001 collection through the installed Agent launcher;
- HEALTH-003 collection through the installed Agent launcher;
- preservation of the HEALTH-003 cursor across standard uninstallation;
- standard uninstallation of Agent integration;
- successful reinstallation and Agent recovery.

The `--purge` path has not been executed in development because it intentionally destroys the private connection file and state. It remains pending explicit authorization.

## Post-Installation Verification

Verify installed collector keys through the Agent:

```bash
sudo zabbix_agentd -t ifx.health.instance_state
sudo zabbix_agentd -t ifx.health.assert_failures.raw
```

Expected development values are:

```text
ifx.health.instance_state                  [t|5]
ifx.health.assert_failures.raw             [t|COUNT|0]
```
