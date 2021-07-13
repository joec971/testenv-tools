# syntax=docker/dockerfile:1.0.0-experimental

FROM alpine:@ALPINE_VERSION@ as builder
LABEL description="Store Git repository for RISC-V binutils"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add openssh-client git
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
WORKDIR /toolchain
RUN --mount=type=ssh git clone --depth 1 --branch sifive-binutils-@SI5_BRANCH@ \
    git@github.com:sifive/riscv-binutils-gdb-internal.git riscv-binutils-gdb
WORKDIR /

# Docker 18.09+ is required
# export DOCKER_BUILDKIT=1
# eval `ssh-agent -s`
# ssh-add ~/.ssh/id_...
# docker build --ssh default -f binutils-src-sifive.dockerfile -t sifive/binutils-src:@SI5_VER@ .
# unset DOCKER_BUILDKIT
