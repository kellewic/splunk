#!/bin/env bash
. "$(dirname $(readlink -fn $0))/common.sh"

TIME="$(getTime)"

MEM_TOTAL=$((($(cat /proc/meminfo |grep MemTotal|sed 's/ *.*: *\([0-9]*\) *.*/\1/'|tr -d '[[:space:]]'))*1024))
CPUS=$((($(cat /proc/cpuinfo |grep processor|tail -n1|cut -d':' -f2|tr -d '[[:space:]]'))+1))
DISK=$((($(df --total -kl|grep total|sed 's/^total *\([0-9]*\) *.*/\1/'|tr -d '[[:space:]]'))*1024))

echo "{\"_time\":$TIME,\"mem_total_bytes\":$MEM_TOTAL,\"cpus\":$CPUS,\"disk_total_bytes\":$DISK}"

