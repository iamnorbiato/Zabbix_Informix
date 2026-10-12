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

### 2.5 Catálogo e arquivos de conexão por target

O Collector Linux pode monitorar vários Informix com uma única instalação. O
catálogo é manual e relaciona um alias operacional ao valor `INFORMIXSERVER`:

```text
/etc/zabbix-informix/targets/catalog
```

Exemplo com três targets:

```text
producao-primary|ol_informix1210
producao-hdr|ol_informix1210_hdr
homologacao|ol_informix_hml
```

Para cada valor `INFORMIXSERVER`, crie um diretório e um arquivo privado de
conexão separado:

```text
/etc/zabbix-informix/targets/ol_informix1210/informix-connect.sql
/etc/zabbix-informix/targets/ol_informix1210_hdr/informix-connect.sql
/etc/zabbix-informix/targets/ol_informix_hml/informix-connect.sql
```

O `informix-connect.sql` deve ser criado pelo DBA ou responsável pelas
credenciais, nunca pelo Git ou pelo instalador. Não coloque senha no catálogo.

Exemplo mínimo, usando placeholders que devem ser substituídos pelo DBA:

```sql
CONNECT TO 'sysmaster@ol_informix1210'
    USER 'zabbix_monitor'
    USING 'SENHA_FORNECIDA_PELO_DBA';
```

O formato exato pode variar conforme a política de autenticação Informix. Não invente usuário, senha, banco ou sintaxe alternativa: use o formato já aprovado no ambiente e teste com `dbaccess`.

Propriedade e permissões:

```bash
sudo install -d -o root -g zabbix -m 0750 \
  /etc/zabbix-informix/targets/ol_informix1210
sudo chown root:zabbix \
  /etc/zabbix-informix/targets/ol_informix1210/informix-connect.sql
sudo chmod 0640 \
  /etc/zabbix-informix/targets/ol_informix1210/informix-connect.sql
sudo test -r \
  /etc/zabbix-informix/targets/ol_informix1210/informix-connect.sql
```

O arquivo deve ser somente leitura para o processo (`0640`), pertencente a `root:zabbix`. Não use `777`, não deixe o arquivo no diretório pessoal de um operador e não o envie para Git, tickets ou logs.

### 2.6 Teste mínimo de conexão — antes da instalação

Com `INFORMIXDIR`, `INFORMIXSERVER` e `INFORMIXSQLHOSTS` definidos:

```bash
dbaccess - /etc/zabbix-informix/targets/ol_informix1210/informix-connect.sql
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
dbaccess - /etc/zabbix-informix/targets/ol_informix1210/informix-connect.sql < /tmp/ifx-zabbix-preflight.sql
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
  --connection-file /etc/zabbix-informix/targets/ol_informix1210/informix-connect.sql
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

### 4.1 Apresentação do Linux Collector ao Zabbix Server

Esta etapa é executada depois que o pacote foi instalado no Linux Collector e o
serviço `zabbix-agent` está ativo. O template não é instalado no Linux; ele será
importado posteriormente no Zabbix Server.

No Linux Collector, confirme o nome do host e o endereço que será informado ao
Zabbix Server:

```bash
hostname
hostname -f
ip -br address
sudo systemctl is-active zabbix-agent
```

Confirme que o Agent está escutando na porta padrão:

```bash
sudo ss -lntp | grep ':10050'
```

Confirme as chaves instaladas e o parâmetro de target:

```bash
sudo grep -nE \
  'ifx\.(sql|health|session|lock|log|hdr|storage).*target' \
  /etc/zabbix/zabbix_agentd.d/zabbix-informix.conf
```

Teste localmente uma chave representativa para cada grupo antes de envolver o
Zabbix Server:

```bash
sudo zabbix_agentd -t \
  'ifx.health.instance_state_target[producao-primary]'

sudo zabbix_agentd -t \
  'ifx.sql.top_n_target[producao-primary]'

sudo zabbix_agentd -t \
  'ifx.storage.dbspace.discovery_target[producao-primary]'
```

Todos os testes devem retornar valor válido, sem `ZBX_NOTSUPPORTED`, erro de
permissão ou erro de conexão Informix.

### 4.2 Teste a partir do Zabbix Server ou Proxy

Execute esta etapa no Zabbix Server ou Proxy que fará a coleta. Substitua
`<IP_DO_LINUX_COLLECTOR>` pelo endereço do Linux Collector:

```bash
zabbix_get \
  -s <IP_DO_LINUX_COLLECTOR> \
  -p 10050 \
  -k 'ifx.health.instance_state_target[producao-primary]'
```

Exemplo:

```bash
zabbix_get \
  -s 192.168.0.50 \
  -p 10050 \
  -k 'ifx.health.instance_state_target[producao-primary]'
```

O retorno deve ser um valor Informix válido, por exemplo:

```text
5
```

Teste também o SQL-MASTER:

```bash
zabbix_get \
  -s 192.168.0.50 \
  -p 10050 \
  -k 'ifx.sql.top_n_target[producao-primary]'
```

O retorno esperado é um texto delimitado por `|`, contendo as linhas do
SQL-MASTER. Não deve retornar `ZBX_NOTSUPPORTED` nem `Received empty response`.

Se o teste falhar, volte ao Linux Collector e verifique:

```bash
sudo systemctl status zabbix-agent
sudo journalctl -u zabbix-agent -n 50 --no-pager
sudo tail -n 50 /var/log/zabbix/zabbix_agentd.log
```

No Zabbix Server ou Proxy, confirme a conectividade de rede:

```bash
nc -vz <IP_DO_LINUX_COLLECTOR> 10050
```

Somente depois de obter retorno válido com `zabbix_get` deve-se importar o
template, criar os hosts Informix e definir a macro `{$IFX_TARGET}`.

## 5. Instalação do painel SQL

No host do frontend Zabbix, copie o pacote para uma área de staging:

```bash
sudo mkdir -p /tmp/informix_sql_top_n
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

- SQL-002 discovery/detail foi removido do release; o detalhe é exibido no widget.
- SQL-003 a SQL-016 são visões do SQL-MASTER, não itens duplicados.
- Sorts e atividade temporária já são cobertos por SQL-MASTER/SQL-012/SQL-013 (`sql_sorttotal`, `sql_sortdisk`, `sql_sortmem`) e STORAGE-011. Não instale um coletor adicional para essa finalidade.
- Package Cache Changes não possui contador Informix confiável validado em `syssqltrace`; permanece encerrado como indisponível e não deve ser criado como métrica artificial.
- Stale Statistics não possui implementação aprovada.
- Validação de desenvolvimento não equivale a aceite de produção/AIX.
# Exportação do cadastro de target no host Informix

O cadastro dos servidores Informix no Linux coletor é manual. No host Informix, execute o exportador somente para gerar um relatório de referência:

```sh
ksh -n 05-collectors/informix/tools/ifx-export-agent-target.ksh
print "EXPORTER_SYNTAX_RC=$?"

chmod 0750 05-collectors/informix/tools/ifx-export-agent-target.ksh
print "EXPORTER_MODE_RC=$?"

ksh -c '
. /etc/zabbix-informix/runtime.env || return 1
IFX_CONNECT_FILE=/etc/zabbix-informix/targets/ol_informix1210/informix-connect.sql \\
  05-collectors/informix/tools/ifx-export-agent-target.ksh
print "EXPORTER_RC=$?"
'
```

O relatório deve ser revisado antes do cadastro no Linux coletor. `OBSERVED_ROLE` e `OBSERVED_STATE` são valores brutos do Informix; `CANONICAL_ROLE` é a normalização operacional. O papel não deve ser gravado como configuração fixa, pois é redescoberto durante a coleta.

No Linux coletor, após criar o diretório do target, o arquivo de conexão deve permanecer protegido:

```sh
sudo chown root:zabbix /etc/zabbix-informix/targets/<INFORMIXSERVER>/informix-connect.sql
sudo chmod 0640 /etc/zabbix-informix/targets/<INFORMIXSERVER>/informix-connect.sql
```
# Catálogo manual de targets Informix

Quando um Agent Linux monitora mais de um Informix, mantenha o catálogo em `/etc/zabbix-informix/targets/catalog`. O formato é `alias|INFORMIXSERVER`, uma linha por target autorizado:

```text
producao-primary|ol_informix1210
producao-standby|ol_informix1210_hdr
homologacao|ol_informix_hml
```

O arquivo deve ser instalado com `root:zabbix` e modo `0640`. Ative `IFX_TARGET_REQUIRE_CATALOG=YES` no `runtime.env`. O alias é apenas uma identificação operacional; o papel `PRIMARY`, `SECONDARY` ou `STANDALONE` continua sendo coletado dinamicamente.
