#!/usr/bin/ksh

# ==============================================================================
# Author  : Norba
# Date    : 2026-09-14
# Script  : ifx-health-uptime.ksh
# Purpose : Parse and normalize IBM Informix instance uptime into seconds.
#
# Change Control
# Date    : 2026-09-14
# Author  : Norba
# Change  : Initial version.
# Date    : 2026-09-14
# Author  : Norba
# Change  : Fixed uptime arithmetic expansion.
# Date    : 2026-09-14
# Author  : Norba
# Change  : Renamed SECONDS variable to avoid KornShell reserved special variable.
# ==============================================================================

#
# IFX-HEALTH-002 — Instance Uptime
#
# Input:
#   $1 = file containing stdout from "onstat -"
#
# Output:
#   Non-negative integer representing uptime in seconds.
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
# Require evidence that this is Informix Dynamic Server output.
#
if ! print -- "$OUTPUT" | grep -i "IBM Informix Dynamic Server" >/dev/null 2>&1
then
    print -u2 "invalid Informix output"
    exit 1
fi

#
# Extract:
#
#   Up <days> days <HH>:<MM>:<SS>
#
UPTIME_FIELDS="$(print -- "$OUTPUT" | awk '
{
    for (i = 1; i <= NF; i++) {
        if (tolower($i) == "up" && (i + 3) <= NF) {
            days = $(i + 1)
            unit = $(i + 2)
            time = $(i + 3)

            if (tolower(unit) == "day" || tolower(unit) == "days") {
                print days " " time
                exit
            }
        }
    }
}')"

if [ -z "$UPTIME_FIELDS" ]; then
    print -u2 "unable to extract Informix uptime"
    exit 1
fi

DAYS="$(print -- "$UPTIME_FIELDS" | awk '{print $1}')"
TIME_VALUE="$(print -- "$UPTIME_FIELDS" | awk '{print $2}')"

HOURS="$(print -- "$TIME_VALUE" | awk -F':' '{print $1}')"
MINUTES="$(print -- "$TIME_VALUE" | awk -F':' '{print $2}')"
UPTIME_SECONDS="$(print -- "$TIME_VALUE" | awk -F':' '{print $3}')"

#
# Validate numeric components.
#
case "$DAYS" in
    ''|*[!0-9]*)
        print -u2 "invalid uptime days"
        exit 1
        ;;
esac

case "$HOURS" in
    ''|*[!0-9]*)
        print -u2 "invalid uptime hours"
        exit 1
        ;;
esac

case "$MINUTES" in
    ''|*[!0-9]*)
        print -u2 "invalid uptime minutes"
        exit 1
        ;;
esac

case "$UPTIME_SECONDS" in
    ''|*[!0-9]*)
        print -u2 "invalid uptime seconds"
        exit 1
        ;;
esac

#
# Validate expected ranges.
#
if [ "$HOURS" -gt 23 ]; then
    print -u2 "uptime hours out of range"
    exit 1
fi

if [ "$MINUTES" -gt 59 ]; then
    print -u2 "uptime minutes out of range"
    exit 1
fi

if [ "$UPTIME_SECONDS" -gt 59 ]; then
    print -u2 "uptime seconds out of range"
    exit 1
fi

#
# Normalize to total seconds.
#
TOTAL_SECONDS=$(( \
    (DAYS * 86400) + \
    (HOURS * 3600) + \
    (MINUTES * 60) + \
    UPTIME_SECONDS \
))

print "$TOTAL_SECONDS"
exit 0