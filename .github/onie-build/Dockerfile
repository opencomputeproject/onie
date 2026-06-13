# ONIE build environment for CI.
#
# Debian 13 (trixie) host for the modernized toolchain.  Required because
# kernel 6.18's objtool needs a newer host libelf than Debian 11 ships
# (0.183 fails with "elf_update: invalid section alignment"), and
# crosstool-NG 1.28 / GCC 14 align with the trixie host toolchain.  (The
# old crosstool-NG 1.24 / GCC 8.3 toolchain could NOT build on trixie.)
#
# This image builds the generic kvm_x86_64 target with secure boot
# enabled.  It includes the secure-boot tooling needed to exercise the SB
# build path -- pesign, efitools, sbsigntool and gnupg2 (for key
# generation and EFI signing).
FROM debian:13
WORKDIR /onie

# Tolerate transient Debian mirror hiccups (connection resets mid-fetch).
RUN echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries

# Build dependencies for crosstool-NG and the ONIE image.
RUN apt-get update && apt-get install -y \
    autoconf \
    autoconf-archive \
    automake \
    autopoint \
    bc \
    bison \
    bsdextrautils \
    build-essential \
    coreutils \
    cpio \
    curl \
    device-tree-compiler \
    dosfstools \
    efitools \
    fakeroot \
    flex \
    gawk \
    git \
    gnupg2 \
    gperf \
    help2man \
    libefivar-dev \
    libelf-dev \
    libexpat1 \
    libexpat1-dev \
    libncurses-dev \
    libpopt-dev \
    libssl-dev \
    libtool \
    libtool-bin \
    locales \
    mtools \
    pesign \
    pkgconf \
    python3-all-dev \
    python3-sphinx \
    python3-venv \
    rst2pdf \
    rsync \
    sbsigntool \
    stgit \
    texinfo \
    tree \
    u-boot-tools \
    unzip \
    util-linux \
    uuid-dev \
    uuid-runtime \
    wget \
    zip \
    xorriso \
    && rm -rf /var/lib/apt/lists/*

# Generate UTF-8 locale (needed for the uclibc / crosstool-NG build).
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# Create the build user with the same UID/GID as the host invoker so
# build artifacts are not left owned by root.  Override at build time
# with --build-arg UID=$(id -u) --build-arg GID=$(id -g).
#
# NOTE: -l avoids docker layer-export hangs for large UIDs.
#       (https://github.com/moby/moby/issues/5419#issuecomment-41478290)
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID build && \
    useradd -l -m -u $UID -g $GID -s /bin/bash build && \
    chown -R build:build /onie

USER build

# /sbin and /usr/sbin hold tools the build invokes.
RUN echo 'export PATH="/sbin:/usr/sbin:$PATH"' >> ~/.bashrc

# The build runs git commands; give it a default identity.
RUN git config --global user.email "build@example.com" && \
    git config --global user.name "Build User"

CMD ["/bin/bash", "--login"]
