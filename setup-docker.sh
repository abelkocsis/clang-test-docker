#!/bin/bash

docker build -t test-clang-$USER . --rm # --no-cache --build-arg projects=curl,ffmpeg

testingRootDir=/home/abelkocsis/clang-tests

docker run --interactive --tty --rm -v $testingRootDir:/testDir test-clang-$USER # -e "projects=curl"