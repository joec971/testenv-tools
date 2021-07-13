FROM sifive/llvm-src:@SI5_VER@ as clang
FROM newlib-src:v4.1.0 as newlib

FROM sifive/llvm-riscv:@ALPINE_VER@-@SI5_VER@ as builder
RUN apk update
RUN apk upgrade
RUN apk add build-base samurai cmake git patch vim python3 coreutils texinfo
COPY --from=clang /toolchain/llvm /toolchain/llvm
COPY --from=newlib /toolchain/newlib /toolchain/newlib
WORKDIR /toolchain

ENV CLANGPATH=/usr/local/clang
ENV xlen=32
ENV xtarget="riscv${xlen}-unknown-elf"
# if build=DEBUG, generated library are built with -g -Og, otherwise -Os
ENV build=@BUILD@
ENV prefix=${CLANGPATH}

RUN ln -s /usr/bin/python3 /usr/bin/python

ADD clang-riscv-sifive.sh /
ADD 0001-clearcache-baremetal-build.patch /
ADD 0002-int_cache-baremetal-build.patch /
RUN (cd /toolchain/llvm && \
     cat /0001-clearcache-baremetal-build.patch \
         /0002-int_cache-baremetal-build.patch | patch -p1)
RUN sh /clang-riscv-sifive.sh

WORKDIR /

FROM alpine:@ALPINE_VERSION@
LABEL description="RISC-V 32-bit environment"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANGPATH=/usr/local/clang
ENV xlen=32
ENV xtarget="riscv${xlen}-unknown-elf"
COPY --from=builder ${CLANGPATH}/${xtarget} \
     ${CLANGPATH}/${xtarget}
WORKDIR /

# docker build -f clang-riscv32-sifive.dockerfile -t sifive/clang-riscv32:@ALPINE_VER@-@SI5_VER@-n4.1 .
# if debug:
#  docker build -f clang-riscv32-sifive.dockerfile -t sifive/clang-riscv32_dbg:@ALPINE_VER@-@SI5_VER@-n4.1 .

