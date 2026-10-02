#!/usr/bin/env ksh
# ============================================================================== 
# Script  : ifx-log-not-backed-up.ksh
# Purpose : Count Informix logical logs that are not marked as backed up.
# ============================================================================== 

IFX_LOG_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_LOG_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_LOG_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-logs"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_LOG_002_STATEMENT_FILE="${IFX_LOG_002_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-LOG-002-Not-Backed-Up.sql}"

typeset dataset
typeset not_backed_up

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_LOG_002_STATEMENT_FILE}" ]]; then
    fail "LOG-002 statement file not found: ${IFX_LOG_002_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_LOG_002_STATEMENT_FILE}")" || {
    fail "Unable to collect LOG-002 logical logs not backed up."
}

case "${dataset}" in
    *'|') not_backed_up="${dataset%"|"}" ;;
    *) fail "Invalid LOG-002 logical logs dataset." ;;
esac

case "${not_backed_up}" in
    ''|*[!0-9]*)
        fail "Invalid LOG-002 logical logs value."
        ;;
esac

print -r -- "${not_backed_up}"
exit 0
