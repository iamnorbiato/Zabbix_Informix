#!/bin/ksh
. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1
IFX_STORAGE_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_STORAGE_DIR}/../../.." && pwd)"
target="${1:-}"; if (( $# > 1 )); then print -u2 "Usage: $0 [target-alias-or-INFORMIXSERVER]"; exit 1; fi
if [[ -n "${target}" ]]; then dataset="$(ifx_db_execute_target "${target}" sysmaster "${IFX_REPOSITORY_DIR}/01-statements/informix-storage/IFX-STORAGE-001-Dbspace-Utilization.sql")" || exit 1; else dataset="$(ifx_db_execute sysmaster "${IFX_REPOSITORY_DIR}/01-statements/informix-storage/IFX-STORAGE-001-Dbspace-Utilization.sql")" || exit 1; fi
printf '%s\n' "${dataset}" | awk -F '|' '
BEGIN { printf "{\"data\":["; first=1 }
NF >= 7 && $1 != "" {
    gsub(/\\/, "\\\\", $1); gsub(/"/, "\\\"", $1)
    gsub(/\\/, "\\\\", $2); gsub(/"/, "\\\"", $2)
    if (!first) printf ","
    printf "{\"{#IFX_DBSPACE}\":\"%s\",\"{#IFX_DBSPACE_CLASS}\":\"%s\"}", $1, $2
    first=0
}
END { print "]}" }
'
