#!/bin/bash

setup=true
run=true
delete=false
checker=$3
list=false

declare -A data
declare -a projects
declare -a checkers

list_projects () {
    printf "The container has been set up to test the following projects:\n\n"
    printf '%s\n' "${projects[@]}"
    exit 0
}

get_all_projects () {
    cd /opt/wd/
    while read proj link; do
        data[$proj]=$link
    done <"project_links.txt"
    for setup_file in /opt/wd/setup_files/*_setup.sh ; do
        basename=$(basename $setup_file)
        proj=${basename%_setup.sh}
        if [[ ! " ${!data[@]} " =~ " ${proj} " ]]; then
            data+=([$proj]="")
        fi
    done
}

get_chosen_projects_link () {
    cd /opt/wd/
    for p in ${projects[@]}; do
        data+=([$p]="")
    done
    data+=(["codechecker"]="")
    while read proj link; do
        if [[ "${!data[@]}" =~ "${proj}" ]]; then
            data[$proj]=$link
        fi
    done <"project_links.txt"
}

update_repo () {
    p=$1
    echo "Checking "$p" directory..."
    cd /testDir
    if [ ! -d $p ]; then
        git clone ${data[$p]}
    else
        cd /testDir/$p
        git fetch --all --tags
    fi
    cd /testDir/$p
    latesttag=$(git describe --tags)
    git checkout tags/$latesttag
}

configure_project () {
    p=$1
    cd /testDir/$p
    echo "Configuring "$p"..."
    make clean
    if [ -f "/opt/wd/setup_files/"$p"_setup.sh" ]; then
        echo "Special config file is found"
        cp "/opt/wd/setup_files/"$p"_setup.sh" ./setup.sh
        bash "./setup.sh"
        rm ./setup.sh
    else
        if [ -f "CMakeLists.txt" ]; then
            echo "CMakeLists.txt is found"
            cmake .
        fi
        if [ -f "./autogen.sh" ]; then
            echo "autogen.sh is found"
            sh ./autogen.sh
        fi
        if [ -f "./buildconf" ]; then
            echo "buildconf is found"
            ./buildconf
        fi
        if [ -f "./configure" ]; then
            echo "Configure file is found"
            if [ -f "/opt/wd/setup_files/"$p"_config_args.txt" ]; then
                echo "Configure argument file is found"
                arguments=$(<"/opt/wd/setup_files/"$p"_config_args.txt")
                ./configure $arguments
            else
                ./configure
            fi
        fi
    fi
}

codechecker_config () {
    echo "Configuring up CodeChecker..."
    cd /testDir/codechecker
    make venv
    . $PWD/venv/bin/activate
    make package
    export PATH="$PWD/build/CodeChecker/bin:$PATH"

    if [ ! -d /llvm-project ]; then
        echo "Warning: own clang was not specified"
    elif [ ! -f /llvm-project/build/bin/clang ] || [ ! -f /llvm-project/build/bin/clang-tidy ]; then
        echo "Warning: clang or clang-tidy binaries are not found"
    else
        cd /testDir/codechecker/build/CodeChecker/config/
        json=$(cat package_layout.json)
        echo $json | jq '.runtime.analyzers.clangsa="/llvm-project/build/bin/clang"' | jq '.runtime.analyzers."clang-tidy"="/llvm-project/build/bin/clang-tidy"' >package_layout.json
    fi
}

codechecker_log () {
    p=$1
    cd /testDir/$p
    echo "Running CodeChecker log on "$p"..."
    CodeChecker log -b "make -j42" "-o" "compilation.json"
}

setup_checkers () {
    if [ "$checker" == "all" ]; then
        checker="--enable-all --disable Wall"
    else
        enableChs=''
        for c in "${checkers[@]}"; do
            enableChs="$enableChs --enable $c"
        done
        checker="--disable Weverything --disable default $enableChs"
    fi
}

codechecker_analyze () {
    p=$1
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
}

delete_projects () {
    echo "Deleting projects..."
    cd /testDir
    for p in "${!data[@]}"; do
        echo "Deleting "$p"..."
        rm -r $p
    done
}

check_checkers () {
    cd /testDir/codechecker/build/CodeChecker/config/
    json=$(cat package_layout.json)
    tidy=$(echo $json | jq -r '.runtime.analyzers."clang-tidy"')
    checks=("$@")
    for c in "${checks[@]}"; do
        $tidy -list-checks -checks=* | grep $c -q
        if [ $? -ne 0 ]; then
            echo "Error: invalid checker name: $c"
            exit 1
        fi
    done
}

if [ "$1" == "FALSE" ]; then
    setup=false
elif [ ! "$1" == "TRUE" ]; then
    echo "Warning: setup argument is neither TRUE nor FALSE. Default TRUE value is applied."
fi

if [ "$2" == "FALSE" ]; then
    run=false
elif [ ! "$2" == "TRUE" ]; then
    echo "Warning: run argument is neither TRUE nor FALSE. Default TRUE value is applied."
fi

if [ "$4" == "TRUE" ]; then
    delete=true
elif [ ! "$4" == "FALSE" ]; then
    echo "Warning: delete argument is neither TRUE nor FALSE. Default FALSE value is applied."
fi

if [ "$5" == "TRUE" ]; then
    list=true
elif [ ! "$5" == "FALSE" ]; then
    echo "Warning: list argument is neither TRUE nor FALSE. Default FALSE value is applied."
fi

projects_string="${@:6}"

IFS=',' read -ra projects <<<"$projects_string"
IFS=',' read -ra checkers <<<"$checker"

if $list; then
    list_projects
fi

if [ "$projects" == "all" ]; then
    get_all_projects
else
    data+=(["codechecker"]="")
    bash ./check_projects_arg.sh "${projects[@]}"
    if [ $? -ne 0 ]; then
        exit 4
    fi
    get_chosen_projects_link
fi

for p in "${!data[@]}"; do
    if [ ! ${data[$p]} ]; then
        echo "Warning: there is no git link for "$p
    fi
done

#SETUP
if $setup; then
    echo "Setting up projects..."
    for p in "${!data[@]}"; do
        update_repo $p
    done
    unset 'data[codechecker]'

    for p in "${!data[@]}"; do
        configure_project $p
    done

    codechecker_config

    #run CodeChecker
    for p in "${!data[@]}"; do
        codechecker_log $p
    done

fi

#Running checks
if $run; then
    if [ ! "$checker" == "all" ]; then
        echo "Checking checker names..."
        check_checkers "${checkers[@]}"
    fi

    echo "Setting up environment..."
    cd /testDir/codechecker
    . /testDir/codechecker/venv/bin/activate
    export PATH=/testDir/codechecker/build/CodeChecker/bin:$PATH

    cd /testDir
    if [ ! -d reports ]; then
        mkdir reports
    fi

    unset 'data[codechecker]'
    setup_checkers

    echo "Running analysis..."
    for p in "${!data[@]}"; do
        echo "Running CodeChecker analyze on "$p"..."
        codechecker_analyze $p
    done

fi

if $delete; then
    delete_projects
else
    echo "Setting up permissions..."
    cd /testDir
    for p in "${!data[@]}"; do
        chmod -R uog=rwx $p
    done
fi
