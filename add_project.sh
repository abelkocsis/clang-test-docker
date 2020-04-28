#!/bin/bash

root=$PWD

printf "Adding project to test docker..."

#LINK -> git_links.txt
printf "\nPlease, paste the git link of the project here: "
read link



wget $link -q --spider -o /dev/null
if [ $? -ne 0 ]; then
    echo "Invalid repository!"
    exit 1
else
    printf "Repository checked."
fi


basename=$(basename $link)
name=${basename%.*}

echo "$name $link" >> $root/project_links.txt
printf "\n$name project was saved."

#REQUIREMENTS
#txt -> ./requirements/$p_debian.txt
printf "\nDependency file (.txt) destination for $name project: "
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
        #extra -> ./requirements/$p_custom_deps_debian.sh
        printf "Special dependency setup file (.sh) destination: "
        read depSh
        if [ $depSh ]; then
            cp $depSh "$root/requirements/$name""_custom_deps_debian.sh"
        else
            printf "Warning: No dependency setup was added."
        fi
    fi 
fi

#SETUP
printf "\nAfter cloning, the tester automatically finds the following files in the project main directory: autogen.sh, configure.sh, CMakeLists.txt, buildconf.sh."

#config_Args -> ./setup_files/p_config_args.txt
printf "\nIf you want, you can add additional arguments to the configure.sh file by typing here: "
read configArgs
if [ "$configArgs" ]; then
    echo "$configArgs" > "$root/setup_files/$name""_config_args.txt"
fi

#extrasetup -> ./requirements/p_setup.sh
printf "You can add special setup file: "
read specSetup
if [ "$specSetup" ]; then
    cp "$specSetup" "$root/setup_files/$name""_setup.sh"
fi
