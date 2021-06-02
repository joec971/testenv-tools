# syntax=docker/dockerfile:1.0.0-experimental

FROM alpine:3.13.5
LABEL description="Store Git repository for LLVM/Clang SiFive toolchain"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add openssh-client git
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
WORKDIR /toolchain
RUN --mount=type=ssh git clone git@github.com:sifive/riscv-llvm-internal llvm
WORKDIR /toolchain/llvm
RUN git checkout -t origin/sifive-llvm-2021.04-release -b sifive-llvm-2021.04-release
WORKDIR /

# Docker 18.09+ is required
# export DOCKER_BUILDKIT=1
# eval `ssh-agent -s`
# ssh-agent ~/.ssh/id_...
# docker build --ssh default -f llvm-src-riscv-sifive.dockerfile -t sifive/llvm-src:r202104 .
# unset DOCKER_BUILDKIT
