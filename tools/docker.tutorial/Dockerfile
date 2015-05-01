FROM debian:7.8
MAINTAINER Rob Sherwood <rob.sherwood@bigswitch.com>
WORKDIR /root
RUN apt-get update && apt-get install -y \
        bridge-utils \
        dosfstools \
        iproute \
        iputils-ping \
        mtools \
        net-tools \
        qemu-kvm \
        sudo \
        tmux \
        traceroute 

# uncomment for debugging
RUN apt-get install -y \
    procps

# Assumes files have been copied into $ONL/tools/docker.tutorial by Makefile
# Docker v1.0 (which is default with ubutu 14.04) has bugs and ignores WORKDIR
ADD kvm-router-demo.sh ./
ADD loader-i386.iso  ./
ADD onl-i386-kvm.swi ./
