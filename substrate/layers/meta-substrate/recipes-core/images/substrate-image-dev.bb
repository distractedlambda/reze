require substrate-image-base.bb

IMAGE_FEATURES += "\
    dbg-pkgs \
    doc-pkgs \
    ssh-server-openssh \
    tools-debug \
    tools-profile \
    "

IMAGE_INSTALL += "\
    kmscube \
    packagegroup-core-full-cmdline \
    rsync \
    "
