#!/usr/bin/env bash

## Find and remove excess buckets from Splunk indexes

TMP_FILE="/tmp/excess_buckets.sh.tmp"

echo "START" > $TMP_FILE
echo `date` >> $TMP_FILE

## Use an indexer so we know we'll get all indexes
HOST="indexer1:8089"
SUDO_USER="sudo_user"
SPLUNK_BIN="/opt/splunk/bin/splunk"
SPLUNK_USER="admin"
SPLUNK_PASS="12345678"

## Get session token from Splunk
AUTH_XML="$(curl --noproxy '*' -sk https://$HOST/services/auth/login -d username=$SPLUNK_USER -d password=$SPLUNK_PASS)"
SESSION_KEY=$(echo "$AUTH_XML" |tr '\n' ' ' |sed 's/.*<sessionKey>\(.*\)<\/sessionKey>.*/\1/')

echo "GOT SESSION" >> $TMP_FILE

## Get all index names
IDXS=$(curl --noproxy '*' -sk -H "Authorization: Splunk $SESSION_KEY" "https://$HOST/services/data/indexes?count=-1" |grep '<title>' |sed 's/ *<title>\(.*\)<\/title> */\1/' |sort -u)

echo "" >> $TMP_FILE
echo $IDXS >> $TMP_FILE
echo "" >> $TMP_FILE

for index in ${IDXS[@]}; do
    ## Check index for excess buckets
    if sudo -u $SUDO_USER $SPLUNK_BIN list excess-buckets $index -auth ${SPLUNK_USER}:$SPLUNK_PASS |grep excess |grep -v '=0' &>/dev/null; then
        echo "$index has excess buckets" | tee -a $TMP_FILE
        sudo -u $SUDO_USER $SPLUNK_BIN remove excess-buckets $index -auth ${SPLUNK_USER}:$SPLUNK_PASS |tee -a $TMP_FILE
    else
        echo "No excess buckets for $index" >> $TMP_FILE
    fi
done

echo "DONE" >> $TMP_FILE
echo `date` >> $TMP_FILE

