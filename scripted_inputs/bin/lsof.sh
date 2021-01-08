#!/bin/bash
. "$(dirname $(readlink -fn $0))/common.sh"

TIME="$(getTime)"

for line in `lsof -nPs |tail -n+2 |grep -v 'Permission denied' |awk '{ print $2 }' |uniq -c |sed 's/^ *//g' |awk '{print "\"pid\":"$2",\"count\":"$1}'`; do
    echo "{\"_time\":$TIME,$line}"
done

