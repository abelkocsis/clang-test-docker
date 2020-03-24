#!/bin/bash

setup=false
run=false

if [ "$1" == "TRUE" ];
then
    setup=true
fi

if [ "$2" == "TRUE" ];
then
    setup=true
fi

projects_string="${@:3}"

IFS=',' read -ra projects <<< "$projects_string"

projects+=( "codechecker" )

for p in "${projects[@]}"
do
    cat "./requirements/"$p"_debian.txt" | xargs apt-get -yqq install
done