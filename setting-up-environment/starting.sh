#!/bin/bash

cd /myvol/codechecker

make venv
. $PWD/venv/bin/activate
make package
export PATH="$PWD/build/CodeChecker/bin:$PATH"

cd /myvol/curl
./buildconf
./configure

codeChecker=/myvol/codechecker/build/CodeChecker/bin/CodeChecker

$codeChecker log -b "make -j42" -o compilation.json
