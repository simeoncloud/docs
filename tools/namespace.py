import json
import os

with open('./ResourceNamespaceInfo.json', 'r') as f:
    original = json.load(f)

for root, subdirs, files in os.walk('../Baseline/Source/Resources/Content'):
    # for each file
    # print(root)
    for filename in files:
        split_path = os.path.splitext(filename)
        if split_path[1] != '.json':
            continue

        if split_path[0] != 'Configuration':
            continue

        relpath = os.path.relpath(root, '../Baseline/Source/Resources/Content')
        components = relpath.split('/')
        namespace = ':'.join(components)
        print(f'Adding isDeletable to {namespace}')

        # inefficient but whatever
        for i in range(len(original)):
            if original[i]['Namespace'] == namespace:
                original[i]['isDeletable'] = False
                break


with open('./ResourceNamespaceInfo.new.json', 'w') as f:
    # original file is indented with two spaces instead of a tab
    json.dump(original, f, indent='  ')