#!/bin/bash

username=$USER

testingRootDir=/home/abelkocsis/clang-tests
llvmProjLocal=/home/abelkocsis/llvm-project

docker run --interactive --tty -v $testingRootDir:/myvol -v $llvmProjLocal:/llvm test-run-$username