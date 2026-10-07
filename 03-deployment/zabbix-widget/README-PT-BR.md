# Pacote do painel Informix SQL Top-N

## Finalidade

Widget customizado para o frontend Zabbix 7.0. Ele lê o item mestre textual `ifx.sql.top_n`, apresenta o Top-N em tabela e mostra o SQL completo da linha selecionada.

## Conteúdo

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

## Pré-requisitos

- Zabbix frontend 7.0 compatível;
- PHP do frontend em funcionamento;
- item mestre `ifx.sql.top_n` existente e associado ao host;
- permissão de escrita administrativa em `/usr/share/zabbix/modules`.

## Instalação

Copie o diretório `informix_sql_top_n` para:

```text
/usr/share/zabbix/modules/informix_sql_top_n
```

Use proprietário `root:root` e modo `0644` nos arquivos. Valide PHP com `php -l` quando o CLI estiver disponível. Recarregue o frontend e faça recarga completa do navegador.

## Uso

Adicione o widget ao dashboard, selecione o item mestre e use o seletor interno para alterar a métrica. O painel atualiza a ordenação imediatamente. A tabela possui rolagem interna; o painel lateral exibe o statement completo selecionado.

## Atualização e rollback

Antes de atualizar, preserve uma cópia do diretório instalado. Para rollback, restaure a versão anterior completa do módulo e recarregue o frontend. Não misture arquivos JavaScript, CSS, PHP e views de versões diferentes.

## Limites

O widget não acessa Informix diretamente, não cria itens Zabbix e não implementa discovery por `sql_id`. Ele depende do texto armazenado pelo item mestre.
