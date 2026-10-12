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
- `Disk sorts` indica sorts executados em disco e é o principal indicador de spill; `sql_sorttotal`, `sql_sortdisk` e `sql_sortmem` já cobrem a observabilidade de sorts. A utilização do temporary dbspace é acompanhada separadamente por STORAGE-011.
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

O SQL-MASTER é a fonte única para o painel. SQL-002 discovery/detail não deve ser recriado; seus artefatos legados foram removidos. Sorts/temporários estão cobertos por SQL-MASTER/SQL-012/SQL-013 e STORAGE-011. Package Cache Changes, CPU por SQL e Stale Statistics permanecem indisponíveis ou fora do escopo implementado.
# Exportador de cadastro de target

O arquivo `05-collectors/informix/tools/ifx-export-agent-target.ksh` é executado no host Informix e produz um relatório somente leitura para o cadastro manual no Linux com Zabbix Agent.

Após transferir o arquivo, ajuste a permissão obrigatoriamente:

```sh
chmod 0750 05-collectors/informix/tools/ifx-export-agent-target.ksh
```

Valide com `ksh -n`, execute o exportador e revise `SQLHOSTS_ENTRY`, `OBSERVED_ROLE`, `OBSERVED_STATE`, `OBSERVED_HDR_PEER` e `CANONICAL_ROLE`. Não copie senhas para o relatório. O arquivo `informix-connect.sql` do target deve ser criado separadamente com proprietário `root`, grupo `zabbix` e modo `0640`.
# Operação do catálogo manual

Para adicionar um Informix, inclua uma linha `alias|INFORMIXSERVER` em `/etc/zabbix-informix/targets/catalog`, crie `/etc/zabbix-informix/targets/<INFORMIXSERVER>/informix-connect.sql` com `root:zabbix` e modo `0640`, e valide o target pelo alias com `ifx_target_load <alias>`. Não grave `PRIMARY`, `SECONDARY` ou senha no catálogo. O papel é sempre determinado pelo Informix durante a coleta.

Após qualquer transferência ou alteração do catálogo:

```sh
sudo chown root:zabbix /etc/zabbix-informix/targets/catalog
sudo chmod 0640 /etc/zabbix-informix/targets/catalog
```
