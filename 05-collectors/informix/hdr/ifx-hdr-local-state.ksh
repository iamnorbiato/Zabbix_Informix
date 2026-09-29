#!/usr/bin/env ksh
# Collect the local Informix DRI/HDR role, state, and configured partner from sysmaster.
# This collector reports source values; it does not declare HDR healthy or failed.

IFX_HDR_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HDR_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HDR_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-hdr"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HDR_001_STATEMENT_FILE="${IFX_HDR_001_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HDR-001-Local-Role-and-State.sql}"

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

if [[ ! -f "${IFX_HDR_001_STATEMENT_FILE}" ]]; then
    fail "HDR-001 statement file not found: ${IFX_HDR_001_STATEMENT_FILE}"
fi

dataset="$(ifx_db_execute sysmaster "${IFX_HDR_001_STATEMENT_FILE}")" || {
    fail "Unable to collect HDR-001 local role and state."
}

normalized_dataset="$(
    print -r -- "${dataset}" |
    awk -F '|' '
    {
        row_count++

        if (NF != 4 || $1 == "" || $2 == "" || $4 != "" ||
            $1 ~ /\\/ || $2 ~ /\\/ || $3 ~ /\\/) {
            invalid = 1
            next
        }

        role = $1
        state = $2
        peer = $3
    }

    END {
        if (invalid || row_count != 1) {
            exit 1
        }

        print role "|" state "|" peer
    }
    '
)" || {
    fail "Invalid HDR-001 local role and state dataset."
}

print -r -- "${normalized_dataset}"

exit 0
