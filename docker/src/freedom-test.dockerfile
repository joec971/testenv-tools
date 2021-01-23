#-------------------------------------------------------------------------------
# Build an small image base to perform unit test with a QEMU virtual machine
# Note that QEMU VM is not contained in this image
#-------------------------------------------------------------------------------
FROM alpine:3.13

LABEL description="Lightweigth test environment for QEMU & FPGA"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"

WORKDIR /

RUN apk update
RUN apk add glib pixman libgcc dtc coreutils mpfr4 xz libstdc++ ncurses libusb libusb-compat libftdi1
# if python is installed along with the above packages, an error is triggered
RUN apk add python3 py3-pip
RUN pip3 install pyserial

# docker build -f freedom-test.dockerfile -t freedom-test:tmp .
# docker run --name freedom-test_tmp -it freedom-test:tmp /bin/sh -c "exit"
# docker export freedom-test_tmp | docker import - sifive/freedom-test:a3.13-v1.1
# docker rm freedom-test_tmp
# docker rmi freedom-test:tmp
