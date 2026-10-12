#!/usr/bin/env ksh

IFX_LOCKS_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_LOCKS_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_LOCKS_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-locks"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_LOCK_005_STATEMENT_FILE="${IFX_LOCK_005_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-LOCK-005-Lock-Table-Exhaustion.sql}"

typeset dataset
typeset lock_table_exhaustion_attempts

fail()
{
    print -u2 "${1}"
    exit 1
}

target="${1:-}"
if (( $# > 1 )); then
    fail "Usage: $0 [target-alias-or-INFORMIXSERVER]"
fi

if [[ ! -f "${IFX_LOCK_005_STATEMENT_FILE}" ]]; then
    fail "LOCK-005 statement file not found: ${IFX_LOCK_005_STATEMENT_FILE}"
fi

if [[ -n "${target}" ]]; then
    dataset="$(ifx_db_execute_target "${target}" sysmaster "${IFX_LOCK_005_STATEMENT_FILE}")" || {
        fail "Unable to collect LOCK-005 lock table exhaustion attempts."
    }
else
    dataset="$(ifx_db_execute sysmaster "${IFX_LOCK_005_STATEMENT_FILE}")" || {
        fail "Unable to collect LOCK-005 lock table exhaustion attempts."
    }
fi

case "${dataset}" in
    *'|')
        lock_table_exhaustion_attempts="${dataset%"|"}"
        ;;
    *)
        fail "Invalid LOCK-005 lock table exhaustion dataset."
        ;;
esac

case "${lock_table_exhaustion_attempts}" in
    ''|*[!0-9]*)
        fail "Invalid LOCK-005 lock table exhaustion value."
        ;;
esac

print -r -- "${lock_table_exhaustion_attempts}"

exit 0