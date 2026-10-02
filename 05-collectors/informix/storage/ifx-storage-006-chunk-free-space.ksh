#!/bin/ksh
. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1
IFX_STORAGE_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_STORAGE_DIR}/../../.." && pwd)"
dataset="$(ifx_db_execute sysmaster "${IFX_REPOSITORY_DIR}/01-statements/informix-storage/IFX-STORAGE-006-Chunk-Free-Space.sql")" || exit 1
printf '%s\n' "${dataset}" | awk -F '|' 'NF == 5 && $1 != "" { print; ok=1 } END { if (!ok) exit 1 }' || { print -u2 "Invalid STORAGE-006 dataset."; exit 1; }
