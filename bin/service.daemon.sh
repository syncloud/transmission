#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export TRANSMISSION_WEB_HOME=${DIR}/transmission/usr/local/share/transmission/public_html
exec ${DIR}/transmission/bin/transmission.sh -g /var/snap/transmission/current/config --no-auth -f --log-level=debug
