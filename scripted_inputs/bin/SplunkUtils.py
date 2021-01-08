import json, os, re, subprocess
from subprocess import PIPE
from time import time, gmtime

samples_dir_name = '../script_samples/bin'

## Make the _time key the first one in the JSON
def to_json_custom(s):
    json_data = json.dumps(s, separators=(',', ':'))

    ## Get _time key from JSON
    m = re.search('("_time":\d+\.\d+),?', json_data)

    if (m is not None):
        ## Remove _time key from JSON
        json_data = re.sub('("_time":\d+\.\d+),?', '', json_data)

        ## Put _time key at head of JSON
        json_data = re.sub('^\{', '{'+m.group(1)+',', json_data)

        ## For cases where _time was at end of JSON, remove training comma
        json_data = re.sub(',\}$', '}', json_data)

    return json_data

## Get unixtime
def getTime():
    return time()

## Create a factory to force a value to a lower and upper bound
##
## pctFactory = forceRangeFactory(0, 100)
## pctFactory(-1)   ## returns 0
def forceRangeFactory(lower, upper):
    def factory(val):
        if (val < lower):
            return lower
        elif (val > upper):
            return upper

        return val

    return factory

def getPctRangeFactory(): return forceRangeFactory(0, 100)

## Formats string from CamelCase to underscores
def format_as_underscore(name):
    name = re.sub("\((\w)", lambda m: m.group(1).upper(), name)
    name = re.sub("_|\)", "", name)
    name = re.sub("(\d)([A-Z])", lambda m: m.group(1) + m.group(2).lower(), name)

    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

## Determine if a line is blank; line can be either a str or list
def isblank(line):
    if not isinstance(line, str):
        line = "".join(str(line))

    return not bool(len(line))

## Get the directory a script is running from
_scriptDirectory = os.path.dirname(os.path.realpath(__file__))
def _getScriptDirectory():
    return _scriptDirectory

## Get the samples directory
def _getSamplesDirectory():
    return "%s/%s" % (_getScriptDirectory(), samples_dir_name)

## Get the running script's sample file location
_my_name = os.path.basename(__file__)
_my_names = [_my_name, "%sc" % _my_name]
def _getScriptSampleFilename(sample):
    import inspect

    filename = None
    frame = inspect.currentframe()

    try:
        filename = os.path.basename(inspect.getsourcefile(frame.f_back.f_back))
        filename = "%s/%s.sample%d" % (_getSamplesDirectory(), os.path.splitext(filename)[0], sample)
    finally:
        del frame

    print(filename)

    if filename is not None and os.path.exists(filename):
        return filename
    else:
        return None

## Run command with given args anf kwargs
def runCommand(args, **kwargs):
    ## Set up defaults if not specified in kwargs
    kwargs.setdefault('stdout', PIPE)
    kwargs.setdefault('stdin', PIPE)
    kwargs.setdefault('stderr', subprocess.STDOUT)

    sample = kwargs.pop('sample', False)

    ## Do we want to run with sample data instead of the real command?
    if sample is not False:
        return open(_getScriptSampleFilename(sample), 'rb')
    else:
        p = subprocess.Popen(args, **kwargs)
        return p.stdout


