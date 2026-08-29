#!/bin/bash -e

DIR=$( cd "$( dirname "$0" )" && pwd )
cd "${DIR}"

ARTIFACT_SUBDIR=$1
SPEC=$2
PROJECT=${3:-desktop}

export PLAYWRIGHT_FULL_DOMAIN=buster.com
export PLAYWRIGHT_APP_DOMAIN=transmission.buster.com
export PLAYWRIGHT_DEVICE_HOST=transmission.buster.com
export PLAYWRIGHT_DEVICE_USER=user
export PLAYWRIGHT_DEVICE_PASSWORD=Password1
export PLAYWRIGHT_SSH_USER=root
export PLAYWRIGHT_SSH_PASSWORD=Password1
export PLAYWRIGHT_PROJECT=${PROJECT}
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact/${ARTIFACT_SUBDIR}

${DIR}/../../apt.sh sshpass openssh-client curl
${DIR}/wait-app.sh ${PLAYWRIGHT_APP_DOMAIN}
npm ci --no-audit --no-fund
npx playwright test --project=${PLAYWRIGHT_PROJECT} "$SPEC"
