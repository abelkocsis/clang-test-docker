#!/bin/bash

apt-get -yqq install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 libboost-all-dev software-properties-common libminiupnpc-dev libzmq3-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
add-apt-repository ppa:bitcoin/bitcoin
apt-get -yqq update
apt-get -yqq install libdb4.8-dev libdb4.8++-dev
