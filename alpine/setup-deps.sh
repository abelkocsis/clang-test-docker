#!/bin/bash

setup=false
run=false

if [ "$1" == "TRUE" ];
then
    setup=true
fi

if [ "$2" == "TRUE" ];
then
    run=true
fi

projects_string="${@:3}"

if $setup; then
    IFS=',' read -ra projects <<< "$projects_string"
    projects+=( "codechecker" )
else
    projects=( "codechecker" )
    if [ ! $run ]; then
        echo "You must select at least one of the following functions: setup, run!"
    fi
fi

for p in "${projects[@]}"
do
    if [ -f "./requirements/"$p"_custom_setup_alpine.sh" ]; then
        echo "Custom setup for $p: ./requirements/"$p"_custom_setup_alpine.sh"
        bash "./requirements/"$p"_custom_setup_alpine.sh"
    elif [ ! -f "./requirements/"$p"_alpine.txt" ]; then
        echo "Warning: " "./requirements/"$p"_alpine.txt" "not exist! Make sure that you set up the " "./requirements/"$p"_alpnie.txt" "correctly or the project has no dependencies!"
    else
        cat "./requirements/"$p"_alpine.txt" | xargs apk add
    fi
done