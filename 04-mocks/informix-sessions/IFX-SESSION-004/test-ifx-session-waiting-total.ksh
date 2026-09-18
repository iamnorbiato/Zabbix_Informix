#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : test-ifx-session-waiting-total.ksh
# Purpose : Validate IFX-SESSION-004 waiting thread total parser against mocks.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

#
# IFX-SESSION-004 — Waiting Threads Total
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

COLLECTOR="${SCRIPT_DIR}/../../../05-collectors/informix/sessions/ifx-session-waiting-total.ksh"

PASS_COUNT=0
FAIL_COUNT=0

pass()
{
    print "PASS $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail()
{
    print "FAIL $1"
    print "     expected: $2"
    print "     actual  : $3"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

run_success_test()
{
    TEST_NAME="$1"
    INPUT_FILE="$2"
    EXPECTED_VALUE="$3"

    RESULT="$(
        ksh "$COLLECTOR" "${SCRIPT_DIR}/${INPUT_FILE}" 2>/dev/null
    )"

    RESULT_RC=$?

    if [ "$RESULT_RC" -eq 0 ] &&
       [ "$RESULT" = "$EXPECTED_VALUE" ]; then
        pass "$TEST_NAME"
    else
        fail "$TEST_NAME" \
             "value=${EXPECTED_VALUE}, rc=0" \
             "value=${RESULT}, rc=${RESULT_RC}"
    fi
}

run_failure_test()
{
    TEST_NAME="$1"
    INPUT_FILE="$2"

    RESULT="$(
        ksh "$COLLECTOR" "${SCRIPT_DIR}/${INPUT_FILE}" 2>/dev/null
    )"

    RESULT_RC=$?

    if [ "$RESULT_RC" -ne 0 ] &&
       [ -z "$RESULT" ]; then
        pass "$TEST_NAME"
    else
        fail "$TEST_NAME" \
             "no value, non-zero rc" \
             "value=${RESULT}, rc=${RESULT_RC}"
    fi
}

print "IFX-SESSION-004 Mock Validation"
print "==============================="

run_success_test "Normal Waiting Threads" "normal.txt" "22"
run_success_test "Zero Waiting Threads" "zero.txt" "0"
run_success_test "Single Waiting Thread" "single.txt" "1"
run_success_test "High Waiting Threads" "high.txt" "750"
run_success_test "Lower Observation" "lower.txt" "8"

run_failure_test "Empty Result" "empty.txt"
run_failure_test "Non-Numeric Result" "non-numeric.txt"
run_failure_test "Negative Result" "negative.txt"
run_failure_test "Decimal Result" "decimal.txt"
run_failure_test "Execution Error" "execution-error.txt"

print
print "Results"
print "======="
print "PASS: ${PASS_COUNT}"
print "FAIL: ${FAIL_COUNT}"
print

if [ "$FAIL_COUNT" -eq 0 ]; then
    print "IFX-SESSION-004: MOCK VALIDATION PASSED"
    exit 0
fi

print "IFX-SESSION-004: MOCK VALIDATION FAILED"
exit 1
