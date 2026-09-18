#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : test-ifx-session-waiting-by-reason.ksh
# Purpose : Validate IFX-SESSION-005 parser against the approved mock contract.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARSER="${SCRIPT_DIR}/../../../05-collectors/informix/sessions/ifx-session-waiting-by-reason.ksh"

PASS=0
FAIL=0

run_success_test()
{
    NAME="$1"
    FILE="$2"
    EXPECTED="$3"

    OUTPUT="$("$PARSER" "$FILE" 2>/dev/null)"
    RC=$?

    if [ "$RC" -eq 0 ] && [ "$OUTPUT" = "$EXPECTED" ]; then
        print "PASS: $NAME"
        PASS=$((PASS + 1))
    else
        print "FAIL: $NAME"
        print "      rc=$RC"
        print "      expected=[$EXPECTED]"
        print "      actual=[$OUTPUT]"
        FAIL=$((FAIL + 1))
    fi
}

run_failure_test()
{
    NAME="$1"
    FILE="$2"

    OUTPUT="$("$PARSER" "$FILE" 2>/dev/null)"
    RC=$?

    if [ "$RC" -ne 0 ] && [ -z "$OUTPUT" ]; then
        print "PASS: $NAME"
        PASS=$((PASS + 1))
    else
        print "FAIL: $NAME"
        print "      rc=$RC"
        print "      stdout=[$OUTPUT]"
        FAIL=$((FAIL + 1))
    fi
}

run_success_test \
    "normal" \
    "${SCRIPT_DIR}/normal.txt" \
"REASON_A|Synthetic reason A|12
REASON_B|Synthetic reason B|7
REASON_C|Synthetic reason C|3"

run_success_test \
    "single-reason" \
    "${SCRIPT_DIR}/single-reason.txt" \
"REASON_A|Synthetic reason A|5"

run_success_test \
    "zero-count" \
    "${SCRIPT_DIR}/zero-count.txt" \
"REASON_A|Synthetic reason A|0"

run_success_test \
    "empty-success" \
    "${SCRIPT_DIR}/empty-success.txt" \
""

run_success_test \
    "new-reason" \
    "${SCRIPT_DIR}/new-reason.txt" \
"REASON_A|Synthetic reason A|12
REASON_NEW|Synthetic newly discovered reason|4"

run_failure_test \
    "duplicate-reason" \
    "${SCRIPT_DIR}/duplicate-reason.txt"

run_failure_test \
    "negative-count" \
    "${SCRIPT_DIR}/negative-count.txt"

run_failure_test \
    "decimal-count" \
    "${SCRIPT_DIR}/decimal-count.txt"

run_failure_test \
    "malformed-row" \
    "${SCRIPT_DIR}/malformed-row.txt"

run_failure_test \
    "execution-error" \
    "${SCRIPT_DIR}/execution-error.txt"

print
print "PASS: $PASS"
print "FAIL: $FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
