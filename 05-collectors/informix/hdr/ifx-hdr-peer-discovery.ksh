#!/usr/bin/env ksh
# Discover remote HDR peers from sysmaster:syscluster.
# The local Informix server row is excluded explicitly.

IFX_HDR_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HDR_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HDR_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-hdr"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HDR_003_STATEMENT_FILE="${IFX_HDR_003_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HDR-003-Cluster-Rows.sql}"

typeset dataset
typeset local_server

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

[[ -n "${IFX_INFORMIXSERVER}" ]] || fail "INFORMIXSERVER is not configured."
[[ -f "${IFX_HDR_003_STATEMENT_FILE}" ]] || fail "HDR-003 statement file not found: ${IFX_HDR_003_STATEMENT_FILE}"

local_server="${IFX_INFORMIXSERVER}"
dataset="$(ifx_db_execute sysmaster "${IFX_HDR_003_STATEMENT_FILE}")" || {
    fail "Unable to collect HDR-003 cluster rows."
}

print -r -- "${dataset}" |
awk -F '|' -v local_server="${local_server}" '
function json_escape(value) {
    gsub(/\\/, "\\\\", value)
    gsub(/"/, "\\\"", value)
    return value
}

BEGIN {
    printf "{\"data\":["
    emitted = 0
}

{
    if (NF == 0) {
        next
    }

    if (NF != 6 || $1 == "" || $2 == "" || $3 == "" || $4 == "" ||
        $6 != "" ||
        $1 ~ /\\/ || $2 ~ /\\/ || $3 ~ /\\/ || $4 ~ /\\/ ||
        $5 ~ /\\/) {
        invalid = 1
        next
    }

    if ($1 == local_server || toupper($3) != "HDR") {
        next
    }

    if (emitted++) {
        printf ","
    }

    printf "{\"{#IFX_HDR_PEER}\":\"%s\",\"{#IFX_HDR_ROLE}\":\"%s\",\"{#IFX_HDR_NODE_TYPE}\":\"%s\",\"{#IFX_HDR_SERVER_STATE}\":\"%s\",\"{#IFX_HDR_CONNECTION_STATE}\":\"%s\"}",
        json_escape($1), json_escape($2), json_escape($3), json_escape($4), json_escape($5)
}

END {
    printf "]}\n"
    if (invalid) {
        exit 1
    }
}
'
rc=$?

if (( rc != 0 )); then
    fail "Invalid HDR-003 cluster dataset."
fi

exit 0
