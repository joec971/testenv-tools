#!/bin/sh
docker login
docker push sifive/clang-riscv64_dbg:a3.13-r2021.06.1-n4.1
docker push sifive/clang-riscv32_dbg:a3.13-r2021.06.1-n4.1
docker push sifive/clang-riscv32:a3.13-r2021.06.1-n4.1
docker push sifive/clang-riscv64:a3.13-r2021.06.1-n4.1
docker push sifive/clang-riscv:a3.13-r2021.06.1
docker push sifive/llvm-riscv-nano:a3.13-r2021.06.1
docker push sifive/qemu-fdt:d1b72f48
docker push sifive/binutils-riscv:a3.13-r2021.06.1
docker push sifive/gcc-riscv:a3.13-r2021.06.1
docker push sifive/freedom-dev:a3.13-v1.1
docker push sifive/freedom-test:a3.13-v1.3
docker push sifive/openfpgaloader:a3.13-ad21a3b
docker push sifive/xc3sprog:a3.13-r795
docker push sifive/openocd-riscv:a3.13-gd52e4668a
