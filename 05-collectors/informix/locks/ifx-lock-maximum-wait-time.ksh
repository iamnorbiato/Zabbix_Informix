#!/bin/ksh
# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : ifx-lock-maximum-wait-time.ksh
# Purpose : Validate normalized maximum current lock wait time in seconds.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

if [ "$#" -ne 1 ]; then
    print -u2 "Usage: $0 <input-file>"
    exit 1
fi

INPUT_FILE="$1"

if [ ! -r "$INPUT_FILE" ]; then
    print -u2 "Input file is not readable: $INPUT_FILE"
    exit 1
fi

# Detect explicit collection execution failure used by the mock contract.
EXIT_CODE_LINE=$(grep '^EXIT_CODE=' "$INPUT_FILE" 2>/dev/null)

if [ -n "$EXIT_CODE_LINE" ]; then
    EXIT_CODE=${EXIT_CODE_LINE#EXIT_CODE=}

    case "$EXIT_CODE" in
        ''|*[!0-9]*)
            print -u2 "Invalid EXIT_CODE in input"
            exit 1
            ;;
    esac

    if [ "$EXIT_CODE" -ne 0 ]; then
        print -u2 "Collection execution failed with exit code $EXIT_CODE"
        exit 1
    fi
fi

if [ ! -s "$INPUT_FILE" ]; then
    print -u2 "Empty input"
    exit 1
fi

VALUE=$(
    awk '
    {
        line = $0

        sub(/^[[:space:]]+/, "", line)
        sub(/[[:space:]]+$/, "", line)

        if (line == "")
            next

        count++

        if (count > 1)
            invalid = 1

        if (line !~ /^[0-9]+$/)
            invalid = 1

        value = line
    }

    END {
        if (count != 1 || invalid)
            exit 1

        print value
    }
    ' "$INPUT_FILE"
)

RC=$?

if [ "$RC" -ne 0 ] || [ -z "$VALUE" ]; then
    print -u2 "Invalid maximum lock wait time"
    exit 1
fi

print -- "$VALUE"
exit 0
