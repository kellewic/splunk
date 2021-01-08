#!/bin/bash
. "$(dirname $(readlink -fn $0))/common.sh"

TIME="$(getTime)"
pids="$(ps -ef|wc -l)"

echo "{\"_time\":$TIME,\"pids\":$pids}"

