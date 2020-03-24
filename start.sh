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

declare -A data
for p in ${projects[@]}
do
    data+=([$p]="")
done

data+=(["codechecker"]="")

while read proj link
do
    if [[ "${!data[@]}" =~ "${proj}" ]]; then
        data[$proj]=$link
    fi  
done < "requirements/git_links.txt"

echo ${data[@]}
for p in "${!data[@]}"; do 
    if [ ! ${data[$p]} ]; then
        echo "Warning: there is no git link for "$p
    fi
done

if $setup; then
    for p in "${!data[@]}"; do

        cd /testDir
        echo "Checking "$p" directory..."
        if [ ! -d  $p ]; then
            git clone ${data[$p]}
        else
            cd /testDir/$p
            git pull
        fi
        cd /testDir/$p
        #latesttag=$(git describe --tags)
        #git checkout ${latesttag}
    done

    #codechekcer setup
    echo "Setting up CodeChecker..."
    cd /testDir/codechecker
    make venv
    . $PWD/venv/bin/activate
    make package
    export PATH="$PWD/build/CodeChecker/bin:$PATH"
    codeChecker=/testDir/codechecker/build/CodeChecker/bin/CodeChecker

    unset 'data[codechecker]'

    for p in "${!data[@]}"; do
        cd /testDir/$p
        echo "Configuring "$p"..."
        if [ -f  "/opt/wd/requirements/"$p"_setup.sh" ]; then
            cp "/opt/wd/requirements/"$p"_setup.sh" ./setup.sh
            bash "./setup.sh"
        else
            if [ -f "./autogen.sh" ]; then
                sh ./autogen.sh
            fi
            if [ -f "./buildconf" ]; then
                ./buildconf
            fi
            if [ -f "./configure" ]; then
                if [ -f "/opt/wd/requirements/"$p"_config_args.txt" ]; then
                    arguments=$(<"/opt/wd/requirements/"$p"_config_args.txt")
                    echo "READ ARGUMENTS:" $arguments
                    ./configure $arguments
                else
                    ./configure
                fi
            fi

        fi
        echo "Running CodeChecker log on "$p"..."
        $codeChecker log -b "make -j42" -o compilation.json
    done
fi








