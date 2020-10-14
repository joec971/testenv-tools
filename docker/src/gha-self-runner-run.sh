#!/bin/sh

# should be private (400 or 600)!
# Personal Access Token should be generated from the GitHub web UI
PAT="${HOME}/.gha-self-runner.pat"

# run from host;
# beware that this (-v option) exposes all the docker host containerS to the
# runner, which is a security issue with a public repository
# do not let this container w/o supervision (no detach or other background
# run).
docker run \
	--env ORGANIZATION=sifive \
	--env ACCESS_TOKEN="$(cat ${PAT})" \
	--name gha-runner \
    -u docker:$(grep docker /etc/group | cut -d: -f3) \
	-v /var/run/docker.sock:/var/run/docker.sock \
	gha-runner:2.273.5

