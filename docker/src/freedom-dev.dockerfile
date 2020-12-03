#-------------------------------------------------------------------------------
# Build an small image base for compiling/building bare metal target software
# Note that toolchain is not contained in this image
#-------------------------------------------------------------------------------
FROM alpine:3.12.1

ENV CLANG11PATH=/usr/local/clang11
ENV BU235PATH=/usr/local/riscv-elf-binutils
ENV PATH=$PATH:${CLANG11PATH}/bin:${BU235PATH}/bin

WORKDIR /

LABEL description="Light development environment"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"

RUN apk update
RUN apk upgrade
RUN apk add ninja cmake git curl
# if python is installed along with abobe package, an error is triggered
RUN apk add python3 py3-pip
# if wheel is installed along with mako, mako does not detect it
RUN pip3 install wheel
# mako is a templating engine used to generate C files
RUN pip3 install mako pyyaml

# docker build -f freedom-dev.dockerfile -t freedom-dev:tmp .
# docker run --name freedom-dev_tmp -it freedom-dev:tmp /bin/sh -c "exit"
# docker export freedom-dev_tmp | docker import - freedom-dev:a3.12-v1.1
# docker rm freedom-dev_tmp
# docker rmi freedom-dev:tmp
# docker tag freedom-dev:a3.12-v1.1 sifive/freedom-dev:a3.12-v1.1