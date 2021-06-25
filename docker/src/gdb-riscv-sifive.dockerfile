# syntax=docker/dockerfile:1.0.0-experimental

FROM alpine:3.13.5 as builder
LABEL description="Build GDB for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base file readline-dev expat-dev python3-dev flex bison texinfo openssh-client git
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
WORKDIR /toolchain
RUN --mount=type=ssh git clone --depth 1 --branch sifive-binutils-2021.06.1 \
    git@github.com:sifive/riscv-binutils-gdb-internal.git riscv-binutils-gdb
RUN mkdir /toolchain/build
WORKDIR /toolchain/build
RUN ../riscv-binutils-gdb/configure \
    --prefix=/usr/local/riscv-elf-gdb \
    --target=riscv64-unknown-elf \
    --enable-gdb \
    --disable-shared \
    --disable-binutils \
    --disable-ld \
    --disable-gold \
    --disable-gas \
    --disable-sim \
    --disable-gprof \
    --disable-nls \
    --without-gmp \
    --without-mpfr \
    --without-mpc \
    --without-cloog \
    --with-python3 \
    --with-expat \
    --enable-lto \
    --disable-werror \
    --disable-debug \
    --with-pkgversion="SiFive r2021.06.1"
RUN make -j$(nproc)
RUN make install
WORKDIR /

FROM alpine:3.13.5
LABEL description="RISC-V GDB"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
COPY --from=builder /usr/local/riscv-elf-gdb /usr/local/riscv-elf-gdb
WORKDIR /

# Docker 18.09+ is required
# export DOCKER_BUILDKIT=1
# eval `ssh-agent -s`
# ssh-add ~/.ssh/id_...
# docker build  --ssh default -f gdb-riscv-sifive.dockerfile -t sifive/gdb-riscv:a3.13-r2021.06.1 .
# unset DOCKER_BUILDKIT