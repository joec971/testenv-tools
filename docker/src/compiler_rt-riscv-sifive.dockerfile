FROM sifive/llvm-src:@SI5_VER@ as clang

FROM sifive/llvm-riscv:@ALPINE_VER@-@SI5_VER@ as builder
RUN apk update
RUN apk upgrade
RUN apk add build-base samurai cmake git patch vim python3 coreutils
COPY --from=clang /toolchain/llvm /toolchain/llvm
WORKDIR /toolchain

ENV CLANGPATH=/usr/local/clang
# if build=DEBUG, generated library are built with -g -Og, otherwise -Os
ENV build=@BUILD@
ENV prefix=${CLANGPATH}/lib/clang

RUN ln -s /usr/bin/python3 /usr/bin/python

ADD compiler_rt-riscv-sifive.sh /
ADD 0001-clearcache-baremetal-build.patch /
ADD 0002-int_cache-baremetal-build.patch /
ADD 0003-atomic-memfunc-baremetal-build.patch /
RUN (cd /toolchain/llvm && \
    cat /0001-clearcache-baremetal-build.patch \
    /0002-int_cache-baremetal-build.patch \
    /0003-atomic-memfunc-baremetal-build.patch | patch -p1)
RUN sh /compiler_rt-riscv-sifive.sh

WORKDIR /

FROM alpine:@ALPINE_VERSION@
LABEL description="RISC-V 32-bit environment"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANGPATH=/usr/local/clang
ENV prefix=${CLANGPATH}/lib/clang
COPY --from=builder ${prefix} ${prefix}
WORKDIR /

# docker build -f compiler_rt-riscv-sifive.dockerfile -t sifive/compiler_rt-riscv:@ALPINE_VER@-@SI5_VER@ .
# if debug:
#  docker build -f compiler_rt-riscv-sifive.dockerfile -t compiler_rt-riscv_dbg:@ALPINE_VER@-@SI5_VER@ .
