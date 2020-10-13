#!/bin/sh

# should be private (400 or 600)!
PAT="${HOME}/.gha-self-runner.pat"

docker run \
        --detach \
	--env ORGANIZATION=sifive \
	--env ACCESS_TOKEN="$(cat ${PAT})" \
	--name gha-runner \
	-v /var/run/docker.sock:/var/run/docker.sock \
	gha-runner:2.273.5

