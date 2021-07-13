FROM sifive/llvm-src:@SI5_VER@
ENV CLANGPATH=/usr/local/clang
LABEL description="Build a SiFive LLVM/Clang toolchain for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com"
RUN apk update
RUN apk add build-base samurai cmake file python3-dev libedit-dev swig git
WORKDIR /toolchain/llvm/build
RUN cmake -G Ninja -Wno-dev \
   -DCMAKE_INSTALL_PREFIX=${CLANGPATH} \
   -DCMAKE_BUILD_TYPE=Release \
   -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld" \
   -DLLVM_ENABLE_SPHINX=False \
   -DLLVM_INCLUDE_TESTS=False \
   -DLLVM_TARGETS_TO_BUILD=RISCV \
   -DLLVM_INSTALL_UTILS=ON \
   -DLLVM_DEFAULT_TARGET_TRIPLE=riscv64-elf \
   -DCMAKE_CROSSCOMPILING=ON \
   -DLLVM_OPTIMIZED_TABLEGEN=ON \
   ../llvm
RUN ninja
RUN ninja install
RUN mkdir -p ${CLANGPATH}/share/man/man1 ${CLANGPATH}/share/man/man7
RUN cp ../lld/docs/ld.lld.1 ../llvm/docs/llvm-objdump.1 ${CLANGPATH}/share/man/man1/
RUN cp ../llvm/docs/re_format.7 ${CLANGPATH}/share/man/man7/
ENV PATH=${PATH}:${CLANGPATH}/bin
RUN file ${CLANGPATH}/bin/* | grep ELF | cut -d: -f1 | xargs strip
WORKDIR /


# there should be at least 2GB/RAM per core to build

# because LLVM C++ library build process needs the LLVM native .a libraries,
# we need a two-stage process:
# * build a full clang-riscv image required to build the toolchain, then
# * build a .a -stripped version of the clang-riscv image useful to build
#   target application, saving image storage footprint
# This dockerfile is dedicated to build the first, full and large one. This
# on is therefore never pushed to the docker hub, as it only lasts for the
# time required to build the toolchain itself

# docker build -f llvm-riscv-sifive.dockerfile -t sifive/llvm-riscv:@ALPINE_VER@-@SI5_VER@ .
