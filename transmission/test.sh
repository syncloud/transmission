#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PREFIX=${DIR}/../build/snap/transmission

du -d10 -h $PREFIX | sort -h | tail -100

ldd ${PREFIX}/usr/local/bin/transmission-daemon
ls -la ${PREFIX}/bin
${PREFIX}/bin/transmission.sh --help
