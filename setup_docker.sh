#!/bin/bash

docker build -t test-clang . --rm # --no-cache --build-arg projects=curl,ffmpeg

testDir=/home/abelkocsis/thesis/projects
llvm=/home/abelkocsis/thesis/llvm-project/

docker run --rm --interactive --tty -v $testDir:/testDir -v $llvm:/llvm-project test-clang # -e "projects=curl" --interactive --tty