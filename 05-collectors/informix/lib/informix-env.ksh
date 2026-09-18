#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : informix-env.ksh
# Purpose : Prepare and validate the Informix Client SDK environment.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# Date    : 2026-09-17
# Author  : Norba
# Change  : Add configurable private collector state directory.
# ==============================================================================

# ------------------------------------------------------------------------------
# Default local configuration
# ------------------------------------------------------------------------------

IFX_CONFIG_DIR="${IFX_CONFIG_DIR:-${HOME}/.config/zabbix-tailor}"
IFX_CONNECT_FILE="${IFX_CONNECT_FILE:-${IFX_CONFIG_DIR}/informix-connect.sql}"
IFX_STATE_DIR="${IFX_STATE_DIR:-${IFX_CONFIG_DIR}/state}"

# ------------------------------------------------------------------------------
# Informix Client SDK
# ------------------------------------------------------------------------------

IFX_INFORMIXDIR="${IFX_INFORMIXDIR:-/home/norbiato/informix}"
IFX_INFORMIXSERVER="${IFX_INFORMIXSERVER:-ol_informix1210}"
IFX_INFORMIXSQLHOSTS="${IFX_INFORMIXSQLHOSTS:-${IFX_INFORMIXDIR}/etc/sqlhosts}"

# ------------------------------------------------------------------------------
# ifx_db_init
#
# Prepare the Informix Client SDK environment and validate the private
# connection file.
# ------------------------------------------------------------------------------

ifx_db_init()
{
    if [[ ! -d "${IFX_INFORMIXDIR}" ]]; then
        print -u2 "Informix Client SDK directory not found: ${IFX_INFORMIXDIR}"
        return 1
    fi

    if [[ ! -f "${IFX_INFORMIXSQLHOSTS}" ]]; then
        print -u2 "Informix sqlhosts file not found: ${IFX_INFORMIXSQLHOSTS}"
        return 1
    fi

    if [[ ! -f "${IFX_CONNECT_FILE}" ]]; then
        print -u2 "Informix connection file not found: ${IFX_CONNECT_FILE}"
        return 1
    fi

    export INFORMIXDIR="${IFX_INFORMIXDIR}"
    export INFORMIXSERVER="${IFX_INFORMIXSERVER}"
    export INFORMIXSQLHOSTS="${IFX_INFORMIXSQLHOSTS}"
    export PATH="${INFORMIXDIR}/bin:${PATH}"

    return 0
}
