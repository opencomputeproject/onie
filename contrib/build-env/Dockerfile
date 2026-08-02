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
    libefivar-dev libnss3-tools libnss3-dev libpopt-dev libelf-dev \
    libssl-dev sbsigntool uuid-runtime uuid-dev cpio gnu-efi \
    bsdmainutils curl sudo unzip gettext autopoint locales \
    gnupg2 monkeysphere libfile-slurp-perl && \
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    git clone --depth 1 --branch v1.9.2 https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools.git /tmp/efitools && \
    make -C /tmp/efitools && \
    cp /tmp/efitools/cert-to-efi-sig-list /tmp/efitools/sign-efi-sig-list \
       /tmp/efitools/sig-list-to-certs /tmp/efitools/efi-readvar /tmp/efitools/efi-updatevar \
       /usr/local/bin/ && \
    mkdir -p /usr/share/efitools/efi && \
    cp /tmp/efitools/efi/*.efi /usr/share/efitools/efi/ 2>/dev/null || true && \
    rm -rf /tmp/efitools

# Create build user
RUN useradd -m -s /bin/bash build && \
        adduser build sudo && \
        echo "build:build" | chpasswd

WORKDIR /home/build

# Add /sbin and /usr/sbin to build user's path; uClibc needs UTF-8 locale
RUN echo export PATH="/sbin:/usr/sbin:\$PATH" >> .bashrc && \
    echo export LANG=en_US.UTF-8 >> .bashrc && \
    echo export LC_ALL=en_US.UTF-8 >> .bashrc

# Add common files, like .gitconfig
COPY home .

# Create /home/build/src as a mount point for sharing files with the
# host system.
RUN mkdir src

# Make sure everything in /home/build is owned by the build user
RUN chown -R build:build .

USER build

CMD ["/bin/bash", "--login"]
