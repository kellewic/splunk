#!/usr/bin/env python

import os.path, site, sys

mydir = os.path.dirname(os.path.realpath(__file__))
site.addsitedir("%s/../../Amex-imdp-python-modules" % mydir)

from SplunkUtils import to_json_custom, getTime, getPctRangeFactory, runCommand

args = ['iostat', '-ykx', '60', '1']
p_stdout = runCommand(args)

keys = ["read_req_merged/s", "write_req_merged/s", "read_req/s", "write_req/s",
        "read_B/s", "write_B/s", "avg_req_size", "avg_queue_size", "await",
        "svctm", "%util"]

forcePct = getPctRangeFactory()

for line in p_stdout:
    if line.startswith('sd'):
        iostats = line.split()
        iodisk = dict(_time=getTime(), disk=iostats[0])
        iodisk.update(map(None, keys, [int(float(x)) for x in iostats[1:]]))

        iodisk["read_B/s"] = iodisk["read_B/s"] * 1024
        iodisk["write_B/s"] = iodisk["write_B/s"] * 1024
        iodisk["%util"] = forcePct(iodisk["%util"])

        print to_json_custom(iodisk)

