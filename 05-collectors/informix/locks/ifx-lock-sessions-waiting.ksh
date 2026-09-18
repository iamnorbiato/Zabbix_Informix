#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : ifx-lock-sessions-waiting.ksh
# Purpose : Normalize and validate the Informix sessions waiting for locks metric.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

#
# IFX-LOCK-001 — Sessions Waiting for Locks
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
# A successful scalar collection must contain one value.
#
if [ ! -s "$INPUT_FILE" ]; then
    print -u2 "empty sessions waiting for locks result"
    exit 1
fi

NORMALIZED="$(
    awk '
    function trim(value) {
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        return value
    }

    BEGIN {
        count = 0
        failed = 0
    }

    {
        value = trim($0)

        if (value == "") {
            failed = 1
            next
        }

        count++

        if (count > 1) {
            failed = 1
            next
        }

        if (value !~ /^[0-9]+$/) {
            failed = 1
            next
        }

        normalized = value
    }

    END {
        if (failed || count != 1) {
            exit 1
        }

        print normalized
    }
    ' "$INPUT_FILE"
)"

PARSE_RC=$?

if [ "$PARSE_RC" -ne 0 ]; then
    print -u2 "invalid sessions waiting for locks result"
    exit 1
fi

print -- "$NORMALIZED"

exit 0
