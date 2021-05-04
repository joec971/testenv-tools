FROM debian:10.9-slim as builder
LABEL description="Package Vivado Lab subset for VCU118 targets"
LABEL maintainer="Emmanuel Blot <emmanuel.blot@sifive.com>"
LABEL version="2020.2"

# Quoting Xilinx official support page:
# https://forums.xilinx.com/t5/Installation-and-Licensing/Vivado-lab-license/td-p/988222
# You don't need any licenses to be able to use Xilinx Vivado Lab Tools.
#
# Please note that at the stage when they all be doing the installation, there
# will be a section where each user would need to read and accept the software
# license agreement. Once they all have done so, they will be able to proceed
# further with their installations.

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y libgomp1 libtinfo5 libusb-1.0-0 xz-utils

WORKDIR /usr/local/xilinx
# This package only contains a subset of the massive 6GiB Vivado Lab official
# installation. It has been skimmed to the bare minimum - which still weight
# 800MiB - to create a manageable Docker image size. Note that it can only flash
# VCU118 boards.
ADD vivado_lab_2020.2.tar .

# Avoid installing the whole systemd for the sake of retrieving a locale.
COPY vivado-localectl Vivado_Lab/2020.2/bin/localectl
RUN chmod +x Vivado_Lab/2020.2/bin/localectl

# disable a feature that requires X11, and triggers an error
# see https://www.xilinx.com/support/answers/62553.html
RUN sed -i 's/^rdi::x11_workaround//g' \
    /usr/local/xilinx/Vivado_Lab/2020.2/lib/scripts/rdi/features/base/base.tcl

ENV PATH=$PATH:/usr/local/xilinx/Vivado_Lab/2020.2/bin
ENV LD_LIBRARY_PATH=/usr/local/xilinx/Vivado_Lab/2020.2/lib/lnx64.o

# docker build -f vivadolab.dockerfile -t sifive/vivadolab:d10.9-v20.2 .
