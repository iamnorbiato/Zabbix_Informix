#!/usr/bin/env ksh
# Discover non-system, non-temporary database/dbspace backup associations.

IFX_LOG_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_LOG_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_LOG_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-logs"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_LOG_006_STATEMENT_FILE="${IFX_LOG_006_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-LOG-006-Backup-Inventory.sql}"

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

[[ -f "${IFX_LOG_006_STATEMENT_FILE}" ]] || fail "LOG-006 statement file not found: ${IFX_LOG_006_STATEMENT_FILE}"

dataset="$(ifx_db_execute sysmaster "${IFX_LOG_006_STATEMENT_FILE}")" || {
    fail "Unable to collect LOG-006 backup inventory."
}

print -r -- "${dataset}" |
awk -F '|' '
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
    if (NF == 1 && $1 == "") {
        next
    }

    if (NF != 8 || $1 == "" || $2 == "" || $3 == "" || $7 == "" || $8 != "") {
        invalid = 1
        next
    }

    if ($1 ~ /[{}"\\]/ || $2 ~ /[{}"\\]/ || $7 ~ /[{}"\\]/ || $8 ~ /[{}"\\]/) {
        invalid = 1
        next
    }

    if (emitted++) {
        printf ","
    }

    printf "{\"{#IFX_DATABASE}\":\"%s\",\"{#IFX_DBSPACE}\":\"%s\",\"{#IFX_BACKUP_DESTINATION}\":\"%s\"}",
        json_escape($1), json_escape($2), json_escape($7)
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
    fail "Invalid LOG-006 backup inventory dataset."
fi

exit 0
