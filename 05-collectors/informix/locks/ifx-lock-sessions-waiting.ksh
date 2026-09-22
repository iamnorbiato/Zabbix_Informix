#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-22
# Script  : ifx-lock-sessions-waiting.ksh
# Purpose : Collect qualifying Informix client sessions currently waiting for
#           locks through sysmaster:syslocks and sysmaster:syssessions.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial mock parser.
# Date    : 2026-09-22
# Author  : Norba
# Change  : Replace mock parsing with remote SQL collection through syslocks.
# ==============================================================================

IFX_LOCKS_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_LOCKS_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_LOCKS_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-locks"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_LOCK_001_STATEMENT_FILE="${IFX_LOCK_001_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-LOCK-001-Sessions-Waiting-for-Locks.sql}"

typeset dataset
typeset sessions_waiting_for_locks

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_LOCK_001_STATEMENT_FILE}" ]]; then
    fail "LOCK-001 statement file not found: ${IFX_LOCK_001_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_LOCK_001_STATEMENT_FILE}")" || {
    fail "Unable to collect LOCK-001 sessions waiting for locks."
}

case "${dataset}" in
    *'|')
        sessions_waiting_for_locks="${dataset%"|"}"
        ;;
    *)
        fail "Invalid LOCK-001 sessions waiting for locks dataset."
        ;;
esac

case "${sessions_waiting_for_locks}" in
    ''|*[!0-9]*)
        fail "Invalid LOCK-001 sessions waiting for locks value."
        ;;
esac

print -r -- "${sessions_waiting_for_locks}"

exit 0