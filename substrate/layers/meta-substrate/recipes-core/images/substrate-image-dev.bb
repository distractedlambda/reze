require substrate-image-base.bb

IMAGE_FEATURES += "\
    bash-completion-pkgs \
    dbg-pkgs \
    empty-root-password \
    ssh-server-openssh \
    "

IMAGE_INSTALL:append = " \
    bash-completion \
    htop \
    kmscube \
    rsync \
    tmux \
    "
