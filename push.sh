#!/bin/sh
docker login
docker push sifive/xc3sprog:a3.13-r795        
docker push sifive/openocd-riscv:a3.13-gd52e4668a  
docker push sifive/clang-riscv64_dbg:a3.13-v11.0.1-n4.1
docker push sifive/clang-riscv32_dbg:a3.13-v11.0.1-n4.1
docker push sifive/clang-riscv64:a3.13-v11.0.1-n4.1
docker push sifive/clang-riscv32:a3.13-v11.0.1-n4.1
docker push sifive/gdb-riscv:a3.13-v10.1       
docker push sifive/binutils-riscv:a3.13-v2.35.1     
docker push sifive/clang-riscv:a3.13-v11.0.1        