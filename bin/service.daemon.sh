#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
${DIR}/bin/wait-for-configure.sh
WEB=public_html
if [[ "$(cat ${SNAP_COMMON}/web-ui 2>/dev/null)" == "legacy" ]]; then
  WEB=public_html-legacy
fi
export TRANSMISSION_WEB_HOME=${DIR}/transmission/usr/local/share/transmission/${WEB}
exec ${DIR}/transmission/bin/transmission.sh -g ${SNAP_DATA}/config --no-auth -f --log-level=info
