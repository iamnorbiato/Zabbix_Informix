#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-22
# Script  : ifx-session-weekly-peak-physical-connections.ksh
# Purpose : Collect the latest Informix weekly high-water value for concurrent
#           physical connections through sysmaster:sysfeatures.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial mock parser.
# Date    : 2026-09-22
# Author  : Norba
# Change  : Replace mock parsing with remote SQL collection through sysfeatures.
# ==============================================================================

IFX_SESSIONS_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_SESSIONS_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SESSIONS_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-sessions"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_SESSION_003_STATEMENT_FILE="${IFX_SESSION_003_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-SESSION-003-Weekly-Peak-Concurrent-Physical-Connections.sql}"

typeset dataset
typeset weekly_peak_physical_connections

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_SESSION_003_STATEMENT_FILE}" ]]; then
    fail "SESSION-003 statement file not found: ${IFX_SESSION_003_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_SESSION_003_STATEMENT_FILE}")" || {
    fail "Unable to collect SESSION-003 weekly peak physical connections."
}

case "${dataset}" in
    *'|')
        weekly_peak_physical_connections="${dataset%"|"}"
        ;;
    *)
        fail "Invalid SESSION-003 weekly peak physical connections dataset."
        ;;
esac

case "${weekly_peak_physical_connections}" in
    ''|*[!0-9]*)
        fail "Invalid SESSION-003 weekly peak physical connections value."
        ;;
esac

print -r -- "${weekly_peak_physical_connections}"

exit 0