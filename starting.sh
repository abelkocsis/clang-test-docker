#!/bin/bash

cd /testDir
git clone https://github.com/Ericsson/codechecker.git
cd /testDir/codechecker
git checkout remotes/origin/release-v6.11.1

make venv
. $PWD/venv/bin/activate
make package
export PATH="$PWD/build/CodeChecker/bin:$PATH"

cd /testDir/curl
./buildconf
./configure

codeChecker=/testDir/codechecker/build/CodeChecker/bin/CodeChecker

$codeChecker log -b "make -j42" -o compilation.json
