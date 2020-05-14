apt-get install -yqq libboost-dev libboost-test-dev libboost-program-options-dev libboost-filesystem-dev \
    libboost-thread-dev libevent-dev automake libtool flex bison pkg-config g++ libssl-dev \
    build-essential curl doxygen gcc-multilib git python3-dev python-virtualenv python-dev \
    wget

cd /opt/
wget http://xenia.sote.hu/ftp/mirrors/www.apache.org/thrift/0.13.0/thrift-0.13.0.tar.gz
tar -xvf thrift-0.13.0.tar.gz
cd thrift-0.13.0
./bootstrap.sh
./configure
make -j14
make install

