#!/bin/bash

cd /testDir
if [ ! -d  sqlite ]; then
    export FOSSIL_USER=user
    mkdir sqlite
    cd sqlite
    fossil clone https://www.sqlite.org/src sqlite.fossil
    fossil open sqlite.fossil
fi
cd /testDir/sqlite

./configure