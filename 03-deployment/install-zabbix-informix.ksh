#!/usr/bin/env ksh

usage()
{
    print -u2 "Usage: $0 \\"
    print -u2 "  --install-home <absolute-path> \\"
    print -u2 "  --config-home <absolute-path> \\"
    print -u2 "  --launcher-home <absolute-path> \\"
    print -u2 "  --agent-include-dir <absolute-path> \\"
    print -u2 "  --informix-home <absolute-path> \\"
    print -u2 "  --informix-server <server-name> \\"
    print -u2 "  --informix-sqlhosts <absolute-path> \\"
    print -u2 "  --connection-file <absolute-path> \\"
    print -u2 "  [--state-source <absolute-path>]"
    exit 1
}

fail()
{
    print -u2 "Installation failed: $1"
    exit 1
}

require_absolute_path()
{
    case "$2" in
        /*)
            ;;
        *)
            fail "$1 must be an absolute path."
            ;;
    esac

    case "$2" in
        *'&'*|*'|'*|*'
'*)
            fail "$1 contains unsupported characters."
            ;;
    esac
}

if [[ "$(id -u)" != "0" ]]; then
    fail "Run this installer as root."
fi

release_dir="$(cd "$(dirname "$0")/.." && pwd)" || fail "Unable to determine release directory."

install_home=
config_home=
launcher_home=
agent_include_dir=
informix_home=
informix_server=
informix_sqlhosts=
connection_source=
state_source=

while (( $# > 0 )); do
    case "$1" in
        --install-home)
            install_home="$2"
            shift 2
            ;;
        --config-home)
            config_home="$2"
            shift 2
            ;;
        --launcher-home)
            launcher_home="$2"
            shift 2
            ;;
        --agent-include-dir)
            agent_include_dir="$2"
            shift 2
            ;;
        --informix-home)
            informix_home="$2"
            shift 2
            ;;
        --informix-server)
            informix_server="$2"
            shift 2
            ;;
        --informix-sqlhosts)
            informix_sqlhosts="$2"
            shift 2
            ;;
        --connection-file)
            connection_source="$2"
            shift 2
            ;;
        --state-source)
            state_source="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

[[ -n "${install_home}" ]] || usage
[[ -n "${config_home}" ]] || usage
[[ -n "${launcher_home}" ]] || usage
[[ -n "${agent_include_dir}" ]] || usage
[[ -n "${informix_home}" ]] || usage
[[ -n "${informix_server}" ]] || usage
[[ -n "${informix_sqlhosts}" ]] || usage
[[ -n "${connection_source}" ]] || usage

require_absolute_path "INSTALL_HOME" "${install_home}"
require_absolute_path "CONFIG_HOME" "${config_home}"
require_absolute_path "LAUNCHER_HOME" "${launcher_home}"
require_absolute_path "AGENT_INCLUDE_DIR" "${agent_include_dir}"
require_absolute_path "INFORMIX_HOME" "${informix_home}"
require_absolute_path "INFORMIXSQLHOSTS" "${informix_sqlhosts}"
require_absolute_path "CONNECTION_FILE" "${connection_source}"

if [[ -n "${state_source}" ]]; then
    require_absolute_path "STATE_SOURCE" "${state_source}"
fi

case "${informix_server}" in
    ''|*[!A-Za-z0-9_.-]*)
        fail "INFORMIXSERVER contains unsupported characters."
        ;;
esac

[[ -d "${informix_home}" ]] || fail "Informix Client SDK directory not found: ${informix_home}"
[[ -f "${informix_sqlhosts}" ]] || fail "Informix sqlhosts file not found: ${informix_sqlhosts}"
[[ -f "${connection_source}" ]] || fail "Connection file not found: ${connection_source}"
[[ -f "${release_dir}/01-statements/informix-health/IFX-HEALTH-001-Instance-State.sql" ]] || fail "HEALTH-001 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-health/IFX-HEALTH-002-Instance-Uptime.sql" ]] || fail "HEALTH-002 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-health/IFX-HEALTH-003-Assert-Failures.sql" ]] || fail "HEALTH-003 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-health/IFX-HEALTH-004-Checkpoint-Count.sql" ]] || fail "HEALTH-004 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-health/IFX-HEALTH-005-Checkpoint-Duration.sql" ]] || fail "HEALTH-005 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-health/IFX-HEALTH-006-Checkpoint-Waits.sql" ]] || fail "HEALTH-006 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-health/IFX-HEALTH-007-LRU-Writes.sql" ]] || fail "HEALTH-007 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-health/IFX-HEALTH-008-Foreground-Writes.sql" ]] || fail "HEALTH-008 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sessions/IFX-SESSION-001-Total-Connected-Sessions.sql" ]] || fail "SESSION-001 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sessions/IFX-SESSION-002-Sessions-in-Read-Call.sql" ]] || fail "SESSION-002 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sessions/IFX-SESSION-003-Weekly-Peak-Concurrent-Physical-Connections.sql" ]] || fail "SESSION-003 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sessions/IFX-SESSION-004-Waiting-Client-Sessions-Total.sql" ]] || fail "SESSION-004 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sessions/IFX-SESSION-005-Waiting-Client-Sessions-by-Reason.sql" ]] || fail "SESSION-005 statement is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/health/ifx-health-state.ksh" ]] || fail "HEALTH-001 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/health/ifx-health-uptime.ksh" ]] || fail "HEALTH-002 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/health/ifx-health-assert-failures.ksh" ]] || fail "HEALTH-003 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/health/ifx-health-checkpoint-count.ksh" ]] || fail "HEALTH-004 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/health/ifx-health-checkpoint-duration.ksh" ]] || fail "HEALTH-005 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/health/ifx-health-checkpoint-waits.ksh" ]] || fail "HEALTH-006 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/health/ifx-health-lru-writes.ksh" ]] || fail "HEALTH-007 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/health/ifx-health-foreground-writes.ksh" ]] || fail "HEALTH-008 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sessions/ifx-session-total-connected.ksh" ]] || fail "SESSION-001 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sessions/ifx-session-in-read-call.ksh" ]] || fail "SESSION-002 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sessions/ifx-session-weekly-peak-physical-connections.ksh" ]] || fail "SESSION-003 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sessions/ifx-session-waiting-total.ksh" ]] || fail "SESSION-004 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sessions/ifx-session-waiting-by-reason.ksh" ]] || fail "SESSION-005 collector is missing from the release."
[[ -f "${release_dir}/03-deployment/zabbix-informix.conf.template" ]] || fail "Zabbix Agent template is missing from the release."

id zabbix >/dev/null 2>&1 || fail "Required operating-system user not found: zabbix"

connection_target="${config_home}/informix-connect.sql"
runtime_env="${config_home}/runtime.env"
state_target="${config_home}/state"
agent_config="${agent_include_dir}/zabbix-informix.conf"

mkdir -p "${install_home}" || fail "Unable to create INSTALL_HOME."
mkdir -p "${config_home}" || fail "Unable to create CONFIG_HOME."
mkdir -p "${launcher_home}" || fail "Unable to create LAUNCHER_HOME."
mkdir -p "${agent_include_dir}" || fail "Unable to create AGENT_INCLUDE_DIR."

cp -R "${release_dir}/01-statements" "${install_home}/" || fail "Unable to install SQL statements."
cp -R "${release_dir}/05-collectors" "${install_home}/" || fail "Unable to install collectors."

chown -R root:zabbix "${install_home}" || fail "Unable to set installed-code ownership."
find "${install_home}" -type d -exec chmod 750 {} \; || fail "Unable to protect installed directories."
find "${install_home}" -type f -name '*.ksh' -exec chmod 750 {} \; || fail "Unable to protect installed scripts."
find "${install_home}" -type f -name '*.sql' -exec chmod 640 {} \; || fail "Unable to protect installed SQL statements."

chown root:zabbix "${config_home}" || fail "Unable to set configuration-directory ownership."
chmod 1730 "${config_home}" || fail "Unable to protect configuration directory."

if [[ "${connection_source}" != "${connection_target}" ]]; then
    cp "${connection_source}" "${connection_target}" || fail "Unable to install private connection file."
fi

chown root:zabbix "${connection_target}" || fail "Unable to set connection-file ownership."
chmod 640 "${connection_target}" || fail "Unable to protect connection file."

if [[ ! -d "${state_target}" ]]; then
    if [[ -n "${state_source}" && -d "${state_source}" ]]; then
        cp -R "${state_source}" "${state_target}" || fail "Unable to migrate collector state."
    else
        mkdir "${state_target}" || fail "Unable to create collector state directory."
    fi
fi

chown -R zabbix:zabbix "${state_target}" || fail "Unable to set state-directory ownership."
chmod 700 "${state_target}" || fail "Unable to protect state directory."
find "${state_target}" -type f -exec chmod 600 {} \; || fail "Unable to protect state files."

{
    print "IFX_COLLECTOR_HOME=${install_home}"
    print "IFX_INFORMIXDIR=${informix_home}"
    print "IFX_INFORMIXSERVER=${informix_server}"
    print "IFX_INFORMIXSQLHOSTS=${informix_sqlhosts}"
    print "IFX_CONFIG_DIR=${config_home}"
    print "IFX_STATE_DIR=${state_target}"
    print "IFX_CONNECT_FILE=${connection_target}"
} > "${runtime_env}" || fail "Unable to write runtime configuration."

chown root:zabbix "${runtime_env}" || fail "Unable to set runtime-configuration ownership."
chmod 640 "${runtime_env}" || fail "Unable to protect runtime configuration."

cp "${release_dir}/03-deployment/launchers/ifx-health-001" "${launcher_home}/ifx-health-001" || fail "Unable to install HEALTH-001 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-health-002" "${launcher_home}/ifx-health-002" || fail "Unable to install HEALTH-002 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-health-003" "${launcher_home}/ifx-health-003" || fail "Unable to install HEALTH-003 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-health-004" "${launcher_home}/ifx-health-004" || fail "Unable to install HEALTH-004 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-health-005" "${launcher_home}/ifx-health-005" || fail "Unable to install HEALTH-005 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-health-006" "${launcher_home}/ifx-health-006" || fail "Unable to install HEALTH-006 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-health-007" "${launcher_home}/ifx-health-007" || fail "Unable to install HEALTH-007 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-health-008" "${launcher_home}/ifx-health-008" || fail "Unable to install HEALTH-008 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-session-001" "${launcher_home}/ifx-session-001" || fail "Unable to install SESSION-001 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-session-002" "${launcher_home}/ifx-session-002" || fail "Unable to install SESSION-002 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-session-003" "${launcher_home}/ifx-session-003" || fail "Unable to install SESSION-003 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-session-004" "${launcher_home}/ifx-session-004" || fail "Unable to install SESSION-004 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-session-005" "${launcher_home}/ifx-session-005" || fail "Unable to install SESSION-005 launcher."

chown root:zabbix \
    "${launcher_home}/ifx-health-001" \
    "${launcher_home}/ifx-health-002" \
    "${launcher_home}/ifx-health-003" \
    "${launcher_home}/ifx-health-004" \
    "${launcher_home}/ifx-health-005" \
    "${launcher_home}/ifx-health-006" \
    "${launcher_home}/ifx-health-007" \
    "${launcher_home}/ifx-health-008" \
    "${launcher_home}/ifx-session-001" \
    "${launcher_home}/ifx-session-002" \
    "${launcher_home}/ifx-session-003" \
    "${launcher_home}/ifx-session-004" \
    "${launcher_home}/ifx-session-005" || fail "Unable to set launcher ownership."

chmod 750 \
    "${launcher_home}/ifx-health-001" \
    "${launcher_home}/ifx-health-002" \
    "${launcher_home}/ifx-health-003" \
    "${launcher_home}/ifx-health-004" \
    "${launcher_home}/ifx-health-005" \
    "${launcher_home}/ifx-health-006" \
    "${launcher_home}/ifx-health-007" \
    "${launcher_home}/ifx-health-008" \
    "${launcher_home}/ifx-session-001" \
    "${launcher_home}/ifx-session-002" \
    "${launcher_home}/ifx-session-003" \
    "${launcher_home}/ifx-session-004" \
    "${launcher_home}/ifx-session-005" || fail "Unable to protect launchers."

sed \
    -e "s|@RUNTIME_ENV@|${runtime_env}|g" \
    -e "s|@LAUNCHER_HOME@|${launcher_home}|g" \
    "${release_dir}/03-deployment/zabbix-informix.conf.template" \
    > "${agent_config}" || fail "Unable to write Zabbix Agent configuration."

chown root:root "${agent_config}" || fail "Unable to set Zabbix Agent configuration ownership."
chmod 644 "${agent_config}" || fail "Unable to protect Zabbix Agent configuration."

print "Zabbix Informix installation completed."
print "Restart the Zabbix Agent using the service-management command for this host."