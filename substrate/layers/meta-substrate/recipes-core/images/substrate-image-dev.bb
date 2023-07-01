require substrate-image-minimal.bb

IMAGE_FEATURES += "\
    bash-completion-pkgs \
    dbg-pkgs \
    debug-tweaks \
    ssh-server-openssh \
    tools-debug \
    tools-profile \
    "

IMAGE_INSTALL += "\
    rsync \
    strace \
    "
