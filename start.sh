#!/bin/bash

setup=true
run=true
delete=false
checker=$3
list=false

if [ "$1" == "FALSE" ]; then
    setup=false
fi

if [ "$2" == "FALSE" ]; then
    run=false
fi

if [ "$4" == "TRUE" ]; then
    delete=true
fi

if [ "$5" == "TRUE" ]; then
    list=true
fi

projects_string="${@:6}"

IFS=',' read -ra projects <<<"$projects_string"
IFS=',' read -ra checkers <<<"$checker"

if $list; then
    printf "The container have been set up for the following projects:\n\n"
    printf '%s\n' "${projects[@]}"
    exit 1
fi

declare -A data

if [ "$projects" == "all" ]; then
    while read proj link; do
        data[$proj]=$link
    done <"project_links.txt"
else
    for p in ${projects[@]}; do
        data+=([$p]="")
    done
    data+=(["codechecker"]="")
    while read proj link; do
        if [[ "${!data[@]}" =~ "${proj}" ]]; then
            data[$proj]=$link
        fi
    done <"project_links.txt"
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
        if [ ! -d $p ]; then
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
        if [ -f "/opt/wd/setup_files/"$p"_setup.sh" ]; then
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

    if [ ! -d /llvm-project ]; then
        echo "Warning: own clang was not specified"
    elif [ ! -f /llvm-project/build/bin/clang ] || [ ! -f /llvm-project/build/bin/clang-tidy ]; then
        echo "Warning: clang or clang-tidy binaries not found"
    else
        cd /testDir/codechecker/build/CodeChecker/config/
        json=$(cat package_layout.json)
        echo $json | jq '.runtime.analyzers.clangsa="/llvm-project/build/bin/clang"' | jq '.runtime.analyzers."clang-tidy"="/llvm-project/build/bin/clang-tidy"' >package_layout.json
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
        #cp "compilation.json" "/testDir/compilations/"$p"_compilation.json"
        #rm "compilation.json"
    done

fi

#Running checks
if $run; then
    echo "Setting up environment..."
    cd /testDir/codechecker
    . /testDir/codechecker/venv/bin/activate
    export PATH=/testDir/codechecker/build/CodeChecker/bin:$PATH
    export PATH=/llvm-project:$PATH

    cd /testDir
    if [ ! -d reports ]; then
        mkdir reports
    fi

    unset 'data[codechecker]'

    #echo "checker:" $checker
    #echo "cheWeverythingcker:" $Weverything

    if [ "$checker" == "all" ]; then
        checker="--enable-all --disable Wall"
        echop "checker:ALL"
    else
        enableChs=''
        for c in "${checkers[@]}"; do
            enableChs="$enableChs --enable $c"
        done
        checker="--disable Weverything --disable default $enableChs"
        echo "checker: $checker"
    fi

    #echo "checker:" $checker
    #echo "cheWeverythingcker:" $Weverything

    echo "Running analysis..."
    for p in "${!data[@]}"; do
        echo "Running CodeChecker analyze on "$p"..."
        cd /testDir/$p
        rm -r "/testDir/reports/"$p
        mkdir "/testDir/reports/"$p

        CodeChecker analyze \
            "compilation.json" \
            --analyzers clang-tidy \
            $checker \
            -o "/testDir/reports/"$p \
            -j 42
        #TODO:
        #--tidyargs /home/username/test_env/tidy_args.txt

        CodeChecker parse "/testDir/reports/"$p -e html -o "/testDir/reports/"$p"/html"
    done

fi

if $delete; then
    echo "Deleting projects"
    cd /testDir
    for p in "${!data[@]}"; do
        echo "Deleting "$p"..."
        rm -r $p
    done
fi
