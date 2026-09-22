#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-21
# Script  : ifx-session-waiting-by-reason.ksh
# Purpose : Collect and strictly normalize the fixed Informix client-session
#           waiting dataset from sysmaster:syssessions.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial mock parser for dynamic waiting threads by reason.
# Date    : 2026-09-21
# Author  : Norba
# Change  : Replace mock parsing with remote SQL collection of fixed waiting
#           client-session dimensions.
# ==============================================================================

IFX_SESSIONS_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_SESSIONS_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SESSIONS_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-sessions"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_SESSION_005_STATEMENT_FILE="${IFX_SESSION_005_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-SESSION-005-Waiting-Client-Sessions-by-Reason.sql}"

typeset dataset
typeset normalized_dataset

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_SESSION_005_STATEMENT_FILE}" ]]; then
    fail "SESSION-005 statement file not found: ${IFX_SESSION_005_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_SESSION_005_STATEMENT_FILE}")" || {
    fail "Unable to collect SESSION-005 waiting client sessions by reason."
}

normalized_dataset="$(
    print -r -- "${dataset}" |
    awk -F '|' '
    function trim(value) {
        gsub(/^[[:space:]]+/, "", value)
        gsub(/[[:space:]]+$/, "", value)
        return value
    }

    BEGIN {
        expected_name["LATCH"] = "Waiting client sessions - latch"
        expected_name["LOCK"] = "Waiting client sessions - lock"
        expected_name["BUFFER"] = "Waiting client sessions - buffer"
        expected_name["CHECKPOINT"] = "Waiting client sessions - checkpoint"
        expected_name["LOG_BUFFER"] = "Waiting client sessions - log buffer"
        expected_name["TRANSACTION"] = "Waiting client sessions - transaction"

        ordered_id[1] = "LATCH"
        ordered_id[2] = "LOCK"
        ordered_id[3] = "BUFFER"
        ordered_id[4] = "CHECKPOINT"
        ordered_id[5] = "LOG_BUFFER"
        ordered_id[6] = "TRANSACTION"
    }

    {
        dimension_id = trim($1)
        dimension_name = trim($2)
        dimension_count = trim($3)
        unload_terminator = trim($4)

        if (NF != 4 ||
            unload_terminator != "" ||
            !(dimension_id in expected_name) ||
            dimension_name != expected_name[dimension_id] ||
            dimension_count !~ /^(0|[1-9][0-9]*)$/ ||
            seen[dimension_id]++) {
            invalid = 1
            next
        }

        value[dimension_id] = dimension_count
        row_count++
    }

    END {
        if (invalid || row_count != 6) {
            exit 1
        }

        for (sequence = 1; sequence <= 6; sequence++) {
            dimension_id = ordered_id[sequence]

            if (!(dimension_id in value)) {
                exit 1
            }

            print dimension_id "|" expected_name[dimension_id] "|" value[dimension_id]
        }
    }
    '
)" || {
    fail "Invalid SESSION-005 waiting client sessions dataset."
}

print -r -- "${normalized_dataset}"

exit 0