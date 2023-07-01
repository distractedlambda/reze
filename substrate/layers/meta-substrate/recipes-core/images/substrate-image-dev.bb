IMAGE_FEATURES += "\
    bash-completion-pkgs \
    dbg-pkgs \
    debug-tweaks \
    hwcodecs \
    ssh-server-openssh \
    tools-debug \
    tools-profile \
    "

IMAGE_INSTALL = "packagegroup-core-boot"

inherit core-image
