#!/bin/bash

declare -a all_projects

# Reading all available projects
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

# Checking if arguments are valid projects or not
for p in "${projects[@]}" ; do
    if [[ ! "${all_projects[@]}" =~ "${p}" ]]; then
        echo "TestEnv Error: $p is not a valid project name"
        exit 1
    fi
done