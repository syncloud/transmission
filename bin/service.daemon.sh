#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
exec ${DIR}/transmission/bin/transmission.sh -g /var/snap/transmission/current/config/transmission --rpc-bind-address /var/snap/transmission/current/transmission.socket --no-auth -f --log-level=debug
