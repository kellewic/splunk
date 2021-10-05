import argparse, json, os, re, sys

serverclass_conf = "serverclass.conf"
my_dir = os.path.dirname(os.path.realpath(__file__))
template_dir = os.path.join(my_dir, "templates")
main_template = "main.jinja"

## add path for templating library
templating_path = os.path.join(my_dir, "jinja", "src")
sys.path.insert(0, templating_path)
from jinja2 import Environment, FileSystemLoader

## parse options
arg_parser = argparse.ArgumentParser()
arg_parser.add_argument(
    "--json-config-dir",
    help="Directory where the JSON configuration files are stored",
    required=True
)
arg_parser.add_argument(
    "--serverclass-conf-output-dir",
    help="Directory where the serverclass.conf output will be written"
)
(args, params) = arg_parser.parse_known_args()

json_config_dir = args.json_config_dir
serverclass_conf_output_dir = args.serverclass_conf_output_dir
serverclass_conf_output_file = sys.stdout

## input cleanup and check that paths exist
json_config_dir = re.sub('/+$', "", args.json_config_dir)

if not os.path.exists(json_config_dir):
    raise FileNotFoundError("JSON configuration files directory {} does not exist".format(json_config_dir))

if serverclass_conf_output_dir is not None:
    serverclass_conf_output_dir = re.sub('/(?:\w+\.conf)?$', "", args.serverclass_conf_output_dir)

    if not os.path.exists(serverclass_conf_output_dir):
        raise FileNotFoundError("{} output directory {} does not exist".format(serverclass_conf, serverclass_conf_output_dir))

    serverclass_conf_output_file = os.path.join(serverclass_conf_output_dir, serverclass_conf)


## strip comments from JSON file
def strip_comments(fd):
    return re.sub('\s*#+.*', "", fd.read())

## process section JSON files
sections = []
files_not_found = []

for dirpath, dirnames, filenames in os.walk(json_config_dir):
    for fname in filenames:
        if fname.startswith("section-"):
            fpath = os.path.join(dirpath, fname)

            with open(fpath, 'r', encoding='utf-8') as fd:
                serverclasses = []
                section = json.loads(strip_comments(fd))

                for serverclass in section["serverclasses"]:
                    serverclass_path = os.path.join(dirpath, serverclass)

                    ## allow serverclass JSON file with or without the .json extension
                    if not os.path.exists(serverclass_path):
                        serverclass_path = "{}.json".format(serverclass_path)

                    if not os.path.exists(serverclass_path):
                        files_not_found.append(serverclass_path)
                        continue

                    with open(serverclass_path, 'r', encoding='utf-8') as sc_fd:
                        serverclasses.append(json.loads(strip_comments(sc_fd)))

                section["serverclasses"] = serverclasses
                sections.append(section)

## output file processing issues
if len(files_not_found) > 0:
    sys.stderr.write("The following files were not found for processing:\n")
    for f in files_not_found:
        print(f)
    sys.exit(1)

## send sections to template engine
env = Environment(
    loader=FileSystemLoader(template_dir),
    trim_blocks=True,
    lstrip_blocks=True
)

## output processed serverclass.conf
env.get_template(main_template).stream(sections=sections).dump(serverclass_conf_output_file)

