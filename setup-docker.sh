#!/bin/bash

docker build -t test-clang-$USER .

testingRootDir=/home/abelkocsis/clang-tests

docker run --interactive --tty -v $testingRootDir:/testDir test-clang-$USER