FROM alpine:3.12.3 as builder
LABEL description="Build XC3SPROG"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
RUN apk update
RUN apk add build-base cmake ninja pkgconfig subversion patch 
RUN apk add libusb-dev libusb-compat-dev libftdi1-dev
WORKDIR /
RUN svn checkout https://svn.code.sf.net/p/xc3sprog/code/trunk@795 xc3sprog
COPY xc3sprog.patch xc3sprog.patch
WORKDIR /xc3sprog
RUN patch -p1 < ../xc3sprog.patch
RUN mkdir /xc3sprog/build
WORKDIR /xc3sprog/build
RUN cmake -G Ninja -Wno-dev -DCMAKE_INSTALL_PREFIX=/usr/local/xc3sprog ..
RUN ninja
RUN ninja install
RUN strip /usr/local/xc3sprog/bin/*
WORKDIR /

FROM alpine:3.12.3
LABEL description="Tool suite to program Xilinx FPGAs, CPLDs, and EEPROM"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
COPY --from=builder /usr/local/xc3sprog /usr/local/xc3sprog
# unable to find a way to use Docker wit a non-root user w/ access to USB
# device, even with eudev package and proper udev rules. Run xc3sprog as root
# (unsafe...)
RUN chmod +s /usr/local/xc3sprog/bin/*
WORKDIR /

# docker build -f xc3sprog.dockerfile -t sifive/xc3sprog:a3.12-r795 .

















