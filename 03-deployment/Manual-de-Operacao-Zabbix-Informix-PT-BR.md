# Manual de Operação — Zabbix Informix

## 1. Painel SQL Top-N

O painel usa o item mestre `ifx.sql.top_n` e apresenta as consultas capturadas pelo `syssqltrace`.

No seletor interno, escolha a métrica desejada:

- Maximum runtime;
- Total executions;
- Average time;
- Disk reads;
- Buffer reads;
- Cache ratio;
- Lock waits;
- Lock wait time;
- I/O waits;
- Disk sorts;
- Memory sorts;
- Estimated cost;
- Estimated rows;
- Actual rows;
- Read/write ratio.

A troca é imediata e não exige recarregar a página. Clique em uma linha para exibir o statement completo no painel lateral.

## 2. Interpretação

- `Runtime` representa tempo decorrido da execução, não CPU puro.
- `Disk reads` e `Buffer reads` são contadores por statement do trace.
- `Disk sorts` indica sorts executados em disco e é o principal indicador de spill.
- `Read/write ratio` é derivada dos campos de leitura e escrita disponíveis.
- `SQL ID` é transitório dentro do buffer do trace.
- A ausência de linhas pode significar ausência de histórico, filtro de banco ou trace desligado.

## 3. Trace Informix

Para investigação controlada, confirme no servidor Informix:

```bash
onstat -g his | head -20
```

Confirme nível, modo global, quantidade de traces e duração do buffer. O trace tem custo e capacidade finitos; não altere o nível em produção sem avaliação do DBA.

## 4. Validação operacional

No host do Agent:

```bash
sudo zabbix_agentd -t ifx.sql.top_n
sudo zabbix_agentd -t ifx.sql.user_qps
sudo systemctl is-active zabbix-agent
```

No frontend, confira `Monitoring → Latest data` para o item mestre e o dashboard para o widget.

## 5. Diagnóstico rápido

| Sintoma | Verificação |
|---|---|
| Sem dados | Testar `ifx.sql.top_n`, trace e histórico do item. |
| `Permission denied` | Conferir modo `750`, proprietário `root:zabbix` e grupo do Agent. |
| Item com string inválida | Conferir contrato do item e o delimitador final do executor. |
| SQL com `\\` ou `|` residual | Atualizar `WidgetView.php` e recarregar frontend/cache. |
| Widget vazio | Conferir item mestre selecionado, módulo instalado e logs do Apache. |
| Tipo atropelando coluna | Confirmar `widget.css` atualizado e recarga completa do navegador. |

## 6. Segurança e operação

Não exiba `informix-connect.sql`, não coloque credenciais no Git e não use comandos do SO para medir filesystem Informix. Filesystem pertence à monitoração de AIX/SO.

## 7. Escopo

O SQL-MASTER é a fonte única para o painel. SQL-002 discovery/detail não deve ser recriado. Package Cache Changes, CPU por SQL e Stale Statistics permanecem fora do escopo implementado.
