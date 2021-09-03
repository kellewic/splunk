#!/usr/bin/env python3

import site

## Add the Splunk SDK path to our import search path
## so we don't have to install the SDK on the server
site.addsitedir("./splunk-sdk-python-1.6.16")

import splunklib.client as client
import splunklib.results as results

host="localhost"
username="admin"
password=""
app="search"

service = client.connect(host=host, port=8089, app=app, username=username, password=password)

search = '''
| rest /services/search/jobs
| fields - fieldMetadata*, custom*, performance*

| where isRealTimeSearch=0 AND isDone=0
| where 'eai:acl.app' != ""
| where NOT match(label, "^_ACCELERATE_DM_")
| where runDuration >= 3600

| table sid, eai:acl.app, label, dispatchState, runDuration
'''

rr = results.ResultsReader(service.jobs.export(search))

for result in rr:
    if isinstance(result, results.Message):
        #print("{}: {}".format(result.type, result.message))
        pass

    elif isinstance(result, dict):
        sid = result['sid']

        job = client.Job(service, sid)
        job.cancel()

service.logout()
