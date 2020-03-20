#!/bin/bash

username=$USER

docker build -t curl-tester-$username .

destionationOfCurl=/Users/kocsisabel/research/security/clang-test-docker

docker run --interactive --tty -v $destionationOfCurl:/myvol curl-tester-$username