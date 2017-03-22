#!/bin/bash -e

sudo apt-get update
which equivs-control || sudo apt-get install -y equivs

sudo apt-get -y install python-pip python-dev build-essential
sudo pip install --upgrade pip
sudo pip install --upgrade virtualenv
sudo pip install cassandra-driver
sudo apt-get -y install flex bison libboost-python-dev google-mock libgtest-dev liblog4cplus-dev libtbb-dev curl libcurl4-openssl-dev libxml2-dev libboost-dev libboost-filesystem-dev libboost-system-dev libboost-program-options-dev libdmalloc-dev libdmalloc5 libgoogle-perftools-dev libgoogle-perftools4 libboost-regex-dev python-virtualenv python-libxml2 libxslt1-dev libipfix-dev libipfix protobuf-compiler libprotobuf-dev python-pycassa cassandra-cpp-driver cassandra-cpp-driver-dev cassandra-cpp-driver-dev  libnetty-java libjavassist-java python-subunit subunit google-perftools

wget https://launchpad.net/ubuntu/+archive/primary/+files/python-gevent_1.1.2-1_amd64.deb
sudo apt-get install python-greenlet python-greenlet-dev
sudo dpkg -i python-gevent_1.1.2-1_amd64.deb

cd build/packages
for d in */ ; do
    pushd $d
    sudo mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes -y" -i debian/control
    #sudo dpkg -i $d*.deb
    popd
done
cd ../..

export JVM_VERSION=1.7
export KERNELDIR=/lib/modules/$(basename `ls -d /lib/modules/*|tail -1`)/build
export RTE_KERNELDIR=${KERNELDIR}


sudo scons --root=`pwd` --kernel-dir=$KERNELDIR install
sudo scons --root=`pwd` --kernel-dir=$KERNELDIR -k -j 1 \
	controller/src/analytics:test \
	controller/src/base:test \
	controller/src/bfd:test \
	controller/src/bgp:test \
	controller/src/control-node:test \
	controller/src/db:test \
	controller/src/discovery:test \
	controller/src/dns:test \
	controller/src/database/gendb:test \
	controller/src/ifmap:test \
	controller/src/io:test \
	controller/src/net:test \
	controller/src/opserver:test \
	controller/src/query_engine:test \
	controller/src/schema:test \
	controller/src/xmpp:test \
	controller/src/api-lib:test \
	controller/src/config/api-server:test \
	controller/src/config/schema-transformer:test \
	controller/src/ksync:test