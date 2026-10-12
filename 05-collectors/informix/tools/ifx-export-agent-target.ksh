#!/usr/bin/env ksh
# Generate a reviewed, read-only registration report for an Informix target.

typeset server="${IFX_INFORMIXSERVER:-${INFORMIXSERVER:-}}"
typeset sqlhosts_file="${IFX_INFORMIXSQLHOSTS:-${INFORMIXSQLHOSTS:-}}"
typeset connect_file="${IFX_CONNECT_FILE:-}"
typeset connect_db="${IFX_EXPORT_DATABASE:-sysmaster}"
typeset sqlhosts_line
typeset role_data
typeset rc
typeset script_dir
typeset informix_lib_dir
typeset statement_file
typeset dataset

script_dir="$(cd "$(dirname "${.sh.file}")" && pwd)"
informix_lib_dir="$(cd "${script_dir}/../lib" && pwd)"
statement_file="${IFX_EXPORT_STATEMENT_FILE:-${script_dir}/../../../01-statements/informix-hdr/IFX-HDR-001-Local-Role-and-State.sql}"

fail()
{
    print -u2 "ifx-export-agent-target: $1"
    return 1
}

[[ -n "${server}" ]] || { fail "INFORMIXSERVER is not configured."; exit 1; }
[[ -n "${sqlhosts_file}" ]] || { fail "INFORMIXSQLHOSTS is not configured."; exit 1; }
[[ -r "${sqlhosts_file}" ]] || { fail "sqlhosts file is not readable: ${sqlhosts_file}"; exit 1; }
. "${informix_lib_dir}/informix-db.ksh" || { fail "Informix database library could not be loaded."; exit 1; }

sqlhosts_line="$(awk -v target="${server}" '
    $0 !~ /^[[:space:]]*#/ && NF >= 4 && $1 == target { print; exit }
' "${sqlhosts_file}")"

[[ -n "${sqlhosts_line}" ]] || {
    fail "INFORMIXSERVER was not found in sqlhosts: ${server}"
    exit 1
}

if [[ -n "${connect_file}" && ! -r "${connect_file}" ]]; then
    fail "connection file is not readable: ${connect_file}"
    exit 1
fi

[[ -f "${statement_file}" ]] || { fail "HDR statement file not found: ${statement_file}"; exit 1; }

dataset="$(ifx_db_execute "${connect_db}" "${statement_file}")"
rc=$?
if (( rc != 0 )); then
    fail "unable to query sysdri."
    exit ${rc}
fi

role_data="$(print -r -- "${dataset}" | awk -F '|' 'NF >= 2 { print $1 "|" $2 "|" $3; exit }')"
[[ -n "${role_data}" ]] || role_data="UNKNOWN|UNKNOWN|"

print "# Informix target registration report"
print "TARGET_ID=${server}"
print "INFORMIXSERVER=${server}"
print "SQLHOSTS_FILE=${sqlhosts_file}"
print "SQLHOSTS_ENTRY=${sqlhosts_line}"
print "${role_data}" | awk -F '|' '
{
    role = toupper($1)
    if (role == "PRIMARY") {
        canonical = "PRIMARY"
    }
    else if (role == "SECONDARY") {
        canonical = "SECONDARY"
    }
    else if (role == "STANDARD" || role == "NOT INITIALIZED") {
        canonical = "STANDALONE"
    }
    else {
        canonical = "UNKNOWN"
    }

    print "OBSERVED_ROLE=" $1
    print "OBSERVED_STATE=" $2
    print "OBSERVED_HDR_PEER=" $3
    print "CANONICAL_ROLE=" canonical
}'
print ""
print "# Create on the Linux collector after review:"
print "# /etc/zabbix-informix/targets/${server}/informix-connect.sql"
print "# owner=root group=zabbix mode=0640"
print ""
print "# Validate on the Linux collector:"
print "# ifx_db_execute_target ${server} sysmaster <statement-file>"

exit 0
