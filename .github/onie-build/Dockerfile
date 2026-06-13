# ONIE build environment for CI.
#
# Debian 11 is required: onie/build-config/Makefile still pulls in
# python2-era tooling (python-all-dev) that is unavailable on newer
# Debian releases.
#
# This image builds the generic kvm_x86_64 target with secure boot
# enabled.  It includes the secure-boot key-generation and EFI signing
# tooling (gnupg2, efitools, sbsigntool), the NSS command-line tools the
# shim signing step shells out to (libnss3-tools: pk12util/certutil), and
# the build dependencies for the pesign that ONIE compiles from source
# (NSS/NSPR dev packages).
FROM debian:11
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
    bsdmainutils \
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
    libncurses5 \
    libncurses5-dev \
    libnspr4-dev \
    libnss3-dev \
    libnss3-tools \
    libpopt-dev \
    libssl-dev \
    libtool \
    libtool-bin \
    locales \
    mtools \
    pkgconf \
    python-all-dev \
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
