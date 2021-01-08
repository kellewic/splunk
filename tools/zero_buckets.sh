#!/usr/bin/env bash

## Find all cold buckets that have no events

HOST="localhost:8089"
SPLUNK_USER="admin"
SPLUNK_PASS="12345678"

AUTH_XML="$(curl --noproxy '*' -sk https://$HOST/services/auth/login -d username=$SPLUNK_USER -d password=$SPLUNK_PASS)"
SESSION_KEY=$(echo "$AUTH_XML" |tr '\n' ' ' |sed 's/.*<sessionKey>\(.*\)<\/sessionKey>.*/\1/')

read -r -d '' SEARCH << END
|dbinspect [|rest /services/data/indexes |dedup title |where isVirtual=0 |rename title as index |table index |format "" "" " " "" " " ""]
|fields bucketId, state, eventCount
|where state="cold"
|stats sum(eventCount) as eventCount by bucketId
|where eventCount=0
|table bucketId
END

OUTPUT="${1}_cold_zero_buckets.txt"

curl --noproxy '*' -sk -H "Authorization: Splunk $SESSION_KEY" "https://$HOST/services/search/jobs/export" \
    --data-urlencode search="$SEARCH" \
    -d 'output_mode=csv&enable_lookups=false&earliest_time=0' \
    |tail -n+2 \
    |tr -d '"' \
    >"$OUTPUT"

