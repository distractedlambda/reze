require substrate-image-minimal.bb

IMAGE_FEATURES += "\
    debug-tweaks \
    ssh-server-openssh \
    "

IMAGE_INSTALL += "\
    kmscube \
    rsync \
    "
