FROM sifive/binutils-src:@SI5_VER@ as binutils
LABEL description="Build GDB for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base file readline-dev expat-dev python3-dev flex bison texinfo

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
    --with-pkgversion="SiFive @SI5_VER@"
RUN make -j$(nproc)
RUN make install
WORKDIR /

FROM alpine:@ALPINE_VERSION@
LABEL description="RISC-V GDB"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
COPY --from=binutils /usr/local/riscv-elf-gdb /usr/local/riscv-elf-gdb
WORKDIR /

# docker build -f gdb-riscv-sifive.dockerfile -t sifive/gdb-riscv:@ALPINE_VER@-@SI5_VER@ .

