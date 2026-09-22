#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-21
# Script  : ifx-session-waiting-total.ksh
# Purpose : Collect the current number of Informix client sessions with one or
#           more documented syssessions waiting flags set.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial mock parser for waiting threads.
# Date    : 2026-09-21
# Author  : Norba
# Change  : Replace mock parsing with remote SQL collection of waiting client
#           sessions through sysmaster:syssessions.
# ==============================================================================

IFX_SESSIONS_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_SESSIONS_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SESSIONS_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-sessions"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_SESSION_004_STATEMENT_FILE="${IFX_SESSION_004_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-SESSION-004-Waiting-Client-Sessions-Total.sql}"

typeset dataset
typeset waiting_client_sessions

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_SESSION_004_STATEMENT_FILE}" ]]; then
    fail "SESSION-004 statement file not found: ${IFX_SESSION_004_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_SESSION_004_STATEMENT_FILE}")" || {
    fail "Unable to collect SESSION-004 waiting client sessions."
}

case "${dataset}" in
    *'|')
        waiting_client_sessions="${dataset%"|"}"
        ;;
    *)
        fail "Invalid SESSION-004 waiting client sessions dataset."
        ;;
esac

case "${waiting_client_sessions}" in
    ''|*[!0-9]*)
        fail "Invalid SESSION-004 waiting client sessions value."
        ;;
esac

print -r -- "${waiting_client_sessions}"

exit 0