#!/bin/ksh
. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1

IFX_SQL_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SQL_DIR}/../../.." && pwd)"
statement="${IFX_REPOSITORY_DIR}/01-statements/informix-sql/IFX-SQL-017-User-SQL-QPS.sql"
[[ -r "${statement}" ]] || { print -u2 "Informix statement file not found: ${statement}"; exit 1; }

dataset="$(ifx_db_execute sysmaster "${statement}")" || exit 1
[[ -n "${dataset}" ]] || { print -u2 "Invalid SQL-017 dataset."; exit 1; }
dataset="$(printf '%s' "${dataset}" | sed 's/|$//')"
printf '%s\n' "${dataset}"
