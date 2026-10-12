#!/bin/ksh
. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1
IFX_STORAGE_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_STORAGE_DIR}/../../.." && pwd)"
target="${1:-}"; if (( $# > 1 )); then print -u2 "Usage: $0 [target-alias-or-INFORMIXSERVER]"; exit 1; fi
if [[ -n "${target}" ]]; then dataset="$(ifx_db_execute_target "${target}" sysmaster "${IFX_REPOSITORY_DIR}/01-statements/informix-storage/IFX-STORAGE-005-Chunk-Utilization.sql")" || exit 1; else dataset="$(ifx_db_execute sysmaster "${IFX_REPOSITORY_DIR}/01-statements/informix-storage/IFX-STORAGE-005-Chunk-Utilization.sql")" || exit 1; fi
printf '%s\n' "${dataset}" | awk -F '|' 'NF == 6 && $1 != "" { print; ok=1 } END { if (!ok) exit 1 }' || { print -u2 "Invalid STORAGE-005 dataset."; exit 1; }
