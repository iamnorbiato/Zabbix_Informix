#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-15
# Script  : ifx-session-waiting-by-reason.ksh
# Purpose : Normalize and validate IBM Informix waiting threads by reason dataset.
#
# Change Control
# Date    : 2026-09-15
# Author  : Norba
# Change  : Initial version.
# ==============================================================================

#
# IFX-SESSION-005 — Waiting Threads by Reason
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
# Empty file is a valid successful dataset containing zero wait reasons.
#
if [ ! -s "$INPUT_FILE" ]; then
    exit 0
fi

#
# Validate the complete dataset before emitting anything.
#
NORMALIZED="$(
    awk -F'|' '
    function trim(value) {
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        return value
    }

    BEGIN {
        failed = 0
    }

    {
        if (NF != 3) {
            failed = 1
            next
        }

        reason_id = trim($1)
        reason_name = trim($2)
        count = trim($3)

        if (reason_id == "") {
            failed = 1
            next
        }

        if (reason_name == "") {
            failed = 1
            next
        }

        if (count !~ /^[0-9]+$/) {
            failed = 1
            next
        }

        if (seen[reason_id]++) {
            failed = 1
            next
        }

        rows[++row_count] = reason_id "|" reason_name "|" count
    }

    END {
        if (failed) {
            exit 1
        }

        for (i = 1; i <= row_count; i++) {
            print rows[i]
        }
    }
    ' "$INPUT_FILE"
)"

PARSE_RC=$?

if [ "$PARSE_RC" -ne 0 ]; then
    print -u2 "invalid waiting threads by reason dataset"
    exit 1
fi

#
# Emit only after complete dataset validation succeeds.
#
if [ -n "$NORMALIZED" ]; then
    print -- "$NORMALIZED"
fi

exit 0
