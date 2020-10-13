#!/bin/sh

export ORGANIZATION=$ORGANIZATION
export ACCESS_TOKEN=$ACCESS_TOKEN

if [ -z "${ORGANIZATION}" -o -z "${ACCESS_TOKEN}" ]; then
    echo "Missing credentials" >&2
    exit 1
fi

URL="https://api.github.com/repos/${ORGANIZATION}/testenv-tools/actions/runners/registration-token"

echo "Requesting registration token from ${URL}"
REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" -H "Accept: application/vnd.github.v3+json" "${URL}" | jq .token --raw-output)

cd /home/docker/actions-runner

./config.sh --url https://github.com/${ORGANIZATION}/testenv-tools --token ${REG_TOKEN}

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!

