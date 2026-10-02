#!/bin/ksh
. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1
IFX_STORAGE_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_STORAGE_DIR}/../../.." && pwd)"
dataset="$(ifx_db_execute sysmaster "${IFX_REPOSITORY_DIR}/01-statements/informix-storage/IFX-STORAGE-004-Chunk-State.sql")" || exit 1
printf '%s\n' "${dataset}" | awk -F '|' '
BEGIN { printf "{\"data\":["; first=1 }
NF >= 8 && $1 != "" {
    gsub(/\\/, "\\\\", $1); gsub(/"/, "\\\"", $1)
    gsub(/\\/, "\\\\", $2); gsub(/"/, "\\\"", $2)
    gsub(/\\/, "\\\\", $3); gsub(/"/, "\\\"", $3)
    name=tolower($1)
    if (name ~ /^temp/) class="TEMPORARY"
    else if (name == "root_dbs" || name == "rootdbs" || name == "sysadm_dbs" || name == "sysadmin" || name == "catal_dbs") class="SYSTEM"
    else if (name ~ /phys/) class="PHYSICAL_LOG"
    else if (name ~ /log/) class="LOGICAL_LOG"
    else class="APPLICATION"
    if (!first) printf ","
    printf "{\"{#IFX_DBSPACE}\":\"%s\",\"{#IFX_DBSPACE_CLASS}\":\"%s\",\"{#IFX_CHUNK}\":\"%s\",\"{#IFX_CHUNK_PATH}\":\"%s\"}", $1, class, $2, $3
    first=0
}
END { print "]}" }
'
