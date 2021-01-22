FROM llvm-riscv:a3.13-v11.0.1 as source
# FROM sifive/clang-riscv:a3.13-v11.0.1 as source

FROM alpine:3.13
LABEL description="RISC-V selected binary tools"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
ENV CLANG11PATH=/usr/local/clang11
WORKDIR ${CLANG11PATH}

COPY --from=source ${CLANG11PATH}/bin/llvm-addr2line \
                   ${CLANG11PATH}/bin/llvm-dwarfdump \
                   ${CLANG11PATH}/bin/llvm-nm \
    ${CLANG11PATH}/bin/
WORKDIR /

# Selected tools that are useful to run and validate unit tests.
# This is not the full toolchain.

# docker build -f llvm-riscv-v11-nano.dockerfile -t sifive/llvm-riscv-nano:a3.13-v11.0.1 .
