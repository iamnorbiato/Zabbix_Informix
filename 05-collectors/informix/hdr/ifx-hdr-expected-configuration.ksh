#!/usr/bin/env ksh
# Report expected-HDR compliance from fresh sysmaster data and explicit policy.
# Connected-HDR mappings remain UNKNOWN until validated on a real HDR pair.

IFX_HDR_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HDR_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HDR_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-hdr"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HDR_001_STATEMENT_FILE="${IFX_HDR_001_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HDR-001-Local-Role-and-State.sql}"
IFX_HDR_003_STATEMENT_FILE="${IFX_HDR_003_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HDR-003-Cluster-Rows.sql}"

typeset local_dataset
typeset cluster_dataset

fail()
{
    print -u2 "${1}"
    exit 1
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

case "${IFX_HDR_REQUIRED:-}:${IFX_HDR_ALERT_ON_DISCONNECT:-}" in
    NO:NO|YES:YES)
        ;;
    *)
        fail "Invalid HDR policy: required/alert settings must be NO/NO or YES/YES."
        ;;
esac

case "${IFX_HDR_REQUIRED}" in
    YES)
        case "${IFX_HDR_EXPECTED_PEER:-}" in
            ''|*[!A-Za-z0-9_.-]*)
                fail "Invalid HDR policy: expected peer must be a nonempty Informix server name."
                ;;
        esac
        ;;
    NO)
        [[ -z "${IFX_HDR_EXPECTED_PEER:-}" ]] || fail "Invalid HDR policy: expected peer must be empty when HDR is not required."
        ;;
esac

[[ -f "${IFX_HDR_001_STATEMENT_FILE}" ]] || fail "HDR-001 statement file not found: ${IFX_HDR_001_STATEMENT_FILE}"
[[ -f "${IFX_HDR_003_STATEMENT_FILE}" ]] || fail "HDR-003 statement file not found: ${IFX_HDR_003_STATEMENT_FILE}"

local_dataset="$(ifx_db_execute sysmaster "${IFX_HDR_001_STATEMENT_FILE}")" || fail "Unable to collect HDR local DRI state."
cluster_dataset="$(ifx_db_execute sysmaster "${IFX_HDR_003_STATEMENT_FILE}")" || fail "Unable to collect HDR cluster rows."

# These exact rows were observed on the standalone development instance.
# Do not infer connected-HDR health or peer identity from unvalidated rows.
if [[ "${local_dataset}" == 'Not Initialized|Off||' &&
      "${cluster_dataset}" == "${IFX_INFORMIXSERVER}|P|PRIMARY|Active||" ]]; then
    if [[ "${IFX_HDR_REQUIRED}" == NO ]]; then
        print 0
    else
        print 2
    fi
    exit 0
fi

print 3
exit 0
