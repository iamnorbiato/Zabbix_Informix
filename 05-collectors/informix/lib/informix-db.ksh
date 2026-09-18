#!/usr/bin/env ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : informix-db.ksh
# Purpose : Provide the main Informix database interface for collectors.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module location
# ------------------------------------------------------------------------------

IFX_DB_LIB_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"

# ------------------------------------------------------------------------------
# Informix database modules
# ------------------------------------------------------------------------------

. "${IFX_DB_LIB_DIR}/informix-env.ksh"
. "${IFX_DB_LIB_DIR}/informix-connection.ksh"
. "${IFX_DB_LIB_DIR}/informix-query.ksh"