# syntax=docker/dockerfile:1.0.0-experimental

FROM alpine:@ALPINE_VERSION@ as builder
LABEL description="Build binutils for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base gmp-dev mpfr-dev file git texinfo flex bison openssh-client git
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
WORKDIR /toolchain
RUN --mount=type=ssh git clone --depth 1 --branch sifive-binutils-@SI5_BRANCH@ \
    git@github.com:sifive/riscv-binutils-gdb-internal.git riscv-binutils-gdb
RUN ls -l
RUN mkdir /toolchain/build
WORKDIR /toolchain/build
ENV BU2PATH=/usr/local/riscv-elf-binutils
RUN ../riscv-binutils-gdb/configure \
    --prefix=${BU2PATH} \
    --target=riscv64-unknown-elf \
    --disable-shared \
    --disable-nls \
    --with-gmp \
    --with-mpfr \
    --disable-cloog-version-check \
    --enable-multilib \
    --enable-interwork \
    --enable-lto \
    --disable-werror \
    --disable-debug \
    --disable-gdb \
    --disable-gold \
    --with-pkgversion="SiFive @SI5_VER@"
RUN make -j$(nproc)
RUN make install
RUN strip ${BU2PATH}/bin/*
RUN (cd ${BU2PATH}/riscv64-unknown-elf/bin; \
     for but in *; do \
        rm ${but}; \
        ln -s ${BU2PATH}/bin/riscv64-unknown-elf-${but} ${but}; \
     done)
WORKDIR /

FROM alpine:@ALPINE_VERSION@
LABEL description="RISC-V binutils"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV BU2PATH=/usr/local/riscv-elf-binutils
ENV PATH=$PATH:${BU2PATH}/bin
COPY --from=builder ${BU2PATH} ${BU2PATH}
WORKDIR /

# Docker 18.09+ is required
# export DOCKER_BUILDKIT=1
# eval `ssh-agent -s`
# ssh-add ~/.ssh/id_...
# docker build  --ssh default -f binutils-riscv-sifive.dockerfile -t sifive/binutils-riscv:@ALPINE_VER@-@SI5_VER@ .
# unset DOCKER_BUILDKIT
