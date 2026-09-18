#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : test-ifx-health-assert-failures.ksh
# Purpose : Validate IFX-HEALTH-003 stateful collector behavior against mock
#           Informix online.log scenarios.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

#
# IFX-HEALTH-003 — Assert Failures
#
# This test runner validates:
#
#   - first-run bootstrap behavior;
#   - incremental assertion detection;
#   - duplicate prevention;
#   - multiple assertion detection;
#   - Assert Warning exclusion;
#   - normal-message handling;
#   - empty-log handling;
#   - log truncation recovery;
#   - invalid state handling;
#   - missing source handling;
#   - state preservation after collection failure.
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

COLLECTOR="${SCRIPT_DIR}/../../../05-collectors/informix/health/ifx-health-assert-failures.ksh"

PASS_COUNT=0
FAIL_COUNT=0

WORK_DIR="${SCRIPT_DIR}/.test-work.$$"

mkdir -p "$WORK_DIR"

if [ "$?" -ne 0 ]; then
    print "Unable to create temporary test directory."
    exit 1
fi

cleanup()
{
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT HUP INT TERM


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


run_collector()
{
    LOG_FILE="$1"
    STATE_FILE="$2"

    RESULT="$(
        ksh "$COLLECTOR" "$LOG_FILE" "$STATE_FILE" 2>/dev/null
    )"

    RESULT_RC=$?
}


test_value()
{
    TEST_NAME="$1"
    EXPECTED_VALUE="$2"
    EXPECTED_RC="$3"

    if [ "$RESULT_RC" -eq "$EXPECTED_RC" ] &&
       [ "$RESULT" = "$EXPECTED_VALUE" ]; then
        pass "$TEST_NAME"
    else
        fail "$TEST_NAME" \
             "value=${EXPECTED_VALUE}, rc=${EXPECTED_RC}" \
             "value=${RESULT}, rc=${RESULT_RC}"
    fi
}


print "IFX-HEALTH-003 Mock Validation"
print "=============================="

#
# ----------------------------------------------------------------------
# Test 1
# First execution must establish EOF and ignore historical assertions.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/bootstrap.log"
TEST_STATE="${WORK_DIR}/bootstrap.state"

cp "${SCRIPT_DIR}/one-assert.log" "$TEST_LOG"

run_collector "$TEST_LOG" "$TEST_STATE"

test_value "Bootstrap Ignores Historical Assert" "0" "0"


#
# ----------------------------------------------------------------------
# Test 2
# Incremental assertion appended after bootstrap must be detected.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/incremental.log"
TEST_STATE="${WORK_DIR}/incremental.state"

cp "${SCRIPT_DIR}/incremental-step-1.log" "$TEST_LOG"

run_collector "$TEST_LOG" "$TEST_STATE"

if [ "$RESULT_RC" -ne 0 ] || [ "$RESULT" != "0" ]; then
    fail "Incremental Assert" \
         "bootstrap value=0, rc=0" \
         "bootstrap value=${RESULT}, rc=${RESULT_RC}"
else
    cp "${SCRIPT_DIR}/incremental-step-2.log" "$TEST_LOG"

    run_collector "$TEST_LOG" "$TEST_STATE"

    test_value "Incremental Assert" "1" "0"
fi


#
# ----------------------------------------------------------------------
# Test 3
# Same assertion must not be emitted again.
# ----------------------------------------------------------------------
#

if [ -f "$TEST_STATE" ]; then

    run_collector "$TEST_LOG" "$TEST_STATE"

    test_value "No Duplicate Assert" "0" "0"

else
    fail "No Duplicate Assert" \
         "state file available" \
         "state file missing"
fi


#
# ----------------------------------------------------------------------
# Test 4
# Multiple new assertion failures must be counted independently.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/multiple.log"
TEST_STATE="${WORK_DIR}/multiple.state"

cp "${SCRIPT_DIR}/initial-clean.log" "$TEST_LOG"

run_collector "$TEST_LOG" "$TEST_STATE"

if [ "$RESULT_RC" -ne 0 ] || [ "$RESULT" != "0" ]; then
    fail "Multiple New Asserts" \
         "bootstrap value=0, rc=0" \
         "bootstrap value=${RESULT}, rc=${RESULT_RC}"
else
    cat "${SCRIPT_DIR}/multiple-asserts.log" >> "$TEST_LOG"

    run_collector "$TEST_LOG" "$TEST_STATE"

    test_value "Multiple New Asserts" "2" "0"
fi


#
# ----------------------------------------------------------------------
# Test 5
# Assert Warning must not be counted.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/warning.log"
TEST_STATE="${WORK_DIR}/warning.state"

cp "${SCRIPT_DIR}/initial-clean.log" "$TEST_LOG"

run_collector "$TEST_LOG" "$TEST_STATE"

if [ "$RESULT_RC" -ne 0 ] || [ "$RESULT" != "0" ]; then
    fail "Assert Warning Excluded" \
         "bootstrap value=0, rc=0" \
         "bootstrap value=${RESULT}, rc=${RESULT_RC}"
else
    cat "${SCRIPT_DIR}/assert-warning.log" >> "$TEST_LOG"

    run_collector "$TEST_LOG" "$TEST_STATE"

    test_value "Assert Warning Excluded" "0" "0"
fi


#
# ----------------------------------------------------------------------
# Test 6
# Mixed content containing one real assertion must return 1.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/mixed.log"
TEST_STATE="${WORK_DIR}/mixed.state"

cp "${SCRIPT_DIR}/initial-clean.log" "$TEST_LOG"

run_collector "$TEST_LOG" "$TEST_STATE"

if [ "$RESULT_RC" -ne 0 ] || [ "$RESULT" != "0" ]; then
    fail "Mixed Events" \
         "bootstrap value=0, rc=0" \
         "bootstrap value=${RESULT}, rc=${RESULT_RC}"
else
    cat "${SCRIPT_DIR}/mixed-events.log" >> "$TEST_LOG"

    run_collector "$TEST_LOG" "$TEST_STATE"

    test_value "Mixed Events" "1" "0"
fi


#
# ----------------------------------------------------------------------
# Test 7
# Empty readable log is a successful collection.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/empty.log"
TEST_STATE="${WORK_DIR}/empty.state"

cp "${SCRIPT_DIR}/empty.log" "$TEST_LOG"

run_collector "$TEST_LOG" "$TEST_STATE"

test_value "Empty Log" "0" "0"


#
# ----------------------------------------------------------------------
# Test 8
# Log truncation must safely establish a new baseline.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/truncated.log"
TEST_STATE="${WORK_DIR}/truncated.state"

cp "${SCRIPT_DIR}/multiple-asserts.log" "$TEST_LOG"

run_collector "$TEST_LOG" "$TEST_STATE"

if [ "$RESULT_RC" -ne 0 ] || [ "$RESULT" != "0" ]; then
    fail "Log Truncation" \
         "bootstrap value=0, rc=0" \
         "bootstrap value=${RESULT}, rc=${RESULT_RC}"
else
    cp "${SCRIPT_DIR}/truncated.log" "$TEST_LOG"

    run_collector "$TEST_LOG" "$TEST_STATE"

    test_value "Log Truncation" "0" "0"
fi


#
# ----------------------------------------------------------------------
# Test 9
# Invalid collector state must cause collection failure.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/invalid-state.log"
TEST_STATE="${WORK_DIR}/invalid-state.state"

cp "${SCRIPT_DIR}/initial-clean.log" "$TEST_LOG"

cat > "$TEST_STATE" <<EOF
FILE_ID=INVALID
OFFSET=INVALID
EOF

run_collector "$TEST_LOG" "$TEST_STATE"

if [ "$RESULT_RC" -ne 0 ] && [ -z "$RESULT" ]; then
    pass "Invalid State"
else
    fail "Invalid State" \
         "no value, non-zero rc" \
         "value=${RESULT}, rc=${RESULT_RC}"
fi


#
# ----------------------------------------------------------------------
# Test 10
# Missing/unreadable source must cause collection failure.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/does-not-exist.log"
TEST_STATE="${WORK_DIR}/missing-source.state"

run_collector "$TEST_LOG" "$TEST_STATE"

if [ "$RESULT_RC" -ne 0 ] && [ -z "$RESULT" ]; then
    pass "Missing Source"
else
    fail "Missing Source" \
         "no value, non-zero rc" \
         "value=${RESULT}, rc=${RESULT_RC}"
fi


#
# ----------------------------------------------------------------------
# Test 11
# Failed collection must not advance previously committed state.
# ----------------------------------------------------------------------
#

TEST_LOG="${WORK_DIR}/preserve.log"
TEST_STATE="${WORK_DIR}/preserve.state"

cp "${SCRIPT_DIR}/initial-clean.log" "$TEST_LOG"

run_collector "$TEST_LOG" "$TEST_STATE"

if [ "$RESULT_RC" -ne 0 ] || [ "$RESULT" != "0" ]; then
    fail "State Preserved After Failure" \
         "successful bootstrap" \
         "value=${RESULT}, rc=${RESULT_RC}"
else

    STATE_BEFORE="$(cat "$TEST_STATE")"

    mv "$TEST_LOG" "${TEST_LOG}.saved"

    run_collector "$TEST_LOG" "$TEST_STATE"

    STATE_AFTER="$(cat "$TEST_STATE")"

    mv "${TEST_LOG}.saved" "$TEST_LOG"

    if [ "$RESULT_RC" -ne 0 ] &&
       [ -z "$RESULT" ] &&
       [ "$STATE_BEFORE" = "$STATE_AFTER" ]; then
        pass "State Preserved After Failure"
    else
        fail "State Preserved After Failure" \
             "failure with unchanged state" \
             "value=${RESULT}, rc=${RESULT_RC}"
    fi
fi


print
print "Results"
print "======="
print "PASS: ${PASS_COUNT}"
print "FAIL: ${FAIL_COUNT}"
print

if [ "$FAIL_COUNT" -eq 0 ]; then
    print "IFX-HEALTH-003: MOCK VALIDATION PASSED"
    exit 0
fi

print "IFX-HEALTH-003: MOCK VALIDATION FAILED"
exit 1