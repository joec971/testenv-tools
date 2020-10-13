FROM alpine:3.12
LABEL description="Store Git repository for LLVM/Clang 11 toolchain"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add curl
WORKDIR /toolchain
RUN curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/llvm-project-11.0.0.tar.xz
RUN [ "b7b639fc675fa1c86dd6d0bc32267be9eb34451748d2efd03f674b773000e92b" = \
      "$(sha256sum llvm-project-11.0.0.tar.xz | cut -d' ' -f1)" ] && \
    tar xf llvm-project-11.0.0.tar.xz && \
    mv llvm-project-11.0.0 llvm && rm llvm-project-11.0.0.tar.xz
WORKDIR /

# docker build -f clang-v11.dockerfile -t clang:v11.0.0 .
