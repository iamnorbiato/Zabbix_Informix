#!/bin/ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : test-ifx-lock-maximum-wait-time.ksh
# Purpose : Validate IFX-LOCK-002 parser against the governed mock dataset.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

PARSER="${SCRIPT_DIR}/../../../05-collectors/informix/locks/ifx-lock-maximum-wait-time.ksh"

PASS=0
FAIL=0

run_success()
{
    MOCK="$1"
    EXPECTED="$2"

    OUTPUT=$("$PARSER" "${SCRIPT_DIR}/${MOCK}.txt" 2>/dev/null)
    RC=$?

    if [ "$RC" -eq 0 ] && [ "$OUTPUT" = "$EXPECTED" ]; then
        print "PASS: ${MOCK}"
        PASS=$((PASS + 1))
    else
        print "FAIL: ${MOCK} expected rc=0 stdout='${EXPECTED}' got rc=${RC} stdout='${OUTPUT}'"
        FAIL=$((FAIL + 1))
    fi
}

run_failure()
{
    MOCK="$1"

    OUTPUT=$("$PARSER" "${SCRIPT_DIR}/${MOCK}.txt" 2>/dev/null)
    RC=$?

    if [ "$RC" -ne 0 ] && [ -z "$OUTPUT" ]; then
        print "PASS: ${MOCK}"
        PASS=$((PASS + 1))
    else
        print "FAIL: ${MOCK} expected rc!=0 stdout empty got rc=${RC} stdout='${OUTPUT}'"
        FAIL=$((FAIL + 1))
    fi
}

run_success normal 45
run_success zero 0
run_success single-second 1
run_success long 3600
run_success lower 8

run_failure empty
run_failure nonnumeric
run_failure negative
run_failure decimal
run_failure execution-error

print
print "PASS: ${PASS}"
print "FAIL: ${FAIL}"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
