#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
exec ${DIR}/transmission/bin/transmission.sh --config-path /var/snap/transmission/current/config start
