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

Os itens abaixo devem ser concluídos e testados antes de instalar collectors ou launchers. Se o teste de conexão falhar, pare o procedimento e corrija o Client SDK, o `sqlhosts`, a rede ou a credencial.

### 2.1 Binários e identidade

- `ksh`, `dbaccess`, Zabbix Agent e Informix Client SDK compatível;
- usuário/grupo do Agent (`zabbix:zabbix` no desenvolvimento);
- host cadastrado no Zabbix com `Hostname` correspondente;
- PHP/frontend Zabbix compatível com o módulo do widget;
- backup dos arquivos atuais antes de atualizar.

Confirme os binários:

```bash
command -v ksh
command -v dbaccess
command -v zabbix_agentd
id zabbix
```

### 2.2 Como localizar o `sqlhosts`

O `sqlhosts` normalmente fica em um destes locais:

```text
${INFORMIXDIR}/etc/sqlhosts
${INFORMIXDIR}/etc/sqlhosts.ol_informix1210
/etc/sqlhosts
```

Localize o Client SDK e procure o arquivo:

```bash
printf 'INFORMIXDIR=%s\n' "${INFORMIXDIR:-não definido}"
find /opt /usr /etc -type f -name sqlhosts -readable 2>/dev/null
```

Se `INFORMIXDIR` não estiver definido, use o diretório informado pelo administrador do Client SDK. O caminho escolhido deve ser o mesmo passado ao instalador em `--informix-sqlhosts`.

### 2.3 Conteúdo mínimo do `sqlhosts`

O arquivo precisa conter uma linha para o nome usado em `--informix-server`, com quatro campos:

```text
ol_informix1210  onsoctcp  informix-db.example.com  9088
```

Significado:

| Campo | Exemplo | Significado |
|---|---|---|
| 1 | `ol_informix1210` | `INFORMIXSERVER` usado pelo cliente |
| 2 | `onsoctcp` | protocolo Informix/SQLI |
| 3 | `informix-db.example.com` | hostname ou IP do servidor Informix |
| 4 | `9088` | serviço/porta SQLI do servidor |

O nome do primeiro campo deve ser exatamente igual ao valor de `--informix-server`. A porta pode ser um número ou um nome de serviço resolvido em `/etc/services`.

Não copie este exemplo para produção sem substituir host e porta pelos valores fornecidos pelo DBA. Valide resolução de nome e conectividade de rede antes de continuar.

### 2.4 Como validar o `sqlhosts`

```bash
export INFORMIXDIR=/opt/informix
export INFORMIXSERVER=ol_informix1210
export INFORMIXSQLHOSTS=/opt/informix/etc/sqlhosts
export PATH="$INFORMIXDIR/bin:$PATH"
export LD_LIBRARY_PATH="$INFORMIXDIR/lib:$INFORMIXDIR/lib/esql:${LD_LIBRARY_PATH:-}"

test -r "$INFORMIXSQLHOSTS"
grep -E "^[[:space:]]*${INFORMIXSERVER}[[:space:]]" "$INFORMIXSQLHOSTS"
```

O segundo comando deve retornar exatamente a entrada da instância. Se não retornar, o nome passado ao instalador não corresponde ao `sqlhosts`.

### 2.5 Arquivo `informix-connect.sql`

O `informix-connect.sql` é um script SQL privado usado pelo executor para abrir a sessão não interativa. Ele deve ser criado pelo DBA ou pelo responsável pelas credenciais, nunca pelo Git ou pelo instalador.

Localização aprovada:

```text
/etc/zabbix-informix/informix-connect.sql
```

Exemplo mínimo, usando placeholders que devem ser substituídos pelo DBA:

```sql
CONNECT TO 'sysmaster@ol_informix1210'
    USER 'zabbix_monitor'
    USING 'SENHA_FORNECIDA_PELO_DBA';
```

O formato exato pode variar conforme a política de autenticação Informix. Não invente usuário, senha, banco ou sintaxe alternativa: use o formato já aprovado no ambiente e teste com `dbaccess`.

Propriedade e permissões:

```bash
sudo chown root:zabbix /etc/zabbix-informix/informix-connect.sql
sudo chmod 0640 /etc/zabbix-informix/informix-connect.sql
sudo test -r /etc/zabbix-informix/informix-connect.sql
```

O arquivo deve ser somente leitura para o processo (`0640`), pertencente a `root:zabbix`. Não use `777`, não deixe o arquivo no diretório pessoal de um operador e não o envie para Git, tickets ou logs.

### 2.6 Teste mínimo de conexão — antes da instalação

Com `INFORMIXDIR`, `INFORMIXSERVER` e `INFORMIXSQLHOSTS` definidos:

```bash
dbaccess - /etc/zabbix-informix/informix-connect.sql
```

O comando deve terminar com retorno `0`, sem erro de servidor, usuário, senha ou `sqlhosts`. Se o script de conexão abrir a sessão mas não encerrar, use o formato de conexão aprovado pelo DBA com `DISCONNECT CURRENT;`.

### 2.7 Teste dummy no `sysmaster`

Antes de instalar o pacote, crie um arquivo temporário sem credenciais:

```bash
cat > /tmp/ifx-zabbix-preflight.sql <<'EOF'
DATABASE sysmaster;
SET ISOLATION TO DIRTY READ;
SELECT DBINFO('dbname') AS database_name;
DISCONNECT CURRENT;
EOF
```

Execute usando o mesmo ambiente do Client SDK:

```bash
dbaccess - /etc/zabbix-informix/informix-connect.sql < /tmp/ifx-zabbix-preflight.sql
echo "DBACCESS_RC=$?"
rm -f /tmp/ifx-zabbix-preflight.sql
```

Critérios para avançar: `DBACCESS_RC=0`, banco selecionado `sysmaster`, isolamento aceito e uma linha de resultado. Somente depois desses critérios a instalação de collectors e launchers está autorizada.

## 3. Instalação do coletor

Só avance para esta seção depois que os testes da seção 2 terminarem com `DBACCESS_RC=0`.

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
