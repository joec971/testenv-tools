FROM alpine:3.12.3 as builder
LABEL description="Build GDB for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base file curl readline-dev expat python3-dev texinfo
WORKDIR /toolchain
RUN curl -LO "http://ftp.gnu.org/gnu/gdb/gdb-10.1.tar.xz"
RUN [ "f82f1eceeec14a3afa2de8d9b0d3c91d5a3820e23e0a01bbb70ef9f0276b62c0" = \
    "$(sha256sum gdb-10.1.tar.xz | cut -d' ' -f1)" ] && \
    tar xvf gdb-10.1.tar.xz
RUN mkdir /toolchain/build
WORKDIR /toolchain/build
RUN ../gdb-10.1/configure \
    --prefix=/usr/local/riscv-elf-gdb \
    --target=riscv64-unknown-elf \
    --disable-shared \
    --disable-nls \
    --without-gmp \
    --without-mpfr \
    --without-mpc \
    --without-cloog \
    --with-python3 \
    --enable-lto \
    --disable-werror \
    --disable-debug
RUN make -j$(nproc)
RUN make install
WORKDIR /

FROM alpine:3.12.3
LABEL description="RISC-V GDB"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
COPY --from=builder /usr/local/riscv-elf-gdb /usr/local/riscv-elf-gdb
ENV PATH=$PATH:/usr/local/riscv-elf-gdb/bin
WORKDIR /

# docker build -f gdb-riscv-v10.dockerfile -t gdb-riscv:a3.12-v10.1 .
# docker tag gdb-riscv:a3.12-v10.1 sifive/gdb-riscv:a3.12-v10.1
