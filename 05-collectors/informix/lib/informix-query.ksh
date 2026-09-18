#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : informix-query.ksh
# Purpose : Provide remote Informix SQL execution functions for collectors.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# Date    : 2026-09-15
# Author  : Norba
# Change  : Add native UNLOAD result handling for collector statements.
# Date    : 2026-09-17
# Author  : Norba
# Change  : Add controlled LAST_ID rendering and protected temporary statement handling.
# ==============================================================================

ifx_db_render_last_id()
{
    typeset statement_file="$1"
    typeset last_id="$2"

    if [[ -z "${statement_file}" || -z "${last_id}" ]]; then
        print -u2 "Usage: ifx_db_render_last_id <statement-file> <last-id>"
        return 1
    fi

    if [[ ! -f "${statement_file}" ]]; then
        print -u2 "Informix statement file not found: ${statement_file}"
        return 1
    fi

    case "${last_id}" in
        *[!0-9]*)
            print -u2 "Invalid Informix LAST_ID value: ${last_id}"
            return 1
            ;;
    esac

    sed "s/{{LAST_ID}}/${last_id}/g" "${statement_file}"
}

ifx_db_execute()
{
    typeset database="$1"
    typeset statement_file="$2"
    typeset last_id="$3"
    typeset rendered_statement_file
    typeset batch_file
    typeset result_file
    typeset unload_statement
    typeset delimiter_statement
    typeset rc

    if [[ -z "${database}" || -z "${statement_file}" ]]; then
        print -u2 "Usage: ifx_db_execute <database> <statement-file> [last-id]"
        return 1
    fi

    if [[ ! -f "${statement_file}" ]]; then
        print -u2 "Informix statement file not found: ${statement_file}"
        return 1
    fi

    ifx_db_init || return 1

    batch_file="$(mktemp "${IFX_CONFIG_DIR}/informix-batch.XXXXXX.sql")" || {
        print -u2 "Unable to create protected Informix batch file."
        return 1
    }

    result_file="$(mktemp "${IFX_CONFIG_DIR}/informix-result.XXXXXX.unl")" || {
        rm -f "${batch_file}"
        print -u2 "Unable to create protected Informix result file."
        return 1
    }

    rendered_statement_file="$(mktemp "${IFX_CONFIG_DIR}/informix-statement.XXXXXX.sql")" || {
        rm -f "${batch_file}" "${result_file}"
        print -u2 "Unable to create protected Informix statement file."
        return 1
    }

    chmod 600 "${batch_file}" "${result_file}" "${rendered_statement_file}" || {
        rm -f "${batch_file}" "${result_file}" "${rendered_statement_file}"
        print -u2 "Unable to protect Informix temporary files."
        return 1
    }

    trap 'rm -f "${batch_file}" "${result_file}" "${rendered_statement_file}"' EXIT HUP INT TERM

    if [[ -n "${last_id}" ]]; then
        ifx_db_render_last_id "${statement_file}" "${last_id}" > "${rendered_statement_file}" || {
            rm -f "${batch_file}" "${result_file}" "${rendered_statement_file}"
            trap - EXIT HUP INT TERM
            return 1
        }
    else
        cat "${statement_file}" > "${rendered_statement_file}" || {
            rm -f "${batch_file}" "${result_file}" "${rendered_statement_file}"
            trap - EXIT HUP INT TERM
            return 1
        }
    fi

    if grep -q '{{' "${rendered_statement_file}"; then
        rm -f "${batch_file}" "${result_file}" "${rendered_statement_file}"
        trap - EXIT HUP INT TERM
        print -u2 "Unresolved Informix SQL placeholder."
        return 1
    fi

    unload_statement="UNLOAD TO '${result_file}'"
    delimiter_statement="DELIMITER '|'"

    {
        cat "${IFX_CONNECT_FILE}"
        print
        print "DATABASE ${database};"
        print "SET ISOLATION TO DIRTY READ;"
        print
        print "${unload_statement}"
        print "${delimiter_statement}"
        cat "${rendered_statement_file}"
        print
        print "DISCONNECT CURRENT;"
    } > "${batch_file}"

    dbaccess -a - "${batch_file}" >/dev/null
    rc=$?

    if (( rc == 0 )); then
        cat "${result_file}"
    fi

    rm -f "${batch_file}" "${result_file}" "${rendered_statement_file}"
    trap - EXIT HUP INT TERM

    return ${rc}
}
