require substrate-image-base.bb

IMAGE_FEATURES += "\
    empty-root-password \
    ssh-server-openssh \
    "
