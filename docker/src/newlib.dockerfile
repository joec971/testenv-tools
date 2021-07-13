FROM alpine:@ALPINE_VERSION@
LABEL description="Store Git repository for newlib & C runtime libraries"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@free.fr>"
RUN apk update
RUN apk add curl
WORKDIR /toolchain
RUN curl -LO ftp://sourceware.org/pub/newlib/newlib-@NEWLIB_VERSION@.tar.gz && \
    [ "f296e372f51324224d387cc116dc37a6bd397198756746f93a2b02e9a5d40154" = \
       "$(sha256sum newlib-@NEWLIB_VERSION@.tar.gz | cut -d' ' -f1)" ] && \
     tar xf newlib-@NEWLIB_VERSION@.tar.gz && \
     mv newlib-@NEWLIB_VERSION@ newlib
WORKDIR /

# docker build -f newlib-v4.dockerfile -t newlib-src:v@NEWLIB_VERSION@ .
