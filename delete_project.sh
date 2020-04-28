#!/bin/bash

printf "Deleteing project on test docker..."
printf "\nPlease, give the name of project you would like to delete: "
read name

bash check_projects_arg.sh $name
if [ $? -ne 0 ]; then
    exit 1
fi

printf "Deletting starts..."
if [ -f "setup_files/"$name"_setup.sh" ]; then
    rm "setup_files/"$name"_setup.sh"
fi
if [ -f "setup_files/"$name"_config_args.sh" ]; then
    rm "setup_files/"$name"_config_args.sh"
fi
if [ -f "requirements/"$name"_debian.txt" ]; then
    rm "requirements/"$name"_debian.txt"
fi
if [ -f "requirements/"$name"_custom_deps_debian.sh" ]; then
    rm "requirements/"$name"_custom_deps_debian.sh"
fi
pattern="/$name/d"
sed $pattern -i project_links.txt
printf "\n$name deleted succesfully!\n"