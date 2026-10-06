#!/bin/ksh
. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1

IFX_SQL_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SQL_DIR}/../../.." && pwd)"
statement="${IFX_REPOSITORY_DIR}/01-statements/informix-sql/IFX-SQL-015-Top-Estimated-Rows.sql"
[[ -r "${statement}" ]] || { print -u2 "Informix statement file not found: ${statement}"; exit 1; }

dataset="$(ifx_db_execute sysmaster "${statement}")" || exit 1
[[ -n "${dataset}" ]] || { print -u2 "Invalid SQL-015 dataset."; exit 1; }
printf '%s\n' "${dataset}"
