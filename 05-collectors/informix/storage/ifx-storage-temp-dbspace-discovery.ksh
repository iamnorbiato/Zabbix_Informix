#!/bin/ksh
. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1
IFX_STORAGE_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_STORAGE_DIR}/../../.." && pwd)"
dataset="$(ifx_db_execute sysmaster "${IFX_REPOSITORY_DIR}/01-statements/informix-storage/IFX-STORAGE-011-Temporary-Dbspace-Utilization.sql")" || exit 1
printf '%s\n' "${dataset}" | awk -F '|' '
BEGIN { printf "{\"data\":["; first=1 }
NF == 4 && $1 != "" {
    gsub(/\\/, "\\\\", $1); gsub(/"/, "\\\"", $1)
    if (!first) printf ","
    printf "{\"{#IFX_TEMP_DBSPACE}\":\"%s\"}", $1
    first=0
}
END { print "]}" }
'
