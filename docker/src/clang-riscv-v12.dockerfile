FROM llvm-riscv:a3.13-v12.0.0 as source

FROM alpine:3.13
LABEL description="RISC-V toolchain"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANGPATH=/usr/local/clang12
WORKDIR ${CLANGPATH}

COPY --from=source ${CLANGPATH}/bin ${CLANGPATH}/bin
COPY --from=source ${CLANGPATH}/lib/*.so ${CLANGPATH}/lib/
COPY --from=source ${CLANGPATH}/lib/clang ${CLANGPATH}/lib/clang
COPY --from=source ${CLANGPATH}/lib/cmake ${CLANGPATH}/lib/cmake
COPY --from=source ${CLANGPATH}/libexec ${CLANGPATH}/libexec
COPY --from=source ${CLANGPATH}/share ${CLANGPATH}/share
COPY --from=source ${CLANGPATH}/include ${CLANGPATH}/include
WORKDIR /

# because LLVM C++ library build process needs the LLVM native .a libraries,
# we need a two-stage process:
# * build a full clang-riscv image required to build the toolchain, then
# * build a .a -stripped version of the clang-riscv image useful to build
#   target application, saving image storage footprint
# This dockerfile is dedicated to build the second, enlightened one.

# docker build -f clang-riscv-v12.dockerfile -t sifive/clang-riscv:a3.13-v12.0.0 .
