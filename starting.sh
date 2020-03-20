#!/bin/bash

cd /myvol/curl
./buildconf
./configure

codeChecker = /home/abelkocsis/codechecker/build/CodeChecker/bin/CodeChecker

$codeChecker log -b "make -j42" -o compile_commands.json