#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-22
# Script  : ifx-session-in-read-call.ksh
# Purpose : Collect qualifying Informix client sessions observed in a read call
#           through sysmaster:syssessions.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial mock parser.
# Date    : 2026-09-22
# Author  : Norba
# Change  : Replace mock parsing with remote SQL collection through syssessions.
# ==============================================================================

IFX_SESSIONS_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_SESSIONS_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SESSIONS_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-sessions"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_SESSION_002_STATEMENT_FILE="${IFX_SESSION_002_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-SESSION-002-Sessions-in-Read-Call.sql}"

typeset dataset
typeset sessions_in_read_call

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_SESSION_002_STATEMENT_FILE}" ]]; then
    fail "SESSION-002 statement file not found: ${IFX_SESSION_002_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_SESSION_002_STATEMENT_FILE}")" || {
    fail "Unable to collect SESSION-002 sessions in read call."
}

case "${dataset}" in
    *'|')
        sessions_in_read_call="${dataset%"|"}"
        ;;
    *)
        fail "Invalid SESSION-002 sessions in read call dataset."
        ;;
esac

case "${sessions_in_read_call}" in
    ''|*[!0-9]*)
        fail "Invalid SESSION-002 sessions in read call value."
        ;;
esac

print -r -- "${sessions_in_read_call}"

exit 0