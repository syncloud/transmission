#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PREFIX=${DIR}/../build/snap/transmission

${PREFIX}/bin/transmission.sh --help
${PREFIX}/bin/transmission.sh --version

test -z "$(find ${PREFIX} -name 'python3*' -print -quit)"

test -f ${PREFIX}/usr/local/share/transmission/public_html/index.html
test -f ${PREFIX}/usr/local/share/transmission/public_html-legacy/index.html
test -f ${PREFIX}/usr/local/share/transmission/public_html-legacy/transmission-app.js
