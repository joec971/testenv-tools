FROM gcc-src:v10.2.0 as gcc
FROM newlib-src:v4.1.0 as newlib
FROM sifive/binutils-riscv:a3.13-v2.36.1 as builder
LABEL description="Build a GCC 10 toolchain for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com"
RUN apk update
RUN apk add build-base git python3-dev gawk pkgconfig texinfo patchutils curl \
            bc make autoconf automake bison flex libtool m4 \
            gmp-dev isl-dev mpfr-dev mpc1-dev expat-dev zlib-dev
COPY --from=gcc /toolchain/gcc-10.2.0 /toolchain/gcc-10.2.0
COPY --from=newlib /toolchain/newlib /toolchain/newlib

ENV PATH=/usr/local/riscv-elf-binutils/bin:/usr/local/riscv-elf-gcc/bin:$PATH

WORKDIR /toolchain/gcc-10.2.0/build-stage1

# stage1
# GCC makes the assumption the Python3 executable is called 'python'
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN ../configure \
     --target=riscv64-unknown-elf \
     --prefix=/usr/local/riscv-elf-gcc \
     --disable-shared \
     --disable-threads \
     --disable-tls \
     --enable-languages=c,c++ \
     --with-system-zlib \
     --with-newlib \
     --with-sysroot=/usr/local/riscv-elf-gcc/riscv64-unknown-elf \
     --disable-libmudflap \
     --disable-libssp \
     --disable-libquadmath \
     --disable-libgomp \
     --disable-nls \
     --disable-tm-clone-registry \
     --disable-multilib \
     --src=.. \
     --with-python=/usr/bin/python3 \
     --with-abi=lp64d \
     --with-arch=rv64imafdc \
     --with-tune=rocket \
     CFLAGS_FOR_TARGET="-Os -mcmodel=medlow" \
     CXXFLAGS_FOR_TARGET="-Os -mcmodel=medlow"
RUN make -j$(nproc) all-gcc >/dev/null
RUN make install-gcc
# GCC makes the assumption the binutils are installed within its own install dir...
RUN ln -s /usr/local/riscv-elf-binutils/riscv64-unknown-elf /usr/local/riscv-elf-gcc/riscv64-unknown-elf

WORKDIR /toolchain/newlib/build-newlib
RUN ../configure \
    --target=riscv64-unknown-elf \
    --prefix=/usr/local/riscv-elf-gcc \
    --enable-newlib-io-long-double \
    --enable-newlib-io-long-long \
    --enable-newlib-io-c99-formats \
    --enable-newlib-register-fini \
    CFLAGS="-B /usr/local/riscv-elf-binutils/" \
    CFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE -mcmodel=medlow" \
    CXXFLAGS_FOR_TARGET="-O2 -D_POSIX_MODE -mcmodel=medlow"
RUN make -j$(nproc) >/dev/null
RUN make install

# WORKDIR /toolchain/newlib/build-newlib-nano
# RUN ../configure \
#     --target=riscv64-unknown-elf \
#     --prefix=/toolchain/newlib/install-newlib-nano \
#     --enable-newlib-reent-small \
#     --disable-newlib-fvwrite-in-streamio \
#     --disable-newlib-fseek-optimization \
#     --disable-newlib-wide-orient \
#     --enable-newlib-nano-malloc \
#     --disable-newlib-unbuf-stream-opt \
#     --enable-lite-exit \
#     --enable-newlib-global-atexit \
#     --enable-newlib-nano-formatted-io \
#     --disable-newlib-supplied-syscalls \
#     --disable-nls \
#     CFLAGS_FOR_TARGET="-Os -ffunction-sections -fdata-sections -Os -mcmodel=medlow" \
#     CXXFLAGS_FOR_TARGET="-Os -ffunction-sections -fdata-sections -Os -mcmodel=medlow"
# RUN make -j$(nproc) >/dev/null
# RUN make install

WORKDIR /toolchain/gcc-10.2.0/build-gcc-stage2
RUN ../configure \
    --target=riscv64-unknown-elf \
    --prefix=/usr/local/riscv-elf-gcc \
    --disable-shared \
    --disable-threads \
    --enable-languages=c,c++ \
    --with-system-zlib \
    --enable-tls \
    --with-newlib \
    --with-sysroot=/usr/local/riscv-elf-gcc/riscv64-unknown-elf \
    --with-native-system-header-dir=/include \
    --disable-libmudflap \
    --disable-libssp \
    --disable-libquadmath \
    --disable-libgomp \
    --disable-nls \
    --disable-tm-clone-registry \
    --src=.. \
    --disable-multilib \
    --with-abi=lp64d \
    --with-arch=rv64imafdc \
    --with-tune=rocket \
    CFLAGS_FOR_TARGET="-Os -mcmodel=medlow" \
    CXXFLAGS_FOR_TARGET="-Os -mcmodel=medlow"
RUN make -j$(nproc)
RUN make install

RUN strip /usr/local/riscv-elf-gcc/bin/*
RUN strip /usr/local/riscv-elf-gcc/libexec/gcc/riscv64-unknown-elf/10.2.0/c*
RUN strip /usr/local/riscv-elf-gcc/libexec/gcc/riscv64-unknown-elf/10.2.0/lto*
RUN strip /usr/local/riscv-elf-gcc/libexec/gcc/riscv64-unknown-elf/10.2.0/plugin/*
RUN strip /usr/local/riscv-elf-gcc/libexec/gcc/riscv64-unknown-elf/10.2.0/install-tools/fixincl
