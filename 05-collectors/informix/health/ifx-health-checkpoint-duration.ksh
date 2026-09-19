#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : ifx-health-checkpoint-duration.ksh
# Purpose : Collect the duration of the most recently completed IBM Informix
#           checkpoint through sysmaster:syscheckpoint.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial onstat-based mock parser.
# Date    : 2026-09-18
# Author  : Norba
# Change  : Replace the mock parser with remote SQL collection using
#           syscheckpoint.cp_time.
# ==============================================================================

IFX_HEALTH_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HEALTH_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HEALTH_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-health"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HEALTH_005_STATEMENT_FILE="${IFX_HEALTH_005_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-005-Checkpoint-Duration.sql}"

typeset dataset
typeset checkpoint_duration_seconds
typeset integer_part
typeset fractional_part

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_HEALTH_005_STATEMENT_FILE}" ]]; then
    fail "HEALTH-005 statement file not found: ${IFX_HEALTH_005_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_HEALTH_005_STATEMENT_FILE}")" || {
    fail "Unable to collect HEALTH-005 checkpoint duration."
}

case "${dataset}" in
    *'|')
        checkpoint_duration_seconds="${dataset%"|"}"
        ;;
    *)
        fail "Invalid HEALTH-005 checkpoint duration dataset."
        ;;
esac

case "${checkpoint_duration_seconds}" in
    '')
        fail "Invalid HEALTH-005 checkpoint duration value."
        ;;
esac

if [[ "${checkpoint_duration_seconds}" == *.* ]]; then
    integer_part="${checkpoint_duration_seconds%%.*}"
    fractional_part="${checkpoint_duration_seconds#*.}"

    case "${integer_part}" in
        ''|*[!0-9]*)
            fail "Invalid HEALTH-005 checkpoint duration value."
            ;;
    esac

    case "${fractional_part}" in
        ''|*[!0-9]*)
            fail "Invalid HEALTH-005 checkpoint duration value."
            ;;
    esac
else
    case "${checkpoint_duration_seconds}" in
        *[!0-9]*)
            fail "Invalid HEALTH-005 checkpoint duration value."
            ;;
    esac
fi

print -r -- "${checkpoint_duration_seconds}"

exit 0