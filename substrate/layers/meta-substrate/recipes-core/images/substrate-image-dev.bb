require substrate-image-minimal.bb

IMAGE_FEATURES += "\
    dbg-pkgs \
    debug-tweaks \
    doc-pkgs \
    ssh-server-openssh \
    tools-debug \
    tools-profile \
    "

IMAGE_INSTALL += "\
    kmscube \
    rsync \
    "
