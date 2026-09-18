#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : test-ifx-lock-sessions-waiting.ksh
# Purpose : Validate IFX-LOCK-001 parser against the approved mock contract.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARSER="${SCRIPT_DIR}/../../../05-collectors/informix/locks/ifx-lock-sessions-waiting.ksh"

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
    "12"

run_success_test \
    "zero" \
    "${SCRIPT_DIR}/zero.txt" \
    "0"

run_success_test \
    "single" \
    "${SCRIPT_DIR}/single.txt" \
    "1"

run_success_test \
    "high" \
    "${SCRIPT_DIR}/high.txt" \
    "500"

run_success_test \
    "lower" \
    "${SCRIPT_DIR}/lower.txt" \
    "3"

run_failure_test \
    "empty" \
    "${SCRIPT_DIR}/empty.txt"

run_failure_test \
    "nonnumeric" \
    "${SCRIPT_DIR}/nonnumeric.txt"

run_failure_test \
    "negative" \
    "${SCRIPT_DIR}/negative.txt"

run_failure_test \
    "decimal" \
    "${SCRIPT_DIR}/decimal.txt"

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
