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

- IFX-LOCK-001 — Sessions Waiting for Locks — DEVELOPMENT_RUNTIME_VALIDATED — controlled lock detection, active Agent item, red `HIGH` trigger, recovery to `RESOLVED`, exported template, and uninstall/reinstall lifecycle validated
- IFX-LOCK-002 — Maximum Lock Wait Time — DEFINED

Informix HDR status:

- IFX-HDR-001 — Local Role and State — DEFINED
- IFX-HDR-002 — Expected HDR Configuration — DEFINED
- IFX-HDR-003 — HDR Peer Discovery — DEFINED
- IFX-HDR-004 — HDR Peer Connectivity — DEFINED
- IFX-HDR-005 — HDR Peer State and Sync Mode — DEFINED
- IFX-HDR-006 — HDR Last Acknowledgement Age — DEFINED — SOURCE SEMANTICS REQUIRE VALIDATION
- IFX-HDR-007 — HDR Log Progress and Backlog — DEFINED — SOURCE SEMANTICS REQUIRE VALIDATION

The HDR design is SQL-only at runtime and does not execute `onstat`. Its first source candidates are `sysmaster:sysdri` and `sysmaster:syscluster`. No HDR collector, deployment integration, Zabbix template or trigger has been implemented. Real target HDR validation is mandatory before implementation, including source schema, state mappings, peer identity, acknowledgement-time semantics and log-progress semantics.

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
