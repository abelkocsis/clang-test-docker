#!/bin/bash

dest=/home/abelkocsis
mkdir clang-tests
cd clang-tests
git clone https://github.com/abelkocsis/clang-test-docker.git
git clone https://github.com/Ericsson/codechecker.git

git clone https://github.com/curl/curl.git
