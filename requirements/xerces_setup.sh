#!/bin/bash

cd /testDir
if [ ! -d  xerces ]; then
    wget http://www-eu.apache.org/dist//xerces/c/3/sources/xerces-c-3.2.2.tar.gz
    tar xf xerces-c-3.2.2.tar.gz
    mv xerces-c-3.2.2 xerces
    rm xerces-c-3.2.2.tar.gz
fi
cd xerces

./configure
