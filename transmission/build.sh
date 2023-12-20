#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/build
VERSION=$1

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

apt update
apt -y install build-essential cmake wget libcurl4-openssl-dev libssl-dev
cd ${BUILD_DIR}
wget --progress dot:giga https://github.com/transmission/transmission/releases/download/$VERSIOM/transmission-$VERSIOM.tar.xz
tar xf $VERSION.tar.gz
cd transmission-$VERSION
cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_QT=OFF
cd build
cmake --build .

# cleanup
apt-get -y purge build-essential
apt-get -y autoremove
rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /root/.cache

TARGET=${DIR}/../build/snap/transmission
mkdir $TARGET
cp -r /bin ${TARGET}
cp -r /sbin ${TARGET}
cp -r /lib* ${TARGET}
cp -r /usr/lib ${TARGET}
cp -r /usr/local/lib ${TARGET}

cp $DIR/transmission.sh ${TARGET}/bin

ldd ${TARGET}/usr/sbin/transmission
