FROM clang:v11.0.0 as clang
FROM newlib:v4.1.0 as newlib

FROM llvm-riscv:a3.12-v11.0.0 as builder
RUN apk update
# this is a workaround till llvm-riscv is rebased on Alpine 3.12.3+
RUN apk del ninja
RUN apk upgrade
RUN apk add build-base ninja cmake git patch vim python3 curl coreutils texinfo
COPY --from=clang /toolchain/llvm /toolchain/llvm
COPY --from=newlib /toolchain/newlib /toolchain/newlib
WORKDIR /toolchain

ENV CLANG11PATH=/usr/local/clang11
ENV xlen=32
ENV xtarget="riscv${xlen}-unknown-elf"
# if build=DEBUG, generated library are built with -g -Og, otherwise -Os
# ENV build=DEBUG
ENV prefix=${CLANG11PATH}

RUN ln -s /usr/bin/python3 /usr/bin/python

ADD clang-riscv-v11.sh /
RUN sh /clang-riscv-v11.sh

WORKDIR /

FROM alpine:3.12.3
LABEL description="RISC-V 32-bit environment"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANG11PATH=/usr/local/clang11
ENV xlen=32
ENV xtarget="riscv${xlen}-unknown-elf"
COPY --from=builder ${CLANG11PATH}/${xtarget} \
     ${CLANG11PATH}/${xtarget}
WORKDIR /

# docker build -f clang-riscv32-v11.dockerfile -t sifive/clang-riscv32:a3.12-v11.0.0-n4.1 .
# if debug:
#  docker build -f clang-riscv32-v11.dockerfile -t sifive/clang-riscv32_dbg:a3.12-v11.0.0-n4.1 .

