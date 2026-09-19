#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : ifx-health-checkpoint-count.ksh
# Purpose : Collect IBM Informix cumulative checkpoint count through
#           sysmaster:sysshmhdr.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial onstat-based mock parser.
# Date    : 2026-09-18
# Author  : Norba
# Change  : Replace the mock parser with remote SQL collection using
#           pf_numckpts.
# ==============================================================================

IFX_HEALTH_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HEALTH_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HEALTH_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-health"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HEALTH_004_STATEMENT_FILE="${IFX_HEALTH_004_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-004-Checkpoint-Count.sql}"

typeset dataset
typeset checkpoint_count

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_HEALTH_004_STATEMENT_FILE}" ]]; then
    fail "HEALTH-004 statement file not found: ${IFX_HEALTH_004_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_HEALTH_004_STATEMENT_FILE}")" || {
    fail "Unable to collect HEALTH-004 checkpoint count."
}

case "${dataset}" in
    *'|')
        checkpoint_count="${dataset%"|"}"
        ;;
    *)
        fail "Invalid HEALTH-004 checkpoint count dataset."
        ;;
esac

case "${checkpoint_count}" in
    ''|*[!0-9]*)
        fail "Invalid HEALTH-004 checkpoint count value."
        ;;
esac

print -r -- "${checkpoint_count}"

exit 0