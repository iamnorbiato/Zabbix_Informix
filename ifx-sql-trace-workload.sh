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

dbaccess_bin="${DBACCESS_BIN:-$(command -v dbaccess 2>/dev/null || true)}"
if [[ -z "${dbaccess_bin}" ]]; then
  echo "dbaccess not found." >&2
  exit 1
fi

started_at="$(date +%s)"
ends_at=$((started_at + duration_seconds))
run_count=0

echo "Starting read-only Informix SQL trace workload."
echo "Duration: ${duration_seconds}s; interval: ${interval_seconds}s"

while (( $(date +%s) < ends_at )); do
  "${dbaccess_bin}" sysmaster <<'SQL' >/dev/null
SELECT COUNT(*) FROM systables;
SELECT FIRST 100 tabid, TRIM(tabname)
FROM systables
ORDER BY tabid DESC;
SELECT owner, COUNT(*)
FROM systables
GROUP BY owner
ORDER BY COUNT(*) DESC;
SQL

  "${dbaccess_bin}" tailor <<'SQL' >/dev/null
SELECT COUNT(*) FROM zbx_ifx_session_test_lock;
SELECT FIRST 100 id, note
FROM zbx_ifx_session_test_lock
ORDER BY id DESC;
SELECT id, note
FROM zbx_ifx_session_test_lock
ORDER BY note;
SQL

  run_count=$((run_count + 1))
  printf 'workload_round=%s elapsed=%ss\n' \
    "${run_count}" "$(( $(date +%s) - started_at ))"
  sleep "${interval_seconds}"
done

echo "Completed read-only workload rounds: ${run_count}"
