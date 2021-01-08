#!/usr/bin/env bash

HOST="localhost:8089"
USER="admin"
PASS="12345678"

AUTH_XML="$(curl --noproxy '*' -sk https://$HOST/services/auth/login -d username=$USER -d password=$PASS)"
SESSION_KEY=$(echo "$AUTH_XML" |tr '\n' ' ' |sed 's/.*<sessionKey>\(.*\)<\/sessionKey>.*/\1/')

echo $SESSION_KEY

## $SESSION_KEY can then be used in subsequent curl calls like so:
##
## curl --noproxy '*' -sk -H "Authorization: Splunk $SESSION_KEY" "https://$HOST//services/deployment/server/applications"

