#!/bin/bash

# declaring variables
setup=true
analyze=true
delete=false
checkers_string=$3
list=false
checker=""

declare -A data
declare -a projects
declare -a checkers

# list all available projects
list_projects () {
    printf "TestEnv: The container has been set up to test the following projects:\n\n"
    printf '%s\n' "${projects[@]}"
    exit 0
}

# store all available projects to data array
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

# store all chosen projects and their links in data array
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

# Clone or fetch the git repo of a project and checkout to the latest tag
update_repo () {
    p=$1
    echo "TestEnv: Checking "$p" directory..."
    cd /testDir
    if [ ! -d $p ] && [ ${data[$p]} ] ; then
        git clone ${data[$p]}
        if [ $? -ne 0 ]; then
            printf "TestEnv Error: cloning $p is failed. \nPlease, try again, disable the project or try to add the link of the project with add_project.sh\n"
            exit 5
        fi
    else
        cd /testDir/$p
        git fetch --all --tags
    fi
    cd /testDir/$p
    latesttag=$(git describe --tags `git rev-list --tags --max-count=1`)
    git checkout $latesttag -f
}

# Trying to configure a project in numerous ways
configure_project () {
    p=$1
    cd /testDir/$p
    echo "TestEnv: Configuring "$p"..."
    # Cleaning last build
    make clean
    # Configuring with....
    if [ -f "/opt/wd/setup_files/"$p"_setup.sh" ]; then
        # ...special config file
        echo "TestEnv: Special config file is found"
        cp "/opt/wd/setup_files/"$p"_setup.sh" ./setup.sh
        bash "./setup.sh"
        if [ $? -ne 0 ]; then
            printf 'TestEnv Error: '$p'_setup.sh failed. Please, disable '$p' or try to fix the following setup file: /clang-test-docker/setup_files/'$p'_setup.sh\nMake sure that you added '$p' during building the image. \nYou can list the possible projects in the following way:\tdocker run -e "list=TRUE" <yourContainerName>\n'
            exit 5
        fi
        rm ./setup.sh
    else
        if [ -f "CMakeLists.txt" ]; then
            # ...cmake...
            echo "TestEnv: CMakeLists.txt is found"
            cmake .
            if [ $? -ne 0 ]; then
                printf 'TestEnv Error: CMake failed during configuring '$p'. Please, disable '$p' or make sure that you added '$p' during building the image. \nYou can list the possible projects in the following way:\tdocker run -e "list=TRUE" <yourContainerName>\n'
                exit 7
            fi
        fi
        if [ -f "./autogen.sh" ]; then
            # ...autogen.sh...
            echo "TestEnv: autogen.sh is found"
            sh ./autogen.sh
            if [ $? -ne 0 ]; then
                printf 'TestEnv Error: autogen.sh failed during configuring '$p'. Please, disable '$p' or make sure that you added '$p' during building the image. \nYou can list the possible projects in the following way:\tdocker run -e "list=TRUE" <yourContainerName>\n'
                exit 8
            fi
        fi
        if [ -f "./buildconf" ]; then
            # ...buildconf...
            echo "TestEnv: buildconf is found"
            ./buildconf
            if [ $? -ne 0 ]; then
                printf 'TestEnv Error: buildconf failed during configuring '$p'. Please, disable '$p' or make sure that you added '$p' during building the image. \nYou can list the possible projects in the following way:\tdocker run -e "list=TRUE" <yourContainerName>\n'
                exit 9
            fi
        fi
        if [ -f "./configure" ]; then
            echo "TestEnv: configure file is found"
            if [ -f "/opt/wd/setup_files/"$p"_config_args.txt" ]; then
                # ...configure with specified arguments
                echo "TestEnv: configure argument file is found"
                arguments=$(<"/opt/wd/setup_files/"$p"_config_args.txt")
                ./configure $arguments
                if [ $? -ne 0 ]; then
                    printf 'TestEnv Error: configure failed during configuring '$p' with additional arguments. Please, disable '$p' or make sure that you added '$p' during building the image. \nYou can list the possible projects in the following way:\tdocker run -e "list=TRUE" <yourContainerName>\n'
                    exit 10
                fi
            else
                # configure without specified arguments
                ./configure
                if [ $? -ne 0 ]; then
                    printf 'TestEnv Error: configure failed during configuring '$p'. Please, disable '$p', check your custom configure arguments or make sure that you added '$p' during building the image. \nYou can list the possible projects in the following way:\tdocker run -e "list=TRUE" <yourContainerName>\n'
                    exit 11
                fi
            fi
        fi
    fi
}

# configuring CodeChecker
codechecker_config () {
    echo "TestEnv: Configuring up CodeChecker..."
    cd /testDir/codechecker
    git checkout v6.11.1
    make venv
    if [ $? -ne 0 ]; then
        printf 'TestEnv Error: Configuring CodeChecker failed. Please, rebuild the image.'
        exit 4
    fi
    . $PWD/venv/bin/activate
    make package
    if [ $? -ne 0 ]; then
        printf 'TestEnv Error: Configuring CodeChecker failed. Please, rebuild the image.'
        exit 4
    fi
    export PATH="$PWD/build/CodeChecker/bin:$PATH"

    if [ ! -f /llvm-project/build/bin/clang ] || [ ! -f /llvm-project/build/bin/clang-tidy ]; then
        printf "TestEnv Error: clang or clang-tidy binaries are not found.\nMake sure that you volumed the right llvm-project directory and the build directory located in llvm-project/build.\n"
        exit 13
    else
        cd /testDir/codechecker/build/CodeChecker/config/
        json=$(cat package_layout.json)
        echo $json | jq '.runtime.analyzers.clangsa="/llvm-project/build/bin/clang"' | jq '.runtime.analyzers."clang-tidy"="/llvm-project/build/bin/clang-tidy"' >package_layout.json
    fi
}

# Running "CodeChecker log" on a project
codechecker_log () {
    p=$1
    cd /testDir/$p
    echo "TestEnv: Running CodeChecker log on "$p"..."
    CodeChecker log -b "make -j42" "-o" "compilation.json"
}

# Setting up Codechecker argument (checker) for chosen checkers
setup_checkers () {
    if [ "$checkers_string" == "all" ]; then
        checker="--enable-all --disable Wall"
    else
        enableChs=''
        for c in "${checkers[@]}"; do
            enableChs="$enableChs --enable $c"
        done
        disableChs=''
        modules=( "abseil" "android" "boost" "bugprone" "cert" "cppcoreguidelines" "darwin" "fuchsia" "google" "hicpp" "linuxkernel" 
            "llvm" "misc" "modernize" "mpi" "objc" "openmp" "performance" "portability" "readability" "zircon" )
        for m in "${modules[@]}"; do
            disableChs="$disableChs --disable $m"
        done
        checker="--disable default --disable Weverything $disableChs $enableChs"
    fi
}

# Running "CodeChecker analyze" on a project
codechecker_analyze () {
    p=$1
    cd /testDir/$p
    if [ -d "/testDir/reports/"$p ]; then
        rm -r "/testDir/reports/"$p
    fi
    mkdir "/testDir/reports/"$p

    CodeChecker analyze \
        "compilation.json" \
        --analyzers clang-tidy \
        $checker \
        -o "/testDir/reports/"$p \
        -j 42

    CodeChecker parse "/testDir/reports/"$p -e html -o "/testDir/reports/"$p"/html"
}

# Delete all chosen projects
delete_projects () {
    echo "TestEnv: Deleting projects..."
    cd /testDir
    for p in "${!data[@]}"; do
        echo "TestEnv: Deleting "$p"..."
        rm -r $p
    done
}

# Check if checkers names are valid or not
check_checkers () {
    cd /testDir/codechecker/build/CodeChecker/config/
    json=$(cat package_layout.json)
    tidy=$(echo $json | jq -r '.runtime.analyzers."clang-tidy"')
    checks=("$@")
    for c in "${checks[@]}"; do
        $tidy -list-checks -checks=* | grep $c -q
        if [ $? -ne 0 ]; then
            echo "TestEnv Error: invalid checker name: $c"
            exit 2
        fi
    done
}

# Check if the necessary folders are mounted or not
check_args () {
    if [ ! -d /llvm-project ]; then
        printf "TestEnv Error: /llvm-project is not found! \nMake sure that you added it as a volume. \nExample:\tdocker run -v /path/to/test/dir/:/testDir -v /path/to/llvm-project/:/llvm-project <yourContainerName>\n"
        exit 15
    elif [ ! -d /testDir ]; then
        printf "TestEnv Error: /testDir is not found! \nMake sure that you added it as a volume. \nExample:\tdocker run -v /path/to/test/dir/:/testDir -v /path/to/llvm-project/:/llvm-project <yourContainerName>\n"
        exit 15
    fi
}

# PROGRAM STARTS

# Reading and storing arguments
if [ "$1" == "FALSE" ]; then
    setup=false
elif [ ! "$1" == "TRUE" ]; then
    echo "TestEnv Warning: setup argument is neither TRUE nor FALSE. Default TRUE value is applied."
fi

if [ "$2" == "FALSE" ]; then
    analyze=false
elif [ ! "$2" == "TRUE" ]; then
    echo "TestEnv Warning: analyze argument is neither TRUE nor FALSE. Default TRUE value is applied."
fi

if [ "$4" == "TRUE" ]; then
    delete=true
elif [ ! "$4" == "FALSE" ]; then
    echo "TestEnv Warning: delete argument is neither TRUE nor FALSE. Default FALSE value is applied."
fi

if [ "$5" == "TRUE" ]; then
    list=true
elif [ ! "$5" == "FALSE" ]; then
    echo "TestEnv Warning: list argument is neither TRUE nor FALSE. Default FALSE value is applied."
fi

projects_string="${@:6}"

IFS=',' read -ra projects <<<"$projects_string"
IFS=',' read -ra checkers <<<"$checkers_string"

# Starting working
if $list; then
    list_projects
fi

# Get projects and their git links
if [ "$projects" == "all" ]; then
    get_all_projects
else
    data+=(["codechecker"]="")
    bash ./check_projects_arg.sh "${projects[@]}"
    if [ $? -ne 0 ]; then
        exit 3
    fi
    get_chosen_projects_link
fi

for p in "${!data[@]}"; do
    if [ ! ${data[$p]} ]; then
        echo "TestEnv Warning: there is no git link for "$p
    fi
done

# SETUP
if $setup; then
    # Configuring projects
    check_args
    echo "TestEnv: Setting up projects..."
    for p in "${!data[@]}"; do
        update_repo $p
    done
    unset 'data[codechecker]'

    for p in "${!data[@]}"; do
        configure_project $p
    done

    codechecker_config

    # Running CodeChecker log
    for p in "${!data[@]}"; do
        codechecker_log $p
    done

fi

#Running checks
if $analyze; then
    # Checking arguments
    check_args
    if [ ! "$checkers_string" == "all" ]; then
        echo "TestEnv: Checking checker names..."
        check_checkers "${checkers[@]}"
    fi
    # Set up environment for Codechecker
    echo "TestEnv: Setting up environment..."
    cd /testDir/codechecker
    . /testDir/codechecker/venv/bin/activate
    export PATH=/testDir/codechecker/build/CodeChecker/bin:$PATH

    cd /testDir
    if [ ! -d reports ]; then
        mkdir reports
    fi

    # Setting up arguments and runningy CodeChecker analyze
    unset 'data[codechecker]'
    setup_checkers

    echo "TestEnv: Running analyzis..."
    for p in "${!data[@]}"; do
        echo "TestEnv: Running CodeChecker analyze on "$p"..."
        codechecker_analyze $p
    done

fi

# Deleting projects or make the user be able to do it later
if $delete; then
    unset 'data[codechecker]'
    delete_projects
else
    echo "TestEnv: Setting up permissions..."
    cd /testDir
    chmod -R 777 ./
fi
echo "TestEnv: Done!"
