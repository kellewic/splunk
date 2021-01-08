#!/bin/bash

. "$(dirname $(readlink -fn $0))/common.sh"

declare -a LOADAVG=( $(< /proc/loadavg) );

output_json \
    "_time" "$(getTime)" \
    "oneMin" "${LOADAVG[0]}" \
    "fiveMin" "${LOADAVG[1]}" \
    "fifteenMin" "${LOADAVG[2]}"

