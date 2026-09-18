#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-18
# Script  : ifx-health-uptime.ksh
# Purpose : Collect IBM Informix instance uptime in seconds through
#           sysmaster:sysshmhdr.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial onstat-based mock parser.
# Date    : 2026-09-18
# Author  : Norba
# Change  : Replace the onstat parser with remote SQL collection using bttime.
# ==============================================================================

IFX_HEALTH_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HEALTH_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HEALTH_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-health"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HEALTH_002_STATEMENT_FILE="${IFX_HEALTH_002_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-002-Instance-Uptime.sql}"

typeset dataset
typeset uptime_seconds

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_HEALTH_002_STATEMENT_FILE}" ]]; then
    fail "HEALTH-002 statement file not found: ${IFX_HEALTH_002_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_HEALTH_002_STATEMENT_FILE}")" || {
    fail "Unable to collect HEALTH-002 instance uptime."
}

case "${dataset}" in
    *'|')
        uptime_seconds="${dataset%"|"}"
        ;;
    *)
        fail "Invalid HEALTH-002 uptime dataset."
        ;;
esac

case "${uptime_seconds}" in
    ''|*[!0-9]*)
        fail "Invalid HEALTH-002 uptime value."
        ;;
esac

print -r -- "${uptime_seconds}"

exit 0