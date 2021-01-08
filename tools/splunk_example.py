#!/usr/bin/env python

## Basic template for a Python script to interact with a Splunk server

import site, sys

import ssl
if hasattr(ssl, '_create_unverified_context'):
    ssl._create_default_https_context = ssl._create_unverified_context

site.addsitedir('splunk-sdk-python-1.6.13')

## https://github.com/splunk/splunk-sdk-python/releases
import splunklib.client as client
import splunklib.results as results
import splunklib.binding as binding
## https://github.com/splunk/splunk-sdk-python/tree/master/examples

connectionHandler = binding.handler(timeout = 10)

splunk_props = {
    "host": "127.0.0.1",
    "scheme": "https",
    "port": 8089,
    "app": "search",
    "username": "",
    "password": "",
    "handler": connectionHandler
}

try:
    service = client.connect(**splunk_props)
except Exception as e:
    print "Error connecting to the splunk platform : {}".format(str(e))

search = ('search index=main earliest=-15m@m | head 10')

rr = results.ResultsReader(service.jobs.export(search))

for result in rr:
    if isinstance(result, results.Message):
        # Diagnostic messages may be returned in the results - used for DEBUGGING
        print '%s: %s' % (result.type, result.message)
        pass
    elif isinstance(result, dict):
        ## Normal events are returned as OrderedDict
        print result

print "\n"

service.logout()
