#!/usr/bin/env ksh

usage()
{
    print -u2 "Usage: $0 \\"
    print -u2 "  --install-home <absolute-path> \\"
    print -u2 "  --config-home <absolute-path> \\"
    print -u2 "  --launcher-home <absolute-path> \\"
    print -u2 "  --agent-include-dir <absolute-path> \\"
    print -u2 "  [--purge]"
    exit 1
}

fail()
{
    print -u2 "Uninstallation failed: $1"
    exit 1
}

require_product_path()
{
    case "$2" in
        /*/zabbix-informix)
            ;;
        *)
            fail "$1 must be an absolute product path ending in /zabbix-informix."
            ;;
    esac
}

if [[ "$(id -u)" != "0" ]]; then
    fail "Run this uninstaller as root."
fi

install_home=
config_home=
launcher_home=
agent_include_dir=
purge=false

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
        --purge)
            purge=true
            shift
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

require_product_path "INSTALL_HOME" "${install_home}"
require_product_path "CONFIG_HOME" "${config_home}"
require_product_path "LAUNCHER_HOME" "${launcher_home}"

case "${agent_include_dir}" in
    /*)
        ;;
    *)
        fail "AGENT_INCLUDE_DIR must be an absolute path."
        ;;
esac

agent_config="${agent_include_dir}/zabbix-informix.conf"

rm -f "${agent_config}" || fail "Unable to remove Zabbix Agent configuration."
rm -f "${launcher_home}/ifx-health-001" || fail "Unable to remove HEALTH-001 launcher."
rm -f "${launcher_home}/ifx-health-002" || fail "Unable to remove HEALTH-002 launcher."
rm -f "${launcher_home}/ifx-health-003" || fail "Unable to remove HEALTH-003 launcher."
rm -f "${launcher_home}/ifx-health-004" || fail "Unable to remove HEALTH-004 launcher."
rm -f "${launcher_home}/ifx-health-005" || fail "Unable to remove HEALTH-005 launcher."
rm -f "${launcher_home}/ifx-health-006" || fail "Unable to remove HEALTH-006 launcher."
rm -f "${launcher_home}/ifx-health-007" || fail "Unable to remove HEALTH-007 launcher."
rm -f "${launcher_home}/ifx-health-008" || fail "Unable to remove HEALTH-008 launcher."
rm -f "${launcher_home}/ifx-session-001" || fail "Unable to remove SESSION-001 launcher."
rm -f "${launcher_home}/ifx-session-002" || fail "Unable to remove SESSION-002 launcher."
rm -f "${launcher_home}/ifx-session-003" || fail "Unable to remove SESSION-003 launcher."
rm -f "${launcher_home}/ifx-session-004" || fail "Unable to remove SESSION-004 launcher."
rm -f "${launcher_home}/ifx-session-005" || fail "Unable to remove SESSION-005 launcher."
rm -f "${launcher_home}/ifx-lock-001" || fail "Unable to remove LOCK-001 launcher."
if [[ -d "${launcher_home}" ]]; then
    rmdir "${launcher_home}" 2>/dev/null || true
fi

if [[ "${purge}" == "true" ]]; then
    rm -rf "${install_home}" || fail "Unable to remove INSTALL_HOME."
    rm -rf "${config_home}" || fail "Unable to remove CONFIG_HOME."
    print "Zabbix Informix was removed with private configuration and collector state."
else
    print "Zabbix Agent integration was removed."
    print "INSTALL_HOME and CONFIG_HOME were preserved."
    print "Use --purge only when private configuration and collector state must also be removed."
fi

print "Restart the Zabbix Agent using the service-management command for this host."