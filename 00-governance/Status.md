*1. definir arquitetura da coleta (DONE)*

*2. montar catálogo/matriz das métricas (DONE)*

**3. validar cada métrica manualmente em um Informix/AIX real (CURRENT — IN PROGRESS)**

Informix Health status:

- IFX-HEALTH-001 — Instance State — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-002 — Instance Uptime — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-003 — Assert Failures — DEVELOPMENT_RUNTIME_VALIDATED
- IFX-HEALTH-004 — Checkpoint Count — MOCK_VALIDATED
- IFX-HEALTH-005 — Checkpoint Duration — MOCK_VALIDATED
- IFX-HEALTH-006 — Checkpoint Waits — MOCK_VALIDATED
- IFX-HEALTH-007 — LRU Writes — MOCK_VALIDATED
- IFX-HEALTH-008 — Foreground Writes — MOCK_VALIDATED

`DEVELOPMENT_RUNTIME_VALIDATED` for IFX-HEALTH-001, IFX-HEALTH-002 and IFX-HEALTH-003 means that their remote SQL collectors, Informix Client SDK, Zabbix Agent active checks, Zabbix items and trigger configurations were validated in the Linux development topology.

Target-environment validation remains pending. The production topology may use Informix on AIX and a separate Zabbix Server, Agent and Client SDK host.

Informix Sessions and Concurrency status:

- IFX-SESSION-001 — Total Connected Sessions — MOCK_VALIDATED
- IFX-SESSION-002 — Active Sessions — MOCK_VALIDATED
- IFX-SESSION-003 — Historical Session Peak — MOCK_VALIDATED
- IFX-SESSION-004 — Waiting Threads Total — MOCK_VALIDATED
- IFX-SESSION-005 — Waiting Threads by Reason — MOCK_VALIDATED

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
