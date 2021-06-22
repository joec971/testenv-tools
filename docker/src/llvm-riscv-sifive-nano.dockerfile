FROM sifive/llvm-riscv:a3.13-r2021.06.1 as source

FROM alpine:3.13.5
LABEL description="RISC-V selected binary tools"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANGPATH=/usr/local/clang
WORKDIR ${CLANGPATH}

COPY --from=source ${CLANGPATH}/bin/llvm-addr2line \
                   ${CLANGPATH}/bin/llvm-dwarfdump \
                   ${CLANGPATH}/bin/llvm-nm \
                   ${CLANGPATH}/bin/llvm-strings \
    ${CLANGPATH}/bin/
WORKDIR /

# Selected tools that are useful to run and validate unit tests.
# This is not the full toolchain.

# docker build -f llvm-riscv-sifive-nano.dockerfile -t sifive/llvm-riscv-nano:a3.13-r2021.06.1 .
