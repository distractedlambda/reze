require substrate-image-base.bb

IMAGE_FEATURES += "\
    bash-completion-pkgs \
    dbg-pkgs \
    dev-pkgs \
    empty-root-password \
    ssh-server-openssh \
    tools-debug \
    tools-profile \
    tools-sdk \
    "

IMAGE_INSTALL:append = " \
    bash-completion \
    htop \
    kmscube \
    man-db \
    man-pages \
    packagegroup-core-full-cmdline \
    rsync \
    tmux \
    vim \
    "
