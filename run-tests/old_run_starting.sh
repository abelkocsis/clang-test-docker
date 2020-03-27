#!/bin/bash

cd /myvol/codechecker


. /myvol/codechecker/venv/bin/activate

codeChecker=/myvol/codechecker/build/CodeChecker/bin/CodeChecker

export PATH=/myvol/codechecker/build/CodeChecker/bin:$PATH
export PATH=/llvm/build/bin:$PATH

cd /myvol/curl

CodeChecker analyze compilation.json -o ./reports

