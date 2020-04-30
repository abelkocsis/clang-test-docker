#!/bin/bash

docker build -t test-clang . --rm # --no-cache --build-arg projects=curl,ffmpeg

testingRootDir=/home/abelkocsis/clang-tests
llvm=/home/abelkocsis/thesis/llvm-project/

docker run --rm --interactive --tty -v $testingRootDir:/testDir -v $llvm:/llvm-project test-clang # -e "projects=curl" --interactive --tty