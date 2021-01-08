#!/bin/bash 
. "$(dirname $(readlink -fn $0))/common.sh"

## Get processes using swap
for DIR in `find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+"`
do
    PID=${DIR##/proc/}

    PROGNAME=`cat /proc/$PID/comm 2>/dev/null`
    [ $? == 1 ] && continue

    SWAP=$((`grep -m1 VmSwap $DIR/status 2>/dev/null | awk '{ print $2 }'`+0))
    [ $SWAP -eq 0 ] && continue

    d="$(date +'%s.%3N')"
    echo "{\"_time\":$d,\"pid\":$PID,\"swapped_kb\":$SWAP,\"comm\":\"$PROGNAME\"}"
done

