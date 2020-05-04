#!/bin/bash

# Reading arguments
projects_string="${@}"
IFS=',' read -ra projects <<< "$projects_string"

# Checking some important issues
if [ -z "$projects" ]; then
    echo "TestEnv Error: You must add at least one project!"
    exit 1
fi
if [ ! -f "./project_links.txt" ]; then
    echo "TestEnv Error: project_links.txt file is not found!"
    exit 2
fi
if [ ! -d "./requirements" ]; then
    echo "TestEnv Error: requirements folder is not found!"
    exit 3
fi

# Checking projects...
projects+=( "codechecker" )
if [ "$projects" == "all" ]; then
    # ...when we need all of them
    unset projects
    while read proj link
    do
        projects+=($proj)
    done < "./project_links.txt"
    for setup_file in /opt/wd/setup_files/*_setup.sh ; do
        basename=$(basename $setup_file)
        proj=${basename%_setup.sh}
        if [[ ! " ${projects[@]} " =~ " ${proj} " ]]; then
            projects+=($proj)
        fi

    done 
else
    # ...when we need just some of them
    # Checking if the projects names are fine
    bash ./check_projects_arg.sh "${projects[@]}"
    if [ $? -ne 0 ]; then
        exit 4
    fi
fi

# Installing dependencies...
cat "./requirements/debian.txt" | xargs apt-get -yqq install 
if [ $? -ne 0 ]; then
    printf "TestEnv Error: Installing dependencies failed. Please, try again.\n"
    exit 5
fi

for p in "${projects[@]}" ; do
    echo "TestEnv: Installing dependencies for $p project..."
    if [ -f "./requirements/"$p"_custom_deps_debian.sh" ]; then
        # ...with custom setup
        echo "TestEnv: Custom setup for $p: ./requirements/"$p"_custom_deps_debian.sh"
        bash "./requirements/"$p"_custom_deps_debian.sh"
        if [ $? -ne 0 ]; then
            printf "TestEnv Error: Installing dependencies failed. Check your custom dependency file for $p.\n"
            exit 6
        fi
    elif [ ! -f "./requirements/"$p"_debian.txt" ]; then
        # ...if there is nothing to install
        echo "TestEnv Warning: " "./requirements/"$p"_debian.txt" "not exist! Make sure that you set up the " "./requirements/"$p"_debian.txt" "correctly or the project has no dependencies!"
    else
        # ...with usual txt file
        cat "./requirements/"$p"_debian.txt" | xargs apt-get -yqq install
        if [ $? -ne 0 ]; then
            printf "TestEnv Error: Installing dependencies failed. Make sure that you used the right dependency name when setting up $p.\n"
            exit 7
        fi
    fi
done