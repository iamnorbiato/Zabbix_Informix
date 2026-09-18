#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : ifx-health-assert-failures.ksh
# Purpose : Collect new Informix assertion-failure events through sysadmin:
#           ph_alert using persistent incremental state.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial version.
# Date    : 2026-09-17
# Author  : Norba
# Change  : Replace deprecated online.log collection with remote sysadmin:
#           ph_alert incremental collection.
# Date    : 2026-09-17
# Author  : Norba
# Change  : Allow controlled statement-file overrides for collector validation.
# ==============================================================================

IFX_HEALTH_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_INFORMIX_DIR="$(cd "${IFX_HEALTH_DIR}/.." && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_HEALTH_DIR}/../../.." && pwd)"
IFX_STATEMENTS_DIR="${IFX_REPOSITORY_DIR}/01-statements/informix-health"

. "${IFX_INFORMIX_DIR}/lib/informix-db.ksh" || exit 1

IFX_HEALTH_003_STATEMENT_FILE="${IFX_HEALTH_003_STATEMENT_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-003-Assert-Failures.sql}"
IFX_HEALTH_003_BASELINE_FILE="${IFX_HEALTH_003_BASELINE_FILE:-${IFX_STATEMENTS_DIR}/IFX-HEALTH-003-Assert-Failures-Baseline.sql}"

typeset state_file
typeset lock_dir
typeset batch_file
typeset last_id
typeset next_last_id
typeset dataset
typeset baseline_output
typeset baseline_id
typeset assertion_count

cleanup()
{
    if [[ -n "${batch_file}" && -f "${batch_file}" ]]; then
        rm -f "${batch_file}"
    fi

    if [[ -n "${lock_dir}" && -d "${lock_dir}" ]]; then
        rmdir "${lock_dir}" 2>/dev/null
    fi
}

fail()
{
    print -u2 "${1}"
    exit 1
}

commit_state()
{
    typeset next_id="$1"
    typeset temporary_state

    temporary_state="$(mktemp "${IFX_STATE_DIR}/.ifx-health-003-state.XXXXXX")" || {
        print -u2 "Unable to create temporary HEALTH-003 state file."
        return 1
    }

    chmod 600 "${temporary_state}" || {
        rm -f "${temporary_state}"
        print -u2 "Unable to protect temporary HEALTH-003 state file."
        return 1
    }

    print -r -- "${next_id}" > "${temporary_state}" || {
        rm -f "${temporary_state}"
        print -u2 "Unable to write temporary HEALTH-003 state file."
        return 1
    }

    mv -f "${temporary_state}" "${state_file}" || {
        rm -f "${temporary_state}"
        print -u2 "Unable to commit HEALTH-003 state file."
        return 1
    }

    return 0
}

read_state()
{
    typeset state_line_count

    if [[ ! -f "${state_file}" || ! -r "${state_file}" ]]; then
        print -u2 "HEALTH-003 state file is not readable: ${state_file}"
        return 1
    fi

    state_line_count="$(wc -l < "${state_file}" | tr -d '[:space:]')" || {
        print -u2 "Unable to inspect HEALTH-003 state file."
        return 1
    }

    if [[ "${state_line_count}" != "1" ]]; then
        print -u2 "Invalid HEALTH-003 state file line count."
        return 1
    fi

    last_id="$(cat "${state_file}")" || {
        print -u2 "Unable to read HEALTH-003 state file."
        return 1
    }

    case "${last_id}" in
        ''|*[!0-9]*)
            print -u2 "Invalid HEALTH-003 last_id state value."
            return 1
            ;;
    esac

    chmod 600 "${state_file}" || {
        print -u2 "Unable to protect HEALTH-003 state file."
        return 1
    }

    return 0
}

parse_baseline()
{
    baseline_output="$1"

    case "${baseline_output}" in
        *'|')
            baseline_id="${baseline_output%"|"}"
            ;;
        *)
            print -u2 "Invalid HEALTH-003 baseline dataset."
            return 1
            ;;
    esac

    case "${baseline_id}" in
        ''|*[!0-9]*)
            print -u2 "Invalid HEALTH-003 baseline value."
            return 1
            ;;
    esac

    return 0
}

append_event()
{
    typeset record="$1"
    typeset remainder
    typeset event_id
    typeset class_id
    typeset event_code
    typeset event_time
    typeset event_message

    case "${record}" in
        *'|'*)
            ;;
        *)
            print -u2 "Invalid HEALTH-003 event dataset record."
            return 1
            ;;
    esac

    event_id="${record%%"|"*}"
    remainder="${record#*"|"}"

    class_id="${remainder%%"|"*}"
    remainder="${remainder#*"|"}"

    event_code="${remainder%%"|"*}"
    remainder="${remainder#*"|"}"

    event_time="${remainder%%"|"*}"
    remainder="${remainder#*"|"}"

    case "${remainder}" in
        *'|')
            event_message="${remainder%"|"}"
            ;;
        *)
            print -u2 "Invalid HEALTH-003 event dataset field count."
            return 1
            ;;
    esac

    case "${event_id}" in
        ''|*[!0-9]*)
            print -u2 "Invalid HEALTH-003 event id."
            return 1
            ;;
    esac

    case "${event_code}" in
        ''|*[!0-9]*)
            print -u2 "Invalid HEALTH-003 event code."
            return 1
            ;;
    esac

    if [[ -z "${class_id}" || -z "${event_time}" || "${event_message}" == *'|'* ]]; then
        print -u2 "Invalid HEALTH-003 event dataset fields."
        return 1
    fi

    if (( event_id <= next_last_id )); then
        print -u2 "HEALTH-003 event dataset is not strictly ordered by id."
        return 1
    fi

    next_last_id="${event_id}"

    if [[ "${class_id}" == "6" &&
          ( "${event_code}" == "6300" || "${event_code}" == "6500" ) ]]; then
        print -r -- "EVENT|${event_id}|${class_id}|${event_code}|${event_time}|${event_message}" >> "${batch_file}" || {
            print -u2 "Unable to write HEALTH-003 event batch."
            return 1
        }

        (( assertion_count += 1 ))
    fi

    return 0
}

emit_batch()
{
    print -r -- "COUNT|${assertion_count}" || return 1

    if (( assertion_count > 0 )); then
        cat "${batch_file}" || return 1
    fi

    return 0
}

if (( $# != 0 )); then
    fail "Usage: $0"
fi

if [[ ! -f "${IFX_HEALTH_003_STATEMENT_FILE}" ]]; then
    fail "HEALTH-003 statement file not found: ${IFX_HEALTH_003_STATEMENT_FILE}"
fi

if [[ ! -f "${IFX_HEALTH_003_BASELINE_FILE}" ]]; then
    fail "HEALTH-003 baseline statement file not found: ${IFX_HEALTH_003_BASELINE_FILE}"
fi

case "${IFX_INFORMIXSERVER}" in
    ''|*[!A-Za-z0-9_.-]*)
        fail "Invalid Informix server name for HEALTH-003 state."
        ;;
esac

if [[ ! -d "${IFX_STATE_DIR}" ]]; then
    mkdir -p "${IFX_STATE_DIR}" || fail "Unable to create Informix state directory."
fi

chmod 700 "${IFX_STATE_DIR}" || fail "Unable to protect Informix state directory."

state_file="${IFX_STATE_DIR}/ifx-health-003.${IFX_INFORMIXSERVER}.last-id"
lock_dir="${state_file}.lock"

if [[ -e "${lock_dir}" ]]; then
    fail "HEALTH-003 collector lock is already held."
fi

mkdir "${lock_dir}" || fail "Unable to acquire HEALTH-003 collector lock."
chmod 700 "${lock_dir}" || {
    rmdir "${lock_dir}" 2>/dev/null
    fail "Unable to protect HEALTH-003 collector lock."
}

trap 'cleanup' EXIT
trap 'cleanup; exit 1' HUP INT TERM

if [[ ! -e "${state_file}" ]]; then
    baseline_output="$(ifx_db_execute sysadmin "${IFX_HEALTH_003_BASELINE_FILE}")" || {
        fail "Unable to establish HEALTH-003 baseline."
    }

    parse_baseline "${baseline_output}" || exit 1

    assertion_count=0
    emit_batch || fail "Unable to emit HEALTH-003 baseline batch."

    commit_state "${baseline_id}" || fail "Unable to persist HEALTH-003 baseline state."

    exit 0
fi

read_state || exit 1

dataset="$(ifx_db_execute sysadmin "${IFX_HEALTH_003_STATEMENT_FILE}" "${last_id}")" || {
    fail "Unable to collect HEALTH-003 event dataset."
}

assertion_count=0
next_last_id="${last_id}"

if [[ -n "${dataset}" ]]; then
    batch_file="$(mktemp "${IFX_STATE_DIR}/.ifx-health-003-batch.XXXXXX")" || {
        fail "Unable to create temporary HEALTH-003 event batch."
    }

    chmod 600 "${batch_file}" || fail "Unable to protect temporary HEALTH-003 event batch."

    while IFS= read -r record || [[ -n "${record}" ]]; do
        append_event "${record}" || exit 1
    done <<EOF
${dataset}
EOF
fi

emit_batch || fail "Unable to emit HEALTH-003 event batch."

if (( next_last_id > last_id )); then
    commit_state "${next_last_id}" || fail "Unable to persist HEALTH-003 state."
fi

exit 0
