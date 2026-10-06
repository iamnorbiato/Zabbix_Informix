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

if (( duration_seconds < 1 || interval_seconds < 1 )); then
  echo "Duration and interval must be positive integers." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(cd "${script_dir}/../../.." && pwd)"
sysmaster_sql="${repo_dir}/01-statements/informix-sql/IFX-SQL-TRACE-Workload-Sysmaster.sql"
tailor_sql="${repo_dir}/01-statements/informix-sql/IFX-SQL-TRACE-Workload-Tailor.sql"
[[ -r "${sysmaster_sql}" && -r "${tailor_sql}" ]] || { echo "SQL workload statements not found." >&2; exit 1; }

started_at="$(date +%s)"
ends_at=$((started_at + duration_seconds))
run_count=0

echo "Starting read-only Informix SQL trace workload."
echo "Duration: ${duration_seconds}s; interval: ${interval_seconds}s"

while (( $(date +%s) < ends_at )); do
  ksh -c '. 05-collectors/informix/lib/informix-db.ksh; ifx_db_execute sysmaster "$1" >/dev/null' ksh "${sysmaster_sql}" || exit 1
  ksh -c '. 05-collectors/informix/lib/informix-db.ksh; ifx_db_execute tailor "$1" >/dev/null' ksh "${tailor_sql}" || exit 1

  run_count=$((run_count + 1))
  printf 'workload_round=%s elapsed=%ss\n' \
    "${run_count}" "$(( $(date +%s) - started_at ))"
  sleep "${interval_seconds}"
done

echo "Completed read-only workload rounds: ${run_count}"
