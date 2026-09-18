#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : test-ifx-health-uptime.ksh
# Purpose : Validate IFX-HEALTH-002 parser behavior against its mock inputs.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

PARSER="${PROJECT_ROOT}/05-collectors/informix/health/ifx-health-uptime.ksh"

PASS=0
FAIL=0

run_value_test()
{
    TEST_NAME="$1"
    MOCK_FILE="$2"
    EXPECTED_VALUE="$3"

    OUTPUT="$("${PARSER}" "${SCRIPT_DIR}/${MOCK_FILE}" 2>/dev/null)"
    EXIT_CODE=$?

    if [ "${OUTPUT}" = "${EXPECTED_VALUE}" ] &&
       [ "${EXIT_CODE}" -eq 0 ]
    then
        print "PASS  ${TEST_NAME}"
        PASS=$((PASS + 1))
    else
        print "FAIL  ${TEST_NAME}"
        print "      expected value: ${EXPECTED_VALUE}"
        print "      actual value  : ${OUTPUT}"
        print "      expected exit : 0"
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

print "IFX-HEALTH-002 Mock Validation"
print "=============================="

run_value_test "Multi-Day"                "multi-day.txt"                 "10643530"
run_value_test "Single-Day"               "single-day.txt"                "86401"
run_value_test "Near-Zero"                "near-zero.txt"                 "197"
run_value_test "Quiescent"                "quiescent.txt"                 "477015"
run_value_test "Different Version/Memory" "different-version-memory.txt" "176523"

run_failure_test "Malformed Uptime" "malformed-uptime.txt"
run_failure_test "Missing Uptime"   "missing-uptime.txt"

print
print "Results"
print "======="
print "PASS: ${PASS}"
print "FAIL: ${FAIL}"

if [ "${FAIL}" -eq 0 ]
then
    print
    print "IFX-HEALTH-002: MOCK VALIDATION PASSED"
    exit 0
fi

print
print "IFX-HEALTH-002: MOCK VALIDATION FAILED"
exit 1