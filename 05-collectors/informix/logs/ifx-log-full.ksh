#!/usr/bin/env ksh
# ============================================================================== 
# Script  : ifx-log-full.ksh
# Purpose : Count Informix logical logs whose used space reaches their size.
# ============================================================================== 

IFX_LOG_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_LOG_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_LOG_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-logs"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_LOG_005_STATEMENT_FILE="${IFX_LOG_005_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-LOG-005-Logical-Logs-Full.sql}"

typeset dataset
typeset logical_logs_full

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_LOG_005_STATEMENT_FILE}" ]]; then
    fail "LOG-005 statement file not found: ${IFX_LOG_005_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_LOG_005_STATEMENT_FILE}")" || {
    fail "Unable to collect LOG-005 full logical logs."
}

case "${dataset}" in
    *'|') logical_logs_full="${dataset%"|"}" ;;
    *) fail "Invalid LOG-005 logical logs dataset." ;;
esac

case "${logical_logs_full}" in
    ''|*[!0-9]*)
        fail "Invalid LOG-005 logical logs value."
        ;;
esac

print -r -- "${logical_logs_full}"
exit 0
