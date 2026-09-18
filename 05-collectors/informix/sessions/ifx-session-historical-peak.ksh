#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : ifx-session-historical-peak.ksh
# Purpose : Normalize and validate IBM Informix historical session peak output.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

#
# IFX-SESSION-003 — Historical Session Peak
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

#
# Detect explicit mock source execution failure.
#
if grep -q '^EXIT_CODE=' "$INPUT_FILE" 2>/dev/null; then

    EXIT_CODE="$(awk -F= '/^EXIT_CODE=/ {print $2; exit}' "$INPUT_FILE")"

    case "$EXIT_CODE" in
        ''|*[!0-9]*)
            print -u2 "invalid execution status"
            exit 1
            ;;
    esac

    if [ "$EXIT_CODE" -ne 0 ]; then
        print -u2 "source execution failed"
        exit 1
    fi
fi

#
# Extract non-empty lines after trimming surrounding whitespace.
#
VALUE="$(
    awk '
    {
        gsub(/^[[:space:]]+/, "", $0)
        gsub(/[[:space:]]+$/, "", $0)

        if (length($0) > 0) {
            print $0
        }
    }
    ' "$INPUT_FILE"
)"

if [ -z "$VALUE" ]; then
    print -u2 "empty historical session peak"
    exit 1
fi

#
# Exactly one normalized scalar is permitted.
#
VALUE_COUNT="$(
    print -- "$VALUE" |
    awk 'END {print NR}'
)"

if [ "$VALUE_COUNT" -ne 1 ]; then
    print -u2 "multiple historical session peak values"
    exit 1
fi

#
# Historical maximum contract:
# value must be a non-negative integer.
#
# No comparison with previous observations is performed here.
#
case "$VALUE" in
    *[!0-9]*)
        print -u2 "invalid historical session peak"
        exit 1
        ;;
esac

print "$VALUE"
exit 0
