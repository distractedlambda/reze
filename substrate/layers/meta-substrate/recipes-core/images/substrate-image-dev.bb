require substrate-image-base.bb

IMAGE_FEATURES += "\
    bash-completion-pkgs \
    dbg-pkgs \
    empty-root-password \
    ssh-server-openssh \
    tools-debug \
    tools-profile \
    "

IMAGE_INSTALL += "\
    bash \
    bash-completion \
    bc \
    binutils \
    bzip2 \
    coreutils \
    cpio \
    curl \
    diffutils \
    ed \
    elfutils \
    ethtool \
    findutils \
    gawk \
    grep \
    gzip \
    htop \
    iptables \
    iputils \
    kmscube \
    less \
    logrotate \
    man-db \
    man-pages \
    pciutils \
    rsync \
    sed \
    strace \
    tar \
    time \
    tmux \
    unzip \
    usbutils \
    util-linux \
    vim \
    wget \
    which \
    xz \
    "
