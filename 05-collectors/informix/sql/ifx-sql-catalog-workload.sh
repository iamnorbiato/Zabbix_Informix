#!/usr/bin/env bash
set -u

duration_seconds="${1:-1200}"
interval_seconds="${2:-2}"

case "${duration_seconds}" in
  ''|*[!0-9]*) echo "Invalid duration: ${duration_seconds}" >&2; exit 1 ;;
esac
case "${interval_seconds}" in
  ''|*[!0-9]*) echo "Invalid interval: ${interval_seconds}" >&2; exit 1 ;;
esac
(( duration_seconds > 0 && interval_seconds > 0 )) || exit 1

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "${script_dir}/../../.." && pwd)"
db_library="${repo_dir}/05-collectors/informix/lib/informix-db.ksh"
[[ -r "${db_library}" ]] || { echo "Informix query library not found: ${db_library}" >&2; exit 1; }

started_at="$(date +%s)"
ends_at=$((started_at + duration_seconds))
run_count=0

echo "Starting read-only temporary catalog workload."
echo "Duration: ${duration_seconds}s; interval: ${interval_seconds}s"

while (( $(date +%s) < ends_at )); do
  run_sql() {
    sql_file="$(mktemp "${TMPDIR:-/tmp}/ifx-catalog-workload.XXXXXX.sql")" || return 1
    printf '%s\n' "$2" > "${sql_file}"
    ksh -c '. "$1"; ifx_db_execute sysmaster "$2" >/dev/null' \
      ksh "${db_library}" "${sql_file}"
    rc=$?
    rm -f "${sql_file}"
    return ${rc}
  }

  run_sql sysmaster 'SELECT FIRST 100000 tabid, colname FROM syscolumns;' || exit 1
  run_sql sysmaster 'SELECT COUNT(*) FROM syscolumns;' || exit 1
  run_sql sysmaster 'SELECT SUBSTR(TRIM(colname), 1, 1), COUNT(*), MIN(tabid), MAX(tabid) FROM syscolumns GROUP BY 1 ORDER BY 2 DESC;' || exit 1

  run_count=$((run_count + 1))
  printf 'workload_round=%s elapsed=%ss\n' \
    "${run_count}" "$(( $(date +%s) - started_at ))"
  sleep "${interval_seconds}"
done

printf 'completed_workload_rounds=%s\n' "${run_count}"
