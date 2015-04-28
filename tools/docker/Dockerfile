FROM debian:7.8
MAINTAINER Rob Sherwood <rob.sherwood@bigswitch.com>

# First round of dependences
RUN apt-get update && apt-get install -y \
        apt \
        apt-cacher-ng \
        apt-file \
        apt-utils \
        autoconf \
        automake1.9 \
        autotools-dev \
        bc \
        binfmt-support \
        binfmt-support \
        bison \
        bsdmainutils \
        build-essential \
        ccache \
        cdbs \
        cpio \
        debhelper \
        debhelper \
        debhelper \
        devscripts \
        devscripts \
        dialog \
        dosfstools \
        dpkg-sig \
        file \
        flex \
        gcc \
        genisoimage \
        ifupdown \
        iproute \
        iputils-ping \
        kmod \
        less \
        libc6-dev \
        libedit-dev \
        libi2c-dev \
        libtool \
        locales \
        lsof \
        make \
        mingetty \
        mtd-utils \
        mtools \
        multistrap \
        nano \
        ncurses-dev \
        netbase \
        net-tools \
        nfs-common \
        openssh-server \
        pkg-config \
        pkg-config \
        procps \
        psmisc \
        python \
        python \
        python-yaml \
        qemu \
        qemu-user-static \
        realpath \
        realpath \
        rsyslog \
        squashfs-tools \
        sudo \
        syslinux \
        texinfo=4.13a.dfsg.1-10 \
        traceroute \
        uboot-mkimage \
        vim-tiny \
        wget \
        xapt \
        zile \
        zip 
#RUN apt-get insstall binutils-powerpc-linux-gnu libgomp1-powerpc-cross

# Now the unstable deps and cross compilers
# NOTE 1: texinfo 5.x and above breaks the buildroot build, thus the specific 4.x version
# NOTE 2: this cp is needed to fix an i2c compile problem
# NOTE 3: the /etc/apt/apt.conf.d/docker-* options break multistrap so
#       that it can't find.  Essential packages or resolve apt.opennetlinux.org
# NOTE 4: the default qemu-user-static (1.2) dies with a segfault in
#       `make onl-powerpc`; use 1.4 instead

RUN echo 'APT::Get::AllowUnauthenticated "true";\nAPT::Get::Assume-Yes "true";' | tee /etc/apt/apt.conf.d/99opennetworklinux && \
    echo "deb http://apt.opennetlinux.org/debian/ unstable main" | tee /etc/apt/sources.list.d/opennetlinux.list && \
    dpkg --add-architecture powerpc && \
    apt-get update && \
    apt-get install -y  \
        binutils-powerpc-linux-gnu=2.22-7.1 \
        gcc-4.7-powerpc-linux-gnu \ 
        libc6-dev-powerpc-cross \
        libgomp1-powerpc-cross=4.7.2-4  && \
    xapt -a powerpc libedit-dev ncurses-dev libsensors4-dev libwrap0-dev libssl-dev libsnmp-dev && \
    update-alternatives --install /usr/bin/powerpc-linux-gnu-gcc powerpc-linux-gnu-gcc /usr/bin/powerpc-linux-gnu-gcc-4.7 10 && \
    cp  /usr/include/linux/i2c-dev.h /usr/powerpc-linux-gnu/include/linux/i2c-dev.h && \
    rm /etc/apt/apt.conf.d/docker-* && \
    wget "https://launchpad.net/ubuntu/+source/qemu/1.4.0+dfsg-1expubuntu3/+build/4336762/+files/qemu-user-static_1.4.0%2Bdfsg-1expubuntu3_amd64.deb" && \
    dpkg -i qemu-user-static_1.4.0+dfsg-1expubuntu3_amd64.deb

#RUN echo 'deb http://http.debian.net/debian unstable main' >> /etc/apt/sources.list && \
#    dpkg --add-architecture powerpc && \
#    apt-get update && \
#    apt-get install -y  \
#        binutils-powerpc-linux-gnu \ 
#        cpp-powerpc-linux-gnu \
#        gcc-4.7-multilib \
#        gcc-powerpc-linux-gnu \
#        multistrap && \
#    xapt -a powerpc libedit-dev ncurses-dev libsensors4-dev libwrap0-dev libssl-dev libsnmp-dev && \
#    cp  /usr/include/linux/i2c-dev.h /usr/powerpc-linux-gnu/include/linux/i2c-dev.h && \
#    echo 'APT::Get::AllowUnauthenticated "true";\nAPT::Get::Assume-Yes "true";' | tee /etc/apt/apt.conf.d/99opennetworklinux && \
#    echo "deb http://apt.opennetlinux.org/debian/ unstable main" | tee /etc/apt/sources.list.d/opennetlinux.list


# Run this by default if no other command is specified
#CMD make onl-powerpc onl-x86
