FROM alpine:3.13 as builder
LABEL description="Build OpenOCD for RISC-V targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base autoconf automake libtool pkgconfig texinfo coreutils git
RUN apk add libusb-dev libftdi1-dev
WORKDIR /
RUN git clone --single-branch --branch riscv \
    https://github.com/riscv/riscv-openocd.git
WORKDIR /riscv-openocd
RUN mkdir build
RUN ls -l
RUN ./bootstrap
WORKDIR /riscv-openocd/build
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
WORKDIR /riscv-openocd
RUN echo -e "\nGit info" $(git describe) "\n"
WORKDIR /

FROM alpine:3.13
LABEL description="RISC-V OpenOCD"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
COPY --from=builder /usr/local/riscv-openocd /usr/local/riscv-openocd
# unable to find a way to use Docker wit a non-root user w/ access to USB
# device, even with eudev package and proper udev rules. Run openocd as root
# (unsafe...)
RUN chmod +s /usr/local/riscv-openocd/bin/openocd
WORKDIR /

# docker build -f openocd-riscv.dockerfile -t openocd-riscv:a3.13-tmp .
# docker tag openocd-riscv:a3.13-tmp sifive/openocd-riscv:a3.13-SHA .
