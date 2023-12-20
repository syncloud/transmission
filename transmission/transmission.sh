#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib/*-linux-gnu*)
LIBS=$LIBS:$(echo ${DIR}/opt/transmission/lib)
${DIR}/lib/*-linux*/ld-*.so* --library-path $LIBS ${DIR}/opt/transmission/bin/transmission "$@"
