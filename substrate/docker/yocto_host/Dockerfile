FROM ubuntu:jammy

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    chrpath \
    cpio \
    debianutils \
    diffstat \
    file \
    gawk \
    gcc \
    git \
    iputils-ping \
    libc-dev \
    libegl1-mesa \
    liblz4-tool \
    libsdl1.2-dev \
    locales \
    mesa-common-dev \
    python3 \
    python3-git \
    python3-jinja2 \
    python3-pexpect \
    python3-pip \
    python3-subunit \
    socat \
    texinfo \
    tmux \
    unzip \
    vim \
    wget \
    xz-utils \
    zstd

RUN locale-gen en_US.UTF-8

RUN useradd yocto-host -m -u 1069

RUN mkdir /build && chown 1069:1069 /build

USER yocto-host

WORKDIR /substrate
