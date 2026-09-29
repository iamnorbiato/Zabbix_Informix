#!/usr/bin/env ksh

IFX_HDR_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HDR_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HDR_DIR}/../../.." && pwd)"
IFX_STATEMENT_FILE="${IFX_HDR_003_STATEMENT_FILE:-${IFX_REPOSITORY_DIR}/01-statements/informix-hdr/IFX-HDR-003-Cluster-Rows.sql}"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 2 )); then
    fail "Usage: $0 <connection|server> <peer-name>"
fi

field="$1"
peer="$2"

case "${field}" in
    connection|server)
        ;;
    *)
        fail "Invalid HDR peer field: ${field}"
        ;;
esac

case "${peer}" in
    ''|*[!A-Za-z0-9_.-]*)
        fail "Invalid HDR peer name."
        ;;
esac

[[ -f "${IFX_STATEMENT_FILE}" ]] || fail "HDR peer statement file not found: ${IFX_STATEMENT_FILE}"

dataset="$(ifx_db_execute sysmaster "${IFX_STATEMENT_FILE}")" || fail "Unable to collect HDR peer state."

print -r -- "${dataset}" |
awk -F '|' -v expected_peer="${peer}" -v field="${field}" '
{
    if (NF == 0) {
        next
    }

    if (NF != 6 || $1 == "" || $2 == "" || $3 == "" || $4 == "" ||
        $6 != "" || $1 ~ /\\/ || $2 ~ /\\/ || $3 ~ /\\/ ||
        $4 ~ /\\/ || $5 ~ /\\/) {
        invalid = 1
        next
    }

    if ($1 == expected_peer && toupper($3) == "HDR") {
        match_count++
        value = (field == "connection") ? $5 : $4
    }
}

END {
    if (invalid || match_count != 1) {
        exit 1
    }

    print value
}
'

(( $? == 0 )) || fail "Invalid or missing HDR peer field."
exit 0
