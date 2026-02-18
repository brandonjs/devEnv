#!/Library/Frameworks/Python.framework/Versions/3.6/bin/python3

import yaml
import json

with open("./build/sam/template.yml", "r") as yaml_in, open("./build/sam/template.json", "w") as json_out:
    yaml_object = yaml.safe_load(yaml_in)
    json.dump(yaml_object, json_out)


