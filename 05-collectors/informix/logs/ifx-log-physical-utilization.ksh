#!/usr/bin/env ksh
# ============================================================================== 
# Script  : ifx-log-physical-utilization.ksh
# Purpose : Collect the percentage used by the Informix physical log.
# ============================================================================== 

IFX_LOG_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_LOG_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_LOG_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-logs"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_LOG_004_STATEMENT_FILE="${IFX_LOG_004_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-LOG-004-Physical-Utilization.sql}"

typeset dataset
typeset utilization

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_LOG_004_STATEMENT_FILE}" ]]; then
    fail "LOG-004 statement file not found: ${IFX_LOG_004_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_LOG_004_STATEMENT_FILE}")" || {
    fail "Unable to collect LOG-004 physical-log utilization."
}

case "${dataset}" in
    *'|') utilization="${dataset%"|"}" ;;
    *) fail "Invalid LOG-004 physical-log utilization dataset." ;;
esac

case "${utilization}" in
    ''|*[!0-9.]*|.*|*.*.*)
        fail "Invalid LOG-004 physical-log utilization value."
        ;;
esac

print -r -- "${utilization}"
exit 0
