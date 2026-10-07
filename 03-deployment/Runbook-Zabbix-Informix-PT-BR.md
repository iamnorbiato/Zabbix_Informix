# Runbook Zabbix Informix — Instalação, Atualização e Desinstalação

## 1. Escopo

Este runbook cobre a instalação do pacote de coleta Informix no host do Zabbix Agent/Informix Client SDK e a instalação do painel SQL no frontend do Zabbix.

O coletor e o painel são componentes distintos:

| Componente | Host | Diretório principal |
|---|---|---|
| Collectors, statements e launchers | Host do Agent/Client SDK | `/opt/zabbix-informix` e `/usr/local/lib/zabbix-informix` |
| Configuração privada | Host do Agent/Client SDK | `/etc/zabbix-informix` |
| Widget SQL Top-N | Host do frontend Zabbix | `/usr/share/zabbix/modules/informix_sql_top_n` |

## 2. Pré-requisitos

- `ksh`, `dbaccess`, Zabbix Agent e Informix Client SDK compatível;
- acesso de leitura ao `sysmaster` e ao banco configurado;
- `sqlhosts` funcional;
- arquivo privado `informix-connect.sql` fora do Git;
- host cadastrado no Zabbix com `Hostname` correspondente;
- PHP/frontend Zabbix compatível com o módulo do widget;
- backup dos arquivos atuais antes de atualizar.

## 3. Instalação do coletor

Na raiz da release, no host de coleta:

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

Resultado esperado: `Zabbix Informix installation completed.`

Depois:

```bash
sudo systemctl restart zabbix-agent
sudo systemctl is-active zabbix-agent
```

Resultado esperado: `active`.

## 4. Validação do coletor

```bash
sudo zabbix_agentd -t ifx.sql.top_n
sudo zabbix_agentd -t ifx.sql.user_qps
sudo zabbix_agentd -t ifx.sql.active.raw
```

Cada chave deve retornar valor válido, sem mensagem de erro ou `Permission denied`.

## 5. Instalação do painel SQL

No host do frontend Zabbix, copie o pacote para uma área de staging:

```bash
sudo mkdir -p /home/norbiato/informix_sql_top_n
```

Instale os arquivos do pacote em:

```text
/usr/share/zabbix/modules/informix_sql_top_n/
```

Preserve esta estrutura:

```text
Widget.php
manifest.json
actions/WidgetView.php
includes/WidgetForm.php
views/widget.view.php
views/widget.edit.php
assets/js/class.widget.js
assets/css/widget.css
```

Permissões esperadas: `root:root`, modo `0644`.

Após atualizar PHP, JavaScript ou CSS, recarregue o Apache/PHP-FPM conforme o serviço do host e faça recarga completa do navegador.

## 6. Configuração no dashboard

1. Abra o dashboard do Zabbix.
2. Adicione o widget `Informix SQL Top-N`.
3. Selecione o item mestre `SQL-MASTER — Top-N SQL — consolidated output`.
4. Salve o widget.
5. Use o seletor interno de métrica para ordenar o mesmo dataset.

## 7. Atualização

1. Registre a versão atual.
2. Preserve `runtime.env`, `informix-connect.sql` e o diretório `state`.
3. Instale a nova release com os mesmos parâmetros.
4. Reinstale os arquivos do widget no frontend.
5. Reinicie o Agent e recarregue o dashboard.
6. Execute as validações das seções 4 e 8.

## 8. Desinstalação do coletor

Remoção padrão, preservando configuração e estado:

```bash
sudo ksh 03-deployment/uninstall-zabbix-informix.ksh \
  --install-home /opt/zabbix-informix \
  --config-home /etc/zabbix-informix \
  --launcher-home /usr/local/lib/zabbix-informix \
  --agent-include-dir /etc/zabbix/zabbix_agentd.d
```

Remoção completa com `--purge` apaga também credenciais e estado. Só execute após confirmar os caminhos e obter autorização explícita.

## 9. Desinstalação do painel

Remova somente o diretório do módulo:

```bash
sudo rm -rf /usr/share/zabbix/modules/informix_sql_top_n
```

Antes, remova o widget dos dashboards ou substitua-o por outro widget. Reinicie o frontend conforme a política do host.

## 10. Limites conhecidos

- SQL-002 discovery/detail foi removido; o detalhe é exibido no widget.
- SQL-003 a SQL-016 são visões do SQL-MASTER, não itens duplicados.
- Package Cache Changes e Stale Statistics não possuem implementação aprovada.
- Validação de desenvolvimento não equivale a aceite de produção/AIX.
