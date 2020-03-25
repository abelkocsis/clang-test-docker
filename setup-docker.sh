#!/bin/bash

docker build -t test-clang-$USER . --rm # --no-cache --build-arg projects=curl,ffmpeg

testingRootDir=/home/abelkocsis/clang-tests
llvmBin=/home/abelkocsis/llvm-project/build/bin

docker run --interactive --tty --rm -v $testingRootDir:/testDir -v $llvmBin:/llvmBin test-clang-$USER # -e "projects=curl"