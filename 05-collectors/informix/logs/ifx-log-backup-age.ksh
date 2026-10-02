#!/usr/bin/env ksh
# Collect Level-0 backup age for one database/dbspace association.

IFX_LOG_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_LOG_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_LOG_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-logs"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_LOG_006_STATEMENT_FILE="${IFX_LOG_006_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-LOG-006-Backup-Inventory.sql}"

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 2 )); then
    fail "Usage: $0 <database> <dbspace>"
fi

database_name="${1}"
dbspace_name="${2}"

[[ -f "${IFX_LOG_006_STATEMENT_FILE}" ]] || fail "LOG-006 statement file not found: ${IFX_LOG_006_STATEMENT_FILE}"

dataset="$(ifx_db_execute sysmaster "${IFX_LOG_006_STATEMENT_FILE}")" || {
    fail "Unable to collect LOG-006 backup age."
}

age="$(print -r -- "${dataset}" | awk -F '|' -v database="${database_name}" -v dbspace="${dbspace_name}" '
    NF == 8 && $8 == "" && $1 == database && $2 == dbspace {print $3; found++}
    END {if (found != 1) exit 1}
')" || fail "LOG-006 database/dbspace association not found or not unique."

case "${age}" in
    -1|-1.0) print -r -- "-1" ;;
    ''|*[!0-9.]*|.*|*.*.*) fail "Invalid LOG-006 backup age value." ;;
    *) print -r -- "${age}" ;;
esac

exit 0
