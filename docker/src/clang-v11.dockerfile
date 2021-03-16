FROM alpine:3.13
LABEL description="Store Git repository for LLVM/Clang 11 toolchain"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add curl
WORKDIR /toolchain
RUN curl -LO https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.1/llvm-project-11.0.1.src.tar.xz
RUN [ "af95d00f833dd67114b21c3cfe72dff2e1cdab627651f977b087a837136d653b" = \
      "$(sha256sum llvm-project-11.0.1.src.tar.xz | cut -d' ' -f1)" ] && \
      tar xf llvm-project-11.0.1.src.tar.xz && \
      mv llvm-project-11.0.1.src llvm && rm llvm-project-11.0.1.src.tar.xz
WORKDIR /

# docker build -f clang-v11.dockerfile -t clang-src:v11.0.1 .
