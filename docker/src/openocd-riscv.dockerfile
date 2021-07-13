FROM alpine:@ALPINE_VERSION@ as builder
LABEL description="Build OpenOCD for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base autoconf automake libtool pkgconfig texinfo coreutils git patch curl
RUN apk add libusb-dev libftdi1-dev
WORKDIR /
RUN git clone --depth 1 --branch v0.11.0 https://git.code.sf.net/p/openocd/code openocd
RUN curl -LO https://gist.githubusercontent.com/sifive-eblot/a5299eb1f132a00bf45ad97dff4fe78d/raw/ded99a42d5b4f118ec57c7f8c7c4e16bd2b61738/elf64.patch && \
    [ "d267ba8010e04e88a7e4c0dbd78fdcfa6972387f28045bf986ac53ed17704500" = \
    "$(sha256sum elf64.patch | cut -d' ' -f1)" ]
WORKDIR /openocd
RUN patch -p1 < ../elf64.patch
RUN mkdir build
RUN ls -l
RUN ./bootstrap
WORKDIR /openocd/build
RUN ../configure \
    --prefix=/usr/local/riscv-openocd \
    --enable-verbose \
    --enable-verbose-jtag-io \
    --enable-ftdi \
    --enable-jlink \
    --disable-doxygen-html \
    --disable-doxygen-pdf \
    --disable-werror \
    --disable-dummy \
    --disable-stlink \
    --disable-ti-icdi \
    --disable-ulink \
    --disable-usb-blaster-2 \
    --disable-ft232r \
    --disable-vsllink \
    --disable-xds110 \
    --disable-osbdm \
    --disable-opendous \
    --disable-aice \
    --disable-usbprog \
    --disable-rlink \
    --disable-armjtagew \
    --disable-kitprog \
    --disable-usb-blaster \
    --disable-presto \
    --disable-openjtag \
    --disable-parport \
    --disable-jtag_vpi \
    --disable-amtjtagaccel \
    --disable-zy1000-master \
    --disable-zy1000 \
    --disable-ep93xx \
    --disable-at91rm9200 \
    --disable-bcm2835gpio \
    --disable-imx_gpio \
    --disable-gw16012 \
    --disable-oocd_trace \
    --disable-buspirate \
    --disable-sysfsgpio \
    --disable-minidriver-dummy \
    --disable-remote-bitbang
RUN make -j$(nproc)
RUN make install
WORKDIR /openocd
RUN echo -e "\nGit info" $(git describe) "\n"
WORKDIR /

FROM alpine:@ALPINE_VERSION@
LABEL description="RISC-V OpenOCD"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
COPY --from=builder /usr/local/riscv-openocd /usr/local/riscv-openocd
# unable to find a way to use Docker wit a non-root user w/ access to USB
# device, even with eudev package and proper udev rules. Run openocd as root
# (unsafe...)
RUN chmod +s /usr/local/riscv-openocd/bin/openocd
WORKDIR /

# docker build -f openocd-riscv.dockerfile -t sifive/openocd-riscv:@ALPINE_VER@-v0.11.0a .
