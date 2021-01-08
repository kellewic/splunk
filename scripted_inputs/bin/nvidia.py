#!/usr/bin/env python

import os.path, re, site, sys

from SplunkUtils import getTime, runCommand, isblank, to_json_custom

args = ['nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.total,memory.free,temperature.gpu,serial --format=csv,noheader']
lines = []

try:
    p_stdout = runCommand(args, shell=True)
    lines = [line.strip() for line in p_stdout]
except Exception as e:
    sys.stderr.write("ERROR {0}\n".format(str(e)))
    sys.exit()

event_time = getTime()

for line in lines:
    line = str(line)
    if isblank(line): continue
    if re.search('nvidia-smi:\s*command not found', line):
        sys.stderr.write("WARN nvidia-smi command not found\n")
        break

    line = re.sub('[\n %]', '', line)
    stats = line.split(',')

    print(to_json_custom({
        '_time': event_time,
        'gpu': stats[0],
        'mem': stats[1],
        'total_mem': stats[2],
        'free_mem': stats[3],
        'temp': stats[4],
        'serial': stats[5]
    }))

