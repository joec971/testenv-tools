FROM alpine:3.13 as builder
LABEL description="Build openFPGALoader"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base cmake samurai pkgconfig git
RUN apk add libusb-dev libftdi1-dev eudev-dev
WORKDIR /
RUN git clone https://github.com/trabucayre/openFPGALoader.git
RUN mkdir /openFPGALoader/build
WORKDIR /openFPGALoader/build
RUN cmake -G Ninja -Wno-dev -DCMAKE_INSTALL_PREFIX=/usr/local/openfpgaloader ..
RUN ninja
RUN ninja install
RUN strip /usr/local/openfpgaloader/bin/*
RUN git rev-parse --short HEAD
WORKDIR /

FROM alpine:3.13
LABEL description="Universal utility for programming FPGA"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
COPY --from=builder /usr/local/openfpgaloader /usr/local/openfpgaloader
# unable to find a way to use Docker wit a non-root user w/ access to USB
# device, even with eudev package and proper udev rules. Run xc3sprog as root
# (unsafe...)
RUN chmod +s /usr/local/openfpgaloader/bin/*
WORKDIR /

# docker build -f openfpgaloader.dockerfile -t sifive/openfpgaloader:a3.13-v0.2.1-git .

















