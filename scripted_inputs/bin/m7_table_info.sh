#!/bin/env bash

## This script finds all M7 tables at a given mount point
## and determines how many Perl processes are needed to
## process them all more quickly than sequential.

MY_DIR="$(dirname $(readlink -fn $0))"
SCRIPT="m7_table_info.pl"
LOCK_FILE="/tmp/m7_table_info.lock"
TABLES_FILE="/tmp/m7_table_info_targets.txt"
OUTPUT_DIR="/tmp/splunk_m7_table_output"
NUM_PROCESSES=${1-10}
START_INDEX=0
RUNID=$(date +"%s")
PROD=1

## Prevent script from spawning itself a bunch of times
if [ -e $LOCK_FILE ]; then
    ## Check if script is running
    ps ax |grep "/bin/m7_table_info" |grep -Ev "(grep|$$)" &>/dev/null

    if [ $? -eq 0 ]; then
        >&2 echo "INFO Lock file exists; script is running; exiting"
        exit 1
    else
        >&2 echo "INFO Lock file exists; script not running; removing lock file"
        rm -f $LOCK_FILE
    fi
fi

touch $LOCK_FILE

## Remove lock file when script exits
trap "{ rm -f $LOCK_FILE ; }" EXIT

[ ! -e $OUTPUT_DIR ] && mkdir $OUTPUT_DIR

if [ $PROD -eq 1 ]; then ## This line is for testing outside of an M7 host
    find /mountpoint -type d \( \
        -path /mountpoint/pigtemp \
        -o -path /mountpoint/mirror \
        -o -path /mountpoint/Mysql_Backups \
        -o -path /mountpoint/admin \
        -o -path /mountpoint/admins \
        -o -path /mountpoint/apptests \
        -o -path /mountpoint/hivequerylogs \
        -o -path /mountpoint/hivescratch \
        -o -path /mountpoint/mysqljob \
        -o -path /mountpoint/utilities \
        -o -path /mountpoint/benchmarktest \
    \) -prune \
    -o -type l -ls |grep 'mapr::table' |awk '{print $11}' >$TABLES_FILE
fi

if [ -e $TABLES_FILE -a -s $TABLES_FILE ]; then
    ## Determine how many tables we need to scan
    num_tables=$(wc -l $TABLES_FILE |cut -d ' ' -f1)

    ## If number of tables is fewer than number of processes; reduce number of processes
    if [ $num_tables -lt $NUM_PROCESSES ]; then
        NUM_PROCESSES=$num_tables
    fi

    ## Determine how many extra tables there are so we can spread them evenly over the processes
    extra=$(($num_tables % $NUM_PROCESSES))

    ## Determine how many tables to assign to each process
    num_assign=$(($num_tables/$NUM_PROCESSES))

    >&2 echo "INFO num_tables = $num_tables"
    >&2 echo "INFO num_processes = $NUM_PROCESSES"
    >&2 echo "INFO num_assign = $num_assign"
    >&2 echo "INFO extra = $extra"

    ## Assign each process a range of tables by start and end indexes
    for ((i = 1; i <= $NUM_PROCESSES; i++)); do
        ## If 0 then we didn't add an extra table; if 1 then we did
        adjust_start=0

        ## Assign extra tables evenly across as many processes as necessary
        if [ $extra -gt 0 ]; then
            END_INDEX=$(($START_INDEX + $num_assign))
            extra=$(($extra - 1))
            adjust_start=1
        else
            END_INDEX=$(($START_INDEX + $num_assign - 1))
        fi

        ## Fire off each Perl script in the background
        >&2 echo "INFO Spawning process #${i} with items $START_INDEX to $END_INDEX"
        { $MY_DIR/$SCRIPT $START_INDEX $END_INDEX $RUNID ; } &

        ## Adjust start index for next loop
        START_INDEX=$(($START_INDEX + $num_assign + $adjust_start))
    done

    ## Let Perl processes finish their tasks
    wait

    if [ $? -ne 0 ]; then
        >&2 echo "Wait exited with code $?"
    fi

    ## Get output from Perl script processes and send to Splunk
    for file in "$OUTPUT_DIR"/*; do
        cat $file
        rm -f $file
    done
fi

