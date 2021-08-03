FROM newlib-src:v@NEWLIB_VERSION@ as newlib

FROM sifive/llvm-riscv:@ALPINE_VER@-@SI5_VER@ as builder
RUN apk update
RUN apk upgrade
RUN apk add build-base git patch vim coreutils texinfo
COPY --from=newlib /toolchain/newlib /toolchain/newlib
WORKDIR /toolchain

ENV CLANGPATH=/usr/local/clang
# if build=DEBUG, generated library are built with -g -Og, otherwise -Os
ENV build=@BUILD@
ENV prefix=${CLANGPATH}/riscv64-unknown-elf

RUN ln -s /usr/bin/python3 /usr/bin/python

ADD newlib-riscv-sifive.sh /
RUN sh /newlib-riscv-sifive.sh

WORKDIR /

FROM alpine:@ALPINE_VERSION@
LABEL description="RISC-V 32-bit environment"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANGPATH=/usr/local/clang
ENV prefix=${CLANGPATH}/riscv64-unknown-elf
COPY --from=builder ${prefix} ${prefix}
WORKDIR /

# docker build -f newlib-riscv-sifive.dockerfile -t sifive/newlib-riscv:@ALPINE_VER@-@SI5_VER@-@NEWLIB_VER@ .
# if debug:
#  docker build -f newlib-riscv-sifive.dockerfile -t newlib-riscv_dbg:@ALPINE_VER@-@SI5_VER@-@NEWLIB_VER@ .
