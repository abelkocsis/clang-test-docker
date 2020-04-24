#!/bin/bash

projects_string="${@}"

IFS=',' read -ra projects <<< "$projects_string"

if [ -z "$projects" ]; then
    echo "Error: You must add at least one project!"
    exit 1
fi
if [ ! -f "./project_links.txt" ]; then
    echo "Error: project_links.txt file not found!"
    exit 2
fi
if [ ! -d "./requirements" ]; then
    echo "Error: requirements folder not found!"
    exit 3
fi

projects+=( "codechecker" )
if [ "$projects" == "all" ]; then
    unset projects
    while read proj link
    do
        projects+=($proj)
    done < "./project_links.txt"

fi

for p in "${projects[@]}"
do
    echo "Install dependencies for $p project..."
    if [ -f "./requirements/"$p"_custom_deps_debian.sh" ]; then
        echo "Custom setup for $p: ./requirements/"$p"_custom_deps_debian.sh"
        bash "./requirements/"$p"_custom_deps_debian.sh"
    elif [ ! -f "./requirements/"$p"_debian.txt" ]; then
        echo "Warning: " "./requirements/"$p"_debian.txt" "not exist! Make sure that you set up the " "./requirements/"$p"_debian.txt" "correctly or the project has no dependencies!"
    else
        cat "./requirements/"$p"_debian.txt" | xargs apt-get -yqq install
    fi
done