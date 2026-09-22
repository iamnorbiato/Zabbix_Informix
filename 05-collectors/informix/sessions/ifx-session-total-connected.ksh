#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-20
# Script  : ifx-session-total-connected.ksh
# Purpose : Collect current Informix client sessions through sysmaster:syssessions,
#           excluding observed internal service sessions and the collector itself.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial mock parser.
# Date    : 2026-09-20
# Author  : Norba
# Change  : Replace mock parsing with remote SQL collection through syssessions.
# ==============================================================================

IFX_SESSIONS_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_SESSIONS_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SESSIONS_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-sessions"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_SESSION_001_STATEMENT_FILE="${IFX_SESSION_001_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-SESSION-001-Total-Connected-Sessions.sql}"

typeset dataset
typeset total_connected_sessions

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_SESSION_001_STATEMENT_FILE}" ]]; then
    fail "SESSION-001 statement file not found: ${IFX_SESSION_001_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_SESSION_001_STATEMENT_FILE}")" || {
    fail "Unable to collect SESSION-001 total connected sessions."
}

case "${dataset}" in
    *'|')
        total_connected_sessions="${dataset%"|"}"
        ;;
    *)
        fail "Invalid SESSION-001 total connected sessions dataset."
        ;;
esac

case "${total_connected_sessions}" in
    ''|*[!0-9]*)
        fail "Invalid SESSION-001 total connected sessions value."
        ;;
esac

print -r -- "${total_connected_sessions}"

exit 0