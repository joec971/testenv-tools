FROM llvm-riscv:a3.13-v12.0.0 as source
# FROM sifive/clang-riscv:a3.13-v12.0.0 as source

FROM alpine:3.13
LABEL description="RISC-V selected binary tools"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANGPATH=/usr/local/clang12
WORKDIR ${CLANGPATH}

COPY --from=source ${CLANGPATH}/bin/llvm-addr2line \
                   ${CLANGPATH}/bin/llvm-dwarfdump \
                   ${CLANGPATH}/bin/llvm-nm \
                   ${CLANGPATH}/bin/llvm-strings \
    ${CLANGPATH}/bin/
WORKDIR /

# Selected tools that are useful to run and validate unit tests.
# This is not the full toolchain.

# docker build -f llvm-riscv-v12-nano.dockerfile -t sifive/llvm-riscv-nano:a3.13-v12.0.0 .
