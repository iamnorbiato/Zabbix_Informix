*1. definir arquitetura da coleta (DONE)*

*2. montar catálogo/matriz das métricas (DONE)*

**3. validar cada métrica manualmente em um Informix/AIX real (CURRENT — IN PROGRESS)**

Informix Health status:

- IFX-HEALTH-001 — Instance State — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-002 — Instance Uptime — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-003 — Assert Failures — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-004 — Checkpoint Count — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-005 — Checkpoint Duration — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-006 — Checkpoint Waits — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-007 — LRU Writes — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-008 — Foreground Writes — DEVELOPMENT_RUNTIME_VALIDATED

`DEVELOPMENT_RUNTIME_VALIDATED` for IFX-HEALTH-001, IFX-HEALTH-002, IFX-HEALTH-003, IFX-HEALTH-004, IFX-HEALTH-005, IFX-HEALTH-006, IFX-HEALTH-007 and IFX-HEALTH-008 means that their remote SQL collectors, Informix Client SDK, Zabbix Agent active checks, Zabbix items and applicable trigger configurations were validated in the Linux development topology. Target Informix/AIX validation remains pending.

`DEVELOPMENT_RUNTIME_VALIDATED` for IFX-SESSION-001 means that its `sysmaster:syssessions` SQL source, explicit collector-infrastructure exclusions, strict scalar collector normalization, parameterized deployment launcher, Zabbix Agent active check and Zabbix template item were validated in the Linux development topology. The same value was confirmed through collector, installed launcher and Zabbix Agent execution. Target Informix/AIX validation remains pending.

`DEVELOPMENT_RUNTIME_VALIDATED` for IFX-SESSION-002 means that its `sysmaster:syssessions` SQL source, documented `state` bit `32` (`In a read call`), strict scalar collector normalization, parameterized deployment launcher, Zabbix Agent active key, template item, exported template definition, and uninstall/reinstall lifecycle were validated in the Linux development topology. The same valid value, `0`, was confirmed through DBeaver SQL, the versioned statement, repository collector, installed launcher, and Zabbix Agent. Target Informix/AIX validation remains pending.

`DEVELOPMENT_RUNTIME_VALIDATED` for IFX-SESSION-003 means that its `sysmaster:sysfeatures.max_conns` weekly physical-connection high-water source, strict scalar collector normalization, parameterized deployment launcher, Zabbix Agent active key, template item, exported template definition, and uninstall/reinstall lifecycle were validated in the Linux development topology. The same valid value, `6`, was confirmed through DBeaver SQL, the versioned statement, repository collector, installed launcher, and Zabbix Agent. Target Informix/AIX validation remains pending.

`DEVELOPMENT_RUNTIME_VALIDATED` for IFX-SESSION-004 means that its `sysmaster:syssessions` SQL source, strict scalar collector normalization, parameterized deployment launcher, Zabbix Agent active check, Zabbix template item, exported template definition and uninstall/reinstall lifecycle were validated in the Linux development topology. The same valid value, `0`, was confirmed through the SQL statement, repository collector, installed launcher and Zabbix Agent execution. Target Informix/AIX validation and controlled exercises for individual non-lock waiting flags remain pending.

`DEVELOPMENT_RUNTIME_VALIDATED` for IFX-SESSION-005 means that its `sysmaster:syssessions` SQL dataset, fixed six-dimension contract (`LATCH`, `LOCK`, `BUFFER`, `CHECKPOINT`, `LOG_BUFFER` and `TRANSACTION`), strict collector validation, parameterized deployment launcher, Zabbix Agent active check, raw master item and six numeric dependent items were validated in the Linux development topology. The six dependent items were validated with value `0` and without preprocessing errors. Target Informix/AIX validation and controlled exercises for individual non-lock waiting flags remain pending.

Target-environment validation remains pending. The production topology may use Informix on AIX and a separate Zabbix Server, Agent and Client SDK host.

Informix Sessions and Concurrency status:

- IFX-SESSION-001 — Total Connected Client Sessions — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-SESSION-002 — Sessions in Read Call — DEVELOPMENT_RUNTIME_VALIDATED — SQL statement, collector, launcher, active Agent item, exported template and uninstall/reinstall lifecycle validated
- IFX-SESSION-003 — Weekly Peak Concurrent Physical Connections — DEVELOPMENT_RUNTIME_VALIDATED — SQL statement, collector, launcher, active Agent item, exported template and uninstall/reinstall lifecycle validated
- IFX-SESSION-004 — Waiting Client Sessions Total — DEVELOPMENT_RUNTIME_VALIDATED — controlled `is_wlock` client-session validation completed; individual non-lock flag exercises remain pending
- IFX-SESSION-005 — Waiting Client Sessions by Reason — **DEVELOPMENT_RUNTIME_VALIDATED** — SQL dataset, strict six-dimension collector contract, installed launcher, active Agent item, raw master item and six dependent numeric items validated; controlled exercises for individual non-lock waiting flags remain pending

Informix Locks and Contention status:

- IFX-LOCK-001 — Sessions Waiting for Locks — DEVELOPMENT_RUNTIME_VALIDATED — controlled lock detection, 90-second `HIGH` trigger, recovery to `RESOLVED`, exported template and uninstall/reinstall lifecycle validated
- IFX-LOCK-002 — Lock Waits — DEVELOPMENT_RUNTIME_VALIDATED — controlled counter increment from `2` to `3`, active item, exported template and uninstall/reinstall lifecycle validated
- IFX-LOCK-003 — Lock Timeouts — DEVELOPMENT_RUNTIME_VALIDATED — source and full runtime chain validated with baseline `0`; safely controlled positive timeout exercise pending
- IFX-LOCK-004 — Deadlocks — DEVELOPMENT_RUNTIME_VALIDATED — source and full runtime chain validated with baseline `0`; `HIGH` increment trigger exported
- IFX-LOCK-005 — Lock Table Exhaustion Attempts — DEVELOPMENT_RUNTIME_VALIDATED — `ovlock` source and full runtime chain validated with baseline `0`; `HIGH` increment trigger exported
- IFX-LOCK-006 — Maximum Lock Wait Duration — SOURCE_REJECTED — `sysrstcb.lkwaittime` did not provide proven current elapsed-wait semantics
- IFX-LOCK-007 — Lock Escalation — SOURCE_REJECTED — no SQL-visible escalation source in the current SMI catalog or `sysprofile`

Informix HDR status:

- IFX-HDR-003 — HDR Peer Discovery — SOURCE_VALIDATED — syscluster real validado no standalone e no primary HDR de produção; linha local excluída e peer psk_wms_hdr identificado
- IFX-HDR-004 — HDR Peer Connectivity — SOURCE_VALIDATED — connection_status=Connected validado no primary HDR de produção; Agent local ainda não aponta para produção
- IFX-HDR-005 — HDR Peer State and Sync Mode — SOURCE_VALIDATED — server_status=on, role=S e syncmode=SYNC validados no primary HDR de produção; Agent local ainda não aponta para produção
- IFX-HDR-006 — HDR Last Acknowledgement Age — DEFINED — SOURCE SEMANTICS REQUIRE VALIDATION
- IFX-HDR-007 — HDR Log Progress and Backlog — DEFINED — SOURCE SEMANTICS REQUIRE VALIDATION

The HDR design is SQL-only at runtime and does not execute `onstat`. IFX-HDR-001 and IFX-HDR-002 have been implemented and validated in the standalone Linux development topology using real sysmaster data. IFX-HDR-003 has real standalone source validation for the local syscluster row. A real HDR primary/secondary pair is still required to validate remote peer identity, connectivity, operational state, synchronization mode, acknowledgement age, and log-progress semantics. No mock HDR data is an acceptance substitute.

**4. construir collector mínimo**

**5. Template Informix Health**

**6. Template Sessions/Locks**

**7. Storage discovery**

**8. Logs/Backup**

**9. AIX**

**10. HA**

**11. SQL Performance**

**12. Grafana**

**13. tuning de triggers/baselines**

Informix Storage status:

- IFX-STORAGE-001 — Dbspace Utilization — DEVELOPMENT_RUNTIME_VALIDATED — SQL source, collector, launcher, active Agent item, dbspace discovery prototype and Warning/High utilization triggers validated in the Linux development topology
- IFX-STORAGE-002 — Dbspace Free Space — DEVELOPMENT_RUNTIME_VALIDATED — SQL source, collector, launcher, active Agent item and dbspace discovery prototype validated in the Linux development topology
- IFX-STORAGE-003 — Dbspace Growth and Expansion — DEVELOPMENT_RUNTIME_VALIDATED — SQL source, collector, launcher, active Agent item and dbspace discovery prototype validated in the Linux development topology
- IFX-STORAGE-004 — Chunk State — DEVELOPMENT_RUNTIME_VALIDATED — SQL source, collector, launcher, active Agent item, chunk discovery prototypes and offline/recovering/inconsistent triggers validated in the Linux development topology
- IFX-STORAGE-005 — Chunk Utilization — DEVELOPMENT_RUNTIME_VALIDATED — SQL source, collector, launcher, active Agent item and chunk discovery prototype validated; class-specific utilization triggers remain intentionally deferred
- IFX-STORAGE-006 — Chunk Free Space — DEVELOPMENT_RUNTIME_VALIDATED — SQL source, collector, launcher, active Agent item and chunk discovery prototype validated in the Linux development topology
- IFX-STORAGE-011 — Temporary Dbspace Utilization — DEVELOPMENT_RUNTIME_VALIDATED — SQL source, collector, launcher, temporary-dbspace discovery, utilization/free-pages prototypes and sustained Warning/High triggers validated in the Linux development topology

IFX-STORAGE-007, IFX-STORAGE-008, IFX-STORAGE-009 and IFX-STORAGE-010 are outside the Informix SQL package scope. Filesystem utilization, filesystem free space, inode utilization and operational chunk-to-filesystem correlation belong to the operating-system/AIX monitoring implementation because the Informix collector may execute on a client host different from the Informix server. These metrics are not accepted as implemented by this repository.
