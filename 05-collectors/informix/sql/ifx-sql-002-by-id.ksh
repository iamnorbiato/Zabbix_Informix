#!/bin/ksh

if (( $# != 1 )); then
    print -u2 "Usage: $0 <sql_id>"
    exit 1
fi

case "$1" in
    *[!0-9]*)
        print -u2 "Invalid SQL-002 sql_id: $1"
        exit 1
        ;;
esac

. "${IFX_COLLECTOR_HOME:-/opt/zabbix-informix}/05-collectors/informix/lib/informix-db.ksh" || exit 1

IFX_SQL_DIR="$(cd "$(dirname "${.sh.file}")" && pwd)"
IFX_REPOSITORY_DIR="$(cd "${IFX_SQL_DIR}/../../.." && pwd)"
statement="${IFX_REPOSITORY_DIR}/01-statements/informix-sql/IFX-SQL-002-By-ID.sql"

[[ -r "${statement}" ]] || {
    print -u2 "Informix SQL-002 detail statement not found: ${statement}"
    exit 1
}

dataset="$(ifx_db_execute sysmaster "${statement}" "$1")" || {
    print -u2 "Unable to collect SQL-002 detail for sql_id: $1"
    exit 1
}

[[ -n "${dataset}" ]] || {
    print -u2 "SQL-002 sql_id not found: $1"
    exit 1
}

print -r -- "${dataset}"
