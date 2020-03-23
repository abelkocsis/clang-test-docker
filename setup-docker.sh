#!/bin/bash

username=$USER

docker build -t test-setup-$username ./setting-up-environment
#docker build -t test-run-$username ./run-tests # --no-cache

testingRootDir=/home/abelkocsis/clang-tests

#docker run --interactive --tty -v $testingRootDir:/myvol test-setup-$username