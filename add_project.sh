#!/bin/bash

root=$PWD

#NAME
printf "Adding project to test docker..."
printf "\nProject name: "
read name

#LINK -> git_links.txt
printf "\nProject github link: "
read link

echo "$name $link" >> $root/requirements/git_links.txt

#REQUIREMENTS
#txt -> ./requirements/$p_debian.txt
printf "\nDependency file (.txt) destination: "
read depTxt
if [ $depTxt ]; then
    cp $depTxt "$root/requirements/$name""_debian.txt"
else
    #inline -> ./requirements/$p_debian.txt
    printf "Dependencies separated by space: "
    read depOnLine
    if [ "$depOnLine" ]; then
        echo $depOnLine | tr " " "\n" > "$root/requirements/$name""_debian.txt"
    else
        #extra -> ./requirements/$p_custom_setup_debian.sh
        printf "Special dependency setup file (.sh) destination: "
        read depSh
        if [ $depSh ]; then
            cp $depSh "$root/requirements/$name""_custom_setup_debian.sh"
        else
            printf "Warning: No dependency setup was added."
        fi
    fi 
fi

#SETUP
printf "\nAfter cloning, the tester automatically finds the following files in the project main directory: autogen.sh, configure.sh, CMakeLists.txt, buildconf.sh."

#config_Args -> ./requirements/p_config_args.txt
printf "\nIf you want, you can add additional arguments to the configure.sh file by typing here: "
read configArgs
if [ "$configArgs" ]; then
    echo "$configArgs" > "$root/requirements/$name""_config_args.txt"
fi

#extrasetup -> ./requirements/p_setup.sh
printf "You can add special setup file: "
read specSetup
if [ "$specSetup" ]; then
    cp "$specSetup" "$root/requirements/$name""_setup.sh"
fi
