#!/bin/bash -e
DIR=$( cd "$( dirname "$0" )" && pwd )

while ! apt-get update; do
  sleep 1
  echo "retry"
done
apt-get install -y sshpass openssh-client wget imagemagick
pip install -r requirements.txt
mx=1000;my=1000;head -c "$((3*mx*my))" /dev/urandom | convert -depth 8 -size "${mx}x${my}" RGB:- $DIR/images/image-big.png