#!/usr/bin/env bash

## Meant to work with the zero_buckets.sh script to delete zero event cold buckets

input="${1--}"

HOST="localhost:8089"
SPLUNK_USER="admin"
SPLUNK_PASS="12345678"


AUTH_XML="$(curl --noproxy '*' -sk https://$HOST/services/auth/login -d username=$SPLUNK_USER -d password=$SPLUNK_PASS)"
SESSION_KEY=$(echo "$AUTH_XML" |tr '\n' ' ' |sed 's/.*<sessionKey>\(.*\)<\/sessionKey>.*/\1/')

green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

for i in `cat $input |grep -v bucketId |sed 's/\"//g'`; do
    printf "%-93s" $i
    status=$(curl --noproxy '*' -sk -w "%{http_code}" -H "Authorization: Splunk $SESSION_KEY" -X POST -o /dev/null "https://$HOST/services/cluster/master/buckets/$i/freeze")

    if [ "$status" -ne "200" ]; then
        color="$red"
    else
        color="$green"
    fi

    echo -e "[ $color$status$reset ]"
done

