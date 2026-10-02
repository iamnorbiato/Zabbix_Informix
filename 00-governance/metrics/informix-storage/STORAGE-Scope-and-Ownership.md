# Storage and Capacity — Scope and Ownership

## Implemented in the Informix SQL monitoring package

The package implements the following metrics using Informix `sysmaster` sources:

- `STORAGE-001` — dbspace utilization;
- `STORAGE-002` — dbspace free space;
- `STORAGE-003` — dbspace growth and expansion parameters;
- `STORAGE-004` — chunk state;
- `STORAGE-005` — chunk utilization;
- `STORAGE-006` — chunk free space;
- `STORAGE-011` — temporary dbspace utilization and free pages.

These metrics are collected through the Informix SQL collector architecture and are exposed through Zabbix active-agent items and low-level discovery prototypes where applicable.

## Explicitly outside this package

The following metrics are not implemented by this repository:

- `STORAGE-007` — filesystem utilization;
- `STORAGE-008` — filesystem free space;
- `STORAGE-009` — filesystem inode utilization;
- `STORAGE-010` — chunk-to-filesystem mapping as an operational monitoring metric.

Filesystem capacity and inode monitoring belongs to the operating-system/AIX monitoring ownership. A collector running on a client must not execute local filesystem commands against Informix paths, because those paths belong to the Informix host and the result would describe the client filesystem.

`syschunks.fname` may remain useful as Informix metadata, but it is not a substitute for host filesystem telemetry. The operating-system monitoring team is responsible for collecting filesystem utilization, free space and inode usage on the host where the filesystem is mounted.

## Validation boundary

The implemented SQL metrics are validated in the Linux development topology. Filesystem metrics are intentionally excluded from the package acceptance criteria and must be validated by the operating-system monitoring implementation on the target host.
