FROM debian
MAINTAINER Rob Sherwood <rob.sherwood@bigswitch.com>

# First round of dependences
RUN apt-get update && apt-get install -y \
	build-essential \
	pkg-config \
	python \
	debhelper \
	ccache \
	binfmt-support \
	qemu-user-static \
	multistrap \
	apt-cacher-ng \
	devscripts \
	debhelper \
	dpkg-sig \
	realpath
#RUN apt-get insstall binutils-powerpc-linux-gnu libgomp1-powerpc-cross

# Now the unstable deps and cross compilers
RUN echo 'deb http://http.debian.net/debian unstable main' >> /etc/apt/sources.list && \
    dpkg --add-architecture powerpc && \
    apt-get update && \
    apt-get install -y  binutils-powerpc-linux-gnu \ 
        gcc-powerpc-linux-gnu \
        cpp-powerpc-linux-gnu \
        libedit-dev \
        ncurses-dev \
        gcc \
        make \
        xapt \
        cdbs \
        debhelper \
        pkg-config \
        devscripts \
        bison \
        flex \
        texinfo \
        wget \
        cpio \
        multistrap \
        squashfs-tools \
        zip \
        binfmt-support \
        autoconf \
        automake1.9 \
        autotools-dev \
        libtool \
        apt-file \
        file \
        genisoimage \
        syslinux \
        dosfstools \
        mtools \
        bc \
        python-yaml \
        mtd-utils \
        gcc-4.7-multilib \
        uboot-mkimage \
        kmod \
        qemu && \
    xapt -a powerpc libedit-dev ncurses-dev libsensors4-dev libwrap0-dev libssl-dev libsnmp-dev


# Now the ONL deps
RUN echo 'APT::Get::AllowUnauthenticated "true";\nAPT::Get::Assume-Yes "true";' | tee /etc/apt/apt.conf.d/99opennetworklinux && \
    echo "deb http://apt.opennetlinux.org/debian/ unstable main" | tee /etc/apt/sources.list.d/opennetlinux.list


# Run this by default if no other command is specified
#CMD git clone git://github.com/opennetworklinux/ONL && cd ONL && make onl-powerpc onl-x86
