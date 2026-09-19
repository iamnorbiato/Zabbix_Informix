#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : ifx-health-checkpoint-waits.ksh
# Purpose : Collect IBM Informix cumulative checkpoint wait count through
#           sysmaster:sysshmhdr.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial onstat-based mock parser.
# Date    : 2026-09-18
# Author  : Norba
# Change  : Replace the mock parser with remote SQL collection using
#           pf_ckptwts.
# ==============================================================================

IFX_HEALTH_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HEALTH_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HEALTH_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-health"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HEALTH_006_STATEMENT_FILE="${IFX_HEALTH_006_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-006-Checkpoint-Waits.sql}"

typeset dataset
typeset checkpoint_wait_count

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_HEALTH_006_STATEMENT_FILE}" ]]; then
    fail "HEALTH-006 statement file not found: ${IFX_HEALTH_006_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_HEALTH_006_STATEMENT_FILE}")" || {
    fail "Unable to collect HEALTH-006 checkpoint waits."
}

case "${dataset}" in
    *'|')
        checkpoint_wait_count="${dataset%"|"}"
        ;;
    *)
        fail "Invalid HEALTH-006 checkpoint waits dataset."
        ;;
esac

case "${checkpoint_wait_count}" in
    ''|*[!0-9]*)
        fail "Invalid HEALTH-006 checkpoint waits value."
        ;;
esac

print -r -- "${checkpoint_wait_count}"

exit 0