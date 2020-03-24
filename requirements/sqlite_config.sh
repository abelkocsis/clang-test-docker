#!/bin/bash

cd /testDir
if [ ! -d  sqlite ]; then
    mkdir sqlite
    cd sqlite
    fossil clone https://www.sqlite.org/src sqlite.fossil
else
    cd sqlite
    fossil pull
fi

fossil open sqlite.fossil
./configure