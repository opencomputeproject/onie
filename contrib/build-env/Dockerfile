#  Copyright (C) 2018 Curt Brune <curt@cumulusnetworks.com>
#
#  Modified with permission from Benayak Karki
#
#  SPDX-License-Identifier:     GPL-2.0

FROM debian:9

# Stretch is EOL; official mirrors no longer serve it.
# Use archive.debian.org and disable Valid-Until checks.
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    rm -rf /etc/apt/sources.list.d/* && \
    printf "deb http://archive.debian.org/debian/ stretch main\n\
deb http://archive.debian.org/debian-security stretch/updates main\n" > /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    build-essential stgit u-boot-tools util-linux \
    gperf device-tree-compiler python-all-dev xorriso \
    autoconf automake bison flex texinfo libtool libtool-bin \
    realpath gawk libncurses5 libncurses5-dev bc \
    dosfstools mtools pkg-config git wget help2man libexpat1 \
    libexpat1-dev fakeroot python-sphinx rst2pdf \
    libefivar-dev libnss3-tools libnss3-dev libpopt-dev \
    libssl-dev sbsigntool uuid-runtime uuid-dev cpio \
    bsdmainutils curl sudo unzip

# Create build user
RUN useradd -m -s /bin/bash build && \
        adduser build sudo && \
        echo "build:build" | chpasswd

WORKDIR /home/build

# Add /sbin and /usr/sbin to build user's path
RUN echo export PATH="/sbin:/usr/sbin:\$PATH" >> .bashrc

# Add common files, like .gitconfig
COPY home .

# Create /home/build/src as a mount point for sharing files with the
# host system.
RUN mkdir src

# Make sure everything in /home/build is owned by the build user
RUN chown -R build:build .

USER build

CMD ["/bin/bash", "--login"]
