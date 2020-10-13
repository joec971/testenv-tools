FROM debian:10.5 AS gha-runner
LABEL description="GitHub Actions self-runner container"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"

ARG RUNNER_VERSION="2.273.5"

RUN apt-get update -y && apt-get upgrade -y && useradd -m docker
RUN apt-get install -y curl docker.io jq

USER docker
RUN mkdir /home/docker/actions-runner
WORKDIR /home/docker/actions-runner

RUN curl -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz | \
    tar xzf -

USER root
RUN bin/installdependencies.sh 
COPY gha-self-runner-start.sh start.sh
RUN chmod +x start.sh

USER docker
ENTRYPOINT ["./start.sh"]

# docker build -f gha-self-runner.dockerfile -t gha-runner:${RUNNER_VERSION} .
# docker run -ti -v /var/run/docker.sock:/var/run/docker.sock gha-runner:${RUNNER_VERSION}

