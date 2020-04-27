#!/bin/bash

declare -a all_projects

while read proj link ; do
    all_projects+=($proj)
done < "./project_links.txt"
for setup_file in /opt/wd/setup_files/*_setup.sh ; do
    basename=$(basename $setup_file)
    proj=${basename%_setup.sh}
    if [[ ! " ${projects[@]} " =~ " ${proj} " ]]; then
        all_projects+=($proj)
    fi
done

projects=("$@")

for p in "${projects[@]}" ; do
    if [[ ! "${all_projects[@]}" =~ "${p}" ]]; then
        echo "Error: $p is not a valid project name"
        exit 1
    fi
done