FROM alpine:3.13
LABEL description="Store Git repository for LLVM/Clang 12 toolchain"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add curl
WORKDIR /toolchain
RUN curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.0/llvm-project-12.0.0.src.tar.xz
RUN [ "9ed1688943a4402d7c904cc4515798cdb20080066efa010fe7e1f2551b423628" = \
      "$(sha256sum llvm-project-12.0.0.src.tar.xz | cut -d' ' -f1)" ] && \
      tar xf llvm-project-12.0.0.src.tar.xz && \
      mv llvm-project-12.0.0.src llvm && rm llvm-project-12.0.0.src.tar.xz
WORKDIR /

# docker build -f llvm-src-riscv-v12.dockerfile -t llvm-src:v12.0.0 .
