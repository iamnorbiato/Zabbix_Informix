#!/usr/bin/env ksh

IFX_LOCKS_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_LOCKS_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_LOCKS_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-locks"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_LOCK_004_STATEMENT_FILE="${IFX_LOCK_004_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-LOCK-004-Deadlocks.sql}"

typeset dataset
typeset deadlocks

fail()
{
    print -u2 "${1}"
    exit 1
}

target="${1:-}"
if (( $# > 1 )); then
    fail "Usage: $0 [target-alias-or-INFORMIXSERVER]"
fi

if [[ ! -f "${IFX_LOCK_004_STATEMENT_FILE}" ]]; then
    fail "LOCK-004 statement file not found: ${IFX_LOCK_004_STATEMENT_FILE}"
fi

if [[ -n "${target}" ]]; then
    dataset="$(ifx_db_execute_target "${target}" sysmaster "${IFX_LOCK_004_STATEMENT_FILE}")" || {
        fail "Unable to collect LOCK-004 deadlocks."
    }
else
    dataset="$(ifx_db_execute sysmaster "${IFX_LOCK_004_STATEMENT_FILE}")" || {
        fail "Unable to collect LOCK-004 deadlocks."
    }
fi

case "${dataset}" in
    *'|')
        deadlocks="${dataset%"|"}"
        ;;
    *)
        fail "Invalid LOCK-004 deadlocks dataset."
        ;;
esac

case "${deadlocks}" in
    ''|*[!0-9]*)
        fail "Invalid LOCK-004 deadlocks value."
        ;;
esac

print -r -- "${deadlocks}"

exit 0