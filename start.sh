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
            #git pull upstream master
        fi
        cd /testDir/$p
        #latesttag=$(git describe --tags)
        #git checkout ${latesttag}
    done

    unset 'data[codechecker]'

    for p in "${!data[@]}"; do
        cd /testDir/$p
        echo "Configuring "$p"..."
        if [ -f  "/opt/wd/requirements/"$p"_setup.sh" ]; then
            echo "Special config file found"
            cp "/opt/wd/requirements/"$p"_setup.sh" ./setup.sh
            bash "./setup.sh"
            rm ./setup.sh
        else
            if [ -f "./autogen.sh" ]; then
                echo "autogen.sh found"
                sh ./autogen.sh
            fi
            if [ -f "./buildconf" ]; then
                echo "buildconf found"
                ./buildconf
            fi
            if [ -f "./configure" ]; then
                echo "Configure file found"
                if [ -f "/opt/wd/requirements/"$p"_config_args.txt" ]; then
                    echo "Configure argument file found"
                    arguments=$(<"/opt/wd/requirements/"$p"_config_args.txt")
                    echo "READ ARGUMENTS: " $arguments
                    ./configure $arguments
                else
                    ./configure
                fi
            fi

        fi
    done

    #codechekcer setup
    echo "Setting up CodeChecker..."

    cd /testDir/codechecker
    make venv
    . $PWD/venv/bin/activate
    make package
    export PATH="$PWD/build/CodeChecker/bin:$PATH"
    codeChecker=/testDir/codechecker/build/CodeChecker/bin/CodeChecker

    if [ ! -d /llvmBin ] ; then
        echo "Warning: own clang was not specified"
    elif [ ! -f /llvmBin/clang ] || [ ! -f /llvmBin/clang-tidy ] ; then
        echo "Warning: clang or clang-tidy binaries not found"
    else
        cd /testDir/codechecker/build/CodeChecker/config/
        json=`cat package_layout.json`
        echo $json | jq '.runtime.analyzers.clangsa="/llvmBin/clang"' | jq '.runtime.analyzers."clang-tidy"="/llvmBin/clang-tidy"' > package_layout.json
    fi

    #setup compilations dir
    cd /testDir
    if [ ! -d compilations ]; then
        mkdir compilations
    fi

    #run CodeChecker
    for p in "${!data[@]}"; do
        cd /testDir/$p
        echo "Running CodeChecker log on "$p"..."
        $codeChecker log -b "make -j42" "-o compilation.json"
        #cp "/testDir/$p/compilation.json" "/testDir/compilations/"$p"_compilation.json"
        #rm "/testDir/$p/compilation.json"
    done 

fi








