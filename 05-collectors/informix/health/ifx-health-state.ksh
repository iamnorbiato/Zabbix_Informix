#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-18
# Script  : ifx-health-state.ksh
# Purpose : Collect the native IBM Informix instance operational mode through
#           sysmaster:sysshmhdr.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial onstat-based mock parser.
# Date    : 2026-09-18
# Author  : Norba
# Change  : Replace the onstat parser with remote SQL collection from
#           sysmaster:sysshmhdr.
# ==============================================================================

IFX_HEALTH_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HEALTH_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HEALTH_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-health"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HEALTH_001_STATEMENT_FILE="${IFX_HEALTH_001_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-001-Instance-State.sql}"

typeset dataset
typeset state_code

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_HEALTH_001_STATEMENT_FILE}" ]]; then
    fail "HEALTH-001 statement file not found: ${IFX_HEALTH_001_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_HEALTH_001_STATEMENT_FILE}")" || {
    fail "Unable to collect HEALTH-001 instance state."
}

case "${dataset}" in
    *'|')
        state_code="${dataset%"|"}"
        ;;
    *)
        fail "Invalid HEALTH-001 instance state dataset."
        ;;
esac

case "${state_code}" in
    0|1|2|3|4|5|6|7|255)
        print -r -- "${state_code}"
        ;;
    *)
        fail "Invalid HEALTH-001 instance state value."
        ;;
esac

exit 0