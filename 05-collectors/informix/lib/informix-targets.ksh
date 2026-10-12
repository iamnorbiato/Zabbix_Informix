#!/usr/bin/env ksh
# ==============================================================================
# Informix target resolution library
#
# sqlhosts is the technical source of connection endpoints. Optional aliases
# are resolved through IFX_TARGET_ALIASES_FILE. Credentials remain outside Git.
# ==============================================================================

IFX_TARGET_ALIASES_FILE="${IFX_TARGET_ALIASES_FILE:-${IFX_CONFIG_DIR}/target-aliases}"
IFX_TARGET_CONNECT_DIR="${IFX_TARGET_CONNECT_DIR:-${IFX_CONFIG_DIR}/targets}"
IFX_TARGET_CATALOG_FILE="${IFX_TARGET_CATALOG_FILE:-${IFX_TARGET_CONNECT_DIR}/catalog}"
IFX_TARGET_REQUIRE_CATALOG="${IFX_TARGET_REQUIRE_CATALOG:-NO}"

ifx_target_fail()
{
    print -u2 "Informix target error: $1"
    return 1
}

ifx_target_sqlhosts_has_server()
{
    typeset server="$1"

    [[ -n "${server}" ]] || return 1
    [[ -r "${IFX_INFORMIXSQLHOSTS}" ]] || return 1

    awk -v wanted="${server}" '
        /^[[:space:]]*#/ { next }
        NF >= 4 && $1 == wanted { found = 1; exit }
        END { exit(found ? 0 : 1) }
    ' "${IFX_INFORMIXSQLHOSTS}"
}

ifx_target_resolve_alias()
{
    typeset requested="$1"

    IFX_TARGET_SERVER="${requested}"
    IFX_TARGET_ALIAS="${requested}"

    typeset resolved
    resolved=""

    if [[ -r "${IFX_TARGET_ALIASES_FILE}" ]]; then
        resolved="$(awk -F'|' -v wanted="${requested}" '
            /^[[:space:]]*#/ { next }
            NF >= 2 && $1 == wanted { print $2; exit }
            NF >= 2 && $2 == wanted { print $1; exit }
        ' "${IFX_TARGET_ALIASES_FILE}")"
    fi

    if [[ -z "${resolved}" && -r "${IFX_TARGET_CATALOG_FILE}" ]]; then
        resolved="$(awk -F'|' -v wanted="${requested}" '
            /^[[:space:]]*#/ { next }
            NF >= 2 && $1 == wanted { print $2; exit }
            NF >= 2 && $2 == wanted { print $1; exit }
        ' "${IFX_TARGET_CATALOG_FILE}")"
    fi

    if [[ -n "${resolved}" ]]; then
        ifx_target_sqlhosts_has_server "${requested}" >/dev/null 2>&1 || {
            IFX_TARGET_SERVER="${resolved}"
        }
        IFX_TARGET_ALIAS="${requested}"
    fi
}

ifx_target_catalog_has_server()
{
    typeset requested="$1"
    typeset server="$2"

    [[ -r "${IFX_TARGET_CATALOG_FILE}" ]] || return 1

    awk -F '|' -v wanted_alias="${requested}" -v wanted_server="${server}" '
        /^[[:space:]]*#/ { next }
        NF >= 2 && (($1 == wanted_alias && $2 == wanted_server) || $2 == wanted_server) { found = 1; exit }
        END { exit(found ? 0 : 1) }
    ' "${IFX_TARGET_CATALOG_FILE}"
}

ifx_target_load()
{
    typeset requested="$1"

    [[ -n "${requested}" ]] || {
        ifx_target_fail "Usage: ifx_target_load <informixserver-or-alias>"
        return 1
    }

    [[ -r "${IFX_INFORMIXSQLHOSTS}" ]] || {
        ifx_target_fail "sqlhosts file not readable: ${IFX_INFORMIXSQLHOSTS}"
        return 1
    }

    ifx_target_resolve_alias "${requested}" || return 1

    if [[ "${IFX_TARGET_REQUIRE_CATALOG}" == "YES" ]]; then
        ifx_target_catalog_has_server "${requested}" "${IFX_TARGET_SERVER}" || {
            ifx_target_fail "target is not registered in catalog: ${requested}"
            return 1
        }
    fi

    ifx_target_sqlhosts_has_server "${IFX_TARGET_SERVER}" || {
        ifx_target_fail "INFORMIXSERVER not found in sqlhosts: ${IFX_TARGET_SERVER}"
        return 1
    }

    typeset connect_file="${IFX_TARGET_CONNECT_DIR}/${IFX_TARGET_SERVER}/informix-connect.sql"
    [[ -r "${connect_file}" ]] || {
        ifx_target_fail "connection file not readable for ${IFX_TARGET_SERVER}: ${connect_file}"
        return 1
    }

    IFX_TARGET_REQUESTED="${requested}"
    IFX_INFORMIXSERVER="${IFX_TARGET_SERVER}"
    IFX_CONNECT_FILE="${connect_file}"

    export IFX_TARGET_REQUESTED IFX_TARGET_ALIAS IFX_TARGET_SERVER
    export IFX_INFORMIXSERVER IFX_CONNECT_FILE
    return 0
}
