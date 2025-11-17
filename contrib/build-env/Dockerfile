#  Copyright (C) 2018 Curt Brune <curt@cumulusnetworks.com>
#
#  Modified with permission from Benayak Karki
#
#  SPDX-License-Identifier:     GPL-2.0

FROM debian:9

# Add initial development packages
COPY sources.list /etc/apt/sources.list

# install required packages
RUN apt-get update && apt-get install -y \
    build-essential stgit u-boot-tools util-linux \
    gperf device-tree-compiler python-all-dev xorriso \
    autoconf automake bison flex texinfo libtool libtool-bin \
    realpath gawk libncurses5 libncurses5-dev bc \
    dosfstools mtools pkg-config git wget help2man libexpat1 \
    libexpat1-dev fakeroot python-sphinx rst2pdf \
    libefivar-dev libnss3-tools libnss3-dev libpopt-dev \
    libssl-dev sbsigntool uuid-runtime uuid-dev cpio \
    bsdmainutils curl sudo unzip \
    gettext autopoint gawk bison flex texinfo help2man \
    locales libc6-dev build-essential gperf \
    libelf-dev libudev-dev libpci-dev libiberty-dev \
    xutils-dev libcap-dev libattr1-dev \
    gnu-efi libfile-slurp-perl tree grub-efi-amd64-bin mtools xorriso gnupg2

# enable locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

# Create build user
RUN useradd -m -s /bin/bash build && \
        adduser build sudo && \
        echo "build:build" | chpasswd

WORKDIR /home/build

COPY efitools-build.sh /home/build
RUN ./efitools-build.sh

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
