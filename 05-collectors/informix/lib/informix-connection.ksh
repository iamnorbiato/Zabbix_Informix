#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : informix-connection.ksh
# Purpose : Provide Informix remote connection validation functions.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

# ------------------------------------------------------------------------------
# ifx_db_test_connection
#
# Validate non-interactive remote connectivity to the Informix server.
# ------------------------------------------------------------------------------

ifx_db_test_connection()
{
    ifx_db_init || return 1

    dbaccess - "${IFX_CONNECT_FILE}" >/dev/null 2>&1
    return $?
}
