FROM sifive/gcc-src:@SI5_VER@ as gcc
FROM newlib-src:v@NEWLIB_VERSION@ as newlib
FROM sifive/binutils-riscv:@ALPINE_VER@-@SI5_VER@ as builder
LABEL description="Build a GCC 10 toolchain for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com"
RUN apk update
RUN apk add build-base git python3-dev gawk pkgconfig texinfo patchutils \
    bc make autoconf automake bison flex libtool m4 \
    gmp-dev isl-dev mpfr-dev mpc1-dev expat-dev zlib-dev
COPY --from=gcc /toolchain/gcc /toolchain/gcc
COPY --from=newlib /toolchain/newlib /toolchain/newlib

ENV GCCPATH=/usr/local/riscv-elf-gcc
ENV BU2PATH=/usr/local/riscv-elf-binutils
ENV PATH=${BU2PATH}/bin:${GCCPATH}/bin:$PATH
ENV MCMODEL="medany"

# GCC makes the assumption the Python3 executable is called 'python'
RUN ln -s /usr/bin/python3 /usr/bin/python

# GCC makes the assumption the binutils are installed within its own install dir
RUN mkdir ${GCCPATH}
RUN tar cf - -C ${BU2PATH} riscv64-unknown-elf | tar xf - -C ${GCCPATH}

WORKDIR /toolchain/gcc/build-gcc1
RUN ../configure \
    --target=riscv64-unknown-elf \
    --prefix=${GCCPATH} \
    --disable-shared \
    --disable-threads \
    --disable-tls \
    --enable-languages=c \
    --with-system-zlib \
    --with-newlib \
    --with-sysroot=${GCCPATH}/riscv64-unknown-elf \
    --disable-libmudflap \
    --disable-libssp \
    --disable-libquadmath \
    --disable-libgomp \
    --disable-nls \
    --disable-tm-clone-registry \
    --disable-multilib \
    --src=.. \
    --with-python=/usr/bin/python3 \
    --with-pkgversion="SiFive @SI5_VER@" \
    --with-abi=lp64d \
    --with-arch=rv64imafdc \
    CFLAGS_FOR_TARGET="-Os -mcmodel=${MCMODEL}" \
    CXXFLAGS_FOR_TARGET="-Os -mcmodel=${MCMODEL}"
RUN make -j$(nproc) all-gcc >/dev/null
RUN make install-gcc

WORKDIR /toolchain/newlib/build-newlib1
RUN ../configure \
    --target=riscv64-unknown-elf \
    --prefix=${GCCPATH} \
    --enable-newlib-io-long-double \
    --enable-newlib-io-long-long \
    --enable-newlib-io-c99-formats \
    --enable-newlib-register-fini \
    CFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE -mcmodel=${MCMODEL}" \
    CXXFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE -mcmodel=${MCMODEL}"
RUN make -j$(nproc) >/dev/null
RUN make install

WORKDIR /toolchain/gcc/build-gcc2
RUN ../configure \
    --target=riscv64-unknown-elf \
    --prefix=${GCCPATH} \
    --disable-shared \
    --disable-threads \
    --enable-languages=c,c++ \
    --with-system-zlib \
    --enable-tls \
    --with-newlib \
    --with-sysroot=${GCCPATH}/riscv64-unknown-elf \
    --with-native-system-header-dir=/include \
    --disable-libmudflap \
    --disable-libssp \
    --disable-libquadmath \
    --disable-libgomp \
    --disable-nls \
    --disable-tm-clone-registry \
    --src=.. \
    --enable-multilib \
    --with-pkgversion="SiFive @SI5_VER@" \
    --with-abi=lp64d \
    --with-arch=rv64imafdc \
    CFLAGS_FOR_TARGET="-Os -mcmodel=${MCMODEL}" \
    CXXFLAGS_FOR_TARGET="-Os -mcmodel=${MCMODEL}"
RUN make -j$(nproc) >/dev/null
RUN rm -rf ${GCCPATH}
RUN mkdir ${GCCPATH}
RUN tar cf - -C ${BU2PATH} riscv64-unknown-elf | tar xf - -C ${GCCPATH}
RUN make install

# NANO newlib version
WORKDIR /toolchain/newlib/build-newlib2
RUN ../configure \
    --target=riscv64-unknown-elf \
    --prefix=${GCCPATH}  \
    --enable-newlib-reent-small \
    --disable-newlib-fvwrite-in-streamio \
    --disable-newlib-fseek-optimization \
    --disable-newlib-wide-orient \
    --enable-newlib-nano-malloc \
    --disable-newlib-unbuf-stream-opt \
    --enable-lite-exit \
    --enable-newlib-global-atexit \
    --enable-newlib-nano-formatted-io \
    --disable-newlib-supplied-syscalls \
    --disable-nls \
    CFLAGS_FOR_TARGET="-Os -ffunction-sections -fdata-sections -Os -mcmodel=${MCMODEL}" \
    CXXFLAGS_FOR_TARGET="-Os -ffunction-sections -fdata-sections -Os -mcmodel=${MCMODEL}"
RUN make -j$(nproc) >/dev/null
RUN make install

RUN strip ${GCCPATH}/bin/*
RUN strip ${GCCPATH}/libexec/gcc/riscv64-unknown-elf/*/c*
RUN strip ${GCCPATH}/libexec/gcc/riscv64-unknown-elf/*/lto*
RUN strip ${GCCPATH}/libexec/gcc/riscv64-unknown-elf/*/plugin/*
RUN strip ${GCCPATH}/libexec/gcc/riscv64-unknown-elf/*/install-tools/fixincl

FROM alpine:@ALPINE_VERSION@
LABEL description="RISC-V GNU toolchain"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV GCCPATH=/usr/local/riscv-elf-gcc
WORKDIR ${GCCPATH}

COPY --from=builder ${GCCPATH} ${GCCPATH}
WORKDIR /

# docker build -f gcc-riscv-sifive.dockerfile -t sifive/gcc-riscv:@ALPINE_VER@-@SI5_VER@ .
