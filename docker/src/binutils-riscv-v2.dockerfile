FROM alpine:3.13.2 as builder
LABEL description="Build binutils for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base gmp-dev mpfr-dev file git texinfo flex bison
WORKDIR /toolchain
RUN git clone --depth 1 https://github.com/sifive/riscv-binutils-gdb.git -b sifive-rvv-1.0.x-zfh-rvb
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
    --disable-gold
RUN make -j$(nproc)
RUN make install
RUN strip ${BU2PATH}/bin/*
RUN (cd ${BU2PATH}/riscv64-unknown-elf/bin; \
     for but in *; do \
        rm ${but}; \
        ln -s ${BU2PATH}/bin/riscv64-unknown-elf-${but} ${but}; \
     done)
WORKDIR /

FROM alpine:3.13.2
LABEL description="RISC-V binutils"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV BU2PATH=/usr/local/riscv-elf-binutils
ENV PATH=$PATH:${BU2PATH}/bin
COPY --from=builder ${BU2PATH} ${BU2PATH}
WORKDIR /

##docker build -f binutils-riscv-v2.dockerfile -t sifive/binutils-riscv:a3.13-v2.36.1 .
# docker build -f binutils-riscv-v2.dockerfile -t sifive/binutils-riscv:a3.13-sifive .