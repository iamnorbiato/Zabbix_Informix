#!/bin/ksh
. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1

target="${1:-}"
if (( $# > 1 )); then
    print -u2 "Usage: $0 [target-alias-or-INFORMIXSERVER]"
    exit 1
fi

IFX_SQL_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SQL_DIR}/../../.." && pwd)"
statement="${IFX_REPOSITORY_DIR}/01-statements/informix-sql/IFX-SQL-014-Top-Estimated-Cost.sql"
[[ -r "${statement}" ]] || { print -u2 "Informix statement file not found: ${statement}"; exit 1; }

if [[ -n "${target}" ]]; then
    dataset="$(ifx_db_execute_target "${target}" sysmaster "${statement}")" || exit 1
else
    dataset="$(ifx_db_execute sysmaster "${statement}")" || exit 1
fi
[[ -n "${dataset}" ]] || { print -u2 "Invalid SQL-014 dataset."; exit 1; }
printf '%s\n' "${dataset}"
