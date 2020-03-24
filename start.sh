#!/bin/bash

setup=false
run=false

if [ "$1" == "TRUE" ]; then
    setup=true
fi

if [ "$2" == "TRUE" ]; then
    setup=true
fi

projects_string="${@:3}"

IFS=',' read -ra projects <<< "$projects_string"

projects+=("codechecker")
sortedProjects=()
echo ${projects[@]}
declare -A data

while read proj link
do
    if [[ "${projects[@]}" =~ "${proj}" ]]; then
        data[$proj]=$link
    fi  
done < "requirements/git_links.txt"

echo ${data[@]}
for value in "${!my_array[@]}"; do echo "$value"; done

if $setup; then
    for p in "${!data[@]}"; do
        cd /testDir
        echo "p: "$p
        echo "l: "${data[$p]}
        if [ ! -d  $p ]; then
            git clone ${data[$p]}
        else
            git pull
        fi
        #latesttag=$(git describe --tags)
        #git checkout ${latesttag}
    done

    # #codechekcer setup
    # make venv
    # . $PWD/venv/bin/activate
    # make package
    # export PATH="$PWD/build/CodeChecker/bin:$PATH"  

    # #curl setup
    # cd /testDir/curl
    # ./buildconf
    # ./configure

    # #for all START
    # codeChecker=/testDir/codechecker/build/CodeChecker/bin/CodeChecker
    # $codeChecker log -b "make -j42" -o compilation.json

    #for all END
fi








