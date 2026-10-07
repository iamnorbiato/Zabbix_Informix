# Status executivo — Zabbix Informix

**Data de referência:** 2026-10-07
**Ambiente validado:** Linux de desenvolvimento com Informix, Zabbix Agent e frontend Zabbix separados
**Aceite de produção/AIX:** pendente

## 1. Como ler este documento

Este arquivo é o controle executivo do projeto. Ele consolida o que foi acordado, o que foi implementado, o que foi validado somente no desenvolvimento e o que permanece pendente ou rejeitado.

| Status | Significado |
|---|---|
| `DEVELOPMENT_RUNTIME_VALIDATED` | Fonte, SQL/collector, launcher, Agent e item exercitados no desenvolvimento; não significa aceite de produção. |
| `DEFINED` | Métrica acordada e documentada, mas fonte ou cadeia operacional ainda não validada completamente. |
| `SOURCE_REJECTED` | A fonte investigada não possui semântica confiável. |
| `OUT_OF_SCOPE` | A métrica pertence a outra camada/equipe, como filesystem/AIX. |
| `NOT_IMPLEMENTED` | Decisão consciente de não implementar neste ciclo. |

## 2. Resumo executivo

| Área | Estado atual |
|---|---|
| Arquitetura de coleta | Definida e implementada com SQL, collectors, launchers e runtime parametrizado. |
| Health | HEALTH-001 a HEALTH-008 validados no desenvolvimento; aceite no alvo pendente. |
| Sessions | SESSION-001 a SESSION-005 validados no desenvolvimento; aceite no alvo pendente. |
| Locks | LOCK-001 a LOCK-005 validados; LOCK-006 e LOCK-007 rejeitados por fonte/semântica. |
| Storage Informix | STORAGE-001 a STORAGE-006 e STORAGE-011 implementados; STORAGE-007 a STORAGE-010 fora deste pacote. |
| Logs/backup | Definidos/documentados; validação operacional completa pendente. |
| HDR/HA | Contratos definidos; validação de par HDR real pendente. |
| SQL performance | SQL-MASTER e widget Top-N validados no desenvolvimento; SQL-017 QPS implementado. |
| Grafana | Reutilização arquitetural definida; dashboard ainda não implementado. |

## 3. Informix Health

| ID | Métrica | Estado |
|---|---|---|
| IFX-HEALTH-001 | Estado da instância | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-HEALTH-002 | Uptime | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-HEALTH-003 | Assert failures | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-HEALTH-004 | Contagem de checkpoints | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-HEALTH-005 | Duração de checkpoint | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-HEALTH-006 | Esperas de checkpoint | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-HEALTH-007 | LRU writes | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-HEALTH-008 | Foreground writes | `DEVELOPMENT_RUNTIME_VALIDATED` |

## 4. Sessões e concorrência

| ID | Métrica | Estado |
|---|---|---|
| IFX-SESSION-001 | Total de sessões conectadas | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-SESSION-002 | Sessões em read call | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-SESSION-003 | Pico semanal de conexões físicas | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-SESSION-004 | Sessões aguardando execução | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-SESSION-005 | Sessões aguardando por motivo | `DEVELOPMENT_RUNTIME_VALIDATED` |

## 5. Locks

| ID | Métrica | Estado |
|---|---|---|
| IFX-LOCK-001 | Sessões aguardando locks | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-LOCK-002 | Lock waits | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-LOCK-003 | Lock timeouts | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-LOCK-004 | Deadlocks | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-LOCK-005 | Exaustão da tabela de locks | `DEVELOPMENT_RUNTIME_VALIDATED` |
| IFX-LOCK-006 | Duração máxima de lock wait | `SOURCE_REJECTED` |
| IFX-LOCK-007 | Lock escalation | `SOURCE_REJECTED` |

## 6. Storage Informix

| ID | Métrica | Estado |
|---|---|---|
| IFX-STORAGE-001 | Utilização de dbspace | Implementada; desenvolvimento validado. |
| IFX-STORAGE-002 | Espaço livre de dbspace | Implementada; desenvolvimento validado. |
| IFX-STORAGE-003 | Crescimento/expansão de dbspace | Implementada; desenvolvimento validado. |
| IFX-STORAGE-004 | Estado de chunk | Implementada; desenvolvimento validado. |
| IFX-STORAGE-005 | Utilização de chunk | Implementada; desenvolvimento validado. |
| IFX-STORAGE-006 | Espaço livre de chunk | Implementada; desenvolvimento validado. |
| IFX-STORAGE-007 | Filesystem utilization | `OUT_OF_SCOPE` — monitoração de SO/AIX. |
| IFX-STORAGE-008 | Filesystem free space | `OUT_OF_SCOPE` — monitoração de SO/AIX. |
| IFX-STORAGE-009 | Filesystem inodes | `OUT_OF_SCOPE` — monitoração de SO/AIX. |
| IFX-STORAGE-010 | Mapeamento chunk/filesystem | `OUT_OF_SCOPE` — depende do host do filesystem. |
| IFX-STORAGE-011 | Utilização de temporary dbspace | Implementada; desenvolvimento validado. |

## 7. Logs, backup e HDR

| Área | Métricas | Estado |
|---|---|---|
| Logical/physical logs | LOG-001 a LOG-005 | Definidas/documentadas; validação operacional completa pendente. |
| Backup inventory | LOG-006 | Definida; validação no ambiente-alvo pendente. |
| HDR local | HDR-001 e HDR-002 | Desenvolvimento/contratos validados; par real pendente. |
| HDR peer | HDR-003 a HDR-007 | `DEFINED` ou `PENDING_TARGET_VALIDATION`; requer par HDR real. |

## 8. SQL e performance

O SQL-MASTER é o item mestre textual baseado em `syssqltrace`. O widget Zabbix reutiliza esse dataset, possui seletor interno de métrica, rolagem interna e detalhe do statement selecionado. Não são criados itens persistentes por `sql_id`.

| ID/visão | Conteúdo | Estado |
|---|---|---|
| SQL-001 | Active SQL Top-N | Implementado como dataset diagnóstico separado. |
| SQL-MASTER | Top-N consolidado | `DEVELOPMENT_RUNTIME_VALIDATED` |
| SQL-003 a SQL-016 | Runtime, execuções, tempos, leituras, cache, locks, I/O, sorts, custos e linhas | Visões do SQL-MASTER no seletor; sem itens duplicados. |
| SQL-017 | User SQL QPS | Implementado e validado no desenvolvimento. |

### Decisões adicionais

| Métrica considerada | Decisão |
|---|---|
| Read/write ratio | Incorporada ao SQL-MASTER. |
| CPU por SQL | Não disponível de forma confiável; não fabricar métrica. |
| QPS | Coberto pelo SQL-017. |
| Sorts/temp usage | Coberto por `sql_sorttotal`, `sql_sortdisk`, `sql_sortmem` e campos do trace. |
| Package-cache changes | `NOT_IMPLEMENTED`; sem contador por SQL validado no `syssqltrace`. |
| Stale statistics | `NOT_IMPLEMENTED`; `systables.ustlowts` não determina sozinho obsolescência. |

### SQL-002 legado

O discovery/detail por `sql_id` foi removido. A criação de itens persistentes para IDs transitórios causava crescimento desnecessário no Zabbix. O detalhe completo agora é apresentado sob demanda no próprio widget.

## 9. Runtime e operação

- Coletores e launchers usam o `runtime.env` parametrizado.
- SQL-MASTER e SQL-017 foram instalados no agente.
- O widget customizado foi instalado no frontend Zabbix.
- O template/configuração não possui referências ao SQL-002 legado.
- O trace de desenvolvimento foi validado em modo High/Global para gerar histórico suficiente ao painel.
- A validação de desenvolvimento não constitui aceite de produção.

## 10. Próximos passos

1. Reinstalar/validar o release final no host-alvo.
2. Validar permissões, custo e compatibilidade no Informix/AIX alvo.
3. Exportar e revisar o YAML/template Zabbix final.
4. Definir thresholds a partir de baseline do ambiente-alvo.
5. Reproduzir o painel no Grafana, se necessário, usando o SQL-MASTER como fonte Zabbix.
