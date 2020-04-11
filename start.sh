#!/bin/bash

setup=false
run=false
deleteAfterAnalyse=false
checker=$3

if [ "$1" == "TRUE" ]; then
    setup=true
fi

if [ "$2" == "TRUE" ]; then
    run=true
fi

if [ "$4" == "TRUE" ]; then
    deleteAfterAnalyse=true
fi

projects_string="${@:5}"

IFS=',' read -ra projects <<< "$projects_string"

declare -A data

if [ "$projects" == "all" ]; then
    while read proj link
    do
        data[$proj]=$link
    done < "project_links.txt"
else
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
    done < "project_links.txt"
fi

echo ${data[@]}
for p in "${!data[@]}"; do 
    if [ ! ${data[$p]} ]; then
        echo "Warning: there is no git link for "$p
    fi
done

#SETUP
#setupStart=$(($(date +%s%N)/1000000))
if $setup; then
    echo "Setting up projects..."
    for p in "${!data[@]}"; do

        cd /testDir
        echo "Checking "$p" directory..."
        if [ ! -d  $p ]; then
            git clone ${data[$p]}
        else
            cd /testDir/$p
            git fetch --all --tags
        fi
        cd /testDir/$p
        latesttag=$(git describe --tags)
        git checkout tags/$latesttag
    done

    unset 'data[codechecker]'

    for p in "${!data[@]}"; do
        cd /testDir/$p
        echo "Configuring "$p"..."
        make clean
        if [ -f  "/opt/wd/setup_files/"$p"_setup.sh" ]; then
            echo "Special config file found"
            cp "/opt/wd/setup_files/"$p"_setup.sh" ./setup.sh
            bash "./setup.sh"
            rm ./setup.sh
        else
            if [ -f "CMakeLists.txt" ]; then
                echo "CMAkeLists.txt found"
                cmake .
            fi
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
                if [ -f "/opt/wd/setup_files/"$p"_config_args.txt" ]; then
                    echo "Configure argument file found"
                    arguments=$(<"/opt/wd/setup_files/"$p"_config_args.txt")
                    echo "READ ARGUMENTS: " $arguments
                    ./configure $arguments
                else
                    ./configure
                fi
            fi

        fi
    done
    #diff=$(($(($(date +%s%N)/1000000))-$setupStart))
    #time_secs=`echo "scale=3;$diff/1000" | bc`
    
    echo "Setup excecuted in "$time_secs" seconds."
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
        $codeChecker log -b "make -j42" "-o" "compilation.json"
        cp "compilation.json" "/testDir/compilations/"$p"_compilation.json"
        rm "compilation.json"
    done 

    if $deleteAfterAnalyse; then
        echo "Deleting folders"
        cd /testDir
        for p in "${!data[@]}"; do
            echo "Deleting "$p"..."
            rm -r $p
        done 
    fi
fi

#Running checks
if $run; then
    echo "Setting up environment..."
    cd /testDir/codechecker
    . /testDir/codechecker/venv/bin/activate
    export PATH=/testDir/codechecker/build/CodeChecker/bin:$PATH
    export PATH=/llvmBin:$PATH
    
    cd /testDir
    if [ ! -d reports ]; then
        mkdir reports
    fi

    cd /testDir/compilations
    unset 'data[codechecker]'

    echo "checker:" $checker
    echo "cheWeverythingcker:" $Weverything

    if [ "$checker" == "all" ]; then
        Weverything=""
        checker="--enable-all"
    else
        checker="--enable $checker"
        Weverything="--disable Weverything"
    fi 

    echo "checker:" $checker
    echo "cheWeverythingcker:" $Weverything

    echo "Running analysis..."
    for p in "${!data[@]}"; do
        echo "Running CodeChecker analyze on "$p"..."
        if [ ! -d "/testDir/reports/"$p ]; then
            mkdir "/testDir/reports/"$p
        fi
        CodeChecker analyze \
            $p"_compilation.json" \
            --analyzers clang-tidy \
            --disable default \
            $Weverything \
            $checker \
            -o "/testDir/reports/"$p \
            -j 42
            #TODO:
            #--tidyargs /home/username/test_env/tidy_args.txt
            
        CodeChecker parse "/testDir/reports/"$p -e html -o "/testDir/reports/"$p
    done 

fi