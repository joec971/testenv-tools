#!/bin/sh

. $(dirname $0)/versions.sh

docker login
docker push sifive/newlib-riscv:@ALPINE_VER@-@SI5_VER@-@NEWLIB_VER@
docker push sifive/compiler_rt-riscv:@ALPINE_VER@-@SI5_VER@
docker push sifive/clang-riscv:@ALPINE_VER@-@SI5_VER@
docker push sifive/llvm-riscv-nano:@ALPINE_VER@-@SI5_VER@
docker push sifive/binutils-riscv:@ALPINE_VER@-@SI5_VER@
docker push sifive/gcc-riscv:@ALPINE_VER@-@SI5_VER@
docker push sifive/gdb-riscv:@ALPINE_VER@-@SI5_VER@
docker push sifive/freedom-dev:@ALPINE_VER@-v1.1
docker push sifive/freedom-test:@ALPINE_VER@-v1.3
docker push sifive/openfpgaloader:@ALPINE_VER@-ad21a3b
docker push sifive/xc3sprog:@ALPINE_VER@-r795
docker push sifive/openocd-riscv:@ALPINE_VER@-v0.11.0a
