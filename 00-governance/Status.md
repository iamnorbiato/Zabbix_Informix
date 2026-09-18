*1. definir arquitetura da coleta (DONE)*

*2. montar catálogo/matriz das métricas (DONE)*

**3. validar cada métrica manualmente em um Informix/AIX real (CURRENT — BLOCKED: REAL ENVIRONMENT NOT YET AVAILABLE)**

Informix Health mock validation completed while real source validation is unavailable:

- IFX-HEALTH-001 — Instance State — MOCK_VALIDATED
- IFX-HEALTH-002 — Instance Uptime — MOCK_VALIDATED
- IFX-HEALTH-003 — Assert Failures — MOCK_VALIDATED
- IFX-HEALTH-004 — Checkpoint Count — MOCK_VALIDATED
- IFX-HEALTH-005 — Checkpoint Duration — MOCK_VALIDATED
- IFX-HEALTH-006 — Checkpoint Waits — MOCK_VALIDATED
- IFX-HEALTH-007 — LRU Writes — MOCK_VALIDATED
- IFX-HEALTH-008 — Foreground Writes — MOCK_VALIDATED

Informix Sessions and Concurrency mock validation completed while real source validation is unavailable:

- IFX-SESSION-001 — Total Connected Sessions — MOCK_VALIDATED
- IFX-SESSION-002 — Active Sessions — MOCK_VALIDATED
- IFX-SESSION-003 — Historical Session Peak — MOCK_VALIDATED
- IFX-SESSION-004 — Waiting Threads Total — MOCK_VALIDATED
- IFX-SESSION-005 — Waiting Threads by Reason — MOCK_VALIDATED

Next lifecycle target for these metrics:

`SOURCE_VALIDATED`

This requires access to a real Informix/AIX environment.

The existing mock parsers and collectors validate normalized collection contracts only.

They do not constitute completion of the operational collector implementation defined by item 4.

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