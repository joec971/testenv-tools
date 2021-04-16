FROM clang:v12.0.0 as clang
FROM newlib:v4.1.0 as newlib

FROM llvm-riscv:a3.13-v12.0.0 as builder
RUN apk update
RUN apk upgrade
RUN apk add build-base samurai cmake git patch vim python3 curl coreutils texinfo
COPY --from=clang /toolchain/llvm /toolchain/llvm
COPY --from=newlib /toolchain/newlib /toolchain/newlib
WORKDIR /toolchain

ENV CLANGPATH=/usr/local/clang12
ENV xlen=64
ENV xtarget="riscv${xlen}-unknown-elf"
# if build=DEBUG, generated library are built with -g -Og, otherwise -Os
# ENV build=DEBUG
ENV prefix=${CLANGPATH}

RUN ln -s /usr/bin/python3 /usr/bin/python

ADD clang-riscv-v12.sh /
RUN sh /clang-riscv-v12.sh

WORKDIR /

FROM alpine:3.13
LABEL description="RISC-V 64-bit environment"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANGPATH=/usr/local/clang12
ENV xlen=64
ENV xtarget="riscv${xlen}-unknown-elf"
COPY --from=builder ${CLANGPATH}/${xtarget} \
     ${CLANGPATH}/${xtarget}
WORKDIR /

# docker build -f clang-riscv64-v12.dockerfile -t sifive/clang-riscv64:a3.13-v12.0.0-n4.1 .
# if debug:
#  docker build -f clang-riscv64-v12.dockerfile -t sifive/clang-riscv64_dbg:a3.13-v12.0.0-n4.1 .
