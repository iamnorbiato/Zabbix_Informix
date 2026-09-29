# Zabbix Informix — Runbook de instalação e desinstalação

## 1. Escopo e estado

Este procedimento cobre os coletores implementados de HEALTH-001 a HEALTH-008, SESSION-001 a SESSION-005 e LOCK-001 a LOCK-005. LOCK-006 e LOCK-007 não possuem implementação aprovada. HDR ainda está na fase de documentação.

O procedimento completo abaixo foi exercitado na topologia Linux de desenvolvimento. A instalação no AIX depende das verificações da seção 10.

O Agent e o Informix Client SDK ficam no **host de coleta**. O servidor Informix e o Zabbix Server podem estar em outros hosts. Os caminhos do repositório de desenvolvimento não fazem parte da execução instalada.

## 2. Inventário obrigatório antes da instalação

Preencha estes valores para **cada host de coleta**:

| Dado | Desenvolvimento `cluster-prime` | Ambiente de destino |
|---|---|---|
| Sistema operacional | Ubuntu Linux | Confirmar |
| Instância Informix | `ol_informix1210` | Confirmar |
| Diretório do Client SDK | `/opt/informix` | Confirmar |
| Arquivo `sqlhosts` | `/opt/informix/etc/sqlhosts` | Confirmar |
| Usuário/grupo do Agent | `zabbix:zabbix` | Confirmar |
| Diretório incluído pelo Agent | `/etc/zabbix/zabbix_agentd.d` | Confirmar |
| Nome do host cadastrado no Zabbix | `cluster-prime` | Confirmar |
| Endereço do Zabbix Server | Configurado no Agent | Confirmar |
| Diretório de código instalado | `/opt/zabbix-informix` | Confirmar |
| Diretório de configuração privada | `/etc/zabbix-informix` | Confirmar |
| Diretório dos launchers | `/usr/local/lib/zabbix-informix` | Confirmar |
| Origem do arquivo privado de conexão | `/etc/zabbix-informix/informix-connect.sql` nas atualizações | Confirmar |
| Comando de reinício do Agent | `systemctl restart zabbix-agent` | Confirmar |

O instalador atual exige um usuário e grupo de sistema chamados `zabbix`. Caso o Agent de destino use outra identidade, adaptar e validar o instalador antes de implantá-lo; a troca não é um parâmetro do instalador atual.

## 3. Pré-requisitos no host de coleta

1. Obter uma cópia da versão aprovada do repositório no host de coleta. O instalador resolve o diretório da release a partir da posição do próprio script.
2. Ter `ksh`, Zabbix Agent, `dbaccess` e as bibliotecas do Informix Client SDK compatíveis com o sistema operacional.
3. Confirmar que o Agent lê seu diretório de includes e que o host existe no Zabbix com nome idêntico ao `Hostname` configurado no Agent.
4. Configurar o Client SDK com o `sqlhosts` que resolve a instância Informix remota.
5. Disponibilizar um arquivo privado `informix-connect.sql` válido para `dbaccess` em modo não interativo. Ele deve ficar fora do Git. O instalador aceita um arquivo já existente; não cria credenciais.
6. Se houver estado persistente de coleta, identificar sua localização antes da atualização. O cursor de HEALTH-003 deve ser preservado para não repetir eventos.
7. Separar o template Zabbix exportado: `02-zabbix/templates/template-zabbix-tailor-informix-health.yaml`.

Não execute o instalador antes de identificar os caminhos de instalação e confirmar que eles são exclusivos deste produto. O instalador cria diretórios, copia os coletores, altera permissões e grava o arquivo de inclusão do Agent.

## 4. Variáveis de ambiente do Informix

O instalador gera `<CONFIG_HOME>/runtime.env` com os seguintes valores:

```text
IFX_COLLECTOR_HOME=<INSTALL_HOME>
IFX_INFORMIXDIR=<INFORMIX_HOME>
IFX_INFORMIXSERVER=<INFORMIXSERVER>
IFX_INFORMIXSQLHOSTS=<INFORMIXSQLHOSTS>
IFX_CONFIG_DIR=<CONFIG_HOME>
IFX_STATE_DIR=<CONFIG_HOME>/state
IFX_CONNECT_FILE=<CONFIG_HOME>/informix-connect.sql
```

Cada launcher carrega esse arquivo e exporta `INFORMIXDIR`, `INFORMIXSERVER`, `INFORMIXSQLHOSTS`, `PATH` com `<INFORMIXDIR>/bin`, e `LD_LIBRARY_PATH` com `<INFORMIXDIR>/lib` e `<INFORMIXDIR>/lib/esql`. O processo do Agent não depende do `.bashrc` ou `.profile` pessoal de um operador.

O usuário do Agent precisa conseguir atravessar os diretórios do SDK, ler `sqlhosts`, carregar as bibliotecas e executar `dbaccess`. Confirme os nomes e caminhos de biblioteca no AIX antes de reutilizar a configuração Linux de `LD_LIBRARY_PATH`.

Os valores padrão de desenvolvimento ainda presentes em `05-collectors/informix/lib/informix-env.ksh` são substituídos por `runtime.env` na instalação. Eles não devem ser usados como configuração de produção.

## 5. Instalação no `cluster-prime`

Execute a partir da raiz da release, no host de coleta:

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

Na primeira instalação, substitua `--connection-file` pela localização real do arquivo privado existente. Se migrar o estado de outra instalação, acrescente `--state-source <diretório-existente>` somente na primeira instalação, antes de o novo `<CONFIG_HOME>/state` existir. O instalador preserva o estado já presente no destino.

Resultado esperado:

```text
Zabbix Informix installation completed.
Restart the Zabbix Agent using the service-management command for this host.
```

Reinicie o Agent no desenvolvimento:

```bash
sudo systemctl restart zabbix-agent
sudo systemctl is-active zabbix-agent
```

Resultado esperado: `active`.

## 6. Permissões esperadas

| Caminho | Proprietário e grupo | Modo |
|---|---|---|
| `<INSTALL_HOME>` e diretórios internos | `root:zabbix` | `750` |
| Scripts KSH instalados | `root:zabbix` | `750` |
| Statements SQL instalados | `root:zabbix` | `640` |
| `<CONFIG_HOME>` | `root:zabbix` | `1730` |
| `<CONFIG_HOME>/informix-connect.sql` | `root:zabbix` | `640` |
| `<CONFIG_HOME>/runtime.env` | `root:zabbix` | `640` |
| `<CONFIG_HOME>/state` | `zabbix:zabbix` | `700` |
| Arquivos de estado | `zabbix:zabbix` | `600` |
| Launchers instalados | `root:zabbix` | `750` |
| Include `zabbix-informix.conf` | `root:root` | `644` |

Não exiba nem copie para tickets o conteúdo de `informix-connect.sql`.

## 7. Validação após instalar

Execute no host de coleta:

```bash
sudo -u zabbix /usr/local/lib/zabbix-informix/ifx-health-001
sudo zabbix_agentd -t ifx.health.instance_state
sudo zabbix_agentd -t ifx.health.assert_failures.raw
sudo zabbix_agentd -t ifx.session.total_connected
sudo zabbix_agentd -t ifx.lock.sessions_waiting
sudo zabbix_agentd -t ifx.lock.waits
sudo zabbix_agentd -t ifx.lock.timeouts
sudo zabbix_agentd -t ifx.lock.deadlocks
sudo zabbix_agentd -t ifx.lock.table_exhaustion_attempts
```

Os valores dependem da instância e do instante da coleta. Cada chave deve retornar um valor válido, não uma mensagem de erro. A chave HEALTH-003 é stateful: o primeiro uso pode estabelecer baseline; confirme a política de cursor antes da instalação em outra instância.

No Zabbix Server, importe o template exportado, vincule-o ao host que representa o Agent de coleta e confira `Monitoring → Latest data`. O item bruto HEALTH-003 deve alimentar seu item dependente; SESSION-005 deve alimentar seis itens dependentes. Confirme que os triggers esperados foram importados.

O instalador local não importa o template no Zabbix Server nem cadastra o host. Esses passos pertencem à configuração do Zabbix.

## 8. Atualização e retorno à release anterior

Antes de atualizar, registre a versão da release e preserve uma cópia recuperável do código instalado, dos launchers, do include do Agent, do arquivo privado de conexão e do estado. Não inclua o arquivo privado em um repositório Git.

Rode o instalador da nova release com os mesmos parâmetros. Ele copia `01-statements` e `05-collectors` para `<INSTALL_HOME>`, substitui launchers conhecidos e recria `runtime.env` e o include do Agent. Depois reinicie o Agent e execute a validação da seção 7.

O instalador atual usa `cp -R` sobre a instalação existente. Portanto, uma atualização pode deixar arquivos antigos que não existem mais na release nova. Revise esse comportamento antes de declarar um processo de upgrade de produção confiável.

Se precisar voltar à release anterior, reinstale aquela release com os mesmos parâmetros e restaure os artefatos preservados conforme o incidente. Preserve o diretório de estado sempre que precisar manter a posição do cursor HEALTH-003.

## 9. Desinstalação

### Remoção padrão, com preservação de dados

Execute a partir da raiz da release, no host de coleta:

```bash
sudo ksh 03-deployment/uninstall-zabbix-informix.ksh \
  --install-home /opt/zabbix-informix \
  --config-home /etc/zabbix-informix \
  --launcher-home /usr/local/lib/zabbix-informix \
  --agent-include-dir /etc/zabbix/zabbix_agentd.d
```

Essa operação remove o include `zabbix-informix.conf` e os launchers conhecidos. Preserva `<INSTALL_HOME>`, `<CONFIG_HOME>`, as credenciais e o estado dos coletores. Reinicie o Agent depois da remoção.

### Remoção completa

O mesmo comando com `--purge` também remove `<INSTALL_HOME>` e `<CONFIG_HOME>`, incluindo `informix-connect.sql` e o estado HEALTH-003. Faça isso somente após confirmar os caminhos exatos e decidir o destino do estado e das credenciais. O desinstalador aceita para os três diretórios do produto apenas caminhos absolutos terminados em `/zabbix-informix`.

Exemplo de desenvolvimento:

```bash
sudo ksh 03-deployment/uninstall-zabbix-informix.ksh \
  --install-home /opt/zabbix-informix \
  --config-home /etc/zabbix-informix \
  --launcher-home /usr/local/lib/zabbix-informix \
  --agent-include-dir /etc/zabbix/zabbix_agentd.d \
  --purge
```

O modo `--purge` ainda não foi exercitado no desenvolvimento. O runbook não presume recuperação automática do que ele remove.

## 10. Pendências específicas do AIX

Antes de executar o instalador no AIX, registrar e confirmar:

1. Versão do AIX, arquitetura, versão de `ksh` e disponibilidade dos comandos usados pelos scripts (`id`, `find`, `sed`, `cp`, `chmod`, `chown`, `dbaccess`).
2. Versão e localização do Informix Client SDK, caminhos das bibliotecas compartilhadas e variável de carregamento adequada ao AIX. A configuração atual exporta `LD_LIBRARY_PATH`, validada no Linux.
3. Identidade real do usuário/grupo do Zabbix Agent. O instalador atual usa `zabbix` de forma fixa.
4. Localização do include do Agent, opções `ServerActive`/`Hostname` e comando de parada, início ou reinício do serviço nesse host.
5. Rotas de rede entre host de coleta, instância Informix e Zabbix Server; resolução de `INFORMIXSERVER` por `sqlhosts`.
6. Localizações aprovadas para código, configuração privada e launchers; confirmar que os diretórios são exclusivos do produto.
7. Método de distribuição e importação do template no Zabbix Server de destino.
8. Política de backup e migração do cursor HEALTH-003, incluindo o comportamento esperado na primeira coleta.

O primeiro deploy AIX deve seguir um procedimento validado nesse próprio sistema antes de ser chamado de instalação suportada.
