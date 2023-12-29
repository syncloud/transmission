#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/build
VERSION=$1
ARCH=$2

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

apt update
apt -y install build-essential cmake wget libcurl4-openssl-dev libssl-dev python3 ninja-build
cd ${BUILD_DIR}
wget --progress dot:giga https://github.com/transmission/transmission/releases/download/$VERSION/transmission-$VERSION.tar.xz
tar xf transmission-$VERSION.tar.xz
cd transmission-$VERSION
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_QT=OFF -DENABLE_MAC=OFF -DENABLE_GTK=OFF -DENABLE_TESTS=OFF
cd build

if [[ $ARCH == "arm" ]]; then
  cmake --build . -j 4
else
  cmake --build .
fi

cmake --install .

# cleanup
apt-get -y purge build-essential
apt-get -y autoremove
rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /root/.cache

TARGET=${DIR}/../build/snap/transmission
mkdir -p $TARGET
cp -r /bin ${TARGET}
cp -r /sbin ${TARGET}
cp -r /lib* ${TARGET}
cp -r /usr ${TARGET}

cp $DIR/transmission.sh ${TARGET}/bin

ldd ${TARGET}/usr/local/bin/transmission-daemon
