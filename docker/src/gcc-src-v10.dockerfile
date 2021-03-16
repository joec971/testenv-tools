FROM alpine:3.13.2
LABEL description="Store Git repository for GNU RISC-V toolchain"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add git
WORKDIR /toolchain
RUN git clone --depth 1 https://github.com/sifive/riscv-gcc -b sifive-gcc-10.2.0 gcc-10.2.0
WORKDIR /

# docker build -f gcc-v10.dockerfile -t gcc-src:v10.2.0 .
