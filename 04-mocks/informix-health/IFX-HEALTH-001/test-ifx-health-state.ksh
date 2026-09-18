#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : test-ifx-health-state.ksh
# Purpose : Validate IFX-HEALTH-001 parser behavior against its mock inputs.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

PARSER="${PROJECT_ROOT}/05-collectors/informix/health/ifx-health-state.ksh"

PASS=0
FAIL=0

run_state_test()
{
    TEST_NAME="$1"
    MOCK_FILE="$2"
    EXPECTED_VALUE="$3"
    EXPECTED_EXIT="$4"

    OUTPUT="$("${PARSER}" "${SCRIPT_DIR}/${MOCK_FILE}" 2>/dev/null)"
    EXIT_CODE=$?

    if [ "${OUTPUT}" = "${EXPECTED_VALUE}" ] &&
       [ "${EXIT_CODE}" -eq "${EXPECTED_EXIT}" ]
    then
        print "PASS  ${TEST_NAME}"
        PASS=$((PASS + 1))
    else
        print "FAIL  ${TEST_NAME}"
        print "      expected value: ${EXPECTED_VALUE}"
        print "      actual value  : ${OUTPUT}"
        print "      expected exit : ${EXPECTED_EXIT}"
        print "      actual exit   : ${EXIT_CODE}"

        FAIL=$((FAIL + 1))
    fi
}

run_failure_test()
{
    TEST_NAME="$1"
    MOCK_FILE="$2"

    OUTPUT="$("${PARSER}" "${SCRIPT_DIR}/${MOCK_FILE}" 2>/dev/null)"
    EXIT_CODE=$?

    if [ "${EXIT_CODE}" -eq 1 ] && [ -z "${OUTPUT}" ]
    then
        print "PASS  ${TEST_NAME}"
        PASS=$((PASS + 1))
    else
        print "FAIL  ${TEST_NAME}"
        print "      expected      : COLLECTION_FAILURE"
        print "      actual value  : ${OUTPUT}"
        print "      actual exit   : ${EXIT_CODE}"

        FAIL=$((FAIL + 1))
    fi
}

print "IFX-HEALTH-001 Mock Validation"
print "=============================="

run_state_test "Online"        "online.txt"        "4"  0
run_state_test "Quiescent"     "quiescent.txt"     "3"  0
run_state_test "Recovery"      "recovery.txt"      "2"  0
run_state_test "Down"          "down.txt"          "0"  0
run_state_test "Unknown State" "unknown-state.txt" "99" 0

run_failure_test "Malformed Output" "malformed.txt"
run_failure_test "Execution Error"  "execution-error.txt"

print
print "Results"
print "======="
print "PASS: ${PASS}"
print "FAIL: ${FAIL}"

if [ "${FAIL}" -eq 0 ]
then
    print
    print "IFX-HEALTH-001: MOCK VALIDATION PASSED"
    exit 0
fi

print
print "IFX-HEALTH-001: MOCK VALIDATION FAILED"
exit 1