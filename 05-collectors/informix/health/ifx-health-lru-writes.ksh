#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : ifx-health-lru-writes.ksh
# Purpose : Collect IBM Informix cumulative LRU write count through
#           sysmaster:sysprofile.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial onstat-based mock parser.
# Date    : 2026-09-18
# Author  : Norba
# Change  : Replace the mock parser with remote SQL collection using
#           sysprofile.lruwrites.
# ==============================================================================

IFX_HEALTH_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HEALTH_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HEALTH_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-health"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HEALTH_007_STATEMENT_FILE="${IFX_HEALTH_007_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-007-LRU-Writes.sql}"

typeset dataset
typeset lru_write_count

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_HEALTH_007_STATEMENT_FILE}" ]]; then
    fail "HEALTH-007 statement file not found: ${IFX_HEALTH_007_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_HEALTH_007_STATEMENT_FILE}")" || {
    fail "Unable to collect HEALTH-007 LRU writes."
}

case "${dataset}" in
    *'|')
        lru_write_count="${dataset%"|"}"
        ;;
    *)
        fail "Invalid HEALTH-007 LRU writes dataset."
        ;;
esac

case "${lru_write_count}" in
    ''|*[!0-9]*)
        fail "Invalid HEALTH-007 LRU writes value."
        ;;
esac

print -r -- "${lru_write_count}"

exit 0