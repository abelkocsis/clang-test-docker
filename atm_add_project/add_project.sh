#!/bin/bash

root=/home/abelkocsis/clang-tests/clang-test-docker/atm_add_project

#NAME
printf "Adding project to test docker..."
printf "\nProject name: "
read name

#LINK -> git_links.txt
printf "\nProject github link:"
read link

echo "$name $link" >> $root/git_links_atm.txt

#REQUIREMENTS
#txt -> ./requirements/$p_debian.txt
printf "\nDependency file (.txt) destination: "
read depTxt
if [ $depTxt ]; then
    cp $depTxt "$root/$name""_debian.txt"
else
    #inline -> ./requirements/$p_debian.txt
    printf "Dependencies separated by space: "
    read depOnLine
    if [ "$depOnLine" ]; then
        echo $depOnLine | tr " " "\n" > "$root/$name""_debian.txt"
    else
        #extra -> ./requirements/$p_custom_setup_debian.sh
        printf "Special dependency setup file (.sh) destination: "
        read depSh
        if [ $depSh ]; then
            cp $depSh "$root/$name""_custom_setup_debian.sh"
        else
            printf "Warning: No dependency setup was added."
        fi
    fi 
fi

#SETUP
#extrasetup -> ./requirements/p_setup.sh

#config_Args -> ./requirements/p_config_args.txt

