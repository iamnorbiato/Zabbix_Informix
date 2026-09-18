#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : ifx-health-state.ksh
# Purpose : Parse and normalize the IBM Informix instance operational state.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

#
# IFX-HEALTH-001 — Instance State
#
# Input:
#   $1 = file containing stdout from "onstat -"
#
# Output:
#   0  = Down          (mock/provisional)
#   1  = Shutdown      (reserved; not implemented)
#   2  = Recovery
#   3  = Quiescent
#   4  = Online
#   99 = Unknown
#
# Exit codes:
#   0 = metric successfully determined
#   1 = collection/parsing failure
#


if [ "$#" -ne 1 ]; then
    print -u2 "usage: $0 <input-file>"
    exit 1
fi

INPUT_FILE="$1"

if [ ! -r "$INPUT_FILE" ]; then
    print -u2 "input file is not readable: $INPUT_FILE"
    exit 1
fi

OUTPUT="$(cat "$INPUT_FILE")"

if [ -z "$OUTPUT" ]; then
    print -u2 "empty input"
    exit 1
fi

#
# Provisional mock rule.
#
# This must NOT be considered production-safe until validated
# against a real Informix/AIX environment.
#
if print -- "$OUTPUT" | grep -i "cannot attach to shared memory" >/dev/null 2>&1
then
    print "0"
    exit 0
fi

#
# A valid state-bearing response must look like an Informix
# Dynamic Server banner.
#
if ! print -- "$OUTPUT" | grep -i "IBM Informix Dynamic Server" >/dev/null 2>&1
then
    print -u2 "invalid Informix output"
    exit 1
fi

#
# The current mock format uses:
#
#   ... -- STATE -- Up ...
#
# Extract the state between the first and second "--".
#
STATE="$(print -- "$OUTPUT" | awk -F'--' 'NF >= 3 {
    value=$2
    gsub(/^[ \t]+/, "", value)
    gsub(/[ \t]+$/, "", value)
    print value
    exit
}')"

if [ -z "$STATE" ]; then
    print -u2 "unable to extract Informix state"
    exit 1
fi

STATE_NORMALIZED="$(print -- "$STATE" | tr '[:upper:]' '[:lower:]')"

case "$STATE_NORMALIZED" in
    "on-line")
        print "4"
        exit 0
        ;;

    "quiescent")
        print "3"
        exit 0
        ;;

    "fast recovery")
        print "2"
        exit 0
        ;;

    *)
        print "99"
        exit 0
        ;;
esac