#!/usr/bin/env bash

# In Github Action's servers,We don't need firefox.Update it will take a lot of time.
apt remove firefox
apt autoremove

apt-get update -y && apt-get upgrade -y
apt-get -y install libncurses-dev dkms libudev-dev libpci-dev libiberty-dev autoconf
apt-get -y install git ccache automake flex lzop bison gperf build-essential zip curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev pwgen 
apt-get -y install libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev libx11-dev lib32z-dev libgl1-mesa-dev xsltproc unzip device-tree-compiler python2 python3 gcc clang libc6 libstdc++6 wget zstd 
apt-get -y install openjdk-11-jdk openjdk-11-jre python-is-python3 openssl kmod cpio libelf-dev libtfm-dev ca-certificates binutils binutils-aarch64-linux-gnu binutils-arm-linux-gnueabi aria2
apt-get -y install gawk gcc glibc-source
apt-get -y install libc6 libc6-dev libc6-i386 libc6-dev-i386
apt-get -y install llvm clang-tools lld
apt-get -y install gcc-aarch64-linux-gnu libncurses5
apt-get -y install bc \
            binutils-dev \
            bison \
            build-essential \
            ca-certificates \
            ccache \
            clang \
            cmake \
            curl \
            file \
            flex \
            git \
            libelf-dev \
            libssl-dev \
            libstdc++-$(apt list libstdc++6 2>/dev/null | grep -Eos '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d . -f 1)-dev \
            lld \
            make \
            ninja-build \
            python3-dev \
            texinfo \
            u-boot-tools \
            xz-utils \
            zlib1g-dev
