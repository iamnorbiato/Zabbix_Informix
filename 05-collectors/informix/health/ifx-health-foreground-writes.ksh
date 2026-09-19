#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : ifx-health-foreground-writes.ksh
# Purpose : Collect IBM Informix cumulative foreground write count through
#           sysmaster:sysprofile.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial onstat-based mock parser.
# Date    : 2026-09-19
# Author  : Norba
# Change  : Replace the mock parser with remote SQL collection using
#           sysprofile.fgwrites.
# ==============================================================================

IFX_HEALTH_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HEALTH_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HEALTH_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-health"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HEALTH_008_STATEMENT_FILE="${IFX_HEALTH_008_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-008-Foreground-Writes.sql}"

typeset dataset
typeset foreground_write_count

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_HEALTH_008_STATEMENT_FILE}" ]]; then
    fail "HEALTH-008 statement file not found: ${IFX_HEALTH_008_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_HEALTH_008_STATEMENT_FILE}")" || {
    fail "Unable to collect HEALTH-008 foreground writes."
}

case "${dataset}" in
    *'|')
        foreground_write_count="${dataset%"|"}"
        ;;
    *)
        fail "Invalid HEALTH-008 foreground writes dataset."
        ;;
esac

case "${foreground_write_count}" in
    ''|*[!0-9]*)
        fail "Invalid HEALTH-008 foreground writes value."
        ;;
esac

print -r -- "${foreground_write_count}"

exit 0