# Serverclass App

This is a Python3 script that allows you to store your Splunk serverlcass.conf configuration in JSON files. It uses [Jinja2](https://jinja2docs.readthedocs.io/) templates to build the configuration file. This is useful to split up the serverclass.conf into separate files that can be source controlled.

### Jinja2 Templates

* [templates/global.jinja](templates/global.jinja) - holds the [global] stanza configurations
* [templates/main.jinja](templates/main.jinja) - imports [global.jinja](templates/main.jinja) and builds each serverlcass and serverclass:app stanzas

### JSON files

These are JSON files but can also have embedded comments using '#', which are stripped before processing. The files can either have a .json extension or not. There are two types of JSON files: section files and serverclass files.

Section files are prefixed with **section-** and contain the following keys:
* **section_comment** - string that will appear above all serverclass stanzas in the section.
* **serverclasses** - array of serverclass JSON file names. These are read by the script and their contents imported to be passed to Jinja [main template](templates/main.jinja).

Serverclass files have no prefix and can be named anything that isn't prefixed with **section-**. They contain the following keys:
* **serverclass_name** - name that is inserted into the serverclass stanza as [serverclass:XXXX]
* **serverclass_comment** - string that appears directly above the serverclass configuration.
* **serverclass_options** - array of options, excepting whitelist.X and blacklist.X, that appear as part of the serverclass stanza (e.g."machineTypesFilter = linux-x86_64").
* **whitelist** - array of whitelist.X items. As part of template processing these are put into sorted order.
* **blacklist** - array of blacklist.X items. As part of template processing these are put into sorted order.
* **serverclass_apps_options** - array of options that appear as part of the serverclass:app stanza. See [jobs-hf.json](test_json/jobs-hf.json) for an example.

### Running
Execute [generate_serverclass_conf.py](generate_serverclass_conf.py) with the following options:
* **--json-config-dir** - path to where the JSON files are stored. Script automatically walks the path looking for files starting with **section-** and processes the serverclasses array inside to find the other JSON configuration files. This option is required.
* **--serverclass-conf-output-dir** - directory to write the resulting serverclass.conf file. This is optional and by default the output is sent to stdout.
