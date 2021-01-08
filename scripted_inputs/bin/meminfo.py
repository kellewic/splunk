#!/usr/bin/env python

import os.path, re, site

from SplunkUtils import to_json_custom, getTime, format_as_underscore

data = dict(_time=getTime())

with open('/proc/meminfo', 'r') as f:
    for line in f.read().split("\n"):
        m = re.match("^(.*?):\s*(\d+)", line)
        if (m is not None):
            data[format_as_underscore(m.group(1))] = int(m.group(2))/1024

buffers_cache = data['buffers'] + data['cached']

## Make like the free output for backwards compat
data['total_mem'] = data.pop('mem_total')
data['free_mem'] = data.pop('mem_free')
data['used_mem'] = data['total_mem'] - data['free_mem']
data['shared'] = 0
data['buff_adj_used'] = data['used_mem'] - buffers_cache
data['buff_adj_free'] = data['free_mem'] + buffers_cache
data['total_swap'] = data.pop('swap_total')
data['free_swap'] = data.pop('swap_free')
data['used_swap'] = data['total_swap'] - data['free_swap']

print(to_json_custom(data))

