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
    print -u2 "  --hdr-required <YES|NO> \\"
    print -u2 "  --hdr-alert-on-disconnect <YES|NO> \\"
    print -u2 "  --hdr-expected-peer <server-name-or-empty> \\"
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
hdr_required=
hdr_alert_on_disconnect=
hdr_expected_peer=

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
        --hdr-required)
            hdr_required="$2"
            shift 2
            ;;
        --hdr-alert-on-disconnect)
            hdr_alert_on_disconnect="$2"
            shift 2
            ;;
        --hdr-expected-peer)
            hdr_expected_peer="$2"
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
[[ -n "${hdr_required}" ]] || usage
[[ -n "${hdr_alert_on_disconnect}" ]] || usage

case "${hdr_required}:${hdr_alert_on_disconnect}" in
    NO:NO|YES:YES)
        ;;
    *)
        fail "HDR policy requires NO/NO or YES/YES."
        ;;
esac

case "${hdr_required}" in
    YES)
        case "${hdr_expected_peer}" in
            ''|*[!A-Za-z0-9_.-]*)
                fail "HDR expected peer must be a nonempty Informix server name."
                ;;
        esac
        ;;
    NO)
        [[ -z "${hdr_expected_peer}" ]] || fail "HDR expected peer must be empty when HDR is not required."
        ;;
esac

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
[[ -f "${release_dir}/01-statements/informix-locks/IFX-LOCK-001-Sessions-Waiting-for-Locks.sql" ]] || fail "LOCK-001 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-locks/IFX-LOCK-002-Lock-Waits.sql" ]] || fail "LOCK-002 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-locks/IFX-LOCK-003-Lock-Timeouts.sql" ]] || fail "LOCK-003 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-locks/IFX-LOCK-004-Deadlocks.sql" ]] || fail "LOCK-004 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-locks/IFX-LOCK-005-Lock-Table-Exhaustion.sql" ]] || fail "LOCK-005 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-logs/IFX-LOG-001-Current-Utilization.sql" ]] || fail "LOG-001 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-logs/IFX-LOG-002-Not-Backed-Up.sql" ]] || fail "LOG-002 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-logs/IFX-LOG-003-Not-Archived.sql" ]] || fail "LOG-003 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-logs/IFX-LOG-004-Physical-Utilization.sql" ]] || fail "LOG-004 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-logs/IFX-LOG-005-Logical-Logs-Full.sql" ]] || fail "LOG-005 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-logs/IFX-LOG-006-Backup-Inventory.sql" ]] || fail "LOG-006 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-hdr/IFX-HDR-001-Local-Role-and-State.sql" ]] || fail "HDR-001 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-hdr/IFX-HDR-003-Cluster-Rows.sql" ]] || fail "HDR-003 cluster statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-003-Top-Max-Time.sql" ]] || fail "SQL-003 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-002-Top-Runtime.sql" ]] || fail "SQL master statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-001-Active-SQL-Top-N.sql" ]] || fail "SQL-001 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-002-Discovery.sql" ]] || fail "SQL-002 discovery statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-002-By-ID.sql" ]] || fail "SQL-002 detail statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-004-Top-Executions.sql" ]] || fail "SQL-004 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-005-Top-Average-Time.sql" ]] || fail "SQL-005 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-006-Top-Disk-Reads.sql" ]] || fail "SQL-006 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-007-Top-Buffer-Reads.sql" ]] || fail "SQL-007 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-008-Top-Cache-Ratio.sql" ]] || fail "SQL-008 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-009-Top-Lock-Waits.sql" ]] || fail "SQL-009 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-010-Top-Lock-Wait-Time.sql" ]] || fail "SQL-010 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-011-Top-IO-Waits.sql" ]] || fail "SQL-011 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-012-Top-Disk-Sorts.sql" ]] || fail "SQL-012 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-013-Top-Memory-Sorts.sql" ]] || fail "SQL-013 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-014-Top-Estimated-Cost.sql" ]] || fail "SQL-014 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-015-Top-Estimated-Rows.sql" ]] || fail "SQL-015 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-016-Top-Actual-Rows.sql" ]] || fail "SQL-016 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-sql/IFX-SQL-017-User-SQL-QPS.sql" ]] || fail "SQL-017 statement is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sessions/ifx-session-waiting-by-reason.ksh" ]] || fail "SESSION-005 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/locks/ifx-lock-sessions-waiting.ksh" ]] || fail "LOCK-001 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/locks/ifx-lock-waits.ksh" ]] || fail "LOCK-002 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/locks/ifx-lock-timeouts.ksh" ]] || fail "LOCK-003 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/locks/ifx-lock-deadlocks.ksh" ]] || fail "LOCK-004 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/locks/ifx-lock-table-exhaustion.ksh" ]] || fail "LOCK-005 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/logs/ifx-log-current-utilization.ksh" ]] || fail "LOG-001 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/logs/ifx-log-not-backed-up.ksh" ]] || fail "LOG-002 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/logs/ifx-log-not-archived.ksh" ]] || fail "LOG-003 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/logs/ifx-log-physical-utilization.ksh" ]] || fail "LOG-004 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/logs/ifx-log-full.ksh" ]] || fail "LOG-005 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/logs/ifx-log-backup-discovery.ksh" ]] || fail "LOG-006 collector is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-log-006" ]] || fail "LOG-006 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-log-006-age" ]] || fail "LOG-006 age launcher is missing from the release."
[[ -f "${release_dir}/01-statements/informix-storage/IFX-STORAGE-001-Dbspace-Utilization.sql" ]] || fail "STORAGE-001 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-storage/IFX-STORAGE-002-Dbspace-Free-Space.sql" ]] || fail "STORAGE-002 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-storage/IFX-STORAGE-003-Dbspace-Growth-and-Expansion.sql" ]] || fail "STORAGE-003 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-storage/IFX-STORAGE-004-Chunk-State.sql" ]] || fail "STORAGE-004 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-storage/IFX-STORAGE-005-Chunk-Utilization.sql" ]] || fail "STORAGE-005 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-storage/IFX-STORAGE-006-Chunk-Free-Space.sql" ]] || fail "STORAGE-006 statement is missing from the release."
[[ -f "${release_dir}/01-statements/informix-storage/IFX-STORAGE-011-Temporary-Dbspace-Utilization.sql" ]] || fail "STORAGE-011 statement is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-001-dbspace-utilization.ksh" ]] || fail "STORAGE-001 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-002-dbspace-free-space.ksh" ]] || fail "STORAGE-002 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-003-dbspace-growth.ksh" ]] || fail "STORAGE-003 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-004-chunk-state.ksh" ]] || fail "STORAGE-004 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-005-chunk-utilization.ksh" ]] || fail "STORAGE-005 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-006-chunk-free-space.ksh" ]] || fail "STORAGE-006 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-011-temporary-dbspace.ksh" ]] || fail "STORAGE-011 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/hdr/ifx-hdr-local-state.ksh" ]] || fail "HDR-001 collector is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-hdr-001" ]] || fail "HDR-001 launcher is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/hdr/ifx-hdr-expected-configuration.ksh" ]] || fail "HDR-002 collector is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-hdr-002" ]] || fail "HDR-002 launcher is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/hdr/ifx-hdr-peer-discovery.ksh" ]] || fail "HDR-003 collector is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-hdr-003" ]] || fail "HDR-003 launcher is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/hdr/ifx-hdr-peer-field.ksh" ]] || fail "HDR peer-field collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-003-top-max-time.ksh" ]] || fail "SQL-003 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-001-active-sql.ksh" ]] || fail "SQL-001 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-004-top-executions.ksh" ]] || fail "SQL-004 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-005-top-average-time.ksh" ]] || fail "SQL-005 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-006-top-disk-reads.ksh" ]] || fail "SQL-006 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-007-top-buffer-reads.ksh" ]] || fail "SQL-007 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-008-top-cache-ratio.ksh" ]] || fail "SQL-008 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-009-top-lock-waits.ksh" ]] || fail "SQL-009 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-010-top-lock-wait-time.ksh" ]] || fail "SQL-010 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-011-top-io-waits.ksh" ]] || fail "SQL-011 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-012-top-disk-sorts.ksh" ]] || fail "SQL-012 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-013-top-memory-sorts.ksh" ]] || fail "SQL-013 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-014-top-estimated-cost.ksh" ]] || fail "SQL-014 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-015-top-estimated-rows.ksh" ]] || fail "SQL-015 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-016-top-actual-rows.ksh" ]] || fail "SQL-016 collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/sql/ifx-sql-017-user-sql-qps.ksh" ]] || fail "SQL-017 collector is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-hdr-004" ]] || fail "HDR-004 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-hdr-005" ]] || fail "HDR-005 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-003" ]] || fail "SQL-003 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-001" ]] || fail "SQL-001 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-004" ]] || fail "SQL-004 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-005" ]] || fail "SQL-005 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-006" ]] || fail "SQL-006 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-007" ]] || fail "SQL-007 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-008" ]] || fail "SQL-008 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-009" ]] || fail "SQL-009 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-010" ]] || fail "SQL-010 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-011" ]] || fail "SQL-011 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-012" ]] || fail "SQL-012 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-013" ]] || fail "SQL-013 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-014" ]] || fail "SQL-014 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-015" ]] || fail "SQL-015 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-016" ]] || fail "SQL-016 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-sql-017" ]] || fail "SQL-017 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-001" ]] || fail "STORAGE-001 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-002" ]] || fail "STORAGE-002 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-003" ]] || fail "STORAGE-003 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-004" ]] || fail "STORAGE-004 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-005" ]] || fail "STORAGE-005 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-006" ]] || fail "STORAGE-006 launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-011" ]] || fail "STORAGE-011 launcher is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-dbspace-discovery.ksh" ]] || fail "Storage dbspace discovery collector is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-chunk-discovery.ksh" ]] || fail "Storage chunk discovery collector is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-dbspace-discovery" ]] || fail "Storage dbspace discovery launcher is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-chunk-discovery" ]] || fail "Storage chunk discovery launcher is missing from the release."
[[ -f "${release_dir}/05-collectors/informix/storage/ifx-storage-temp-dbspace-discovery.ksh" ]] || fail "Storage temporary dbspace discovery collector is missing from the release."
[[ -f "${release_dir}/03-deployment/launchers/ifx-storage-temp-dbspace-discovery" ]] || fail "Storage temporary dbspace discovery launcher is missing from the release."
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
    print "IFX_HDR_REQUIRED=${hdr_required}"
    print "IFX_HDR_ALERT_ON_DISCONNECT=${hdr_alert_on_disconnect}"
    print "IFX_HDR_EXPECTED_PEER=${hdr_expected_peer}"
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
cp "${release_dir}/03-deployment/launchers/ifx-lock-001" "${launcher_home}/ifx-lock-001" || fail "Unable to install LOCK-001 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-lock-002" "${launcher_home}/ifx-lock-002" || fail "Unable to install LOCK-002 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-lock-003" "${launcher_home}/ifx-lock-003" || fail "Unable to install LOCK-003 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-lock-004" "${launcher_home}/ifx-lock-004" || fail "Unable to install LOCK-004 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-lock-005" "${launcher_home}/ifx-lock-005" || fail "Unable to install LOCK-005 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-log-001" "${launcher_home}/ifx-log-001" || fail "Unable to install LOG-001 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-log-002" "${launcher_home}/ifx-log-002" || fail "Unable to install LOG-002 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-log-003" "${launcher_home}/ifx-log-003" || fail "Unable to install LOG-003 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-log-004" "${launcher_home}/ifx-log-004" || fail "Unable to install LOG-004 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-log-005" "${launcher_home}/ifx-log-005" || fail "Unable to install LOG-005 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-log-006" "${launcher_home}/ifx-log-006" || fail "Unable to install LOG-006 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-log-006-age" "${launcher_home}/ifx-log-006-age" || fail "Unable to install LOG-006 age launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-001" "${launcher_home}/ifx-storage-001" || fail "Unable to install STORAGE-001 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-002" "${launcher_home}/ifx-storage-002" || fail "Unable to install STORAGE-002 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-003" "${launcher_home}/ifx-storage-003" || fail "Unable to install STORAGE-003 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-004" "${launcher_home}/ifx-storage-004" || fail "Unable to install STORAGE-004 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-005" "${launcher_home}/ifx-storage-005" || fail "Unable to install STORAGE-005 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-006" "${launcher_home}/ifx-storage-006" || fail "Unable to install STORAGE-006 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-011" "${launcher_home}/ifx-storage-011" || fail "Unable to install STORAGE-011 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-dbspace-discovery" "${launcher_home}/ifx-storage-dbspace-discovery" || fail "Unable to install storage dbspace discovery launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-chunk-discovery" "${launcher_home}/ifx-storage-chunk-discovery" || fail "Unable to install storage chunk discovery launcher."
cp "${release_dir}/03-deployment/launchers/ifx-storage-temp-dbspace-discovery" "${launcher_home}/ifx-storage-temp-dbspace-discovery" || fail "Unable to install storage temporary dbspace discovery launcher."
cp "${release_dir}/03-deployment/launchers/ifx-hdr-001" "${launcher_home}/ifx-hdr-001" || fail "Unable to install HDR-001 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-hdr-002" "${launcher_home}/ifx-hdr-002" || fail "Unable to install HDR-002 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-hdr-003" "${launcher_home}/ifx-hdr-003" || fail "Unable to install HDR-003 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-hdr-004" "${launcher_home}/ifx-hdr-004" || fail "Unable to install HDR-004 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-hdr-005" "${launcher_home}/ifx-hdr-005" || fail "Unable to install HDR-005 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-003" "${launcher_home}/ifx-sql-003" || fail "Unable to install SQL-003 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-top-n" "${launcher_home}/ifx-sql-top-n" || fail "Unable to install SQL master launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-001" "${launcher_home}/ifx-sql-001" || fail "Unable to install SQL-001 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-004" "${launcher_home}/ifx-sql-004" || fail "Unable to install SQL-004 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-005" "${launcher_home}/ifx-sql-005" || fail "Unable to install SQL-005 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-006" "${launcher_home}/ifx-sql-006" || fail "Unable to install SQL-006 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-007" "${launcher_home}/ifx-sql-007" || fail "Unable to install SQL-007 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-008" "${launcher_home}/ifx-sql-008" || fail "Unable to install SQL-008 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-009" "${launcher_home}/ifx-sql-009" || fail "Unable to install SQL-009 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-010" "${launcher_home}/ifx-sql-010" || fail "Unable to install SQL-010 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-011" "${launcher_home}/ifx-sql-011" || fail "Unable to install SQL-011 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-012" "${launcher_home}/ifx-sql-012" || fail "Unable to install SQL-012 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-013" "${launcher_home}/ifx-sql-013" || fail "Unable to install SQL-013 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-014" "${launcher_home}/ifx-sql-014" || fail "Unable to install SQL-014 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-015" "${launcher_home}/ifx-sql-015" || fail "Unable to install SQL-015 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-016" "${launcher_home}/ifx-sql-016" || fail "Unable to install SQL-016 launcher."
cp "${release_dir}/03-deployment/launchers/ifx-sql-017" "${launcher_home}/ifx-sql-017" || fail "Unable to install SQL-017 launcher."

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
    "${launcher_home}/ifx-session-005" \
    "${launcher_home}/ifx-lock-001" \
    "${launcher_home}/ifx-lock-002" \
    "${launcher_home}/ifx-lock-003" \
    "${launcher_home}/ifx-lock-004" \
    "${launcher_home}/ifx-lock-005" \
    "${launcher_home}/ifx-log-001" \
    "${launcher_home}/ifx-log-002" \
    "${launcher_home}/ifx-log-003" \
    "${launcher_home}/ifx-log-004" \
    "${launcher_home}/ifx-log-005" \
    "${launcher_home}/ifx-log-006" \
    "${launcher_home}/ifx-log-006-age" \
    "${launcher_home}/ifx-hdr-001" \
    "${launcher_home}/ifx-hdr-002" \
    "${launcher_home}/ifx-hdr-003" \
    "${launcher_home}/ifx-hdr-004" \
   "${launcher_home}/ifx-hdr-005" \
    "${launcher_home}/ifx-sql-003" \
    "${launcher_home}/ifx-sql-004" \
    "${launcher_home}/ifx-sql-005" \
    "${launcher_home}/ifx-sql-006" \
    "${launcher_home}/ifx-sql-007" \
    "${launcher_home}/ifx-sql-008" \
    "${launcher_home}/ifx-sql-009" \
    "${launcher_home}/ifx-sql-010" \
    "${launcher_home}/ifx-sql-011" \
    "${launcher_home}/ifx-sql-012" \
    "${launcher_home}/ifx-sql-013" \
    "${launcher_home}/ifx-sql-014" \
    "${launcher_home}/ifx-sql-015" \
    "${launcher_home}/ifx-sql-016" \
    "${launcher_home}/ifx-sql-017" \
    "${launcher_home}/ifx-sql-top-n" \
   "${launcher_home}/ifx-sql-003" \
    "${launcher_home}/ifx-sql-004" \
    "${launcher_home}/ifx-sql-005" \
    "${launcher_home}/ifx-sql-006" \
    "${launcher_home}/ifx-sql-007" \
    "${launcher_home}/ifx-sql-008" \
    "${launcher_home}/ifx-sql-009" \
    "${launcher_home}/ifx-sql-010" \
    "${launcher_home}/ifx-sql-011" \
    "${launcher_home}/ifx-sql-012" \
    "${launcher_home}/ifx-sql-013" \
    "${launcher_home}/ifx-sql-014" \
    "${launcher_home}/ifx-sql-015" \
    "${launcher_home}/ifx-sql-016" \
    "${launcher_home}/ifx-sql-004" \
    "${launcher_home}/ifx-sql-005" \
    "${launcher_home}/ifx-sql-006" \
    "${launcher_home}/ifx-sql-007" \
    "${launcher_home}/ifx-sql-008" \
    "${launcher_home}/ifx-sql-009" \
    "${launcher_home}/ifx-sql-010" \
    "${launcher_home}/ifx-sql-011" \
    "${launcher_home}/ifx-sql-012" \
    "${launcher_home}/ifx-sql-013" \
    "${launcher_home}/ifx-sql-014" \
    "${launcher_home}/ifx-sql-015" \
    "${launcher_home}/ifx-sql-016" \
    "${launcher_home}/ifx-sql-017" \
    "${launcher_home}/ifx-storage-001" \
    "${launcher_home}/ifx-storage-002" \
    "${launcher_home}/ifx-storage-003" \
    "${launcher_home}/ifx-storage-004" \
    "${launcher_home}/ifx-storage-005" \
    "${launcher_home}/ifx-storage-006" \
    "${launcher_home}/ifx-storage-011" \
    "${launcher_home}/ifx-storage-dbspace-discovery" \
    "${launcher_home}/ifx-storage-chunk-discovery" \
    "${launcher_home}/ifx-storage-temp-dbspace-discovery" || fail "Unable to set launcher ownership."

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
    "${launcher_home}/ifx-session-005" \
    "${launcher_home}/ifx-lock-001" \
    "${launcher_home}/ifx-lock-002" \
    "${launcher_home}/ifx-lock-003" \
    "${launcher_home}/ifx-lock-004" \
    "${launcher_home}/ifx-lock-005" \
    "${launcher_home}/ifx-log-001" \
    "${launcher_home}/ifx-log-002" \
    "${launcher_home}/ifx-log-003" \
    "${launcher_home}/ifx-log-004" \
    "${launcher_home}/ifx-log-005" \
    "${launcher_home}/ifx-log-006" \
    "${launcher_home}/ifx-log-006-age" \
    "${launcher_home}/ifx-hdr-001" \
    "${launcher_home}/ifx-hdr-002" \
    "${launcher_home}/ifx-hdr-003" \
    "${launcher_home}/ifx-hdr-004" \
   "${launcher_home}/ifx-hdr-005" \
    "${launcher_home}/ifx-sql-003" \
    "${launcher_home}/ifx-sql-004" \
    "${launcher_home}/ifx-sql-005" \
    "${launcher_home}/ifx-sql-006" \
    "${launcher_home}/ifx-sql-007" \
    "${launcher_home}/ifx-sql-008" \
    "${launcher_home}/ifx-sql-009" \
    "${launcher_home}/ifx-sql-010" \
    "${launcher_home}/ifx-sql-011" \
    "${launcher_home}/ifx-sql-012" \
    "${launcher_home}/ifx-sql-013" \
    "${launcher_home}/ifx-sql-014" \
    "${launcher_home}/ifx-sql-015" \
    "${launcher_home}/ifx-sql-016" \
    "${launcher_home}/ifx-sql-top-n" \
    "${launcher_home}/ifx-storage-001" \
    "${launcher_home}/ifx-storage-002" \
    "${launcher_home}/ifx-storage-003" \
    "${launcher_home}/ifx-storage-004" \
    "${launcher_home}/ifx-storage-005" \
    "${launcher_home}/ifx-storage-006" \
    "${launcher_home}/ifx-storage-011" \
    "${launcher_home}/ifx-storage-dbspace-discovery" \
    "${launcher_home}/ifx-storage-chunk-discovery" \
    "${launcher_home}/ifx-storage-temp-dbspace-discovery" || fail "Unable to protect launchers."

chown root:zabbix \
    "${launcher_home}/ifx-sql-001" \

chmod 750 \
    "${launcher_home}/ifx-sql-001" \

sed \
    -e "s|@RUNTIME_ENV@|${runtime_env}|g" \
    -e "s|@LAUNCHER_HOME@|${launcher_home}|g" \
    "${release_dir}/03-deployment/zabbix-informix.conf.template" \
    > "${agent_config}" || fail "Unable to write Zabbix Agent configuration."

chown root:root "${agent_config}" || fail "Unable to set Zabbix Agent configuration ownership."
chmod 644 "${agent_config}" || fail "Unable to protect Zabbix Agent configuration."

print "Zabbix Informix installation completed."
print "Restart the Zabbix Agent using the service-management command for this host."
